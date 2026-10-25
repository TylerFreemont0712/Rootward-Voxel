"""Source refinement: bring small bottle silhouettes to the front of the open shelves."""
from pathlib import Path
import hashlib,json,shutil
import bpy,bmesh
root=Path.cwd();folder=root/'art/source/world/hollow-apothecary-cabinet/v1';source=folder/'model.blend'
if (folder/'bottle-refinement.json').exists():raise RuntimeError('Bottle staging already applied; preserve source.')
shutil.copy2(source,folder/'model.before-bottle-staging.blend')
before=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source))
for obj in bpy.context.scene.objects:
    if obj.type!='MESH':continue
    mat=obj.data.materials[0].name
    if mat in ['glass_teal','glass_blue','glass_violet','clay']:
        for v in obj.data.vertices:v.co.y-=.14
    elif mat=='cream':
        for v in obj.data.vertices:
            if v.co.z>.85:v.co.y-=.14
    elif mat=='oak':
        bm=bmesh.new();bm.from_mesh(obj.data)
        unseen=set(bm.verts)
        while unseen:
            first=next(iter(unseen));stack=[first];component=set()
            while stack:
                v=stack.pop()
                if v in component:continue
                component.add(v);stack.extend(edge.other_vert(v) for edge in v.link_edges)
            unseen-=component
            ys=[v.co.y for v in component];zs=[v.co.z for v in component]
            if min(zs)>.85 and max(zs)-min(zs)<.08 and abs((min(ys)+max(ys))*.5+.07)<.01:
                for v in component:v.co.y-=.14
        bm.to_mesh(obj.data);bm.free()
    obj.data.update()
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(source))
(folder/'bottle-refinement.json').write_text(json.dumps({'reason':'Bring bottle bodies, labels and corks toward the shelf front so they read at the approved elevated camera.','method':'Translate the existing authored bottle components by -0.14 Blender Y; preserve cabinet shape and all other objects. No regeneration.','before_sha256':before,'after_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
shutil.copy2(Path(__file__),folder/'stage_bottles.py')
