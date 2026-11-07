#!/usr/bin/env python3
"""Run the project's automated checks from test/manifest.json, in parallel, with a one-screen summary.

    scripts/test.sh                 quick tier (rules, documents, art contracts, guards)
    scripts/test.sh flow            quick + the real game scene driven headless
    scripts/test.sh full            everything, including the audit of every runtime model
    scripts/test.sh smoke           does the game boot and does every room load? (about 20 s)
    scripts/test.sh square lane     any tests whose id contains these words
    scripts/test.sh --list          every test with its tier and rough cost

Options: -j N parallel jobs (default: half the cores, at most 8), --serial, -v print passing output too,
--no-import skip the import check, --check only validate the manifest. Exit status is 0 only if every test passed.
"""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'test/manifest.json'
CACHE = ROOT / '.cache'
STAMP = CACHE / 'import.stamp'
ORDER = ['quick', 'flow', 'full']


def load():
    return json.loads(MANIFEST.read_text())


def check_manifest(data):
    problems = []
    seen = set()
    registered = set()
    for test in data['tests']:
        if test['id'] in seen:
            problems.append('Duplicate test id: ' + test['id'])
        seen.add(test['id'])
        registered.add(test['file'])
        if not (ROOT / test['file']).is_file():
            problems.append('Missing test file: ' + test['file'])
        if test['tier'] not in ORDER:
            problems.append(f"{test['id']}: unknown tier {test['tier']}")
    for path in sorted((ROOT / 'test').glob('test_*.*')):
        rel = path.relative_to(ROOT).as_posix()
        if path.suffix in ('.gd', '.py') and rel not in registered:
            problems.append(f'{rel} is not listed in test/manifest.json (a base class used by other tests belongs in tools/ or a non-test_ file)')
    smoke = data.get('smoke')
    if smoke and not (ROOT / f'test/{smoke}.gd').is_file():
        problems.append('Missing smoke test test/%s.gd' % smoke)
    return problems


def select(data, words):
    tests = data['tests']
    if not words:
        words = ['quick']
    chosen, seen = [], set()
    for word in words:
        if word == 'smoke':
            batch = [{'id': 'smoke', 'file': f"test/{data['smoke']}.gd", 'tier': 'quick', 'est': 20, 'what': 'Boot and load every room'}]
        elif word in ORDER:
            batch = [t for t in tests if ORDER.index(t['tier']) <= ORDER.index(word)]
        else:
            batch = [t for t in tests if word == t['id'] or word in t['id']]
            if not batch:
                raise SystemExit(f"No test, tier or word matches '{word}'. Try scripts/test.sh --list.")
        for test in batch:
            if test['id'] not in seen:
                seen.add(test['id'])
                chosen.append(test)
    return sorted(chosen, key=lambda t: -t.get('est', 1))


def godot_bin():
    return os.environ.get('GODOT_BIN', 'godot')


def env():
    result = dict(os.environ)
    result.setdefault('ROOTWARD_SANDBOX_RUNTIME', str(ROOT / 'sandbox/runtime'))
    result['VOXEL_LAB_FRESH'] = '1'
    return result


def import_needed():
    if not STAMP.exists():
        return True
    stamp = STAMP.stat().st_mtime
    roots = ['assets', 'app', 'core', 'scenes', 'ui', 'art', 'pipeline', 'sandbox', 'test', 'tools', 'content']
    skip = {'source', 'runtime', 'runtime-windows', '__pycache__'}
    for top in roots:
        for base, dirs, files in os.walk(ROOT / top):
            dirs[:] = [d for d in dirs if d not in skip]
            for name in files:
                if name.endswith(('.json', '.gd', '.gdshader', '.tscn', '.tres', '.glb', '.png', '.import', '.cfg')):
                    if os.stat(os.path.join(base, name)).st_mtime > stamp:
                        return True
    return (ROOT / 'project.godot').stat().st_mtime > stamp


def run_import():
    CACHE.mkdir(exist_ok=True)
    started = time.time()
    subprocess.run([godot_bin(), '--headless', '--editor', '--path', str(ROOT), '--import', '--quit'],
                   stdout=(CACHE / 'import.log').open('w'), stderr=subprocess.STDOUT, check=False, cwd=ROOT)
    STAMP.write_text(str(time.time()))
    return time.time() - started


def command(test):
    if test.get('kind') == 'python':
        # The ground art check needs Pillow, which the system interpreter carries.
        art = '/usr/bin/python3' if Path('/usr/bin/python3').exists() else sys.executable
        python = os.environ.get('ART_PYTHON', art) if test['id'] == 'ground_art' else sys.executable
        return [python, str(ROOT / test['file'])]
    return [godot_bin(), '--headless', '--path', str(ROOT), '-s', 'res://' + test['file']]


def summary_line(output):
    for line in reversed(output.splitlines()):
        if re.search(r'checks|passed|OK$', line) and 'FAIL' not in line:
            return line.strip()[:100]
    return ''


def run_one(test):
    started = time.time()
    try:
        done = subprocess.run(command(test), cwd=ROOT, env=env(), stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=900)
        output = done.stdout + done.stderr
        code = done.returncode
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or '') + (error.stderr or '') + '\nTIMED OUT after 900 s'
        code = 124
    if code == 0 and 'SCRIPT ERROR' in output:
        code = 3  # a script error hidden behind a passing exit is still a bug
    return {'id': test['id'], 'file': test['file'], 'code': code, 'seconds': round(time.time() - started, 1),
            'summary': summary_line(output), 'output': output}


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('words', nargs='*', help='tier (quick, flow, full), smoke, or test ids / parts of ids')
    parser.add_argument('-j', '--jobs', type=int, default=0)
    parser.add_argument('--serial', action='store_true')
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--no-import', action='store_true')
    options = parser.parse_args()
    data = load()
    problems = check_manifest(data)
    if options.check or problems:
        for problem in problems:
            print('MANIFEST:', problem)
        if options.check:
            print('Test manifest: %d tests, %d problems.' % (len(data['tests']), len(problems)))
        if problems:
            raise SystemExit(1)
        if options.check:
            return
    if options.list:
        for tier in ORDER:
            print(f"\n{tier}: {data['tiers'][tier]}")
            for test in data['tests']:
                if test['tier'] == tier:
                    print(f"  {test['id']:20s} ~{test.get('est', 1):3d}s  {test['what']}")
        print(f"\nsmoke: scripts/test.sh smoke  (test/{data['smoke']}.gd)")
        return
    chosen = select(data, options.words)
    if not options.no_import and any(t.get('kind') != 'python' for t in chosen):
        if import_needed():
            print('Importing changed resources...', end=' ', flush=True)
            print('%.0f s' % run_import())
    jobs = 1 if options.serial else (options.jobs or max(1, min(8, (os.cpu_count() or 4) // 2)))
    print(f'Running {len(chosen)} tests, {jobs} at a time.')
    started = time.time()
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for result in pool.map(run_one, chosen):
            results.append(result)
            mark = ' ok ' if result['code'] == 0 else 'FAIL'
            print(f"[{mark}] {result['id']:20s} {result['seconds']:5.1f}s  {result['summary']}", flush=True)
            if options.verbose and result['code'] == 0:
                print(result['output'].rstrip())
    failed = [r for r in results if r['code'] != 0]
    for result in failed:
        print(f"\n--- {result['id']} ({result['file']}) exited {result['code']} ---")
        lines = [l for l in result['output'].splitlines() if l.strip() and not l.startswith('Godot Engine')]
        print('\n'.join(lines[-40:]))
    CACHE.mkdir(exist_ok=True)
    (CACHE / 'test-report.json').write_text(json.dumps([{k: v for k, v in r.items() if k != 'output'} for r in results], indent=1))
    wall = time.time() - started
    print(f"\n{len(results) - len(failed)} of {len(results)} passed in {wall:.0f} s (serial cost {sum(r['seconds'] for r in results):.0f} s)."
          + (f"  Failed: {', '.join(r['id'] for r in failed)}" if failed else ''))
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
