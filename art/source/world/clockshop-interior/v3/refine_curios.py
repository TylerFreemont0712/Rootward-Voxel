"""Second pass on the clockmaker's furniture (2026-11-05): mouldings, framed doors, turned columns, brass fittings and
feet added to the saved masters. For each asset the retained v1 model is opened, new geometry is appended in its own
materials through the shared house kit (nothing existing is moved or removed), and the result is saved as
`<asset>/v2/model.blend` beside a provenance record. v1 stays beside it. The catalog selects v2.

    blender -b --python refine_curios.py -- [asset-id ...]      (default: every asset below; refuses to overwrite v2)
Front is Blender -Y, one unit is one metre."""
from pathlib import Path
import hashlib, json, math, sys
import bpy
ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / 'art/source/world/seaside-houses/v1'))
import house_kit as k


def open_master(asset):
    path = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(path))
    k.M.clear()
    k.M.update({m.name: m for m in bpy.data.materials})
    root = next(o for o in bpy.data.objects if o.type == 'EMPTY' and o.parent is None)
    return root, k.Parts(20261105), path


def save(asset, root, parts, source):
    out = ROOT / 'art/source/world' / asset / 'v2/model.blend'
    if out.exists():
        raise RuntimeError('v2 exists for ' + asset)
    parts.finish(root)
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and any(s in obj.name for s in ['brass', 'steel', 'ink', 'clear_glass', 'diagram']):
            obj['illustrated_edges'] = False
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(out))
    (out.parent / 'provenance.json').write_text(json.dumps({
        'record': 'art/source/world/clockshop-interior/v3/refine_curios.py', 'units': 'metres', 'front': 'Blender -Y',
        'previous': 'v1/model.blend', 'previous_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'source_sha256': hashlib.sha256(out.read_bytes()).hexdigest()}, indent=2) + '\n')
    print('refined', asset)


# --- primitives -------------------------------------------------------------------------------------------------
def box(p, m, at, size, bevel=.01, rot=(0, 0, 0)):
    p.box('clockshop_' + m, at, size, rot=rot, bevel=bevel)


def rod(p, m, a, b, r=.02, n=14, rb=None):
    p.cylinder('clockshop_' + m, a, b, r, sides=n, radius_b=rb)


def ball(p, m, at, r=.04, squash=(1, 1, 1)):
    p.sphere('clockshop_' + m, at, r, subdivisions=2, squash=squash)


def turned(p, m, x, y, z0, profile, n=14):
    z = z0
    for h, r0, r1 in profile:
        rod(p, m, (x, y, z), (x, y, z + h), r0, n, r1)
        z += h
    return z


def frame_front(p, m, x0, x1, z0, z1, y, width=.03, depth=.02, bevel=.006):
    box(p, m, ((x0 + x1) / 2, y, z0 + width / 2), (x1 - x0, depth, width), bevel)
    box(p, m, ((x0 + x1) / 2, y, z1 - width / 2), (x1 - x0, depth, width), bevel)
    box(p, m, (x0 + width / 2, y, (z0 + z1) / 2), (width, depth, z1 - z0 - 2 * width), bevel)
    box(p, m, (x1 - width / 2, y, (z0 + z1) / 2), (width, depth, z1 - z0 - 2 * width), bevel)


def dentils(p, m, x0, x1, y, z, count, size=(.035, .03, .035)):
    for i in range(count):
        box(p, m, (x0 + (x1 - x0) * (i + .5) / count, y, z), size, .004)


def feet(p, m, xs, ys, z, r=.035):
    for x in xs:
        for y in ys:
            ball(p, m, (x, y, z), r, (1, 1, .8))


def hinge(p, x, y, z, h=.12):
    box(p, 'brass', (x, y, z), (.04, .008, h), .003)
    rod(p, 'brass', (x, y + .003, z - h / 2 - .01), (x, y - .008, z - h / 2 - .01), .011, 10)


def escutcheon(p, x, y, z):
    rod(p, 'brass', (x, y + .002, z), (x, y - .012, z), .02, 14)
    box(p, 'ink', (x, y - .0125, z - .004), (.007, .004, .028), 0)


def cornice(p, m, cx, cy, z, w, d, layers=((1, 1, .045), (.94, .94, .035))):
    for scale_w, scale_d, h in layers:
        box(p, m, (cx, cy, z + h / 2), (w * scale_w, d * scale_d, h), .01)
        z += h


# --- assets ---------------------------------------------------------------------------------------------------
def longcase(p):
    box(p, 'walnut', (0, -.02, .30), (1.04, .70, .05), .012)
    box(p, 'walnut', (0, -.02, .345), (.98, .66, .04), .012)
    box(p, 'darkwood', (0, -.34, .17), (.62, .02, .20), .006)
    box(p, 'brass', (0, -.355, .17), (.05, .008, .05), .004)
    box(p, 'walnut', (0, -.02, 2.27), (.92, .70, .045), .012)
    box(p, 'walnut', (0, -.02, 2.315), (.87, .66, .03), .01)
    frame_front(p, 'darkwood', -.27, .27, .62, 2.20, -.32, .045, .028, .008)
    for z in (.95, 1.9):
        hinge(p, -.255, -.345, z, .13)
    escutcheon(p, .215, -.34, 1.40)
    ball(p, 'brass', (.215, -.36, 1.50), .02)
    for x in (-.355, .355):
        turned(p, 'walnut', x, -.325, 2.36, [(.04, .05, .045), (.65, .035, .035), (.05, .045, .05)], 16)
        rod(p, 'brass', (x, -.325, 2.36), (x, -.325, 2.40), .052, 16)
        rod(p, 'brass', (x, -.325, 3.06), (x, -.325, 3.10), .052, 16)
    box(p, 'walnut', (0, -.02, 3.19), (.94, .74, .05), .012)
    box(p, 'walnut', (0, -.02, 3.235), (.88, .70, .035), .01)
    dentils(p, 'brass', -.40, .40, -.375, 3.16, 11)
    box(p, 'walnut', (0, -.03, 3.30), (.74, .62, .05), .01)
    for x in (-.30, .30):
        rod(p, 'brass', (x, -.27, 3.325), (x, -.27, 3.40), .02, 12, .012)
        ball(p, 'brass', (x, -.27, 3.44), .04)
    rod(p, 'brass', (0, -.1, 3.325), (0, -.1, 3.55), .02, 12, .01)
    ball(p, 'brass', (0, -.1, 3.60), .055)
    rod(p, 'brass', (0, -.1, 3.65), (0, -.1, 3.72), .012, 10, .004)


def regulator(p):
    box(p, 'walnut', (0, 0, .30), (.86, .40, .04), .01)
    box(p, 'walnut', (0, 0, .335), (.80, .36, .03), .01)
    frame_front(p, 'darkwood', -.25, .25, .38, 1.21, -.205, .035, .02, .006)
    hinge(p, -.245, -.215, .55, .1)
    hinge(p, -.245, -.215, 1.05, .1)
    escutcheon(p, .2, -.213, .78)
    cornice(p, 'walnut', 0, 0, 1.935, .90, .40)
    dentils(p, 'brass', -.38, .38, -.215, 1.93, 9, (.03, .025, .03))
    for x in (-.31, .31):
        turned(p, 'walnut', x, -.17, 1.30, [(.03, .035, .03), (.45, .022, .022), (.03, .03, .035)], 14)
    rod(p, 'brass', (0, -.02, 1.99), (0, -.02, 2.12), .016, 12, .008)
    ball(p, 'brass', (0, -.02, 2.16), .045)
    feet(p, 'brass', (-.34, .34), (-.12, .12), .24)


def mantel_clock(p):
    feet(p, 'brass', (-.30, .30), (-.07, .17), .02, .035)
    box(p, 'darkwood', (0, .06, .095), (.74, .38, .03), .008)
    box(p, 'walnut', (0, .06, .13), (.68, .34, .03), .008)
    for x in (-.335, .335):
        rod(p, 'brass', (x, .06, .52), (x + (.03 if x > 0 else -.03), .06, .52), .012, 10)
        ball(p, 'brass', (x + (.05 if x > 0 else -.05), .06, .52), .028)
    rod(p, 'brass', (0, .06, .89), (0, .06, .93), .02, 12, .01)
    ball(p, 'brass', (0, .06, .96), .035)
    box(p, 'brass', (0, -.095, .105), (.22, .008, .035), .003)
    for x in (-.17, .17):
        rod(p, 'brass', (x, -.10, .20), (x, -.10, .70), .008, 8)


def display_counter(p):
    box(p, 'darkwood', (0, 0, .03), (3.14, 1.10, .06), .01)
    for x in (-.92, 0, .92):
        frame_front(p, 'walnut', x - .40, x + .40, .26, .79, -.535, .035, .02, .006)
    box(p, 'walnut', (0, 0, .835), (3.10, 1.06, .03), .01)
    for x in (-1.2, 1.2):
        box(p, 'brass', (x, -.545, .84), (.14, .008, .06), .004)
    box(p, 'brass', (0, -.545, .84), (.48, .008, .05), .004)
    feet(p, 'brass', (-1.45, 1.45), (-.45, .45), .075, .04)
    for x in (-.46, .46):
        rod(p, 'brass', (x, -.545, .50), (x, -.555, .50), .026, 14)


def repair_bench(p):
    box(p, 'walnut', (0, 0, .30), (2.80, .78, .045), .01)           # lower shelf
    for x in (-1.40, 1.40):
        box(p, 'walnut', (x, 0, .45), (.05, .78, .05), .008)       # end stretchers
    box(p, 'walnut', (0, -.50, .82), (3.06, .05, .05), .01)        # apron rail
    box(p, 'darkwood', (-.55, -.02, .355), (.50, .30, .09), .008)  # tool box on the shelf
    box(p, 'brass', (-.55, -.18, .385), (.10, .01, .035), .004)
    box(p, 'brass', (-.55, -.02, .405), (.52, .32, .006), .002)
    for x in (-1.0, 0.0, 1.0):
        rod(p, 'brass', (x, -.535, .70), (x, -.56, .70), .022, 12)  # drawer pulls
    ball(p, 'brass', (1.25, -.45, .94), .03)                         # bench stop knob


def parts_cabinet(p):
    cornice(p, 'walnut', 0, 0, 2.38, 2.30, .84, ((1, 1, .05), (.95, .93, .04), (.9, .88, .03)))
    dentils(p, 'brass', -1.0, 1.0, -.43, 2.40, 21, (.03, .025, .03))
    box(p, 'darkwood', (0, 0, .09), (2.24, .80, .10), .01)
    for x in (-.54, 0, .54):
        box(p, 'walnut', (x, -.405, 1.25), (.035, .025, 1.80), .006)
    for x in (-.98, .98):
        box(p, 'walnut', (x, -.405, 1.25), (.05, .03, 1.95), .006)
    for x in (-.95, .95):
        ball(p, 'brass', (x, 0, 2.52), .045)
        rod(p, 'brass', (x, 0, 2.45), (x, 0, 2.50), .02, 12)
    feet(p, 'brass', (-1.0, 1.0), (-.33, .33), .03, .045)


def wall_shelf(p):
    box(p, 'walnut', (0, -.265, .135), (1.96, .03, .04), .008)       # front lip
    box(p, 'walnut', (0, .24, .16), (1.96, .03, .09), .008)           # back rail
    for x in (-.80, 0, .80):
        box(p, 'walnut', (x, -.02, -.04), (.07, .36, .08), .008)       # corbel top
        box(p, 'walnut', (x, -.17, -.17), (.07, .06, .30), .008)       # corbel front
        box(p, 'walnut', (x, .02, -.20), (.07, .06, .24), .008, rot=(math.radians(35), 0, 0))
        ball(p, 'brass', (x, -.215, -.34), .035)
    for x in (-.95, .95):
        ball(p, 'brass', (x, -.265, .135), .028)


def watch_cabinet(p):
    cornice(p, 'walnut', 0, 0, 2.53, 2.02, .66, ((1, 1, .05), (.94, .93, .04)))
    dentils(p, 'brass', -.9, .9, -.345, 2.545, 19, (.03, .025, .03))
    box(p, 'darkwood', (0, 0, .09), (2.00, .66, .09), .01)
    for x in (-.93, .93):
        turned(p, 'walnut', x, -.325, .35, [(.04, .05, .04), (1.7, .03, .03), (.04, .04, .05)], 14)
        ball(p, 'brass', (x, -.325, 2.15), .04)
    box(p, 'brass', (0, -.335, 2.40), (.9, .006, .06), .003)
    feet(p, 'brass', (-.92, .92), (-.26, .26), .03, .04)
    for z in (1.07, 1.65):
        box(p, 'brass', (0, -.34, z), (1.76, .008, .02), .003)


ASSETS = {'clockshop-longcase': longcase, 'clockshop-regulator': regulator, 'clockshop-mantel-clock': mantel_clock,
          'clockshop-display-counter': display_counter, 'clockshop-repair-bench': repair_bench,
          'clockshop-parts-cabinet': parts_cabinet, 'clockshop-wall-shelf': wall_shelf,
          'clockshop-watch-cabinet': watch_cabinet}

if __name__ == '__main__':
    wanted = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else list(ASSETS)
    for asset in wanted or list(ASSETS):
        root, parts, source = open_master(asset)
        ASSETS[asset](parts)
        save(asset, root, parts, source)
