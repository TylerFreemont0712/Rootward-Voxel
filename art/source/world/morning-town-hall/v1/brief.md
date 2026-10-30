# Village Morning Town Hall

An 8.6 × 6.8 m civic shell with a roughly 11 m clock/bell tower. Front faces Blender −Y / Godot +Z. Broad shallow stone steps support a real hinged double leaf; door plane 3.51 m, width 1.8 m. Limestone foundation, plaster panels, chunky oak braces, teal tile courses, gold clock and bronze bell, civic banners, lettering and notices. Catalog collision covers walls independently of roof overhang. Enterable via the ordinary saved room contract.

Original one-time geometry in `../../village-landmarks/v1/author.py`. The saved `model.blend` becomes the editable master. Edit it and run `scripts/world-art.sh build morning-town-hall`; never rerun the author over an existing source. Existing painted library pictures are packed into the source/export. No network or authoring tools needed to play.

`reveal_clock.py` deliberately raises the first tower above the roof ridge and replaces intersecting test cap slabs with one clean hipped cap. The first source remains beside the editable master as `model.pre-clock-reveal.blend`.
