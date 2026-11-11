"""Paints Haverlund's town ground pictures for build-mode paint, deterministically, with Blender's numpy.

They are drawn by the same masonry and noise routines as the lane and square's own paving
(art/source/world/sparks-lane/v1/textures.py), so painted ground sits with the authored ground:
  * town_flags and town_cobbles are the square's own limestone flags and sandstone cobbles, copied unchanged;
  * town_setts (large granite setts), town_brick (running-bond brick paving), town_gravel (warm hoggin gravel)
    and town_bed (planting-bed soil with leaf litter and sprigs) are new, in the same palette and hand.
Lawn uses the existing `grass` picture, which is the square's lawn picture at its own density.

Run once: blender -b --factory-startup --python paint.py. It refuses to overwrite a native picture.
"""
from pathlib import Path
import hashlib, importlib.util, json, shutil, sys
import numpy as np
import bpy

HERE = Path(__file__).resolve().parent
NATIVE = HERE / 'native'
LANE = HERE.parents[1] / 'sparks-lane/v1'
spec = importlib.util.spec_from_file_location('lane_textures', LANE / 'textures.py')
lane = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lane)


def save(name, rgb):
    path = NATIVE / (name + '.png')
    if path.exists():
        print('KEEP', path.name)
        return
    h, w, _ = rgb.shape
    rgba = np.concatenate([np.clip(rgb, 0, 1), np.ones((h, w, 1))], axis=2).astype(np.float32)
    image = bpy.data.images.new(name, w, h, alpha=False)
    image.pixels = rgba[::-1].ravel()
    image.filepath_raw = str(path)
    image.file_format = 'PNG'
    image.save()
    print('PAINTED', path.name)


def gravel(size, seed):
    """Warm hoggin: a fine sandy bed scattered with small rounded pebbles, each with a lit top and a dark foot."""
    rng = np.random.default_rng(seed)
    noise = lane.fbm(size, seed)
    fine = lane.tile_noise(size, 128, seed + 7)
    out = np.array([.70, .63, .52]) * (0.86 + 0.22 * noise[..., None]) * (0.94 + 0.12 * fine[..., None])
    tones = [np.array(c) for c in ([.78, .72, .62], [.62, .56, .48], [.70, .66, .60], [.56, .50, .42], [.82, .77, .67], [.66, .58, .46])]
    ys, xs = np.mgrid[-20:21, -20:21]
    for _ in range(1500):
        cx, cy = rng.integers(0, size, 2)
        rx, ry = rng.uniform(7.0, 16.0), rng.uniform(5.5, 12.0)
        tone = tones[rng.integers(0, len(tones))]
        d = (xs / rx) ** 2 + (ys / ry) ** 2
        mask = d < 1
        shade = np.clip(1.08 - 0.25 * (ys / ry) - 0.18 * d, .7, 1.12)
        yy = (cy + ys[mask]) % size
        xx = (cx + xs[mask]) % size
        out[yy, xx] = tone * shade[mask][:, None]
        foot = (d < 1.35) & (d >= 1) & (ys > 0)
        out[(cy + ys[foot]) % size, (cx + xs[foot]) % size] *= .78
    return out


def bed(size, seed):
    """A planting bed: dark crumbly soil, leaf litter and small green sprigs, edged by nothing (kerbs are drawn)."""
    rng = np.random.default_rng(seed)
    noise = lane.fbm(size, seed)
    fine = lane.tile_noise(size, 160, seed + 3)
    out = np.array([.33, .25, .19]) * (0.80 + 0.30 * noise[..., None]) * (0.88 + 0.22 * fine[..., None])
    crumbs = rng.integers(0, size, (9000, 2))
    for cy, cx in crumbs:
        out[cy, cx] = out[cy, cx] * rng.uniform(.75, 1.25)
    leaves = [np.array(c) for c in ([.52, .38, .20], [.60, .45, .24], [.44, .32, .18])]
    for _ in range(420):
        cx, cy = rng.integers(0, size, 2)
        r = rng.uniform(7.0, 13.0)
        tone = leaves[rng.integers(0, len(leaves))]
        for dy in range(-int(r), int(r) + 1):
            for dx in range(-int(r * 1.6), int(r * 1.6) + 1):
                if (dx / (r * 1.6)) ** 2 + (dy / r) ** 2 < 1:
                    out[(cy + dy) % size, (cx + dx) % size] = tone
    greens = [np.array(c) for c in ([.36, .55, .25], [.46, .64, .30], [.30, .47, .22])]
    for _ in range(260):
        cx, cy = rng.uniform(0, size, 2)
        tone = greens[rng.integers(0, len(greens))]
        for blade in range(rng.integers(4, 8)):
            lean = rng.uniform(-.8, .8)
            length = rng.uniform(16, 34)
            for step in range(int(length)):
                x = int(cx + lean * step) % size
                y = int(cy - step) % size
                for dx in range(4):
                    out[y, (x + dx) % size] = tone * (1 - .3 * step / length) * (1 - .08 * dx)
    return out


if __name__ == '__main__':
    NATIVE.mkdir(parents=True, exist_ok=True)
    for name, source in (('town_flags', 'lane-flags'), ('town_cobbles', 'lane-cobbles')):
        target = NATIVE / (name + '.png')
        if not target.exists():
            shutil.copyfile(LANE / (source + '.png'), target)
            print('COPIED', target.name)
    save('town_setts', lane.masonry(1024, 4101, 16, (14, 17), 3.5, 5, [[.56, .57, .59], [.50, .52, .55], [.61, .61, .61], [.47, .48, .51], [.58, .55, .52], [.53, .51, .49]], [.31, .30, .29], [.27, .26, .26], jitter=.06))
    save('town_brick', lane.masonry(1024, 4102, 14, (5, 6), 3.0, 3, [[.63, .34, .25], [.57, .30, .22], [.69, .41, .29], [.53, .32, .26], [.66, .37, .26], [.60, .36, .29]], [.56, .51, .45], [.38, .22, .17], jitter=.05))
    save('town_gravel', gravel(1024, 4103))
    save('town_bed', bed(1024, 4104))
    record = {name: hashlib.sha256((NATIVE / (name + '.png')).read_bytes()).hexdigest()
              for name in ('town_flags', 'town_cobbles', 'town_setts', 'town_brick', 'town_gravel', 'town_bed')}
    print('TOWN GROUND', json.dumps(record))
