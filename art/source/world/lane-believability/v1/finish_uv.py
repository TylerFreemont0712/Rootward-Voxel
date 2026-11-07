"""Add explicit UV layers to the new untextured handrails for the normal geometry audit."""
from pathlib import Path
import hashlib
import json
import bpy

ROOT = Path(__file__).resolve().parents[5]
for asset in ['haverlund-lane-set', 'haverlund-lane-surround']:
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version = 0
    fixed = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or not obj.data.polygons or obj.data.uv_layers:
            continue
        layer = obj.data.uv_layers.new(name='UVMap')
        for poly in obj.data.polygons:
            for loop in poly.loop_indices:
                co = obj.data.vertices[obj.data.loops[loop].vertex_index].co
                layer.data[loop].uv = (co.x + co.y, co.z)
        fixed.append(obj.name)
    if not fixed:
        continue
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    record = source.with_name('lane-believability.json')
    note = json.loads(record.read_text())
    note['after_sha256'] = hashlib.sha256(source.read_bytes()).hexdigest()
    note['uv_finish'] = {'record':str(Path(__file__).relative_to(ROOT)), 'meshes':fixed}
    record.write_text(json.dumps(note, indent=2) + '\n')
