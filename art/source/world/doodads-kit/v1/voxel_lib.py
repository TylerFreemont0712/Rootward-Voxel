"""Shared helpers for the voxel doodads kit. Imported by one-time Blender authoring scripts in this folder.

Blender Z-up, one unit per metre, front -Y (Godot +Z). A model is a grid of VOXEL-sized cubes given as
{(x, y, z): material}. Every material becomes one object named <material>_geometry that holds only its exposed
faces, with flat shading, and carries a `part` property for grouping in the Outliner.

Run only inside Blender. author_models() refuses to overwrite a saved source, so it is a one-time record: edit the
saved model.blend afterwards and run scripts/world-art.sh build <id>.
"""
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
VOXEL = 0.05
DIRECTIONS = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
MAT = {}


def _linear(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def make_materials(colours):
    """colours maps a material name to a hex colour. Flat base colour, no textures."""
    for name, colour in colours.items():
        material = bpy.data.materials.new(name)
        material.use_nodes = True
        rgb = tuple(int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4))
        material.diffuse_color = (*rgb, 1)
        principled = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        principled.inputs['Base Color'].default_value = (*map(_linear, rgb), 1)
        principled.inputs['Roughness'].default_value = 0.92
        principled.inputs['Metallic'].default_value = 0
        MAT[name] = material


def face_corners(cell, normal):
    """The four corners of one voxel face, wound so the normal points out of the voxel."""
    axis = next(i for i in range(3) if normal[i])
    side = 1 if normal[axis] > 0 else 0
    across = [i for i in range(3) if i != axis]
    corners = []
    for u, v in ((0, 0), (1, 0), (1, 1), (0, 1)):
        point = list(cell)
        point[axis] += side
        point[across[0]] += u
        point[across[1]] += v
        corners.append(point)
    first, second, third = (Vector(corners[i]) for i in range(3))
    if (second - first).cross(third - first).dot(Vector(normal)) < 0:
        corners.reverse()
    return corners


def voxel_object(material, cells, centre, parts):
    """Exposed faces of every voxel made of `material`. A face touching another voxel is hidden and left out."""
    vertices, faces = [], []
    for cell, voxel_material in cells.items():
        if voxel_material != material:
            continue
        for normal in DIRECTIONS:
            if tuple(a + b for a, b in zip(cell, normal)) in cells:
                continue
            start = len(vertices)
            for corner in face_corners(cell, normal):
                vertices.append(tuple((c - o) * VOXEL for c, o in zip(corner, centre)))
            faces.append((start, start + 1, start + 2, start + 3))
    name = f'{material}_geometry'
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(MAT[material])
    layer = data.uv_layers.new(name='UVMap')
    for polygon in data.polygons:
        axis = max(range(3), key=lambda k: abs(polygon.normal[k]))
        for index in polygon.loop_indices:
            co = data.vertices[data.loops[index].vertex_index].co
            layer.data[index].uv = (co.y, co.z) if axis == 0 else ((co.x, co.z) if axis == 1 else (co.x, co.y))
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj['part'] = parts[material]
    return obj


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)


def frame_view(cells, centre):
    """Orthographic material view of the saved source, framed on the model, as the handoff's init does."""
    points = [Vector(((x - centre[0]) * VOXEL, (y - centre[1]) * VOXEL, (z - centre[2]) * VOXEL)) for x, y, z in cells]
    lower = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    upper = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                region = area.spaces.active.region_3d
                region.view_location = (lower + upper) * 0.5
                region.view_distance = max((upper - lower).length * 1.25, 1.0)
                region.view_perspective = 'ORTHO'
                area.spaces.active.shading.type = 'MATERIAL'


def author_models(script_file, models, colours, parts):
    """Write one editable model.blend and provenance.json per model.

    models: list of (model_id, cells, centre), where centre is the (x, y, z) voxel that sits at the origin.
    colours: {material: hex}. parts: {material: part name}. script_file: the calling script's __file__.
    """
    for model_id, _, _ in models:
        if (ROOT / f'art/source/world/{model_id}/v1/model.blend').exists():
            raise RuntimeError(f'Editable source already exists: {model_id}. Open it in Blender; never rerun the author over edits.')
    make_materials(colours)
    script = Path(script_file).resolve()
    for model_id, cells, centre in models:
        clear_scene()
        for material in sorted(set(cells.values())):
            voxel_object(material, cells, centre, parts)
        frame_view(cells, centre)
        folder = ROOT / f'art/source/world/{model_id}/v1'
        folder.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
        (folder / 'provenance.json').write_text(json.dumps({
            'asset': model_id, 'version': 'v1', 'created': datetime.now(timezone.utc).isoformat(),
            'author': script.relative_to(ROOT).as_posix(),
            'author_sha256': hashlib.sha256(script.read_bytes()).hexdigest(),
            'voxel_metres': VOXEL,
            'note': 'One-time procedural voxel authoring. model.blend becomes the editable source after this run.',
        }, indent=2) + '\n')
        print('Editable source saved:', folder / 'model.blend')
