"""One-time authoring record for Hotaru's robot body. Refuses an existing editable master.

Run: blender --background --factory-startup --python art/source/world/hotaru-robot/v1/author.py
Afterwards model.blend is the authority; edit it in Blender and export with
scripts/world-art.sh build hotaru-robot. This script is not a second build pipeline.
"""
from pathlib import Path
import hashlib
import json
import math

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
OUTPUT = HERE / 'model.blend'
if OUTPUT.exists():
    raise RuntimeError('Open the existing Hotaru master; authoring never overwrites it.')

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene


def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4


def material(name, color, roughness=.8, metallic=0.0, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    rgb = tuple(linear(int(color[i:i + 2], 16) / 255) for i in (0, 2, 4))
    mat.diffuse_color = (*rgb, 1)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*rgb, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*rgb, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return mat


# Palette from docs/concept/v0.7/02-art-direction.md. The glass and eyes are the
# changing parts: the game finds them by these material names, never by node path.
mats = {
    'hotaru_enamel': material('hotaru_enamel', 'efe3c6', .72),
    'hotaru_enamel_shade': material('hotaru_enamel_shade', 'd9c9a6', .8),
    'hotaru_teal': material('hotaru_teal', '2f8c8c', .7),
    'hotaru_brass': material('hotaru_brass', 'c99a3e', .45, .35),
    'hotaru_red': material('hotaru_red', 'c8453a', .55),
    'hotaru_slot': material('hotaru_slot', '3a2a22', .9),
    'spark_glass': material('spark_glass', 'ffc861', .25, emission=.6),
    'spark_eye': material('spark_eye', 'fff1c2', .3, emission=2.5),
}


def empty(name, at=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_size = .05
    scene.collection.objects.link(obj)
    obj.location = at
    obj.parent = parent
    return obj


root = empty('hotaru')


def finish(obj, mat, parent, smooth=False):
    obj.data.materials.clear()
    obj.data.materials.append(mats[mat])
    # Pivots carry no rotation, so a child's local position is its offset from the pivot.
    obj.parent = parent
    obj.location -= parent.location
    for poly in obj.data.polygons:
        poly.use_smooth = smooth
    return obj


def link(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    return obj


def lathe(name, profile, mat, parent, segments=16, closed=False, caps=(True, True), smooth=True):
    """Revolve (radius, height) points around Z. Sides are smooth, caps and rims crisp."""
    verts, faces = [], []
    for radius, z in profile:
        for i in range(segments):
            a = math.tau * i / segments
            verts.append((radius * math.cos(a), radius * math.sin(a), z))
    rings = len(profile)
    spans = rings if closed else rings - 1
    for k in range(spans):
        for i in range(segments):
            k2 = (k + 1) % rings
            faces.append((k * segments + i, k * segments + (i + 1) % segments,
                          k2 * segments + (i + 1) % segments, k2 * segments + i))
    side_faces = len(faces)
    if not closed and caps[0] and profile[0][0] > 0:
        faces.append(tuple(reversed(range(segments))))
    if not closed and caps[1] and profile[-1][0] > 0:
        faces.append(tuple(range((rings - 1) * segments, rings * segments)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    obj = finish(link(name, mesh), mat, parent)
    for index, poly in enumerate(mesh.polygons):
        poly.use_smooth = smooth and index < side_faces
    # Sharp rims where a smooth side meets a flat cap keep the enamel edges readable.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for edge in bm.edges:
        if len(edge.link_faces) == 2 and edge.link_faces[0].smooth != edge.link_faces[1].smooth:
            edge.smooth = False
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    return obj


def band(name, inner, outer, z0, z1, mat, parent, segments=16):
    return lathe(name, [(inner, z0), (outer, z0), (outer, z1), (inner, z1)], mat, parent, segments, closed=True, smooth=False)


def sphere(name, at, scale, mat, parent, segments=12, rings=8, smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=at)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, mat, parent, smooth)


def box(name, at, size, mat, parent, rotation=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft arris', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj, mat, parent)


def cylinder(name, at, radius, depth, mat, parent, rotation=(0, 0, 0), segments=12, smooth=True):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius, depth=depth, location=at, rotation=rotation)
    obj = finish(bpy.context.object, mat, parent)
    obj.name = name
    for poly in obj.data.polygons:
        poly.use_smooth = smooth and abs(poly.normal.z) < .5 if rotation == (0, 0, 0) else smooth
    return obj


# Front is Blender -Y, which the glTF exporter turns into Godot +Z, the world's forward.
# The origin is the ground under her feet in working mode; one metre is one grid cell.
LIFT = .05          # height of the folded legs
WINDOW_Z = LIFT + .095

# The lantern body: round-bellied, narrower at its foot and collar.
lathe('Lantern body', [(.07, LIFT + .012), (.092, LIFT + .036), (.102, LIFT + .08), (.099, LIFT + .125),
                       (.086, LIFT + .163), (.076, LIFT + .172)], 'hotaru_enamel', root, segments=20)
band('Foot ring', .056, .074, LIFT, LIFT + .014, 'hotaru_brass', root)
lathe('Underside', [(.056, LIFT + .002), (.07, LIFT + .012)], 'hotaru_enamel_shade', root, caps=(True, False))
band('Lower teal band', .083, .093, LIFT + .018, LIFT + .028, 'hotaru_teal', root)
band('Upper teal band', .09, .1, LIFT + .138, LIFT + .149, 'hotaru_teal', root)
band('Brass collar', .066, .084, LIFT + .168, LIFT + .18, 'hotaru_brass', root)

# A lantern's cap: a teal brim and dome, so she reads from the high game camera.
lathe('Cap brim', [(.07, LIFT + .178), (.108, LIFT + .186), (.106, LIFT + .195), (.07, LIFT + .193)],
      'hotaru_teal', root, segments=20, smooth=False)
dome = [(.082 * math.cos(t), LIFT + .19 + .068 * math.sin(t)) for t in [i * math.pi / 2 / 6 for i in range(6)]]
lathe('Domed cap', dome + [(.012, LIFT + .258)], 'hotaru_teal', root, segments=20)
cylinder('Rotor stem', (0, 0, LIFT + .265), .01, .018, 'hotaru_brass', root)

# Her face: one round spark window in a brass rim. The spark makes two eyes.
bpy.ops.mesh.primitive_torus_add(major_radius=.045, minor_radius=.0075, major_segments=20, minor_segments=6,
                                 location=(0, -.1, WINDOW_Z), rotation=(math.pi / 2, 0, 0))
finish(bpy.context.object, 'hotaru_brass', root, smooth=True).name = 'Window rim'
sphere('Spark window', (0, -.096, WINDOW_Z), (.04, .014, .04), 'spark_glass', root, 16, 8)
for side in (-1, 1):
    sphere('Spark eye', (side * .0155, -.108, WINDOW_Z + .004), (.0085, .004, .0115), 'spark_eye', root, 10, 6)
for side in (-1, 1):
    sphere('Window rivet', (side * .058, -.092, WINDOW_Z), (.005, .005, .005), 'hotaru_brass', root, 8, 4)

# The tape reader under the window: what you print feeds in here.
box('Tape slot', (0, -.094, LIFT + .036), (.042, .012, .008), 'hotaru_slot', root)
box('Tape slot lip', (0, -.096, LIFT + .042), (.05, .01, .004), 'hotaru_brass', root)

# Nell's brass name plate on her back, like a name painted on a delivery van.
box('Name plate', (0, .099, LIFT + .1), (.052, .008, .03), 'hotaru_brass', root, bevel=.002)
for side in (-1, 1):
    sphere('Plate rivet', (side * .021, .104, LIFT + .1), (.0035, .0035, .0035), 'hotaru_slot', root, 6, 4)

# Rotor: spins while she floats. The game turns the 'rotor' pivot.
rotor = empty('rotor', (0, 0, LIFT + .276), root)
cylinder('Rotor hub', (0, 0, LIFT + .276), .015, .012, 'hotaru_brass', rotor)
for side in (-1, 1):
    box('Rotor blade', (side * .056, 0, LIFT + .278), (.092, .024, .005), 'hotaru_brass', rotor,
        rotation=(side * .25, 0, 0), bevel=.002)
sphere('Red knob', (0, 0, LIFT + .29), (.014, .014, .014), 'hotaru_red', rotor, 12, 8)

# Short arms on little brass shoulders; hands come later as parts.
for side, label in ((-1, 'arm_left'), (1, 'arm_right')):
    shoulder = empty(label, (side * .1, 0, LIFT + .1), root)
    sphere('Shoulder', (side * .1, 0, LIFT + .1), (.015, .015, .015), 'hotaru_brass', shoulder, 10, 6)
    cylinder('Stub arm', (side * .113, -.003, LIFT + .085), .01, .032, 'hotaru_enamel', shoulder,
             rotation=(0, side * .65, 0), segments=10)
    sphere('Stub hand', (side * .124, -.005, LIFT + .069), (.016, .015, .016), 'hotaru_teal', shoulder, 10, 6)

# Legs fold away while she floats; working mode shows them.
legs = empty('legs', (0, 0, LIFT), root)
for side in (-1, 1):
    cylinder('Leg', (side * .036, 0, .03), .014, .04, 'hotaru_brass', legs, segments=10)
    box('Foot', (side * .036, -.008, .008), (.036, .05, .016), 'hotaru_enamel', legs, bevel=.004)

# Plain cube-projected UVs so the importer has coordinates; materials are flat colours.
for obj in [o for o in scene.objects if o.type == 'MESH']:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=.3)
    bpy.ops.object.mode_set(mode='OBJECT')

scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['rootward_source'] = 'Editable Hotaru robot authority. Authoring script refuses to overwrite it.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
(HERE / 'provenance.json').write_text(json.dumps({
    'asset': 'hotaru-robot', 'version': 'v1', 'date': '2026-10-26',
    'derived_from': None,
    'brief': 'docs/concept/v0.7/03-robot-companion.md',
    'authoring_record': 'author.py',
    'authoring_record_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'note': 'New model authored from the v0.7 robot companion design. model.blend is now authority.'
}, indent=2) + '\n')
print('Saved Hotaru robot', OUTPUT)
