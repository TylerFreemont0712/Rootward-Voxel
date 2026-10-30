"""Deliberate saved-source correction: expose the clock above the ridge.
Replace the intersecting test cap slabs with one clean four-sided hip roof.
"""
import bpy, shutil
from pathlib import Path
ROOT=Path.cwd();p=ROOT/'art/source/world/morning-town-hall/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(p))
if bpy.context.scene.get('clock_revealed'):raise RuntimeError('Revision already applied.')
backup=p.with_name('model.pre-clock-reveal.blend')
if not backup.exists():shutil.copy2(p,backup)
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o.get('part')=='Clock tower':
        if o.data.materials[0].name=='hall_roof':
            bpy.data.objects.remove(o,do_unlink=True)
        else:
            o.location.z+=1.2
verts=[(-1.42,-3.02,9.80),(1.42,-3.02,9.80),(1.42,-.28,9.80),(-1.42,-.28,9.80),(0,-1.65,10.72)]
d=bpy.data.meshes.new('Clean belfry hip cap');d.from_pydata(verts,[],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)])
d.materials.append(bpy.data.materials['hall_roof']);d.update();uv=d.uv_layers.new(name='UVMap')
for face in d.polygons:
    for li in face.loop_indices:
        co=d.vertices[d.loops[li].vertex_index].co;uv.data[li].uv=(co.x/1.3,(co.y+co.z)/1.3)
o=bpy.data.objects.new('Clock tower clean hip roof',d);bpy.context.scene.collection.objects.link(o);o['part']='Clock tower'
bpy.context.scene['clock_revealed']=True
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(p))
