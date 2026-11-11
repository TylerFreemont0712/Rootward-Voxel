"""Rootwell in-game finish: warmer heart, fine glass highlights without black hulls, a visible glass silhouette."""
from pathlib import Path
import hashlib,json,math,shutil,sys
import bpy
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/sparks-lane/v1'));import lane_kit as k
folder=ROOT/'art/source/world/square-rootwell/v1';src=folder/'model.blend';note=folder/'glass-revision.json'
if note.exists():raise RuntimeError('Glass revision already applied')
shutil.copy2(src,folder/'model.pre-glass-revision.blend');before=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src));bpy.context.preferences.filepaths.save_version=0
k.M.clear();k.h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY')
k.h.material('window_reflection','e1f3ed')
reflection=k.M['window_reflection'];reflection.name='square_window_reflection'
# Label reflection material as window glass so the runtime's illustrated hull never thickens it.
for obj in bpy.context.scene.objects:
 if obj.type=='MESH' and obj.name.startswith('window highlight'):
  obj.data.materials.clear();obj.data.materials.append(reflection)
mat=next(m for m in bpy.data.materials if m.name=='loft_window_dome')
mat.diffuse_color=(*mat.diffuse_color[:3],.25)
mat.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=.25
spark=next(m for m in bpy.data.materials if m.name=='loft_spark')
node=spark.node_tree.nodes.get('Principled BSDF');amber=(1.0,.43,.075,1)
node.inputs['Base Color'].default_value=amber;node.inputs['Emission Color'].default_value=amber;node.inputs['Emission Strength'].default_value=.7
for phi in (math.pi,0):
 k.h.curve('Glass silhouette',[(.966*math.cos(a)*math.cos(phi),.966*math.cos(a)*math.sin(phi),.75+1.125*math.sin(a)) for a in [i*math.pi/2/20 for i in range(21)]],.009,'window_reflection')
# A small inner curl surrounds the heart rather than a straight stalk above it.
root=next(m for m in bpy.data.materials if m.name=='loft_root');k.M['root']=root
k.h.curve('Inner root curl',[(-.32,-.16,.72),(-.4,-.25,.9),(-.2,-.3,1.2),(.15,-.17,1.32),(.33,.02,1.45)],.065,'root')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(src))
note.write_text(json.dumps({'record':'art/source/world/sparks-square/v1/rootwell_glass_revision.py','before_sha256':before,'after_sha256':hashlib.sha256(src.read_bytes()).hexdigest()},indent=2)+'\n')
