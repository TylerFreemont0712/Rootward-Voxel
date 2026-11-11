# Anonymous painted crowd — v2

The user requested the existing character sheets, their exact animation and silhouettes, gray/black colors, a small child adjustment, and no haunted appearance. These are appearance masks, not new character designs.

`appearances.json` is the editable source selection. The man uses the complete `sparks_bram` atlas, the woman `sparks_mira`, and the child the approved boy. The build preserves each alpha byte, erases RGB colors to a flat mask, copies the original shared-frame contract and records source/output/template hashes. The child is rendered at 96% width and 88% height. Adults keep their approved scale. The selected presenter uses 96% opacity and gray 0.46, with no glow.

Build only through `scripts/art.sh`. Outputs are derived under `assets/characters/phantoms/`; originals remain unchanged. No AI-generated image, new provider, hand-drawn gait or separate build entry point is involved.

The geometric v1 silhouette study is rejected and unselected. Named actors outside Nell's shop and Nell herself are absent from active area placements.
