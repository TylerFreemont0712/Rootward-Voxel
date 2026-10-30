"""One-time authoring of the furnishings for the loft's new space (the loft grew to 14 by 12 on 2026-10-28):
a wardrobe, a window seat under the front street window, a rocking chair with a knitting basket, and a tall potted
plant. They use the loft's own helpers, palette and painted surfaces.

Existing Blender masters are never rewritten; after creation, each model.blend is the authority. Origins are the
ground centre; fronts face logical -y.
"""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
from mathutils import Matrix

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('loft_author', HERE / 'author.py')
loft = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loft)
box, cylinder, sphere, torus, rod, curve, book, pot, pull = (loft.box, loft.cylinder, loft.sphere, loft.torus, loft.rod,
                                                               loft.curve, loft.book, loft.pot, loft.pull)


def wardrobe():
    for x in (-.52, .52):
        for y in (-.24, .24):
            box('Wardrobe bun foot', (x, y, .06), (.12, .12, .12), 'wood_dark', .03)
    box('Wardrobe plinth', (0, 0, .17), (1.2, .62, .12), 'wood_dark', .02)
    box('Wardrobe carcass', (0, .02, 1.1), (1.14, .56, 1.76), 'oak', .025)
    box('Wardrobe cornice', (0, 0, 2.02), (1.26, .66, .1), 'wood_dark', .03)
    box('Cornice moulding', (0, -.32, 1.95), (1.2, .04, .05), 'wood_edge', .01)
    # Left door shut; right door a hand's width ajar, a blue sleeve and a red scarf caught in it.
    box('Wardrobe left door', (-.285, -.27, 1.1), (.54, .05, 1.66), 'oak', .015)
    for z in (.62, 1.48):
        box('Door panel', (-.285, -.3, z), (.4, .02, .62), 'wood', .012)
    pull(-.06, -.31, 1.15, .1)
    door = box('Wardrobe right door', (.285, -.27, 1.1), (.54, .05, 1.66), 'oak', .015)
    door.location = (.555, -.27, 1.1)                     # hinged at its outer edge
    door.data.transform(Matrix.Translation((-.27, 0, 0)))
    door.rotation_euler.z = .42
    box('Dark wardrobe inside', (.28, -.22, 1.1), (.5, .02, 1.6), 'ink', 0)
    box('Hanging blue sleeve', (.12, -.3, 1.05), (.12, .1, .6), 'blue', .04, 3)
    curve('Red scarf caught in the door', [(.04, -.31, 1.35), (.06, -.36, 1.1), (.02, -.37, .85), (.05, -.35, .62)], .035, 'red')
    # On top: a round hat box and a small case.
    cylinder('Hat box', (-.28, .02, 2.2), .22, .26, 'teal', 24)
    cylinder('Hat box lid', (-.28, .02, 2.34), .23, .05, 'teal_dark', 24)
    torus('Hat box ribbon', (-.28, .02, 2.2), .225, .012, 'cream')
    box('Small case on the wardrobe', (.3, .02, 2.16), (.48, .3, .18), 'leather', .03)
    box('Case strap', (.3, -.13, 2.16), (.05, .02, .19), 'leather_dark', .005)


def window_seat():
    box('Seat chest', (0, 0, .22), (1.3, .52, .44), 'wood_dark', .02)
    for x in (-.38, .38):
        box('Chest front panel', (x, -.27, .22), (.5, .02, .3), 'oak', .012)
    box('Seat lid', (0, 0, .46), (1.34, .56, .05), 'oak', .015)
    box('Quilted seat cushion', (0, -.01, .55), (1.24, .5, .13), 'quilt', .05, 3)
    for x, colour, tilt in ((-.38, 'cream', .18), (.36, 'teal_light', -.14)):
        p = box('Leaning pillow', (x, .19, .78), (.44, .14, .36), colour, .07, 4)
        p.rotation_euler.x = -.25
        p.rotation_euler.y = tilt
    box('Folded plum blanket', (.12, -.05, .66), (.5, .34, .1), 'plum', .04, 3)
    book((-.46, -.08, .62), (.3, .22, .06), 'red', .2)
    book((-.47, -.08, .68), (.28, .2, .05), 'blue', -.1)
    cylinder('Tea mug on the books', (-.46, -.08, .78), .055, .1, 'ceramic', 14)
    torus('Mug handle', (-.4, -.08, .78), .03, .009, 'ceramic', (math.pi / 2, 0, 0))


def rocking_chair():
    for x in (-.27, .27):
        curve('Curved rocker', [(x, -.42, .1), (x, -.18, .02), (x, .18, .02), (x, .42, .12)], .025, 'wood_dark')
        for y in (-.2, .2):
            rod('Chair leg', (x, y, .04), (x * .95, y * .95, .42), .028, 'oak')
        rod('Arm support', (x, -.2, .42), (x, -.24, .66), .022, 'oak')
        box('Chair arm', (x, -.02, .67), (.07, .5, .04), 'oak', .015)
    box('Chair seat', (0, -.02, .44), (.58, .52, .06), 'oak', .02)
    box('Seat cushion', (0, -.03, .5), (.5, .46, .07), 'red', .03, 3)
    for x in (-.25, .25):
        rod('Back post', (x, .22, .44), (x, .3, 1.15), .025, 'wood_dark')
    for i in range(5):
        x = -.18 + i * .09
        rod('Back spindle', (x, .23, .5), (x, .29, 1.05), .012, 'oak')
    box('Back top rail', (0, .3, 1.12), (.56, .05, .08), 'wood_dark', .02)
    # A knitted throw over the back, in stripes.
    for i, colour in enumerate(('cream', 'teal', 'cream', 'ochre', 'cream')):
        p = box('Knitted throw stripe', (0, .2 - i * .02, 1.06 - i * .11), (.6, .06, .11), colour, .025)
        p.rotation_euler.x = .18
    # The knitting basket beside it, needles in a ball.
    cylinder('Knitting basket', (.55, -.2, .14), .17, .28, 'ochre', 18, .2)
    torus('Basket rim', (.55, -.2, .28), .19, .02, 'wood_edge')
    for dx, dy, colour in ((-.05, .03, 'teal'), (.06, -.04, 'red'), (.0, .08, 'cream')):
        sphere('Ball of wool', (.55 + dx, -.2 + dy, .32), (.08, .08, .07), colour)
    for a in (.4, .9):
        rod('Knitting needle', (.55, -.2, .32), (.55 + math.cos(a) * .25, -.2 + math.sin(a) * .1, .5), .006, 'brass')


def floor_plant():
    cylinder('Big terracotta pot', (0, 0, .2), .2, .4, 'ochre', 20, .25)
    torus('Pot rim', (0, 0, .4), .25, .03, 'ceramic')
    cylinder('Potting soil', (0, 0, .405), .22, .02, 'soil', 20)
    for k in range(11):
        a = k * 2.4
        height = .65 + (k % 4) * .18
        end = (math.cos(a) * .28, math.sin(a) * .24, .4 + height)
        rod('Plant stem', (0, 0, .41), end, .012, 'leaf_dark')
        leaf = sphere('Broad leaf', end, (.2, .07, .09), ['leaf', 'leaf_light', 'leaf'][k % 3], 12, 6)
        leaf.rotation_euler = (0, -.5, a)


assets = {'loft-wardrobe': wardrobe, 'loft-window-seat': window_seat, 'loft-rocking-chair': rocking_chair, 'loft-floor-plant': floor_plant}
for name in assets:
    if (ROOT / 'art/source/world' / name / 'v1/model.blend').exists():
        raise RuntimeError('Existing editable master; refusing to overwrite ' + name)
for name, make in assets.items():
    loft.start(name)
    make()
    loft.save(name)
    provenance = ROOT / 'art/source/world' / name / 'v1/provenance.json'
    record = json.loads(provenance.read_text())
    record['date'] = '2026-10-28'
    record['authoring_record'] = 'art/source/world/sparks-loft/v1/flipped_loft_props.py'
    record['authoring_record_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    provenance.write_text(json.dumps(record, indent=2) + '\n')
