"""Deliberate edits of adopted masters. Run once in Blender; never initializes the scene.
Removes only the earlier tagged grid, insets framed channels, and retextures existing pilasters.
Source backups and the generated surface audit sit beside each master.
"""
import bpy, bmesh, math, json, shutil, sys
from pathlib import Path
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent

# Every route is in the area's authoring coordinates and ends at an entrance, a junction or beyond the district.
ROUTES={
'haverlund-square-ground':[
 ('root-west',[(35.30,24),(21.7,24)]),
 ('market-spine',[(21.7,2.5),(21.7,46)]),
 ('spindle-street',[(21.7,8),(-32.4,8)]),
 ('hill-street',[(21.7,46),(14.5,46),(14.5,96.4)]),
 ('root-north',[(42,30.70),(42,47)]),
 ('civic-spine',[(23,51),(23,47),(58.5,47),(58.5,51.4)]),
 ('guild-feed',[(41,47),(41,52)]),
 ('root-east',[(48.70,24),(69.5,24)]),
 ('lantern-street',[(69.5,24),(69.5,45.5),(106.4,45.5)]),
 ('root-south',[(42,17.30),(42,2.5)]),
 ('promenade',[(21.7,2.5),(60.5,2.5)]),
 ('harbour-steps',[(60.5,2.5),(60.5,-40.4)]),
],
'haverlund-lane-set':[
 ('street-trunk',[(12.5,29.5),(12.5,24.85),(13.5,24.85),(13.5,2.9)]),
 ('workshop-threshold',[(13.5,12),(8.65,12)]),
 ('nell-threshold',[(13.5,19.3),(8.38,19.3)]),
 ('bram-threshold',[(13.5,24.85),(4.78,24.85)]),
 ('tram-platform',[(1.2,2.9),(23.2,2.9)]),
 ('tram-shelter',[(19.6,2.9),(19.6,4.0)]),
],
'haverlund-lane-surround':[
 ('town-steps-continuation',[(12.5,29.5),(12.5,76.4)]),
]}

class Meshes:
 def __init__(self):self.parts={}
 def face(self,mat,points,uv=None):
  d=self.parts.setdefault(mat,[[],[],[]]);n=len(d[0]);d[0].extend(points);d[1].append(tuple(range(n,n+len(points))));d[2].append(uv or [(0,0)]*len(points))
 def quad(self,mat,a,b,side,ua=0,ub=1):
  self.face(mat,[a-side,b-side,b+side,a+side],[(ua,0),(ub,0),(ub,1),(ua,1)])
 def finish(self,root):
  for key,(vs,fs,uvs) in self.parts.items():
   mesh=bpy.data.meshes.new(key);mesh.from_pydata(vs,[],fs);mesh.update();uv=mesh.uv_layers.new(name='GridUV')
   for poly,coords in zip(mesh.polygons,uvs):
    for li,co in zip(poly.loop_indices,coords):uv.data[li].uv=co
   o=bpy.data.objects.new(key,mesh);bpy.context.scene.collection.objects.link(o);o.parent=root;o.data.materials.append(bpy.data.materials[key]);o['grid_inlay']=True
   if key=='grid_glass':o['power_grid']=True

def material(name,color,metallic=0):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Metallic'].default_value=metallic;bs.inputs['Roughness'].default_value=.56
 if name=='grid_glass':bs.inputs['Emission Color'].default_value=(1,.48,.12,1);bs.inputs['Emission Strength'].default_value=.45
 return m

# Split original planar paving faces around the channel mouth. UVs are interpolated along cut edges.
def clip(poly,axis,value,keep_less):
 out=[]
 for a,b in zip(poly,poly[1:]+poly[:1]):
  av=a[0][axis]-value;bv=b[0][axis]-value;ina=av<=1e-7 if keep_less else av>=-1e-7;inb=bv<=1e-7 if keep_less else bv>=-1e-7
  if ina:out.append(a)
  if ina!=inb:
   t=av/(av-bv);out.append((a[0].lerp(b[0],t),a[1].lerp(b[1],t)))
 return out

def recess(o,rectangles):
 if not rectangles:return 0
 mesh=o.data;uv=mesh.uv_layers.active;records=[];changed=0
 for poly in mesh.polygons:
  pts=[(o.matrix_world @ mesh.vertices[mesh.loops[li].vertex_index].co,uv.data[li].uv.copy() if uv else Vector((0,0))) for li in poly.loop_indices]
  pieces=[pts]
  if abs(poly.normal.z)>.99:
   xs=[q[0].x for q in pts];ys=[q[0].y for q in pts];zz=pts[0][0].z
   for x0,y0,x1,y1,z in rectangles:
    if abs(zz-z)>.006 or max(xs)<=x0 or min(xs)>=x1 or max(ys)<=y0 or min(ys)>=y1:continue
    nexts=[]
    for piece in pieces:
     inside=piece
     for axis,v,less in [(0,x0,False),(0,x1,True),(1,y0,False),(1,y1,True)]:
      outside=clip(inside,axis,v,not less)
      if len(outside)>=3:nexts.append(outside)
      inside=clip(inside,axis,v,less)
      if len(inside)<3:break
    pieces=nexts;changed+=1
  for piece in pieces:
   if len(piece)>=3:records.append((piece,poly.material_index))
 # Drop degenerate clipped polygons.
 inverse=o.matrix_world.inverted();vs=[];fs=[];coords=[];mats=[]
 for piece,mi in records:
  if len(piece)<3:continue
  area=sum((piece[i][0]-piece[0][0]).cross(piece[i+1][0]-piece[0][0]).length for i in range(1,len(piece)-1))
  if area<1e-8:continue
  n=len(vs);vs.extend([inverse @ q[0] for q in piece]);fs.append(tuple(range(n,n+len(piece))));coords.append([q[1] for q in piece]);mats.append(mi)
 new=bpy.data.meshes.new(mesh.name+'_recessed');new.from_pydata(vs,[],fs);new.update()
 for mat in mesh.materials:new.materials.append(mat)
 layer=new.uv_layers.new(name='UVMap')
 for poly,cs,mi in zip(new.polygons,coords,mats):
  poly.material_index=mi
  for li,co in zip(poly.loop_indices,cs):layer.data[li].uv=co
 o.data=new
 return changed

def extract_pillars(o):
 bm=bmesh.new();bm.from_mesh(o.data);seen=set();chosen=[]
 for v in bm.verts:
  if v in seen:continue
  stack=[v];seen.add(v);group=[]
  while stack:
   q=stack.pop();group.append(q)
   for e in q.link_edges:
    u=e.other_vert(q)
    if u not in seen:seen.add(u);stack.append(u)
  lo=Vector(tuple(min(v.co[i] for v in group) for i in range(3)));hi=Vector(tuple(max(v.co[i] for v in group) for i in range(3)));size=hi-lo
  if size.z>3 and .48<max(size.x,size.y)<.75 and .08<min(size.x,size.y)<.4:chosen.append((group,lo,hi))
 if not chosen:bm.free();return 0
 verts=[];faces=[];uvs=[];remove=[]
 for group,lo,hi in chosen:
  index={v:len(verts)+i for i,v in enumerate(group)};verts.extend([v.co.copy() for v in group]);ff=set(f for v in group for f in v.link_faces);axis=0 if hi.x-lo.x>hi.y-lo.y else 1
  for f in ff:
   faces.append(tuple(index[v] for v in f.verts));uvs.append([((v.co[axis]-lo[axis])/(hi[axis]-lo[axis]),(v.co.z-lo.z)/(hi.z-lo.z)) for v in f.verts])
  remove.extend(group)
 bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(o.data);bm.free()
 mesh=bpy.data.meshes.new('Existing_power_pillars');mesh.from_pydata(verts,[],faces);mesh.update();layer=mesh.uv_layers.new(name='PillarUV')
 for f,cs in zip(mesh.polygons,uvs):
  for li,uv in zip(f.loop_indices,cs):layer.data[li].uv=uv
 p=bpy.data.objects.new('Existing_power_pillars',mesh);bpy.context.scene.collection.objects.link(p);p.matrix_world=o.matrix_world;p.parent=o.parent;p['power_pillar']=True;p.data.materials.append(o.data.materials[0])
 return len(chosen)

def make_bvh(objects):
 verts=[];faces=[]
 for o in objects:
  if o.type!='MESH':continue
  n=len(verts);verts.extend([o.matrix_world @ v.co for v in o.data.vertices]);faces.extend([tuple(n+i for i in f.vertices) for f in o.data.polygons])
 return BVHTree.FromPolygons(verts,faces)

def edit(asset):
 file=ROOT/'art/source/world'/asset/'v1/model.blend';backup=file.with_name('model.pre-grid-inlay.blend')
 bpy.ops.wm.open_mainfile(filepath=str(file))
 if bpy.context.scene.get('grid_inlay_revision'):raise RuntimeError('Revision already applied; edit the master rather than rerunning this one-time source edit.')
 if not backup.exists():shutil.copy2(file,backup)
 root=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and not o.parent)
 for o in list(bpy.context.scene.objects):
  if o.get('power_grid',False):bpy.data.objects.remove(o,do_unlink=True)
 # Remove only the old straight cardinal brass pieces; preserve the Rootwell's round rings.
 if asset=='haverlund-square-ground':
  o=bpy.data.objects['ground_brass'];bm=bmesh.new();bm.from_mesh(o.data)
  bad=[v for v in bm.verts if ((abs(v.co.x-42)<.12 and abs(v.co.y-24)>6.65) or (abs(v.co.y-24)<.12 and abs(v.co.x-42)>6.65))]
  bmesh.ops.delete(bm,geom=bad,context='VERTS');bm.to_mesh(o.data);bm.free()
 for name,col,metal in [('grid_bed',(.075,.09,.085),.45),('grid_bronze',(.33,.24,.12),.68),('grid_glass',(.42,.24,.065),.18),('grid_stone',(.49,.45,.34),0)]:material(name,col,metal)
 ground=[o for o in bpy.context.scene.objects if o.type=='MESH' and (o.name.startswith(('ground_','seaside_stone','lane_flags','lane_cobbles','lane_grass','lane_limestone')))]
 bvh=make_bvh(ground)
 # Doorsteps belong to separate building models. Include their actual transformed surfaces in the survey.
 buildings=[]
 if asset=='haverlund-lane-set':
  for aid,at in [('lane-workshop',(4.75,13.5,1)),('lane-nell-house',(4.8,20,1)),('lane-cottage',(2.5,25.45,1)),('lane-tram-shelter',(19.6,3.75,0))]:
   with bpy.data.libraries.load(str(ROOT/'art/source/world'/aid/'v1/model.blend'),link=False) as (src,dst):dst.objects=[n for n in src.objects]
   for o in dst.objects:
    if o is not None and o.type=='MESH':
     # Read library object's authored world transform, including its root.
     verts=[Matrix.Translation(at) @ o.matrix_world @ v.co for v in o.data.vertices];mesh=bpy.data.meshes.new('survey');mesh.from_pydata(verts,[],[tuple(f.vertices) for f in o.data.polygons]);mesh.update();tmp=bpy.data.objects.new('survey',mesh);buildings.append(tmp)
  door_bvh=make_bvh(buildings)
 else:door_bvh=None
 meshout=Meshes();rects=[];audit=[]
 def height(x,y):
  hit=bvh.ray_cast(Vector((x,y,20)),Vector((0,0,-1)),60)[0]
  if hit is None:
   nearby=[bvh.ray_cast(Vector((x+dx,y+dy,20)),Vector((0,0,-1)),60)[0] for dx,dy in [(.025,0),(-.025,0),(0,.025),(0,-.025)]]
   nearby=[h for h in nearby if h is not None];hit=max(nearby,key=lambda h:h.z) if nearby else None
  z=hit.z if hit is not None else None
  if door_bvh is not None and x<10 and y>9:
   hh=door_bvh.ray_cast(Vector((x,y,1.8)),Vector((0,0,-1)),1.0)[0]
   if hh is not None and hh.z<1.5:z=max(z or 1,hh.z)
  return z
 def strip(a,b,distance,normal_override=None):
  d=b-a;length=d.length
  if length<1e-5:return
  side_hint=Vector((-d.y,d.x,0)).normalized() if abs(d.x)+abs(d.y)>1e-5 else last_side
  normal=d.cross(side_hint).normalized() if abs(d.x)+abs(d.y)>1e-5 else Vector((0,-1,0))
  if normal_override is not None:normal=normal_override
  # For risers use the outward-facing horizontal direction of travel.
  if abs(d.z)>abs(d.x)+abs(d.y):normal=Vector((0,-1,0))
  side=Vector((-d.y,d.x,0)).normalized() if abs(d.x)+abs(d.y)>1e-5 else last_side
  a=a+normal*.006;b=b+normal*.006
  meshout.quad('grid_bed',a-normal*.018,b-normal*.018,side*.19,distance,distance+length)
  for off in [-.142,.142]:meshout.quad('grid_bronze',a+side*off,b+side*off,side*.018,distance,distance+length)
  # Narrow luminous panes, broken by metal crossbars at regular service intervals.
  count=max(1,math.ceil(length/.55))
  for i in range(count):
   t0=(i+.025)/count;t1=(i+.975)/count
   meshout.quad('grid_glass',a.lerp(b,t0)-normal*.004,b.lerp(a,1-t1)-normal*.004,side*.082,distance+length*t0,distance+length*t1)
  if abs(d.z)<.01:
   x0=min(a.x,b.x)-abs(side.x)*.19;y0=min(a.y,b.y)-abs(side.y)*.19;x1=max(a.x,b.x)+abs(side.x)*.19;y1=max(a.y,b.y)+abs(side.y)*.19
   if x1-x0>.01 and y1-y0>.01:rects.append((x0,y0,x1,y1,a.z-.006))
 # Survey every path at 2.5 cm intervals, compress into level runs, and explicitly wrap each riser.
 for name,points in ROUTES[asset]:
  previous=None;distance=0;last_side=Vector((1,0,0));runs=0
  for aa,bb in zip(points,points[1:]):
   aa=Vector(aa);bb=Vector(bb);n=max(1,round((bb-aa).length/.025));samples=[]
   for i in range(n+1):
    q=aa.lerp(bb,i/n);z=height(q.x,q.y)
    if z is None:raise RuntimeError(f'Unsupported route {asset}:{name} at {q}')
    samples.append(Vector((q.x,q.y,z)))
   start=samples[0];prev=start
   for q in samples[1:]:
    if abs(q.z-prev.z)>.004:
     # The ray sample brackets the nosing. Find the exact surface edge by bisection.
     left=prev.copy();right=q.copy()
     for _ in range(10):
      mid=(left+right)*.5;z=height(mid.x,mid.y)
      if abs(z-prev.z)<.004:left=Vector((mid.x,mid.y,prev.z))
      else:right=Vector((mid.x,mid.y,q.z))
     edge=(left+right)*.5;lowend=Vector((edge.x,edge.y,prev.z));highstart=Vector((edge.x,edge.y,q.z));last_side=Vector((-(bb-aa).y,(bb-aa).x,0)).normalized()
     strip(start,lowend,distance);distance+=(lowend-start).length
     # Bias outward toward the lower tread so the riser trim is visible rather than buried in the stone.
     lower_dir=Vector((bb.x-aa.x,bb.y-aa.y,0)).normalized()*(1 if q.z<prev.z else -1)
     delta=lower_dir*.012
     strip(lowend+delta,highstart+delta,distance,lower_dir);distance+=abs(q.z-prev.z);start=highstart;runs+=1
    prev=q
   strip(start,samples[-1],distance);distance+=(samples[-1]-start).length
  audit.append({'route':name,'start':points[0],'end':points[-1],'length':round(distance,3),'risers':runs,'surface_start':height(*points[0]),'surface_end':height(*points[-1])})
 # Recessed service plates make every T and elbow an intentional fitting.
 joints={
  'haverlund-square-ground':[(21.7,24),(21.7,8),(21.7,46),(14.5,46),(42,47),(41,47),(23,47),(58.5,47),(69.5,24),(69.5,45.5),(42,2.5),(60.5,2.5),(21.7,2.5)],
  'haverlund-lane-set':[(13.5,12),(13.5,19.3),(13.5,24.85),(12.5,24.85),(13.5,2.9),(19.6,2.9),(1.2,2.9),(23.2,2.9)],
  'haverlund-lane-surround':[]
 }
 for x,y in joints[asset]:
  z=height(x,y)+.009
  meshout.face('grid_bronze',[(x-.27,y-.27,z),(x+.27,y-.27,z),(x+.27,y+.27,z),(x-.27,y+.27,z)])
  meshout.face('grid_bed',[(x-.23,y-.23,z+.001),(x+.23,y-.23,z+.001),(x+.23,y+.23,z+.001),(x-.23,y+.23,z+.001)])
  for d in [(1,0),(0,1)]:
   a=Vector((x-d[0]*.21,y-d[1]*.21,z+.002));b=Vector((x+d[0]*.21,y+d[1]*.21,z+.002));side=Vector((-d[1]*.06,d[0]*.06,0));meshout.quad('grid_glass',a,b,side,0,.42)
  for dx in [-.21,.21]:
   for dy in [-.21,.21]:
    pts=[(x+dx+math.cos(i*math.pi/3)*.018,y+dy+math.sin(i*math.pi/3)*.018,z+.003) for i in range(6)]
    meshout.face('grid_bronze',pts)
 # Inset the channels into original broad paving surfaces. Keep stone stairs' existing bevels and shapes.
 clipped=0
 for o in ground:
  if o.name.startswith(('ground_cobbles','ground_flags','lane_flags','lane_cobbles','lane_grass')):clipped+=recess(o,rects)
 pillars=0
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH' and o.name.startswith('seaside_stone'):pillars+=extract_pillars(o)
 meshout.finish(root)
 for o in buildings:
  bpy.data.objects.remove(o,do_unlink=True)
 bpy.context.scene['grid_inlay_revision']=2;bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(file))
 (file.parent/'grid-inlay-audit.json').write_text(json.dumps({'asset':asset,'routes':audit,'paving_cuts':clipped,'existing_pillars':pillars},indent=2)+'\n')
 print('EDITED',asset,'cuts',clipped,'pillars',pillars,flush=True)

if __name__=='__main__':
 for asset in sys.argv[sys.argv.index('--')+1:]:edit(asset)
