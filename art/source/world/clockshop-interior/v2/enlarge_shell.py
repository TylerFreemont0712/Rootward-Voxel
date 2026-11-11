"""Deliberate saved-master edit: 14×14 room, unchanged door frame/hinges and floor texel scale."""
from pathlib import Path
import bpy,bmesh,hashlib,json,sys
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/clockshop-shell/v1/model.blend';target=ROOT/'art/source/world/clockshop-shell/v2/model.blend'
if target.exists():raise RuntimeError('Saved source exists; edit deliberately.')
bpy.ops.wm.open_mainfile(filepath=str(source))
for obj in bpy.context.scene.objects:
 if obj.type!='MESH' or obj.name.startswith('door_leaf'):continue
 bm=bmesh.new();bm.from_mesh(obj.data);seen=set()
 for seed in bm.verts:
  if seed in seen:continue
  group=[seed];seen.add(seed);stack=[seed]
  while stack:
   v=stack.pop()
   for e in v.link_edges:
    n=e.other_vert(v)
    if n not in seen:seen.add(n);group.append(n);stack.append(n)
  pts=[v.co for v in group];lo=Vector(tuple(min(v[i] for v in pts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in pts) for i in range(3)))
  frame=lo.y>-.25 and hi.y<.15 and lo.x>5 and hi.x<7 and hi.z>.2
  if not frame:
   for v in group:
    v.co.x=(v.co.x+.5)*14/12-.5;v.co.y=(v.co.y+.5)*14/12-.5
 bm.to_mesh(obj.data);bm.free();obj.data.update()
 if obj.name=='clockshop_floor':
  for poly in obj.data.polygons:
   for li in poly.loop_indices:
    v=obj.data.vertices[obj.data.loops[li].vertex_index].co;obj.data.uv_layers.active.data[li].uv=(v.x/2.4,v.y/2.4)
# Close the old window's unframed side gaps; retain the existing enlarged glazing and joinery.
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'));import house_kit as k
k.M.clear();k.M.update({m.name:m for m in bpy.data.materials});p=k.Parts(1104)
for x,w in [(5.90,.96),(10.88,.60)]:p.box('clockshop_wall',(x,13.57,2.63),(w,.24,2.27),bevel=.008)
p.finish(bpy.data.objects['clockshop_shell'])
target.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(target))
target.with_name('expansion.json').write_text(json.dumps({'previous_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'size':[14,14],'door_unchanged':True,'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
