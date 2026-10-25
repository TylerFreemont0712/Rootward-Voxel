"""Recorded corrections after the first Godot review. Reads existing shop masters; never seeds them.
Normal later work edits the saved sources. Running this deliberately reapplies only these corrections.
"""
from pathlib import Path
import bpy,json,hashlib,sys
root=Path.cwd();sys.path.insert(0,str(root/'pipeline'))
from blender_retexture import uv_object,retexture_material
for id in ['hollow-bakery','hollow-smithy']:
 source=root/'art/source/world'/id/'v1/model.blend';bpy.ops.wm.open_mainfile(filepath=str(source))
 for obj in bpy.context.scene.objects:
  if obj.name.startswith('Painted tiled roof') and obj.location.x*obj.rotation_euler.y<0:obj.rotation_euler.y*=-1
  if obj.name.startswith('Forge dark firebox'):obj.location.y=.95
 roof='roof_violet' if id=='hollow-bakery' else 'roof_teal'
 entries={roof:{'mode':'world','tile':1.2},'window_warm':{'mode':'face'}}
 retexture_material(bpy.data.materials['window_warm'],{'texture':'window_glow','mode':'face','emission':.35},root/'assets/world/textures/lush')
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH':uv_object(obj,entries)
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 p=source.parent/'provenance.json';d=json.loads(p.read_text());d['source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest();d['review_correction']='Roof slopes aligned with ridge/eaves; open forge firebox; warm display panes.';p.write_text(json.dumps(d,indent=2)+'\n')
