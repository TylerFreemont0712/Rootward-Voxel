"""Follow-up native edits to the saved v2 sources: parcel Pip and eye-blink metadata.
Keeps a pre-edit source copy and refuses a second application.
"""
import importlib.util
import json
import hashlib
import math
from pathlib import Path
import shutil

import bmesh
import bpy
from mathutils import Matrix,Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('edit',HERE/'refine_sources.py');e=importlib.util.module_from_spec(spec);spec.loader.exec_module(e)

for asset in ['robot-pip','robot-wick']:
    source=e.ROOT/'art/source/world'/asset/'v2/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if bpy.context.scene.get('robot_finish_pass'):raise RuntimeError('Finish pass already applied. Edit the saved source instead.')
    backup=source.with_name('model.pre-finish.blend')
    if backup.exists():raise RuntimeError('Finish backup exists; inspect rather than overwriting it.')
    shutil.copy2(source,backup)
    e.ROOT_OBJECT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.parent is None)
    e.M={key:bpy.data.materials['robot_'+key] for key in ['brass','gold','cream','teal','paper_edge','paper']}
    if asset=='robot-pip':
        for obj in list(bpy.context.scene.objects):
            if obj.get('part')=='satchel':bpy.data.objects.remove(obj,do_unlink=True)
        # Remove the original four letters while retaining the card at the routine slot.
        for obj in list(bpy.context.scene.objects):
            if obj.type!='MESH' or obj.get('part')!='body' or not any(m and m.name.startswith(('robot_paper','robot_green_paper')) for m in obj.data.materials):continue
            bm=bmesh.new();bm.from_mesh(obj.data)
            selected=[v for v in bm.verts if (obj.matrix_world@v.co).z<.60]
            bmesh.ops.delete(bm,geom=selected,context='VERTS');bm.to_mesh(obj.data);bm.free()
            # Rotate the remaining slot-card seam with its tilted paper, rather than leaving a floating flap.
            if any(m and m.name.startswith('robot_paper_edge') for m in obj.data.materials):
                center=Vector((0,-.273,.923));rotation=Matrix.Rotation(math.radians(30),3,'X')
                for v in obj.data.vertices:
                    world=obj.matrix_world@v.co
                    if world.z>.85:v.co=obj.matrix_world.inverted()@(center+rotation@(world-center))
        e.material('parcel','BB9360',0,.87);e.material('parcel_green','75864C',0,.85)
        for i,(x,z) in enumerate([(-.087,.481),(.087,.481),(-.087,.385),(.087,.385)]):
            e.box('Wrapped parcel '+str(i),(x,-.18,z),(.135,.11,.067),'parcel_green' if i==2 else 'parcel',.007)
            e.curve('Parcel vertical twine',[(x,-.13,z+.035),(x,-.238,z+.035),(x,-.238,z-.035),(x,-.13,z-.035)],.0018,'paper_edge')
            e.curve('Parcel horizontal twine',[(x-.069,-.20,z),(x-.069,-.238,z),(x+.069,-.238,z),(x+.069,-.20,z)],.0018,'paper_edge')
        for obj in list(bpy.context.scene.objects):
            if obj.type!='MESH' or obj.get('part') not in ['left_arm','right_arm']:continue
            if not any(m and m.name.startswith('robot_red') for m in obj.data.materials):continue
            index=len(obj.data.materials);obj.data.materials.append(e.M['brass'])
            side=1 if obj.get('part')=='left_arm' else -1;hand=Vector((side*.35,-.145,.58))
            for polygon in obj.data.polygons:
                if (obj.matrix_world@polygon.center-hand).length>.077:polygon.material_index=index
        for side in [-1,1]:e.torus('Cream shoulder washer',(side*.273,0,.78),.045,.007,'cream','X','left_arm' if side>0 else 'right_arm')
    else:
        glass=bpy.data.materials.get('robot_glass')
        glass.node_tree.nodes.get('Principled BSDF').inputs['Emission Strength'].default_value=.55
        glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.48
        flame=e.material('lantern_spark','FFE6A1',0,.3,1.7)
        for obj in bpy.context.scene.objects:
            if obj.type=='MESH' and obj.get('part')=='lantern' and any(m and m.name.startswith('robot_eyes') for m in obj.data.materials):
                obj.data.materials.clear();obj.data.materials.append(flame)
    e.consolidate()
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.get('part')=='head' and any(m and m.name.startswith('robot_eyes') for m in obj.data.materials):obj['blink_eyes']=True
    bpy.context.scene['robot_finish_pass']='2026-10-29 parcels and independent spark-eye blink'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(source))
    record={'asset':asset,'date':'2026-10-29','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':'model.pre-finish.blend','backup_sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),'edit_record':str(Path(__file__).relative_to(e.ROOT)),'edit_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'note':'User removed Pip satchel and requested compartment parcels; tagged eye-only geometry for cosmetic blink. Previous v2 source preserved.'}
    (source.parent/'finish-pass.json').write_text(json.dumps(record,indent=2)+'\n')
