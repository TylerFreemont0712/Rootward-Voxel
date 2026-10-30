"""Review-driven finish edit of saved masters, with new texture provenance.
Existing furniture geometry is preserved. Only the shell gains panel seams.
"""
from pathlib import Path
import importlib.util
import json
import bpy
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
NOTE=HERE/'surface-review.json'
if NOTE.exists(): raise RuntimeError('Surface review already applied; edit the existing masters.')
spec=importlib.util.spec_from_file_location('loft_helpers',HERE/'author.py')
h=importlib.util.module_from_spec(spec); spec.loader.exec_module(h)
assets=['loft-shell']+list(h.BUILDERS)
for asset in assets:
    source=ROOT/'art/source/world'/asset/'v1/model.blend'
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version=0
    oak=bpy.data.images.load(str(HERE/'honey-oak-v2.png'))
    for mat in bpy.data.materials:
        if not mat.use_nodes: continue
        bsdf=mat.node_tree.nodes.get('Principled BSDF')
        for n in mat.node_tree.nodes:
            if n.type=='TEX_IMAGE' and n.image and Path(n.image.filepath).name=='honey-oak.png': n.image=oak
        if mat.name=='loft_white':
            c=tuple(h.linear(int('e0d2b9'[i:i+2],16)/255) for i in (0,2,4))
            mat.diffuse_color=(*c,1); bsdf.inputs['Base Color'].default_value=(*c,1)
        if mat.name=='loft_quilt':
            tex=next(n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE')
            mul=mat.node_tree.nodes.new('ShaderNodeMixRGB'); mul.blend_type='MULTIPLY'
            mul.inputs[0].default_value=1; mul.inputs[2].default_value=(.68,.68,.68,1)
            mat.node_tree.links.new(tex.outputs['Color'],mul.inputs[1]); mat.node_tree.links.new(mul.outputs[0],bsdf.inputs['Base Color'])
        if mat.name=='loft_plaster':
            tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=bpy.data.images.load(str(HERE/'cream-plaster.png'),check_existing=True)
            mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
        if asset=='loft-shell' and mat.name=='loft_wainscot':
            tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=oak
            mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    if asset=='loft-shell':
        for obj in bpy.context.scene.objects:
            if obj.type!='MESH' or not obj.data.materials: continue
            kind=obj.data.materials[0].name
            if kind not in ('loft_plaster','loft_wainscot'): continue
            uv=obj.data.uv_layers.active or obj.data.uv_layers.new(name='Painted surface')
            for p in obj.data.polygons:
                axis=0 if abs(p.normal.x)>.7 else 1
                for li in p.loop_indices:
                    v=obj.matrix_world@obj.data.vertices[obj.data.loops[li].vertex_index].co
                    horizontal=v.y if axis==0 else v.x
                    uv.data[li].uv=(horizontal/4,v.z/4) if kind=='loft_plaster' else (v.z/1.8,horizontal/1.3)
        h.PARENT=bpy.data.objects['loft_shell']; h.material('panel_seam','86674b')
        for n in range(33):
            y=1.0+n*.255
            if y<9.5: h.box('West wainscot seam',(-.495,y,.42),(.008,.007,.72),'panel_seam',0)
        for n in range(45):
            x=-.4+n*.265
            if x<11.5: h.box('North wainscot seam',(x,9.493,.42),(.007,.008,.72),'panel_seam',0)
        pieces=[o for o in bpy.context.scene.objects if o.type=='MESH' and 'wainscot seam' in o.name]
        bpy.ops.object.select_all(action='DESELECT')
        for o in pieces:o.select_set(True)
        bpy.context.view_layer.objects.active=pieces[0]; bpy.ops.object.join(); bpy.context.object.name='Wainscot board seams'
    bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(source))
    print('REFINED',asset,flush=True)
NOTE.write_text(json.dumps({'date':'2026-10-27','assets':assets,'record':'refine_surfaces.py','reason':'Gameplay review showed yellow wood, flat plaster and clipped whites. The second oak is calmer; new cream plaster and lower quilt/pillow values retain texture under the actual room light. Geometry of existing furniture preserved.'},indent=2)+'\n')
