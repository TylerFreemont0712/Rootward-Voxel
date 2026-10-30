"""Compose Hotaru's robot portrait, expressions and concept sheets from recorded inputs.

Inputs: painted.png (the selected ComfyUI paint-over, see prompt.txt and paint-workflow.json),
concept/renders/*.png and portrait-base.json (rendered by concept/render_turnaround.py from
the robot's Blender source) and the approved boy's runtime sheet for scale.
Outputs: sprite.png (neutral portrait, the selected companion source), expressions/*.png,
concept/expression-sheet.png and concept/turnaround-sheet.png. Needs Pillow:
    /data/ComfyUI/.venv/bin/python art/source/companions/hotaru/v3/compose_portrait.py
"""
from pathlib import Path
import json
import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
RENDERS = HERE / 'concept/renders'
FONT = str(ROOT / 'ui/fonts/alegreya.ttf')
PAPER = (246, 240, 226, 255)
INK = (74, 58, 44, 255)
SPARK_CORE = (255, 248, 222)
SPARK_HALO = (255, 214, 120)
SS = 4  # supersampling for clean eye shapes

layout = json.loads((RENDERS / 'portrait-base.json').read_text())
size = tuple(layout['size'])
eyes = [tuple(e) for e in layout['eyes']]
eye_h = layout['eye_height_px']
eye_w = eye_h * .72
window = tuple(layout['window_centre'])
window_r = layout['window_radius_px']

# The painting keeps the render's silhouette: its alpha, grown by a hair and softened.
painted = Image.open(HERE / 'painted.png').convert('RGB')
alpha = Image.open(RENDERS / 'portrait-base.png').getchannel('A')
alpha = alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.2))
base = painted.convert('RGBA')
base.putalpha(alpha)


def glow_layer(draw_shapes):
    """Draw shapes at 4x, then add a warm halo and a bright core."""
    big = Image.new('L', (size[0] * SS, size[1] * SS), 0)
    draw_shapes(ImageDraw.Draw(big))
    core = big.resize(size, Image.LANCZOS)
    halo = core.filter(ImageFilter.GaussianBlur(9))
    layer = Image.new('RGBA', size, (0, 0, 0, 0))
    layer.paste(Image.new('RGBA', size, (*SPARK_HALO, 255)), mask=halo.point(lambda v: int(v * .75)))
    layer.alpha_composite(Image.composite(Image.new('RGBA', size, (*SPARK_CORE, 255)),
                                          Image.new('RGBA', size, (0, 0, 0, 0)), core))
    return layer


def scaled(points):
    return [(x * SS, y * SS) for x, y in points]


def oval(d, centre, w, h):
    x, y = centre
    d.ellipse(scaled([(x - w / 2, y - h / 2), (x + w / 2, y + h / 2)]), fill=255)


def arc(d, centre, w, h, width, start, end):
    x, y = centre
    d.arc(scaled([(x - w / 2, y - h / 2), (x + w / 2, y + h / 2)]), start, end, fill=255, width=int(width * SS))


def ring(d, centre, r, width):
    x, y = centre
    d.ellipse(scaled([(x - r, y - r), (x + r, y + r)]), outline=255, width=int(width * SS))


left, right = eyes
expressions = {
    'neutral': lambda d: [oval(d, e, eye_w, eye_h) for e in eyes],
    'happy': lambda d: [arc(d, (e[0], e[1] + eye_h * .18), eye_w * 1.25, eye_h * .9, eye_w * .32, 200, 340) for e in eyes],
    'thinking': lambda d: (oval(d, left, eye_w, eye_h), oval(d, (right[0], right[1] + eye_h * .12), eye_w * 1.1, eye_h * .32)),
    'surprised': lambda d: [ring(d, e, eye_h * .48, eye_w * .3) for e in eyes],
    'stopped': lambda d: [oval(d, (e[0], e[1] + eye_h * .32), eye_w * .78, eye_h * .5) for e in eyes],
}


def window_mask(scale=1.0, blur=3):
    mask = Image.new('L', size, 0)
    r = window_r * .86 * scale
    ImageDraw.Draw(mask).ellipse([(window[0] - r, window[1] - r), (window[0] + r, window[1] + r)], fill=255)
    return mask.filter(ImageFilter.GaussianBlur(blur))


def portrait(name):
    image = base.copy()
    if name == 'off':
        # No spark: the glass goes dark amber, with the painted highlights kept faintly.
        dark = Image.new('RGBA', size, (58, 38, 24, 255))
        dim = Image.blend(image, dark, .78)
        image = Image.composite(dim, image, window_mask())
        return image
    if name == 'stopped':
        # A stop dims the spark toward orange; motion adds the flicker in the game.
        warm = Image.new('RGBA', size, (214, 110, 40, 255))
        image = Image.composite(Image.blend(image, warm, .35), image, window_mask())
    layer = glow_layer(expressions[name])
    # Eyes stay inside the window glass.
    clip = window_mask(.98, 1)
    layer.putalpha(ImageChops.multiply(layer.getchannel('A'), clip))
    image.alpha_composite(layer)
    return image


ORDER = ['off', 'neutral', 'happy', 'thinking', 'surprised', 'stopped']
LABELS = {'off': 'Off', 'neutral': 'Neutral', 'happy': 'Happy', 'thinking': 'Thinking',
          'surprised': 'Surprised', 'stopped': 'Stopped (error)'}
(HERE / 'expressions').mkdir(exist_ok=True)
faces = {}
for name in ORDER:
    faces[name] = portrait(name)
    faces[name].save(HERE / 'expressions' / f'{name}.png')
faces['neutral'].save(HERE / 'sprite.png')


def label(draw, xy, text, size_px, fill=INK, anchor='la'):
    draw.text(xy, text, font=ImageFont.truetype(FONT, size_px), fill=fill, anchor=anchor)


# Expression sheet: six crops of the window and cap, plus the full neutral portrait.
crop = (int(window[0] - 290), int(window[1] - 560), int(window[0] + 420), int(window[1] + 300))
cw, ch = (crop[2] - crop[0]) // 2, (crop[3] - crop[1]) // 2
sheet = Image.new('RGBA', (60 + 3 * (cw + 30) + 420, 140 + 2 * (ch + 70)), PAPER)
d = ImageDraw.Draw(sheet)
label(d, (60, 40), 'Hotaru · spark-eye expressions', 46)
label(d, (60, 96), 'One painting; the spark in her window draws the eyes. Stage 0 uses Neutral in dialogue.', 24)
for i, name in enumerate(ORDER):
    x, y = 60 + (i % 3) * (cw + 30), 140 + (i // 3) * (ch + 70)
    sheet.alpha_composite(faces[name].crop(crop).resize((cw, ch), Image.LANCZOS), (x, y))
    label(d, (x + cw // 2, y + ch + 12), LABELS[name], 28, anchor='ma')
full = faces['neutral'].resize((380, int(380 * size[1] / size[0])), Image.LANCZOS)
sheet.alpha_composite(full, (sheet.width - 410, 150))
label(d, (sheet.width - 220, 150 + full.height + 12), 'Dialogue portrait', 28, anchor='ma')
sheet.convert('RGB').save(HERE / 'concept/expression-sheet.png')

# Turnaround sheet: following and working modes, five angles, and her size beside the boy.
views = [('front', 'Front'), ('front-34', 'Front ¾'), ('side', 'Side'), ('back-34', 'Back ¾'), ('back', 'Back')]
cell = 300
turn = Image.new('RGBA', (60 + 5 * cell + 480, 150 + 2 * (cell + 60)), PAPER)
d = ImageDraw.Draw(turn)
label(d, (60, 36), 'Hotaru · robot turnaround', 46)
label(d, (60, 92), 'Rendered from art/source/world/hotaru-robot/v1/model.blend. Cream enamel, teal cap and bands, brass, one spark window.', 22)
for row, (mode, title) in enumerate([('following', 'Following — rotor up, legs folded'),
                                      ('working', 'Working — legs out, on the grid (later stage)')]):
    y = 150 + row * (cell + 60)
    label(d, (60, y - 4), title, 26)
    for col, (view, name) in enumerate(views):
        im = Image.open(RENDERS / f'{mode}-{view}.png').resize((cell, cell), Image.LANCZOS)
        turn.alpha_composite(im, (60 + col * cell, y + 24))
        label(d, (60 + col * cell + cell // 2, y + cell + 18), name, 22, anchor='ma')
# Scale panel: one metre per cell. The boy's frame is 1.45 m tall; renders span 0.46 m.
boy_sheet = Image.open(ROOT / 'assets/characters/adventurer/sheet.png').convert('RGBA')
# Frame 8 of the 4-column template grid is the south-east idle pose (row 2, column 0).
boy = boy_sheet.crop((0, 2 * 448, 384, 3 * 448))
boy_px = 380
px_per_m = boy_px / 1.45
boy = boy.resize((int(384 * boy_px / 448), boy_px), Image.LANCZOS)
robot = Image.open(RENDERS / 'following-front-34.png')
robot = robot.resize((int(.46 * px_per_m), int(.46 * px_per_m)), Image.LANCZOS)
px, py = turn.width - 460, 300
turn.alpha_composite(boy, (px, py))
anchor_x, anchor_y = px + boy.width * 192 / 384, py + boy_px * 420 / 448
# Her origin floats 0.55 m to the side and 0.8 m up (HotaruRobot.OFFSET); the render centre is 0.19 m above it.
cx, cy = anchor_x + .55 * px_per_m, anchor_y - (.8 + .19) * px_per_m
turn.alpha_composite(robot, (int(cx - robot.width / 2), int(cy - robot.height / 2)))
label(d, (px + 200, py + boy_px + 24), 'Scale beside the apprentice', 22, anchor='ma')
turn.convert('RGB').save(HERE / 'concept/turnaround-sheet.png')
print('Composed portrait, expressions and sheets in', HERE)
