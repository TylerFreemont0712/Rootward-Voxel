"""Adds the town round Spindle Lane to content/areas/haverlund-lane.json (version 4): the surround ground model and
the background houses and trees from lane_plan.py, each its own placement. Also points the town steps at Rootward
Square's new arrival. The previous document is archived as content/areas/archive/haverlund-lane-v3.json.

    python3 art/source/world/square-hub/v1/dress_lane.py
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE))
import lane_plan  # noqa: E402
import plan  # noqa: E402

PATH = ROOT / 'content/areas/haverlund-lane.json'
document = json.loads(PATH.read_text())
if document['version'] != 3:
    raise SystemExit('Spindle Lane is already dressed (version %d); edit the document directly.' % document['version'])
archive = ROOT / 'content/areas/archive/haverlund-lane-v3.json'
if not archive.exists():
    archive.write_text(json.dumps(document, indent=2, ensure_ascii=False) + '\n')
document['version'] = 4
assets = document['interior']['assets']
assets.append({'id': 'town-ground', 'asset': 'haverlund-lane-surround', 'at': [0, 0], 'turn': 0, 'height': 0.0, 'scale': 1.0})
for index, (asset, x, y, z, turn, look) in enumerate(lane_plan.HOUSES):
    assets.append({'id': f'town-house-{index + 1}', 'asset': asset, 'at': [x, y], 'turn': turn, 'height': z, 'scale': 1.0, 'look': look})
for index, (asset, x, y, z, turn, scale) in enumerate(lane_plan.TREES):
    assets.append({'id': f'town-tree-{index + 1}', 'asset': asset, 'at': [x, y], 'turn': turn, 'height': z, 'scale': scale})
# A stone balustrade along the tram bed's open south edge over the lower town: eight 3 m bays and nine piers.
scale = (23.6 + .45) / 24.0
for k in range(8):
    assets.append({'id': f'town-balustrade-{k + 1}', 'asset': 'town-balustrade', 'at': [round(-.45 + 3 * scale * k, 3), -1.55], 'turn': 0, 'height': 0.0, 'scale': round(scale, 4)})
for k in range(9):
    assets.append({'id': f'town-balustrade-pier-{k + 1}', 'asset': 'town-balustrade-pier', 'at': [round(-.45 + 3 * scale * k, 3), -1.55], 'turn': 0, 'height': 0.0, 'scale': 1.0})
for link in document['interior']['links']:
    if link['to'] == 'haverlund-square':
        link['arrival'] = list(plan.ARRIVAL)
PATH.write_text(json.dumps(document, indent=2, ensure_ascii=False) + '\n')
print('Spindle Lane v4:', len(assets), 'placements')
