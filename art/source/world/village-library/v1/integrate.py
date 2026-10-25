"""One-time library registration using the existing Blender→Godot world-art build, one id at a time.

Run from the repository root with explicit ids (or --all). Existing .blend files are never regenerated.
Rebuilding one adopted object afterwards is simply: scripts/world-art.sh build <id>.
"""
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
specs = json.loads((HERE / 'library.json').read_text())['assets']
requested = sys.argv[1:]
if not requested:
    raise SystemExit('Pass explicit hollow-<id> ids or --all.')
wanted = specs if requested == ['--all'] else [s for s in specs if s['id'] in requested]
if requested != ['--all'] and len(wanted) != len(set(requested)):
    raise SystemExit('Unknown requested asset id.')
blender = os.environ.get('BLENDER_BIN', '/home/joejin/blender/blender')
categories = {
    'furniture':('Furniture','Carved cottage furniture and useful household pieces'),
    'workshop':('Workshop','Tools, craft benches and working machines'),
    'market':('Market','Food counters, wagons and household wares'),
    'garden':('Garden','Garden, farmyard and animal shelters'),
    'village-magic':('Village & Magic','Lanterns, village mechanisms and restrained magic'),
}
for spec in wanted:
    id = spec['id']
    source = ROOT / 'art/source/world' / id / 'v1/model.blend'
    if not source.exists() and id in json.loads((ROOT/'pipeline/world-catalog.json').read_text())['assets']:
        raise RuntimeError('Registered editable source is missing; restore it instead of regenerating: '+id)
    if not source.exists():
        subprocess.run([blender,'--background','--factory-startup','--python-exit-code','1','--python',str(HERE/'author.py'),'--',id],cwd=ROOT,check=True)
    # Re-read shared catalogs before each mutation; retain every unrelated entry and field.
    catalog_path = ROOT/'pipeline/world-catalog.json'
    catalog = json.loads(catalog_path.read_text())
    record = {
        'version':'v1','authority':'blender','status':'builder_library', 'label':spec['title'],
        'source':str(source.relative_to(ROOT)), 'runtime':f'assets/world/{id}/model.glb',
        'pivot':'Ground centre; front +Z in Godot; one metre per cell',
        'logical_footprint':[-spec['width']/2,-spec['depth']/2,spec['width'],spec['depth']],
        'behavior':'Interactive prop; boolean active state, static ground footprint' if spec['interaction'] else 'Static decorative prop; catalog footprint blocks movement',
        'notes':spec['blurb'], 'library':'village-library-v1',
        'interaction':spec['interaction'],
    }
    if id in catalog['assets']:
        if catalog['assets'][id] != record:
            raise RuntimeError('Catalog entry was edited; preserve it and integrate deliberately: '+id)
    else:
        catalog['assets'][id]=record
        catalog_path.write_text(json.dumps(catalog,indent=2,ensure_ascii=False)+'\n')
    subprocess.run([str(ROOT/'scripts/world-art.sh'),'build',id],cwd=ROOT,check=True)
    build_path=ROOT/'content/build/catalog.json'
    build=json.loads(build_path.read_text())
    category=spec['category']
    if not any(c['id']==category for c in build['categories']):
        title,blurb=categories[category]
        build['categories'].append({'id':category,'title':title,'blurb':blurb})
    item={'id':id,'category':category,'kind':'prop','asset':id,'title':spec['title'],
          'blurb':spec['blurb'],'audience':'studio'}
    existing=next((i for i in build['items'] if i['id']==id),None)
    if existing is not None and existing != item:
        raise RuntimeError('Builder entry was edited; preserve it: '+id)
    if existing is None:
        build['items'].append(item)
        build_path.write_text(json.dumps(build,indent=2,ensure_ascii=False)+'\n')
    print(f"LIBRARY READY {spec['number']:02d}/50: {id}",flush=True)
