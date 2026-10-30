"""Small final edits to saved v2 sources: retain Heron's posed payload and Tally's paper receipt.
Preserves the previous source and refuses repeat application.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import math

import bpy
import bmesh
from mathutils import Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('edit',HERE/'refine_sources.py');e=importlib.util.module_from_spec(spec);spec.loader.exec_module(e)

for asset in ['robot-heron','robot-tally','robot-tender']:
    source=e.ROOT/'art/source/world'/asset/'v2/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if bpy.context.scene.get('work_tool_finish'):raise RuntimeError('Work details already finished; edit the saved source.')
    backup=source.with_name('model.pre-work-details.blend')
    if backup.exists():
        if backup.read_bytes()!=source.read_bytes():raise RuntimeError('Backup differs; inspect before another source edit.')
    else:shutil.copy2(source,backup)
    e.ROOT_OBJECT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.parent is None)
    e.M={key:bpy.data.materials['robot_'+key] for key in ['brass','gold','paper','ink','wood','teal'] if bpy.data.materials.get('robot_'+key)}
    if asset=='robot-heron':
        if 'wood' not in e.M:e.material('wood','976B41',0,.8)
        e.box('Held timber crate',(0,-.425,.665),(.235,.22,.20),'wood',.008,'payload')
        for x in [-.106,.106]:
            for y in [-.526,-.324]:e.box('Crate corner batten',(x,y,.665),(.025,.018,.21),'brass',.004,'payload')
        for z in [.572,.758]:
            e.box('Crate front rail',(0,-.54,z),(.25,.022,.025),'brass',.004,'payload')
            e.box('Crate rear rail',(0,-.314,z),(.25,.022,.025),'brass',.004,'payload')
        for side in [-1,1]:e.curve('Crate suspension sling',[(0,-.40,.845),(side*.105,-.425,.768)],.006,'ink','payload')
        # Cross-brace has a real rectangular section and lies on the front boards.
        a,b=Vector((-.095,-.54,.585)),Vector((.095,-.54,.745))
        obj=e.box('Crate diagonal brace',(a+b)/2,(.018,.018,(b-a).length),'brass',.003,'payload')
        obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    elif asset=='robot-tally':
        for obj in list(bpy.context.scene.objects):
            if obj.type=='MESH' and obj.get('part')=='tray' and any(m and m.name.startswith('robot_paper') for m in obj.data.materials):bpy.data.objects.remove(obj,do_unlink=True)
        points=[(-.218,.53),(-.25,.548),(-.28,.527),(-.31,.493),(-.345,.48)]
        verts=[]
        for y,z in points:verts.extend([(.022,y,z),(.088,y,z)])
        faces=[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(points)-1)]
        mesh=bpy.data.meshes.new('Curled receipt');mesh.from_pydata(verts,[],faces)
        uv=mesh.uv_layers.new()
        for polygon in mesh.polygons:
            for li in polygon.loop_indices:
                vi=mesh.loops[li].vertex_index;uv.data[li].uv=(vi%2,(vi//2)/(len(points)-1))
        obj=bpy.data.objects.new('Curled paper receipt',mesh);bpy.context.scene.collection.objects.link(obj);e.finish(obj,obj.name,'paper','tray')
        bpy.context.view_layer.objects.active=obj
        solid=obj.modifiers.new('Paper thickness','SOLIDIFY');solid.thickness=.0015
        bpy.ops.object.modifier_apply(modifier=solid.name)
        for y,z in [(-.258,.547),(-.28,.532),(-.304,.503)]:e.curve('Printed receipt stroke',[(.033,y,z),(.078,y,z)],.0013,'ink','tray')
    else:
        # Replace the intersecting proxy roof with an inset panel fitted to the actual cream shell.
        for obj in list(bpy.context.scene.objects):
            if obj.type!='MESH' or obj.get('part')!='body':continue
            if any(m and m.name.startswith('robot_teal') for m in obj.data.materials):
                bm=bmesh.new();bm.from_mesh(obj.data)
                bmesh.ops.delete(bm,geom=[v for v in bm.verts if (obj.matrix_world@v.co).z>.55],context='VERTS')
                bm.to_mesh(obj.data);bm.free()
            if any(m and m.name.startswith('robot_brass') for m in obj.data.materials):
                for vert in obj.data.vertices:
                    point=obj.matrix_world@vert.co
                    if point.z>.64:
                        point.z+=.018;vert.co=obj.matrix_world.inverted()@point
        vertices,faces=[],[]
        segments=48
        for r in [.205,.17,.12,.065,.01]:
            for i in range(segments):
                a=i*math.tau/segments;x,y=math.cos(a)*r,math.sin(a)*r*.92
                z=.39+.29*math.sqrt(max(0,1-(x/.333)**2-(y/.307)**2))+.008
                vertices.append((x,y,z))
        for ring in range(4):
            for i in range(segments):
                j=(i+1)%segments
                faces.append((ring*segments+i,(ring+1)*segments+i,(ring+1)*segments+j,ring*segments+j))
        faces.append(tuple(4*segments+i for i in range(segments)))
        mesh=bpy.data.meshes.new('Fitted maintenance cap');mesh.from_pydata(vertices,[],faces);mesh.uv_layers.new()
        obj=bpy.data.objects.new('Flush teal roof panel',mesh);bpy.context.scene.collection.objects.link(obj);e.finish(obj,obj.name,'teal')
    e.consolidate()
    bpy.context.scene['work_tool_finish']='2026-10-29 payload and paper details'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(source))
    (source.parent/'work-tool-pass.json').write_text(json.dumps({'asset':asset,'date':'2026-10-29','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':'model.pre-work-details.blend','backup_sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),'edit_record':str(Path(__file__).relative_to(e.ROOT)),'edit_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
