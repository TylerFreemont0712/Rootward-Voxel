"""Places a town-power-pillar on Spindle Lane's surround walls wherever pillars_revision.py removed a carved pilaster,
in content/areas/haverlund-lane.json (the document is the master; this record runs once).

    python3 art/source/world/square-hub/v1/lane_pillars.py
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
path = ROOT / 'content/areas/haverlund-lane.json'
document = json.loads(path.read_text())
assets = document['interior']['assets']
if any(item['asset'] == 'town-power-pillar' for item in assets):
    raise SystemExit('Spindle Lane already has its power pillars; edit the document directly.')
for index, pillar in enumerate(json.loads((HERE / 'pillars-haverlund-lane-surround.json').read_text())):
    assets.append({'id': f'power-pillar-{index + 1}', 'asset': 'town-power-pillar', 'at': pillar['at'], 'turn': pillar['turn'],
                   'height': pillar['top'], 'scale': 1.0})
path.write_text(json.dumps(document, indent=2, ensure_ascii=False) + '\n')
print('Spindle Lane: placed', index + 1, 'power pillars')
