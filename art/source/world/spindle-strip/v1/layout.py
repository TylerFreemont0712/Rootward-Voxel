"""Single authored layout revision. Run only against archived square v5; current documents own later edits."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[5]
def load(p):return json.loads((ROOT/p).read_text())
def save(p,d):(ROOT/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
p=load('content/areas/haverlund-square.json')
if p['version']!=5:raise RuntimeError('Already revised: edit the current area document.')
p['version']=6;p['spawn']=[1,12];r=p['interior']
# Retire the temporary twins; structural room identities remain in the saved journey catalog.
remove={'clockmaker','apothecary','bench-terrace-1','terrace-planter'}
remove.update(a['id'] for a in r['assets'] if a['id'].startswith('upper-park-'))
remove.update(a['id'] for a in r['assets'] if a['asset'].startswith('town-railing') and ((abs(a['at'][1]-5.65)<.02 and a['at'][0]<5.6) or (abs(a['at'][0]-11.65)<.02 and a['at'][1]>10)))
r['assets']=[a for a in r['assets'] if a['id'] not in remove]
r['furniture']=[a for a in r['furniture'] if not (a['at']==[4.0,.9] or a['at']==[1.0,4.6])]
# New larger west arrival: off the stair nosings, with a five-cell reciprocal loading boundary.
back=next(l for l in r['links'] if l['id']=='uphill')
back.update(at=[0,12],approach=[0,12],cells=[[0,y] for y in range(10,15)],arrivals=[[12,26],[12,26],[12,26],[13,26],[13,26]])
r['links']=[l for l in r['links'] if l['id'] not in ['clockmaker','apothecary']]
old_fittings={f['id'] for f in r['lamp_fixtures'] if f['asset'] in remove}
r['lamp_fixtures']=[f for f in r['lamp_fixtures'] if f['id'] not in old_fittings]
p['lamps']=[l for l in p['lamps'] if l['id'] not in old_fittings]
r['life']['smoke']=[s for s in r['life'].get('smoke',[]) if s['at']!=[3.6,23.1]]
grid=[list(row) for row in p['terrain']];levels=[list(row) for row in p['levels']]
def cell(x,y,mat,level):grid[-1-y][x]=mat;levels[-1-y][x]=str(level)
for y in range(0,6):
 for x in range(0,6):cell(x,y,'.' if x!=3 and y!=2 else '=',2)
for y in range(11,55):
 for x in range(0,12):cell(x,y,'=' if x>=5 or y<16 or y>=52 else '.',2)
# Generous paved court at the new arrival, then a continuous promenade along future active frontage.
for y in range(10,16):
 for x in range(0,12):cell(x,y,'=',2)
# Keep existing east-descending steps intact at y6..10. The extended landing joins from the north.
for s in p['stairs']:
 if s['at'][1]==10 and s['at'][0] in [6,11]:
  # y10 belongs to the extended landing, so this row no longer has a stair.
  pass
p['stairs']=[s for s in p['stairs'] if not (s['at'][1]==10 and s['at'][0] in [6,11])]
for y in range(16,52):
 for x in range(0,5):cell(x,y,'.',2)
p['terrain']=[''.join(row) for row in grid];p['levels']=[''.join(row) for row in levels]
# Frontage bands are design reservations, not invisible collision. Unbuilt ground remains walkable.
plots=[{'id':'clockmaker','label':'Pendulum & Pin','rect':[.0,16,5,8],'facing':'E','approach':[6,20],'concept':'art/source/world/spindle-strip/v1/clockmaker-concept.png'},
 {'id':'apothecary','label':'Thyme & Tonic','rect':[.0,26,5,9],'facing':'E','approach':[6,30],'concept':'art/source/world/spindle-strip/v1/apothecary-concept.png'},
 {'id':'future-shop-3','rect':[.0,37,5,7],'facing':'E','approach':[6,40]},
 {'id':'future-shop-4','rect':[.0,46,5,6],'facing':'E','approach':[6,49]}]
save('content/development/spindle-strip-plan.json',{'schema':1,'area':p['id'],'status':'layout_ready_building_concepts_for_review','arrival':[1,12],'promenade':[5,11,6,44],'park':[0,0,6,6],'frontages':plots})
# Real furnishings for the small public park and promenade only.
def put(id,asset,at,height=2,turn=0,scale=1,size=None):
 r['assets'].append({'id':id,'asset':asset,'at':at,'height':height,'turn':turn,'scale':scale})
 if size:r['furniture'].append({'kind':'bench' if 'bench' in id else 'counter','at':at,'size':size})
put('spindle-park-tree','lane-tree',[1.1,1.1],scale=.47,size=[.42,.42])
put('spindle-park-shrub','lane-planter',[4.2,4.6],turn=90,scale=.75,size=[.6,1.0])
put('spindle-park-bench','lane-bench',[2.5,.7],turn=180,size=[1.7,.66])
put('spindle-park-seat','lane-bench',[.7,4.0],turn=90,size=[.66,1.7])
put('spindle-park-birdbath','town-fountain',[2.0,3.8],scale=.35,size=[.45,.45])
for n,y in enumerate([17,25,36,45,52]):
 put('strip-planter-'+str(n),'lane-planter',[4.6,y],turn=90,scale=.75,size=[.6,1.0])
for n,y in enumerate([18,35,50]):
 put('strip-lamp-'+str(n),'square-banner-lamp',[9.5,y],turn=180,size=[.5,.5])
 fid='strip-lamp-'+str(n)
 p['lamps'].append({'id':fid,'at':[9.5,y],'zone':'rootward-square','style':'fixture','stand':[9,y-1],'requires':'field-tablet','automatic':True,'title':'Spindle strip lamp'})
 r['lamp_fixtures'].append({'id':fid,'asset':fid,'range':7,'energy':1.65})
 r['life']['sway'].append(fid)
for n,y in enumerate([22,40]):
 put('strip-bench-'+str(n),'lane-bench',[10.5,y],turn=270,size=[.66,1.7])
 put('strip-tree-'+str(n),'lane-cypress',[10.2,y+2.4],scale=.65,size=[.45,.45])
# Continuous real railings at the high terrace's drop, matching the park's new raised edge.
def rail_run(id,a,b,height):
 dx,dy=b[0]-a[0],b[1]-a[1];length=abs(dx)+abs(dy);turn=0 if dx else 90
 pieces=round(length/2);step=length/pieces
 for n in range(pieces):
  at=[a[0]+dx*n/pieces,a[1]+dy*n/pieces]
  r['assets'].append({'id':f'{id}-bay-{n}','asset':'town-railing','at':at,'height':height,'turn':turn,'scale':step/2,'solid':True})
 for n in range(pieces+1):
  at=[a[0]+dx*n/pieces,a[1]+dy*n/pieces]
  r['assets'].append({'id':f'{id}-post-{n}','asset':'town-railing-post','at':at,'height':height,'turn':turn,'scale':1,'solid':True})
rail_run('strip-edge',[11.65,14.65],[11.65,54.65],2.16)
rail_run('park-view',[-.5,-.35],[5.5,-.35],2.0)
rail_run('park-east',[5.65,-.35],[5.65,5.65],2.0)
# Avoid a new rail bay obstructing the existing high arrival/stair route.
p['zones'].insert(0,{'id':'spindle-strip','title':'Spindle Walk','rect':[0,11,12,44]})
p['zones'].insert(1,{'id':'spindle-park','title':'Spindle Garden','rect':[0,0,6,6]})
# Every new fitting belongs to the visited strip zone.
for lamp in p['lamps']:
 if lamp['id'].startswith('strip-lamp-'):lamp['zone']='spindle-strip'
save('content/areas/haverlund-square.json',p)
lane=load('content/areas/haverlund-lane.json');lane['version']+=1
out=next(l for l in lane['interior']['links'] if l['id']=='town-steps');out.update(arrival=[1,12],arrivals=[[1,11],[1,13]])
save('content/areas/haverlund-lane.json',lane)
for id in ['bakery','greengrocer','bookshop','clockmaker','apothecary']:
 path='content/areas/shop-'+id+'.json';d=load(path);d['version']+=1
 room=d['interior'];room['furniture']=[];room['inspections']=[]
 room['assets']=[a for a in room['assets'] if a['id'] in ['shop-door','shop-pendant-1-model','shop-pendant-2-model']]
 if id in ['clockmaker','apothecary']:
  room['links'][0]['arrival']=[6,15];room['links'][0]['facing']='S'
 save(path,d)
print('Layout revised; cleared five interiors; four future frontage plots.')
