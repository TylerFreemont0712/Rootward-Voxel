"""Paints the lane's tiling ground pictures and the salmon plaster, deterministically, with Blender's numpy.

Run once: blender -b --python textures.py. It refuses to overwrite an existing picture; delete one deliberately to
repaint it. Pictures are sRGB PNGs that tile seamlessly; author.py packs them into the editable masters.
"""
from pathlib import Path
import math
import numpy as np
import bpy

HERE = Path(__file__).resolve().parent
LOFT = HERE.parents[1] / 'sparks-loft/v1'


def tile_noise(size, cells, seed):
    """Smooth value noise that wraps at the picture's edges."""
    rng = np.random.default_rng(seed)
    lattice = rng.random((cells, cells))
    t = np.arange(size) / size * cells
    i0 = np.floor(t).astype(int) % cells
    i1 = (i0 + 1) % cells
    f = t - np.floor(t)
    f = f * f * (3 - 2 * f)
    rows = lattice[i0][:, i0] * (1 - f)[None, :] + lattice[i0][:, i1] * f[None, :]
    rows1 = lattice[i1][:, i0] * (1 - f)[None, :] + lattice[i1][:, i1] * f[None, :]
    return rows * (1 - f)[:, None] + rows1 * f[:, None]


def fbm(size, seed, octaves=((4, .5), (8, .28), (16, .14), (32, .08))):
    total = sum(w for _, w in octaves)
    return sum(tile_noise(size, c, seed + k) * w for k, (c, w) in enumerate(octaves)) / total


def save(name, rgb):
    path = HERE / (name + '.png')
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


def masonry(size, seed, courses, per_course, gap, radius, palette, grout, outline, jitter=.05):
    """Rounded stones laid in courses. `per_course` is a (low, high) stone count per course; every course wraps."""
    rng = np.random.default_rng(seed)
    out = np.zeros((size, size, 3))
    noise = fbm(size, seed + 100)
    fine = tile_noise(size, 64, seed + 200)
    ys, xs = np.mgrid[0:size, 0:size].astype(float)
    heights = rng.uniform(.8, 1.2, courses)
    heights = heights / heights.sum() * size
    top = 0.0
    for course, ch in enumerate(heights):
        y0, y1 = int(round(top)), int(round(top + ch))
        top += ch
        count = int(rng.integers(per_course[0], per_course[1] + 1))
        widths = rng.uniform(.75, 1.25, count)
        widths = widths / widths.sum() * size
        shift = rng.uniform(0, size)
        edges = np.concatenate([[0], np.cumsum(widths)])
        band = slice(y0, y1)
        u = (xs[band] + shift) % size
        v = ys[band] - y0
        index = np.searchsorted(edges, u, side='right') - 1
        index = np.clip(index, 0, count - 1)
        left = edges[index]
        width = widths[index]
        lu = u - left - width / 2
        lv = v - (y1 - y0) / 2
        hx = width / 2 - gap
        hy = (y1 - y0) / 2 - gap
        r = np.minimum(radius, np.minimum(hx, hy) * .9)
        qx = np.abs(lu) - hx + r
        qy = np.abs(lv) - hy + r
        d = np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r
        tones = rng.integers(0, len(palette), count)
        base = np.array(palette)[tones[index]]
        base = base * (1 + rng.uniform(-jitter, jitter, (count, 1))[index])
        rim = np.clip(-d / (r * 1.4 + 1e-6), 0, 1)
        light = np.clip((-lu / (hx + 1e-6) - lv / (hy + 1e-6)) * .5, -1, 1)
        stone = base * (0.86 + 0.14 * rim[..., None]) * (1 + 0.07 * light[..., None] * (1 - rim[..., None]))
        stone = stone * (0.92 + 0.16 * noise[band][..., None]) * (0.97 + 0.06 * fine[band][..., None])
        g = np.array(grout) * (0.85 + 0.3 * noise[band][..., None])
        edge = np.clip((d + 3.0) / 3.0, 0, 1)[..., None]
        line = np.array(outline)
        inside = (d < 0)[..., None]
        out[band] = np.where(inside, stone * (1 - edge) + line * edge, g)
    return out


def grass(size, seed):
    rng = np.random.default_rng(seed)
    noise = fbm(size, seed)
    base = np.array([.44, .60, .29])
    out = base * (0.82 + 0.36 * noise[..., None])
    tones = [np.array(c) for c in ([.36, .52, .24], [.55, .70, .33], [.62, .76, .38], [.30, .45, .22])]
    for _ in range(5200):
        cx, cy = rng.uniform(0, size, 2)
        length = rng.uniform(7, 15)
        lean = rng.uniform(-.5, .5)
        tone = tones[rng.integers(0, len(tones))]
        for step in range(int(length)):
            x = int(cx + lean * step) % size
            y = int(cy - step) % size
            fade = 1 - step / length
            for dx in (0, 1):
                xx = (x + dx) % size
                out[y, xx] = out[y, xx] * (1 - .55 * fade) + tone * .55 * fade
    for _ in range(140):
        cx, cy = rng.integers(0, size, 2)
        petal = [np.array([.97, .95, .88]), np.array([.96, .84, .40])][rng.integers(0, 2)]
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            out[(cy + dy) % size, (cx + dx) % size] = petal
    return out


def tinted_plaster(tint=(1.0, 0.80, 0.70)):
    source = bpy.data.images.load(str(LOFT / 'cream-plaster.png'))
    w, h = source.size
    rgb = np.array(source.pixels[:]).reshape(h, w, 4)[::-1, :, :3]
    return rgb * np.array(tint)


LUSH_GRASS = HERE.parents[4] / 'assets/world/textures/lush/grass.png'


def lush_grass(size=1024, seed=2813):
    """The project's lush grass picture (Kindle Hollow's ground), borrowed at its own density of 32 art pixels per
    cell and laid out over 8 by 8 cells without repeating: each art pixel samples the source through a slow wrapped
    warp, then the field takes the ground's light and dark grass tints as broad patches, with a few daisies."""
    source = bpy.data.images.load(str(LUSH_GRASS))
    w, h = source.size
    src = np.array(source.pixels[:]).reshape(h, w, 4)[::-1, :, :3]
    art = 4                                   # source pixels per art pixel (128 px = 32 art pixels per cell)
    cells = w // art
    grid = size // art                        # 256 art pixels over 8 cells
    warp_x = (fbm(grid, seed, ((2, .6), (4, .3), (8, .1))) - .5) * 26
    warp_y = (fbm(grid, seed + 50, ((2, .6), (4, .3), (8, .1))) - .5) * 26
    jy, jx = np.mgrid[0:grid, 0:grid]
    sx = (jx + np.round(warp_x).astype(int)) % cells
    sy = (jy + np.round(warp_y).astype(int)) % cells
    pixels = src[sy * art + art // 2, sx * art + art // 2]
    patches = fbm(grid, seed + 90, ((3, .55), (6, .3), (12, .15)))
    tint = 0.84 + 0.30 * np.clip((patches - .5) * 1.8 + .5, 0, 1)
    warm = np.stack([1 + .05 * (patches - .5), np.ones_like(patches), 1 - .06 * (patches - .5)], axis=2)
    pixels = pixels * tint[..., None] * warm
    rng = np.random.default_rng(seed)
    for _ in range(150):
        cy, cx = rng.integers(0, grid, 2)
        pixels[cy, cx] = [np.array([.96, .94, .86]), np.array([.95, .84, .40])][rng.integers(0, 2)]
    return np.repeat(np.repeat(pixels, art, axis=0), art, axis=1)


def glass(size, kind):
    """One whole pane. 'home': sky in the glass and cream curtains drawn back; 'shop': a warm room of shelves
    behind the reflection; 'tram': the reflection over varnished seat backs."""
    ys, xs = np.mgrid[0:size, 0:size].astype(float) / size        # ys 0 at the top
    sky = np.array([.62, .77, .80])
    deep = np.array([.19, .31, .35])
    out = sky * (1 - ys[..., None]) ** 1.4 + deep * (1 - (1 - ys[..., None]) ** 1.4)
    if kind == 'shop':
        glow = np.exp(-(((xs - .5) / .45) ** 2 + ((ys - .55) / .5) ** 2))
        out = np.array([.42, .27, .16]) * (1 - glow[..., None]) + np.array([.93, .72, .42]) * glow[..., None]
        for shelf in (.36, .68):
            band = np.abs(ys - shelf) < .022
            out[band] = np.array([.30, .19, .12])
            for k in range(7):
                cx = .1 + k * .13 + .02 * math.sin(k * 3.1)
                r = .035 + .015 * (k % 3)
                jar = ((xs - cx) / r) ** 2 + ((ys - (shelf - r * 1.1)) / (r * 1.25)) ** 2 < 1
                out[jar] = [np.array([.52, .38, .22]), np.array([.66, .55, .30]), np.array([.36, .44, .40])][k % 3]
    if kind == 'tram':
        seats = (ys > .62) & (np.abs(((xs * 3) % 1) - .5) < .38)
        out[seats] = out[seats] * .35 + np.array([.55, .36, .20]) * .65
    # Two light streaks across the glass, then the frame's soft inner shadow.
    streak = xs + ys * .85
    for centre, width, strength in ((.55, .09, .28), (.78, .035, .22)):
        out = out + strength * np.exp(-((streak - centre) / width) ** 2)[..., None] * (.5 if kind == 'shop' else 1)
    if kind == 'home':
        for side in (0, 1):
            edge = xs if side == 0 else 1 - xs
            reach = np.minimum(.2, .07 + .22 * np.abs(ys - .58))   # gathered at a tie, fuller above and below
            cloth = edge < reach
            folds = .9 + .1 * np.sin(edge * 90)
            out[cloth] = (np.array([.93, .89, .80]) * folds[..., None])[cloth]
    border = np.minimum(np.minimum(xs, 1 - xs), np.minimum(ys, 1 - ys))
    out = out * (.72 + .28 * np.clip(border / .07, 0, 1))[..., None]
    return out


if __name__ == '__main__':
    save('lane-cobbles', masonry(1024, 2810, 12, (8, 10), 4.5, 16, [[.78, .70, .57], [.74, .65, .52], [.82, .75, .62], [.70, .63, .53], [.77, .67, .51]], [.40, .33, .26], [.42, .33, .25]))
    save('lane-flags', masonry(1024, 2811, 6, (3, 5), 4.0, 9, [[.80, .75, .64], [.76, .71, .61], [.84, .79, .68], [.73, .69, .60]], [.48, .42, .35], [.50, .42, .33], jitter=.03))
    save('lane-grass', grass(1024, 2812))
    save('salmon-plaster', tinted_plaster())
    # Second pass after the 2026-10-28 review: the borrowed lush grass, dressed limestone, glass with a picture in it.
    save('lane-grass-lush', lush_grass())
    save('lane-ashlar', masonry(1024, 2814, 8, (4, 5), 3.5, 7, [[.86, .80, .68], [.83, .77, .65], [.89, .84, .72], [.80, .74, .63], [.85, .78, .64]], [.62, .56, .47], [.60, .53, .43], jitter=.025))
    save('lane-glass', glass(256, 'home'))
    save('lane-glass-shop', glass(256, 'shop'))
    save('lane-glass-tram', glass(256, 'tram'))
