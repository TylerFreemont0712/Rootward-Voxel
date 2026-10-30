"""Guarded original authoring/design record. Saved Blender files own future edits.

Run in Blender with -- cottage|tree|fence. Export only through world-art.sh.
The cottage is a deliberate finish edit of the adopted reference reconstruction;
the oak and fence are new geometry. No earlier editable source is overwritten.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import sys

import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[5]
KIND=sys.argv[sys.argv.index('--')+1]
IDS={'cottage':'painted-cottage','tree':'painted-oak','fence':'painted-garden-fence'}
ID=IDS[KIND]
HERE=ROOT/'art/source/world'/ID/'v1'
OUTPUT=HERE/'model.blend'
if OUTPUT.exists():raise RuntimeError('Editable source exists. Open model.blend; authoring never overwrites it.')
HERE.mkdir(parents=True,exist_ok=True)
rng=random.Random(261026)
M={}

def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4

def material(name,colour,emission=0):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    rgb=[linear(int(colour[i:i+2],16)/255) for i in [0,2,4]]
    mat.diffuse_color=(*rgb,1)
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value=(*rgb,1)
    bsdf.inputs['Roughness'].default_value=.9
    if emission:
        bsdf.inputs['Emission Color'].default_value=(*rgb,1)
        bsdf.inputs['Emission Strength'].default_value=emission
    M[name]=mat
    return mat

def uv(obj):
    mesh=obj.data;mesh.update();layer=mesh.uv_layers.active or mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        axis=max(range(3),key=lambda i:abs(poly.normal[i]))
        axes=[i for i in range(3) if i!=axis]
        for li in poly.loop_indices:
            p=mesh.vertices[mesh.loops[li].vertex_index].co
            layer.data[li].uv=(p[axes[0]],p[axes[1]])

def put(obj,name,mat,bevel=0):
    obj.name=name
    obj.data.materials.append(M[mat])
    if bevel:
        mod=obj.modifiers.new('Soft hewn edge','BEVEL');mod.width=bevel;mod.segments=1
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    uv(obj)
    return obj

def mesh(name,vertices,faces,mat):
    data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj)
    return put(obj,name,mat)

def box(name,at,size,mat,bevel=.018):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at)
    obj=bpy.context.object;obj.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return put(obj,name,mat,bevel)

def beam(name,a,b,width,mat,depth=None):
    a,b=Vector(a),Vector(b)
    obj=box(name,(a+b)*.5,(width,depth or width,(b-a).length),mat,.014)
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return obj

def taper(name,points,radii,mat,sides=9):
    vertices=[]
    for (x,y,z),radius in zip(points,radii):
        vertices.extend([(x+math.cos(i*math.tau/sides)*radius,y+math.sin(i*math.tau/sides)*radius,z) for i in range(sides)])
    faces=[tuple(reversed(range(sides)))]
    for j in range(len(points)-1):
        for i in range(sides):
            faces.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
    faces.append(tuple(range((len(points)-1)*sides,len(points)*sides)))
    return mesh(name,vertices,faces,mat)

if KIND=='cottage':
    original=ROOT/'art/source/world/reference-cottage/v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(original))
    palette={
        'study_oak':'b37b3d','study_oak_warm':'a66d36','study_oak_light':'c58d4b',
        'study_timber':'725033','study_door_oak':'ae7738','study_endgrain':'bd8b4a',
        'study_endgrain_dark':'755030','study_mortar':'85765e',
        'study_stone':'ccbea0','study_stone_light':'e2d5b5','study_stone_warm':'b9ad92',
        'study_violet':'7564a0','study_violet_light':'9683b7','study_violet_dark':'574b7d',
        'study_tile_edge':'c0acd5','study_clay_under':'453952',
        'study_iron':'363b3b','study_brass':'c1954d','study_glass':'43556d',
        'study_glass_light':'66788e','study_window':'ffcb75',
        'study_recess':'36291e','study_leaf_dark':'35533b','study_leaf':'5d813d',
        'study_leaf_light':'92a94e','study_flower':'f9efd4','study_pollen':'e7b54d','study_soil':'58452e',
    }
    old={m.name:m for m in bpy.data.materials}
    for name,colour in palette.items():
        if name in old:old[name].name='Preserved earlier '+name
        material(name,colour,.2 if name=='study_window' else 0)
    for obj in bpy.context.scene.objects:
        if obj.type!='MESH':continue
        for i,mat in enumerate(list(obj.data.materials)):
            semantic=mat.name.removeprefix('Preserved earlier ')
            if semantic in M:obj.data.materials[i]=M[semantic]
        # Each disconnected roof tile gets a small, calm hue variation. Source
        # bevels, rounded noses and overlapping geometry remain the artwork.
        if 'Violet roof' in obj.name:
            shades=['7564a0','7c6aa9','6f5f98','8975b0','806ca8','6b5b92']
            variations=[material('Painted violet tile '+str(i),c) for i,c in enumerate(shades)]
            obj.data.materials.clear()
            for mat in variations:obj.data.materials.append(mat)
            parents=list(range(len(obj.data.vertices)))
            def find(i):
                while parents[i]!=i:
                    parents[i]=parents[parents[i]];i=parents[i]
                return i
            for edge in obj.data.edges:
                a,b=map(find,edge.vertices);parents[b]=a
            selected={}
            for face in obj.data.polygons:
                key=find(face.vertices[0])
                if key not in selected:selected[key]=rng.randrange(len(variations))
                face.material_index=selected[key]
    note={'derived_from':str(original.relative_to(ROOT)),'original_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),
          'geometry':'Retained adopted reference-cottage geometry, door hinge, UVs, tile noses, masonry, garden and barrel.',
          'finish':'New calm honey, violet and limestone palette; colour by individual clay tile, without the old surface noise.'}
else:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for name,colour in {
        'painted_oak':'98673b','painted_oak_light':'bd8a4d','painted_oak_dark':'63452d',
        'painted_ink':'454135','painted_brass':'c19b52',
        'leaf_shadow':'31533b','leaf_deep':'42653c','leaf_green':'60853e',
        'leaf_light':'82a14a','leaf_sun':'a4b65a','leaf_gold':'b7bf65',
    }.items():material(name,colour)
    if KIND=='tree':
        # The visible roots fit within the original hearth-oak's 0.5 m trunk
        # occupancy. The crown is cosmetic, with a dappled, stepped silhouette.
        trunk=taper('Warm bent oak',[(0,0,.015),(.04,.025,.42),(-.07,.04,1.25),(.08,0,2.15),(.14,.12,3.08)], [.32,.30,.245,.20,.10],'painted_oak')
        trunk.data.materials.append(M['painted_oak_light']);trunk.data.materials.append(M['painted_oak_dark'])
        for face in trunk.data.polygons:
            if face.normal.x>.3 and face.normal.y<.4:face.material_index=1
            elif face.normal.y>.35:face.material_index=2
        for angle in [.1,1.8,3.1,4.6]:
            taper('Grounded root',[(math.cos(angle)*.43,math.sin(angle)*.43,.015),(math.cos(angle)*.20,math.sin(angle)*.20,.20),(0,0,.60)],[.055,.12,.13],'painted_oak_dark',7)
        for a,b,r in [((0,0,1.6),(-.90,-.22,3.05),.15),((0,0,2.1),(.95,.18,3.4),.14),((.05,0,2.35),(-.15,.82,3.65),.115)]:
            taper('Forked bough',[a,((a[0]+b[0])*.5,(a[1]+b[1])*.5,(a[2]+b[2])*.5),b],[r,r*.75,.045],'painted_oak')
        # A few long brush-like bark grooves, deliberately shaped rather than
        # tiled noise. These are attached strips on the front of the trunk.
        for x,z,length in [(-.10,.55,.6),(.08,.95,.55),(-.05,1.55,.5),(.13,1.8,.3)]:
            beam('Drawn bark crease',(x,-.224,z),(x+.025,-.225,z+length),.018,'painted_oak_dark',.009)
        # Union of unequal lobes, rasterised into a fine geometric leaf mass.
        # Only exposed faces are emitted: no stacks of hidden interior cubes.
        lobes=[(-1.12,-.25,3.15,1.0,.95,.82),(-.20,-.65,3.63,1.28,1.04,1.02),
               (1.0,-.25,3.48,1.10,1.03,1.03),(-.68,.60,3.92,1.18,1.05,.96),
               (.60,.65,4.12,1.18,.96,1.08),(.07,.0,4.50,.96,.86,.73),
               (1.36,.50,3.63,.75,.83,.79),(-1.32,.48,3.45,.85,.82,.78)]
        step=.17
        occupied={}
        for ix in range(-14,15):
            for iy in range(-12,13):
                for iz in range(14,32):
                    x,y,z=ix*step,iy*step,iz*step
                    field=min(((x-a)/rx)**2+((y-b)/ry)**2+((z-c)/rz)**2 for a,b,c,rx,ry,rz in lobes)
                    irregular=.065*math.sin(ix*1.3+iz*.7)*math.cos(iy*1.7+iz*.4)
                    if field<1+irregular:occupied[(ix,iy,iz)]=True
        vertices=[];faces=[];colours=[]
        # Each face uses a quieter patch of colour, with sunlit tops and dark
        # foliage below. The normal light and the fine ink supply the shading.
        sides=[((1,0,0),[(1,0,0),(1,1,0),(1,1,1),(1,0,1)]),((-1,0,0),[(0,1,0),(0,0,0),(0,0,1),(0,1,1)]),
               ((0,1,0),[(1,1,0),(0,1,0),(0,1,1),(1,1,1)]),((0,-1,0),[(0,0,0),(1,0,0),(1,0,1),(0,0,1)]),
               ((0,0,1),[(0,0,1),(1,0,1),(1,1,1),(0,1,1)]),((0,0,-1),[(0,1,0),(1,1,0),(1,0,0),(0,0,0)])]
        for (ix,iy,iz) in occupied:
            for direction,corners in sides:
                if (ix+direction[0],iy+direction[1],iz+direction[2]) in occupied:continue
                offset=len(vertices)
                vertices.extend([((ix+x-.5)*step,(iy+y-.5)*step,(iz+z-.5)*step) for x,y,z in corners])
                faces.append(tuple(range(offset,offset+4)))
                patch=(ix//3+iy//3*2+iz//3*3)%4
                tone=1 if iz<19 else (2 if iz<24 else 3)
                tone+=1 if direction[2]>0 else (-1 if direction[2]<0 else 0)
                tone+=1 if patch==0 else 0
                colours.append(max(0,min(5,tone)))
        crown=mesh('Sculpted stepped leaf crown',vertices,faces,'leaf_shadow')
        for name in ['leaf_deep','leaf_green','leaf_light','leaf_sun','leaf_gold']:crown.data.materials.append(M[name])
        for face,colour in zip(crown.data.polygons,colours):face.material_index=colour
        crown['part']='Crown'
        note={'geometry':'New bent nine-sided trunk and forked boughs; exposed-face voxel union of eight unequal crown lobes.',
              'footprint':'Root geometry within original 0.5 m oak radius; canopy never determines collision.',
              'palette':'Six broad leaf values, honey bark and drawn bark creases; no runtime texture generation.'}
    else:
        # Low, two-rail village fence with bevelled caps and visible joinery.
        for x in [-1.20,1.20]:
            box('Square hewn post',(x,0,.45),(.20,.22,.90),'painted_oak')
            cap=taper('Chamfered post cap',[(x,0,.90),(x,0,.97)], [.16,.105],'painted_oak_light',4)
            cap.rotation_euler.z=math.pi*.25
            # The tapered cap is authored in world coordinates, so rotate its
            # actual mesh around the post centre instead of its object origin.
            cap.rotation_euler.z=0
            box('Quiet iron foot',(x,0,.065),(.215,.235,.13),'painted_ink',.012)
            for z in [.32,.69]:
                bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.024,location=(x,-.123,z))
                put(bpy.context.object,'Hand-forged pin','painted_ink')
            beam('Post grain',(x-.035,-.113,.38),(x-.019,-.113,.78),.014,'painted_oak_dark',.006)
            beam('Post glint',(x+.07,-.113,.16),(x+.075,-.113,.80),.015,'painted_oak_light',.006)
        for z in [.32,.69]:
            box('Overlapping warm rail',(0,-.025,z),(2.48,.135,.14),'painted_oak_light',.02)
            box('Drawn lower rail edge',(0,-.096,z-.044),(2.32,.009,.018),'painted_oak',.003)
            beam('Long grain stroke',(-.90,-.097,z+.015),(-.10,-.097,z+.024),.012,'painted_oak',.005)
            beam('Second grain stroke',(.20,-.097,z+.008),(.79,-.097,z+.016),.009,'painted_oak',.005)
        note={'geometry':'New 2.6 m two-rail fence; bevelled end posts, low iron shoes, pins and broad drawn grain strokes.',
              'footprint':'Full 2.6 by 0.32 m ground strip, blocks walking independently of the mesh.'}

scene=bpy.context.scene
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['rootward_source']='Editable illustrated village source. Earlier adopted masters preserved.'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
(HERE/'provenance.json').write_text(json.dumps({'asset':ID,'version':'v1','date':'2026-10-26',
 'reference':'reference/voxel-isometric.png','authoring_record':'art/source/world/illustrated-village/v1/author.py',**note},indent=2)+'\n')
(HERE/'brief.md').write_text('# '+ID+'\n\nReference-matched semi-drawn voxel study for Village Morning. Fine sepia edges, calm warm materials and softened geometry.\n\nThe editable authority is `model.blend`; export through `scripts/world-art.sh build '+ID+'`. Earlier adopted source art remains intact.\n')
print('Saved editable illustrated asset:',OUTPUT)
