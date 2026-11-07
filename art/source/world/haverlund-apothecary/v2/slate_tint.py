"""Saved-master edit: the concept's mossy green slate. The authoring record's legacy MixRGB tint did not reach the
glTF export; this replaces it on the roof and ridge paintings with a Mix (colour, Multiply) node, which the exporter
writes as a base-colour factor. Run once: blender -b --factory-startup --python slate_tint.py"""
from pathlib import Path
import bpy, json, hashlib
path = Path(__file__).with_name('model.blend')
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('apoth_slate_tint'):
    raise RuntimeError('Slate tint already applied; edit the master instead.')
before = hashlib.sha256(path.read_bytes()).hexdigest()
TINT = (.66, .86, .74, 1)
for name in ('seaside_roof', 'seaside_ridge'):
    mat = bpy.data.materials[name]
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    for n in [n for n in nodes if n.bl_idname == 'ShaderNodeMixRGB']:
        nodes.remove(n)
    tex = next(n for n in nodes if n.type == 'TEX_IMAGE')
    bsdf = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
    mix = nodes.new('ShaderNodeMix'); mix.data_type = 'RGBA'; mix.blend_type = 'MULTIPLY'
    mix.inputs['Factor'].default_value = 1.0
    mix.inputs[7].default_value = TINT            # B (colour)
    links.new(tex.outputs['Color'], mix.inputs[6])  # A (colour)
    links.new(mix.outputs[2], bsdf.inputs['Base Color'])
bpy.context.scene['apoth_slate_tint'] = True
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('slate_tint.json').write_text(json.dumps({'previous_sha256': before, 'tint': TINT[:3], 'materials': ['seaside_roof', 'seaside_ridge']}, indent=2) + '\n')
print('SLATE TINT SAVED')
