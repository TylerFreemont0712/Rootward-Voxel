"""Read-only Blender checks for the user-marked support/intersection defects."""
from pathlib import Path
import bpy
import bmesh
import json
from mathutils import Vector
from mathutils.bvhtree import BVHTree

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
results={}
def open_asset(asset):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/world'/asset/'v1/model.blend'))
def objects(material):
    return [o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials[0].name==material]
def bvh(o):
    return BVHTree.FromPolygons([o.matrix_world@v.co for v in o.data.vertices], [list(p.vertices) for p in o.data.polygons])
def groups(o):
    bm=bmesh.new();bm.from_mesh(o.data);unseen=set(bm.verts)
    while unseen:
        seed=unseen.pop();group={seed};todo=[seed]
        while todo:
            for e in todo.pop().link_edges:
                for v in e.verts:
                    if v in unseen:unseen.remove(v);group.add(v);todo.append(v)
        yield [o.matrix_world@v.co for v in group]
    bm.free()

open_asset('workshop-armchair')
cloth=objects('workshop_plaid')[0]
cushion=objects('workshop_teal_dark')[0]
upholstery=objects('workshop_upholstery')+objects('workshop_upholstery_light')
for name,part in [('throw',cloth),('cushion',cushion)]:
    intersections=sum(len(bvh(part).overlap(bvh(o))) for o in upholstery)
    assert intersections==0,(name,intersections)
    results[name+'_upholstery_intersections']=intersections
assert not bvh(cloth).overlap(bvh(cushion))
results['throw_cushion_intersections']=0

open_asset('workshop-shop-doors')
pot_bases=[min(p.z for p in group) for o in objects('workshop_ochre') for group in groups(o)
    if max(p.z for p in group)-min(p.z for p in group)>.30]
assert len(pot_bases)==2 and all(.169<z<.171 for z in pot_bases),pot_bases
results['porch_pot_bases']=pot_bases
results['stone_step_top']=.16

open_asset('workshop-umbrella-stand')
crock=objects('workshop_ceramic')[0]
hit=bvh(crock).ray_cast(Vector((.10,.12,2)),Vector((0,0,-1)))
assert hit[0] is not None and .11<hit[0].z<.13 and hit[1].z>.9,hit
results['crock_recessed_floor']=list(hit[0])
results['crock_floor_normal']=list(hit[1])

for asset in ['workshop-repair-bench','workshop-assembly-table','workshop-parts-crate']:
    open_asset(asset)
    assert not objects('workshop_linen'),asset
results['white_coverings_removed']=3
(HERE/'geometry-validation.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
