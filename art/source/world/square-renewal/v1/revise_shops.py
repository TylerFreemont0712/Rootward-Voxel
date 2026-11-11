"""Deliberate storefront edits on copied adopted masters. Never recreates their upper stories.
Run once after copying an existing source into a new version. Refuses an already revised source.
Normal exports: scripts/world-art.sh build <id>. Coordinates are Blender metres.
"""
from pathlib import Path
import sys,json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'))
import house_kit as k
SPECS={
 'haverlund-bakery':('MORNING LOAF','bread',2.5,.3,'6d9582'),
 'haverlund-greengrocer':('THE PANTRY','food',2.3,.5,'6b8f84'),
 'haverlund-bookshop':('FINCH & THREAD','clothes',2.5,-.3,'657e9e'),
 'haverlund-clockmaker':('PENDULUM & PIN','clock',2.3,.5,'456e79'),
 'haverlund-apothecary':('THYME & TONIC','herbs',2.3,0,'607b65'),
}

def revise(id):
 cat=json.load(open(ROOT/'pipeline/world-catalog.json'));path=ROOT/cat['assets'][id]['source']
 bpy.ops.wm.open_mainfile(filepath=str(path))
 if bpy.context.scene.get('square_renewal'):raise RuntimeError('Already revised: '+id)
 source_hash=hashlib.sha256(path.read_bytes()).hexdigest()
 label,kind,X,dx,colour=SPECS[id];Y=3.2
 root=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.parent is None)
 # Remove only front ground-floor joinery, old wares/signs and their picture panes.
 # Ground-floor side/back masonry and all adopted upper floors/plant revisions remain.
 removed=0
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  if o.name.startswith(('detail_wares','detail_planters','shop_glass','bread')):
   removed+=len(o.data.polygons);bpy.data.objects.remove(o,do_unlink=True);continue
  bm=bmesh.new();bm.from_mesh(o.data)
  take=[]
  for f in bm.faces:
   pts=[o.matrix_world@v.co for v in f.verts]
   if max(p.z for p in pts)<3.42 and max(p.y for p in pts)<-3.035 and min(p.x for p in pts)>-X+.29 and max(p.x for p in pts)<X-.29:
    take.append(f)
   elif min(p.y for p in pts)<-3.44 and max(p.z for p in pts)<4.55 and max(p.y for p in pts)<-3.18:
    take.append(f)
  removed+=len(take)
  if take:bmesh.ops.delete(bm,geom=take,context='FACES')
  bm.to_mesh(o.data);bm.free();o.data.update()
 # Reuse the exact packed painted surface materials.
 k.M.clear()
 for m in bpy.data.materials:k.M[m.name]=m
 k.material('shop_joinery',colour,roughness=.78)
 k.material('shop_recess','263b3c',roughness=.93)
 k.material('shop_glazing','8eb2b6',roughness=.22)
 k.material('shop_cream','eee3c4',roughness=.8)
 k.material('shop_brass','be9b56',roughness=.45,metallic=.3)
 k.material('lamp_glass','ffe1a0',emission=.5)
 p=k.Parts(1103)
 # Deep dark reveal behind an opening door; sill, jambs and a glazed transom.
 dw,dh=1.15,2.4
 p.box('shop_recess',(dx,-2.84,dh/2),(dw,.045,dh),bevel=0)
 for x in [dx-dw/2-.09,dx+dw/2+.09]:
  p.box('shop_joinery',(x,-3.22,1.42),(.14,.24,2.84),bevel=.012)
 p.box('stone',(dx,-3.36,.045),(dw+.3,.5,.09),bevel=.018)
 p.box('shop_cream',(dx,-3.225,2.48),(dw,.1,.1),bevel=.008)
 p.box('shop_glazing',(dx,-3.16,2.68),(dw,.035,.3),bevel=0)
 # Each display is a real recessed box, with goods in front of its dark backing.
 for side,(a,b) in enumerate([(-X+.36,dx-dw/2-.17),(dx+dw/2+.17,X-.36)]):
  if b-a<.23:continue
  c=(a+b)/2;w=b-a
  p.box('shop_recess',(c,-2.87,1.56),(w,.04,1.98),bevel=0)
  p.box('shop_joinery',(c,-3.18,.32),(w,.16,.64),bevel=.01)
  for x in [a+.035,b-.035]:p.box('shop_cream',(x,-3.21,1.71),(.065,.12,2.14),bevel=.005)
  for z in [.67,2.76]:p.box('shop_cream',(c,-3.22,z),(w+.04,.16,.08),bevel=.006)
  p.box('shop_brass',(c,-3.22,2.43),(w,.025,.025),bevel=0)
  # Sparse pale diagonal glazing strokes preserve a glass reading without a flat shop photograph.
  p.box('shop_glazing',(a+w*.22,-3.19,2.19),(.026,.015,.44),(0,math.radians(-25),0),0)
  p.box('shop_glazing',(a+w*.29,-3.19,2.2),(.016,.014,.29),(0,math.radians(-25),0),0)
  p.box('timber',(c,-3.04,.85),(w,.32,.08),bevel=.008)
  display(p,kind,c,-3.10,.92,w)
  if w>.7:
   p.box('timber',(c,-3.01,1.68),(w,.26,.065),bevel=.008)
   display(p,kind,c,-3.06,1.72,w)
 # Legible fascia and cornice, matching but distinct paints.
 p.box('shop_joinery',(0,-3.22,3.08),(2*X-.5,.2,.44),bevel=.018)
 for z in [2.88,3.29]:p.box('shop_brass',(0,-3.33,z),(2*X-.6,.025,.025),bevel=.002)
 k.text(p,'shop_cream',label,k.facing_text(0,-3.332,3.08,(0,-1)),min(.19,(2*X-.95)/len(label)*1.45))
 p.box('timber',(0,-3.24,3.36),(2*X-.35,.32,.09),bevel=.012)
 # A wall lantern belongs to the shop's power circuit.
 lx=-X+.22
 p.box('shop_brass',(lx,-3.38,2.76),(.28,.3,.08),bevel=.015)
 p.box('lamp_glass',(lx,-3.38,2.96),(.21,.22,.34),bevel=.005)
 p.box('shop_joinery',(lx,-3.38,3.17),(.31,.33,.09),bevel=.012)
 # A physically hinged leaf. Preserve glass as a separate child, with the common swing metadata on its pivot.
 hinge=bpy.data.objects.new('door_leaf_shop',None);bpy.context.scene.collection.objects.link(hinge)
 hinge.parent=root;hinge.location=(dx-dw/2,-3.17,0);hinge['swing']=-100
 door=k.Parts(1104)
 for x in [.06,dw-.06]:door.box('shop_joinery',(x,0,dh/2),(.12,.10,dh),bevel=.012)
 for z,h in [(.08,.16),(.65,.16),(2.34,.12)]:door.box('shop_joinery',(dw/2,0,z),(dw,.1,h),bevel=.012)
 door.box('shop_joinery',(dw/2,.01,.36),(dw-.2,.065,.48),bevel=.01)
 door.box('shop_glazing',(dw/2,.012,1.52),(dw-.24,.035,1.56),bevel=.004)
 door.box('shop_cream',(dw/2,-.025,1.51),(.045,.035,1.56),bevel=.004)
 door.box('shop_cream',(dw/2,-.027,1.7),(dw-.23,.035,.045),bevel=.004)
 door.box('shop_brass',(dw-.17,-.09,1.03),(.045,.05,.24),bevel=.014)
 door.finish(hinge)
 p.finish(root)
 bpy.context.scene['square_renewal']=True
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('square-renewal.json').write_text(json.dumps({'derived_from_sha256':source_hash,'removed_front_faces':removed,'label':label,'door_center':[dx,-3.17],'record':str(Path(__file__).relative_to(ROOT))},indent=2))
 print('REVISED',id,removed)

def display(p,kind,x,y,z,w):
 n=max(1,int(w/.26));step=w/(n+1)
 if kind in ['bread','food','herbs']:
  for i in range(n):
   xx=x-w/2+(i+1)*step
   if kind=='bread':
    p.sphere('shop_cream',(xx,y,z+.10),.13,1,(.65,1.2,.65))
    for dx in [-.045,.035]:p.box('shop_brass',(xx+dx,y-.07,z+.18),(.012,.12,.012),bevel=0)
   elif kind=='food':
    p.box('timber',(xx,y,z+.09),(.22,.20,.18),bevel=.008)
    for dx in [-.05,.04]:p.sphere('flower_orange' if i%2 else 'olive',(xx+dx,y-.04,z+.22),.065,1)
   else:
    p.cylinder('shop_glazing',(xx,y,z),(xx,y,z+.26),.065,10,uv='flat')
    p.box('shop_cream',(xx,y-.067,z+.13),(.085,.009,.10),bevel=.002)
    p.cylinder('shop_brass',(xx,y,z+.26),(xx,y,z+.31),.041,8,uv='flat')
 elif kind=='clock':
  for i in range(max(1,int(w/.55))):
   nn=max(1,int(w/.55));xx=x+(i-(nn-1)/2)*.5
   p.box('timber',(xx,y,z+.24),(.39,.19,.48),bevel=.035)
   p.cylinder('shop_cream',(xx,y-.105,z+.28),(xx,y-.12,z+.28),.16,20,uv='flat')
   p.box('shop_recess',(xx,y-.13,z+.33),(.014,.015,.10),bevel=0)
   p.box('shop_recess',(xx+.05,y-.13,z+.28),(.1,.015,.014),bevel=0)
 else:
  # Folded bolts and a small hanging shirt silhouette.
  for i in range(n):
   p.box('cloth_rose' if i%2 else 'cloth_blue',(x-w/2+(i+1)*step,y,z+.11),(.19,.22,.22),bevel=.035)
  if w>.8:
   p.box('shop_cream',(x,y,z+.57),(.29,.08,.40),bevel=.02)
   for side in [-1,1]:p.box('shop_cream',(x+side*.19,y,z+.68),(.2,.08,.16),(0,side*.3,0),.015)

for id in sys.argv[sys.argv.index('--')+1:]:revise(id)
