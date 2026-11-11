"""Read-only inventory of foliage in the selected Sparks & Machines masters."""
from pathlib import Path
import json
import importlib.util
import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[5]
spec = importlib.util.spec_from_file_location('house_kit', ROOT / 'art/source/world/seaside-houses/v1/house_kit.py')
kit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)


def components(bm):
    unseen = set(bm.verts)
    while unseen:
        seed = min(unseen, key=lambda v: v.index)
        unseen.remove(seed)
        found = {seed}
        todo = [seed]
        while todo:
            for edge in todo.pop().link_edges:
                for vertex in edge.verts:
                    if vertex in unseen:
                        unseen.remove(vertex)
                        found.add(vertex)
                        todo.append(vertex)
        yield found


def colour(obj, faces, uv):
    face = min(faces, key=lambda f: f.index)
    material = obj.data.materials[face.material_index]
    if material is None:
        return ''
    name = material.name
    if name == 'house_paint' and uv:
        pos = face.loops[0][uv].uv
        image = next(n.image for n in material.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image)
        rows = image.size[1] // kit.CELL
        index = int(pos.x * kit.PALETTE_COLUMNS) + int((1 - pos.y) * rows) * kit.PALETTE_COLUMNS
        names = list(kit.FLAT)
        if 0 <= index < len(names):
            centre = ((index % 8 + .5) / 8, 1 - (index // 8 + .5) / rows)
            if abs(pos.x - centre[0]) < .015 and abs(pos.y - centre[1]) < .015:
                return names[index]
        return ''
    return name.removeprefix('loft_').removeprefix('workshop_').removeprefix('lane_').removeprefix('square_')


def active_assets():
    catalog = json.loads((ROOT / 'pipeline/world-catalog.json').read_text())
    ids = set()
    def visit(value):
        if isinstance(value, dict):
            for child in value.values(): visit(child)
        elif isinstance(value, list):
            for child in value: visit(child)
        elif isinstance(value, str) and value in catalog['assets']:
            ids.add(value)
    for area in ('workshop-loft', 'workshop-floor', 'haverlund-lane', 'haverlund-square'):
        visit(json.loads((ROOT / 'content/areas' / (area + '.json')).read_text()))
    return {key: catalog['assets'][key] for key in sorted(ids) if not key.startswith('robot-')}


if __name__ == '__main__':
    output = {}
    for asset, entry in active_assets().items():
        bpy.ops.wm.open_mainfile(filepath=str(ROOT / entry['source']))
        counts = {}
        for obj in bpy.context.scene.objects:
            if obj.type != 'MESH': continue
            if not any(m and (m.name == 'house_paint' or any(t in m.name for t in ('leaf', 'flower', 'cypress'))) for m in obj.data.materials): continue
            bm = bmesh.new(); bm.from_mesh(obj.data); bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
            uv = bm.loops.layers.uv.active
            for verts in components(bm):
                faces = {f for v in verts for f in v.link_faces}
                if not faces: continue
                name = colour(obj, faces, uv)
                if name not in {'leaf', 'leaf_light', 'leaf_dark', 'olive', 'cypress', 'cypress_light'} and not name.startswith('flower_'): continue
                key = (name, len(verts), len(faces))
                counts[key] = counts.get(key, 0) + 1
            bm.free()
        if counts:
            output[asset] = [{'colour': k[0], 'vertices': k[1], 'faces': k[2], 'count': n} for k,n in counts.items()]
            print(asset, str(output[asset]))
    (ROOT / '.cache/plant-style/component-inventory.json').write_text(json.dumps(output, indent=2)+'\n')
