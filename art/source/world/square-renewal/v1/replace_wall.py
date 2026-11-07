"""Replace one straight retaining-wall bay with the reusable module, preserving stair cheeks."""
from pathlib import Path
import bpy,bmesh,json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5];p=ROOT/'art/source/world/haverlund-square-ground/v2/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(p))
if bpy.context.scene.get('modular_wall_bay'):raise RuntimeError('Already replaced')
removed=0
for o in bpy.context.scene.objects:
 if o.type!='MESH' or 'seaside_stone' not in o.name:continue
 bm=bmesh.new();bm.from_mesh(o.data)
 for y in [28.5,31.5]:
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=Vector((0,y,0)),plane_no=Vector((0,1,0)),clear_inner=False,clear_outer=False)
 fs=[f for f in bm.faces if 11.12<f.calc_center_median().x<11.88 and 28.50001<f.calc_center_median().y<31.49999 and -.1<f.calc_center_median().z<2.3]
 removed+=len(fs)
 if fs:bmesh.ops.delete(bm,geom=fs,context='FACES')
 bm.to_mesh(o.data);bm.free();o.data.update()
bpy.context.scene['modular_wall_bay']=True
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p));print('REMOVED WALL FACES',removed)
