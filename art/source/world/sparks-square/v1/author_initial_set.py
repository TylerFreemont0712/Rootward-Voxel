"""Guarded initial authorship of Haverlund's downhill square. Never replaces an adopted master.
The selected T3 square and T5 Rootwell are references. Shared lane materials/geometry preserve its established style.
After creation model.blend is authority; export through scripts/world-art.sh build <id>.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import sys
import bpy
from mathutils import Vector
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE.parents[1] / 'sparks-lane/v1'))
import lane_kit as k
R = random.Random(2829)
ASSETS = ('haverlund-square-set', 'square-rootwell', 'square-town-hall', 'square-bakery', 'square-bookshop', 'square-grocer', 'square-market-stall', 'square-cafe-table', 'square-delivery-robot', 'square-node')


def begin(asset):
    k.start(asset, 'square')
    k.h.material('roof_blue', '4e8197')
    k.h.material('roof_blue_light', '6597a6')
    k.h.material('roof_blue_dark', '3b657d')
    k.h.material('ochre_plaster', 'ddbf83', str(k.LOFT / 'cream-plaster'))
    k.h.material('blue_plaster', 'b9ced0')
    k.h.material('spark', 'ffca70', emission=1.7)
    k.h.material('root', '98673f')
    k.h.material('root_light', 'be8e55')
    k.h.material('window_dome', 'c9e2e1')
    mat=k.M['window_dome']; mat.diffuse_color=(*mat.diffuse_color[:3], .19)
    mat.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.19
    if hasattr(mat,'surface_render_method'): mat.surface_render_method='DITHERED'
    return k.Batch(R)


def save(asset, parts=()):
    # Batch the static art but preserve named glass, dial and screen surfaces for presentation and later edits.
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH': continue
        semantic=obj.name if any(obj.name.startswith(p) for p in parts) else 'static'
        groups.setdefault((semantic,obj.data.materials[0].name),[]).append(obj)
    for (semantic,mat),objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1: bpy.ops.object.join()
        bpy.context.object.name=mat if semantic=='static' else semantic
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.scene['rootward_source']='Editable square master. Do not rerun author.py.'
    bpy.ops.file.pack_all()
    folder=ROOT/'art/source/world'/asset/'v1'; folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'model.blend'))
    (folder/'provenance.json').write_text(json.dumps({'asset':asset,'date':'2026-10-28','authoring_record':str(HERE.relative_to(ROOT)/'author.py'),'authoring_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'references':['docs/concept/v0.7/art/5-town/T3-rootward-square-day.wheels.png','docs/concept/v0.7/art/5-town/T5-rootwell-sheet.png'],'shared_kit':'art/source/world/sparks-lane/v1/lane_kit.py','shared_kit_sha256':hashlib.sha256(Path(k.__file__).read_bytes()).hexdigest(),'note':'New native geometry; packed lane paintings reused. model.blend is editable authority.'},indent=2)+'\n')
    print('AUTHORED',asset,flush=True)


def torus(name,at,r,t,mat,rot=(0,0,0)):
    return k.h.torus(name,at,r,t,mat,rot)


def rail(b,x0,x1,y,z):
    for x in [x0+i*(x1-x0)/max(1,round((x1-x0)/1.3)) for i in range(round((x1-x0)/1.3)+1)]:
        b.box('limestone',(x,y,z+.52),(.28,.3,1.04),.03)
        b.box('limestone_pale',(x,y,z+1.08),(.36,.4,.1),.02)
    for h in (.3,.92): b.box('iron',((x0+x1)/2,y,z+h),(x1-x0,.05,.04),.008)
    for i in range(int((x1-x0)/.18)):
        x=x0+(i+.5)*.18
        b.cylinder('iron',(x,y,z+.25),(x,y,z+.93),.013,5)


def square_set(b):
    # Main cobbled plaza, flagged shop apron, a planted harbour edge and two landings above the eastern approach.
    k.quad_surface('Square cobbles','cobbles',[(-.5,-.5,31.5,29.5)],2,0)
    k.quad_surface('Shop pavement','flags',[(-.45,5.5,7,29.4),(8,18.5,23.4,29.4)],3,.008)
    k.quad_surface('Harbour garden','grass',[(7,-.4,26.3,4.2),(27,5,31.4,18.5)],8,.012)
    b.box('soil_dark',(15.5,14.5,-.8),(32,30,1.58),0)
    k.stone_courses(b,R,'x',-.5,31.5,-.8,0,-.5,depth=.3,course=.27)
    k.stone_courses(b,R,'y',-.5,29.5,-.8,0,31.5,depth=.3,course=.27)
    for x0,x1,y,z in [(7,26.3,4.4,0),(27,31.2,19.2,0)]: rail(b,x0,x1,y,z)
    # Hill steps: first flight rises at y26, then at y28; row27 is a landing. Matches levels/stairs exactly.
    for y0,z0,z1 in [(25.5,0,1),(27.5,1,2)]:
        for i in range(4):
            top=z0+(i+1)*.25
            b.box('limestone_pale',(29, y0+(i+.5)*.25,top/2),(2.45,.25,top),.018)
        b.box('limestone',(29,y0+1.25,z1/2),(2.45,1.5,z1),.02)
        for x in (27.6,30.4):
            b.cylinder('iron',(x,y0,z0+.9),(x,y0+1,z1+.9),.025,8)
            for yy,zz in [(y0,z0),(y0+1,z1)]:b.cylinder('iron',(x,yy,zz),(x,yy,zz+.9),.023,8)
    for y0,y1,z in [(26.5,27.5,1),(28.5,29.5,2)]:
        k.quad_surface('Hill landing','flags',[(27.7,y0,30.3,y1)],3,z)
    for x in (27.35,30.65):
        b.box('limestone',(x,27.5,1.0),(.48,4.0,2.0),.03)
        b.box('limestone_pale',(x,27.5,2.05),(.6,4.1,.1),.025)
    k.lettering('Steps plate','SPINDLE STEPS',(30.37,25.8,.5),.13,'enamel_blue')
    # Cobble setts radiate round the Rootwell. Brass branches disappear into the town, one toward the hill.
    for r in (2.25,2.52,2.8):
        for i in range(int(math.tau*r/.38)):
            a=math.tau*(i+.5)/int(math.tau*r/.38)
            b.box(['limestone','limestone_pale','limestone_warm'][i%3],(17+math.cos(a)*r,13+math.sin(a)*r,.025),(.32,.21,.05),.025,(0,0,a+math.pi/2))
    for x0,x1 in [(7.0,14.7),(19.3,26.8)]: b.box('brass',((x0+x1)/2,13,.018),(x1-x0,.07,.035),.008)
    for y0,y1 in [(4.6,10.7),(15.3,18.5)]: b.box('brass',(17,(y0+y1)/2,.018),(.07,y1-y0,.035),.008)
    # Rain channels and iron grates stay level with the paving, with actual slots between bars.
    for x in (7.1,26.6):
        b.box('limestone_shade',(x,13,.013),(.16,20,.025),0)
        for y in (7,15,22):
            for i in range(7): b.box('iron',(x-.08+i*.026,y,.03),(.014,.35,.03),.003)
    # A rear retaining wall, a fountain at the shops, chalk marks and uncollected milk on the baker's step.
    k.stone_courses(b,R,'x',-.3,26.9,0,1.2,29.45,depth=.3,course=.3)
    for x in (8,23.8):
        k.flower_clump(b,(x,28.8,.1),.35,R,('flower_white','flower_pink'),count=9)
    for x,y in [(8,2.5),(13,2.7),(23.5,2.2),(29,10),(30,15)]:
        for _ in range(12):
            k.flower_clump(b,(x+R.uniform(-.5,.5),y+R.uniform(-.45,.45),.03),.08,R,('flower_white','flower_yellow'),count=3)
    for i in range(4):
        b.box('paper',(9.4+i*.12,18.0,.02),(.09,.2,.012),.004,(0,0,.12*i))
    # Service line supported at each end; no floating wires across the approach.
    for x,y in ((7.8,26.8),(25.9,24.5),(26.2,6.2)):
        b.box('wood',(x,y,2.2),(.15,.15,4.4),.02)
        b.box('wood',(x,y,4.3),(1.1,.1,.12),.01)
        for side in (-.4,.4): b.cylinder('ceramic',(x+side,y,4.3),(x+side,y,4.55),.06,8)
    for a,c in [((7.4,26.8,4.5),(25.5,24.5,4.5)),((25.5,24.5,4.5),(25.8,6.2,4.5))]:k.catenary('Service wire',a,c,.4,.012)
    b.finish()


def rootwell(b):
    # Broad low circular steps and ring of separate limestone blocks, with a modest pressure vessel at its centre.
    for radius,top in [(1.95,.16),(1.7,.32),(1.45,.64)]:
        for i in range(24):
            a=math.tau*i/24
            b.box(['limestone','limestone_pale','limestone_warm'][i%3],(math.cos(a)*(radius-.12),math.sin(a)*(radius-.12),top/2),(.27,.4,top),.025,(0,0,a))
    b.cylinder('limestone_shade',(0,0,.05),(0,0,.65),1.25,48)
    torus('Wide brass rim',(0,0,.7),1.16,.095,'brass')
    torus('Enamel inner ring',(0,0,.72),1.02,.07,'teal')
    # Glass bell: open at its base so the root can genuinely be seen through it.
    vs=[]; fs=[]; segments=48; rows=18
    for j in range(rows+1):
        a=(math.pi/2-.025)*j/rows
        for i in range(segments):
            phi=math.tau*i/segments
            vs.append((.96*math.cos(a)*math.cos(phi),.96*math.cos(a)*math.sin(phi),.75+1.12*math.sin(a)))
    for j in range(rows):
        for i in range(segments):
            a=j*segments+i;c=j*segments+(i+1)%segments
            fs.append((a,c,c+segments,a+segments))
    mesh=bpy.data.meshes.new('Glass bell');mesh.from_pydata(vs,[],fs);mesh.update();mesh.uv_layers.new()
    obj=bpy.data.objects.new('window_dome',mesh);bpy.context.collection.objects.link(obj);k.h.put(obj,'window_dome',True)
    k.h.curve('Root rising',[(0,0,.66),(-.28,.16,.9),(.2,.13,1.25),(.12,-.1,1.53),(-.17,.08,1.82)],.105,'root')
    k.h.curve('Root branch',[(.08,.05,1.2),(-.23,-.15,1.35),(-.5,-.12,1.42)],.038,'root_light')
    for i in range(9):
        a=i*.8
        b.sphere('leaf',(.35*math.cos(a),.3*math.sin(a),.9+i*.09),.09,2,(1.2,.55,.7))
    b.sphere('spark',(.03,-.26,1.0),.2,3)
    torus('Spark collar',(.03,-.26,1),.24,.025,'brass',(math.pi/2,0,0))
    b.cylinder('brass',(0,0,1.85),(0,0,2.06),.09,16)
    torus('Dome top',(0,0,1.87),.14,.035,'brass')
    # Each valve faces its branch. All have a connected spindle and flange, never a floating wheel.
    for a in (0,math.pi/2,math.pi,3*math.pi/2):
        x,y=1.3*math.cos(a),1.3*math.sin(a)
        b.cylinder('brass',(x,y,.38),(x,y,1.0),.055,12)
        torus('Valve wheel',(x,y,1.02),.16,.023,'brass')
        for q in range(4):
            ph=math.pi*q/2;b.cylinder('brass',(x,y,1.02),(x+.15*math.cos(ph),y+.15*math.sin(ph),1.02),.014,6)
    # Pressure dial faces the approach (south). Cream face, low red band, ticks, a deliberately low needle.
    k.h.disc('Pressure face',(0,-1.4,.62),.34,.05,'cream',(math.pi/2,0,0))
    torus('Pressure bezel',(0,-1.43,.62),.35,.045,'brass',(math.pi/2,0,0))
    for i in range(11):
        a=math.radians(210-i*24); x,z=.28*math.cos(a),.62+.28*math.sin(a)
        b.box('ink',(x,-1.463,z),(.015,.006,.045),.002,(0,math.pi/2-a,0))
    b.cylinder('red',(0,-1.47,.62),(-.21,-1.47,.48),.018,8)
    b.sphere('brass',(0,-1.47,.62),.04,2)
    k.lettering('Dial label','ROOTWORKS',(0,-1.467,.71),.065,'ink')
    # Restrained highlight strokes; transparent dome stays legible in the compatibility renderer.
    for phi in (3.75,5.15):
        k.h.curve('window highlight',[(.98*math.cos(a)*math.cos(phi),.98*math.cos(a)*math.sin(phi),.75+1.13*math.sin(a)) for a in (.18,.35,.52,.69,.86)],.012,'white')
    b.finish()


def roof(b,x0,x1,depth,eave,ridge,blue=False):
    for side in (-1,1):
        tones=('roof_blue','roof_blue_light','roof_blue_dark','roof_blue') if blue else ('terracotta','terracotta_light','terracotta_dark','terracotta')
        k.roof_deck(b,x0,x1,side*depth,0,eave,ridge,mat='roof_blue_dark' if blue else 'terracotta_dark')
        k.tiled_roof(b,x0,x1,side*depth,0,eave,ridge,R,tones=tones)


def hall(b):
    # A new detailed civic version: same cream/timber and blue silhouette as the accepted concept hall.
    w,d=8.4,5.5;eave,ridge=4.0,6.0
    openings=[(.85,2.0,1.05,2.8),(3.4,5.0,.1,3.05),(6.4,7.55,1.05,2.8)]
    k.wall('Hall front','plaster',(-w/2,-d/2),(w/2,-d/2),0,eave,.22,openings)
    k.wall('Hall east','plaster',(w/2,-d/2),(w/2,d/2),0,eave,.22,[(.6,1.7,1.1,2.8),(3.5,4.65,1.1,2.8)])
    k.wall('Hall back','plaster',(w/2,d/2),(-w/2,d/2),0,eave,.22)
    k.wall('Hall west','plaster',(-w/2,d/2),(-w/2,-d/2),0,eave,.22)
    for y in (-d/2,d/2):k.gable_plaster('Hall gable','plaster',y,-w/2,w/2,eave,ridge,0,-1 if y<0 else 1,axis='y')
    for y in (-d/2-.04,d/2+.04):
        for z in (.45,3.12,3.9):b.box('timber',(0,y,z),(w+.1,.14,.16),.018)
        for x in (-4.1,-2.1,-.88,.88,2.1,4.1):b.box('timber',(x,y,2.1),(.14,.14,3.75),.016)
    for x in (-w/2-.04,w/2+.04):
        for z in (.45,3.12,3.9):b.box('timber',(x,0,z),(.14,d,.16),.015)
        for y in (-2.65,0,2.65):b.box('timber',(x,y,2.1),(.14,.14,3.75),.015)
    k.stone_courses(b,R,'x',-w/2,w/2,0,.5,-d/2-.05,depth=.2,course=.25,skip=lambda x,z:abs(x)<.85)
    for x in (-2.77,2.77):k.window(b,(x,-d/2,1.92),1.15,1.75,(0,-1),shutters=False,glass='window_shop',bars=(1,2))
    for y in (-1.6,1.32):k.window(b,(w/2,y,1.95),1.1,1.7,(1,0),shutters=False,bars=(1,2))
    for side in (-1,1):
        b.box('oak',(side*.4,-d/2+.02,1.55),(.77,.13,2.85),.02)
        for z in (.8,1.7,2.5):b.box('wood_dark',(side*.4,-d/2-.06,z),(.58,.03,.5),.02)
        b.sphere('brass',(side*.14,-d/2-.13,1.6),.045,2)
    for x in (-.9,.9):b.box('limestone_pale',(x,-d/2-.05,1.6),(.23,.3,3.05),.025)
    b.box('limestone_pale',(0,-d/2-.07,3.2),(2.07,.36,.22),.03)
    for i in range(3):b.box('limestone_pale',(0,-d/2-.15-i*.3,.12*(3-i)),(2.4+i*.2,.65,.24*(3-i)),.025)
    roof(b,-4.5,4.5,d/2+.3,3.96,6.0,True)
    # Small square clock tower straddles the ridge, with copper cap and four real clock faces.
    b.box('limestone',(0,0,6.25),(1.7,1.7,2.0),.045)
    for z in (5.65,7.22):b.box('limestone_pale',(0,0,z),(1.92,1.92,.16),.025)
    for x in (-.78,.78):
        for y in (-.78,.78):b.box('limestone_pale',(x,y,6.4),(.17,.17,1.5),.02)
    for side in (-1,1):
        for axis in (0,1):
            pos=(0,side*.87,6.42) if axis==0 else (side*.87,0,6.42)
            rot=(math.pi/2,0,0) if axis==0 else (0,math.pi/2,0)
            k.h.disc('Clock face',pos,.57,.025,'ink',rot)
            torus('Clock bezel',pos,.57,.035,'brass',rot)
            # South/east hands and minute marks; time just after eight.
            for i in range(12):
                a=math.tau*i/12;u=.46*math.sin(a);v=.46*math.cos(a)
                at=(u,side*.896,6.42+v) if axis==0 else (side*.896,u,6.42+v)
                b.sphere('brass',at,.027,1)
            if axis==0:
                b.cylinder('brass',(0,side*.9,6.42),(-.24,side*.9,6.25),.02,6)
                b.cylinder('brass',(0,side*.9,6.42),(.12,side*.9,6.78),.016,6)
            else:
                b.cylinder('brass',(side*.9,0,6.42),(side*.9,-.24,6.25),.02,6)
                b.cylinder('brass',(side*.9,0,6.42),(side*.9,.12,6.78),.016,6)
    roof(b,-1.08,1.08,1.05,7.27,8.08,True)
    b.sphere('brass',(0,0,8.25),.09,2)
    k.lettering('Hall lettering','HAVERLUND',(0,-d/2-.13,3.57),.22,'brass')
    b.finish()


def shop(b,which):
    w,d=5.4,5.8;mat=['ochre_plaster','salmon','blue_plaster'][which]
    # Front faces east onto the pavement. Real openings and painted panes, matching the lane houses.
    opens=[(.45,1.45,.16,2.4),(2.0,5.15,.7,2.5),(.7,1.7,3.4,4.75),(3.6,4.6,3.4,4.75)]
    k.wall('Shopfront',mat,(w/2,-d/2),(w/2,d/2),0,5.3,.2,opens)
    k.wall('Shop south',mat,(-w/2,-d/2),(w/2,-d/2),0,5.3,.2,[(1.8,3,3.4,4.75)])
    k.wall('Shop north',mat,(w/2,d/2),(-w/2,d/2),0,5.3,.2)
    k.wall('Shop back',mat,(-w/2,d/2),(-w/2,-d/2),0,5.3,.2)
    for y in (-d/2,d/2):k.gable_plaster('Shop gable',mat,y,-w/2,w/2,5.3,7.0,0,-1 if y<0 else 1,axis='y')
    for yy in (-1.7,1.2):k.window(b,(w/2,yy,4.08),1,1.35,(1,0),flowers=('flower_white','flower_pink'),bars=(1,1))
    k.window(b,(.0,-d/2,4.08),1.2,1.35,(0,-1),bars=(1,1))
    k.window(b,(w/2,.675,1.6),3.15,1.8,(1,0),shutters=False,box=False,glass='window_shop',frame='teal',bars=(2,1))
    b.box('teal',(w/2-.05,-1.95,1.27),(.14,.95,2.3),.02)
    for zz in (.55,1.2):b.box('teal_dark',(w/2+.025,-1.95,zz),(.02,.73,.45),.01)
    b.sphere('brass',(w/2+.05,-1.65,1.18),.04,2)
    b.box('limestone_pale',(w/2+.18,-1.95,.1),(.6,1.12,.2),.02)
    for z in (.34,2.65,3.0,5.2): b.box('timber',(w/2+.03,0,z),(.13,d,.12),.015)
    for y in (-2.8,-1.4,2.8): b.box('timber',(w/2+.03,y,2.7),(.13,.13,5.1),.015)
    # Proper shop fascia and soft scalloped awning, alternating fabric strips with their ends hanging down.
    b.box('teal',(w/2+.07,.25,2.86),(.18,4.5,.4),.02)
    k.lettering('Shop fascia',['MORNING LOAF','FINCH & SONS','GREENGROCER'][which],(w/2+.17,.25,2.86),.23,'cream',(math.pi/2,0,math.pi/2))
    for i in range(12):
        y=-1.75+i*.34
        material=['cloth_ochre','cloth_rose','teal'][which] if i%2==0 else 'stripe_cream'
        b.box(material,(w/2+.6,y,2.35),(1.25,.34,.045),.01,(0,.18,0))
        b.box(material,(w/2+1.2,y,2.22),(.04,.33,.2),.015)
    for y in (-1.95,2.35):b.cylinder('iron',(w/2+.04,y,1.85),(w/2+1.2,y,2.28),.019,6)
    roof(b,-w/2-.25,w/2+.25,d/2+.28,5.32,7.03)
    b.box('brick',(-1.65,1.4,6.9),(.55,.65,1.8),.025)
    b.box('limestone_pale',(-1.65,1.4,7.85),(.68,.78,.16),.02)
    # Worn step, broom, products in wooden trays left by each shop; distinct uses, consistent proportions.
    for t in range(2):
        y=.0+t*1.3
        for z in (.18,.45):b.box('wood',(3.1,y,z),(.7,1.0,.06),.01)
        for end in (-.5,.5): b.box('wood_light',(3.1,y+end,.34),(.7,.04,.3),.01)
        for j in range(8):
            x=2.87+(j%2)*.28;yy=y-.32+(j//2)*.21
            if which==0:
                b.sphere('ochre',(x,yy,.57),.12,2,(1,.68,.6))
                b.box('cream',(x,yy,.635),(.09,.015,.008),.003,(0,0,.4))
            elif which==1:
                b.box(['teal','plum','cloth_ochre'][j%3],(x,yy,.55),(.18,.15,.16),.012)
                b.box('pages',(x,yy,.55),(.17,.135,.12),.004)
            else:b.sphere(['flower_red','leaf_light','cloth_ochre'][j%3],(x,yy,.57),.11,2)
    b.cylinder('wood',(2.9,-2.65,.1),(2.85,-2.7,1.8),.022,6)
    b.box('linen',(2.9,-2.65,.16),(.15,.28,.24),.02)
    b.finish()


def market(b):
    # A stall with a cloth roof stretched between four actual poles, produce bins, brass scale, baskets and crate.
    for x in (-1.25,1.25):
        for y in (-.65,.65):b.cylinder('wood',(x,y,0),(x,y,2.3),.04,8)
    for y in (-.65,.65):b.box('wood',(0,y,2.25),(2.65,.08,.08),.01)
    for i in range(14):
        x=-1.3+(i+.5)*2.6/14
        for side in (-1,1):b.box('cloth_rose' if i%2 else 'stripe_cream',(x,side*.44,2.28),(2.6/14,.92,.04),.008,(side*-.13,0,0))
    for y in (-.85,.85):b.box('cloth_rose',(0,y,2.14),(2.65,.035,.22),.01)
    for x in (-1.0,1.0):
        for y in (-.45,.45):b.box('wood',(x,y,.47),(.09,.09,.94),.01)
    b.box('oak',(0,0,.95),(2.6,1.3,.12),.025)
    for x in (-.78,0,.78):
        b.box('wood_dark',(x,0,1.04),(.7,1.05,.06),.008)
        for y in (-.5,.5):b.box('wood_light',(x,y,1.12),(.7,.035,.15),.008)
        for j in range(10):b.sphere(['flower_red','leaf_light','cloth_ochre'][int((x+1)*2)%3],(x+(j%2-.5)*.25,(j//2-2)*.18,1.18),.13,2)
    for x in (-.95,.95):
        b.box('wood_dark',(x,.12,.2),(.55,.7,.35),.02)
        for j in range(3):b.box('wood',(x,-.25,.1+j*.11),(.55,.035,.07),.008)
    b.cylinder('brass',(.45,-.25,1.05),(.45,-.25,1.63),.025,8)
    b.box('brass',(.45,-.25,1.58),(.65,.035,.04),.006)
    for x in (.14,.76):
        for dx in (-.1,.1):b.cylinder('brass',(x,-.25,1.58),(x+dx,-.25,1.3),.008,5)
        k.h.disc('Scale pan',(x,-.25,1.29),.15,.012,'brass')
    b.finish()


def cafe(b):
    b.cylinder('iron',(0,0,.1),(0,0,.82),.04,10)
    k.h.disc('Cafe top',(0,0,.85),.55,.08,'oak')
    for a in (0,2.1,4.2):b.cylinder('iron',(0,0,.3),(.4*math.cos(a),.4*math.sin(a),.03),.025,8)
    for x in (-.95,.95):
        k.h.disc('Chair seat',(x,0,.47),.25,.05,'wood')
        for dx in (-.17,.17):
            for dy in (-.17,.17):b.cylinder('iron',(x+dx,dy,.03),(x+dx,dy,.46),.018,6)
        k.h.curve('Chair back',[(x-.22,.18,.46),(x-.22,.22,.98),(x+.22,.22,.98),(x+.22,.18,.46)],.022,'iron')
    k.h.disc('Saucer',(.19,.08,.902),.12,.015,'cream')
    torus('Cup rim',(.19,.08,1.03),.065,.014,'cream')
    # Hollow cup walls and low tea, rather than a solid lid.
    for i in range(20):
        a=math.tau*i/20;b.box('cream',(.19+math.cos(a)*.066,.08+math.sin(a)*.066,.975),(.025,.025,.1),.005)
    k.h.disc('Tea',(.19,.08,.94),.055,.008,'wood_dark')
    torus('Cup handle',(.28,.08,.99),.036,.012,'cream',(math.pi/2,0,0))
    b.box('paper',(-.18,-.05,.9),(.24,.32,.012),.003,(0,0,.22))
    for i in range(5):b.box('ink',(-.18,-.16+i*.035,.908),(.16,.007,.002),0,(0,0,.22))
    b.finish()


def robot(b):
    # Teen-sized town world, squat worker: a rolling trolley base, not human legs.
    for x in (-.27,.27):
        b.cylinder('rubber',(x-.05,0,.2),(x+.05,0,.2),.19,20)
        b.cylinder('brass',(x-.058,0,.2),(x+.058,0,.2),.09,16)
    b.box('teal',(0,0,.35),(.56,.5,.25),.08)
    b.sphere('cream',(0,0,.68),.36,3,(1,.8,1.15))
    k.h.disc('Spark window',(0,-.285,.77),.2,.03,'spark',(math.pi/2,0,0))
    torus('Window rim',(0,-.32,.77),.2,.035,'brass',(math.pi/2,0,0))
    for x in (-.07,.07):b.sphere('white',(x,-.34,.79),.025,2)
    b.sphere('teal',(0,0,1.06),.37,3,(1,1,.42))
    torus('Cap brim',(0,0,1.04),.34,.035,'teal')
    b.sphere('red',(0,0,1.25),.065,2)
    for side in (-1,1):
        b.cylinder('brass',(side*.3,0,.75),(side*.46,-.12,.58),.045,10)
        b.sphere('teal',(side*.46,-.12,.58),.07,2)
    b.box('wood',(0,.4,.55),(.5,.35,.38),.025)
    for j in range(3):b.box('wood_light',(0,.59,.43+j*.11),(.48,.025,.07),.006)
    for j in range(4):b.box('paper',(-.15+j*.1,.4,.79),(.07,.2,.22),.004)
    b.finish()


def node(b):
    # Freestanding service pedestal carries the same real screen/small socket language as the workshop.
    b.box('limestone',(0,0,.08),(.75,.6,.16),.025)
    b.box('teal',(0,0,.72),(.48,.36,1.35),.04)
    b.box('enamel_cream',(0,-.04,1.52),(.86,.33,.72),.06)
    glass=k.h.box('terminal_screen',(0,-.215,1.6),(.69,.012,.39),'window',.015)
    glass['part']='terminal_screen'
    b.box('brass',(.22,-.23,1.29),(.14,.03,.14),.015)
    k.h.disc('Socket',(.22,-.25,1.29),.04,.02,'steel_dark',(math.pi/2,0,0))
    light=k.h.box('connection_lamp',(-.25,-.24,1.31),(.055,.018,.055),'lamp_glass',.015)
    light['part']='connection_lamp'
    k.lettering('Node label','SQUARE',(0,-.226,1.86),.11,'ink')
    b.box('teal_dark',(0,0,1.97),(.96,.5,.12),.03)
    b.finish()


if __name__=='__main__':
    requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(ASSETS)
    makers=[square_set,rootwell,hall,lambda b:shop(b,0),lambda b:shop(b,1),lambda b:shop(b,2),market,cafe,robot,node]
    for asset in requested:
        if asset not in ASSETS: raise ValueError(asset)
        k.guard([asset]); b=begin(asset); makers[ASSETS.index(asset)](b)
        save(asset,('window_dome','window highlight','terminal_screen','connection_lamp'))
