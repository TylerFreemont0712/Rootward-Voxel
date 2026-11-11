"""Remove only the windowsill plant from the adopted keepsakes master."""
from pathlib import Path
import bpy,bmesh,hashlib,json,shutil
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
path=ROOT/'art/source/world/loft-window-life/v1/model.blend'
backup=path.with_name('model.pre-sill-plant-removal.blend')
if backup.exists():raise RuntimeError('Already edited; open the current master.')
shutil.copy2(path,backup);before=hashlib.sha256(path.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.preferences.filepaths.save_version=0
removed=0
for o in list(bpy.context.scene.objects):
    if o.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(o.data);remaining=set(bm.verts);delete=[]
    while remaining:
        seed=remaining.pop();group={seed};todo=[seed]
        while todo:
            for e in todo.pop().link_edges:
                for v in e.verts:
                    if v in remaining:remaining.remove(v);group.add(v);todo.append(v)
        if max((o.matrix_world@v.co).x for v in group)<.05:delete.extend(group);removed+=1
    if delete:bmesh.ops.delete(bm,geom=delete,context='VERTS')
    bm.to_mesh(o.data);bm.free();o.data.update()
    if not o.data.vertices:bpy.data.objects.remove(o,do_unlink=True)
assert removed>10
bpy.ops.wm.save_as_mainfile(filepath=str(path))
(HERE/'sill-plant-removal.json').write_text(json.dumps({'asset':'loft-window-life','before':before,
    'after':hashlib.sha256(path.read_bytes()).hexdigest(),'backup':str(backup.relative_to(ROOT)),
    'change':'Windowsill plant removed; book and keepsake box retained. Other loft plants untouched.'},indent=2)+'\n')
