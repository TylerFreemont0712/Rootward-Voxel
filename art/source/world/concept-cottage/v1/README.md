# Concept Cottage

An original 3.8 × 3.4 metre cottage modeled from scratch after the **left-hand log house** in `reference/voxel-isometric.png`. No previous building meshes were reused. `author.py` records first authorship and refuses an existing source. The saved **model.blend** is now the editable master; use `scripts/world-art.sh build concept-cottage` after editing it.

The mesh has individual staggered glazed roof tiles, notched oak courses, a round cross-barred gable window, dressed limestone jambs and voussoirs, a seven-board hinged door, forged straps, brass knocker, stepped landing, hollow block chimney and stone daisy planter. Later camera-fit corrections and their backups are recorded in `provenance.json` and the doorway authoring records. Furniture/trading are not added.

The built-in `image_gen.imagegen` tool painted `textures/violet_glaze.png` and `textures/honey_oak.png`. Exact prompts are `textures/prompt.txt`, `textures/oak-prompt.txt` and `textures/library.json`; `textures/generation.json` pins native hashes and tool provenance. `pipeline/art-catalog.json` selects them under `building_textures`. The existing texture packager, through **scripts/art.sh**, creates opaque, lossless, mipmapped 128-pixel lush/solid variants and a manifest. The Blender source packs its selected images; the audited runtime GLB needs no service.

Choose **B → Objects → Houses → Concept Cottage**. It supports rotation, placement/move/delete, material finishes, undo/redo, saves and its own cottage room through the ordinary house instance system. It is a new shelf entry; the existing village placements are preserved.
