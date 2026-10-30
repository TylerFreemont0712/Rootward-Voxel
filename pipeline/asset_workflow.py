#!/usr/bin/env python3
"""Local authoring queue shared by the development showcase and coding agents.

Only fixed operations run here. Notes are data, never Python or shell source.
"""
from __future__ import annotations

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import uuid


class WorkflowError(ValueError):
    pass


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stamp() -> str:
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def atomic_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    try:
        temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


class AssetWorkflow:
    def __init__(self, root: Path):
        self.root = root.resolve()
        self.catalog_path = self.root / 'pipeline/world-catalog.json'
        if not (self.root / 'project.godot').is_file() or not self.catalog_path.is_file():
            raise WorkflowError('Asset changes require a writable source checkout of this project.')
        self.queue = self.safe('asset-requests/requests')

    def safe(self, relative: str) -> Path:
        relative = str(relative).removeprefix('res://')
        path = self.root / relative
        if not relative or Path(relative).is_absolute() or '..' in Path(relative).parts:
            raise WorkflowError('Expected a project-relative file path: ' + relative)
        if not path.resolve().is_relative_to(self.root):
            raise WorkflowError('Path leaves the project: ' + relative)
        return path

    @contextmanager
    def lock(self):
        folder = self.safe('asset-requests')
        folder.mkdir(parents=True, exist_ok=True)
        lock = folder / '.write-lock'
        try:
            descriptor = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        except FileExistsError:
            raise WorkflowError('Another asset operation is writing. Retry after it finishes; inspect asset-requests/.write-lock if an authoring process was interrupted.') from None
        try:
            os.write(descriptor, str(os.getpid()).encode())
            os.close(descriptor)
            yield
        finally:
            lock.unlink(missing_ok=True)

    def catalog(self) -> dict:
        return json.loads(self.catalog_path.read_text())

    def asset(self, asset_id: str) -> dict:
        entry = self.catalog()['assets'].get(asset_id)
        if not entry:
            raise WorkflowError('Unknown world asset: ' + asset_id)
        return entry

    def records(self) -> list[dict]:
        result = []
        if self.queue.exists():
            for path in sorted(self.queue.glob('*.json'), reverse=True):
                data = json.loads(path.read_text())
                if data.get('schema') != 1 or data.get('id') != path.stem:
                    raise WorkflowError('Invalid request record: ' + str(path.relative_to(self.root)))
                result.append(data)
        return result

    def record(self, request_id: str) -> dict:
        if not re.fullmatch(r'[a-zA-Z0-9_-]+', request_id):
            raise WorkflowError('Invalid request ID.')
        path = self.queue / (request_id + '.json')
        if not path.is_file():
            raise WorkflowError('Request does not exist: ' + request_id)
        record = json.loads(path.read_text())
        if record.get('schema') != 1 or record.get('id') != request_id:
            raise WorkflowError('Invalid request record: ' + request_id)
        return record

    def save(self, record: dict) -> None:
        if not re.fullmatch(r'[a-zA-Z0-9_-]+', record['id']):
            raise WorkflowError('Invalid request ID.')
        self.queue.mkdir(parents=True, exist_ok=True)
        # JSON is authoritative. Markdown is the human/agent handoff, regenerated on every change.
        atomic_json(self.queue / (record['id'] + '.json'), record)
        path = self.queue / (record['id'] + '.md')
        temporary = path.with_suffix('.md.tmp')
        temporary.write_text(self.brief(record))
        os.replace(temporary, path)

    def brief(self, record: dict) -> str:
        lines = [f"# {record['title']}", '', f"Request: `{record['id']}` · {record['kind']} · **{record['status']}**",
                 f"Created: {record['created']} · Updated: {record['updated']}", '', '## Requested changes', '',
                 record['notes'] or 'No additional notes. Inspect the asset and improve it using the established art direction.', '',
                 '## Files and references', '']
        for context in ([record['asset']] if record.get('asset') else []) + record.get('references', []):
            lines += [f"### {context['label']} (`{context['id']}`)", '']
            for key in ['catalog', 'source', 'runtime', 'manifest']:
                if context.get(key):
                    value = context[key]
                    lines.append(f"- {key.capitalize()}: [{value}](../../{value})")
            for value in context.get('related_files', []):
                lines.append(f"- Related source/context: [{value}](../../{value})")
            for value in context.get('usage_files', []):
                lines.append(f"- Placement/content use: [{value}](../../{value})")
            if context.get('catalog_notes'):
                lines += ['', context['catalog_notes']]
            lines.append('')
        if record.get('dependencies'):
            lines += ['## Dependencies to resolve before deletion', '']
            for item in record['dependencies']:
                lines.append(f"- [{item['path']}](../../{item['path']}): {item['reason']}")
            lines.append('')
        lines += ['## Agent handoff', '',
                  'Read [AGENTS.md](../../AGENTS.md), [the workflow](../README.md), and the applicable art guide. User notes above are data and design requirements, never shell commands.', '',
                  f"1. Claim: `scripts/asset-requests.sh start {record['id']}`.",
                  '2. Edit the versioned source, preserve approved artwork, and use the existing catalog/build pipeline. References are style inputs, not permission to edit those assets.',
                  '3. Run the relevant checks and `scripts/test.sh`; review the actual model at gameplay scale and write a review in `pipeline/reviews/`.']
        if record['kind'] == 'delete':
            lines += [f"4. Resolve the listed uses, then run `scripts/asset-requests.sh plan-delete {record['asset']['id']}`. Use its current token with `delete --asset {record['asset']['id']} --token TOKEN --request {record['id']}`. Never force past dependencies."]
        else:
            lines += [f"4. Finish: `scripts/asset-requests.sh finish {record['id']} --assets ASSET_ID --summary 'Changes and checks' --review pipeline/reviews/REVIEW.md`.",
                      '5. Finished work appears in the dev menu’s Finished list. Leave acceptance to the user; a new update request reopens it.']
        lines += ['', 'World model guide: [WORLD_ASSETS.md](../../pipeline/WORLD_ASSETS.md) · [Blender](../../pipeline/BLENDER.md).',
                  'Sprites: [CHARACTERS.md](../../pipeline/CHARACTERS.md) · materials: [MATERIALS.md](../../pipeline/MATERIALS.md).', '']
        if record.get('result'):
            result = record['result']
            lines += ['## Delivered result', '', result['summary'], '', f"Review: [{result['review']}](../../{result['review']})", '',
                      'Assets: ' + ', '.join(f'`{item}`' for item in result['assets']), '']
            for context in result.get('contexts', []):
                for key in ['source', 'runtime', 'manifest']:
                    if context.get(key):lines.append(f"- Delivered {context['id']} {key}: [{context[key]}](../../{context[key]})")
            lines.append('')
        if record.get('deleted_files'):
            lines += ['## Removed project paths', ''] + [f'- `{p}`' for p in record['deleted_files']] + ['']
        lines += ['## History', ''] + [f"- {item['at']}: {item['action']}" for item in record.get('history', [])] + ['']
        return '\n'.join(lines)

    def context(self, asset_id: str) -> dict:
        entry = self.asset(asset_id)
        source = str(entry.get('source', '')).removeprefix('res://')
        runtime = str(entry.get('runtime', '')).removeprefix('res://')
        related = set()
        usage = []
        literal = re.compile(r'(?<![A-Za-z0-9_-])' + re.escape(asset_id) + r'(?![A-Za-z0-9_-])')
        for path in (self.root / 'content').rglob('*.json'):
            if path.is_file() and not path.is_symlink() and literal.search(path.read_text(errors='replace')):
                usage.append(str(path.relative_to(self.root)))
        if source:
            folder = self.safe(source).parent
            if folder.exists():
                related.update(str(p.relative_to(self.root)) for p in folder.iterdir() if p.suffix in {'.json', '.md', '.txt', '.py'})
        # Catalog notes often name the source pack, concept plate and recorded source edit.
        for match in re.findall(r'(?:art|docs|pipeline)/[A-Za-z0-9_./-]+', str(entry.get('notes', ''))):
            match = match.rstrip('.')
            target = self.safe(match)
            if target.is_file():
                related.add(match)
            elif target.is_dir() and (target / 'README.md').is_file():
                related.add(match.rstrip('/') + '/README.md')
        return {'id': asset_id, 'label': entry.get('label', asset_id.replace('-', ' ').title()),
                'catalog': 'pipeline/world-catalog.json', 'source': source, 'runtime': runtime,
                'manifest': str(Path(runtime).with_name('manifest.json')) if runtime else '',
                'catalog_notes': entry.get('notes', ''), 'related_files': sorted(related), 'usage_files': sorted(usage),
                'catalog_entry': entry}

    def reference_options(self) -> list[dict]:
        return [{'id': key, 'label': value.get('label', key.replace('-', ' ').title())}
                for key, value in sorted(self.catalog()['assets'].items())]

    def submit(self, data: dict) -> dict:
        kind = data.get('kind')
        if kind not in {'new', 'update', 'delete'}:
            raise WorkflowError('Choose new, update or delete.')
        title = str(data.get('title', '')).strip()
        asset_id = str(data.get('asset_id', ''))
        if kind != 'new':
            context = self.context(asset_id)
            title = ('Update ' if kind == 'update' else 'Delete ') + context['label']
        else:
            context = {}
            if not title:
                raise WorkflowError('Give the new asset a short name.')
        notes = str(data.get('notes', ''))
        if len(title) > 180 or len(notes) > 16000:
            raise WorkflowError('Use a name up to 180 characters and notes up to 16,000 characters.')
        references = data.get('references', [])
        if not isinstance(references, list) or len(references) > 12:
            raise WorkflowError('Select up to 12 reference assets.')
        now = stamp()
        record = {'schema': 1, 'id': datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S') + '-' + uuid.uuid4().hex[:8],
                  'kind': kind, 'title': title, 'asset_type': str(data.get('asset_type', 'world model')),
                  'status': 'requested', 'notes': notes, 'asset': context,
                  'references': [self.context(item) for item in dict.fromkeys(references)],
                  'created': now, 'updated': now, 'history': [{'at': now, 'action': 'Requested in development showcase'}]}
        if kind == 'delete':
            record['dependencies'] = self.plan_delete(asset_id)['blockers']
        if kind == 'new':
            record['existing_assets'] = list(self.catalog()['assets'])
        with self.lock():
            # Revising finished work moves it out of Finished while keeping its delivery history.
            if kind == 'update':
                for previous in self.records():
                    if previous['status'] == 'finished' and asset_id in previous.get('result', {}).get('assets', []):
                        previous['status'] = 'changes_requested'
                        previous['updated'] = now
                        previous['history'].append({'at': now, 'action': 'Further changes requested: ' + record['id']})
                        self.save(previous)
            self.save(record)
        return record

    def fingerprint(self, asset_id: str) -> dict:
        entry = self.asset(asset_id)
        source, runtime = self.safe(entry.get('source', '')), self.safe(entry.get('runtime', ''))
        if not source.is_file() or not runtime.is_file():
            raise WorkflowError('Build source and runtime files before marking finished: ' + asset_id)
        manifest_path = runtime.with_name('manifest.json')
        if not manifest_path.is_file():
            raise WorkflowError('A normal world-art build manifest is required: ' + asset_id)
        manifest = json.loads(manifest_path.read_text())
        result = {'source': digest(source), 'runtime': digest(runtime),
                  'entry': hashlib.sha256(json.dumps(entry, sort_keys=True).encode()).hexdigest()}
        if manifest.get('source_sha256') != result['source'] or manifest.get('runtime_sha256') != result['runtime']:
            raise WorkflowError('The build manifest is stale. Rebuild through scripts/world-art.sh: ' + asset_id)
        return result

    def current(self, record: dict) -> bool:
        try:
            fingerprints = record.get('result', {}).get('fingerprints', {})
            return bool(fingerprints) and all(self.fingerprint(key) == value for key, value in fingerprints.items())
        except (WorkflowError, OSError, ValueError):
            return False

    def transition(self, request_id: str, action: str, data: dict) -> dict:
        with self.lock():
            record = self.record(request_id)
            status = record['status']
            if action == 'start':
                if status not in {'requested', 'in_progress'}:
                    raise WorkflowError('Only a requested task can be started.')
                record['status'] = 'in_progress'
            elif action == 'finish':
                if status not in {'requested', 'in_progress'} or record['kind'] == 'delete':
                    raise WorkflowError('Only open new/update work can be marked finished; deletion uses the delete command.')
                assets = list(dict.fromkeys(data.get('assets', [])))
                if not assets or (record['kind'] == 'update' and record['asset']['id'] not in assets):
                    raise WorkflowError('Include the requested asset in the finished result.')
                if record['kind'] == 'new' and not any(asset not in record.get('existing_assets', []) for asset in assets):
                    raise WorkflowError('A new asset request needs at least one newly registered model ID.')
                summary = str(data.get('summary', '')).strip()
                review = str(data.get('review', '')).removeprefix('res://')
                if not summary or not review.startswith('pipeline/reviews/') or not self.safe(review).is_file():
                    raise WorkflowError('Provide a change/check summary and an existing review in pipeline/reviews/.')
                record['result'] = {'assets': assets, 'summary': summary, 'review': review,
                                    'contexts': [self.context(key) for key in assets],
                                    'fingerprints': {key: self.fingerprint(key) for key in assets}}
                record['status'] = 'finished'
            elif action == 'accept':
                if status != 'finished' or not self.current(record):
                    raise WorkflowError('Only unchanged, finished work can be accepted. Rebuild and review changed assets first.')
                record['status'] = 'accepted'
            else:
                raise WorkflowError('Unknown task action.')
            record['updated'] = stamp()
            record['history'].append({'at': record['updated'], 'action': action})
            self.save(record)
            return record

    def overview(self) -> dict:
        records = self.records()
        for record in records:
            record['brief'] = 'asset-requests/requests/' + record['id'] + '.md'
            if record['status'] == 'finished':
                record['review_current'] = self.current(record)
        return {'requests': records, 'references': self.reference_options(),
                'queue_path': str(self.root / 'asset-requests'), 'catalog': self.catalog()['assets']}

    def plan_delete(self, asset_id: str) -> dict:
        entry = self.asset(asset_id)
        blockers = []
        roots = []
        # Only exclusive, conventional asset directories are eligible for automatic deletion.
        for key, prefix in [('source', 'art/source/world'), ('runtime', 'assets/world')]:
            path = str(entry.get(key, '')).removeprefix('res://')
            expected = f'{prefix}/{asset_id}'
            candidate = self.safe(expected)
            if not path.startswith(expected + '/'):
                blockers.append({'path': 'pipeline/world-catalog.json', 'reason': f'{key} is shared or outside the asset’s own folder: {path}'})
                continue
            roots.append(expected)
            if candidate.exists() and any(p.is_symlink() for p in [candidate, *candidate.rglob('*')]):
                blockers.append({'path': expected, 'reason': 'A symbolic link needs manual ownership review.'})
        needles = [asset_id] + [str(entry.get(k, '')).removeprefix('res://') for k in ['source', 'runtime'] if entry.get(k)]
        literal = re.compile(r'(?<![A-Za-z0-9_-])' + re.escape(asset_id) + r'(?![A-Za-z0-9_-])')
        catalog = self.catalog()
        for other_id, other in catalog['assets'].items():
            if other_id == asset_id:
                continue
            values = json.dumps(other, ensure_ascii=False)
            if literal.search(values) or any(folder + '/' in values for folder in roots):
                blockers.append({'path': 'pipeline/world-catalog.json', 'reason': 'Another asset references or shares these files: ' + other_id})
        if literal.search(json.dumps(catalog.get('areas', {}))):
            blockers.append({'path': 'pipeline/world-catalog.json', 'reason': 'An area presentation selects this asset.'})
        suffixes = {'.json', '.gd', '.tscn', '.tres', '.py', '.sh', '.gdshader'}
        for folder in ['content', 'app', 'core', 'scenes', 'ui', 'art', 'pipeline', 'scripts', 'tools', 'test', 'sandbox']:
            base = self.root / folder
            if not base.exists():
                continue
            for path in base.rglob('*'):
                relative = path.relative_to(self.root).as_posix()
                if path.suffix not in suffixes or not path.is_file() or path.is_symlink():
                    continue
                if relative == 'pipeline/world-catalog.json' or relative.startswith(('art/source/', 'sandbox/runtime/')):
                    continue
                text = path.read_text(errors='replace')
                if literal.search(text) or any(needle and needle in text for needle in needles[1:]):
                    blockers.append({'path': relative, 'reason': 'Asset ID or owned file is referenced here.'})
        files = []
        for folder in roots:
            path = self.safe(folder)
            if path.is_dir() and not path.is_symlink():
                files += [p for p in path.rglob('*') if p.is_file() and not p.is_symlink()]
        inventory = {str(path.relative_to(self.root)): digest(path) for path in sorted(files)}
        payload = {'asset_id': asset_id, 'entry': entry, 'roots': roots, 'files': inventory, 'blockers': blockers}
        return {'asset_id': asset_id, 'roots': roots, 'files': list(inventory), 'blockers': blockers,
                'token': hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()}

    def delete(self, asset_id: str, token: str, request_id: str = '', notes: str = '') -> dict:
        with self.lock():
            plan = self.plan_delete(asset_id)
            if plan['blockers']:
                raise WorkflowError('Asset is still referenced. Resolve its dependency list or request deletion first.')
            if token != plan['token']:
                raise WorkflowError('The asset or its references changed. Review a fresh deletion plan.')
            if request_id:
                record = self.record(request_id)
                if record['kind'] != 'delete' or record['asset']['id'] != asset_id or record['status'] not in {'requested', 'in_progress'}:
                    raise WorkflowError('This is not an open deletion request for the selected asset.')
            else:
                now = stamp()
                record = {'schema': 1, 'id': datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S') + '-' + uuid.uuid4().hex[:8],
                          'kind': 'delete', 'title': 'Delete ' + asset_id, 'notes': notes, 'asset': self.context(asset_id),
                          'references': [], 'created': now, 'history': []}
            original_catalog = self.catalog_path.read_bytes()
            prior_records = {suffix: (self.queue / (record['id'] + suffix)).read_bytes()
                             if (self.queue / (record['id'] + suffix)).exists() else None for suffix in ['.json', '.md']}
            catalog = json.loads(original_catalog)
            del catalog['assets'][asset_id]
            staging = self.safe('.cache/asset-deletion/' + record['id'])
            staging.mkdir(parents=True, exist_ok=False)
            moved = []
            try:
                for index, folder in enumerate(plan['roots']):
                    source = self.safe(folder)
                    if source.exists():
                        destination = staging / str(index)
                        os.replace(source, destination)
                        moved.append((source, destination))
                atomic_json(self.catalog_path, catalog)
                record.update(status='deleted', updated=stamp(), deleted_files=plan['files'])
                record['history'].append({'at': record['updated'], 'action': 'Deleted owned source/runtime folders and world-catalog entry'})
                self.save(record)
            except Exception:
                self.catalog_path.write_bytes(original_catalog)
                for source, destination in reversed(moved):
                    if destination.exists():
                        os.replace(destination, source)
                for suffix, content in prior_records.items():
                    path = self.queue / (record['id'] + suffix)
                    if content is None:
                        path.unlink(missing_ok=True)
                    else:
                        path.write_bytes(content)
                shutil.rmtree(staging)
                raise
            # This is actual removal, not a hidden catalog entry or an archive.
            shutil.rmtree(staging)
            return record


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('operation', choices=['overview', 'list', 'show', 'submit', 'start', 'finish', 'accept', 'plan-delete', 'delete'])
    parser.add_argument('request', nargs='?', default='')
    parser.add_argument('--payload', default='{}')
    parser.add_argument('--payload-file', type=Path)
    parser.add_argument('--asset', default='')
    parser.add_argument('--assets', nargs='+', default=[])
    parser.add_argument('--summary', default='')
    parser.add_argument('--review', default='')
    parser.add_argument('--token', default='')
    parser.add_argument('--request', dest='delete_request', default='')
    args = parser.parse_args()
    workflow = AssetWorkflow(args.root)
    if args.payload_file:
        payload_path = args.payload_file.resolve()
        if not payload_path.is_relative_to(workflow.root) or payload_path.stat().st_size > 262144:
            raise WorkflowError('Request data must be a JSON file inside this project, at most 256 KiB.')
        payload = json.loads(payload_path.read_text())
    else:
        payload = json.loads(args.payload)
    if args.operation == 'overview':
        value = workflow.overview()
    elif args.operation == 'list':
        value = workflow.records()
    elif args.operation == 'show':
        value = workflow.record(args.request)
    elif args.operation == 'submit':
        value = workflow.submit(payload)
    elif args.operation in {'start', 'finish', 'accept'}:
        value = workflow.transition(args.request, args.operation, vars(args))
    elif args.operation == 'plan-delete':
        value = workflow.plan_delete(args.request or args.asset)
    else:
        value = workflow.delete(args.asset, args.token, args.delete_request, str(payload.get('notes', '')))
    print(json.dumps({'ok': True, 'data': value}, ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except (WorkflowError, OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'ok': False, 'error': str(error)}, ensure_ascii=False))
        sys.exit(1)
