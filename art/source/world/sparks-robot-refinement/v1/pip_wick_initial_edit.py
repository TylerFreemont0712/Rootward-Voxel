"""Deliberate v1 -> v2 source edits for Pip/Wick; NEVER an adopted-source regenerator.

Opens the existing Blender source, keeps its root and drive-wheel objects/pivots, replaces
the early proxy shells with the approved concept forms, and saves a NEW editable version.
Refuses existing v2 sources. Future edits belong in those saved .blend files.
"""
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
ASSETS = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['robot-pip', 'robot-wick']
M = {}
ROOT_OBJECT = None


def linear(hex_value):
    values = [int(hex_value[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v < .04045 else ((v + .055) / 1.055) ** 2.4 for v in values) + (1,)


def material(name, colour, metal=0, rough=.45, emission=0):
    mat = bpy.data.materials.new('robot_' + name)
    mat.diffuse_color = linear(colour)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = linear(colour)
    shader.inputs['Metallic'].default_value = metal
    shader.inputs['Roughness'].default_value = rough
    if emission:
        shader.inputs['Emission Color'].default_value = linear(colour)
        shader.inputs['Emission Strength'].default_value = emission
    M[name] = mat
    return mat


def painted(name, colour, rough=.45, cloth=False):
    """Bake a subtle Blender-native enamel/cloth colour study, packed into the source and GLB."""
    mat = material(name, colour, .08 if not cloth else 0, rough)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader, output = nodes.get('Principled BSDF'), nodes.get('Material Output')
    uv = nodes.new('ShaderNodeTexCoord')
    noise = nodes.new('ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 34 if cloth else 9
    noise.inputs['Detail'].default_value = 2
    links.new(uv.outputs['UV'], noise.inputs['Vector'])
    ramp = nodes.new('ShaderNodeValToRGB')
    base = linear(colour)
    ramp.color_ramp.elements[0].color = tuple(c * .82 for c in base[:3]) + (1,)
    ramp.color_ramp.elements[1].color = tuple(min(1, c * 1.055) for c in base[:3]) + (1,)
    links.new(noise.outputs['Fac'], ramp.inputs[0])
    emit = nodes.new('ShaderNodeEmission')
    links.new(ramp.outputs['Color'], emit.inputs['Color'])
    links.new(emit.outputs[0], output.inputs['Surface'])
    image = bpy.data.images.new('painted_' + name, width=256, height=256, alpha=False)
    target = nodes.new('ShaderNodeTexImage')
    target.image = image
    nodes.active = target
    bpy.ops.mesh.primitive_plane_add(size=2)
    plane = bpy.context.object
    plane.data.materials.append(mat)
    bpy.context.scene.render.engine = 'CYCLES'
    bpy.context.scene.cycles.samples = 1
    bpy.ops.object.bake(type='EMIT', margin=0)
    texture_path = HERE / 'textures' / (name + '.png')
    texture_path.parent.mkdir(exist_ok=True)
    image.filepath_raw = str(texture_path)
    image.file_format = 'PNG'
    image.save()
    image.pack()
    bpy.data.objects.remove(plane, do_unlink=True)
    links.new(target.outputs['Color'], shader.inputs['Base Color'])
    links.new(shader.outputs[0], output.inputs['Surface'])
    return mat


def finish(obj, name, mat, group='body', smooth=True):
    obj.name = name
    obj.parent = ROOT_OBJECT
    obj['part'] = group
    obj.data.materials.clear()
    obj.data.materials.append(M[mat])
    if smooth:
        for poly in obj.data.polygons:poly.use_smooth = True
    return obj


def box(name, at, size, mat, bevel=.015, group='body'):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Rounded painted edges', 'BEVEL')
        mod.width, mod.segments = bevel, 4
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj = finish(obj, name, mat, group)
    normals = obj.modifiers.new('Weighted corner normals', 'WEIGHTED_NORMAL')
    normals.keep_sharp = True
    bpy.ops.object.modifier_apply(modifier=normals.name)
    return obj


def sphere(name, at, scale, mat, group='body'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1, location=at)
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, name, mat, group)


def tube(name, start, end, radius, mat, group='body', radius_end=None):
    a, b = Vector(start), Vector(end)
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=radius, radius2=radius if radius_end is None else radius_end, depth=(b-a).length, location=(a+b)/2)
    obj = bpy.context.object
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, name, mat, group)


def torus(name, at, radius, thickness, mat, axis='Z', group='body', scale=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=40, minor_segments=8, location=at, major_radius=radius, minor_radius=thickness)
    obj = bpy.context.object
    if axis=='Y':obj.rotation_euler.x=math.pi/2
    if axis=='X':obj.rotation_euler.y=math.pi/2
    if scale:obj.scale=scale
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj,name,mat,group)


def curve(name, points, radius, mat, group='body'):
    data = bpy.data.curves.new(name,'CURVE')
    data.dimensions, data.bevel_depth, data.bevel_resolution = '3D', radius, 2
    spline = data.splines.new('BEZIER')
    spline.bezier_points.add(len(points)-1)
    for vert,point in zip(spline.bezier_points,points):
        vert.co=point
        vert.handle_left_type=vert.handle_right_type='AUTO'
    obj=bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    obj.select_set(False)
    return finish(obj,name,mat,group)


def lathe(name, at, profile, mat, group='body', exponent=1, segments=48):
    vertices,faces=[],[]
    for z,rx,ry in profile:
        for i in range(segments):
            angle=math.tau*i/segments
            x=math.copysign(abs(math.cos(angle))**exponent,math.cos(angle))*rx
            y=math.copysign(abs(math.sin(angle))**exponent,math.sin(angle))*ry
            vertices.append((at[0]+x,at[1]+y,at[2]+z))
    for ring in range(len(profile)-1):
        for i in range(segments):
            j=(i+1)%segments
            faces.append((ring*segments+i,ring*segments+j,(ring+1)*segments+j,(ring+1)*segments+i))
    faces += [tuple(reversed(range(segments))),tuple((len(profile)-1)*segments+i for i in range(segments))]
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    uv=mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            index=mesh.loops[li].vertex_index
            uv.data[li].uv=((index%segments)/segments,(index//segments)/max(1,len(profile)-1))
    obj=bpy.data.objects.new(name,mesh)
    bpy.context.scene.collection.objects.link(obj)
    return finish(obj,name,mat,group)


def subtract(obj, at, size):
    cutter=box('temporary opening',at,size,'ink',.008)
    bpy.context.view_layer.objects.active=obj
    modifier=obj.modifiers.new('Real recessed opening','BOOLEAN')
    modifier.operation,modifier.object='DIFFERENCE',cutter
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter,do_unlink=True)


def screws(centre, width, height, y, group='body'):
    for x in (-width/2,width/2):
        for z in (-height/2,height/2):
            sphere('Brass panel rivet',(centre[0]+x,y,centre[2]+z),(.009,.006,.009),'brass',group)


def face(z, y, radius, group='head'):
    tube('Face gasket',(0,y+.006,z),(0,y-.008,z),radius*1.07,'ink',group)
    sphere('Convex amber spark window',(0,y-.016,z),(radius,.028,radius),'amber',group)
    torus('Brass face bezel',(0,y-.02,z),radius,.013,'brass','Y',group)
    torus('Inner face highlight',(0,y-.029,z),radius*.94,.004,'gold','Y',group)
    for side in (-1,1):sphere('Oval spark eye',(side*radius*.34,y-.044,z+.006),(radius*.17,.009,radius*.30),'eyes',group)


def envelope(name, at, width=.13, height=.065, mat='paper', group='body'):
    obj=box(name,at,(width,.012,height),mat,.002,group)
    x,y,z=at
    curve(name+' flap',[(x-width*.47,y-.007,z+height*.43),(x,y-.008,z-height*.10),(x+width*.47,y-.007,z+height*.43)],.0018,'paper_edge',group)
    return obj


def wheel(name, at, radius, width, old_name=None):
    # Keep the adopted drive-wheel objects; replace their proxy mesh in the new source version.
    obj=bpy.data.objects.get(old_name or name)
    old_hub=bpy.data.objects.get((old_name or name)+'_hub')
    mesh_obj=lathe('temporary tyre',(0,0,0),[(-width/2,radius*.56,radius*.56),(-width/2,radius*.87,radius*.87),(-width*.35,radius*.98,radius*.98),(0,radius,radius),(width*.35,radius*.98,radius*.98),(width/2,radius*.87,radius*.87),(width/2,radius*.56,radius*.56)],'rubber')
    # lathe is Z-axis; bake a quarter turn into its mesh so the object pivot remains X-axis.
    from mathutils import Matrix
    mesh_obj.data.transform(Matrix.Rotation(math.pi/2,4,'Y'))
    if obj:
        obj.data=mesh_obj.data
        bpy.data.objects.remove(mesh_obj,do_unlink=True)
    else:obj=mesh_obj
    obj.name,obj.location,obj.parent=name,at,ROOT_OBJECT
    obj['wheel_radius']=radius
    obj['part']='drive_wheel' if radius>.09 else 'caster'
    hub=tube('temporary hub',(-width*.54,0,0),(width*.54,0,0),radius*.61,'brass')
    if old_hub:
        old_hub.data=hub.data
        bpy.data.objects.remove(hub,do_unlink=True)
        hub=old_hub
    hub.name,hub.location,hub.parent=name+'_hub',at,ROOT_OBJECT
    hub['wheel_radius']=radius
    hub['part']='wheel_hub'
    for side in (-1,1):
        torus('Tyre sidewall seam',(at[0]+side*width*.48,at[1],at[2]),radius*.82,.0035,'rubber_edge','X',name)
        sphere('Rounded axle cap',(at[0]+side*width*.57,at[1],at[2]),(.012,radius*.32,radius*.32),'gold',name)
    # Wheel details join their original wheel object below, sharing its exact pivot.
    return obj,hub


def arm(side, shoulder, elbow, hand, colour='brass'):
    group='left_arm' if side>0 else 'right_arm'
    sphere('Shoulder ball',shoulder,(.046,.046,.046),'brass',group)
    tube('Upper arm',shoulder,elbow,.026,colour,group)
    sphere('Elbow bearing',elbow,(.032,.032,.032),'brass',group)
    tube('Forearm',elbow,hand,.022,colour,group)
    sphere('Enamel mitten',hand,(.057,.048,.060),'red' if colour=='red' else 'teal',group)
    sphere('Mitten thumb',(hand[0]-side*.035,hand[1]-.022,hand[2]+.025),(.027,.026,.032),'red' if colour=='red' else 'teal',group)


def pip():
    wheel('wheel_l',(-.265,0,.145),.145,.10,'wheel_fl')
    wheel('wheel_r',(.265,0,.145),.145,.10,'wheel_fr')
    wheel('wheel_c',(0,.215,.055),.055,.045)
    box('Rounded teal rolling chassis',(0,0,.215),(.52,.43,.15),'teal',.065)
    box('Cream chassis rim',(0,-.005,.282),(.48,.39,.065),'cream',.028)
    shell=box('Rounded postbox shell',(0,0,.625),(.50,.42,.69),'red',.065)
    subtract(shell,(0,-.21,.435),(.365,.18,.225))
    subtract(shell,(0,-.213,.936),(.265,.105,.052))
    box('Dark cubby back',(0,-.129,.435),(.349,.012,.209),'ink',.008)
    box('Postal shelf',(0,-.208,.435),(.351,.16,.015),'red_dark',.003)
    box('Postal divider',(0,-.208,.435),(.015,.16,.206),'red_dark',.003)
    for index,(x,z) in enumerate([(-.087,.481),(.087,.481),(-.087,.385),(.087,.385)]):
        envelope('Sorted envelope '+str(index),(x,-.223,z),.143,.069,'green_paper' if index==2 else 'paper')
    box('Brass face mount',(0,-.217,.711),(.307,.025,.302),'brass',.018,'head')
    box('Red recessed face surround',(0,-.234,.711),(.280,.012,.278),'red_dark',.012,'head')
    face(.711,-.25,.125)
    screws((0,0,.711),.263,.258,-.25,'head')
    box('Slot shadow',(0,-.214,.936),(.25,.01,.043),'ink',.004)
    for x in (-.14,.14):box('Slot cheek',(x,-.231,.936),(.02,.025,.074),'red_dark',.006)
    box('Slot lintel',(0,-.233,.969),(.285,.035,.015),'red',.006)
    letter=envelope('Letter in routine slot',(0,-.273,.923),.20,.082)
    letter.rotation_euler.x=math.radians(30)
    lathe('Domed postal lid',(0,0,0),[(.974,.28,.24),(.992,.286,.246),(1.018,.28,.24),(1.066,.245,.213),(1.103,.18,.156),(1.12,.085,.074),(1.124,.018,.016)],'red',exponent=.66)
    lathe('Lid dark seam',(0,0,0),[(.971,.279,.239),(.984,.282,.242)],'red_dark',exponent=.66)
    tube('Finial base',(0,0,1.12),(0,0,1.15),.028,'brass')
    sphere('Postal finial',(0,0,1.173),(.038,.038,.038),'gold')
    for side in (-1,1):arm(side,(side*.27,0,.78),(side*.34,-.025,.65),(side*.35,-.145,.58),'red')
    # Open cloth satchel: outer and inner walls, with the mouth deliberately uncapped.
    bag=lathe('Open canvas satchel',(.385,.045,0),[(.36,.055,.105),(.385,.08,.14),(.53,.085,.16),(.66,.067,.145),(.66,.053,.131),(.535,.068,.143),(.395,.046,.09)],'canvas','satchel',exponent=.7)
    for x in (.32,.45):
        curve('Folded satchel cuff',[(x,-.09,.66),(x,.045,.675),(x,.18,.66)],.012,'canvas_edge','satchel')
    curve('Satchel hanging strap',[(.28,-.02,.85),(.37,-.095,.75),(.445,-.075,.64)],.012,'leather','satchel')
    curve('Satchel rear strap',[(.28,.08,.85),(.37,.19,.75),(.44,.17,.64)],.012,'leather','satchel')
    box('Satchel front pocket',(.466,.045,.495),(.018,.20,.165),'canvas',.012,'satchel')
    curve('Pocket stitching',[(.477,-.048,.56),(.477,-.048,.425),(.477,.135,.425),(.477,.135,.56)],.002,'canvas_edge','satchel')
    for y in (-.074,.164):sphere('Bag cuff stud',(.455,y,.64),(.007,.009,.009),'brass','satchel')
    for i in range(3):
        letter=envelope('Satchel letter '+str(i),(.385,.01+i*.045,.683+i*.012),.09,.09,group='satchel')
        letter.rotation_euler.z=math.radians(90)
    # Rear cover is recessed, with real slats and tiny hinges; no second face on the back.
    box('Rear cover dark seal',(0,.212,.59),(.367,.018,.405),'red_dark',.025)
    box('Rear service cover',(0,.224,.59),(.34,.018,.38),'red',.022)
    for z in (.51,.54,.57):box('Rear ventilation slot',(0,.237,z),(.11,.008,.009),'ink',.004)
    for z in (.68,.72):box('Rear hinge',(-.18,.225,z),(.018,.026,.055),'brass',.005)
    screws((0,0,.59),.28,.31,.239)


def wick():
    wheel('wheel_l',(-.225,.015,.16),.16,.105)
    wheel('wheel_r',(.225,.015,.16),.16,.105)
    wheel('wheel_c',(0,-.223,.052),.052,.042)
    box('Cream low rolling shell',(0,.01,.29),(.405,.35,.26),'cream',.085)
    box('Teal undercarriage',(0,.01,.205),(.42,.35,.105),'teal',.045)
    for side in (-1,1):
        # Static wheel arches do not roll with the tyre.
        curve('Teal fender',[(side*.205,.17,.18),(side*.205,.145,.29),(side*.205,0,.355),(side*.205,-.14,.29),(side*.205,-.16,.18)],.022,'teal')
    sphere('Caster mounting boss',(0,-.173,.24),(.042,.035,.036),'teal')
    for side in (-1,1):curve('Brass caster fork',[(0,-.19,.24),(side*.029,-.224,.15),(side*.029,-.223,.052)],.009,'brass')
    lathe('Teal waist receiver',(0,0,0),[(.409,.105,.105),(.429,.137,.124),(.47,.13,.117),(.49,.12,.108)],'teal')
    lathe('Tapered cream torso',(0,0,0),[(.47,.12,.108),(.50,.132,.12),(.67,.125,.115),(.88,.105,.098),(1.015,.085,.083),(1.035,.072,.073)],'cream')
    torus('Torso lower enamel seam',(0,0,.493),.127,.008,'teal')
    box('Torso access plate',(0,-.119,.673),(.113,.018,.107),'brass',.009)
    screws((0,0,.673),.087,.079,-.132)
    tube('Brass neck',(0,0,1.029),(0,0,1.072),.052,'brass','head')
    torus('Teal neck collar',(0,0,1.062),.068,.011,'teal',group='head')
    sphere('Cream lantern head',(0,0,1.205),(.168,.151,.155),'cream','head')
    face(1.205,-.142,.112)
    lathe('Flared teal lantern cap',(0,0,0),[(1.329,.225,.225),(1.34,.23,.23),(1.35,.21,.21),(1.383,.164,.164),(1.433,.112,.112),(1.47,.067,.067),(1.48,.05,.05)],'teal','head')
    torus('Hat rolled edge',(0,0,1.338),.224,.008,'teal_dark',group='head')
    tube('Hat finial seat',(0,0,1.476),(0,0,1.501),.026,'brass','head')
    sphere('Hat finial',(0,0,1.528),(.032,.032,.032),'gold','head')
    arm(1,(.115,0,.974),(.23,-.035,.84),(.313,-.035,.897))
    arm(-1,(-.115,0,.974),(-.205,-.035,.827),(-.223,-.105,.68))
    # Own LEFT is Blender +X, since the robot faces Blender -Y. No mirrored pole.
    x,y=.335,-.035
    tube('Left-hand telescoping pole',(x,y,.397),(x,y,1.826),.012,'brass','pole')
    for z in (.43,.80,1.18,1.55):tube('Pole sleeve',(x,y,z),(x,y,z+.046),.019,'gold','pole')
    torus('Left mitten pole grip',(x,y,.898),.023,.011,'teal',group='left_arm')
    tube('Pole lower tool cap',(x,y,.39),(x,y,.43),.019,'teal','pole')
    sphere('Upper pole hinge',(x,y,1.833),(.027,.027,.027),'brass','pole')
    tube('Bent brass lamp arm',(x,y,1.834),(.482,y,1.916),.014,'brass','pole')
    sphere('Lantern hook knuckle',(.487,y,1.915),(.026,.026,.026),'gold','pole')
    tube('Lantern hanging link',(.487,y,1.91),(.487,y,1.862),.011,'brass','pole')
    lathe('Carried lantern glass',(.487,y,0),[(1.61,.055,.055),(1.636,.065,.065),(1.78,.088,.088),(1.805,.088,.088)],'glass','lantern',segments=6)
    for i in range(6):
        angle=math.tau*i/6
        tube('Lantern brass glazing bar',(.487+math.cos(angle)*.055,y+math.sin(angle)*.055,1.61),(.487+math.cos(angle)*.09,y+math.sin(angle)*.09,1.806),.007,'brass','lantern')
    lathe('Carried lantern teal roof',(.487,y,0),[(1.806,.117,.117),(1.819,.119,.119),(1.84,.083,.083),(1.865,.032,.032)],'teal','lantern',segments=32)
    torus('Carried lantern brass foot',(.487,y,1.61),.055,.009,'brass',group='lantern')
    sphere('Lantern bottom finial',(.487,y,1.585),(.017,.017,.024),'gold','lantern')
    sphere('Warm lantern spark',(.487,y,1.702),(.025,.025,.059),'eyes','lantern')
    box('Rear torso cover',(0,.113,.70),(.10,.012,.13),'brass',.006)
    for z in (.675,.70,.725):box('Rear torso vent',(0,.122,z),(.064,.005,.006),'ink',.002)


def consolidate():
    """Join static surfaces by semantic part/material, keeping drive pivots independently editable."""
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type!='MESH' or obj.name.startswith('wheel'):continue
        key=(str(obj.get('part','body')),obj.data.materials[0].name)
        groups.setdefault(key,[]).append(obj)
    for (part,mat),objects in groups.items():
        # Wheel sidewall/hub details share the original axle pivot; no secondary roll node.
        pivot=bpy.data.objects.get(part) if part.startswith('wheel') else None
        if pivot:objects.append(pivot)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=pivot or objects[0]
        if len(objects)>1:bpy.ops.object.join()
        obj=bpy.context.object
        if not pivot:obj.name=part+'__'+mat
        obj['part']=part
    bpy.ops.object.select_all(action='DESELECT')


def main(asset):
    global ROOT_OBJECT,M
    if asset not in ['robot-pip','robot-wick']:raise RuntimeError('Only the two explicitly requested robots may be edited.')
    source=ROOT/'art/source/world'/asset/'v1/model.blend'
    output=ROOT/'art/source/world'/asset/'v2/model.blend'
    if output.exists():raise RuntimeError('v2 source already exists. Edit that saved source; this one-time revision refuses overwrite.')
    original_hash=hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    ROOT_OBJECT=next(obj for obj in bpy.context.scene.objects if obj.type=='EMPTY' and obj.parent is None)
    for obj in list(bpy.context.scene.objects):
        if obj==ROOT_OBJECT:continue
        if obj.type=='MESH' and obj.name.startswith('wheel') and (asset!='robot-pip' or obj.name.startswith(('wheel_fl','wheel_fr'))):continue
        bpy.data.objects.remove(obj,do_unlink=True)
    M={}
    painted('red','D8422E',.32)
    painted('cream','F4E4BF',.42)
    painted('teal','167C80',.32)
    painted('canvas','D8C8A1',.9,True)
    for name,colour,metal,rough,emission in [
        ('red_dark','9C281F',.08,.42,0),('teal_dark','105156',.12,.4,0),('brass','C48A2D',.62,.31,0),('gold','E8AF3F',.60,.26,0),
        ('ink','242B2B',.05,.65,0),('rubber','303638',0,.82,0),('rubber_edge','505354',0,.7,0),('amber','F6AC28',.06,.24,.18),
        ('eyes','FFF0B4',0,.3,1.1),('paper','F3E7C6',0,.85,0),('paper_edge','9D7848',0,.8,0),('green_paper','688A45',0,.85,0),
        ('canvas_edge','B5A27B',0,.9,0),('leather','997740',0,.72,0)]:material(name,colour,metal,rough,emission)
    glass=material('glass','F7B94C',.05,.19,.16)
    glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.32
    glass.surface_render_method='DITHERED'
    if asset=='robot-pip':pip()
    else:wick()
    consolidate()
    bpy.context.scene['rootward_source']='Editable adopted model; v2 concept refinement. Open this file for further edits; never regenerate.'
    bpy.context.scene['concept_reference']='docs/concept/v0.72/art/robots/'+asset.removeprefix('robot-')+'-sheet.png'
    bpy.context.scene.unit_settings.system='METRIC'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all()
    output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    if hashlib.sha256(source.read_bytes()).hexdigest()!=original_hash:raise RuntimeError('Previous adopted source changed unexpectedly.')
    record={'asset':asset,'date':'2026-10-29','previous_source':str(source.relative_to(ROOT)),'previous_source_sha256':original_hash,
            'source':str(output.relative_to(ROOT)),'source_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),
            'edit_record':str(Path(__file__).relative_to(ROOT)),'edit_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'note':'Deliberate new source revision after approved robot concept. Existing root/drive-wheel objects retained, proxy shells replaced, wheels resized with axle pivots preserved. Future edits use saved v2 model.blend.'}
    (output.parent/'provenance.json').write_text(json.dumps(record,indent=2)+'\n')
    print('Saved deliberately refined source:',output)


for selected_asset in ASSETS:main(selected_asset)
