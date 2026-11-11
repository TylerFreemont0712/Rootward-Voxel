"""Read-only source audit against the preserved masters; run with Blender."""
from pathlib import Path
import hashlib
import importlib.util
import json

import bpy
import bmesh

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('plant_revision', HERE / 'revise.py')
revision = importlib.util.module_from_spec(spec)
spec.loader.exec_module(revision)


def snapshot(path, changed):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    objects = {}
    materials = {}
    for obj in bpy.context.scene.objects:
        data = {'type': obj.type, 'parent': obj.parent.name if obj.parent else None,
                'transform': [list(row) for row in obj.matrix_local],
                'properties': {k: str(v) for k, v in obj.items() if k != 'plant_style'}}
        if obj.type == 'MESH':
            data['materials'] = [m.name if m else None for m in obj.data.materials]
            if obj.name not in changed:
                bm = bmesh.new()
                bm.from_mesh(obj.data)
                data['geometry'] = revision.protected_fingerprint(bm, bm.faces, bm.loops.layers.uv.active)
                bm.free()
        objects[obj.name] = data
    used_materials = {slot.material for obj in bpy.context.scene.objects for slot in obj.material_slots if slot.material}
    for mat in used_materials:
        nodes = []
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                data = {'type': node.type}
                if node.type == 'BSDF_PRINCIPLED':
                    for key in ('Base Color', 'Roughness', 'Metallic', 'Emission Color', 'Emission Strength'):
                        value = node.inputs[key].default_value
                        data[key] = list(value) if hasattr(value, '__iter__') else value
                if node.type == 'TEX_IMAGE' and node.image:
                    image = node.image
                    data['image'] = image.name
                    data['size'] = list(image.size)
                    data['packed'] = hashlib.sha256(image.packed_file.data).hexdigest() if image.packed_file else None
                nodes.append(data)
        materials[mat.name] = {'colour': list(mat.diffuse_color), 'nodes': nodes}
    return objects, materials


results = []
for record in json.loads((HERE / 'revision.json').read_text()):
    changed = {obj['object']: obj for obj in record['objects']}
    before = snapshot(ROOT / record['backup'], changed)
    after = snapshot(ROOT / record['source'], changed)
    if before != after:
        for category, a, b in zip(('object', 'material'), before, after):
            for key in sorted(set(a) | set(b)):
                if a.get(key) != b.get(key):
                    print('DIFFERENCE', record['asset'], category, key, a.get(key), b.get(key), flush=True)
        raise AssertionError('Non-foliage source changed: ' + record['asset'])
    for name, details in changed.items():
        bm = bmesh.new()
        bm.from_mesh(bpy.data.objects[name].data)
        bm.faces.ensure_lookup_table()
        # The edit deletes old foliage and appends new faces. Surviving original
        # faces retain their order before the appended blades and sprigs.
        protected = list(bm.faces)[:details['protected_faces']]
        actual = revision.protected_fingerprint(bm, protected, bm.loops.layers.uv.active)
        assert actual == details['protected_sha256'], 'Authored faces changed after save: ' + record['asset'] + '/' + name
        bm.free()
    results.append({'asset': record['asset'], 'unchanged_objects': len(before[0]) - len(changed),
                    'foliage_objects_checked': len(changed), 'materials_preserved': len(before[1])})
    print('PRESERVED', record['asset'], flush=True)
(HERE / 'validation.json').write_text(json.dumps({'passed': True, 'models': results}, indent=2) + '\n')
print('Foliage source audit:', len(results), 'models passed')
