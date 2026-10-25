"""Small post-review source edit: side windows and timber bands on the two saved shops.
Run in Blender from the project root. Repeated calls refuse already detailed masters.
"""
from pathlib import Path
import bpy,json,hashlib,sys
root=Path.cwd();sys.path.insert(0,str(root/'pipeline'))
from blender_retexture import uv_object

def box(name,at,size,material):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at)
    obj=bpy.context.object;obj.name=name;obj.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    obj.data.materials.append(bpy.data.materials[material])
    return obj

for id in ['hollow-bakery','hollow-smithy']:
    source=root/'art/source/world'/id/'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if bpy.context.scene.get('shop_side_details'):raise RuntimeError('Shop details already adopted; edit its saved master.')
    w,d=(5,4) if id=='hollow-bakery' else (6,5)
    for x in [-w/2,w/2]:
        for z in [.43,2.9]:box('Shop side timber band',(x,0,z),(.16,d,.14),'wood')
        # The smithy's right-hand bay stays open; its closed hall gets left windows.
        if id=='hollow-smithy' and x>0:continue
        side=1 if x>0 else -1
        for y in [-d*.23,d*.23]:
            box('Shop side window recess',(x,y,1.7),(.10,1.02,1.26),'recess')
            box('Shop side warm panes',(x+side*.065,y,1.7),(.055,.87,1.09),'window_warm')
            for offset in [-.5,0,.5]:box('Shop side window jamb',(x+side*.1,y+offset,1.7),(.12,.075,1.28),'wood')
            for z in [1.08,1.7,2.32]:box('Shop side window rail',(x+side*.1,y,z),(.12,1.08,.075),'wood')
            box('Shop side window sill',(x+side*.12,y,1.0),(.42,1.2,.12),'stone')
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.name.startswith('Shop side'):
            uv_object(obj,{'window_warm':{'mode':'face'},'wood':{'mode':'world','tile':1.2},'stone':{'mode':'world','tile':1.5}})
    bpy.context.scene['shop_side_details']=True
    bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
    path=source.parent/'provenance.json';record=json.loads(path.read_text());record['source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest();record['detail_edit']='art/source/world/building-polish/v1/shop_details.py';path.write_text(json.dumps(record,indent=2)+'\n')
