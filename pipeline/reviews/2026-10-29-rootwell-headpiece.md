# The Rootwell headpiece — 2026-10-29

The user asked for the square's headpiece, the Rootwell, at fairly high detail, from the approved [front and rear paintings](../../docs/concept/v0.72/rootwell-beacon.md). It is the headpiece of the square and the town and will carry story later. This pass is the headpiece only; the square layout comes next.

## Result

- **`rootwell-beacon`**, a new editable Blender master with an audited GLB. It is catalogued `showcase_only` and appears in Asset Showcase (Dev). The playable square deliberately still shows `square-beacon`; the layout pass will swap it. Source pack and full contents: [Rootwell README](../../art/source/world/rootwell/v1/README.md).
- **It follows the paintings face by face**, with the gauge toward the game camera:
  - Base: octagonal steps, a terrace and a dressed limestone drum.
  - South-east, the public face: the pressure gauge on a riveted teal panel, the ROOTWELL plaque, and pipes running down the steps.
  - South: the notice board under a tiled hood, and a brass-ended bench.
  - East: the teal maintenance door under its own hood.
  - North-west: the service face, with a louvred vent, copper risers, valve wheels and capped stubs.
  - Around the base: planters and evergreens, and ivy over the lip.
  - Chamber and crown: the riveted chamber band with four valve stands, bowed amber glass with brass ribs, eight columns with two lanterns, the riveted entablature, the ribbed verdigris dome and the cupola.
- **The existing inspection lines now have physical details:**
  - The needle sits just past the first mark, with a scratch on the bezel where it used to rest.
  - The notices carry a tide table, a Thursday meeting and LOST: ADMIRAL with a tortoise drawing.
  - The keyhole is polished brass, and BACK AT 4 is chalked on the paving.
- **Parts for later story** are separate nodes on true pivots: `gauge_needle` (turns about the dial axis), `maintenance_door` (swings on its hinge line), six `valve_wheel_*` nodes (spin on their axles), `root` and `root_light`. They are listed in the catalog's `story_parts` and checked by the test.
- **The root against its light:** a lit (non-emissive) root keeps the drawn outline. Behind it is an inward-facing light shell just inside the glass: only its far half draws, so from any side the twisted trunk and branching crown stand dark against a glow, as in the paintings.
- **Materials:**
  - From the seaside house kit: the limestone blocks, terracotta hoods, oak, teal boards and the plain-colour palette.
  - Recoloured from the library's copper-patina painting: the verdigris.
  - New: metallic brass, translucent amber glass and the chamber light gradient.

## Not done / limits

- Not placed in the square; no collision beyond the declared 7.5 m `logical_footprint`. The steps are not yet walkable surfaces. Both belong to the layout pass.
- Story parts are ready to move but nothing moves them yet.
- The paintings are lit at dusk with a strong halo. In the game's daylight the chamber reads as a warm amber glow rather than a blaze. A night or lit state (brighter `root_light`, lantern halos) would be presentation code for later.
- Weight: 123,571 triangles in 21 meshes, about three times one background house (brass fittings are 45k of it), and 7.9 MB on disk. It appears once per town.

## Evidence

At the gameplay camera (zoom 13) with outlines and the boy for scale:

- [Front](../../evidence/rootwell/2026-10-29/front.png) · [rear](../../evidence/rootwell/2026-10-29/back.png) · [east](../../evidence/rootwell/2026-10-29/east.png)
- Beside the paintings: [front](../../evidence/rootwell/2026-10-29/front-vs-concept.png), [rear](../../evidence/rootwell/2026-10-29/back-vs-concept.png)
- Close-ups: [gauge](../../evidence/rootwell/2026-10-29/close-gauge.png), [chamber and root](../../evidence/rootwell/2026-10-29/close-chamber.png), [notice board](../../evidence/rootwell/2026-10-29/close-notices.png), [door](../../evidence/rootwell/2026-10-29/close-door.png), [service face](../../evidence/rootwell/2026-10-29/close-service.png)
- [In Asset Showcase](../../evidence/rootwell/2026-10-29/showcase.png)

## Validation

- `scripts/world-art.sh build rootwell-beacon` passed: 21 meshes, 123,571 triangles, bounds ±3.75 × 9.51 inside the 64-unit envelope; headless import passed.
- `test/test_rootwell.gd`: **34 checks passed**. They cover:
  - every story part is its own mesh node;
  - the needle's pivot is the dial centre, its axis is the south-east normal, turning sweeps the tip round the dial, and rising pressure lifts it;
  - the door hangs from its hinge on the east face, and each valve wheel spins about its hub;
  - the glass is translucent, the chamber light is single-sided and glowing, the root is not emissive, and the lanterns use `lamp_glass`;
  - the size and triangle budget hold;
  - no area places it and the square keeps `square-beacon`;
  - Asset Showcase displays it without house looks.
- The house palette image the kit rewrites on each run stayed byte-identical.
- Full `scripts/test.sh` (with `VOXEL_LAB_FRESH=1`) **passed, exit 0**, including modular houses (307), showcase (35), world art (909), source protection (11) and pipeline/link (1,381) checks. Log: `.cache/rootwell/full-test.log`. No commit was made.

## Iterations during review

Six review drafts were made outside `art/source` before adoption:

- An opaque glowing core hid the root. It was replaced by the inward light shell, and the root became lit and outlined.
- The verdigris contrast was cut.
- The dome's strut cage was removed.
- Four lanterns became one per side.
- The step grass was thinned.
- The paper headings were hidden, so the notice-board hood was raised and shortened.
- The root's crown was spread to fill the bell.
- The opening heights were aligned to the stone courses.
- A kit lookup bug that gave the lanterns the houses' pale glass was fixed. House output is unchanged, because the houses never define bare material names.
