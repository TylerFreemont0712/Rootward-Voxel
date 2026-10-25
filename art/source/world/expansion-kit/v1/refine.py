"""Deliberate first review edits to the six NEW Blender sources only.
History of the handoff, not the normal build command. Refuses a second run.
"""
import math
from pathlib import Path
import bpy
from mathutils import Vector, Euler

ROOT=Path(__file__).resolve().parents[5]
IDS=['hearth-oak','ridge-cedar','river-willow','hearth-house','lantern-loft','brook-mill']


def new_mesh(name,verts,faces,material,part):
    data=bpy.data.meshes.new(name)
    data.from_pydata(verts,[],faces)
    data.materials.append(bpy.data.materials[material])
    data.update()
    obj=bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    obj['part']=part
    return obj


def box(name,at,size,material,rotation=(0,0,0),part='Roof monitor'):
    x,y,z=[a/2 for a in size]
    r=Euler(rotation).to_matrix()
    verts=[tuple(Vector(at)+r@Vector(p)) for p in [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]]
    obj=new_mesh(name,verts,[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],material,part)
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Hand cut corners','BEVEL');mod.width=.018;mod.segments=1
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def uv(data):
    layer=data.uv_layers.active or data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        axis=max(range(3),key=lambda k:abs(poly.normal[k]))
        for li in poly.loop_indices:
            co=data.vertices[data.loops[li].vertex_index].co
            layer.data[li].uv=(co.y,co.z) if axis==0 else ((co.x,co.z) if axis==1 else (co.x,co.y))


def trees(asset):
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')=='Canopy']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join()
    obj=bpy.context.view_layer.objects.active
    prefix={'hearth-oak':'leaf','ridge-cedar':'cedar','river-willow':'willow'}[asset]
    names=[prefix,prefix+'_light',prefix+'_dark']
    obj.data.materials.clear()
    for name in names:obj.data.materials.append(bpy.data.materials[name])
    for poly in obj.data.polygons:
        c=poly.center
        field=math.sin(c.x*1.72+c.z*.62)+math.cos(c.y*1.92-c.z*.5)+.4*math.sin(c.x*3+c.y)
        poly.material_index=2 if poly.normal.z<-.4 or field<-1.22 else (1 if field>1.05 else 0)
    # Softer contour edges retain the voxel steps while avoiding hard cube noise.
    mod=obj.modifiers.new('Soft leaf contour','BEVEL')
    mod.width=.016;mod.segments=1;mod.limit_method='ANGLE';mod.angle_limit=.5
    bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.name='Canopy__'+prefix
    obj.data.update()


def loft():
    # Convert the ordinary pitched roof to a broad, broken-pitch gambrel silhouette.
    half=7.65/2
    knee=half*.6
    def profile(x):
        x=abs(x)
        return 2.15-.60*x/knee if x<knee else 1.55*(half-x)/(half-knee)
    for obj in list(bpy.context.scene.objects):
        if obj.type=='MESH' and obj.name.startswith('Roof__'):
            for v in obj.data.vertices:
                v.co.z+=profile(v.co.x)-2.15*(1-abs(v.co.x)/half)
        if obj.name in ['Walls__cream','Walls__plaster_warm']:
            # Existing gables are part of the cream batch; retain them under the new outline.
            pass
    # Fill the broader gable silhouette, with short horizontal timber courses.
    for side in [-1,1]:
        y=side*3.43
        outline=[(-3.425,5.24),(-2.295,6.81),(0,7.28),(2.295,6.81),(3.425,5.24)]
        vv=[(x,y+depth,z) for depth in [-.045,.045] for x,z in outline]
        new_mesh('Gambrel gable infill',vv,[(0,4,3,2,1),(5,6,7,8,9)]+[(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)],'cream','Walls')
        for sign in [-1,1]:
            a=Vector((sign*3.42,y-side*.06,5.25));b=Vector((sign*2.295,y-side*.06,6.81))
            box('Gambrel gable rake',(a+b)/2,(.13,.16,(b-a).length),'timber',(b-a).to_track_quat('Z','Y').to_euler(),'Timber')
        box('Gable collar',(0,y+side*.07,6.72),(4.75,.16,.13),'timber',part='Timber')


def mill():
    # A narrow louvred roof monitor gives the mill its own industrial silhouette.
    z=6.67
    box('Roof monitor body',(0,.30,z+.38),(1.10,1.90,.76),'timber')
    for s in [-1,1]:
        for k in range(5):
            box('Monitor louvre',(s*.57,.30,z+.10+k*.12),(.12,1.75,.085),'oak_edge',(0,s*.22,0))
    rise=.48;half=.84;theta=math.atan2(rise,half)
    for s in [-1,1]:
        box('Monitor teal roof',(s*half/2,.30,z+.76+rise/2),(math.hypot(half,rise)+.04,2.28,.11),'roof_teal',(0,s*theta,0))
        for j in range(5):
            box('Monitor tile seam',(s*half/2,.30-1.12+j*.56,z+.76+rise/2+.04),(math.hypot(half,rise),.025,.035),'roof_teal_hi',(0,s*theta,0))
    box('Monitor ridge',(0,.30,z+1.29),(.18,2.36,.12),'roof_teal_dark')
    # Simple copper weather vane: a broad diamond, no text or logo.
    box('Weather vane stem',(0,.30,z+1.62),(.045,.045,.65),'brass')
    box('Weather vane arrow',(0,.30,z+1.82),(.65,.05,.07),'brass')
    box('Weather vane diamond',(.29,.30,z+1.82),(.22,.05,.22),'brass',(0,math.pi/4,0))


for asset in IDS:
    path=ROOT/f'art/source/world/{asset}/v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(path))
    if bpy.context.scene.get('review_refinement_v1'):
        raise RuntimeError('Already refined; edit Blender source directly: '+asset)
    if asset in IDS[:3]:trees(asset)
    if asset=='lantern-loft':loft()
    if asset=='brook-mill':mill()
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':uv(obj.data)
    bpy.context.scene['review_refinement_v1']='coherent canopy patches, bevelled leaf contours, full UVs; gambrel loft; louvred mill monitor'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    print('REVIEW EDIT SAVED',asset,flush=True)
