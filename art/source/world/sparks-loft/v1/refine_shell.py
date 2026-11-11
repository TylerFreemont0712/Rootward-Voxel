"""Deliberate edit of the existing adopted loft shell, preserving its first master.
Keeps wall/window/rafter geometry. Replaces the noisy generic finish, staggers
the floor joints, opens the stairwell and gives the windows a painted view.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import shutil
import bpy

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
SOURCE=ROOT/'art/source/world/loft-shell/v1/model.blend'
BACKUP=SOURCE.with_name('model.pre-furnishing.blend')
NOTE=SOURCE.with_name('furnishing-revision.json')
if NOTE.exists() or BACKUP.exists():
    raise RuntimeError('This deliberate shell edit already ran; edit the saved master instead.')
before=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
shutil.copy2(SOURCE,BACKUP)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version=0
spec=importlib.util.spec_from_file_location('loft_author_helpers',HERE/'author.py')
h=importlib.util.module_from_spec(spec); spec.loader.exec_module(h)
h.PARENT=bpy.data.objects['loft_shell']
h.material('oak','ffffff','honey-oak')
h.material('wood','946c49')
h.material('wood_dark','755239')
h.material('wood_edge','b58c61')
h.material('plaster','e8dcc4')
h.material('wainscot','a27c56')
h.material('brass','c49a53',metallic=.18)
h.material('window_view','ffffff','harbour-view',.5)
roles={'wood_light':'oak','oak_light':'oak','wood_dark':'wood_dark','oak':'wood',
       'limewash':'plaster','timber_panels':'wainscot','gold':'brass','window_warm':'window_view'}
for o in list(bpy.context.scene.objects):
    if o.type!='MESH': continue
    # These are the only intentionally replaced pieces. The authored shell is
    # opened and edited; it is never reinitialised from its original recipe.
    if o.name.startswith(('Floorboard','Board beside hatch','Floor slab','Cut floor edge')):
        bpy.data.objects.remove(o,do_unlink=True); continue
    for slot in o.material_slots:
        if slot.material and slot.material.name in roles:
            slot.material=h.M[roles[slot.material.name]]
    if any(s.material==h.M['oak'] for s in o.material_slots): h.wood_uv(o)

# A proper dark opening instead of solid flooring below the stair treads.
for name,lo,hi in [
    ('Floor structure west',(-.62,.78,-.62),(2.4,1.85,-.03)),
    ('Floor structure east',(3.6,.78,-.62),(11.6,1.85,-.03)),
    ('Floor structure rear',(-.62,1.85,-.62),(11.6,9.6,-.03)),
]:
    h.box(name,tuple((a+b)/2 for a,b in zip(lo,hi)),tuple(b-a for a,b in zip(lo,hi)),'wood_dark',.012)

# Calm honey boards, with real staggered end joints and grain following their
# length. Each plank samples a different quiet region of the new painting.
for col in range(24):
    x0=-.5+col*.5; x1=x0+.5
    cuts=[.88]+[v for v in [1.6+(col%3)*.93,4.6+(col%3)*.93,7.6+(col%3)*.93] if .88<v<9.5]+[9.5]
    for y0,y1 in zip(cuts,cuts[1:]):
        patches=[]
        if y0<1.85 and x1>2.4 and x0<3.6:
            if x0<2.4: patches.append((x0,2.4,y0,min(y1,1.85)))
            if x1>3.6: patches.append((3.6,x1,y0,min(y1,1.85)))
            if y1>1.85: patches.append((x0,x1,1.85,y1))
        else: patches.append((x0,x1,y0,y1))
        for xa,xb,ya,yb in patches:
            h.box('Staggered honey floorboard',((xa+xb)/2,(ya+yb)/2,-.005),(xb-xa-.014,yb-ya-.014,.05),'oak',.008,1)

# New picture planes sit just in front of the existing wall/reveal; the timber
# mullions are retained, so they still shade and outline the view naturally.
port=bpy.data.objects.get('Porthole glass')
if port:
    # Circular fan with landscape UVs, normal toward the inside of the room.
    cx,cy,cz=port.location; r=.56
    bpy.data.objects.remove(port,do_unlink=True)
    pts=[(cx,cy-.04,cz)]+[(cx+math.cos(a*math.tau/48)*r,cy-.04,cz+math.sin(a*math.tau/48)*r) for a in range(48)]
    mesh=bpy.data.meshes.new('Porthole painted harbour'); mesh.from_pydata(pts,[],[(0,1+k,1+(k+1)%48) for k in range(48)]); mesh.update()
    o=bpy.data.objects.new('Porthole harbour view',mesh); bpy.context.scene.collection.objects.link(o); h.put(o,'window_view')
    uv=mesh.uv_layers.new(name='Window landscape')
    for p in mesh.polygons:
        for li in p.loop_indices:
            v=mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv=((v.x-cx)/(r*2)*.72+.5,(v.z-cz)/(r*2)*.72+.5)
glass=bpy.data.objects.get('Dormer glass')
if glass:
    # The original plate remains the geometrical authority, with deliberate UVs.
    uv=glass.data.uv_layers.active
    coords=[v.co for v in glass.data.vertices]
    xmin,xmax=min(v.x for v in coords),max(v.x for v in coords)
    zmin,zmax=min(v.z for v in coords),max(v.z for v in coords)
    for p in glass.data.polygons:
        for li in p.loop_indices:
            v=glass.data.vertices[glass.data.loops[li].vertex_index].co
            uv.data[li].uv=((v.x-xmin)/(xmax-xmin),(v.z-zmin)/(zmax-zmin))

# A few timber details are silhouette work, not additional noisy texture.
for x in (3.6,8.0):
    h.box('North post chamfer highlight',(x-.065,9.405,1.49),(.02,.018,2.75),'wood_edge',.005)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
NOTE.write_text(json.dumps({'date':'2026-10-27','source_before_sha256':before,'preserved_source':BACKUP.name,'edit_record':'art/source/world/sparks-loft/v1/refine_shell.py','textures':'art/source/world/sparks-loft/v1/prompts.json','note':'Deliberate source edit: existing walls, windows, gable and rafters retained; bespoke painted finish, staggered floor joints and open stairwell.'},indent=2)+'\n')
print('Refined adopted loft shell; original preserved at',BACKUP)
