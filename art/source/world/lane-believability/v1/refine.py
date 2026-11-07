"""One-time deliberate edits to the adopted lane masters. Never recreate either master.

Recover intact gate parts from the preserved source, give each leaf a real hinge,
continue the handrails down the existing treads, and turn vacant paving into plots.
Run from the project root with Blender; the normal world build exports the result.
"""
import hashlib
import json
import math
import shutil
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
RECORD = Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def begin(asset):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = source.with_name('model.pre-lane-believability.blend')
    if backup.exists() and digest(source) != digest(backup):
        raise RuntimeError('Revision already started; inspect the saved master: ' + asset)
    if not backup.exists():
        shutil.copy2(source, backup)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version = 0
    return source, digest(source)


def finish(source, before):
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    source.with_name('lane-believability.json').write_text(json.dumps({
        'date': '2026-11-02', 'before_sha256': before, 'after_sha256': digest(source),
        'record': str(Path(__file__).relative_to(ROOT)), 'record_sha256': digest(Path(__file__)),
        'note': 'Deliberate edit of the adopted master; prior source preserved. Export with scripts/world-art.sh.'
    }, indent=2) + '\n')


def components(bm):
    seen = set()
    for vertex in bm.verts:
        if vertex in seen:
            continue
        group, stack = [], [vertex]
        seen.add(vertex)
        while stack:
            current = stack.pop()
            group.append(current)
            for edge in current.link_edges:
                other = edge.other_vert(current)
                if other not in seen:
                    seen.add(other)
                    stack.append(other)
        yield group


def remove_parts(obj, predicate):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    discard = []
    for group in components(bm):
        points = [obj.matrix_world @ v.co for v in group]
        lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
        hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
        if predicate(lo, hi):
            discard.extend(group)
    if discard:
        bmesh.ops.delete(bm, geom=discard, context='VERTS')
        bm.to_mesh(obj.data)
    bm.free()
    return len(discard)


def mesh(name, vertices, faces, material, parent, uv=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.materials.append(material)
    if uv:
        layer = data.uv_layers.new(name='UVMap')
        for poly, coords in zip(data.polygons, uv):
            for loop, co in zip(poly.loop_indices, coords):
                layer.data[loop].uv = co
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    return obj


def rods(name, segments, material, parent):
    vertices, faces = [], []
    for start, end, radius in segments:
        a, b = Vector(start), Vector(end)
        axis = (b - a).normalized()
        across = axis.cross(Vector((0, 1, 0)))
        if across.length < .01:
            across = axis.cross(Vector((1, 0, 0)))
        across.normalize()
        up = axis.cross(across).normalized()
        offset = len(vertices)
        for point in [a, b]:
            for i in range(6):
                angle = i * math.tau / 6
                vertices.append(point + radius * (across * math.cos(angle) + up * math.sin(angle)))
        faces += [tuple(offset + i for i in reversed(range(6))), tuple(offset + 6 + i for i in range(6))]
        for i in range(6):
            j = (i + 1) % 6
            faces.append((offset+i, offset+j, offset+6+j, offset+6+i))
    return mesh(name, vertices, faces, material, parent)


def tread(y):
    if y < 29.65:
        return 1 - .22 * min(7, max(1, math.floor((y - 27.55) / .3) + 1))
    if y <= 30.5:
        return -.6
    if y <= 36.5:
        return -.6 - .25 * math.ceil((y - 30.5) * 2 - .00001)
    if y <= 38.5:
        return -3.6
    return -3.6 - .25 * math.ceil((min(y, 41.5) - 38.5) * 2 - .00001)


def rails(parent, material, first, last):
    for side, x in [('west', 11.32), ('east', 13.68)]:
        segments = []
        y = first
        while y < last - .001:
            next_y = min(last, y + .25)
            # A smooth grip follows the nosings; balusters stand on the actual treads.
            z = tread(y)
            nz = tread(next_y)
            segments += [((x,y,z+1.02),(x,next_y,nz+1.02),.034),
                         ((x,y,z+.37),(x,next_y,nz+.37),.019),
                         ((x,y,z+.04),(x,y,z+1.02),.013)]
            y = next_y
        for y in [first, last] + [float(y) + .5 for y in range(math.ceil(first), math.floor(last), 2)]:
            z = tread(y)
            segments.append(((x,y,z-.04),(x,y,z+1.1),.045))
        rods('stair_handrail_' + side, segments, material, parent)


def gate():
    source, before = begin('haverlund-lane-set')
    root = bpy.data.objects['lane_iron'].parent
    iron = bpy.data.materials['lane_iron']
    current = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    removed = 0
    for obj in current:
        if obj.name in ['lane_iron', 'lane_brass']:
            removed += remove_parts(obj, lambda lo, hi: lo.x > 11.43 and hi.x < 13.57 and lo.y > 27.12 and hi.y < 28.3 and lo.z > 1.07 and hi.z < 2.42)
        if obj.name == 'lane_limestone_shade':
            remove_parts(obj, lambda lo, hi: lo.y >= 27.49 and hi.y < 29.71 and hi.x-lo.x < .34 and 11.1 < lo.x < 13.9)
    if removed < 500:
        raise RuntimeError('Did not find the damaged gate parts')
    # Recover whole connected pieces, avoiding the old per-vertex edit that stretched
    # the latch/meeting stiles across the opening.
    history = source.with_name('model.pre-square-gate.blend')
    with bpy.data.libraries.load(str(history), link=False) as (available, requested):
        requested.objects = [name for name in available.objects if name in ['lane_iron', 'lane_brass']]
    for side, hinge, sign in [('left',11.48,-1), ('right',13.52,1)]:
        pivot = bpy.data.objects.new('door_leaf_lane_' + side, None)
        bpy.context.collection.objects.link(pivot)
        pivot.parent = root
        pivot.location = (hinge,27.25,1)
        pivot['swing'] = sign * 88
        pivot['purpose'] = 'Hinged gate at the town steps; driven by DoorSwing'
        bpy.context.view_layer.update()
        for old in requested.objects:
            obj = old.copy()
            obj.data = old.data.copy()
            bpy.context.collection.objects.link(obj)
            obj.matrix_world = old.matrix_world.copy()
            keep = lambda lo,hi: lo.x > 11.43 and hi.x < 13.57 and lo.y > 27.12 and hi.y < 27.34 and lo.z > 1.07 and hi.z < 2.42 and ((lo.x+hi.x)/2 < 12.5 if side == 'left' else (lo.x+hi.x)/2 >= 12.5)
            remove_parts(obj, lambda lo,hi: not keep(lo,hi))
            if len(obj.data.vertices) == 0:
                bpy.data.objects.remove(obj, do_unlink=True)
                continue
            obj.name = 'gate_' + side + '_' + old.name.split('.')[0]
            obj.parent = pivot
            obj.matrix_parent_inverse = pivot.matrix_world.inverted()
            for index, mat in enumerate(obj.data.materials):
                obj.data.materials[index] = bpy.data.materials.get(mat.name.split('.')[0], mat)
    rails(root, iron, 27.55, 29.65)
    finish(source, before)


def surface_kind(x, y, z, original):
    # Real streets remain continuous. Gardens are complete parcels with paths, not
    # disconnected grass patches generated by crossing sine waves.
    if z == -8:
        street = (-7.5 < y < -1.5 and x > -3.5) or (-11.5 < y < -8.5 and x < -3.5) or 23.5 < x < 29.5 or -26.5 < y < -24.5 or 45.5 < x < 47.5
        if street:
            return 'ground_cobbles'
        if any(abs(x-hx) < 5.3 and abs(y-hy) < 4.5 for hx,hy in [(-14,-15),(9.5,-15),(33,-13.5),(-8,-33),(22,-34),(37,-33),(36,-2),(36,22),(52,0),(53,25)]):
            return 'ground_flags'
        # Narrow yard paths actually meet the residential streets.
        if abs(x-9.5)<.7 or abs(x-33)<.7 or abs(y-22)<.65 or abs(y+2)<.65:
            return 'ground_flags'
        return 'ground_grass'
    if x < -4 and y > 4.5:
        if abs(x+11)<1 or y in [15,16,27,28] or any(abs(x-hx)<5 and abs(y-hy)<4 for hx,hy in [(-10,9),(-10,30.5),(-26,25)]):
            return 'ground_flags'
        return 'ground_grass'
    if 27.5 < y < 50.5 and 0 <= x < 11.5:
        return 'ground_flags' if abs(x-5)<.8 or abs(y-34)<.7 or abs(y-44)<.7 else 'ground_grass'
    if y > 30.5 and 13.5 < x < 44:
        if abs(x-22)<5.2 and abs(y-35.5)<4.2 or abs(y-38)<.8 or abs(x-28)<.8:
            return 'ground_flags'
        return 'ground_grass'
    return original


def gardens():
    source, before = begin('haverlund-lane-surround')
    root = bpy.data.objects['ground_flags'].parent
    names = ['ground_cobbles','ground_flags','ground_grass']
    batches = {name: ([], [], []) for name in names}
    # Subdivide existing flat tops and interpolate their UVs. Wall/pillar geometry,
    # tread geometry, source heights and power channels are left intact.
    for name in names:
        obj = bpy.data.objects[name]
        data = obj.data
        layer = data.uv_layers.active
        for poly in data.polygons:
            points = [obj.matrix_world @ data.vertices[i].co for i in poly.vertices]
            if len(points) != 4 or max(p.z for p in points)-min(p.z for p in points) > .001:
                raise RuntimeError('Unexpected nonrectangular ground top')
            x0,x1 = min(p.x for p in points),max(p.x for p in points)
            y0,y1 = min(p.y for p in points),max(p.y for p in points)
            z = points[0].z
            uvmap = {(round(p.x,3),round(p.y,3)): Vector(layer.data[loop].uv) for p,loop in zip(points,poly.loop_indices)}
            u00,u10,u01,u11 = [uvmap[(round(x,3),round(y,3))] for x,y in [(x0,y0),(x1,y0),(x0,y1),(x1,y1)]]
            xs = sorted(set([x0,x1]+[i+.5 for i in range(math.floor(x0),math.ceil(x1)) if x0<i+.5<x1]))
            ys = sorted(set([y0,y1]+[i+.5 for i in range(math.floor(y0),math.ceil(y1)) if y0<i+.5<y1]))
            for a,b in zip(xs,xs[1:]):
                for c,d in zip(ys,ys[1:]):
                    target = surface_kind((a+b)/2,(c+d)/2,round(z,3),name)
                    vertices,faces,uvs = batches[target]
                    offset = len(vertices)
                    vertices += [(a,c,z),(b,c,z),(b,d,z),(a,d,z)]
                    faces.append(tuple(offset+i for i in range(4)))
                    coords=[]
                    for x,y in [(a,c),(b,c),(b,d),(a,d)]:
                        fx,fy=(x-x0)/(x1-x0),(y-y0)/(y1-y0)
                        coords.append(u00.lerp(u10,fx).lerp(u01.lerp(u11,fx),fy))
                    uvs.append(coords)
        material = data.materials[0]
        bpy.data.objects.remove(obj,do_unlink=True)
    for name,(vertices,faces,uvs) in batches.items():
        mesh(name,vertices,faces,bpy.data.materials[name],root,uvs)
    iron = bpy.data.materials.new('garden_iron')
    iron.diffuse_color=(.09,.13,.12,1)
    iron.use_nodes=True
    iron.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.09,.13,.12,1)
    iron.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.7
    rails(root, iron, 29.65, 41.5)
    # Protect the tops of the two garden terraces as well as the stair itself.
    segments=[]
    for x,a,b,z in [(11.08,28,36.5,1),(15.6,28,30.5,1),(23.65,4.5,27.5,1),(-4.4,5,34,3)]:
        for y in [a+i*.25 for i in range(round((b-a)*4)+1)]:
            segments.append(((x,y,z+.14),(x,y,z+1.04),.012))
        segments += [((x,a,z+1.04),(x,b,z+1.04),.032),((x,a,z+.38),(x,b,z+.38),.018)]
    rods('garden_edge_railings',segments,iron,root)
    finish(source,before)


if __name__ == '__main__':
    gate()
    gardens()
