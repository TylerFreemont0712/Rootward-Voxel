#!/usr/bin/env python3
"""Safe authoring entry point. The game never runs this tool or Blender."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'pipeline/world-catalog.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def godot(*args):
    subprocess.run([os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(ROOT),
                    '-s', 'res://pipeline/world_art.gd', '--', *map(str, args)], check=True, cwd=ROOT)


def blender(*args, script='blender_handoff.py'):
    binary = os.environ.get('BLENDER_BIN') or shutil.which('blender')
    if not binary and Path('/home/joejin/blender/blender').is_file():
        binary = '/home/joejin/blender/blender'
    if not binary:
        raise SystemExit('Blender is needed for authoring. Set BLENDER_BIN; playing needs only runtime GLBs.')
    subprocess.run([binary, '--background', '--factory-startup', '--python-exit-code', '1',
                    '--python', str(ROOT / 'pipeline' / script), '--', *map(str, args)], check=True, cwd=ROOT)


def main():
    catalog = json.loads(CATALOG.read_text())
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['seed', 'init', 'build', 'compare', 'retexture'])
    parser.add_argument('asset', choices=sorted(catalog['assets']))
    options = parser.parse_args()
    entry = catalog['assets'][options.asset]
    source = ROOT / entry['source']
    seed = source.parent / 'seed.glb'
    runtime = ROOT / entry['runtime']
    cache = ROOT / '.cache/world-art' / options.asset
    cache.mkdir(parents=True, exist_ok=True)

    if options.operation == 'seed':
        if source.exists() or seed.exists():
            raise SystemExit('Source/seed already exists. Bump the catalog version/path for a new seed; existing art is preserved.')
        candidate = cache / 'seed.glb'
        if candidate.exists():
            candidate.unlink()
        godot('seed', options.asset, candidate)
        source.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(candidate, seed)
        shutil.copy2(Path(str(candidate) + '.audit.json'), Path(str(seed) + '.audit.json'))
        (source.parent / 'provenance.json').write_text(json.dumps({
            'asset': options.asset, 'version': entry['version'], 'created': datetime.now(timezone.utc).isoformat(),
            'seed_sha256': digest(seed), 'recipe': 'pipeline/world_seed.gd',
            'recipe_sha256': digest(ROOT / 'pipeline/world_seed.gd'),
            'geometry_recipe_sha256': digest(ROOT / 'scenes/clearing_view.gd'),
            'note': 'One-way procedural bootstrap. model.blend becomes the editable source after init.'
        }, indent=2) + '\n')
    elif options.operation == 'init':
        if source.exists():
            raise SystemExit('Editable source already exists. Open it in Blender; init never overwrites human changes.')
        if not seed.exists():
            raise SystemExit('Run seed first.')
        blender('init', seed, source)
    elif options.operation == 'retexture':
        if not source.exists():
            raise SystemExit('Missing editable source. Run seed, then init.')
        # A deliberate source edit: keep the file as it was beside it, once, then bake the texture catalog in.
        backup = source.with_name('model.pre-retexture.blend')
        if not backup.exists():
            shutil.copy2(source, backup)
        blender(source, ROOT, script='blender_retexture.py')
        catalog_path = ROOT / 'pipeline/texture-catalog.json'
        (source.parent / 'retexture.json').write_text(json.dumps({
            'asset': options.asset, 'retextured': datetime.now(timezone.utc).isoformat(),
            'texture_catalog_sha256': digest(catalog_path), 'texture_set': json.loads(catalog_path.read_text())['set'],
            'script': 'pipeline/blender_retexture.py', 'backup': backup.name,
            'note': 'Materials and UVs rewritten from the texture catalog; geometry untouched. Run build to export.'
        }, indent=2) + '\n')
        print('Retextured; run build next:', source)
    elif options.operation == 'build':
        if not source.exists():
            raise SystemExit('Missing editable source. Run seed, then init.')
        before = digest(source)
        candidate = cache / 'model.glb'
        audit_path = cache / 'audit.json'
        blender('export', source, candidate)
        godot('audit', candidate, audit_path)
        if before != digest(source):
            raise SystemExit('Source changed during export. Runtime output was not promoted; inspect your source.')
        audit = json.loads(audit_path.read_text())
        runtime.parent.mkdir(parents=True, exist_ok=True)
        # Retain one previous runtime export for easy recovery; artist sources are never touched.
        if runtime.exists():
            shutil.copy2(runtime, cache / 'previous.glb')
        temporary = runtime.with_suffix('.glb.pending')
        shutil.copy2(candidate, temporary)
        os.replace(temporary, runtime)
        manifest = {
            'schema': 1, 'asset': options.asset, 'version': entry['version'],
            'source': entry['source'], 'source_sha256': before, 'runtime': entry['runtime'],
            'runtime_sha256': digest(runtime), 'exporter': 'pipeline/blender_handoff.py',
            'exporter_sha256': digest(ROOT / 'pipeline/blender_handoff.py'), 'audit': audit,
        }
        runtime.with_name('manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        print('Promoted audited Blender export:', runtime)
    else:
        if not seed.exists() or not runtime.exists():
            raise SystemExit('Seed and runtime export are both required.')
        godot('compare', seed, runtime)


if __name__ == '__main__':
    try:
        main()
    except subprocess.CalledProcessError as error:
        raise SystemExit(f'Authoring stage failed with exit {error.returncode}; see the diagnostic above. Source art was preserved.') from None
