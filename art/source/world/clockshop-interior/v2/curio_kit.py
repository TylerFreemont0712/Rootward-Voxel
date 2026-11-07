"""Geometry/material helpers for original clockmaking curios; no imported model geometry."""
from pathlib import Path
import sys,math,json,hashlib
import bpy
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'));import house_kit as k
def begin(id):
 path=ROOT/'art/source/world'/id/'v1/model.blend'
 if path.exists():raise RuntimeError('Saved master exists: '+id)
 bpy.ops.wm.read_factory_settings(use_empty=True);k.M.clear()
 for donor in ['clockshop-parts-cabinet','clockshop-display-counter','clockshop-repair-bench','clockshop-shell']:
  palette=ROOT/'art/source/world'/donor/'v1/model.blend'
  with bpy.data.libraries.load(str(palette),link=False) as (data,out):out.materials=[m for m in data.materials if m.startswith('clockshop_') and m not in k.M]
  k.M.update({m.name:m for m in out.materials if m})
 root=bpy.data.objects.new(id.replace('-','_'),None);bpy.context.scene.collection.objects.link(root)
 return root,k.Parts(110411),path
def save(root,p,path):
 p.finish(root)
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH' and any(s in obj.name for s in ['brass','steel','ink','clear_glass','diagram']):obj['illustrated_edges']=False
 path.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('provenance.json').write_text(json.dumps({'record':'art/source/world/clockshop-interior/v2/author_curios.py','units':'metres','front':'Blender -Y','palette':'clockshop-parts-cabinet/v1/model.blend (materials only)','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()},indent=2)+'\n')
def box(p,m,at,size,b=.012):p.box('clockshop_'+m,at,size,bevel=b)
def rod(p,m,a,b,r=.015,n=12):p.cylinder('clockshop_'+m,a,b,r,n)
def ring(p,x,y,z,r,thick=.018,m='brass',n=40):
 for i in range(n):
  a=math.tau*i/n;b=math.tau*(i+1)/n
  p.solid('clockshop_'+m,[(x+r*math.sin(a),y,z+r*math.cos(a)),(x+r*math.sin(b),y,z+r*math.cos(b)),(x+(r+thick)*math.sin(b),y,z+(r+thick)*math.cos(b)),(x+(r+thick)*math.sin(a),y,z+(r+thick)*math.cos(a))],.015,(0,-1,0))
def dial(p,x,y,z,r=.25):
 rod(p,'ivory',(x,y+.015,z),(x,y,z),r,40);ring(p,x,y-.012,z,r,.022)
 for n in range(12):
  a=math.tau*n/12
  rod(p,'ink',(x+math.sin(a)*r*.70,y-.027,z+math.cos(a)*r*.70),(x+math.sin(a)*r*.83,y-.027,z+math.cos(a)*r*.83),r*.018,6)
 p.beam('clockshop_ink',(x,y-.04,z),(x+r*.35,y-.04,z+r*.42),r*.07,r*.05,up=(0,1,0))
 p.beam('clockshop_ink',(x,y-.043,z),(x-r*.62,y-.043,z+r*.17),r*.05,r*.04,up=(0,1,0))
 rod(p,'brass',(x,y-.045,z),(x,y-.07,z),r*.06,10)
def gear(p,x,y,z,r,teeth=16):
 ring(p,x,y,z,r*.68,r*.18,'brass',teeth*2)
 for a in [math.tau*i/5 for i in range(5)]:p.beam('clockshop_brass',(x,y,z),(x+math.sin(a)*r*.74,y,z+math.cos(a)*r*.74),r*.10,.025,up=(0,1,0))
 rod(p,'steel',(x,y+.025,z),(x,y-.035,z),r*.13,10)
 for i in range(teeth):
  a=math.tau*i/teeth;p.box('clockshop_brass',(x+math.sin(a)*r*.91,y,z+math.cos(a)*r*.91),(r*.17,.035,r*.18),rot=(0,a,0),bevel=.002)
def text(p,words,x,y,z,size=.12,m='ivory'):
 curve=bpy.data.curves.new('clockshop_label','FONT');curve.body=words;curve.align_x='CENTER';curve.align_y='CENTER';curve.size=size
 font=Path('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf')
 if font.exists():curve.font=bpy.data.fonts.load(str(font),check_existing=True)
 obj=bpy.data.objects.new('clockshop_label',curve);bpy.context.scene.collection.objects.link(obj);bpy.context.view_layer.update()
 mesh=bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()));frame=k.facing_text(x,y,z,(0,-1))
 p.add('clockshop_'+m,[frame@v.co for v in mesh.vertices],[tuple(f.vertices) for f in mesh.polygons],[[(0,0)]*len(f.vertices) for f in mesh.polygons])
 bpy.data.objects.remove(obj,do_unlink=True);bpy.data.curves.remove(curve);bpy.data.meshes.remove(mesh)
