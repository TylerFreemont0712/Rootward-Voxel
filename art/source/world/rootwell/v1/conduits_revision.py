"""Deliberate, backed-up source edit of the adopted rootwell-beacon: the city's conduits now climb the Rootwell's
steps to the drum on its four cardinal faces, so the power visibly leaves the well and runs out into the square.

Each conduit follows the steps' profile (treads and risers) from the foot of the bottom step to a brass junction plate
at the drum, in the city-power-grid style: a dark bed, two bronze rails and an inset amber pane flagged `power_grid`.
Widths are authored at 1/1.35 so the square's 35 %-larger placement brings them to the ground conduits' 0.38 m.
The file as it was is kept once as model.pre-conduits.blend.

    blender --background --factory-startup --python art/source/world/rootwell/v1/conduits_revision.py
"""
import json
import math
import shutil
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
SOURCE = ROOT / 'art/source/world/rootwell-beacon/v1/model.blend'
SCALE = 1.0 / 1.35
# The step profile from the plaza inward: (radius, height) corners. Steps 3.75, 3.4 and 3.05; the terrace to the drum.
PROFILE = [(3.78, 0.0), (3.75, 0.0), (3.75, .16), (3.4, .16), (3.4, .32), (3.05, .32), (3.05, .48), (2.36, .48)]


def material(name, colour, metallic, emission=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    c = tuple(int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4))
    bsdf.inputs['Base Color'].default_value = (*c, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = .56
    if emission:
        bsdf.inputs['Emission Color'].default_value = (1, .48, .12, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return m


def add(parts, mat, quad, uv):
    verts, faces, uvs = parts.setdefault(mat, ([], [], []))
    base = len(verts)
    verts.extend(quad)
    faces.append((base, base + 1, base + 2, base + 3))
    uvs.append(uv)


def run(parts, glass, axis):
    """One conduit outward along `axis` (a unit 2D vector), following PROFILE from the drum to the foot."""
    out = Vector((axis[0], axis[1], 0))
    side = Vector((-axis[1], axis[0], 0))
    up = Vector((0, 0, 1))
    points = [out * r + up * z for r, z in reversed(PROFILE)]
    distance = 0.0
    for a, b in zip(points, points[1:]):
        length = (b - a).length
        if length < 1e-4:
            continue
        riser = abs((b - a).z) > .01
        normal = out if riser else up
        lift = normal * .006
        half_bed, rail, pane = .19 * SCALE, .142 * SCALE, .082 * SCALE

        def strip(mat, offset, half, depth, u0, u1, store):
            c0, c1 = a + side * offset + lift - normal * depth, b + side * offset + lift - normal * depth
            add(store, mat, [tuple(c0 - side * half), tuple(c1 - side * half), tuple(c1 + side * half), tuple(c0 + side * half)],
                [(u0, 0), (u1, 0), (u1, 1), (u0, 1)])

        strip('grid_bed', 0, half_bed, .012, distance, distance + length, parts)
        for off in (-rail, rail):
            strip('grid_bronze', off, .018 * SCALE, -.004, distance, distance + length, parts)
        strip('grid_glass', 0, pane, .004, distance, distance + length, glass)
        distance += length
    # A brass junction plate on the drum where the conduit leaves it (the east face's door takes the feed itself).
    if axis == (1, 0):
        return
    c = out * 2.09 + up * .62
    add(parts, 'grid_bronze', [tuple(c - side * .2 - up * .14), tuple(c + side * .2 - up * .14), tuple(c + side * .2 + up * .14), tuple(c - side * .2 + up * .14)],
        [(0, 0), (1, 0), (1, 1), (0, 1)])


def build(name, store, root, flag=None):
    for mat, (verts, faces, uvs) in store.items():
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        layer = mesh.uv_layers.new(name='GridUV')
        for poly, coords in zip(mesh.polygons, uvs):
            for li, uv in zip(poly.loop_indices, coords):
                layer.data[li].uv = uv
        mesh.materials.append(bpy.data.materials[mat])
        mesh.update()
        obj = bpy.data.objects.new(name if mat == 'grid_glass' else name + '_' + mat, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = root
        if flag:
            obj[flag] = True


def main():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    if any(o.name.startswith('rootwell_conduit') for o in bpy.context.scene.objects):
        raise SystemExit('The Rootwell already has its step conduits; edit model.blend directly.')
    backup = SOURCE.with_name('model.pre-conduits.blend')
    if not backup.exists():
        shutil.copy2(SOURCE, backup)
    root = next(o for o in bpy.context.scene.objects if o.type == 'EMPTY' and o.parent is None)
    material('grid_bed', '4c5552', .45)
    material('grid_bronze', '9b8459', .68)
    material('grid_glass', 'b08a46', .18, .45)
    frames, glass = {}, {}
    for axis in ((1, 0), (0, 1), (-1, 0), (0, -1)):
        run(frames, glass, axis)
    build('rootwell_conduit_frame', frames, root)
    build('rootwell_conduit_glass', glass, root, 'power_grid')
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    SOURCE.with_name('conduits-revision.json').write_text(json.dumps({
        'asset': 'rootwell-beacon', 'date': '2026-10-29', 'record': 'art/source/world/rootwell/v1/conduits_revision.py',
        'backup': backup.name, 'profile': PROFILE, 'scale': SCALE,
        'note': 'Conduits up the four cardinal steps to the drum; geometry otherwise unchanged.'}, indent=2) + '\n')
    print('REVISED rootwell-beacon', flush=True)


if __name__ == '__main__':
    main()
