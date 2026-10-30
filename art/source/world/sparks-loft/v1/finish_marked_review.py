"""Finish the hanging coat's weighted hem and batch the newly edited static parts.
Deliberate source edits; never recreates a master from the authoring recipe.
"""
from pathlib import Path
import bpy
import json
import hashlib
ROOT = Path(__file__).resolve().parents[5]
record = []
for asset in ('loft-wall-life', 'loft-travel-stacks'):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    before = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version = 0
    coat = bpy.data.objects.get('Coat with weighted folds')
    if coat:
        for v in coat.data.vertices:
            if v.co.z < .84:
                # A broad cloth hem rather than a rounded pouch silhouette.
                centre = -.53 if v.co.z < .79 else -.55
                v.co.x = centre + (v.co.x - centre) * 1.18
        coat.data.update()
    groups = {}
    for o in bpy.context.scene.objects:
        if o.type == 'MESH': groups.setdefault(o.data.materials[0].name, []).append(o)
    for mat, objects in groups.items():
        names = [o.name for o in objects]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects: o.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1: bpy.ops.object.join()
        o = bpy.context.object; o.name = mat; o['reviewed_parts'] = names
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    record.append({'asset':asset,'before':before,'after':hashlib.sha256(source.read_bytes()).hexdigest()})
Path(__file__).with_suffix('.json').write_text(json.dumps(record,indent=2)+'\n')
