"""Guarded first authoring of the addressable stair lantern, matching the workshop."""
from pathlib import Path
import bpy,math,json,hashlib,importlib.util
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('workshop_helpers',HERE/'author.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
asset='workshop-stair-lamp';path=w.ROOT/'art/source/world'/asset/'v1/model.blend'
if path.exists():raise RuntimeError('An adopted master exists; open it for edits.')
w.start(asset)
w.wood('Lantern wall plate',(0,.02,.16),(.28,.09,.67),'wood_dark',.04)
for z in (-.06,.39):w.S('Brass mounting screw',(0,-.035,z),(.026,.012,.026),'brass')
w.Q('Curved iron lantern bracket',[(0,-.02,.38),(0,-.21,.48),(0,-.36,.41)],.022,'steel_dark')
w.T('Lantern suspension ring',(0,-.36,.37),.048,.013,'brass',(math.pi/2,0,0))
w.C('Lantern brass foot',(0,-.36,-.10),.16,.065,'brass',32)
w.C('Frosted lantern glass',(0,-.36,.10),.115,.35,'lamp_glass',32)
for n in range(4):
    a=n*math.tau/4+math.pi/4
    w.R('Lantern corner stay',(math.cos(a)*.13,-.36+math.sin(a)*.13,-.07),
        (math.cos(a)*.13,-.36+math.sin(a)*.13,.29),.012,'brass')
w.C('Lantern rain cap',(0,-.36,.30),.18,.085,'teal_dark',32,.11)
w.C('Lantern cap finial',(0,-.36,.36),.033,.065,'brass',20)
w.save(asset)
p=path.with_name('provenance.json');record=json.loads(p.read_text())
record.update(record=str(Path(__file__).relative_to(w.ROOT)),record_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),purpose='Addressable stair light for the first workshop repair ticket.')
p.write_text(json.dumps(record,indent=2)+'\n')
