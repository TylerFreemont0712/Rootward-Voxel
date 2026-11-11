"""New reusable retaining-wall module and neutral shop shell. Existing sources refused."""
from pathlib import Path
import sys,json,random
import bpy
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/sparks-square/v2'))
import square_kit as s
k=s.k

def save(id):
 path=ROOT/'art/source/world'/id/'v1/model.blend'
 path.parent.mkdir(parents=True,exist_ok=True)
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('provenance.json').write_text(json.dumps({'record':'art/source/world/square-renewal/v1/author_modules.py','units':'metres','axis':'Blender +Y logical north'},indent=2))

def begin(id):
 if (ROOT/'art/source/world'/id/'v1/model.blend').exists():raise RuntimeError('Source exists '+id)
 s.begin(id)

def shell():
 id='town-shop-shell';begin(id);b=k.Batch(random.Random(1103))
 b.box('oak',(5.5,5.5,-.14),(12,12,.24),.015)
 # Twelve by twelve cutaway room, window bays and wainscot.
 k.wall('Back shop wall','plaster',(-.5,11.5),(11.5,11.5),0,3.8,.23,[(1.0,3.0,1.5,3),(8.0,10.0,1.5,3)])
 k.wall('West shop wall','plaster',(-.5,-.5),(-.5,11.5),0,3.8,.23,[(3,5,1.5,3),(8,10,1.5,3)])
 for x in [1.5,8.5]:k.window(b,(x,11.34,2.25),2,1.5,(0,-1),shutters=False,box=False,glass='window_shop',bars=(1,1),name='Shop rear window')
 for y in [3.5,8.5]:k.window(b,(-.34,y,2.25),2,1.5,(1,0),shutters=False,box=False,glass='window_shop',bars=(1,1),name='Shop side window')
 for z in [.12,1.1,3.65]:
  b.box('oak',(5.5,11.32,z),(12,.10,.12),.01);b.box('oak',(-.32,5.5,z),(.1,12,.12),.01)
 for x in [0,5.5,11]:b.box('oak',(x,11.23,1.9),(.14,.16,3.8),.01)
 # Broad board seams, quiet floor border.
 for y in range(12):b.box('wood_dark',(5.5,y,-.009),(11.9,.018,.015),0)
 for x in [0,11]:b.box('wood_dark',(x,5.5,.003),(.07,11.9,.02),0)
 b.finish();save(id)

def wall():
 id='town-retaining-wall';begin(id);b=k.Batch(random.Random(1103))
 b.box('ashlar',(0,0,.95),(3,.36,1.9),.01)
 b.box('limestone_pale',(0,0,1.96),(3.04,.48,.12),.018)
 b.box('limestone_shade',(0,0,.08),(3.04,.44,.16),.012)
 b.finish();save(id)

shell();wall()
