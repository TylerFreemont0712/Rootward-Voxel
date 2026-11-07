# Larger clockshop and custom curios

The user asked for a fuller clockshop with more room for a future quest, and for the square's night/fog boundary to sit roughly twice as far below the rim and fade gradually.

`clockshop-shell/v2/model.blend` is a deliberate edit of the retained v1 master: 14×14 instead of 12×12, with the original door frame/hinges unchanged. The parquet keeps its world scale and subfloor clearance. The larger room keeps the normal gameplay camera scale; an overview capture alone uses a wider review lens.

Thirteen new independently reusable sources live under `art/source/world/<id>/v1/model.blend`:

- `clockshop-display-plinth`, `clockshop-orrery`, `clockshop-watch-cabinet`
- `clockshop-spring-winder`, `clockshop-pendulum-rack`, `clockshop-blueprint-board`
- `clockshop-service-shelf`, `clockshop-oil-and-tools`, `clockshop-ledger-set`
- `clockshop-clock-crates`, `clockshop-stool`, `clockshop-wall-shelf`, `clockshop-cuckoo-clock`

`author_curios.py` is their protected initial authoring record and refuses existing masters. `curio_kit.py` shares primitive helpers and the adopted clockshop materials; it imports no existing model geometry. The planetary rings, open-spoked wheels, mainspring coil, watch chains, diagram lines, ledger pages, brush, labels, shelf brackets and carved clock weights are modeled. All thirteen have studio shelf entries and can be placed through area documents. Detailed stock is decorative until a later quest supplies rules/animation.

`enlarge_shell.py` records the saved-master edit. `layout.py` records the one-time placement composition; current `content/areas/shop-clockmaker.json` is authoritative. Room v3 is retained in `content/areas/archive/shop-clockmaker-v3.json`. The selected v4 room has 50 placed objects, fourteen inspections and three real power-linked pendants. The connected 3×3 central workspace and routes to all inspections remain clear. Existing inspection IDs, door/arrival cells and program memory stay stable.

`deepen_wall.py` preserves ground v5 and saves v6, appending only vertical masonry previously culled below -3 m, down to -9 m. It restores no houses, parks or lower streets. The active atmospheric shader is `art/depth_mist.gdshader`: a single alpha-only depth overlay reconstructs world height in the current viewport and fades geometry from -2.8 to -7 m. The original surface mist implementation is superseded. No scene-color copy is used, so previously rendered transparent objects remain visible above the mist. Camera/character conventions are unchanged.

Rebuild adopted sources with `scripts/world-art.sh build <id>`. Future edits go into their saved Blender masters, not by rerunning authoring records. The original parquet painting continues through the existing `scripts/art.sh` texture library. All runtime output is local; no authoring service is needed to play.

Review: [larger clockshop and gradual depth](../../../../../pipeline/reviews/2026-11-04-clockshop-expansion-and-depth.md).
