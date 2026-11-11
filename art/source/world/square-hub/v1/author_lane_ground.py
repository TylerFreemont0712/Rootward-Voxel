"""Guarded one-time authoring of haverlund-lane-surround: the town's land round Spindle Lane (lane_plan.py), drawn
with the square ground's tools so both areas share one stone, paving and wall language. It never draws the lane
set's own cells; it covers the set's cut faces with dressed retaining walls down to the lower town.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_lane_ground.py
    ... -- --draft .cache/square-hub/drafts
"""
import hashlib
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import author_ground as ground  # noqa: E402
import lane_plan  # noqa: E402

kit = ground.kit
ASSET = 'haverlund-lane-surround'
EAST, NEAR, NORTH = 23.5, -1.4, 27.5


def cells():
    grid = {}
    for x in range(lane_plan.X0, lane_plan.X1 + 1):
        for y in range(lane_plan.Y0, lane_plan.Y1 + 1):
            if lane_plan.owned(x, y):
                grid[(x, y)] = {'z': 0.0, 'mat': 'ground_flags', 'stair': None, 'skip': True}
    for (x, y), (z, kind) in lane_plan.heights().items():
        mat = {'street': 'ground_cobbles', 'yard': 'ground_flags'}.get(kind) or ('ground_grass' if ground.garden(x, y) else 'ground_flags')
        grid[(x, y)] = {'z': z, 'mat': mat, 'stair': None, 'kind': 'outside'}
    stairs, plain = lane_plan.steps()
    for (x, y), z in plain.items():
        grid[(x, y)].update(z=z, mat='ground_cobbles')
    for x, y, low, high in stairs:
        grid[(x, y)].update(z=high, low=low, mat='stone', stair='S')
    return grid


def cover(p, axis, line, out, a, b, top, low):
    """A dressed retaining wall over one of the lane set's cut faces, standing just outside it."""
    ground.wall(p, axis, line, out, a, b, low, top, True, True)


def assemble():
    root = kit.begin(ASSET, ground.PALETTE)
    ground.materials()
    ground.X0, ground.X1, ground.Y0, ground.Y1 = lane_plan.X0, lane_plan.X1, lane_plan.Y0, lane_plan.Y1
    ground.LT = lane_plan.LT
    p = kit.Parts(6101)
    grid = cells()
    ground.tops(p, grid)
    ground.walls(p, grid)
    ground.treads(p, grid)
    # Over the set's cut faces: the south face under the halt and the tunnel hill, the east face under the halt and
    # the lane, the north face beyond the lookout's balustrade.
    lt = lane_plan.LT
    cover(p, 'x', NEAR - .14, -1, -3.55, -.45, 4.7, lt)
    cover(p, 'x', NEAR - .14, -1, -.45, EAST + .14, 0.0, lt)
    cover(p, 'y', EAST + .14, 1, NEAR - .14, 4.5, 0.0, lt)
    cover(p, 'y', EAST + .14, 1, 4.5, NORTH + .14, 1.0, lt)
    cover(p, 'x', NORTH + .14, 1, 15.5, EAST + .14, 1.0, -3.0)
    p.finish(root)


def save(out=None):
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    bpy.ops.file.pack_all()
    if out:
        path = Path(out) / ASSET / 'model.blend'
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(path))
        print('DRAFT', ASSET, path, flush=True)
        return
    scene['rootward_source'] = 'Editable authority: the town round Spindle Lane. Do not rerun the authoring record.'
    folder = ground.ROOT / 'art/source/world' / ASSET / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()  # noqa: E731
    note = {'asset': ASSET, 'date': '2026-10-29', 'authoring_record': 'art/source/world/square-hub/v1/author_lane_ground.py',
            'authoring_record_sha256': digest(__file__), 'plan': 'art/source/world/square-hub/v1/lane_plan.py',
            'plan_sha256': digest(HERE / 'lane_plan.py'), 'drawing': 'art/source/world/square-hub/v1/author_ground.py',
            'drawing_sha256': digest(HERE / 'author_ground.py'),
            'note': 'Land only round the lane set; houses are separate placed models. Build through scripts/world-art.sh.'}
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', ASSET, flush=True)


if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    draft = argv[argv.index('--draft') + 1] if '--draft' in argv else None
    if not draft and (ground.ROOT / 'art/source/world' / ASSET / 'v1/model.blend').exists():
        raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + ASSET)
    assemble()
    save(draft)
