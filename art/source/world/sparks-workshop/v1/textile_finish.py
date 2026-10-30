"""Gameplay-scale textile finish: physical plaid spacing and a painted woven rug."""
from pathlib import Path
import bpy,math,json,hashlib,shutil,importlib.util
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
spec=importlib.util.spec_from_file_location('workshop_helpers',HERE/'author.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
records=[]
def opened(asset):
    path=ROOT/'art/source/world'/asset/'v1/model.blend';backup=path.with_name('model.pre-textile-finish.blend')
    if backup.exists():raise RuntimeError('Already finished; open the current master')
    shutil.copy2(path,backup);records.append({'asset':asset,'before':hashlib.sha256(path.read_bytes()).hexdigest(),'backup':str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.preferences.filepaths.save_version=0
    w.h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY');w.M.clear()
    for m in bpy.data.materials:
        if m.name.startswith('workshop_'):w.M[m.name[9:].split('.')[0]]=m
    return path
def save(path):
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path));records[-1]['after']=hashlib.sha256(path.read_bytes()).hexdigest()

path=opened('workshop-armchair')
profile=[(.62,.62),(.62,1.35),(.48,1.65),(.29,1.60),(.22,1.10),(.13,.79),(-.30,.78),(-.60,.65),(-.63,.32)]
distance=[0]
for a,b in zip(profile,profile[1:]):distance.append(distance[-1]+math.hypot(b[0]-a[0],b[1]-a[1]))
for o in bpy.context.scene.objects:
    if o.type!='MESH':continue
    mat=o.data.materials[0].name
    if mat=='workshop_plaid':
        for v in o.data.vertices:v.co.x*=.72/.54
        uv=o.data.uv_layers.active
        for item in uv.data:
            u,v=item.uv;row=round(v*(len(profile)-1))
            item.uv=(.10+u*.72/1.5,distance[row])
    elif mat=='workshop_ochre':
        for v in o.data.vertices:
            p=o.matrix_world@v.co;p.x=.12+(p.x-.12)*.72/.54;v.co=o.matrix_world.inverted()@p
save(path)

path=opened('workshop-rug')
# Fine raised lines read as rubber ribs at gameplay size. The native woven
# painting supplies the fibers; existing border, backing and fringe are kept.
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o.data.materials[0].name=='workshop_teal':bpy.data.objects.remove(o,do_unlink=True)
w.h.material('woven','ffffff',str(w.LOFT/'woven-rug'))
w.M['woven'].name='workshop_woven'
rows=[(-1.49+j/16*2.98,.054+.004*math.sin(j*.8)) for j in range(17)]
w.fabric('Painted workshop weave',rows,4.36,'woven',40)
save(path)
(HERE/'textile-finish.json').write_text(json.dumps({'date':'2026-10-27','sources':records},indent=2)+'\n')
