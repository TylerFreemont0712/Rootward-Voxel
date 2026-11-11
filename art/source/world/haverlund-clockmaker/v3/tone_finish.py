"""Final game-scale color review: restrained aged copper and neutral, low-opacity display glass."""
from pathlib import Path
import sys,hashlib
import bpy
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_tone_finish'):raise RuntimeError('Already toned for the game view.')
before=hashlib.sha256(path.read_bytes()).hexdigest()
mat=bpy.data.materials['clock_copper_painted'];mix=next(n for n in mat.node_tree.nodes if n.type=='MIX');next(s for s in mix.inputs if s.identifier=='B_Color').default_value=(.40,.40,.56,1)
bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Roughness'].default_value=.78;bs.inputs['Metallic'].default_value=.18
mat=bpy.data.materials['clock_clear_glass'];bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(*k._rgb('eee9dd'),1);bs.inputs['Alpha'].default_value=.075;bs.inputs['Roughness'].default_value=.26
bpy.context.scene['clock_tone_finish']=True
save_record(path,'tone_finish',before)
print('NEUTRAL GLASS AND AGED COPPER SAVED')
