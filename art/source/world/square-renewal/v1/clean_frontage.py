"""Remove retained original fascia faces behind the new joinery; keep upper floors and masonry."""
from pathlib import Path
import sys,json
import bpy,bmesh
ROOT=Path(__file__).resolve().parents[5]
for id in ['haverlund-bakery','haverlund-greengrocer','haverlund-bookshop','haverlund-clockmaker','haverlund-apothecary']:
 path=ROOT/json.load(open(ROOT/'pipeline/world-catalog.json'))['assets'][id]['source']
 bpy.ops.wm.open_mainfile(filepath=str(path))
 if bpy.context.scene.get('frontage_cleaned'):raise RuntimeError('Already cleaned '+id)
 count=0
 for o in bpy.context.scene.objects:
  if o.type!='MESH' or o.name not in ['seaside_shutter','house_paint']:continue
  bm=bmesh.new();bm.from_mesh(o.data)
  fs=[f for f in bm.faces if max((o.matrix_world@v.co).z for v in f.verts)<3.42 and max((o.matrix_world@v.co).y for v in f.verts)<-3.035]
  count+=len(fs)
  if fs:bmesh.ops.delete(bm,geom=fs,context='FACES')
  bm.to_mesh(o.data);bm.free();o.data.update()
 bpy.context.scene['frontage_cleaned']=True;bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path));print('CLEANED',id,count)
