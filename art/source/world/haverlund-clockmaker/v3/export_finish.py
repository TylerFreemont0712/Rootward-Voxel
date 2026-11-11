"""Preserve native material tones through glTF and combine only the fixture's emitting panes."""
from pathlib import Path
import sys,hashlib
import bpy
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_export_finish'):raise RuntimeError('Export finish already applied.')
before=hashlib.sha256(path.read_bytes()).hexdigest();root=bpy.data.objects['haverlund_clockmaker']
# Blender 5's glTF exporter recognizes the modern RGBA Mix/Multiply node, not legacy MixRGB factors.
for name,factor in [('clock_copper_painted',(.66,.85,1,1)),('seaside_timber',(.72,.64,.52,1))]:
 mat=bpy.data.materials[name];nodes=mat.node_tree.nodes;bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');tex=next(n for n in nodes if n.type=='TEX_IMAGE')
 for n in list(nodes):
  if n.type=='MIX_RGB':nodes.remove(n)
 mix=nodes.new('ShaderNodeMix');mix.data_type='RGBA';mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
 a=next(s for s in mix.inputs if s.identifier=='A_Color');b=next(s for s in mix.inputs if s.identifier=='B_Color');out=next(s for s in mix.outputs if s.type=='RGBA')
 b.default_value=factor;mat.node_tree.links.new(tex.outputs['Color'],a);mat.node_tree.links.new(out,bs.inputs['Base Color'])
# There is one logical fixture. Its three lamp bulbs form one mesh, separate from every clear window pane.
verts=[];faces=[];lamp_objects=[]
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 used={obj.data.materials[f.material_index].name for f in obj.data.polygons}
 if not used or not all('lamp_glass' in name for name in used):continue
 base=len(verts);M=root.matrix_world.inverted()@obj.matrix_world;verts.extend(tuple(M@v.co) for v in obj.data.vertices);faces.extend(tuple(base+i for i in f.vertices) for f in obj.data.polygons);lamp_objects.append(obj)
mesh=bpy.data.meshes.new('clockmaker_lamp_glass');mesh.from_pydata(verts,[],faces);mesh.materials.append(bpy.data.materials['house_lamp_glass']);mesh.uv_layers.new(name='UVMap');mesh.update()
obj=bpy.data.objects.new('clockmaker_lamp_glass',mesh);bpy.context.scene.collection.objects.link(obj);obj.parent=root;obj['surface_role']='lamp_glass'
for old in lamp_objects:bpy.data.objects.remove(old,do_unlink=True)
# Remove the retained v2 left planter where the replacement would otherwise overlap it.
old=bpy.data.objects.get('house_paint')
if old:discard_components(old,lambda lo,hi,c:c.x<-3.3 and c.y<-2.55 and hi.z<2.5)
bpy.context.scene['clock_export_finish']=True
save_record(path,'export_finish',before)
print('EXPORT MATERIALS AND ONE FIXTURE GLASS MESH SAVED')
