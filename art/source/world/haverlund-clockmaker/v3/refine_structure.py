"""First deliberate pass on a copy of v2: roof curvature, structural openings and joined masonry."""
from pathlib import Path
import sys,math,hashlib
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path(__file__).with_name('model.blend');previous=ROOT/'art/source/world/haverlund-clockmaker/v2/model.blend'
if path.exists():raise RuntimeError('v3 already exists: edit the saved master.')
bpy.ops.wm.open_mainfile(filepath=str(previous));before=hashlib.sha256(previous.read_bytes()).hexdigest();bind_materials()
root=bpy.data.objects['haverlund_clockmaker']
# Remove only the old copper geometry and its panel overlay, leaving all adopted structural walls and semantic pivots.
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':continue
 if o.name=='copper_sheet_panels':bpy.data.objects.remove(o,do_unlink=True);continue
 remove_material_faces(o,lambda m,c:'clock_copper' in m or m.startswith('clock_patinated_copper'))
 # Dormer box/window/finial, eave brackets and unsupported forward pipes are bounded disconnected pieces.
 if o.name.startswith(('clock_hour_hand','clock_minute_hand','clock_pendulum','door_leaf')):continue
 discard_components(o,lambda lo,hi,c:(lo.x>.12 and hi.x<2.08 and lo.y>-1.62 and hi.y<-.16 and lo.z>6.65 and hi.z<9.1) or (hi.z>5.9 and lo.z<.3 and abs(c.x)>3.7 and c.y<-2.38) or (lo.z>5.65 and hi.z<6.25 and c.y<-2.4))
# Rectify the original offset rectangular holes in the upper front wall. Side/back walls survive untouched.
o=bpy.data.objects.get('seaside_plaster')
if o:
 bm=bmesh.new();bm.from_mesh(o.data)
 fs=[f for f in bm.faces if -2.365<(o.matrix_world@f.calc_center_median()).y<-2.02 and 3.29<(o.matrix_world@f.calc_center_median()).z<6.26 and abs((o.matrix_world@f.calc_center_median()).x)<3.71]
 bmesh.ops.delete(bm,geom=fs,context='FACES');bm.to_mesh(o.data);bm.free();o.data.update()
# Existing tower-side slit was behind a solid wall: open its masonry face rather than draw glass over stone.
o=bpy.data.objects.get('seaside_stone')
if o:
 bm=bmesh.new();bm.from_mesh(o.data)
 for axis,cuts in [(1,[-1.94,-1.26]),(2,[7.55,8.75])]:
  for at in cuts:
   normal=Vector((0,axis==1,axis==2));bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=normal*at,plane_no=normal)
 fs=[f for f in bm.faces if -3.64<f.calc_center_median().x<-3.60 and -1.94<f.calc_center_median().y<-1.26 and 7.55<f.calc_center_median().z<8.75]
 if fs:bmesh.ops.delete(bm,geom=fs,context='FACES')
 bm.to_mesh(o.data);bm.free();o.data.update()
# Approved copper painting, using a patina-dominant section of the existing library. No new raster or runtime shader.
copper=k.material('clock_copper_painted','ffffff',ROOT/'assets/world/textures/lush/copper_patina.png',roughness=.68,metallic=.35)
k.material('clock_copper_edge','49736c',roughness=.63,metallic=.35)
p=k.Parts(110303)
p.group='refined_structure'
k.wall(p,'plaster',(-3.7,-2.35),(3.7,-2.35),3.3,6.25,.30,[(2.95,4.45,3.86,5.67),(5.25,6.65,3.86,5.67)])
# Main roof follows a curved kicked eave and has exact cut-outs around the tower and dormer.
def roofz(y):
 y=abs(y);pts=[(0,8.18),(.35,8.09),(1.4,7.30),(2.28,6.55),(2.60,6.35),(2.83,6.32)]
 for (a,z),(b,w) in zip(pts,pts[1:]):
  if a<=y<=b:return z+(w-z)*(y-a)/(b-a)
 return 6.32
xs=sorted(set([-3.97,-3.78,-1.32,.36,1.84,3.97]+[round(-3.97+i*.47,5) for i in range(1,17)]))
ys=[0,.26,.45,.85,1.25,1.72,2.15,2.60,2.83]
def roof_hole(x,y):return y<-.45 and x<-1.32 or (.36<x<1.84 and -1.72<y<-.26)
for side in [-1,1]:
 for a,b in zip(xs,xs[1:]):
  for c,d in zip(ys,ys[1:]):
   y0=side*c;y1=side*d
   if roof_hole((a+b)/2,(y0+y1)/2):continue
   points=[(a,y0,roofz(y0)),(b,y0,roofz(y0)),(b,y1,roofz(y1)),(a,y1,roofz(y1))]
   if side<0:points.reverse()
   p.solid('clock_copper_painted',points,.045,(0,side,1))
 for x in xs:
  for c,d in zip(ys,ys[1:]):
   if roof_hole(x+.0001,side*(c+d)/2):continue
   p.cylinder('clock_copper_edge',(x,side*c,roofz(c)+.03),(x,side*d,roofz(d)+.03),.018,6)
 p.cylinder('clock_copper_edge',(-3.99,side*2.83,6.32),(3.99,side*2.83,6.32),.065,10)
p.cylinder('clock_copper_edge',(-3.99,0,8.2),(3.99,0,8.2),.065,10)
# Curved bell cap: rounded square rings and raised ribs, flaring over a layered oak cornice.
tx,ty=-2.55,-1.6
rings=[(9.26,1.38),(9.34,1.38),(9.42,1.27),(9.50,1.16),(9.66,1.13),(9.84,1.08),(10.02,.98),(10.18,.82),(10.33,.56),(10.41,.29)]
N=48
def ring_point(r,a,z):
 # Superellipse retains four sides but gives the dome smooth shoulders and rounded corners.
 return (tx+r*math.copysign(abs(math.cos(a))**.57,math.cos(a)),ty+r*math.copysign(abs(math.sin(a))**.57,math.sin(a)),z)
for (z,r),(w,s) in zip(rings,rings[1:]):
 for i in range(N):
  a=math.tau*i/N;b=math.tau*(i+1)/N
  p.solid('clock_copper_painted',[ring_point(r,a,z),ring_point(r,b,z),ring_point(s,b,w),ring_point(s,a,w)],.035,(math.cos((a+b)/2),math.sin((a+b)/2),1))
for i in range(16):
 a=math.tau*i/16
 for (z,r),(w,s) in zip(rings,rings[1:]):p.cylinder('clock_copper_edge',ring_point(r+.015,a,z+.015),ring_point(s+.015,a,w+.015),.018,6)
for z,w,h in [(9.12,2.40,.10),(9.21,2.56,.08),(9.27,2.66,.055)]:p.box('timber',(tx,ty,z),(w,w,h),bevel=.02)
for x in [tx-1.0,tx+1.0]:
 for y in [ty-1.0,ty+1.0]:
  p.box('timber',(x,y,8.99),(.20,.22,.28),bevel=.025)
  p.cylinder('clock_brass',(x,y-.13,8.98),(x,y-.15,8.98),.065,12)
# Joined dormer: a filled arched gable sits on the real roof opening, with a curved copper hood.
dx=1.10;front=-1.77;back=-.36
outline=[(-.79,7.76),(-.62,7.81),(-.48,7.96),(-.30,8.24),(0,8.47),(.30,8.24),(.48,7.96),(.62,7.81),(.79,7.76)]
for y in [front,back]:
 p.solid('timber',[(dx-.68,y,6.78),(dx+.68,y,6.78)]+[(dx+x,y,z) for x,z in reversed(outline[1:-1])],.09,(0,-1 if y==front else 1,0))
for x in [dx-.68,dx+.68]:p.solid('timber',[(x,front,6.78),(x,back,7.95),(x,back,8.0),(x,front,7.86)],.08,(-1 if x<dx else 1,0,0))
for (a,z),(b,w) in zip(outline,outline[1:]):
 p.solid('clock_copper_painted',[(dx+a,front-.14,z+.09),(dx+b,front-.14,w+.09),(dx+b,back+.17,w+.09),(dx+a,back+.17,z+.09)],.045,(0,0,1))
 p.cylinder('timber',(dx+a,front-.16,z+.02),(dx+b,front-.16,w+.02),.055,8)
# Shallow window in front of its opaque joinery, inset frame with real recessed pane.
arch(p,dx,front-.11,7.72,.78,.28,'timber',.085)
for x in [dx-.39,dx+.39]:p.box('timber',(x,front-.10,7.29),(.085,.13,.86),bevel=.008)
p.pane('window_pane',(dx,front-.015,7.40),.74,1.0,(0,-1));p.box('timber',(dx,front-.13,7.38),(.04,.07,.98),bevel=.005)
p.box('timber',(dx,front-.13,7.36),(.78,.07,.045),bevel=.005)
p.cylinder('clock_brass',(dx,-1.04,8.47),(dx,-1.04,8.87),.043,10,radius_b=.012)
p.sphere('clock_brass',(dx,-1.04,8.66),.055,2)
# Continuous fascia cornice and brackets visually support the eave instead of detached wooden blocks.
for x in [-1.15,.30,2.0,3.55]:
 p.box('timber',(x,-2.39,6.03),(.15,.25,.40),bevel=.018)
 p.beam('timber',(x,-2.38,5.81),(x,-2.71,6.24),.14,.13)
p.box('timber',(1.15,-2.48,6.16),(5.55,.30,.13),bevel=.018)
# Rainwater pipes hug the wall and have connected swan necks and anchored brackets.
for x,y in [(-3.76,-2.76),(3.76,-2.40)]:
 p.cylinder('iron',(x,y,.15),(x,y,5.93),.043,10)
 p.beam('iron',(x,y,5.93),(x,-2.82,6.30),.08,.08)
 for z in [.65,2.9,5.2]:p.box('iron',(x,y+.045,z),(.13,.14,.045),bevel=.008,uv='flat')
# Preserve the existing rear porch with a fitted metal lean-to.
p.solid('clock_copper_painted',[(-.16,2.29,3.15),(2.31,2.29,3.15),(2.31,3.34,2.77),(-.16,3.34,2.77)],.055,(0,1,1))
finish(p,root)
# The copper artwork is sampled from a patina-dominant area to avoid orange checkerboard panels.
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 for poly in o.data.polygons:
  if o.data.materials[poly.material_index].name!='clock_copper_painted':continue
  layer=o.data.uv_layers.active
  for li in poly.loop_indices:
   co=o.data.vertices[o.data.loops[li].vertex_index].co
   layer.data[li].uv=(.23+(co.x%1.0)*.15,.49+(co.z%1.3)/1.3*.17)
bpy.context.scene['clockmaker_refinement_pass']=1
save_record(path,'refine_structure',before)
print('PASS 1 SAVED')
