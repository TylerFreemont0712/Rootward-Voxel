"""Deliberate, backed-up source edit: surfaces that sat exactly in one plane now stand a few millimetres apart, so the
renderer no longer flickers between them as the camera follows the apprentice.

A depth probe of the square (the camera slid along its view axis, which changes no pixel except where two surfaces
share a depth) found two kinds of flicker:

    town-fountain         the water in the basin was a disc in the very plane of the bowl's top, in the same mesh.
                          The water discs are lifted 6 mm (basin) and 4 mm (the small trough), and the trough's own top
                          disc 4 mm off the step it stands on.
    seaside kit buildings stone, shutter, timber and paint layers laid in the plane of the plaster or stone behind them
                          (the cafe's shop-front base flickered under its awning). Wherever two triangles of different
                          materials face the same way in the same plane, overlap, and one is turned towards the camera at
                          any of the four placement turns, the upper layer is lifted 4 mm along its own normal. The
                          pass repeats until no pair is left (a lifted stone block can meet a lifted timber beam), so
                          a stack of layers ends up 4 mm apart each. Layers rank shutter > timber > paint > stone >
                          plaster/brick. The `alt_*` parts are per-placement alternatives (only one is ever shown)
                          and are left alone.

Nothing else moves. Each file as it was is kept once as model.pre-coplanar.blend, with a note of what was lifted;
running the script again starts from that original, so it can be tuned and repeated.
Export afterwards with scripts/world-art.sh build <id>.

    blender --background --factory-startup --python art/source/world/square-hub/v1/coplanar_revision.py -- <id> [<id> ...]
"""
import json
import math
import shutil
import sys
from collections import defaultdict
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
LIFT = 0.006          # the fountain's water discs
STEP = 0.004          # one pass of lifting for the building layers
TOL = 0.003
CAMERA = Vector((21.0, 17.8, 21.0))   # towards the camera, in Godot axes (ClearingView.CAMERA_OFFSET)
RANK = {'seaside_shutter': 6, 'seaside_timber': 5, 'house_paint': 4, 'seaside_stone': 3,
        'seaside_plaster': 2, 'seaside_plaster_2': 2, 'house_brick': 2}


def faces_camera(normal, turns=(0, 90, 180, 270)):
    """Blender (x, y, z up) to Godot (x, z, -y), then each placement's yaw."""
    g = Vector((normal.x, normal.z, -normal.y))
    for turn in turns:
        a = math.radians(turn)
        r = Vector((g.x * math.cos(a) + g.z * math.sin(a), g.y, -g.x * math.sin(a) + g.z * math.cos(a)))
        if r.dot(CAMERA) > 0.02:
            return True
    return False


def inside(point, a, b, c, normal):
    s = [((b - a).cross(point - a)).dot(normal), ((c - b).cross(point - b)).dot(normal), ((a - c).cross(point - c)).dot(normal)]
    return all(x >= -1e-7 for x in s) or all(x <= 1e-7 for x in s)


def triangles():
    out = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or obj.name.startswith('IllustratedOutline') or obj.name.startswith('alt_'):
            continue
        mesh = obj.data
        mesh.calc_loop_triangles()
        world = obj.matrix_world
        names = [m.name if m else '' for m in mesh.materials]
        for t in mesh.loop_triangles:
            pts = [world @ mesh.vertices[i].co for i in t.vertices]
            normal = (pts[1] - pts[0]).cross(pts[2] - pts[0])
            if normal.length < 2e-5:
                continue
            normal.normalize()
            out.append({'obj': obj, 'verts': list(t.vertices), 'pts': pts, 'n': normal, 'd': normal.dot(pts[0]),
                        'mat': names[t.material_index] if names else ''})
    return out


def lifts_for_buildings():
    tris = triangles()
    buckets = defaultdict(list)
    for t in tris:
        buckets[(round(t['n'].x * 25), round(t['n'].y * 25), round(t['n'].z * 25), round(t['d'] / (TOL * 2)))].append(t)
    chosen = {}
    for key, items in buckets.items():
        pool = list(items)
        for dk in (-1, 1):
            pool.extend(buckets.get((key[0], key[1], key[2], key[3] + dk), []))
        for a in items:
            if not faces_camera(a['n']):
                continue
            for b in pool:
                if b is a or a['mat'] == b['mat'] or abs(a['d'] - b['d']) > TOL or a['n'].dot(b['n']) < 0.999:
                    continue
                ra, rb = RANK.get(a['mat'], 1), RANK.get(b['mat'], 1)
                if ra <= rb:
                    continue
                centre = sum(a['pts'], Vector()) / 3
                if sum(1 for p in [centre] + [centre + (q - centre) * 0.6 for q in a['pts']] if inside(p, *b['pts'], a['n'])) >= 2:
                    chosen[id(a)] = a
                    break
    return list(chosen.values())


def lift(chosen):
    """Moves each chosen triangle's vertices out along its normal by STEP, once per vertex."""
    moves = defaultdict(lambda: Vector())
    for t in chosen:
        for v in t['verts']:
            moves[(t['obj'].name, v)] += t['n']
    for (name, v), push in moves.items():
        obj = bpy.data.objects[name]
        if push.length < 1e-6:
            continue
        local = obj.matrix_world.to_3x3().inverted() @ (push.normalized() * STEP)
        obj.data.vertices[v].co += local
    for name in {n for n, _ in moves}:
        bpy.data.objects[name].data.update()
    return len(chosen), len(moves)


def lift_fountain():
    """Water discs are faces painted with the water texel (uv v = 0.3, u = 0.688) in the body mesh."""
    obj = bpy.data.objects['house_paint']
    mesh = obj.data
    uv = mesh.uv_layers.active
    moved = {}
    for poly in mesh.polygons:
        if poly.normal.z < 0.99:
            continue
        u = sum(uv.data[i].uv[0] for i in poly.loop_indices) / poly.loop_total
        v = sum(uv.data[i].uv[1] for i in poly.loop_indices) / poly.loop_total
        if abs(u - 0.688) > 0.01 or abs(v - 0.3) > 0.01:
            continue
        z = sum(mesh.vertices[i].co.z for i in poly.vertices) / poly.loop_total
        for i in poly.vertices:
            moved[i] = 0.004 if z < 0.5 else 0.006
    for i, dz in moved.items():
        mesh.vertices[i].co.z += dz
    mesh.update()
    # The small trough's top disc lay in the plane of the step it stands on (both stone, differently mapped).
    stone = bpy.data.objects['seaside_stone'].data
    trough = {i for poly in stone.polygons if poly.normal.z > 0.99 and poly.loop_total == 12
              and abs(sum(stone.vertices[i].co.z for i in poly.vertices) / 12 - 0.22) < 0.001 for i in poly.vertices}
    for i in trough:
        stone.vertices[i].co.z += 0.004
    stone.update()
    return len(moved) + len(trough)


def revise(asset):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = source.with_name('model.pre-coplanar.blend')
    created = not backup.exists()
    if created:
        shutil.copy2(source, backup)
    else:
        shutil.copy2(backup, source)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if asset == 'town-fountain':
        count = lift_fountain()
        note = {'water_vertices_lifted': count}
    else:
        first = lifts_for_buildings()
        if not first:
            if created:
                backup.unlink()
            print('CLEAN', asset, flush=True)
            return
        passes, by_material = 0, defaultdict(int)
        chosen = first
        while chosen and passes < 8:
            faces, verts = lift(chosen)
            for t in chosen:
                by_material[t['mat']] += 1
            passes += 1
            chosen = lifts_for_buildings()
        note = {'passes': passes, 'triangle_lifts_by_material': dict(sorted(by_material.items())), 'left_over': len(chosen)}
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    source.with_name('coplanar.json').write_text(json.dumps({
        'asset': asset, 'date': '2026-10-30', 'record': 'art/source/world/square-hub/v1/coplanar_revision.py',
        'backup': backup.name, 'step_metres': STEP, 'water_lift_metres': LIFT, **note}, indent=2) + '\n')
    print('REVISED', asset, note, flush=True)


if __name__ == '__main__':
    for asset_id in sys.argv[sys.argv.index('--') + 1:]:
        revise(asset_id)
