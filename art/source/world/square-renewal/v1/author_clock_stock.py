"""One-time stock display for the clockmaker; subsequent edits use its saved master."""
from pathlib import Path
import sys,math,random,json
import bpy
ROOT=Path(__file__).resolve().parents[5];id='town-clock-stock';path=ROOT/'art/source/world'/id/'v1/model.blend'
if path.exists():raise RuntimeError('Adopted source exists')
sys.path.insert(0,str(ROOT/'art/source/world/sparks-square/v2'))
import square_kit as s
s.begin(id);k=s.k;b=k.Batch(random.Random(1103))
b.box('oak',(0,0,.6),(2.3,.65,1.2),.025)
b.box('wood_dark',(0,-.34,.60),(2.13,.035,.92),.01)
b.box('oak',(0,0,1.24),(2.45,.75,.12),.025)
for x in [-.74,0,.74]:
 b.box('oak',(x,0,1.88),(.58,.4,1.15),.03)
 b.cylinder('brass',(x,-.215,2.1),(x,-.25,2.1),.245,24)
 b.cylinder('enamel_cream',(x,-.26,2.1),(x,-.275,2.1),.218,24)
 for tick in range(12):
  a=math.tau*tick/12
  b.box('ink',(x+math.sin(a)*.185,-.283,2.1+math.cos(a)*.185),(.018,.012,.036),.001,(0,a,0))
 b.box('ink',(x+.06,-.298,2.13),(.14,.012,.02),.002,(0,-.4,0))
 b.box('ink',(x,-.299,2.17),(.018,.012,.15),.002)
 b.box('wood_dark',(x,-.213,1.62),(.25,.02,.32),.01)
 b.box('brass',(x,-.24,1.66),(.018,.015,.24),.002)
 b.cylinder('brass',(x,-.24,1.55),(x,-.255,1.55),.08,16)
b.finish();path.parent.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('provenance.json').write_text(json.dumps({'record':'art/source/world/square-renewal/v1/author_clock_stock.py','behavior':'Static display; clock calibration quest remains future work.'},indent=2))
