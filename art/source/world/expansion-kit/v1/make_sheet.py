"""Lay out native Godot asset captures; does not paint or retouch the rendered models."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[5]
renders=ROOT/'.cache/world-expansion-v1/renders'
items=[
 ('hearth-oak','Hearth oak','Broad crown • twisted trunk • buttress roots'),
 ('ridge-cedar','Ridge cedar','Blue-green needle pads • layered sweeping boughs'),
 ('river-willow','River willow','Arched limbs • long hanging leaf curtains'),
 ('hearth-house','Hearth house  /  5 × 5 tiles','Violet tiles • stone porch • shuttered dormer'),
 ('lantern-loft','Lantern loft  /  7 × 7 tiles','Teal gambrel roof • balcony • octagonal oriel'),
 ('brook-mill','Brook mill  /  6 × 5 tile shell','Separate wheel • dry sluice • loading hoist • roof vent'),
]
margin=24;gap=24;cw=1200;ch=1114;top=160
sheet=Image.new('RGB',(3696,2480),'#142126');draw=ImageDraw.Draw(sheet)
font=lambda size,bold=False:ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans'+('-Bold' if bold else '')+'.ttf',size)
draw.text((margin,24),'ROOTWARD  /  NEW SCENERY',font=font(50,True),fill='#fff0cb')
draw.text((margin,93),'Six standalone 3D candidates • Godot renders • original player shown at the same scale in every panel',font=font(27),fill='#a9c2bd')
for i,(aid,title,subtitle) in enumerate(items):
 x=margin+(i%3)*(cw+gap);y=top+(i//3)*(ch+gap)
 draw.rectangle((x,y,x+cw-1,y+ch-1),fill='#203035')
 draw.text((x+22,y+12),title,font=font(34,True),fill='#fff0cb')
 draw.text((x+22,y+58),subtitle,font=font(24),fill='#a9c2bd')
 sheet.paste(Image.open(renders/(aid+'.png')).convert('RGB'),(x,y+108))
draw.text((margin,2440),'Houses grow symmetrically from the original 3 × 3 footprint: +1 or +2 tiles per side. No new assets are placed in the game.',font=font(25),fill='#a9c2bd')
out=ROOT/'evidence/scenery-candidates.png';sheet.save(out,optimize=True)
print(out, sheet.size)

# Concrete per-asset source briefs and a compact offline handoff manifest.
records=[]
for aid,title,subtitle in items:
 folder=ROOT/f'art/source/world/{aid}/v1'
 manifest=json.loads((ROOT/f'assets/world/{aid}/manifest.json').read_text())
 b=manifest['audit']['bounds'];dims=[round(b[k+3]-b[k],3) for k in range(3)]
 p=folder/'provenance.json';provenance=json.loads(p.read_text())
 provenance['review_edits']=['art/source/world/expansion-kit/v1/refine.py']+(['art/source/world/expansion-kit/v1/finish_roof.py'] if aid=='lantern-loft' else [])
 provenance['source_sha256']=manifest['source_sha256'];p.write_text(json.dumps(provenance,indent=2)+'\n')
 text=f'''# {title}

Status: **unplaced candidate**, version v1. {subtitle}.

Editable authority: [model.blend](model.blend), authored in Blender 5.2.2 LTS.
Export: `assets/world/{aid}/model.glb`; registered with `status: candidate_unplaced` in `pipeline/world-catalog.json`.
One tile is one metre. Ground origin, front Godot +Z / Blender -Y. Visible bounds (width, height, depth): {dims} metres.
The original painted player remains 1.45 metres tall. House door leaves are 2.18 / 2.28 metres high.

Normal rebuild: `scripts/world-art.sh build {aid}`. Edit the saved Blender source; do not rerun the historical makers.
Initial authorship, deterministic seed and deliberate review edits are recorded in [provenance.json](provenance.json).
Supported Principled materials, rough nonmetal surfaces, opaque colour textures packed into the Blender file and GLB.
Uses the v1 texture pack for wood, plaster, stone, bark and window panes where appropriate; tile geometry and leaf crowns use palette materials.
World-sized box UVs repeat once per metre. No network, Blender or generation service is required to load the supplied GLB in Godot.

Footprint in the catalog is a proposal for later placement. Crowns, porches, eaves, balcony, wheel and sluice have decorative overhang.
No area placements, traversal rules, interiors, door interactions or runtime mechanism bindings were added by this asset set.
The mill's `waterwheel_pivot` is a separate local-X axle assembly for later integration; the sluice is dry and static.

Review: `evidence/scenery-candidates.png`, rendered in Godot at zoom 13, game camera heading/elevation and original actor scale.
'''
 (folder/'brief.md').write_text(text)
 records.append({'id':aid,'label':title,'dimensions_xyz':dims,'source':manifest['source'],'glb':manifest['runtime'],'source_sha256':manifest['source_sha256'],'glb_sha256':manifest['runtime_sha256'],'triangles':manifest['audit']['triangles'],'status':'candidate_unplaced'})
(ROOT/'art/source/world/expansion-kit/v1/manifest.json').write_text(json.dumps({'schema':1,'status':'standalone candidates; no area integration','preview':'evidence/scenery-candidates.png','assets':records},indent=2)+'\n')
