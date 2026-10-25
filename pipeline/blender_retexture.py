"""Bake the painted texture catalog into an editable world-asset .blend: new pictures on every catalogued
material and new UVs on every face. A deliberate source edit, run by `scripts/world-art.sh retexture <id>`.

    blender --background --factory-startup --python pipeline/blender_retexture.py -- <model.blend> <repo root>

The same `retexture(catalog, root)` also runs inside an open Blender session (it edits the open file and
leaves saving to the caller). Geometry is never touched; only materials, images and UV coordinates.

UV rules, from `pipeline/texture-catalog.json` (see its `tile_modes`):
  world  planar per face, in world units: u along the face's horizontal, v up it (or up the slope). A tile of
         1.0 is one grid cell, so a log course of 0.2 shows exactly one row of the log picture.
  face   the whole picture once over each face (glass, glow).
  cells  each face shows one painted cell of an n by n picture, picked by a hash of where the face is, so
         every box of a roof is its own tile.
"""
import json
from pathlib import Path
import sys

import bmesh
import bpy
from mathutils import Vector

UP = Vector((0.0, 0.0, 1.0))


def face_groups(bm):
    """Coplanar faces that share an edge: a box's quad is two triangles after glTF import."""
    seen, groups = set(), []
    for face in bm.faces:
        if face.index in seen:
            continue
        group, stack = [], [face]
        seen.add(face.index)
        while stack:
            current = stack.pop()
            group.append(current)
            for edge in current.edges:
                for other in edge.link_faces:
                    if other.index not in seen and other.material_index == current.material_index and other.normal.dot(current.normal) > 0.9999:
                        seen.add(other.index)
                        stack.append(other)
        groups.append(group)
    return groups


def basis(normal):
    """A horizontal axis `t` and a 'up the face' axis `b` for a face with this world normal."""
    if abs(normal.z) > 0.92:
        t = Vector((1.0, 0.0, 0.0))
    else:
        t = UP.cross(normal).normalized()
    return t, normal.cross(t).normalized()


def uv_object(obj, entries):
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    layer = bm.loops.layers.uv.verify()
    matrix = obj.matrix_world
    rotation = matrix.to_3x3()
    changed = 0
    for group in face_groups(bm):
        slot = group[0].material_index
        material = mesh.materials[slot] if slot < len(mesh.materials) else None
        entry = entries.get(material.name) if material else None
        if entry is None:
            continue
        normal = (rotation @ group[0].normal).normalized()
        t, b = basis(normal)
        points = {loop.vert.index: matrix @ loop.vert.co for face in group for loop in face.loops}
        us = [p.dot(t) for p in points.values()]
        vs = [p.dot(b) for p in points.values()]
        low_u, high_u, low_v, high_v = min(us), max(us), min(vs), max(vs)
        mode = entry.get('mode', 'world')
        cell = (0, 0)
        cells = int(entry.get('cells', 1))
        if mode == 'cells':
            centre = sum(points.values(), Vector()) / len(points)
            key = (int(round(centre.x * 100)) * 73856093) ^ (int(round(centre.y * 100)) * 19349663) ^ (int(round(centre.z * 100)) * 83492791)
            key = abs(key)
            cell = (key % cells, (key // cells) % cells)
        for face in group:
            for loop in face.loops:
                p = matrix @ loop.vert.co
                if mode == 'world':
                    tile = float(entry.get('tile', 1.0))
                    loop[layer].uv = (p.dot(t) / tile, p.dot(b) / tile)
                else:
                    local_u = (p.dot(t) - low_u) / max(high_u - low_u, 1e-6)
                    local_v = (p.dot(b) - low_v) / max(high_v - low_v, 1e-6)
                    if mode == 'cells':
                        local_u, local_v = (cell[0] + local_u) / cells, (cell[1] + local_v) / cells
                    loop[layer].uv = (local_u, local_v)
        changed += len(group)
    bm.to_mesh(mesh)
    bm.free()
    return changed


def load_image(name, path, tint):
    """The picture from disk, multiplied by `tint` (a single brightness factor), packed into the file."""
    image = bpy.data.images.load(str(path), check_existing=False)
    image.name = name
    image.colorspace_settings.name = 'sRGB'
    if abs(tint - 1.0) > 1e-4:
        pixels = list(image.pixels)
        for index in range(0, len(pixels), 4):
            for channel in range(3):
                pixels[index + channel] = min(1.0, pixels[index + channel] * tint)
        image.pixels = pixels
        image.update()
        image.pack()
    else:
        image.pack()
    return image


def retexture_material(material, entry, directory):
    path = directory / (entry['texture'] + '.png')
    if not path.is_file():
        raise RuntimeError(f'Missing texture picture: {path}')
    material.use_nodes = True
    tree = material.node_tree
    principled = next(node for node in tree.nodes if node.type == 'BSDF_PRINCIPLED')
    for node in [n for n in tree.nodes if n.type == 'TEX_IMAGE']:
        tree.nodes.remove(node)
    image = load_image(material.name + '_albedo', path, float(entry.get('tint', 1.0)))
    node = tree.nodes.new('ShaderNodeTexImage')
    node.image = image
    node.interpolation = 'Closest'
    node.extension = 'EXTEND' if entry.get('mode') == 'face' else 'REPEAT'
    node.location = (-420, 300)
    tree.links.new(node.outputs['Color'], principled.inputs['Base Color'])
    principled.inputs['Base Color'].default_value = (1.0, 1.0, 1.0, 1.0)
    for field, socket in [('roughness', 'Roughness'), ('metallic', 'Metallic')]:
        if field in entry:
            principled.inputs[socket].default_value = float(entry[field])
    emission = float(entry.get('emission', 0.0))
    emission_input = principled.inputs.get('Emission Color')
    if emission > 0.0 and emission_input is not None:
        tree.links.new(node.outputs['Color'], emission_input)
        principled.inputs['Emission Strength'].default_value = emission
    elif emission_input is not None:
        for link in list(emission_input.links):
            tree.links.remove(link)
        principled.inputs['Emission Strength'].default_value = 0.0


def retexture(catalog, root):
    """Edit the open file. Returns {'materials': [...], 'faces': n}."""
    directory = Path(root) / str(catalog['sets'][catalog['set']]).removeprefix('res://')
    entries = catalog['materials']
    done = []
    for material in list(bpy.data.materials):
        entry = entries.get(material.name)
        if entry is None or material.users == 0:
            continue
        retexture_material(material, entry, directory)
        done.append(material.name)
    faces = 0
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH':
            faces += uv_object(obj, entries)
    # The old procedural pictures are no longer used by anything: drop them from the file.
    for image in list(bpy.data.images):
        if image.users == 0 and image.type == 'IMAGE':
            bpy.data.images.remove(image)
    bpy.context.scene['rootward_texture_set'] = catalog['set']
    return {'materials': sorted(done), 'faces': faces}


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:]
    source, root = Path(args[0]), Path(args[1])
    bpy.ops.wm.open_mainfile(filepath=str(source))
    result = retexture(json.loads((root / 'pipeline/texture-catalog.json').read_text()), root)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_mainfile()
    print('Retextured', source, '->', len(result['materials']), 'materials,', result['faces'], 'faces:', ', '.join(result['materials']))
