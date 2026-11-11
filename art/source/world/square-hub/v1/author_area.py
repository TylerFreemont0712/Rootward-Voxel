"""Writes content/areas/haverlund-square.json (version 3, the square as the town's hub) from plan.py.

    python3 art/source/world/square-hub/v1/author_area.py

One-time authoring: after the first adoption the JSON document is the master and is edited directly. The previous
version is archived as content/areas/archive/haverlund-square-v2.json. Each building, prop, railing bay and background
house is its own placement on top of the base ground model (haverlund-square-ground), so later work can add, move or
replace any of them without touching the others.
"""
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE))
import plan  # noqa: E402

PREVIOUS = json.loads((ROOT / 'content/areas/haverlund-square.json').read_text())
if PREVIOUS.get('version') == 3 and '--force' not in sys.argv:
    raise SystemExit('Version 3 already written; edit content/areas/haverlund-square.json directly.')
if PREVIOUS.get('version') == 2:
    archive = ROOT / 'content/areas/archive/haverlund-square-v2.json'
    if not archive.exists():
        archive.write_text(json.dumps(PREVIOUS, indent=2, ensure_ascii=False) + '\n')

BAYS = {'balustrade': [('town-balustrade', 3.0), ('town-balustrade-short', 1.5)], 'railing': [('town-railing', 2.0), ('town-railing-short', 1.0)],
        'wall': [('town-garden-wall', 3.0), ('town-garden-wall-short', 1.5)]}
JOINTS = {'balustrade': 'town-balustrade-pier', 'railing': 'town-railing-post', 'railing-stair': 'town-railing-post', 'wall': 'town-garden-pier',
          'gate': 'town-garden-pier'}


def runs():
    """Expands each run into bays laid end to end (scaled together by at most a few per cent so the run fits), and
    stands one pier or post at every bay joint and run end, never two in one place. A raked railing is one stair piece
    placed at its low end, rising along +x; a gate is one piece between two garden piers."""
    placed = []
    counts = {}
    joints = {}

    def put(asset, at, z, turn, scale=1.0):
        counts[asset] = counts.get(asset, 0) + 1
        placed.append({'id': f'{asset}-{counts[asset]}', 'asset': asset, 'at': [round(at[0], 3), round(at[1], 3)], 'turn': round(turn, 2),
                       'height': round(z, 3), 'scale': round(scale, 4)})

    def joint(kind, at, z, turn):
        key = (round(at[0], 2), round(at[1], 2), round(z, 2))
        joints.setdefault(key, (JOINTS[kind], turn))

    for kind, a, b in plan.RUNS:
        dx, dy = b[0] - a[0], b[1] - a[1]
        turn = math.degrees(math.atan2(dy, dx))
        if kind == 'railing-stair':
            low, high = (a, b) if a[2] < b[2] else (b, a)
            put('town-railing-stair', low[:2], low[2], math.degrees(math.atan2(high[1] - low[1], high[0] - low[0])))
            joint(kind, a[:2], a[2], turn)
            joint(kind, b[:2], b[2], turn)
            continue
        if kind == 'gate':
            put('town-garden-gate', a[:2], a[2], turn)
            joint(kind, a[:2], a[2], turn)
            joint(kind, b[:2], b[2], turn)
            continue
        length = math.hypot(dx, dy)
        (long_id, long_len), (short_id, short_len) = BAYS[kind]
        best = None
        for shorts in (0, 1):
            longs = max(0, round((length - shorts * short_len) / long_len))
            total = longs * long_len + shorts * short_len
            if total > 0 and (best is None or abs(total - length) < abs(best[2] - length)):
                best = (longs, shorts, total)
        longs, shorts, total = best
        scale = length / total
        if abs(scale - 1) > .05:
            raise ValueError(f'{kind} run {a}-{b} needs a {scale:.3f} stretch; adjust its ends')
        cursor = 0.0
        for asset, size in [(long_id, long_len)] * longs + [(short_id, short_len)] * shorts:
            t = cursor / length
            put(asset, (a[0] + dx * t, a[1] + dy * t), a[2], turn, scale)
            joint(kind, (a[0] + dx * t, a[1] + dy * t), a[2], turn)
            cursor += size * scale
        joint(kind, b[:2], b[2], turn)
    for (x, y, z), (asset, turn) in sorted(joints.items()):
        put(asset, (x, y), z, turn)
    return placed


def main():
    grid, stairs = plan.cells()
    terrain, levels = [], []
    for y in reversed(range(plan.H)):
        terrain.append(''.join('=' if grid[(x, y)]['walk'] else '#' for x in range(plan.W)))
        levels.append(''.join(str(grid[(x, y)]['level']) for x in range(plan.W)))
    assets, furniture = [], []
    for item in plan.BUILDINGS:
        assets.append({'id': item['id'], 'asset': item['asset'], 'at': item['at'], 'turn': item['turn'], 'height': 0.0, 'scale': item.get('scale', 1.0)})
        for x0, y0, x1, y1 in item['block']:
            furniture.append({'kind': 'counter', 'at': [round((x0 + x1) / 2, 3), round((y0 + y1) / 2, 3)], 'size': [round(x1 - x0, 3), round(y1 - y0, 3)]})
    for ident, asset, x, y, turn, scale, block in plan.DRESSING:
        assets.append({'id': ident, 'asset': asset, 'at': [x, y], 'turn': turn, 'height': 0.0, 'scale': scale})
        if block:
            kind = 'bench' if 'bench' in asset else 'table' if 'stall' in asset or 'cafe' in asset else 'counter'
            # One half-size (hx, hy) round the placement, or several (dx, dy, hx, hy), such as a festoon's two posts.
            for dx, dy, hx, hy in (block if isinstance(block[0], (list, tuple)) else [(0, 0, *block)]):
                furniture.append({'kind': kind, 'at': [round(x + dx, 3), round(y + dy, 3)], 'size': [round(hx * 2, 3), round(hy * 2, 3)]})
    assets.extend(runs())
    # Glowing power pillars where the retaining walls' carved pilasters stood (pillars_revision.py).
    for index, pillar in enumerate(json.loads((HERE / 'pillars-haverlund-square-ground.json').read_text())):
        assets.append({'id': f'power-pillar-{index + 1}', 'asset': 'town-power-pillar', 'at': pillar['at'], 'turn': pillar['turn'],
                       'height': pillar['top'], 'scale': 1.0})
    for index, (asset, x, y, z, turn, look) in enumerate(plan.HOUSES):
        assets.append({'id': f'town-house-{index + 1}', 'asset': asset, 'at': [x, y], 'turn': turn, 'height': z, 'scale': 1.0, 'look': look})
    for index, (asset, x, y, z, turn, scale) in enumerate(plan.TREES):
        assets.append({'id': f'town-tree-{index + 1}', 'asset': asset, 'at': [x, y], 'turn': turn, 'height': z, 'scale': scale})
    # The companion's perch at the head of the street, until she wakes.
    assets.append({'id': 'dormant-hotaru', 'asset': 'loft-hotaru', 'at': [1.5, 10.2], 'turn': 0, 'height': 2.9, 'scale': 1.0})
    lamps = [{'id': lamp['id'], 'at': lamp['at'], 'zone': 'rootward-square', 'style': 'fixture', 'title': lamp['title'],
              'stand': lamp['stand'], 'requires': 'field-tablet'} for lamp in plan.LAMPS]
    life = {
        'smoke': [{'at': [3.6, 23.1], 'height': 12.4}, {'at': [35.5, 57.0], 'height': 13.2},
                  {'at': [27.9, 61.7], 'height': 10.4}, {'at': [56.8, 57.6], 'height': 12.0}, {'at': [42.0, 69.8], 'height': 13.4}],
        'sway': [item[0] for item in plan.DRESSING if item[1] == 'square-banner-lamp'],
        'gulls': {'at': [48, -8], 'height': 9, 'count': 4},
        'robots': [
            {'asset': 'pip', 'path': [[56.0, 45.6], [48.0, 45.6], [38.0, 45.6], [28.0, 45.6], [28.0, 44.0], [23.0, 44.0]], 'speed': .85, 'pause': 5, 'loop': False},
            {'asset': 'trowel', 'path': [[55.6, 22.6], [68.4, 22.6], [68.4, 25.4], [55.6, 25.4]], 'speed': .55, 'pause': 3, 'loop': True},
            {'asset': 'porter', 'path': [[14.0, 9.0], [18.0, 9.0], [18.0, 5.0]], 'speed': .7, 'pause': 3, 'loop': False},
        ],
    }
    document = {
        'schema': PREVIOUS['schema'], 'id': 'haverlund-square', 'title': 'Rootward Square', 'version': 3,
        'size': [plan.W, plan.H], 'spawn': list(plan.ARRIVAL), 'voice_lesson': PREVIOUS.get('voice_lesson', False),
        'terrain': terrain, 'levels': levels, 'stairs': stairs, 'buildings': [], 'trees': [], 'zones': plan.ZONES,
        'lamps': lamps, 'props': [],
        'terminals': [dict(PREVIOUS['terminals'][0], at=[35, 17])],
        'interior': {
            'style': 'workshop-square', 'shell': 'haverlund-square-ground', 'exit': [0, plan.ARRIVAL[1]], 'exit_direction': 'W',
            'exit_posts': [], 'walk_front': 0, 'zoom': 16.0,
            'outdoor': PREVIOUS['interior']['outdoor'], 'life': life, 'furniture': furniture, 'assets': assets,
            'links': [{'id': 'uphill', 'at': [0, plan.ARRIVAL[1]], 'approach': [0, plan.ARRIVAL[1]], 'direction': 'W', 'to': 'haverlund-lane',
                       'arrival': [12, 26], 'facing': 'S', 'label': 'Climb Spindle Steps',
                       # The whole street is the way up: any of its five cells crosses, arriving on the matching side
                       # of the lane's steps, and the apprentice walks on through the gate.
                       'cells': [[0, y] for y in plan.STREET_Y], 'arrivals': [[12, 26], [12, 26], [12, 26], [13, 26], [13, 26]],
                       'walk_through': True, 'enter': 2}],
            'inspections': [{'id': i, 'at': at, 'title': title, 'text': text} for i, at, title, text in plan.INSPECTIONS],
            'lamp_fixtures': [{'id': lamp['id'], 'asset': lamp['asset'], 'range': 5, 'energy': .8} for lamp in plan.LAMPS],
            'lighting': [{'at': list(plan.ROOTWELL), 'height': 6.6, 'range': 10, 'energy': 1.1, 'color': 'ffc274'},
                         {'at': [41.0, 49.0], 'height': 2.4, 'range': 3, 'energy': .35, 'color': 'ffcc7d'}],
        },
    }
    (ROOT / 'content/areas/haverlund-square.json').write_text(json.dumps(document, indent=2, ensure_ascii=False) + '\n')
    print('Wrote haverlund-square v3:', len(assets), 'placements,', len(furniture), 'blocks')


if __name__ == '__main__':
    main()
