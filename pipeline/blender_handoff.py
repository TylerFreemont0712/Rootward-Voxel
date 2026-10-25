"""Run only in Blender: seed GLB -> editable source, or editable source -> candidate GLB."""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Euler, Vector

args = sys.argv[sys.argv.index('--') + 1:]
operation, source, output = args
source, output = Path(source), Path(output)

if operation == 'init':
    if output.exists():
        raise RuntimeError('Editable Blender source exists. Refusing to overwrite human edits.')
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))
    bpy.context.scene.unit_settings.system = 'METRIC'
    bpy.context.scene.unit_settings.scale_length = 1.0
    bpy.context.scene['rootward_source'] = 'Editable authority. Seed generation must not overwrite this file.'
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.file.pack_all()
    points = [obj.matrix_world @ Vector(corner) for obj in bpy.context.scene.objects if obj.type == 'MESH' for corner in obj.bound_box]
    lower = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    upper = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == 'VIEW_3D':
                area.spaces.active.region_3d.view_location = (lower + upper) * 0.5
                area.spaces.active.region_3d.view_distance = max((upper - lower).length * 1.25, 3.0)
                area.spaces.active.region_3d.view_rotation = Euler((math.radians(60), 0, math.radians(45))).to_quaternion()
                area.spaces.active.region_3d.view_perspective = 'ORTHO'
                area.spaces.active.shading.type = 'MATERIAL'
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    print('Editable source saved:', output)
elif operation == 'export':
    bpy.ops.wm.open_mainfile(filepath=str(source))
    # Export reads the artist source; it never saves over it or regenerates the seed.
    bpy.ops.export_scene.gltf(
        filepath=str(output), export_format='GLB', export_image_format='AUTO',
        export_texcoords=True, export_normals=True, export_materials='EXPORT',
        export_animations=False, export_cameras=False, export_lights=False,
        export_yup=True, export_apply=False, export_extras=True,
        export_draco_mesh_compression_enable=False, export_use_gltfpack=False,
        export_meshopt_compression_enable=False, use_selection=False,
        use_visible=False, use_renderable=False, use_active_scene=True,
    )
    print('Exported candidate without changing source:', output)
else:
    raise RuntimeError('Unknown operation: ' + operation)
