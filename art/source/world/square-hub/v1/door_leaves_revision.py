"""Deliberate, backed-up source edit: separates the door leaves of two adopted masters into hinged parts
the game can swing when the apprentice walks through (DoorSwing):

    lane-workshop         the green street doors (they open into the shop; the warm shop picture shows beyond)
    workshop-shop-doors   the same doors from inside (they open into the room; daylight shows beyond)

Each leaf becomes one object `door_leaf_<side>` with its origin on the hinge and a `swing` custom property (degrees
about the vertical; exported as glTF extras). Pieces are moved whole: a connected piece of a door material is taken
only if it lies entirely inside that leaf's box. The file as it was is kept once as model.pre-door-leaves.blend.
Export afterwards with scripts/world-art.sh build <id>.

    blender --background --factory-startup --python art/source/world/square-hub/v1/door_leaves_revision.py -- <id>
"""
import json
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]

SPECS = {
    'lane-workshop': {
        'materials': ('lane_teal', 'lane_teal_dark', 'lane_brass'),
        'leaves': [
            {'name': 'door_leaf_s', 'box': ((4.05, -2.31, .1), (4.3, -1.5, 2.48)), 'hinge': (4.18, -2.28, 0), 'swing': 100},
            {'name': 'door_leaf_n', 'box': ((4.05, -1.5, .1), (4.3, -.69, 2.48)), 'hinge': (4.18, -.72, 0), 'swing': -100},
        ],
        'beyond': {'material': 'lane_window_shop', 'quad': [(3.7, -2.3, .14), (3.7, -.7, .14), (3.7, -.7, 2.46), (3.7, -2.3, 2.46)],
                   'uv': [(0, 0), (1, 0), (1, 1), (0, 1)], 'name': 'doorway_beyond'},
    },
    'workshop-shop-doors': {
        'materials': ('workshop_teal', 'workshop_teal_dark', 'workshop_brass', 'workshop_wood_edge', 'workshop_wood_dark'),
        'leaves': [
            {'name': 'door_leaf_w', 'box': ((-1.36, -.24, 0), (-.02, .09, 2.56)), 'hinge': (-1.34, 0, 0), 'swing': 95},
            {'name': 'door_leaf_e', 'box': ((.02, -.24, 0), (1.36, .09, 2.56)), 'hinge': (1.34, 0, 0), 'swing': -95},
        ],
        'beyond': {'material': 'workshop_harbour', 'quad': [(-1.4, -.7, 0), (1.4, -.7, 0), (1.4, -.7, 2.52), (-1.4, -.7, 2.52)],
                   'uv': [(.08, .12), (.92, .12), (.92, .66), (.08, .66)], 'name': 'doorway_beyond'},
    },
}


def islands(bm):
    seen, groups = set(), []
    for face in bm.faces:
        if face.index in seen:
            continue
        stack, group = [face], []
        seen.add(face.index)
        while stack:
            f = stack.pop()
            group.append(f)
            for edge in f.edges:
                for other in edge.link_faces:
                    if other.index not in seen:
                        seen.add(other.index)
                        stack.append(other)
        groups.append(group)
    return groups


def inside(points, box):
    lo, hi = Vector(box[0]), Vector(box[1])
    return all(lo.x <= p.x <= hi.x and lo.y <= p.y <= hi.y and lo.z <= p.z <= hi.z for p in points)


def revise(asset):
    spec = SPECS[asset]
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = source.with_name('model.pre-door-leaves.blend')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if any(o.name.startswith('door_leaf') for o in bpy.context.scene.objects):
        raise SystemExit(asset + ' already has door leaves; edit the model.blend directly.')
    if not backup.exists():
        shutil.copy2(source, backup)
    root = next((o for o in bpy.context.scene.objects if o.type == 'EMPTY' and o.parent is None), None)
    taken = {leaf['name']: [] for leaf in spec['leaves']}
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH' or not obj.data.materials or obj.data.materials[0].name not in spec['materials']:
            continue
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.faces.ensure_lookup_table()
        world = obj.matrix_world
        uv = bm.loops.layers.uv.active
        doomed = []
        for group in islands(bm):
            points = [world @ v.co for f in group for v in f.verts]
            for leaf in spec['leaves']:
                if inside(points, leaf['box']):
                    for f in group:
                        taken[leaf['name']].append(([world @ v.co for v in f.verts], [tuple(l[uv].uv) if uv else (0, 0) for l in f.loops],
                                                    obj.data.materials[f.material_index].name, f.smooth))
                    doomed.extend(group)
                    break
        if doomed:
            bmesh.ops.delete(bm, geom=list(set(doomed)), context='FACES')
            bm.to_mesh(obj.data)
            obj.data.update()
        bm.free()
    for leaf in spec['leaves']:
        faces = taken[leaf['name']]
        if not faces:
            raise SystemExit(f'No pieces found for {asset} {leaf["name"]}; check its box.')
        hinge = Vector(leaf['hinge'])
        mats = sorted({f[2] for f in faces})
        verts, polys, uvs = [], [], []
        for points, loop_uvs, mat, smooth in faces:
            base = len(verts)
            verts.extend(tuple(p - hinge) for p in points)
            polys.append((tuple(range(base, base + len(points))), mats.index(mat), smooth))
            uvs.append(loop_uvs)
        mesh = bpy.data.meshes.new(leaf['name'])
        mesh.from_pydata(verts, [], [p[0] for p in polys])
        for poly, (_, index, smooth) in zip(mesh.polygons, polys):
            poly.material_index = index
            poly.use_smooth = smooth
        layer = mesh.uv_layers.new(name='UVMap')
        for poly, loop_uvs in zip(mesh.polygons, uvs):
            for li, value in zip(poly.loop_indices, loop_uvs):
                layer.data[li].uv = value
        for name in mats:
            mesh.materials.append(bpy.data.materials[name])
        mesh.update()
        obj = bpy.data.objects.new(leaf['name'], mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.location = hinge
        obj['swing'] = float(leaf['swing'])
        obj['part'] = 'door_leaf'
        if root is not None:
            obj.parent = root
            obj.matrix_parent_inverse = root.matrix_world.inverted()
        print('LEAF', asset, leaf['name'], len(faces), 'faces', mats, flush=True)
    beyond = spec.get('beyond')
    if beyond:
        mesh = bpy.data.meshes.new(beyond['name'])
        mesh.from_pydata(beyond['quad'], [], [(0, 1, 2, 3)])
        layer = mesh.uv_layers.new(name='UVMap')
        for li, value in zip(mesh.polygons[0].loop_indices, beyond['uv']):
            layer.data[li].uv = value
        mesh.materials.append(bpy.data.materials[beyond['material']])
        mesh.update()
        obj = bpy.data.objects.new(beyond['name'], mesh)
        bpy.context.scene.collection.objects.link(obj)
        if root is not None:
            obj.parent = root
            obj.matrix_parent_inverse = root.matrix_world.inverted()
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    note = source.with_name('door-leaves.json')
    note.write_text(json.dumps({'asset': asset, 'date': '2026-10-29', 'record': 'art/source/world/square-hub/v1/door_leaves_revision.py',
                                'backup': backup.name, 'leaves': spec['leaves'],
                                'note': 'Door leaves separated as hinged parts for DoorSwing; geometry otherwise unchanged.'}, indent=2) + '\n')
    print('REVISED', asset, flush=True)


if __name__ == '__main__':
    revise(sys.argv[sys.argv.index('--') + 1])
