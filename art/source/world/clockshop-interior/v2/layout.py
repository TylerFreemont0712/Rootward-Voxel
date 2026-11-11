"""Initial curated expansion placement record. Area JSON is authoritative after this one-time edit."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[5]
def read(p):return json.loads((ROOT/p).read_text())
def write(p,d):(ROOT/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
assets={
'clockshop-display-plinth':('Brass-inlaid curio plinth',[-.55,-.55,1.1,1.1]),
'clockshop-orrery':('Geared planetary orrery',None),
'clockshop-watch-cabinet':('Pocket-watch cabinet',[-.98,-.32,1.96,.64]),
'clockshop-spring-winder':('Mainspring winding tool',None),
'clockshop-pendulum-rack':('Pendulum regulation rack',[-1.1,-.38,2.2,.76]),
'clockshop-blueprint-board':('Escapement drawing board',None),
'clockshop-service-shelf':('Clockmaker service cabinet',[-1.26,-.31,2.52,.62]),
'clockshop-oil-and-tools':('Clock oils and cleaning brushes',None),
'clockshop-ledger-set':('Open repair ledger and manuals',None),
'clockshop-clock-crates':('Wrapped clock delivery crate',[-.60,-.43,1.2,.86]),
'clockshop-stool':('Padded watchmaker stool',[-.34,-.34,.68,.68]),
'clockshop-wall-shelf':('Brass-bracket display shelf',None),
'clockshop-cuckoo-clock':('Carved cuckoo wall clock',None)}
catalog=read('pipeline/world-catalog.json')
for id,(title,foot) in assets.items():
 assert id not in catalog['assets'],'Already registered; edit the selected master.'
 catalog['assets'][id]={'version':1,'authority':'blender','status':'integrated_sparks_square','label':title,'source':f'art/source/world/{id}/v1/model.blend','runtime':f'assets/world/{id}/model.glb','pivot':'Ground/tabletop centre. Blender -Y front; +Y logical north. Wall shelf pivot is shelf base.','logical_footprint':foot,'illustrated_edges':True,'notes':'Original reusable clockmaker curio. art/source/world/clockshop-interior/v2/author_curios.py is the protected initial authoring record; model.blend is the editable authority.','behavior':'Area placements and collision are authoritative. Decorative stock, with authored inspection; no quest mechanism is claimed.'}
write('pipeline/world-catalog.json',catalog)
build=read('content/build/catalog.json')
for id,(title,foot) in assets.items():build['items'].append({'id':id,'category':'workshop','kind':'prop','asset':id,'title':title,'blurb':'Original reusable clockmaker curio. Room documents can place it on a bench, shelf or wall.','audience':'studio'})
write('content/build/catalog.json',build)
p='content/areas/shop-clockmaker.json';d=read(p);assert d['version']==3
archive=ROOT/'content/areas/archive/shop-clockmaker-v3.json';shutil.copy2(ROOT/p,archive)
d['version']=4;d['size']=[14,14];d['terrain']=['.'*14]*14;d['zones'][0]['rect']=[0,0,14,14]
i=d['interior'];i['assets']=[];i['furniture']=[]
def add(id,asset,at,turn=0,height=0,scale=1,solid=False):
 i['assets'].append({'id':id,'asset':asset,'at':at,'turn':turn,'height':height,'scale':scale,**({'solid':True} if solid else {})})
add('longcase-a','clockshop-longcase',[.6,6.4],90,solid=True)
add('longcase-b','clockshop-longcase',[.6,8.5],90,solid=True)
add('longcase-c','clockshop-longcase',[.6,11.2],90,solid=True)
add('display','clockshop-display-counter',[9.5,5.0],solid=True)
add('repair-bench','clockshop-repair-bench',[9.3,12.4],solid=True)
add('side-repair-bench','clockshop-repair-bench',[2.0,8.0],90,solid=True)
add('parts-cabinet','clockshop-parts-cabinet',[2.9,12.7],solid=True)
add('spares-cabinet','clockshop-parts-cabinet',[.7,1.6],90,solid=True)
add('watch-cabinet','clockshop-watch-cabinet',[.6,4.0],90,solid=True)
add('service-cabinet','clockshop-service-shelf',[12.8,5.3],270,solid=True)
add('intake-cabinet','clockshop-service-shelf',[9.2,1.2],solid=True)
add('pendulum-rack','clockshop-pendulum-rack',[12.3,10.0],solid=True)
for n,at in enumerate([[12.5,8.0],[12.6,12.6],[1.0,12.5]]):add('delivery-'+str(n),'clockshop-clock-crates',at,90 if n==2 else 0,solid=True)
for n,at in enumerate([[3.4,3.0],[11.8,2.0],[3.3,6.0]]):add('curio-plinth-'+str(n),'clockshop-display-plinth',at,solid=True)
add('orrery','clockshop-orrery',[3.4,3.0],height=.97)
add('small-orrery','clockshop-orrery',[11.8,2.0],height=.97,scale=.80)
add('spring-winder','clockshop-spring-winder',[3.3,6.0],height=.97)
for n,at in enumerate([[3.7,8.7],[9.3,10.8]]):add('work-stool-'+str(n),'clockshop-stool',at,solid=True)
add('parts-tray','clockshop-clockwork-tray',[2.2,8.35],90,1.08,.65)
add('intake-ledger','clockshop-ledger-set',[8.6,1.2],height=1.49)
add('display-ledger','clockshop-ledger-set',[10.4,4.9],height=1.69,scale=.75)
add('archive-ledger','clockshop-ledger-set',[2.0,12.7],height=2.40,scale=.65)
add('intake-oils','clockshop-oil-and-tools',[9.6,1.2],height=1.49)
add('service-oils','clockshop-oil-and-tools',[12.8,6.28],270,1.49,.65)
add('rear-oils','clockshop-oil-and-tools',[3.8,12.7],height=2.39,scale=.70)
add('rear-shelf','clockshop-wall-shelf',[4.8,13.1],height=1.60)
add('side-shelf','clockshop-wall-shelf',[-.19,10.7],90,1.45,.85)
add('timing-diagram','clockshop-blueprint-board',[4.8,13.15],height=2.70)
add('repair-diagram','clockshop-blueprint-board',[-.20,10.7],90,2.20,.85)
for n,(at,turn,h,s) in enumerate([([-.20,7.5],90,1.60,1),([-.20,9.3],90,1.65,.8),([12.0,13.16],0,1.65,1),([6.1,13.16],0,1.70,.65)]):add('wall-clock-'+str(n),'clockshop-regulator',at,turn,h,s)
for n,(at,h,s) in enumerate([([4.15,13.1],1.72,.70),([4.8,13.1],1.72,.85),([5.45,13.1],1.72,.65),([12.8,5.0],1.49,.65),([12.8,5.8],1.49,.6),([10.2,1.2],1.49,.6),([2.8,12.7],2.39,.7)]):add('mantel-'+str(n),'clockshop-mantel-clock',at,270 if n in [3,4] else 0,h,s)
add('cuckoo-a','clockshop-cuckoo-clock',[-.20,5.8],90,1.60)
add('cuckoo-b','clockshop-cuckoo-clock',[.6,13.16],0,2.05,.90)
lamps=[('shop-pendant-1',[4,4],7.5,1.2),('shop-pendant-2',[10.3,10.0],7.5,1.2),('shop-pendant-3',[3.3,10.3],7,.95)]
d['lamps']=[];i['lamp_fixtures']=[]
for id,at,r,e in lamps:
 add(id+'-model','clockshop-brass-pendant',at,height=3.5)
 d['lamps'].append({'id':id,'zone':'shop-floor','at':at,'style':'fixture','stand':[6,3],'automatic':True,'requires':'field-tablet'})
 i['lamp_fixtures'].append({'id':id,'asset':id+'-model','range':r,'energy':e})
inspections=[
('clock-display',[9,4],'The display case','Mantel clocks and pocket watches wait on green felt. Each ivory tag records the maker, the fault found and the date the movement was serviced.'),
('clock-repairs',[8,11],'The repair bench','A half-built escapement is held upright in its stand. Drivers, a bench vise and a shaded task lamp leave room for a larger calibration job.'),
('clock-parts',[3,11],'Drawers of time','Brass labels divide pinions, springs, jewels and winding keys by size. The open repair manuals on top are full of small corrections.'),
('watch-collection',[2,4],'Nine pocket watches','Chains hang from individual brass hooks. Open faces and closed cases share the cabinet, each with its own little stand and repair ticket.'),
('planetary-orrery',[4,2],'A little clockwork sky','Three tilted brass orbits carry small planets around a golden sun. The exposed reduction wheels explain how one turn can become several slower ones.'),
('mainspring-winder',[4,5],'The spring winder','Two iron jaws hold a coiled mainspring on its arbor. A wooden crank winds it under control; a handwritten note warns against releasing the jaws first.'),
('repair-intake',[9,2],'The repair ledger','A ribbon marks the current page. The entries list owners, symptoms, promised collection dates and which parts are still missing.'),
('clock-oils',[12,6],'Oils and cleaning tools','Fine applicators stand beside labelled bottles and a soft brush. The clockmaker uses different oils for pivots, springs and larger gear trains.'),
('clock-deliveries',[11,8],'Clocks in transit','Slatted crates hold rolled felt and wrapped clock cases. Their brass straps and FRAGILE labels suggest careful deliveries rather than anonymous storage.'),
('pendulum-selection',[11,9],'Pendulums awaiting regulation','Five rods hang from a numbered rack. The bobs have different masses and the lengths are deliberately unequal; each belongs to a particular movement.'),
('escapement-drawing',[5,12],'The escapement drawing','A pinned diagram separates the escape wheel, pallet and pendulum. Dimension lines and small timing notes connect the drawing to the tools on the benches.'),
('bench-cleaning',[3,8],'The watchmaker work station','A second workbench is arranged for smaller movements. Loose gears rest in a removable felt-lined tray, leaving the middle of the shop free for a larger task.'),
('cuckoo-stock',[2,6],'The cuckoo clocks','A tiny carved bird waits under a steep roof. Two pinecone weights and a separate pendulum hang below the clock case.'),
('orrery-stock',[12,3],'The demonstration model','A smaller planetary mechanism is mounted on a matching plinth. Its open rings can be examined without taking the larger display apart.')]
i['inspections']=[{'id':id,'at':at,'title':title,'text':text} for id,at,title,text in inspections]
write(p,d);print('Room 14×14;',len(i['assets']),'placements;',len(inspections),'inspections;',len(assets),'new model types')
