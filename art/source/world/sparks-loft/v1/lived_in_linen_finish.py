"""Fit the exposed sheet beneath the pulled-back quilt, keeping all fabric layers separate."""
from pathlib import Path
import bpy
import bmesh
import math
import hashlib
import json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
path=ROOT/'art/source/world/loft-bed/v1/model.blend'
before=hashlib.sha256(path.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(path))
bpy.context.preferences.filepaths.save_version=0
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.data.materials[0].name!='loft_linen':continue
    bm=bmesh.new();bm.from_mesh(o.data);unseen=set(bm.verts)
    while unseen:
        seed=unseen.pop();group={seed};todo=[seed]
        while todo:
            for edge in todo.pop().link_edges:
                for v in edge.verts:
                    if v in unseen:unseen.remove(v);group.add(v);todo.append(v)
        pts=[o.matrix_world@v.co for v in group]
        if min(p.z for p in pts)<.95:continue
        for v in group:
            p=o.matrix_world@v.co
            u=p.x/.88
            t=(p.y+1.27)/(2.1+.025*math.sin(u*5))
            start=.4-.24*u+.045*math.sin(u*4)-.075
            p.y=start+t*(.84-start)
            v.co=o.matrix_world.inverted()@p
    bm.to_mesh(o.data);bm.free();o.data.update()
bpy.ops.wm.save_as_mainfile(filepath=str(path))
Path(__file__).with_suffix('.json').write_text(json.dumps({'asset':'loft-bed','before':before,
    'after':hashlib.sha256(path.read_bytes()).hexdigest()},indent=2)+'\n')
