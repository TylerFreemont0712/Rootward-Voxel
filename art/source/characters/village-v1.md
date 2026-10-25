# Village residents, version 1

Rowan, Bram, Tessa and Nell were authored on 2026-10-23 as complete shared-frame appearance skins for village NPCs. Mira's existing sources and the approved boy were preserved. `content/villagers.json` owns names, roles and dialogue; `pipeline/character-catalog.json` registers all four with `selectable: false`.

Each `<id>/v1/` folder preserves:

- `SE.png`, `NE.png`: original transparent 1254×1254 generated nine-pose paintings. The approved boy's corresponding direction sheet was the pose/style reference; NE also referenced the new resident's SE identity.
- `SW.png`, `NW.png`: exact horizontal mirrors of individual 418×418 cells, preserving reading order.
- `idle-se.png`, `blink-reference.png`, `blink-generated.png`: neutral pose 9, the 250×250 reference crop starting at `[90,35]`, and the generated closed-eye crop.
- `blink-se.png`, `blink-sw.png`: only two feathered eye ellipses composited onto the exact neutral; SW is an exact mirror. The generated crop was Lanczos-resized to reference size; original alpha and pixels outside those ellipses were preserved.
- `prompt-se.txt`, `prompt-ne.txt`, `prompt-blink.txt`, `prompts.json`: exact prompts and tool disclosure. Built-in `image_gen.imagegen` was used; model identifier and seed were not exposed by that tool.
- `authoring.json`: input SHA-256 hashes, crop/eye coordinates and exact compositing method.
- `sheet.png`, `provenance.json`: packed atlas and source hashes from the existing integer-registration adapter.

`pipeline/prepare_villager_source.gd` performs the one-time mirror/blink assembly and refuses a prepared source folder. It is an authoring adapter before `pipeline/prepare_directional_walk.gd`; it is not called by normal builds or gameplay. New art must use a new version. The shared packer translated frames by whole pixels into the common 1536×5376 atlas. `scripts/art.sh` compiled all seven registered skins, including the hidden twilight tint example, through the existing pipeline.

The boy's frame layout, scale, foot origin, phase behavior, walk timing, breathing and blink settings remain in the unchanged shared template. There are no per-NPC motion settings, runtime generation, bones or separable clothing.

The [village review](../../../pipeline/reviews/2026-10-23-village-expansion.md) records the windowed four-direction walk/idle review beside the boy and selected game captures. Core tests also verify exact per-cell mirrors and eye-only blink differences.
