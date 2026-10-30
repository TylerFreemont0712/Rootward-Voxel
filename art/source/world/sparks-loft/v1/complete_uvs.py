"""Complete the export contract for untextured curves and paper faces.
Only meshes without any UV layer change; existing painted UVs are preserved.
"""
from pathlib import Path
import importlib.util
import json
import bpy
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[4]
spec=importlib.util.spec_from_file_location('loft_helpers',HERE/'author.py')
h=importlib.util.module_from_spec(spec); spec.loader.exec_module(h)
changed={}
for asset in ['loft-shell']+list(h.BUILDERS):
    source=ROOT/'art/source/world'/asset/'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source)); bpy.context.preferences.filepaths.save_version=0
    names=[]
    for o in bpy.context.scene.objects:
        if o.type!='MESH' or o.data.uv_layers:continue
        uv=o.data.uv_layers.new(name='Uniform part planar UV')
        for p in o.data.polygons:
            axes=[i for i in range(3) if i!=max(range(3),key=lambda i:abs(p.normal[i]))]
            for li in p.loop_indices:
                v=o.data.vertices[o.data.loops[li].vertex_index].co
                uv.data[li].uv=(v[axes[0]],v[axes[1]])
        names.append(o.name)
    if names:
        bpy.ops.wm.save_as_mainfile(filepath=str(source)); changed[asset]=names
        print('COMPLETED UV',asset,names,flush=True)
(HERE/'uv-completion.json').write_text(json.dumps({'date':'2026-10-27','record':'complete_uvs.py','changed':changed,'note':'Untextured curve/paper surfaces now have finite UVs for the world audit. Painted UV layers and all geometry/materials unchanged.'},indent=2)+'\n')
