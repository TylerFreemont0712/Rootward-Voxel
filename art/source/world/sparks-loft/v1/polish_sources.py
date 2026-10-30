"""Deliberate pre-review edits of saved masters; never reseeds an asset."""
from pathlib import Path
import importlib.util
import json
import bpy
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
spec=importlib.util.spec_from_file_location('loft_helpers',HERE/'author.py')
h=importlib.util.module_from_spec(spec); spec.loader.exec_module(h)

shell=ROOT/'art/source/world/loft-shell/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(shell))
bpy.context.preferences.filepaths.save_version=0
pieces=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name.startswith('Staggered honey floorboard')]
if len(pieces)>1:
    bpy.ops.object.select_all(action='DESELECT')
    for o in pieces:o.select_set(True)
    bpy.context.view_layer.objects.active=pieces[0]
    bpy.ops.object.join(); bpy.context.object.name='Staggered honey floorboards'
    bpy.context.object['individual_planks']=len(pieces)
    bpy.ops.wm.save_as_mainfile(filepath=str(shell))

cable=ROOT/'art/source/world/loft-cable/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(cable))
bpy.context.preferences.filepaths.save_version=0
h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY')
old=next(o for o in bpy.context.scene.objects if o.type=='MESH')
h.M['cable']=old.data.materials[0]
bpy.data.objects.remove(old,do_unlink=True)
h.curve('Shelf to desk cable',[(0,0,2.27),(-.45,.18,2.18),(-.45,.85,1.60),(-.25,1.60,1.23),(.30,2.20,1.18),(.60,2.55,1.22)],.017,'cable')
bpy.ops.wm.save_as_mainfile(filepath=str(cable))
(HERE/'source-polish.json').write_text(json.dumps({'date':'2026-10-27','record':'polish_sources.py','edits':['Joined the existing new floorboard meshes for low draw cost without changing their triangles.','Fit the new cable mesh to the shelf and tape-reader placements in the area document.'],'note':'Saved editable masters remain authority; normal world build follows.'},indent=2)+'\n')
