"""One-time Blender authoring record for two voxel doodads: a flower pot and a hay bale.

Run once from the project root:
  blender --background --factory-startup --python art/source/world/doodads-kit/v1/author.py
It refuses to run over a saved source. After this handoff, edit each model.blend in Blender and run
scripts/world-art.sh build <id>; this file records how v1 was made and is not the master.

Blender Z-up, one unit per metre, front -Y (Godot +Z). Each model is a grid of 0.05 m voxels. Every material
becomes one object named <material>_geometry that holds only its exposed faces. Faces are not shared between
voxels, so shading stays flat and the result is ordinary geometry with a voxel look.
"""
import hashlib
import json
import random
from datetime import datetime, timezone
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
VOXEL = 0.05
MODEL_IDS = ['flower-pot', 'hay-bale']
for model_id in MODEL_IDS:
    if (ROOT / f'art/source/world/{model_id}/v1/model.blend').exists():
        raise RuntimeError(f'Editable source already exists: {model_id}. Open it in Blender; never rerun the author over edits.')

# Clay and the petal and straw colours are new, so they are defined here. Soil and the leaves come from the shared palette.
COLOURS = {
    'clay': 'b86b45', 'clay_light': 'cf8559', 'clay_dark': '8e4f35', 'soil': '755846',
    'leaf': '4d7e35', 'leaf_light': '7ca946', 'leaf_dark': '2e5835',
    'petal_violet': '8271b1', 'petal_mauve': 'c399ad', 'petal_cream': 'fff0cb', 'petal_gold': 'e5ca85', 'centre': 'c98a3c',
    'hay': 'd9a94e', 'hay_light': 'ecc86c', 'hay_dark': 'b07f3a', 'hay_pale': 'f2dd9b', 'twine': 'e8ddbd',
}
PART = {
    'clay': 'Pot', 'clay_light': 'Pot', 'clay_dark': 'Pot', 'soil': 'Soil',
    'leaf': 'Plants', 'leaf_light': 'Plants', 'leaf_dark': 'Plants',
    'petal_violet': 'Plants', 'petal_mauve': 'Plants', 'petal_cream': 'Plants', 'petal_gold': 'Plants', 'centre': 'Plants',
    'hay': 'Straw', 'hay_light': 'Straw', 'hay_dark': 'Straw', 'hay_pale': 'Straw', 'twine': 'Twine',
}
STRAW = ['hay', 'hay', 'hay_light', 'hay_dark', 'hay_pale']
DIRECTIONS = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
MAT = {}


def linear(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def make_material(name, colour):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    rgb = tuple(int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4))
    material.diffuse_color = (*rgb, 1)
    principled = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
    principled.inputs['Base Color'].default_value = (*map(linear, rgb), 1)
    principled.inputs['Roughness'].default_value = 0.92
    principled.inputs['Metallic'].default_value = 0
    return material


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


def voxel_object(material, cells, centre):
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
    obj['part'] = PART[material]
    return obj


def plant(cells, x, y, head, petal):
    """A one-voxel stem from the soil to `head`, then a plus of four petals round a centre that rises one voxel."""
    for z in range(7, head):
        cells[(x, y, z)] = 'leaf_dark'
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        cells[(x + dx, y + dy, head)] = petal
    cells[(x, y, head)] = 'centre'
    cells[(x, y, head + 1)] = 'centre'


def flower_pot():
    """A stepped terracotta pot on a soil bed: 0.6 m across, a 0.45 m rim, four blossoms on stems to about 0.9 m."""
    cells = {}
    bed = [(x, y) for x in range(-4, 4) for y in range(-4, 4)]
    for x, y in bed:
        for z in range(6):
            cells[(x, y, z)] = 'clay_dark' if z == 0 else ('clay_light' if z == 4 else 'clay')
        cells[(x, y, 6)] = 'soil'
    for x in range(-6, 6):
        for y in range(-6, 6):
            corner = x in (-6, -5, 4, 5) and y in (-6, -5, 4, 5)
            if (x, y) in bed or corner:
                continue
            for z, colour in ((6, 'clay_dark'), (7, 'clay_light'), (8, 'clay_light')):
                cells[(x, y, z)] = colour
    for x, y, z, leaf in [(-1, -2, 11, 'leaf_light'), (0, -2, 11, 'leaf_light'), (-2, -1, 8, 'leaf_dark'),
                          (2, -4, 9, 'leaf_dark'), (2, -5, 9, 'leaf_dark'), (-4, 2, 11, 'leaf_light'),
                          (3, 2, 8, 'leaf'), (3, 3, 8, 'leaf')]:
        cells[(x, y, z)] = leaf
    plant(cells, -2, -2, 16, 'petal_violet')
    plant(cells, 2, -3, 13, 'petal_cream')
    plant(cells, -3, 2, 15, 'petal_mauve')
    plant(cells, 2, 2, 11, 'petal_gold')
    return cells


def hay_bale():
    """A square bale 0.9 m by 0.5 m by 0.5 m: straw runs along its length, three one-voxel twines, rounded edges, loose straws."""
    rng = random.Random(231023)
    cells = {}
    section = [(y, z) for y in range(-5, 5) for z in range(0, 10) if not (y in (-5, 4) and z in (0, 9))]
    for y, z in section:
        base = rng.choice(STRAW)
        x = -9
        while x < 9:
            length = rng.randint(2, 5)
            colour = 'hay_dark' if z == 0 else (base if rng.random() < 0.6 else rng.choice(STRAW))
            for xx in range(x, min(x + length, 9)):
                cells[(xx, y, z)] = colour
            x += length
    for x in (-5, 0, 5):
        for y, z in section:
            if y in (-5, 4) or z == 9:
                cells[(x, y, z)] = 'twine'
    # Loose straws: three stand off the top, one pokes from each front corner, and a few lie on the grass.
    for x, y, z, colour in [(-3, -2, 10, 'hay_light'), (4, 1, 10, 'hay_light'), (1, 3, 10, 'hay'),
                            (-2, -6, 4, 'hay'), (3, -6, 7, 'hay_light')]:
        cells[(x, y, z)] = colour
    for x in range(3, 7):
        cells[(x, -7, 0)] = 'hay'
    for x in range(-8, -6):
        cells[(x, -6, 0)] = 'hay_light'
    return cells


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


def build(model_id, cells, centre):
    clear_scene()
    for material in sorted(set(cells.values())):
        voxel_object(material, cells, centre)
    frame_view(cells, centre)
    path = ROOT / f'art/source/world/{model_id}/v1/model.blend'
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    print('Editable source saved:', path)


def write_provenance(model_id):
    folder = ROOT / f'art/source/world/{model_id}/v1'
    (folder / 'provenance.json').write_text(json.dumps({
        'asset': model_id, 'version': 'v1', 'created': datetime.now(timezone.utc).isoformat(),
        'author': 'art/source/world/doodads-kit/v1/author.py',
        'author_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'voxel_metres': VOXEL,
        'note': 'One-time procedural voxel authoring. model.blend becomes the editable source after this run.',
    }, indent=2) + '\n')


for name, colour in COLOURS.items():
    MAT[name] = make_material(name, colour)
build('flower-pot', flower_pot(), (0, 0, 0))
build('hay-bale', hay_bale(), (0, 0, 0))
for model_id in MODEL_IDS:
    write_provenance(model_id)
