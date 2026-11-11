"""Use Blender 5's supported colour Multiply node for the reviewed quilt tint.
The legacy MixRGB previews correctly in Blender but its factor is not exported.
"""
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/loft-bed/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
bpy.context.preferences.filepaths.save_version=0
mat=bpy.data.materials['loft_quilt']; nodes=mat.node_tree.nodes
tex=next(n for n in nodes if n.type=='TEX_IMAGE')
for n in list(nodes):
    if n.type=='MIX_RGB':nodes.remove(n)
mix=nodes.new('ShaderNodeMix'); mix.data_type='RGBA'; mix.blend_type='MULTIPLY'
mix.inputs[0].default_value=1.0
colors=[s for s in mix.inputs if s.type=='RGBA']
colors[1].default_value=(.68,.68,.68,1)
mat.node_tree.links.new(tex.outputs['Color'],colors[0])
output=next(s for s in mix.outputs if s.type=='RGBA')
mat.node_tree.links.new(output,nodes.get('Principled BSDF').inputs['Base Color'])
bpy.ops.wm.save_as_mainfile(filepath=str(source))
