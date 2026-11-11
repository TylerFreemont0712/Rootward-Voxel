# Pendulum & Pin interior collection

Nine original models, authored for the rebuilt clockshop and registered individually for reuse. No geometry from the rejected room furniture or old shop shell is imported. The approved oak material painting is shared; the parquet is a new built-in imagegen painting.

| ID | Source feature |
| --- | --- |
| `clockshop-shell` | Cutaway room, teal wainscot, framed windows, parquet and hinged glazed entrance |
| `clockshop-longcase` | Walnut bonnet, dial, glazed pendulum cabinet and weights |
| `clockshop-regulator` | Wall case, chapter ring, hands and glazed pendulum |
| `clockshop-display-counter` | Panelled counter, brass frame, actual glass and felt-lined stock |
| `clockshop-repair-bench` | Drawers, vise, loupe lamp, drivers and exposed wheel assembly |
| `clockshop-parts-cabinet` | Twenty-eight drawers with brass label plates and pulls |
| `clockshop-clockwork-tray` | Removable tray with separate open-spoked gears |
| `clockshop-brass-pendant` | Suspension, shade and isolated emitting glass |
| `clockshop-mantel-clock` | Arched case, raised feet, dial and hands |

Each editable master is `art/source/world/<id>/v1/model.blend`; runtime outputs are `assets/world/<id>/model.glb`. Rebuild with `scripts/world-art.sh build <id>`. `author.py` is the initial authoring record and refuses existing masters. `finish.py` records the subsequent saved-master walnut/floor finish and also refuses a repeated finish. `floor_support.py` subsequently lowers the hidden subfloor cap below the parquet to prevent coplanar faces. Future changes edit the saved Blender master rather than rerunning either script.

The source painting is [textures/clockshop_parquet.png](textures/clockshop_parquet.png); its exact built-in imagegen prompt is [floor-prompt.txt](floor-prompt.txt). [Generation/provenance](textures/generation.json) pins source/library hashes. The existing `scripts/art.sh` / `DetailTextureBuilder` pipeline writes lush/solid and 512 px detail outputs to `assets/world/textures/clockshop/`. Sources remain full resolution. This library is available to authoring models; it does not add a global floor-brush option.

Room placements, footprints, inspections and travel are owned by `content/areas/shop-clockmaker.json`. All six portable furnishings have studio build-shelf entries; regulators and pendants can be placed by area documents. There is no runtime dependency on Blender or imagegen. Stock dials are decorative. The exterior facade clock still follows shared town time; no clock-setting lesson or trading is claimed.
