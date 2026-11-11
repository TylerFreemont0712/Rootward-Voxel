"""Read-only asset/evidence checks; writes the current review's validation record.
Run from the project root after the complete scripts/test.sh suite.
"""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path): return json.loads(path.read_text())

catalog = read(ROOT / 'pipeline/world-catalog.json')['assets']
pack = read(ROOT / 'pipeline/art-catalog.json')['world']['source_packs']['sparks_loft']
prompts = read(HERE / 'prompts.json')
paintings = []
selected = {}
for item in prompts['images']:
    path = HERE / item['file']
    assert sha(path) == item['sha256'], path
    with Image.open(path) as im:
        im.verify()
    with Image.open(path) as im:
        assert list(im.size) == item['size'] == [1536, 1024]
        pixels = hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()
    for name, digest in item['input_sha256'].items(): assert sha(ROOT / name) == digest
    paintings.append({'file':item['file'], 'sha256':item['sha256'], 'rgba_sha256':pixels})
    if item['file'] in prompts['selected_surfaces'].values(): selected[pixels] = item['file']
assert len(paintings) == 6 and len(selected) == 5

assets = []
for name in ['loft-shell'] + pack['assets']:
    entry = catalog[name]
    manifest = read((ROOT / entry['runtime']).with_name('manifest.json'))
    assert sha(ROOT / entry['source']) == manifest['source_sha256'], name
    assert sha(ROOT / entry['runtime']) == manifest['runtime_sha256'], name
    assert entry['authority'] == 'blender' and entry['illustrated_edges']
    for mat in manifest['audit']['material_records'].values():
        assert not mat['texture_rgba_sha256'] or mat['texture_rgba_sha256'] in selected
    assets.append({'id':name, 'source_sha256':manifest['source_sha256'],
                   'runtime_sha256':manifest['runtime_sha256'], 'audit':manifest['audit']})

revision = read(HERE / 'marked-review.json')
finishes = {x['asset']: x for x in read(HERE / 'finish_marked_review.json')}
expected_sources = {}
for item in revision['sources']:
    assert sha(ROOT / item['backup']) == item['before']
    expected = item['after']
    if item['asset'] in finishes:
        finish = finishes[item['asset']]
        assert finish['before'] == expected
        expected = finish['after']
    expected_sources[item['asset']] = expected
lived = read(HERE / 'lived-in-revision.json')
for item in lived['sources']:
    assert sha(ROOT / item['backup']) == item['before']
    if item['asset'] in expected_sources: assert item['before'] == expected_sources[item['asset']]
    expected_sources[item['asset']] = item['after']
linen = read(HERE / 'lived_in_linen_finish.json')
assert linen['before'] == expected_sources['loft-bed']
expected_sources['loft-bed'] = linen['after']
for name, expected in expected_sources.items():
    assert next(x for x in assets if x['id'] == name)['source_sha256'] == expected
proof = read(HERE / 'rebuild-proof.json')
bed = next(x for x in assets if x['id'] == 'loft-bed')
assert proof['source_sha256'] == bed['source_sha256']
assert proof['runtime_sha256'] == bed['runtime_sha256'] and all(proof['unchanged'].values())
original = read(ROOT / 'art/source/world/loft-shell/v1/furnishing-revision.json')
assert sha(ROOT / 'art/source/world/loft-shell/v1' / original['preserved_source']) == original['source_before_sha256']
concept = ROOT / 'docs/concept/v0.7/art'
approved = [x for x in read(concept / 'prompts.json')['images'] if x['status'] == 'approved']
for item in approved: assert sha(concept / item['file']) == item['sha256']

captures = []
for path in sorted((ROOT / 'evidence/sparks-loft/lived-in').glob('*.png')):
    with Image.open(path) as im: im.verify()
    with Image.open(path) as im: size = list(im.size)
    assert size in [[1600, 1000], [1280, 720]]
    captures.append({'file':str(path.relative_to(ROOT)), 'size':size, 'sha256':sha(path)})
assert len(captures) == 10
docs = ['README.md', 'docs/PROJECT_HANDOFF.md', 'pipeline/README.md', 'pipeline/UI.md',
        'docs/concept/v0.7/README.md', 'docs/concept/v0.7/05-scenario.md',
        'pipeline/reviews/2026-10-27-loft-lived-in-and-stairs.md',
        'art/source/world/sparks-loft/v1/README.md']
links = 0
for name in docs:
    path = ROOT / name
    for target in re.findall(r'\]\(([^)]+)\)', path.read_text()):
        target = target.split('#', 1)[0].strip('<>')
        if not target or '://' in target: continue
        assert (path.parent / target).resolve().exists(), (name, target)
        links += 1
log = (ROOT / '.cache/sparks-loft-tests.log').read_text()
assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:', log)
full_journey = int(re.search(r'Sparks & Machines journey: (\d+) checks passed\.', log)[1])
assert full_journey >= 65
assert 'World art, area views and projected facing: 577 checks passed.' in log
assert 'Ground art handoff: 121 checks passed.' in log
for size in (1600, 1280):
    review_log = (ROOT / f'.cache/loft-lived-{size}.log').read_text()
    assert 'Sparks & Machines journey: 69 checks passed.' in review_log
    assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:', review_log)
result = {'date':'2026-10-27', 'revision':'lived-in room, a quiet week and descending stairs', 'result':'pass',
    'audited_models':len(assets), 'preserved_previous_masters':len(revision['sources'])+len(lived['sources']),
    'original_concepts_preserved':len(approved), 'painted_outputs_unchanged':len(paintings),
    'local_links_checked':links, 'unedited_bed_rebuild_identical':True,
    'checks':{'full_project_suite':'pass; no script errors or failed checks',
              'full_suite_journey_checks':full_journey, 'final_journey_integration':69,
              'world_art':577, 'review_sizes':[[1600,1000],[1280,720]]},
    'paintings':paintings, 'assets':assets, 'evidence':captures}
(HERE / 'validation.json').write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ('paintings','assets','evidence')}, indent=2))
