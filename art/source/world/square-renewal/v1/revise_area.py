"""One-time deliberate edit of the current area document; prior document retained in .cache.
Current content/areas documents remain the layout masters after this revision.
"""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[5]
def read(p):return json.loads((ROOT/p).read_text())
def write(p,d):(ROOT/p).write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
if read('content/areas/haverlund-square.json').get('version') != 4:
 raise RuntimeError('This historical one-time edit requires the original version 4 document. Edit current area JSON directly.')
c=read('pipeline/world-catalog.json')
for id,label,foot in [('town-shop-shell','Reusable town shop interior',None),('town-retaining-wall','Limestone retaining wall · 3 m',[-1.5,-.24,3,.48])]:
 c['assets'][id]={'version':'v1','authority':'blender','status':'integrated_sparks_square','label':label,'source':f'art/source/world/{id}/v1/model.blend','runtime':f'assets/world/{id}/model.glb','pivot':'Ground centre; Blender +Y logical north','logical_footprint':foot,'illustrated_edges':True,'notes':'art/source/world/square-renewal/v1/author_modules.py. Editable adopted source; export through normal world build.','behavior':'Area owns placement and traversal.'}
# Barrier envelopes include bays and joints. Original start pivots are preserved.
for id,length,width in [('town-railing',2,.12),('town-railing-short',1,.12),('town-railing-stair',1,.12),('town-balustrade',3,.38),('town-balustrade-short',1.5,.38),('town-garden-wall',3,.44),('town-garden-wall-short',1.5,.44),('town-garden-gate',2,.12)]:
 c['assets'][id]['logical_footprint']=[0,-width/2,length,width]
 c['assets'][id]['behavior']='Reusable barrier with authored footprint; placed solid flag enables pure movement collision. Pivot at run start.'
for id,width in [('town-railing-post',.14),('town-balustrade-pier',.66),('town-garden-pier',.66)]:c['assets'][id]['logical_footprint']=[-width/2,-width/2,width,width]
for id,width in [('haverlund-bakery',5),('haverlund-greengrocer',4.6),('haverlund-bookshop',5)]:c['assets'][id]['logical_footprint']=[-width/2,-3.2,width,6.4]
write('pipeline/world-catalog.json',c)
b=read('content/build/catalog.json')
for id in ['town-railing','town-railing-short','town-railing-post','town-garden-wall','town-garden-wall-short','town-garden-pier','town-balustrade','town-balustrade-pier','town-retaining-wall']:
 if not any(i['id']==id for i in b['items']):b['items'].append({'id':id,'category':'garden','kind':'prop','asset':id,'title':c['assets'][id]['label'],'blurb':'Reusable town barrier. Rotate to join bays; its catalog footprint blocks passage.','audience':'studio'})
write('content/build/catalog.json',b)
p=read('content/areas/haverlund-square.json');room=p['interior'];p['version']+=1
removed=set()
for a in room['assets']:
 if a['id'].startswith('town-house-'):
  n=int(a['id'].split('-')[-1])
  if n<=11 or 23<=n<=45 or n>=53:removed.add(a['id'])
 if a['asset']=='town-bollard-light':removed.add(a['id'])
room['assets']=[a for a in room['assets'] if a['id'] not in removed]
# Remaining distant houses keep the simple silhouette treatment, without optional mesh dressing.
for a in room['assets']:
 if a['id'].startswith('town-house-'):a['look']={'seed':int(a['id'].split('-')[-1])+50,'plain':True}
 if a['asset'].startswith(('town-railing','town-garden','town-balustrade')):a['solid']=True
# Old broad approximations overlapped neighboring shop fronts. Use exact bodies and separate low displays.
room['furniture']=room['furniture'][3:]
for a in room['assets']:
 if a['id'] in ['bakery','greengrocer','bookshop']:a['solid']=True
# All removed fittings disappear from logic as well as presentation. Other saves retain their independent data.
room['lamp_fixtures']=[f for f in room['lamp_fixtures'] if f['asset'] not in removed]
kept={f['id'] for f in room['lamp_fixtures']};p['lamps']=[a for a in p['lamps'] if a['id'] in kept]
for f in room['lamp_fixtures']:
 a=next(a for a in room['assets'] if a['id']==f['asset'])
 if a['asset']=='square-banner-lamp':f.update(range=7.0,energy=1.65)
 elif a['id'].startswith('town-house-'):f.update(range=1.8,energy=.25)
 elif a['asset']=='town-festoon':f.update(range=5.0,energy=.65)
# Shopfront entries: exterior crossing cells remain outside the solid building body.
shops=[('bakery','haverlund-bakery','Morning Loaf',[19,17],'W',[20,17]),('greengrocer','haverlund-greengrocer','The Pantry',[19,22],'W',[20,22]),('bookshop','haverlund-bookshop','Finch & Thread',[19,26],'W',[20,26]),('clockmaker','haverlund-clockmaker','Pendulum & Pin',[3,12],'N',[3,11]),('apothecary','haverlund-apothecary','Thyme & Tonic',[9,12],'N',[9,11])]
for id,asset,label,at,direction,arrival in shops:
 if id in ['clockmaker','apothecary']:
  room['assets'].append({'id':id,'asset':asset,'at':[2.5 if id=='clockmaker' else 9,16.05],'height':2,'turn':0,'scale':1,'solid':True})
 room['links'].append({'id':id,'at':at,'approach':at,'direction':direction,'to':'shop-'+id,'arrival':[6,0],'facing':'N','label':'Enter '+label,'walk_through':True,'enter':2,'doors':id})
 fid=id+'-window-lamp'
 p['lamps'].append({'id':fid,'at':at,'zone':p['zones'][-1]['id'],'style':'fixture','stand':at})
 room['lamp_fixtures'].append({'id':fid,'asset':id,'range':4.3,'energy':.85})
# Level-two shopping pavement, connected via the high part of Spindle Steps.
terrain=[list(r) for r in p['terrain']]
for y in [11,12]:
 for x in range(0,12):terrain[len(terrain)-1-y][x]='='
# Building area stays closed; a side park path extends behind the new strip.
for y in range(13,19):
 for x in range(0,12):terrain[len(terrain)-1-y][x]='#'
p['terrain']=[''.join(r) for r in terrain]
# Two compact upper lawns with a few deliberately scattered trees, benches and a bird bath.
for id,asset,at,scale in [('upper-park-tree-1','lane-tree',[4,24],.85),('upper-park-tree-2','lane-tree',[8,34],.9),('upper-park-tree-3','lane-cypress',[2,42],.95),('upper-park-bench','lane-bench',[7,26],1),('upper-park-bench-2','lane-bench',[3,38],1),('upper-park-bath','town-fountain',[6,30],.65)]:room['assets'].append({'id':id,'asset':asset,'at':at,'height':2,'turn':0,'scale':scale})
# Keep the drop rail; open the short front railing only beside the shops' high sidewalk.
room['assets']=[a for a in room['assets'] if not (a['asset'].startswith('town-railing') and 10.5<float(a['at'][1])<10.8 and 6<float(a['at'][0])<11.7)]
# The old shop-front inspections keep their IDs (read history) with new text and accessible approaches.
for i in room['inspections']:
 if i['id']=='bookshop':i.update(title='Finch & Thread',text='Bolts of cloth, folded shirts and a brass measuring rule. The door opens into the clothier’s workroom.')
 if 'book' in i['title'].lower() or 'finch' in i['title'].lower():i.update(title='Finch & Thread',text='Cloth, coats and repairs. A paper measuring tape hangs beside the glazed door.')
# Reduced background still has trees below the promenade, breaking its former regular house rows.
for id,at in [('lower-tree-a',[16,-15]),('lower-tree-b',[43,-19]),('lower-tree-c',[80,11])]:room['assets'].append({'id':id,'asset':'lane-tree','at':at,'height':-10,'turn':35,'scale':1})
write('content/areas/haverlund-square.json',p)
# Shared room structure, different real furniture/wares. State, memory and programs save per shop.
fixtures=[('shop-pendant-1',[3,5]),('shop-pendant-2',[9,8])]
themes={
 'bakery':('Morning Loaf',[('hollow-bakers-oven',[2,9],.85),('hollow-bread-display',[7,9],1),('hollow-trestle-table',[3,5],.8)] ,'The morning batch is cooling. A blackboard gives the next baking time; the oven is still warm.'),
 'greengrocer':('The Pantry',[('hollow-kitchen-dresser',[2,9],1),('hollow-cheese-stand',[7,9],1),('lane-crates',[3,5],1)],'Crates of seasonal food, jars of preserves and a cheese counter. Prices are written on reusable slate tags.'),
 'bookshop':('Finch & Thread',[('hollow-weavers-loom',[2,9],.8),('hollow-linen-rack',[7,9],1),('hollow-spinning-wheel',[3,5],.85)],'Folded cloth at the front, alterations at the back. The loom and spinning wheel leave a clear customer aisle.'),
 'clockmaker':('Pendulum & Pin',[('hollow-writing-desk',[2,9],1),('hollow-tool-rack',[7,9],1),('hollow-mapmakers-table',[3,5],.9)],'A row of clocks waits for calibration. Brass gears, labelled drawers and a careful repair bench suggest a future programming job.'),
 'apothecary':('Thyme & Tonic',[('hollow-apothecary-cabinet',[2,9],1),('hollow-alchemy-bench',[7,9],1),('hollow-herb-drying-rack',[3,5],.9)],'Herbs dry above labelled jars. A recipe ledger and measuring bench are ready for a later programming challenge.')}
for id,asset,label,at,direction,arrival in shops:
 title,wares,text=themes[id]
 assets=[{'id':'shop-counter','asset':'city-hall-help-desk','at':[8,6],'turn':0,'scale':.72,'solid':True}]
 # Explicit furniture footprints for existing room props; catalog geometry need not invent rules.
 furniture=[{'kind':'counter','at':[8,6],'size':[3.9,.95]}]
 for n,(model,pos,scale) in enumerate(wares):
  assets.append({'id':'stock-'+str(n),'asset':model,'at':pos,'turn':0,'scale':scale})
  furniture.append({'kind':'shelf','at':pos,'size':[2.4,1.7] if n<2 else [2.2,1.8]})
 for fid,pos in fixtures:assets.append({'id':fid+'-model','asset':'workshop-pendant','at':pos,'height':0,'turn':0,'scale':1})
 assets.append({'id':'shop-door','asset':'workshop-shop-doors','at':[6,0],'turn':0,'scale':.65})
 lamps=[{'id':fid,'zone':'shop-floor','at':[6,3],'style':'fixture','stand':[6,3]} for fid,_ in fixtures]
 d={'schema':1,'id':'shop-'+id,'title':title,'version':1,'size':[12,12],'spawn':[6,3],'voice_lesson':True,'terrain':['.'*12]*12,'buildings':[],'trees':[],'zones':[{'id':'shop-floor','title':title,'rect':[0,0,12,12]}],'lamps':lamps,'props':[], 'interior':{'style':'workshop-square','shell':'town-shop-shell','zoom':12,'exit':[6,0],'exit_direction':'S','walk_front':0,'furniture':furniture,'assets':assets,'lamp_fixtures':[{'id':fid,'asset':fid+'-model','range':7,'energy':1.25} for fid,_ in fixtures], 'links':[{'id':'square','at':[6,0],'approach':[6,1],'direction':'S','to':'haverlund-square','arrival':arrival,'facing': 'E' if direction=='W' else 'S','label':'Return to the square','walk_through':True,'enter':1,'doors':'shop-door'}], 'inspections':[{'id':'shop-stock','at':[6,8],'title':title,'text':text}],'city_network':True}}
 write('content/areas/shop-'+id+'.json',d)
levels=read('content/levels/catalog.json')
entry=next(l for l in levels['levels'] if l['id']=='sparks-and-machines')
entry['room_areas']+=['shop-'+s[0] for s in shops]
write('content/levels/catalog.json',levels)
print('REMOVED',len(removed),'placements; lamps',len(p['lamps']))
