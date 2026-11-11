"""Deliberate edits to two adopted workshop masters, each preserved beside its saved copy first:

* workshop-tool-wall: the rows of looped, unrecognisable hangers become a shadow board a person could use.
  A spanner rack holds four graduated open-end spanners with the third missing (it is on the bench), a claw
  hammer rests on its pegs, and two screwdrivers hang from a holder. The upper shelf and its plants are untouched.
* workshop-tea-table: the mug held a flat dark disc standing for tea. It is now a hollow white mug.

Run with Blender from this checkout. Each edit refuses to run twice; later changes open the current model.blend.
"""
from pathlib import Path
import bmesh
import bpy
import hashlib
import importlib.util
import json
import math
import shutil
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('workshop_helpers', HERE / 'author.py')
w = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w)
records = []


def opened(asset):
    path = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = path.with_name('model.pre-tool-wall-and-mug.blend')
    if backup.exists():
        raise RuntimeError('Already revised; edit the current master: ' + asset)
    shutil.copy2(path, backup)
    records.append({'asset': asset, 'before': hashlib.sha256(path.read_bytes()).hexdigest(), 'backup': str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(path))
    bpy.context.preferences.filepaths.save_version = 0
    w.h.PARENT = next(o for o in bpy.context.scene.objects if o.type == 'EMPTY')
    w.M.clear()
    for m in bpy.data.materials:
        if m.name.startswith('workshop_'):
            w.M[m.name[9:].split('.')[0]] = m
    return path


PALETTE = {'ink': '503d30', 'steel_dark': '343e44', 'leather': '8f533d', 'teal': '457d76', 'linen_shade': 'bcb29a'}


def ensure(*names):
    """Masters keep only the materials they use; bring in a workshop colour a new part needs."""
    for name in names:
        if name not in w.M:
            w.h.material(name, PALETTE[name]).name = 'workshop_' + name


def remove_components(predicate):
    """Delete every connected piece of every mesh whose bounds satisfy predicate(lo, hi, material)."""
    removed = 0
    for o in list(bpy.context.scene.objects):
        if o.type != 'MESH':
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        unseen = set(bm.verts)
        doomed = []
        while unseen:
            seed = unseen.pop()
            group = {seed}
            todo = [seed]
            while todo:
                for e in todo.pop().link_edges:
                    for v in e.verts:
                        if v in unseen:
                            unseen.remove(v)
                            group.add(v)
                            todo.append(v)
            pts = [o.matrix_world @ v.co for v in group]
            lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
            hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            if predicate(lo, hi, o.data.materials[0].name):
                doomed.extend(group)
                removed += 1
        if doomed:
            bmesh.ops.delete(bm, geom=doomed, context='VERTS')
        bm.to_mesh(o.data)
        bm.free()
        o.data.update()
        if not o.data.vertices:
            bpy.data.objects.remove(o, do_unlink=True)
    return removed


def finish(path, tag):
    groups = {}
    for o in list(bpy.context.scene.objects):
        if o.type == 'CURVE':
            bpy.ops.object.select_all(action='DESELECT')
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target='MESH')
        if o.type != 'MESH':
            continue
        if not o.data.uv_layers:
            uv = o.data.uv_layers.new(name='Source planar UV')
            for p in o.data.polygons:
                axes = [i for i in range(3) if i != max(range(3), key=lambda a: abs(p.normal[a]))]
                for li in p.loop_indices:
                    v = o.data.vertices[o.data.loops[li].vertex_index].co
                    uv.data[li].uv = (v[axes[0]], v[axes[1]])
        groups.setdefault(o.data.materials[0].name, []).append(o)
    for name, items in groups.items():
        names = [o.name for o in items]
        bpy.ops.object.select_all(action='DESELECT')
        for o in items:
            o.select_set(True)
        bpy.context.view_layer.objects.active = items[0]
        if len(items) > 1:
            bpy.ops.object.join()
        bpy.context.object.name = name
        bpy.context.object[tag] = names
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    records[-1]['after'] = hashlib.sha256(path.read_bytes()).hexdigest()


# --------------------------------------------------------------------------------------------- spanners
def spanner_outline(length, head, neck, jaw, tilt):
    """The polygon (x, z) of an upright double open-end spanner, shaft centred on the origin, as a closed loop.

    Each end is a round head with a flat-bottomed jaw opening away from the shaft; the two jaws are turned a
    little either way from the shaft, as a real spanner's are. The outline is built for the top end and the
    same path turned half a revolution gives the bottom end.
    """
    centre = Vector((0, length / 2 - head))
    turn = math.radians(tilt)
    rotate = lambda p: Vector((p.x * math.cos(turn) - p.y * math.sin(turn), p.x * math.sin(turn) + p.y * math.cos(turn)))
    path = []
    # Clockwise from the left neck up and over the left jaw tip, down the jaw and back up to the right jaw tip,
    # then around to the right neck.
    first = math.pi + math.acos(neck / head)
    left_tip = math.pi - math.acos(jaw / head)
    arcs = 10
    for k in range(arcs + 1):
        a = first + (left_tip - first) * k / arcs
        path.append(Vector((head * math.cos(a), head * math.sin(a))))
    floor = .12 * head
    path.append(Vector((-jaw, floor)))
    path.append(Vector((jaw, floor)))
    right_tip = math.acos(jaw / head)
    last = -math.acos(neck / head)
    for k in range(arcs + 1):
        a = right_tip + (last - right_tip) * k / arcs
        path.append(Vector((head * math.cos(a), head * math.sin(a))))
    top = [centre + rotate(p) for p in path]
    # The same end turned half a revolution about the middle of the shaft, so its jaw leans the other way.
    return top + [Vector((-p.x, -p.y)) for p in top]


def flat_part(name, outline, y_front, thickness, mat, at=(0, 0, 0)):
    """Extrude a closed (x, z) outline backward from y_front, as one mesh."""
    bm = bmesh.new()
    verts = [bm.verts.new((at[0] + p.x, y_front, at[2] + p.y)) for p in outline]
    face = bm.faces.new(verts)
    extruded = bmesh.ops.extrude_face_region(bm, geom=[face])
    moved = [e for e in extruded['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, thickness, 0), verts=moved)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(o)
    w.h.put(o, mat)
    return o


def spanner(x, base, length, head, mat='steel_light'):
    neck = .019
    jaw = .30 * head
    outline = spanner_outline(length, head, neck, jaw, 14)
    return flat_part('Open-end spanner', outline, -.060, .022, mat, (x, 0, base + length / 2))


def ring_part(name, outer, inner, y_front, thickness, mat, at=(0, 0, 0)):
    """A band between two corresponding loops (same point order), extruded backward from y_front."""
    bm = bmesh.new()
    count = len(outer)
    big = [bm.verts.new((at[0] + p.x, y_front, at[2] + p.y)) for p in outer]
    small = [bm.verts.new((at[0] + p.x, y_front, at[2] + p.y)) for p in inner]
    faces = [bm.faces.new((big[i], big[(i + 1) % count], small[(i + 1) % count], small[i])) for i in range(count)]
    extruded = bmesh.ops.extrude_face_region(bm, geom=faces)
    moved = [e for e in extruded['geom'] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, thickness, 0), verts=moved)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    o = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(o)
    w.h.put(o, mat)
    return o


def chalk_outline(x, base, length, head):
    """The painted line a spanner's place is marked with on the board, a little way outside the tool."""
    outer = spanner_outline(length + .04, head + .016, .035, .12 * (head + .016), 14)
    inner = spanner_outline(length + .022, head + .008, .027, .22 * (head + .008), 14)
    return ring_part('Chalk spanner outline', outer, inner, -.0465, .0075, 'linen_shade', (x, 0, base + length / 2 - .005))


def tool_wall():
    path = opened('workshop-tool-wall')
    ensure('ink', 'steel_dark', 'leather', 'teal', 'linen_shade')
    # The old hangers: looped steel, steel-grey bodies, handles and hooks, all below the shelf.
    gone = remove_components(lambda lo, hi, mat: mat in ('workshop_steel', 'workshop_steel_light', 'workshop_wood', 'workshop_wood_edge') and hi.z < 1.3)
    assert gone > 30, gone

    # Spanner rack: four slots, graduated sizes; the third spanner is the one on the bench.
    rack_z = .80
    w.wood('Spanner rack', (-1.555, -.095, rack_z - .08), (1.42, .10, .16), 'oak', .014)
    sizes = [(-2.05, .66, .060), (-1.72, .61, .056), (-1.39, .56, .052), (-1.06, .51, .048)]
    for index, (x, length, head) in enumerate(sizes):
        w.B('Spanner slot', (x, -.071, rack_z + .0015), (.052, .036, .004), 'ink', 0)
        base = rack_z - .125
        chalk_outline(x, base, length, head)
        if index != 2:
            spanner(x, base, length, head)

    # Claw hammer: head resting on two pegs, handle hanging between them.
    hx = .62
    for dx in (-.075, .075):
        w.R('Hammer peg', (hx + dx, -.04, 1.082), (hx + dx, -.125, 1.082), .011, 'steel_dark', 12)
    w.R('Hammer handle', (hx, -.078, .62), (hx, -.078, 1.10), .018, 'wood', 12)
    w.R('Hammer handle grip', (hx, -.078, .62), (hx, -.078, .80), .023, 'leather', 12)
    w.B('Hammer head', (hx, -.078, 1.125), (.12, .052, .056), 'steel', .014, 2)
    face = w.C('Hammer striking face', (hx - .095, -.078, 1.125), .036, .05, 'steel_light', 18)
    face.rotation_euler.y = math.pi / 2
    w.Q('Hammer claw', [(hx + .055, -.078, 1.125), (hx + .12, -.078, 1.135), (hx + .165, -.078, 1.075)], .017, 'steel')

    # Screwdrivers: a holder with two holes, each tool standing in its hole on its handle.
    w.wood('Screwdriver holder', (1.28, -.082, .975), (.50, .084, .046), 'oak', .01)
    for x, shaft, grip in ((1.12, .34, 'wood_edge'), (1.40, .25, 'teal')):
        w.C('Holder hole', (x, -.082, .9985), .021, .004, 'ink', 16)
        w.R('Screwdriver shaft', (x, -.082, .975 - shaft), (x, -.082, 1.03), .0085, 'steel_light', 10)
        w.C('Screwdriver handle', (x, -.082, 1.0 + .07), .028, .15, grip, 14, .020)
    w.B('Flat blade tip', (1.12, -.082, .975 - .34 - .012), (.022, .005, .05), 'steel_light', .002)
    w.C('Cross-point tip', (1.40, -.082, .975 - .25 - .014), .0085, .03, 'steel_light', 4, .003)
    finish(path, 'tool_wall_revision_parts')


# --------------------------------------------------------------------------------------------- the mug
def hollow_mug():
    path = opened('workshop-tea-table')
    # The mug was a solid cylinder with a flat disc of tea laid on top of it; the handle stays.
    gone = remove_components(lambda lo, hi, mat: (mat == 'workshop_cream' and lo.x < -.05 and hi.z > .95) or mat == 'workshop_leather_dark')
    assert gone == 2, gone
    profile = [(0.0, .79), (.091, .79), (.100, .80), (.100, .99), (.0885, .99), (.0885, .825), (0.0, .825)]
    segments = 28
    centre = (0, -.06)
    verts, faces = [], []
    ring_start = []
    for r, z in profile:
        if r == 0:
            ring_start.append(len(verts))
            verts.append((centre[0], centre[1], z))
        else:
            ring_start.append(len(verts))
            for i in range(segments):
                a = i / segments * math.tau
                verts.append((centre[0] + r * math.cos(a), centre[1] + r * math.sin(a), z))
    for k in range(len(profile) - 1):
        (r0, _), (r1, _) = profile[k], profile[k + 1]
        for i in range(segments):
            j = (i + 1) % segments
            if r0 == 0:
                faces.append((ring_start[k], ring_start[k + 1] + j, ring_start[k + 1] + i))
            elif r1 == 0:
                faces.append((ring_start[k] + i, ring_start[k] + j, ring_start[k + 1]))
            else:
                faces.append((ring_start[k] + i, ring_start[k] + j, ring_start[k + 1] + j, ring_start[k + 1] + i))
    mesh = bpy.data.meshes.new('Hollow tea mug')
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    o = bpy.data.objects.new('Hollow tea mug', mesh)
    bpy.context.scene.collection.objects.link(o)
    w.h.put(o, 'cream', True)
    finish(path, 'mug_revision_parts')


tool_wall()
hollow_mug()
(HERE / 'tool-wall-and-mug.json').write_text(json.dumps({'date': '2026-10-27', 'record': 'art/source/world/sparks-workshop/v1/tool_wall_and_mug.py', 'sources': records}, indent=2) + '\n')
print('REVISED', [r['asset'] for r in records], flush=True)
