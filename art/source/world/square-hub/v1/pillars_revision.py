"""Deliberate, backed-up source edit: the city-power-grid pass gave the retaining walls' pilasters a carved-light
pattern ('Existing_power_pillars'). The user asked for the whole column to be the power source instead, so this
removes those pilasters from the square ground and the lane surround and records where each stood. The area
documents place a town-power-pillar there: a large glowing column standing out of the wall up to its coping.

Each pilaster's outward side is the lower of the ground either side of it (a ray straight down; no ground on a side
means the lane set's terrace, the higher side). Its wall top is 2.59 m above the pilaster's top, as the ground record
built them. The files as they were are kept once as model.pre-pillars.blend.

    blender --background --factory-startup --python art/source/world/square-hub/v1/pillars_revision.py -- <asset id>
"""
import json
import math
import shutil
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent


def ground_tree(skip):
    verts, faces = [], []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or obj == skip:
            continue
        base = len(verts)
        verts.extend(obj.matrix_world @ v.co for v in obj.data.vertices)
        faces.extend(tuple(base + i for i in poly.vertices) for poly in obj.data.polygons)
    return BVHTree.FromPolygons(verts, faces)


def main(asset):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    pillars = bpy.data.objects.get('Existing_power_pillars')
    if pillars is None:
        raise SystemExit(asset + ' has no carved pilasters left to replace.')
    backup = source.with_name('model.pre-pillars.blend')
    if not backup.exists():
        shutil.copy2(source, backup)
    tree = ground_tree(pillars)
    bm = bmesh.new()
    bm.from_mesh(pillars.data)
    seen, placed = set(), []
    for v in bm.verts:
        if v in seen:
            continue
        stack, group = [v], []
        seen.add(v)
        while stack:
            q = stack.pop()
            group.append(q)
            for e in q.link_edges:
                u = e.other_vert(q)
                if u not in seen:
                    seen.add(u)
                    stack.append(u)
        pts = [pillars.matrix_world @ q.co for q in group]
        lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
        hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
        centre = (lo + hi) / 2
        thin = 0 if hi.x - lo.x < hi.y - lo.y else 1
        probe = []
        for sign in (-1, 1):
            q = centre.copy()
            q[thin] += sign * 1.2
            hit = tree.ray_cast(Vector((q.x, q.y, 60)), Vector((0, 0, -1)), 200)
            probe.append(hit[0].z if hit[0] is not None else 1e9)
        outward = -1 if probe[0] < probe[1] else 1
        face = (lo if outward > 0 else hi)[thin] - outward * .05      # the pilaster stood 0.05 into the wall
        face = (hi if outward > 0 else lo)[thin] - outward * .14
        at = [centre.x, centre.y]
        at[thin] = face
        out = (outward, 0) if thin == 0 else (0, outward)
        turn = {(0, -1): 0, (1, 0): 90, (0, 1): 180, (-1, 0): 270}[out]
        placed.append({'at': [round(at[0], 3), round(at[1], 3)], 'top': round(hi.z + 2.59, 3), 'turn': turn})
    bm.free()
    bpy.data.objects.remove(pillars, do_unlink=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    placed.sort(key=lambda item: (item['turn'], item['at'][0], item['at'][1]))
    (HERE / f'pillars-{asset}.json').write_text(json.dumps(placed, indent=1) + '\n')
    source.with_name('pillars-revision.json').write_text(json.dumps({
        'asset': asset, 'date': '2026-10-29', 'record': 'art/source/world/square-hub/v1/pillars_revision.py',
        'backup': backup.name, 'removed': len(placed), 'placements': f'art/source/world/square-hub/v1/pillars-{asset}.json',
        'note': 'Carved pilasters removed; the area document places town-power-pillar models where they stood.'}, indent=2) + '\n')
    print('REVISED', asset, len(placed), 'pillars', flush=True)


if __name__ == '__main__':
    main(sys.argv[sys.argv.index('--') + 1])
