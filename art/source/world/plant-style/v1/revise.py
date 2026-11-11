"""Deliberate foliage-only edit of the current Sparks masters. Not a model generator.

Run once with Blender. Each master is preserved before editing; a second run refuses
to overwrite it. Later art changes start from the saved master. The normal world
build remains the only exporter. inspect.py reads both named materials and the
original four/five-row packed house palettes without changing either palette.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import random
import shutil
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('plant_inventory', HERE / 'inspect.py')
inventory = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inventory)
UP = Vector((0, 0, 1))
GREENS = {'leaf', 'leaf_light', 'leaf_dark', 'olive', 'cypress', 'cypress_light'}
SPHERES = {12, 42, 52, 62, 114, 162}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class Drawing:
    def __init__(self, bm, obj):
        self.bm, self.obj = bm, obj
        self.inverse = obj.matrix_world.inverted()
        self.uv_layer = bm.loops.layers.uv.verify()
        self.material = 0
        self.uv = (0, 0)
        self.vertices = {}

    def face(self, points, reverse=False):
        verts = []
        for point in points:
            key = tuple(round(float(v), 10) for v in point)
            if key not in self.vertices:
                self.vertices[key] = self.bm.verts.new(self.inverse @ Vector(point))
            vertex = self.vertices[key]
            if vertex not in verts:
                verts.append(vertex)
        if len(verts) < 3:
            return
        face = self.bm.faces.new(list(reversed(verts)) if reverse else verts)
        face.material_index = self.material
        for loop in face.loops:
            loop[self.uv_layer].uv = self.uv

    def leaf(self, base, tip, width, normal=UP):
        """A closed, gently arched blade: tapered shoulders, pointed tip, raised midrib."""
        base, tip, normal = Vector(base), Vector(tip), Vector(normal).normalized()
        direction = tip - base
        side = direction.cross(normal).normalized()
        if side.length < .5:
            side = direction.cross(Vector((0, 1, 0))).normalized()
        normal = side.cross(direction).normalized()
        if normal.dot(UP) < 0:
            normal = -normal
        length = direction.length
        rows = []
        for t, spread in ((0, 0), (.25, .72), (.53, 1), (.78, .55), (1, 0)):
            mid = base + direction * t + normal * (math.sin(t * math.pi) * length * .12)
            rows.append((mid - side * width * spread / 2,
                         mid + normal * (width * .11 * math.sin(t * math.pi)),
                         mid + side * width * spread / 2))
        for a, b in zip(rows, rows[1:]):
            for side_index in (0, 1):
                points = [a[side_index], b[side_index], b[side_index + 1], a[side_index + 1]]
                clean = []
                for p in points:
                    if not any((p - q).length < 1e-7 for q in clean):
                        clean.append(p)
                if len(clean) >= 3:
                    self.face(clean)
                    # A separate underside makes glTF's ordinary one-sided material
                    # readable from behind too, without coincident reverse faces.
                    self.face([p - normal * max(.001, width * .025) for p in clean], True)
        # Close the fine edge along each shoulder.
        for index in (0, 2):
            for a, b in zip(rows, rows[1:]):
                drop = normal * max(.001, width * .025)
                self.face([a[index], b[index], b[index] - drop, a[index] - drop])

    def stem(self, base, tip, radius):
        base, tip = Vector(base), Vector(tip)
        d = (tip - base).normalized()
        side = d.cross(UP).normalized()
        if side.length < .5:
            side = d.cross(Vector((0, 1, 0))).normalized()
        other = d.cross(side)
        rings = [[centre + (side * math.cos(a * math.tau / 5) + other * math.sin(a * math.tau / 5)) * r
                  for a in range(5)] for centre, r in ((base, radius), (tip, radius * .45))]
        for j in range(5):
            self.face([rings[0][j], rings[0][(j + 1) % 5], rings[1][(j + 1) % 5], rings[1][j]])
        self.face(rings[0], True)
        self.face(rings[1])

    def sprig(self, centre, radius, rng, conifer=False):
        """One old foliage ball becomes a small branching plant with open gaps."""
        rx, ry, rz = radius
        base = centre - UP * rz * .85
        tip = centre + UP * rz * .88
        self.stem(base, tip, min(rx, ry, rz) * .055)
        turn = rng.uniform(0, math.tau)
        for level in range(3):
            t = .15 + level * .27
            at = base.lerp(tip, t)
            for side in (-1, 1):
                angle = turn + level * 1.6 + (math.pi if side < 0 else 0)
                extent = .95 - level * (.18 if conifer else .08)
                end = at + Vector((math.cos(angle) * rx * extent, math.sin(angle) * ry * extent,
                                    rz * (.5 if conifer else .32)))
                self.leaf(at, end, min(rx, ry) * (.42 if conifer else .72))
        self.leaf(tip - UP * rz * .25, tip + UP * rz * .18, min(rx, ry) * .43)

    def flower(self, centre, radius, rng):
        """A modest five-petal flower head instead of a coloured ball."""
        r = max(radius)
        turn = rng.uniform(0, math.tau)
        normal = Vector((rng.uniform(-.3, .3), rng.uniform(-.3, .3), 1)).normalized()
        x = normal.cross(Vector((0, 1, 0))).normalized()
        y = normal.cross(x)
        for k in range(5):
            angle = turn + k * math.tau / 5
            d = x * math.cos(angle) + y * math.sin(angle)
            self.leaf(centre - d * r * .12, centre + d * r, r * .68, normal)


def protected_fingerprint(bm, faces, uv):
    """Exact authored face positions, material slots, shading and every UV layer."""
    layers = list(bm.loops.layers.uv.values())
    values = []
    for face in faces:
        values.append((face.material_index, face.smooth,
                       tuple((tuple(loop.vert.co), tuple(tuple(loop[layer].uv) for layer in layers)) for loop in face.loops)))
    return hashlib.sha256(repr(sorted(values)).encode()).hexdigest()


def selected(obj, verts, faces, colour, asset):
    if len(verts) not in SPHERES:
        return False  # Keep all existing stems, vines, grass blades and supports.
    if colour not in GREENS and not colour.startswith('flower_'):
        return False
    # Fruit/vegetables deliberately share paint swatches with flowers and foliage.
    # Preserve the produce display and all other non-botanical uses of those colours.
    if obj.name == 'detail_wares' or asset == 'square-market-stall':
        return False
    if asset in {'haverlund-fruit-market', 'haverlund-greengrocer'} and obj.name == 'house_paint':
        return False
    return all(len(face.verts) in (3, 4) for face in faces)


def revise(asset, entry, check_only=False):
    path = ROOT / entry['source']
    backup = path.with_name('model.pre-plant-style.blend')
    bpy.ops.wm.open_mainfile(filepath=str(path))
    bpy.context.preferences.filepaths.save_version = 0
    changes = []
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH' or not any(m and (m.name == 'house_paint' or any(t in m.name for t in ('leaf', 'flower', 'cypress'))) for m in obj.data.materials):
            continue
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.verts.ensure_lookup_table()
        bm.faces.ensure_lookup_table()
        uv = bm.loops.layers.uv.active
        chosen = []
        for verts in inventory.components(bm):
            faces = {f for v in verts for f in v.link_faces}
            if not faces:
                continue
            colour = inventory.colour(obj, faces, uv)
            if selected(obj, verts, faces, colour, asset):
                chosen.append((verts, faces, colour))
        if not chosen:
            bm.free()
            continue
        if check_only:
            changes.append({'object': obj.name, 'components': len(chosen)})
            bm.free()
            continue
        all_doomed = {f for _, faces, _ in chosen for f in faces}
        protected = set(bm.faces) - all_doomed
        before = protected_fingerprint(bm, protected, uv)
        drawing = Drawing(bm, obj)
        counts = {}
        for index, (verts, faces, colour) in enumerate(chosen):
            rng = random.Random(asset + ':' + obj.name + ':' + str(index))
            coords = [obj.matrix_world @ v.co for v in sorted(verts, key=lambda v: v.index)]
            array = np.array([tuple(p) for p in coords])
            centre = Vector(tuple((array.min(axis=0) + array.max(axis=0)) / 2))
            radius = (array.max(axis=0) - array.min(axis=0)) / 2
            first = min(faces, key=lambda f: f.index)
            drawing.material = first.material_index
            drawing.uv = tuple(first.loops[0][uv].uv) if uv else (0, 0)
            if colour.startswith('flower_'):
                drawing.flower(centre, radius, rng)
            elif len(verts) in (52, 62, 114):
                # Existing elongated UV-sphere leaves retain their authored direction.
                _, axes = np.linalg.eigh(np.cov((array - array.mean(axis=0)).T))
                axis = Vector(tuple(axes[:, -1]))
                if axis.dot(centre) < 0:
                    axis = -axis
                extent = max(abs((p - centre).dot(axis)) for p in coords)
                normal = Vector(tuple(axes[:, 0]))
                drawing.leaf(centre - axis * extent * .85, centre + axis * extent * 1.15,
                             sorted(radius)[1] * 1.8, normal)
            else:
                drawing.sprig(centre, radius, rng, colour.startswith('cypress'))
            counts[colour] = counts.get(colour, 0) + 1
        bmesh.ops.delete(bm, geom=list({v for verts, _, _ in chosen for v in verts}), context='VERTS')
        after = protected_fingerprint(bm, protected, uv)
        assert before == after, 'Non-foliage faces changed: ' + asset + '/' + obj.name
        bmesh.ops.recalc_face_normals(bm, faces=list(set(bm.faces) - protected))
        assert before == protected_fingerprint(bm, protected, uv)
        bm.to_mesh(obj.data)
        bm.free()
        obj.data.update()
        obj['plant_style'] = 'pointed folded leaves and branching sprigs, 2026-10-30'
        changes.append({'object': obj.name, 'replaced_components': counts,
                        'protected_faces': len(protected), 'protected_sha256': before})
    if changes and not check_only:
        if backup.exists():
            raise RuntimeError('Already revised; edit the saved master: ' + asset)
        shutil.copy2(path, backup)
        before = digest(path)
        bpy.ops.wm.save_as_mainfile(filepath=str(path))
        record = {'asset': asset, 'source': entry['source'], 'backup': str(backup.relative_to(ROOT)),
                  'before_sha256': before, 'after_sha256': digest(path), 'objects': changes}
        path.with_name('plant-style.json').write_text(json.dumps(record, indent=2) + '\n')
        return record
    return {'asset': asset, 'objects': changes} if changes else None


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    check_only = '--inspect' in args
    assets = inventory.active_assets()
    explicit = [a for a in args if not a.startswith('--')]
    if explicit:
        assets = {key: assets[key] for key in explicit}
    if not check_only:
        # Preflight the whole batch before touching any source.
        for asset, entry in assets.items():
            if (ROOT / entry['source']).with_name('model.pre-plant-style.blend').exists():
                raise RuntimeError('Already revised; edit current master: ' + asset)
    records = []
    for asset, entry in assets.items():
        record = revise(asset, entry, check_only)
        if record:
            records.append(record)
            print('FOLIAGE', asset, len(record['objects']), flush=True)
    output = ROOT / '.cache/plant-style/plan.json' if check_only else HERE / 'revision.json'
    output.write_text(json.dumps(records, indent=2) + '\n')
