"""One-time authoring of the first-morning note and hand terminal.

Existing Blender masters are never rewritten; after creation, each model.blend is the authority.
"""
import hashlib
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('loft_author', HERE / 'author.py')
loft = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loft)


def note():
    loft.box('Folded note', (0, 0, .008), (.46, .34, .016), 'paper', .004)
    loft.box('Folded corner', (.17, .115, .019), (.09, .07, .006), 'linen_shade', .003)
    for i in range(4):
        loft.box('Ink line %d' % i, (-.035, -.105+i*.055, .018), (.30-i*.025, .008, .002), 'wood_dark', 0)


def terminal():
    loft.box('Hand terminal enamel case', (0, 0, .035), (.36, .23, .07), 'teal_dark', .035, 3)
    loft.box('Glass screen bezel', (0, .025, .075), (.27, .135, .018), 'brass', .012)
    loft.box('Glass screen', (0, .025, .086), (.238, .107, .008), 'glass', .005)
    for i in range(3):
        loft.box('Screen line %d' % i, (-.035+i*.008, .058-i*.026, .091), (.14-i*.022, .006, .002), 'teal_light', .001)
    for x in (-.1, -.035, .03, .095):
        loft.sphere('Small ivory key', (x, -.082, .078), (.018, .016, .009), 'cream', 12, 6)
    loft.sphere('Brass indicator', (.143, .075, .074), (.013, .013, .008), 'brass', 12, 6)


assets = {'loft-note-slip': note, 'loft-hand-terminal': terminal}
for name in assets:
    if (ROOT / 'art/source/world' / name / 'v1/model.blend').exists():
        raise RuntimeError('Existing editable master; refusing to overwrite ' + name)
for name, make in assets.items():
    loft.start(name)
    make()
    loft.save(name)
    provenance = ROOT / 'art/source/world' / name / 'v1/provenance.json'
    record = json.loads(provenance.read_text())
    record['authoring_record'] = 'art/source/world/sparks-loft/v1/first_morning_props.py'
    record['authoring_record_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    provenance.write_text(json.dumps(record, indent=2) + '\n')
