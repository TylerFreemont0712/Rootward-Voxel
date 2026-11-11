"""Final saved-master checks: lamp emitters are separate from window glazing; retain all geometry and pivots."""
from pathlib import Path
import sys,hashlib,json
import bpy,bmesh
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_material_roles'):raise RuntimeError('Roles already finalized.')
before=hashlib.sha256(path.read_bytes()).hexdigest()
# Runtime fixture overrides apply per mesh. An emitting lamp and a display pane must never share one mesh.
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH' or not obj.name.startswith('refined_'):continue
 roles={}
 for face in obj.data.polygons:
  mat=obj.data.materials[face.material_index]
  role='lamp_glass' if 'lamp_glass' in mat.name else 'clear_glass' if mat.name=='clock_clear_glass' else 'backing_panes' if 'window_pane' in mat.name else 'body'
  roles.setdefault(role,[]).append(face.index)
 if not ('lamp_glass' in roles and len(roles)>1) and not ('clear_glass' in roles and len(roles)>1):continue
 for role,indices in roles.items():
  bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table();keep=set(indices)
  bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in keep],context='FACES')
  mesh=bpy.data.meshes.new(obj.name+'_'+role);bm.to_mesh(mesh);bm.free()
  for mat in obj.data.materials:mesh.materials.append(mat)
  out=bpy.data.objects.new(obj.name+'_'+role,mesh);bpy.context.scene.collection.objects.link(out);out.parent=obj.parent;out.matrix_world=obj.matrix_world.copy();out['surface_role']=role
 bpy.data.objects.remove(obj,do_unlink=True)
# A slightly deeper honey-oak tone matches the concept's joinery and keeps the gold sign readable.
mat=bpy.data.materials['seaside_timber'];nodes=mat.node_tree.nodes;bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');tex=next(n for n in nodes if n.type=='TEX_IMAGE')
mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.72,.64,.52,1)
mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);mat.node_tree.links.new(mix.outputs['Color'],bs.inputs['Base Color'])
bpy.context.scene['clock_material_roles']=True
save_record(path,'finalize_material_roles',before)
print('MATERIAL ROLES SAVED')
