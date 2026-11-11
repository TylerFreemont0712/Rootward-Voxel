"""Connect the tower-side drain to its actual higher cornice, rather than the removed lower roof corner."""
from pathlib import Path
import sys,hashlib
import bpy
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_tower_drain'):raise RuntimeError('Tower drain already corrected.')
before=hashlib.sha256(path.read_bytes()).hexdigest();bind_materials()
obj=bpy.data.objects['refined_structure_structure']
discard_components(obj,lambda lo,hi,c:c.x<-3.6 and c.y<-2.6 and lo.z>5.8 and hi.z<6.45)
p=k.Parts(110307);p.group='clockmaker_tower_drain'
p.cylinder('iron',(-3.76,-2.76,5.93),(-3.76,-2.76,9.08),.043,10)
p.cylinder('iron',(-3.76,-2.76,9.08),(-3.68,-2.73,9.26),.043,10)
for z in [6.7,8.3]:p.box('iron',(-3.76,-2.71,z),(.13,.14,.045),bevel=.008,uv='flat')
finish(p,bpy.data.objects['haverlund_clockmaker']);bpy.context.scene['clock_tower_drain']=True
save_record(path,'drain_finish',before)
