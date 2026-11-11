"""Verify the current workshop handoff after tests and native windowed captures."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
def read(path):return json.loads(path.read_text())
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

catalog=read(ROOT/'pipeline/world-catalog.json')['assets']
pack=read(ROOT/'pipeline/art-catalog.json')['world']['source_packs']['sparks_workshop']
ids=read(HERE/'assets.json')
assert pack['assets']==ids and len(ids)==20
prompts=read(HERE/'prompts.json')
paintings=[];texture_hashes=set()
for item in prompts['images']:
    path=HERE/item['file'];assert sha(path)==item['sha256']
    with Image.open(path) as im:
        assert list(im.size)==item['size']==[1536,1024]
        texture_hashes.add(hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest())
    paintings.append({'file':str(path.relative_to(ROOT)),'sha256':sha(path)})
for name,digest in prompts['reused_surfaces'].items():
    path=ROOT/name;assert sha(path)==digest
    with Image.open(path) as im:texture_hashes.add(hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest())
    paintings.append({'file':name,'sha256':digest})

assets=[]
for asset in ids:
    entry=catalog[asset]
    manifest=read((ROOT/entry['runtime']).with_name('manifest.json'))
    assert entry['authority']=='blender' and entry['illustrated_edges']
    assert sha(ROOT/entry['source'])==manifest['source_sha256'],asset
    assert sha(ROOT/entry['runtime'])==manifest['runtime_sha256'],asset
    for mat in manifest['audit']['material_records'].values():
        assert not mat['texture_rgba_sha256'] or mat['texture_rgba_sha256'] in texture_hashes,(asset,mat)
    assets.append({'id':asset,'source_sha256':manifest['source_sha256'],'runtime_sha256':manifest['runtime_sha256'],'audit':manifest['audit']})
    provenance=read((ROOT/entry['source']).with_name('provenance.json'))
    assert sha(ROOT/provenance['record'])==provenance['record_sha256'],asset

expected={};backups=0
for name in ['gameplay-review.json','textile-finish.json','rug_surface_finish.json','user-touchups.json','interior-floor-finish.json','cushion-clearance-finish.json']:
    record=read(HERE/name)
    for item in record.get('sources',[record]):
        if item['asset'] in expected:assert expected[item['asset']]==item['before'],name
        expected[item['asset']]=item['after']
        if 'backup' in item:
            assert sha(ROOT/item['backup'])==item['before'];backups+=1
for asset,digest in expected.items():assert sha(ROOT/catalog[asset]['source'])==digest,asset
proof=read(HERE/'rebuild-proof.json')
assert all(proof['unchanged'].values())
stairs=next(a for a in assets if a['id']==proof['asset'])
assert stairs['source_sha256']==proof['source_sha256'] and stairs['runtime_sha256']==proof['runtime_sha256']
loft=read(ROOT/'art/source/world/sparks-loft/v1/validation.json')
for asset in loft['assets']:
    assert sha(ROOT/catalog[asset['id']]['source'])==asset['source_sha256'],asset['id']
    assert sha(ROOT/catalog[asset['id']]['runtime'])==asset['runtime_sha256'],asset['id']
geometry=read(HERE/'geometry-validation.json')
assert geometry['throw_upholstery_intersections']==geometry['cushion_upholstery_intersections']==geometry['throw_cushion_intersections']==0
assert geometry['white_coverings_removed']==3 and geometry['crock_floor_normal'][2]>.9

log=(ROOT/'.cache/sparks-loft-tests.log').read_text()
assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:',log)
suite=re.findall(r'([^\n]+?): (\d+) checks passed',log)
assert len(suite)>=30 and 'Ground art handoff: 121 checks passed.' in log
assert int(re.search(r'Downstairs workshop: (\d+) checks passed',log)[1])>=75
captures=[]
for width,height in [(1600,1000),(1280,720)]:
    log=(ROOT/f'.cache/workshop-{width}.log').read_text()
    assert 'Downstairs workshop: 75 checks passed.' in log
    assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:',log)
    paths=sorted((ROOT/f'evidence/sparks-workshop/{width}').glob('*.png'))
    assert len(paths)==7
    for path in paths:
        with Image.open(path) as im:assert im.size==(width,height)
        captures.append({'file':str(path.relative_to(ROOT)),'size':[width,height],'sha256':sha(path)})

documents=['README.md','docs/PROJECT_HANDOFF.md','pipeline/README.md','pipeline/UI.md',
    'docs/concept/v0.7/README.md','docs/concept/v0.7/05-scenario.md','docs/concept/v0.7/07-dialogue.md',
    'pipeline/reviews/2026-10-27-workshop-floor.md','art/source/world/sparks-workshop/v1/README.md']
links=0
for name in documents:
    path=ROOT/name
    for target in re.findall(r'\]\(([^)]+)\)',path.read_text()):
        target=target.split('#',1)[0].strip('<>')
        if not target or '://' in target:continue
        resolved=(path.parent/target).resolve()
        if resolved!=HERE/'validation.json':assert resolved.exists(),(name,target)
        links+=1
result={'date':'2026-10-27','result':'pass','revision':'Connected workshop, smaller furniture and marked art touchups',
    'audited_models':len(assets),'placements':26,'preserved_previous_masters':backups,
    'preserved_loft_models':len(loft['assets']),'painted_outputs_unchanged':len(paintings),
    'local_document_links':links,'identical_staircase_rebuild':True,
    'checks':{'full_project_suite':'pass; no script errors or failed checks','suite_counts':{name:int(count) for name,count in suite},
        'windowed_workshop':75,'review_sizes':[[1600,1000],[1280,720]],'geometry':geometry},
    'paintings':paintings,'assets':assets,'evidence':captures}
(HERE/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['assets','paintings','evidence']},indent=2))
