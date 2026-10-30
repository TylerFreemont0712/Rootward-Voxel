"""Complete missing UV channels on the newly added solid-color enchantment meshes.
The normal world-art auditor requires UVs on all exported faces.
"""
import bpy, shutil
from pathlib import Path
p=Path.cwd()/'art/source/world/rootward-tree/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(p))
backup=p.with_name('model.pre-uv-completion.blend')
if not backup.exists():shutil.copy2(p,backup)
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.data.uv_layers:continue
    d=o.data;d.update();layer=d.uv_layers.new(name='UVMap')
    for face in d.polygons:
        axis=max(range(3),key=lambda k:abs(face.normal[k]))
        for li in face.loop_indices:
            v=d.vertices[d.loops[li].vertex_index].co
            layer.data[li].uv=(v.y,v.z) if axis==0 else ((v.x,v.z) if axis==1 else (v.x,v.y))
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(p))
