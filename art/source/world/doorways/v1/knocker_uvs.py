"""Complete UV channels for the three new untextured brass knocker meshes,
so their complete geometry participates in the existing GLB audit contract.
"""
import bpy,json,hashlib,shutil
from pathlib import Path
R=Path.cwd();cat=json.loads((R/'pipeline/world-catalog.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for aid in ['hearth-house','lantern-loft','brook-mill']:
 p=R/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('knocker_uv_review'):raise RuntimeError('Already has complete UVs')
 backup=p.with_name('model.pre-knocker-uv.blend')
 if backup.exists():raise RuntimeError('Preserved source exists')
 shutil.copy2(p,backup)
 for o in bpy.context.scene.objects:
  if o.type!='MESH' or o.data.uv_layers:continue
  uv=o.data.uv_layers.new(name='UVMap')
  for poly in o.data.polygons:
   for li in poly.loop_indices:
    v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v.x,v.z)
 bpy.context.scene['knocker_uv_review']='Complete UV channels on untextured knocker geometry; full audited triangles.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'uv_backup':backup.name,'uv_backup_sha256':sha(backup),'uv_review':'art/source/world/doorways/v1/knocker_uvs.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('Complete UV channels',aid,flush=True)
