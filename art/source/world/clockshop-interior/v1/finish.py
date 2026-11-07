"""Deliberate saved-master material finish: deeper walnut, continuous unoutlined parquet."""
from pathlib import Path
import bpy,json,hashlib
ROOT=Path(__file__).resolve().parents[5]
for folder in sorted((ROOT/'art/source/world').glob('clockshop-*')):
 path=folder/'v1/model.blend'
 if not path.exists():continue
 bpy.ops.wm.open_mainfile(filepath=str(path))
 if bpy.context.scene.get('clockshop_material_finish'):raise RuntimeError('Finish exists; edit saved source.')
 before=hashlib.sha256(path.read_bytes()).hexdigest()
 mat=bpy.data.materials.get('clockshop_walnut')
 if mat:
  nodes=mat.node_tree.nodes;bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');tex=next(n for n in nodes if n.type=='TEX_IMAGE')
  mix=nodes.new('ShaderNodeMix');mix.data_type='RGBA';mix.blend_type='MULTIPLY'
  mix.inputs[0].default_value=1.0;mix.inputs[7].default_value=(.43,.32,.22,1)
  mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[6]);mat.node_tree.links.new(mix.outputs[2],bs.inputs['Base Color'])
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH' and any(m and m.name=='clockshop_floor' for m in obj.data.materials):obj['illustrated_edges']=False
 bpy.context.scene['clockshop_material_finish']=True;bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('finish.json').write_text(json.dumps({'previous_sha256':before,'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
