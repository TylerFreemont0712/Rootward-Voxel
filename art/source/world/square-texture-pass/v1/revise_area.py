"""One-time record of the texture pass on content/areas/haverlund-square.json (v9 -> v10).

The JSON document is the master afterwards; edit it (or the layout studio) rather than rerunning this. It:
  * marks the two new cells of Spindle Steps (x 4-5, y 6-10, ground v9) as the flight they are, and adds a
    second walk-through link ('uphill-steps') across the flight's foot, so walking onto the steps climbs to the lane
    exactly as walking west past the spawn always has ('uphill', its cells and arrivals are unchanged);
  * plants the high gardens behind the rear wall and west of the steps (ground v9 made them lawn): a line of
    cypresses and fruit trees along the top of the wall, and trees further back, as room scenery;
  * gives the lawn at the north end of the walk (y 55-62) a reason to be there: trees and a bench facing the
    view, as layout-studio props (the layout's scope grows to cover it).
The layout epoch is unchanged: nothing a studio edit could stand on moves, so saved layouts still apply.
Run: python3 art/source/world/square-texture-pass/v1/revise_area.py   (refuses a document already at v10)
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
AREA = ROOT / 'content/areas/haverlund-square.json'
doc = json.loads(AREA.read_text())
if doc['version'] >= 10:
    raise SystemExit('Area already revised; edit the document instead.')
room = doc['interior']
H = doc['size'][1]

# --- Spindle Steps reach the terrace ------------------------------------------------------------------------------
terrain = [list(r) for r in doc['terrain']]
for y in range(6, 11):
    for x in (4, 5):
        terrain[H - 1 - y][x] = '#'
doc['terrain'] = [''.join(r) for r in terrain]
uphill = next(i for i, l in enumerate(room['links']) if l['id'] == 'uphill')
room['links'].insert(uphill + 1, {'id': 'uphill-steps', 'at': [6, 8], 'approach': [6, 8], 'direction': 'W',
                                  'to': 'haverlund-lane', 'arrival': [12, 26], 'facing': 'S',
                                  'label': 'Climb Spindle Steps', 'cells': [[6, y] for y in range(6, 11)],
                                  'arrivals': [[12, 26], [12, 26], [12, 26], [13, 26], [13, 26]],
                                  'walk_through': True, 'enter': 2.0})

# --- the high gardens -----------------------------------------------------------------------------------------------
def tree(tid, asset, x, y, height, scale, turn=0):
    room['assets'].append({'id': tid, 'asset': asset, 'at': [x, y], 'turn': turn, 'height': height, 'scale': scale})


row = [(17.5, 'lane-cypress', .9), (21.5, 'lane-tree', .85), (26.0, 'lane-cypress', .95), (31.0, 'lane-tree', .9),
       (35.5, 'lane-cypress', .85), (40.0, 'lane-tree', .8), (44.5, 'lane-cypress', 1.0), (49.0, 'lane-tree', .9),
       (53.0, 'lane-cypress', .9)]
for n, (y, asset, scale) in enumerate(row):
    tree(f'high-garden-{n}', asset, 7.4 if asset == 'lane-cypress' else 6.2, y, 4.0, scale, 37 * n)
for n, (x, y, scale) in enumerate([(4.6, 24.0, .95), (4.2, 38.0, 1.0), (5.0, 50.5, .9), (12.0, 58.5, .95),
                                   (13.6, 61.5, .85)]):
    tree(f'high-orchard-{n}', 'lane-tree', x, y, 4.0, scale, 53 * n + 20)
for n, (x, y, scale) in enumerate([(-2.5, 16.5, 1.0), (-4.0, 27.0, .95), (-2.0, 36.0, 1.05), (-5.0, 46.0, .9),
                                   (-1.5, 2.0, .9)]):
    tree(f'upper-town-tree-{n}', 'lane-tree' if n % 2 == 0 else 'lane-cypress', x, y, 6.0, scale, 71 * n)

# --- the north lawn -----------------------------------------------------------------------------------------------
room['layout']['rect'] = [4, 0, 24, H]
for pid, asset, at, facing, scale in [('north-lawn-tree-0', 'lane-tree', [18.5, 59.5], 'S', .8),
                                      ('north-lawn-tree-1', 'lane-tree', [24.5, 61.0], 'S', .75),
                                      ('north-lawn-cypress', 'lane-cypress', [17.0, 62.0], 'S', .7),
                                      ('north-lawn-bench', 'lane-bench', [22.0, 58.0], 'E', 1.0)]:
    doc['props'].append({'id': pid, 'asset': asset, 'at': at, 'facing': facing, 'scale': scale})

doc['version'] = 10
AREA.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + '\n')
print('Square texture pass: area v10.')
