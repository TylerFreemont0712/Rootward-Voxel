"""Deliberate saved-master revision: a physical nameplate and slate socket anchor."""
import bpy, math
from pathlib import Path
source=Path(__file__).with_name('model.blend')
bpy.ops.wm.open_mainfile(filepath=str(source))
if 'SlateSocket' in bpy.data.objects:
 raise RuntimeError('Detail revision already applied; edit the saved master.')
bpy.ops.object.empty_add(type='PLAIN_AXES',location=(.78,-.365,1.35))
bpy.context.object.name='SlateSocket'
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,-.223,1.74))
plate=bpy.context.object;plate.name='Stop nameplate';plate.dimensions=(1.65,.035,.16)
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
plate.data.materials.append(bpy.data.materials['Worked brass'])
bevel=plate.modifiers.new('Rounded plate','BEVEL');bevel.width=.025;bevel.segments=3
bpy.ops.object.modifier_apply(modifier=bevel.name)
bpy.ops.object.text_add(location=(0,-.245,1.74),rotation=(math.pi/2,0,0))
text=bpy.context.object;text.name='Spindle Lane nameplate';text.data.body='SPINDLE LANE'
text.data.align_x='CENTER';text.data.align_y='CENTER';text.data.size=.12
text.data.extrude=.001;text.data.materials.append(bpy.data.materials['Deep teal enamel'])
bpy.ops.object.convert(target='MESH')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(source))
