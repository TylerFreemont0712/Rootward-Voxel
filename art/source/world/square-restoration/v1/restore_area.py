"""One-time deliberate restoration, not a generator for the current area master."""
from pathlib import Path
import copy,json,subprocess,shutil
ROOT=Path(__file__).resolve().parents[5]
def read(p):return json.loads((ROOT/p).read_text())
def write(p,d):(ROOT/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
path='content/areas/haverlund-square.json';current=read('content/areas/archive/haverlund-square-v7.json')
assert read(path)['version']==7,'Already restored; edit the current area document directly.'
doc=read('content/areas/archive/haverlund-square-v6.json')
original=json.loads(subprocess.check_output(['git','show','HEAD:content/areas/haverlund-square.json'],cwd=ROOT))
def shift(v):
 if isinstance(v,dict):
  for k,x in v.items():
   if k in ['at','spawn','stand','approach','exit','rect'] and isinstance(x,list) and x and isinstance(x[0],(int,float)):x[0]+=16
   elif k in ['cells','route','exit_posts'] and isinstance(x,list):
    for p in x:
     if isinstance(p,list) and p:p[0]+=16
   elif k not in ['arrival','arrivals']:shift(x)
 elif isinstance(v,list):
  for x in v:shift(x)
shift(doc);doc['size']=[88,64];doc['version']=8;doc['spawn']=[17,8]
doc['terrain']=['#'*16+r for r in doc['terrain']]
doc['levels']=['0'*16+r for r in doc['levels']]
room=doc['interior'];room['map_offset']=[16,0];room['exit']=[12,12];doc['spawn']=[13,12]
# Keep the four-cell loading extension on the existing incoming landing.
for y in range(6,15):
 row=list(doc['terrain'][63-y]);lev=list(doc['levels'][63-y])
 for x in range(4,16):row[x]='=';lev[x]='2'
 doc['terrain'][63-y]=''.join(row);doc['levels'][63-y]=''.join(lev)
room['assets']=[a for a in room['assets'] if float(a.get('height',0))>=0 and not a['id'].startswith('lower-tree-')]
clock=copy.deepcopy(next(a for a in current['interior']['assets'] if a['id']=='clockmaker'))
clock.update(at=[12.5,20],height=2.16);room['assets'].append(clock)
room['links']=[a for a in room['links'] if a['id'] not in ['clockmaker','apothecary']]
room['links'].append({'id':'clockmaker','at':[17,21],'approach':[17,21],'direction':'W','to':'shop-clockmaker','arrival':[6,0],'facing':'N','label':'Enter Pendulum & Pin','walk_through':True,'enter':2,'doors':'clockmaker'})
for a in room['links']:
 if a['id']=='uphill':
  a.update(at=[12,12],approach=[12,12],cells=[[12,y] for y in range(10,15)])
room['lamp_fixtures']=[a for a in room['lamp_fixtures'] if a['asset']!='apothecary']
room['lamp_fixtures'].append({'id':'clockmaker-window-lamp','asset':'clockmaker','range':4.3,'energy':.65})
doc['lamps']=[a for a in doc['lamps'] if a['id']!='apothecary-window-lamp']
doc['lamps'].append({'id':'clockmaker-window-lamp','at':[15.2,21],'stand':[17,21],'zone':'spindle-strip','style':'fixture','automatic':True,'requires':'field-tablet'})
for a in doc['lamps']:
 if a['id']=='clockmaker-window-lamp':a.update(at=[15.2,21],stand=[17,21],zone='spindle-strip',automatic=True)
for a in room['lamp_fixtures']:
 if a['id']=='clockmaker-window-lamp':a.update(range=4.3,energy=.65)
doc['zones']=[z for z in doc['zones'] if z['id'] not in ['spindle-strip','spindle-park']]
doc['zones'].insert(0,{'id':'spindle-strip','title':'Spindle Walk','rect':[16,11,12,44]})
for z in doc['zones']:
 if z['id']=='rootward-square':z['rect']=[0,0,88,64]
# Return editable park/barrier pieces to their pre-flat positions.
promote=lambda a:a['id'].startswith(('spindle-park-','strip-edge-','park-view-','park-east-','strip-stair-','strip-planter-','strip-bench-','strip-cypress-'))
editable=[a for a in room['assets'] if promote(a)]
room['assets']=[a for a in room['assets'] if not promote(a)]
centers={tuple(a['at']) for a in editable}
room['furniture']=[a for a in room['furniture'] if tuple(a['at']) not in centers]
for a in editable:
 at=a['at'];at[1]=max(.15,at[1])
 if at[0]<4:at[0]=4
 doc['props'].append({'id':a['id'],'asset':a['asset'],'at':at,'facing':{0:'S',90:'E',180:'N',270:'W'}[int(a.get('turn',0))%360],'scale':a.get('scale',1)})
# Keep layout tools on the existing upper ground, and preserve old player sketches in saved metadata.
room['layout']=copy.deepcopy(current['interior']['layout']);room['layout']['rect']=[4,0,24,55]
room['layout_epoch']=8
room['depth_fog']={'height':-3.0,'size':320,'day':'aebbc0','night':'08121c'}
write(path,doc)
for p in (ROOT/'content/areas').glob('*.json'):
 if p.name=='haverlund-square.json':continue
 d=json.loads(p.read_text());changed=False
 for link in d.get('interior',{}).get('links',[]):
  if link.get('to')!='haverlund-square':continue
  if d['id']=='haverlund-lane':link.update(arrival=[13,12],arrivals=[[13,11],[13,11],[13,12],[13,13],[13,13]])
  if d['id']=='shop-clockmaker':link.update(arrival=[17,21],facing='E')
  changed=True
 if changed:p.write_text(json.dumps(d,indent=2)+'\n')
catalog=read('pipeline/world-catalog.json');entry=catalog['assets']['haverlund-square-ground'];entry.update(version=5,source='art/source/world/haverlund-square-ground/v5/model.blend')
catalog['assets']['haverlund-clockmaker'].update(version=4,source='art/source/world/haverlund-clockmaker/v4/model.blend')
write('pipeline/world-catalog.json',catalog)
print('Restored pre-flat terrain document, four-wide stairs and upper route; retained logical offset.')
