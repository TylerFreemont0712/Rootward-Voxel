# Building source edits — 2026-10-24

The user requested a review of all buildings, more consistent rooftops, clearer doors, a water-connected quest mill, polished lamps and one or two missing village buildings.

`edit_sources.py` records the deliberate edit of nine existing adopted masters. It opens their saved `.blend`, keeps a permanent `model.pre-building-polish.blend`, preserves geometry outside the entrance components, updates roof UVs/materials, adds readable entrances or recenters existing ones, and polishes the lamp without touching its glass. It refuses a source already carrying this revision. It also records the one-time original mesh authoring of the two new shop masters, refusing existing source files.

`review_corrections.py` records corrections found in the first Godot review: roof slope signs on the new shops, warm panes and an open forge mouth. `shop_details.py` adds side windows and timber bands to those saved shop sources and refuses already detailed sources. These are historical, deliberate source edits, not generators to run over later artist changes. Their saved **model.blend** files are now authoritative.

The existing v1 painted violet/teal roof pictures, plank texture and the new limestone, brick and limewash library were reused. No new bitmap generation or original picture repainting was needed. World-space roof UVs use a common 1.2-unit picture width. The existing source packer handles painted material images; the supplied runtime GLBs contain all required art.

Every modified old master has `building-polish.json` with backup/source hashes. New shop `provenance.json` records original authoring and subsequent review edits. All were exported through **`scripts/world-art.sh build <id>`**, with candidate audit and source preservation. Never seed/init or run this historical edit over an adopted file to make a routine change.

The procedural mill rotor/axle remains a separate engine presentation, driven by the versioned area document; adopted building shells keep their previous footprints. New shop footprints, placement, room mappings, shelf entries and finish capabilities are in the normal project catalogs.

See [building guide](../../../../../pipeline/BUILDINGS.md) and [review](../../../../../pipeline/reviews/2026-10-24-building-polish.md). The approved character and camera remain unchanged.
