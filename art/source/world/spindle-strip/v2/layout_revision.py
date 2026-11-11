from pathlib import Path
import json,shutil
root=Path.cwd();path=root/'content/areas/haverlund-square.json';doc=json.loads(path.read_text())
assert doc['version']==6
shutil.copy2(path,root/'content/areas/archive/haverlund-square-v6.json')
def shift(v):
 if isinstance(v,dict):
  for k,x in v.items():
   if k in ['at','spawn','stand','approach','exit','rect'] and isinstance(x,list) and x and isinstance(x[0],(float,int)):x[0]+=16
   elif k in ['cells','route','exit_posts'] and isinstance(x,list):
    for p in x:
     if isinstance(p,list) and p and isinstance(p[0],(float,int)):p[0]+=16
   elif k not in ['arrival','arrivals']:shift(x)
 elif isinstance(v,list):
  for x in v:shift(x)
shift(doc)
doc['size'][0]+=16;doc['version']=7;doc['spawn']=[13,12];doc['interior']['exit']=[12,12]
# Expanded in-bounds shelf; the original square and descending stair bay retain their levels.
for n,(terrain,levels) in enumerate(zip(doc['terrain'],doc['levels'])):
 y=63-n;prefix='.'*16 if y<55 else '#'*16
 t=list(prefix+terrain);l=list(('2'*16 if y<55 else '0'*16)+levels)
 for x in range(28):
  if y<55 and (x<22 or y>=10):
   l[x]='2';t[x]='.'
   if (10<=y<=14) or (17<=x<=19 and y>=15):t[x]='='
   if x<16 and any(a<=y<=b for a,b in [(16,23),(26,34),(37,43),(46,51)]) and x>=10:t[x]='='
 doc['terrain'][n]=''.join(t);doc['levels'][n]=''.join(l)
up=next(x for x in doc['interior']['links'] if x['id']=='uphill')
for k in ['at','approach']:up[k][0]-=4
for p in up['cells']:p[0]-=4
# Promote the park and upper barriers to the existing saved prop system.
promote=lambda a:a['id'].startswith(('spindle-park-','strip-edge-','park-view-','park-east-','strip-stair-','strip-planter-','strip-bench-','strip-cypress-'))
assets=doc['interior']['assets'];editable=[a for a in assets if promote(a)]
doc['interior']['assets']=[a for a in assets if not promote(a)]
for a in editable:
 doc['props'].append({'id':a['id'],'asset':a['asset'],'at':a['at'],'facing':{0:'S',90:'E',180:'N',270:'W'}[int(a.get('turn',0))%360],'scale':a.get('scale',1)})
# Furniture collision rows match these props by old centers; remove only promoted rows.
centers={tuple(a['at']) for a in editable}
doc['interior']['furniture']=[f for f in doc['interior']['furniture'] if tuple(f['at']) not in centers]
# Park perimeter now belongs to the outer flat park, not the obsolete 6-cell garden.
for a in doc['props']:
 if a['id'].startswith('park-view-'):a['at'][0]-=10
 if a['id'].startswith('park-east-'):a['at'][0]=21.25
 if a['id'].startswith('strip-edge-'):a['at'][0]=27.25
 if a['id'].startswith('strip-stair-') and a['at'][0]>27.25:a['at'][0]=27.25
 if a['at'][1]<.15:a['at'][1]=.15
# Keep edit bounds half a cell outside centers, inset enough for the existing prop clearance rules.
items=['lane-tree','lane-cypress','lane-bench','lane-planter','town-fountain','town-railing','town-railing-short','town-railing-post','town-garden-wall','town-garden-wall-short','town-garden-pier','town-balustrade','town-balustrade-pier','town-retaining-wall']
doc['interior']['layout']={'rect':[0,0,28,55],'items':items,'export':'content/development/layouts/haverlund-square.json'}
doc['interior']['map_offset']=[16,0]
for z in doc['zones']:
 if z['id']=='spindle-park':z['rect']=[0,0,22,10]
 if z['id']=='spindle-strip':z['rect']=[0,10,28,45]
 if z['id']=='rootward-square':z['rect']=[0,0,88,64]
path.write_text(json.dumps(doc,indent=2)+'\n')
# Other rooms keep their own coordinates; only their destination in square moves.
for p in (root/'content/areas').glob('*.json'):
 if p==path:continue
 d=json.loads(p.read_text());changed=False
 for link in d.get('interior',{}).get('links',[]):
  if link.get('to')!='haverlund-square':continue
  link['arrival'][0]+=16
  for a in link.get('arrivals',[]):a[0]+=16
  if d['id']=='haverlund-lane':
   link['arrival'][0]-=4
   for a in link.get('arrivals',[]):a[0]-=4
  changed=True
 if changed:p.write_text(json.dumps(d,indent=2)+'\n')
p=root/'content/development/spindle-strip-plan.json';d=json.loads(p.read_text());shift(d);d['arrival']=[13,12];d['park']=[0,0,22,10];d['promenade']=[16,10,12,45];d['status']='editable_flat_layout_concepts_pending';p.write_text(json.dumps(d,indent=2)+'\n')
p=root/'pipeline/world-catalog.json';d=json.loads(p.read_text());e=d['assets']['haverlund-square-ground'];e['version']=4;e['source']='art/source/world/haverlund-square-ground/v4/model.blend'
feet={'lane-tree':[-.45,-.45,.9,.9],'lane-cypress':[-.35,-.35,.7,.7],'lane-bench':[-.85,-.33,1.7,.66],'lane-planter':[-.667,-.4,1.334,.8],'town-fountain':[-.645,-.645,1.29,1.29]}
for k,fp in feet.items():d['assets'][k]['logical_footprint']=fp
p.write_text(json.dumps(d,indent=2)+'\n')
p=root/'content/build/catalog.json';d=json.loads(p.read_text())
for k,title in [('lane-tree','Town garden tree'),('lane-cypress','Town cypress'),('lane-bench','Town park bench'),('lane-planter','Town planter'),('town-fountain','Town fountain')]:
 if not any(a['id']==k for a in d['items']):d['items'].append({'id':k,'category':'garden','kind':'prop','asset':k,'title':title,'blurb':'Place, move or turn this park piece. Its footprint blocks passage.','audience':'studio'})
p.write_text(json.dumps(d,indent=2)+'\n')
# Sparks exposes only explicitly configured layout areas; other rooms retain their current build behavior.
p=root/'content/levels/catalog.json';d=json.loads(p.read_text());next(a for a in d['levels'] if a['id']=='sparks-and-machines')['build_areas']=['haverlund-square'];p.write_text(json.dumps(d,indent=2)+'\n')
p=root/'content/development/sparks-checkpoints.json';d=json.loads(p.read_text())
for c in d['checkpoints'].values():
 if c['area']=='haverlund-square' and 'at' in c:c['at'][0]+=16
p.write_text(json.dumps(d,indent=2)+'\n')
print('Prepared version 7; promoted',len(editable),'editable props')
