"""Deliberate edit of the adopted lane set: swing its two gate leaves open for the town steps.
Keeps a backup and refuses a repeated edit. Other meshes/materials and the lane layout stay intact.
"""
from pathlib import Path
import bpy
import hashlib
import json
import math
import shutil
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
folder=ROOT/'art/source/world/haverlund-lane-set/v1';src=folder/'model.blend'
note=folder/'square-gate-revision.json'
if note.exists():raise RuntimeError('Gate revision already applied; inspect the adopted source.')
shutil.copy2(src,folder/'model.pre-square-gate.blend')
before=hashlib.sha256(src.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(src));bpy.context.preferences.filepaths.save_version=0
count=0
for obj in bpy.context.scene.objects:
    if obj.type!='MESH':continue
    mat=obj.data.materials[0].name
    if not ('iron' in mat or 'brass' in mat):continue
    # The static batch stores vertices in area coordinates, with identity object transforms.
    for v in obj.data.vertices:
        p=obj.matrix_world@v.co
        if 11.46<p.x<13.54 and 27.13<p.y<27.34 and 1.07<p.z<2.42:
            hinge=11.48 if p.x<12.5 else 13.52
            a=math.radians(85 if hinge<12 else -85)
            dx,dy=p.x-hinge,p.y-27.25
            p.x=hinge+math.cos(a)*dx-math.sin(a)*dy
            p.y=27.25+math.sin(a)*dx+math.cos(a)*dy
            v.co=obj.matrix_world.inverted()@p;count+=1
if count<100:raise RuntimeError('Gate leaf selection is unexpectedly small')
bpy.ops.wm.save_as_mainfile(filepath=str(src))
note.write_text(json.dumps({'date':'2026-10-28','record':'art/source/world/sparks-square/v1/open_lane_gate.py','before_sha256':before,'after_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'vertices_swung':count,'note':'Town steps opened for the square; backup retained.'},indent=2)+'\n')
print('Gate opened:',count)
