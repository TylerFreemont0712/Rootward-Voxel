"""One-time authoring of workshop-jar-shelf: open wall shelving of jars and parts for the party wall, where the
north window used to be. Refuses an existing master; afterwards model.blend is the authority.

Origin at the wall's foot, centred; the shelves stand out from the wall toward logical -y.
"""
import hashlib
import importlib.util
import json
import math
import random
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ASSET = 'workshop-jar-shelf'
if (ROOT / 'art/source/world' / ASSET / 'v1/model.blend').exists():
    raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + ASSET)
spec = importlib.util.spec_from_file_location('workshop_author', HERE / 'author.py')
w = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w)
h = w.h
RNG = random.Random(2811)


def jar(x, y, z, r, height, fill, lid='brass'):
    h.cylinder('Jar contents', (x, y, z + height * .42), r * .92, height * .78, fill, 14)
    h.cylinder('Jar glass shoulder', (x, y, z + height * .86), r * .96, height * .12, 'glass', 14, r * .7)
    h.cylinder('Jar lid', (x, y, z + height * .97), r * .72, height * .08, lid, 14)
    h.box('Jar label', (x, y - r * .93, z + height * .45), (r * 1.1, .006, height * .3), 'paper', .002)


def shelf():
    width, depth = 1.7, .34
    levels = (1.2, 1.78, 2.36)
    for x in (-width / 2 + .05, width / 2 - .05):
        w.wood('Shelf upright', (x, -depth / 2, 1.82), (.07, depth, 1.36), 'wood_dark', .015)
    for z in levels:
        w.wood('Jar shelf board', (0, -depth / 2, z), (width, depth, .05), 'oak', .012)
        w.wood('Shelf lip', (0, -depth + .012, z + .035), (width - .1, .025, .04), 'wood', .006)
        for x in (-.55, .55):
            h.rod('Iron shelf bracket', (x, -.02, z - .22), (x, -depth + .05, z - .03), .014, 'steel_dark')
    w.wood('Shelf back rail', (0, -.02, 2.55), (width, .04, .08), 'wood_dark', .01)
    # Bottom shelf: big jars of screws, washers and springs, a tin of rivets.
    for i, (x, fill) in enumerate(((-.66, 'brass'), (-.36, 'steel_light'), (-.06, 'ochre'), (.26, 'steel'))):
        jar(x, -.17, 1.225, .1, .3, fill)
    h.cylinder('Rivet tin', (.58, -.17, 1.3), .12, .14, 'teal_dark', 16)
    h.cylinder('Rivet tin lid', (.58, -.17, 1.38), .125, .025, 'teal', 16)
    # Middle shelf: small jars in a row, a coil of copper wire, a brass gear on its edge.
    for i in range(5):
        jar(-.72 + i * .17, -.16, 1.805, .065, .2, ['red', 'teal_light', 'brass', 'blue_light', 'ochre'][i], 'wood_dark')
    h.torus('Copper wire coil', (.22, -.16, 1.86), .1, .025, 'red', (math.pi / 2, 0, 0))
    h.torus('Copper wire coil', (.22, -.16, 1.89), .095, .022, 'red', (math.pi / 2, 0, .2))
    w.gear((.55, -.17, 1.97), .12, 10)
    # Top shelf: labelled boxes, a stack of manuals, an enamel hand waiting for an automaton.
    for i, (x, colour) in enumerate(((-.62, 'cream'), (-.32, 'teal'), (-.05, 'plum'))):
        h.box('Labelled parts box', (x, -.17, 2.45), (.26, .26, .15 + .03 * i), colour, .02)
        h.box('Box label', (x, -.302, 2.45), (.14, .006, .06), 'paper', .002)
    h.book((.33, -.17, 2.385), (.36, .26, .06), 'blue', .05)
    h.book((.33, -.17, 2.445), (.34, .25, .055), 'red', -.06)
    h.box('Enamel hand palm', (.62, -.17, 2.43), (.13, .06, .11), 'cream', .03)
    for i in range(4):
        h.box('Enamel finger', (.57 + i * .033, -.17, 2.53), (.026, .05, .1), 'cream', .012)


w.start(ASSET)
shelf()
w.save(ASSET)
provenance = ROOT / 'art/source/world' / ASSET / 'v1/provenance.json'
record = json.loads(provenance.read_text())
record.update(date='2026-10-28', record=str(Path(__file__).relative_to(ROOT)), record_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              purpose="Jars and parts on the party wall with Nell's house, where the north window was.")
provenance.write_text(json.dumps(record, indent=2) + '\n')
