"""One-time record of the Spindle Walk terrace revision of content/areas/haverlund-square.json (v8 -> v9).

The JSON document is the master afterwards; edit it (or the layout studio) rather than rerunning this. It:
  * sets the market shop-houses (bakery, The Pantry, Finch & Thread) one cell back against the terrace wall, so no
    path runs in the hidden gap behind them, and moves their doors, inspections and window lamps with them;
  * places Thyme & Tonic beside Pendulum & Pin with a working door, window light and inspection;
  * retires the walled lawns of the clockmaker's court and opens the rear shelf as walkable terrace: a walled physic
    garden north of the apothecary (entered through an opening facing the walk, a fountain on the gate's axis,
    benches facing it, herb beds and trees);
  * dresses the walk's outer edge in one rhythm of lamps, benches facing the view and trees, all as layout-studio
    props so they can be moved, turned or removed in build mode;
  * aligns the logical ground with the repaved terrace and bumps the layout epoch (older layout edits are archived,
    not replayed over the new ground).
Run: python3 art/source/world/square-terrace/v1/revise_area.py   (refuses a document already at v9)
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
AREA = ROOT / 'content/areas/haverlund-square.json'
ROOM = ROOT / 'content/areas/shop-apothecary.json'


def read(p):
    return json.loads(p.read_text())


def write(p, d):
    p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + '\n')


doc = read(AREA)
if doc['version'] >= 9:
    raise SystemExit('Area already revised; edit the document instead.')
room = doc['interior']
H = doc['size'][1]

# --- the market shop-houses: one cell back against the terrace wall ---------------------------------------------
SHOPS = ['bakery', 'greengrocer', 'bookshop']
for a in room['assets']:
    if a['id'] in SHOPS:
        a['at'][0] = round(a['at'][0] - 1.0, 3)
for link in room['links']:
    if link['id'] in SHOPS:
        link['at'][0] -= 1; link['approach'][0] -= 1
for ins in room['inspections']:
    if ins['id'] in SHOPS:
        ins['at'][0] -= 1
for lamp in doc['lamps']:
    if lamp['id'] in [s + '-window-lamp' for s in SHOPS]:
        lamp['at'][0] -= 1; lamp['stand'][0] -= 1

# --- retire the court dressing and the old strip pieces ---------------------------------------------------------
room['assets'] = [a for a in room['assets'] if not a['id'].startswith('court-') and a['id'] not in ('strip-tree-0', 'strip-tree-1')]
OLD_BLOCKS = [[23.3, 18], [21.5, 35], [21.5, 50], [21.2, 24.4], [21.2, 42.4]]
room['furniture'] = [f for f in room['furniture'] if [round(f['at'][0], 2), round(f['at'][1], 2)] not in OLD_BLOCKS]
doc['props'] = [p for p in doc['props'] if p['id'] not in
                ('strip-planter-2', 'strip-planter-3', 'strip-planter-4', 'strip-bench-0', 'strip-bench-1')]

# --- Thyme & Tonic ----------------------------------------------------------------------------------------------
room['assets'].append({'id': 'apothecary', 'asset': 'haverlund-apothecary', 'at': [12.55, 30.4], 'turn': 90,
                       'height': 2.0, 'scale': 1, 'solid': True})
clock_link = next(i for i, l in enumerate(room['links']) if l['id'] == 'clockmaker')
room['links'].insert(clock_link + 1, {'id': 'apothecary', 'at': [16, 30], 'approach': [16, 30], 'direction': 'W',
                                      'to': 'shop-apothecary', 'arrival': [6, 0], 'facing': 'N',
                                      'label': 'Enter Thyme & Tonic', 'walk_through': True, 'enter': 2,
                                      'doors': 'apothecary'})
room['lamp_fixtures'].append({'id': 'apothecary-window-lamp', 'asset': 'apothecary', 'range': 4.3, 'energy': 0.7})
doc['lamps'].append({'id': 'apothecary-window-lamp', 'at': [15.3, 30], 'stand': [16, 30], 'zone': 'spindle-strip',
                     'style': 'fixture', 'automatic': True, 'requires': 'field-tablet'})
room['inspections'].append({'id': 'apothecary', 'at': [16, 32], 'title': 'Thyme & Tonic',
                            'text': 'Jars in the window, every one labelled by hand. One label just says DON’T.'})
room['inspections'].append({'id': 'physic-garden', 'at': [16, 44], 'title': 'The physic garden',
                            'text': 'A slate by the opening: PLEASE DON’T PICK THE FOXGLOVE. Underneath, smaller: OR THE MINT.'})

# --- walk lamps on the outer edge, fed by the new conduit ------------------------------------------------------
LAMP_Y = [18, 30, 42, 52.5]
for n, y in enumerate(LAMP_Y):
    lid = f'strip-lamp-{n}'
    model = next((a for a in room['assets'] if a['id'] == lid), None)
    if model is None:
        model = {'id': lid, 'asset': 'square-banner-lamp', 'at': [0, 0], 'turn': 180, 'height': 2, 'scale': 1}
        room['assets'].append(model)
    model['at'] = [25.8, y]
    lamp = next((l for l in doc['lamps'] if l['id'] == lid), None)
    if lamp is None:
        lamp = {'id': lid, 'zone': 'spindle-strip', 'style': 'fixture', 'requires': 'field-tablet', 'automatic': True,
                'title': 'Spindle strip lamp'}
        doc['lamps'].append(lamp)
    lamp['at'] = [25.8, y]; lamp['stand'] = [25, int(y)]
    room['furniture'].append({'kind': 'counter', 'at': [25.8, y], 'size': [0.5, 0.5]})
    if not any(fx['id'] == lid for fx in room['lamp_fixtures']):
        room['lamp_fixtures'].append({'id': lid, 'asset': lid, 'range': 7, 'energy': 1.65})
    if lid not in room['life']['sway']:
        room['life']['sway'].append(lid)

# --- layout-studio props: the walk's edge rhythm, the shop fronts and the physic garden -------------------------
def prop(pid, asset, at, facing, scale=1.0):
    doc['props'].append({'id': pid, 'asset': asset, 'at': at, 'facing': facing, 'scale': scale})


for n, y in enumerate([21, 27, 39, 45]):
    prop(f'walk-bench-{n}', 'lane-bench', [25.9, y], 'E')           # backs to the walk, facing the view
for n, y in enumerate([24, 36, 48]):
    prop(f'walk-tree-{n}', 'lane-tree', [25.6, y], 'S', 0.55)
for n, y in enumerate([24, 36, 48]):
    room['assets'].append({'id': f'walk-tree-grate-{n}', 'asset': 'town-tree-grate', 'at': [25.6, y], 'turn': 0, 'height': 2, 'scale': 1})
# Garden wall along the walk (x 15.45) with a 2 m opening on the fountain's axis, and its south return.
WALL_X = 15.45
# A 3 m opening (y 43-46) on the fountain's axis; the last bay stops at the foot of the north wall.
for n, (y, asset) in enumerate([(37.0, 'town-garden-wall'), (40.0, 'town-garden-wall'), (46.0, 'town-garden-wall'),
                                (49.0, 'town-garden-wall'), (52.0, 'town-garden-wall-short')]):
    prop(f'garden-wall-{n}', asset, [WALL_X, y], 'E')
for n, y in enumerate([37.0, 40.0, 43.0, 46.0, 49.0, 52.0, 53.5]):
    prop(f'garden-pier-{n}', 'town-garden-pier', [WALL_X, y], 'E')
for n, (x, asset) in enumerate([(9.55, 'town-garden-wall'), (12.55, 'town-garden-wall-short'), (13.95, 'town-garden-wall-short')]):
    prop(f'garden-south-wall-{n}', asset, [x, 37.0], 'S')
for n, x in enumerate([12.55, 13.95]):
    prop(f'garden-south-pier-{n}', 'town-garden-pier', [x, 37.0], 'S')
prop('garden-fountain', 'town-fountain', [12.4, 44.45], 'E')
prop('garden-bench-s', 'lane-bench', [12.4, 42.3], 'N')
prop('garden-bench-n', 'lane-bench', [12.4, 46.7], 'S')
prop('garden-tree-1', 'lane-tree', [10.5, 52.6], 'S', 0.6)
prop('garden-cypress-1', 'lane-cypress', [13.6, 53.0], 'S', 0.55)
prop('garden-cypress-2', 'lane-cypress', [10.4, 38.6], 'S', 0.5)
prop('garden-planter-3', 'lane-planter', [10.3, 46.0], 'E', 0.75)
prop('garden-planter-4', 'lane-planter', [10.3, 43.0], 'E', 0.75)
room['assets'].extend([
    {'id': 'garden-bed-1', 'asset': 'town-lawn', 'at': [12.4, 50.9], 'turn': 0, 'height': 2.0, 'scale': 0.42},
    {'id': 'garden-bed-2', 'asset': 'town-lawn', 'at': [12.4, 39.0], 'turn': 0, 'height': 2.0, 'scale': 0.42},
])

# --- logical ground: the shelf joins the terrace; the paved strip is paving -------------------------------------
terrain = [list(r) for r in doc['terrain']]
levels = [list(r) for r in doc['levels']]
for y in range(16, 55):
    row = H - 1 - y
    for x in range(10, 21):
        if x <= 15 and y >= 25:
            terrain[row][x] = '='; levels[row][x] = '2'
        elif x >= 16 and terrain[row][x] == '.':
            terrain[row][x] = '='
doc['terrain'] = [''.join(r) for r in terrain]
doc['levels'] = [''.join(r) for r in levels]
for zone in doc['zones']:
    if zone['id'] == 'spindle-strip':
        zone['rect'] = [10, 11, 18, 44]

# The authored flights (ground master) have five 0.2 m steps per level; the feet and contact shadows follow them.
room['stair_steps'] = 5
room['layout_epoch'] = 9
doc['version'] = 9
write(AREA, doc)

# The apothecary's room returns to its own door.
inside = read(ROOM)
back = next(l for l in inside['interior']['links'] if l['id'] == 'square')
back.update({'arrival': [16, 30], 'facing': 'E', 'label': 'Return to Spindle Walk'})
write(ROOM, inside)
print('Spindle Walk terrace revised: area v9, layout epoch 9.')
