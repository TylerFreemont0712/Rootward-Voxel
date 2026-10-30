"""Isolated checkout for dev-menu lifecycle review; never changes a real catalog or source."""
import json
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
directory = Path(sys.argv[1]).resolve()
if not directory.is_relative_to(ROOT / '.cache'):
    raise SystemExit('Review fixtures must stay under this project’s .cache/.')
directory.mkdir(parents=True, exist_ok=False)
(directory / 'pipeline/reviews').mkdir(parents=True)
(directory / 'project.godot').write_text('; isolated development review checkout\n')
shutil.copy2(ROOT / 'pipeline/asset_workflow.py', directory / 'pipeline/asset_workflow.py')
catalog = json.loads((ROOT / 'pipeline/world-catalog.json').read_text())
for asset_id in ['robot-wick', 'review-candidate']:
    entry = dict(catalog['assets']['robot-wick'])
    for key in ['source', 'runtime']:
        original = ROOT / entry[key]
        if asset_id == 'review-candidate':
            entry[key] = entry[key].replace('robot-wick', asset_id)
        destination = directory / entry[key]
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(original, destination)
    manifest = json.loads((ROOT / 'assets/world/robot-wick/manifest.json').read_text())
    manifest.update(asset=asset_id, source=entry['source'], runtime=entry['runtime'])
    (directory / entry['runtime']).with_name('manifest.json').write_text(json.dumps(manifest))
    if asset_id == 'review-candidate':
        entry['label'] = 'Unused review candidate'
        catalog['assets'][asset_id] = entry
(directory / 'pipeline/world-catalog.json').write_text(json.dumps(catalog, indent=2))
(directory / 'pipeline/reviews/fixture-review.md').write_text('Isolated fixture for testing the finished queue; not a production art review.\n')
(directory / 'content/areas').mkdir(parents=True)
(directory / 'content/areas/fixture.json').write_text(json.dumps({'asset': 'robot-wick'}))
print(directory)
