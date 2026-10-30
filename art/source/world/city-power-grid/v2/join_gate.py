"""A short riser fitting across the authored six-centimetre set/surround seam."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[5]
p=ROOT/'art/source/world/haverlund-lane-surround/v1/model.blend';bpy.ops.wm.open_mainfile(filepath=str(p))
assert 'Gate_power_coupler' not in bpy.data.objects
root=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and not o.parent)
for name,cx,width in [('Gate_power_coupler',12.5,.164),('Gate_coupler_left',12.358,.036),('Gate_coupler_right',12.642,.036)]:
 mesh=bpy.data.meshes.new(name);mesh.from_pydata([(cx-width/2,29.496,-.534),(cx-width/2,29.496,-.594),(cx+width/2,29.496,-.594),(cx+width/2,29.496,-.534)],[],[(0,1,2,3)]);mesh.update();uv=mesh.uv_layers.new(name='GridUV')
 for li,co in zip(mesh.polygons[0].loop_indices,[(0,0),(.06,0),(.06,1),(0,1)]):uv.data[li].uv=co
 o=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(o);o.parent=root;o['grid_inlay']=True
 if name=='Gate_power_coupler':o['power_grid']=True;o.data.materials.append(bpy.data.materials['grid_glass'])
 else:o.data.materials.append(bpy.data.materials['grid_bronze'])
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p))
