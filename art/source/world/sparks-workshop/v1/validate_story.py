"""Read-only first-jobs handoff checks; writes the current validation record."""
from pathlib import Path
import hashlib,json,re
from PIL import Image
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

catalog=read(ROOT/'pipeline/world-catalog.json')['assets']
ids=read(HERE/'assets.json')
assert len(ids)==21 and ids==read(ROOT/'pipeline/art-catalog.json')['world']['source_packs']['sparks_workshop']['assets']
assets=[]
for id in ids:
    entry=catalog[id];manifest=read((ROOT/entry['runtime']).with_name('manifest.json'))
    assert sha(ROOT/entry['source'])==manifest['source_sha256'],id
    assert sha(ROOT/entry['runtime'])==manifest['runtime_sha256'],id
    assert entry['authority']=='blender' and entry['illustrated_edges']
    assets.append({'id':id,'source_sha256':manifest['source_sha256'],'runtime_sha256':manifest['runtime_sha256'],'audit':manifest['audit']})
previous=read(HERE/'validation.json')
for asset in previous['assets']:
    current=next(a for a in assets if a['id']==asset['id'])
    assert current['source_sha256']==asset['source_sha256'] and current['runtime_sha256']==asset['runtime_sha256']
new=read(ROOT/'art/source/world/workshop-stair-lamp/v1/provenance.json')
assert sha(ROOT/new['record'])==new['record_sha256']
removal=read(ROOT/'art/source/world/sparks-loft/v1/sill-plant-removal.json')
assert sha(ROOT/removal['backup'])==removal['before']
assert sha(ROOT/catalog[removal['asset']]['source'])==removal['after']
loft=read(ROOT/'art/source/world/sparks-loft/v1/validation.json')
for asset in loft['assets']:
    if asset['id']==removal['asset']:
        assert asset['source_sha256']==removal['before']
    else:
        assert sha(ROOT/catalog[asset['id']]['source'])==asset['source_sha256'],asset['id']
        assert sha(ROOT/catalog[asset['id']]['runtime'])==asset['runtime_sha256'],asset['id']
plant=read((ROOT/catalog[removal['asset']]['runtime']).with_name('manifest.json'))
assert plant['source_sha256']==removal['after']
assert not any('leaf' in m or 'soil' in m for m in plant['audit']['material_records'])

prompts=read(HERE/'prompts.json');paintings=[]
for image in prompts['images']:
    assert sha(HERE/image['file'])==image['sha256']
    paintings.append({'file':image['file'],'sha256':image['sha256']})
for file,digest in prompts['reused_surfaces'].items():
    assert sha(ROOT/file)==digest
    paintings.append({'file':file,'sha256':digest})

area=read(ROOT/'content/areas/workshop-floor.json')
quests=read(ROOT/'content/areas/workshop-floor.quests.json')['quests']
story=read(ROOT/'content/journeys/sparks-and-machines.json')
assert len(area['interior']['assets'])==27 and len(area['interior']['lamp_fixtures'])==len(area['lamps'])==3
assert [q['id'] for q in quests]==['say-hello','waiting-ticket','landing-light','morning-round']
assert len(story['scenes'])==4
for scene in story['scenes'].values():
    assert scene.get('requires','say-hello') in [q['id'] for q in quests]
    assert all(id in [lamp['id'] for lamp in area['lamps']] for id in scene.get('lamps_on',[]))
prose=[{'file':name,'sha256':sha(ROOT/name)} for name in ['content/journeys/sparks-and-machines.json','content/areas/workshop-floor.quests.json','content/areas/workshop-floor.json']]

log=(ROOT/'.cache/workshop-first-jobs-tests.log').read_text()
assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:',log)
suite={name:int(n) for name,n in re.findall(r'([^\n]+?): (\d+) checks passed',log)}
assert len(suite)>=35 and suite.get('Sparks & Machines journey',0)>=70 and suite.get('Workshop story and quests',0)>=49
assert 'Ground art handoff: 121 checks passed.' in log
captures=[]
for width,height in [(1600,1000),(1280,720)]:
    log=(ROOT/f'.cache/workshop-quests-{width}.log').read_text()
    assert 'Workshop story and quests: 52 checks passed.' in log
    assert not re.search(r'SCRIPT ERROR|ERROR:|FAIL:',log)
    files=sorted((ROOT/f'evidence/sparks-workshop/first-jobs/{width}').glob('*.png'))
    assert len(files)==7
    for file in files:
        with Image.open(file) as im:assert im.size==(width,height)
        captures.append({'file':str(file.relative_to(ROOT)),'size':[width,height],'sha256':sha(file)})

documents=['README.md','docs/PROJECT_HANDOFF.md','pipeline/README.md','pipeline/UI.md',
    'docs/concept/v0.7/README.md','docs/concept/v0.7/05-scenario.md','docs/concept/v0.7/07-dialogue.md','docs/concept/v0.7/08-quests.md',
    'pipeline/reviews/2026-10-27-workshop-first-jobs.md','art/source/world/sparks-loft/v1/README.md','art/source/world/sparks-workshop/v1/README.md']
links=0
for name in documents:
    path=ROOT/name
    for target in re.findall(r'\]\(([^)]+)\)',path.read_text()):
        target=target.split('#',1)[0].strip('<>')
        if not target or '://' in target:continue
        target=(path.parent/target).resolve()
        if target!=HERE/'story-validation.json':assert target.exists(),(name,target)
        links+=1
result={'date':'2026-10-27','result':'pass','revision':'First workshop jobs, quieter prose and clear loft sill',
    'audited_workshop_models':len(assets),'unchanged_previous_workshop_models':len(previous['assets']),
    'unchanged_other_loft_models':len(loft['assets'])-1,'preserved_window_master':removal,
    'story_scenes':4,'story_pages':sum(len(s['pages']) for s in story['scenes'].values()),
    'reply_choices':sum(len(p.get('choices',[])) for s in story['scenes'].values() for p in s['pages']),
    'checks':{'full_project_suite':'pass; no script errors or failed checks','suite_counts':suite,
        'windowed_story':52,'review_sizes':[[1600,1000],[1280,720]],'local_links':links},
    'prose':prose,'paintings':paintings,'assets':assets,'evidence':captures}
(HERE/'story-validation.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k not in ['assets','evidence','paintings']},indent=2))
