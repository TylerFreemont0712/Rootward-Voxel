# Six rolling robots — refined 3D models

The square’s six 3D models now follow the [approved robot concepts](cast-and-robots.md) more closely, with rounded shells, larger rolling chassis, readable tools and small construction details. The original source models are preserved. All six blink naturally in the world and the dev display.

Pip follows the user’s latest revision: **no bag**, with small wrapped packages in his front compartments. Wick’s pole remains in his own left hand; Tender’s moss remains on her physical rear-right seam.

## Native model comparisons

Each comparison shows the painted reference, the previous model and the refined model at the same game-camera heading/elevation. Pip’s reference painting retains its earlier bag; the new model follows the later user instruction.

| Robot | Main changes | Front comparison | Opposite view | Blink key |
| --- | --- | --- | --- | --- |
| Pip | Rounded postbox, real parcel cubbies, two-wheel base/caster, rear cover and jointed arms | [View](../../../evidence/robot-models/2026-10-29/pip/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/pip/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/pip/blink.png) |
| Wick | Flared cap, cream lantern head/torso, broad wheelbase, detailed left-hand pole and lamp | [View](../../../evidence/robot-models/2026-10-29/wick/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/wick/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/wick/blink.png) |
| Trowel | Watering-can body, perforated rose, carrying handle, rear plant pot and foliage | [View](../../../evidence/robot-models/2026-10-29/trowel/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/trowel/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/trowel/blink.png) |
| Heron | Articulated boom, hinge discs, cable/hoist/hook, striped bumper and posed crate | [View](../../../evidence/robot-models/2026-10-29/heron/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/heron/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/heron/blink.png) |
| Tender | Rounded shell, fitted roof, folded arms, rear hatch/coupling and correctly placed moss | [View](../../../evidence/robot-models/2026-10-29/tender/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/tender/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/tender/blink.png) |
| Tally | Till drawer, rounded cap, counting tray, rimmed coins and curved receipt | [View](../../../evidence/robot-models/2026-10-29/tally/view-0.png) | [Rear](../../../evidence/robot-models/2026-10-29/tally/view-180.png) | [Blink](../../../evidence/robot-models/2026-10-29/tally/blink.png) |

[Native lineup at the square’s camera size](../../../evidence/robot-models/2026-10-29/lineup-gameplay.png) · [Closer lineup](../../../evidence/robot-models/2026-10-29/lineup-detail.png).

The blink compresses only the two eye shapes for 160 ms, then restores their exact original scale. Each robot has its own timing. Existing face glass, lights and movement stay independent of the blink.

## Editing and review

Open `art/source/world/robot-<name>/v2/model.blend`, then use `scripts/world-art.sh build robot-<name>`. The adopted sources pack their material textures; the game needs no authoring tools. [Source records](../../../art/source/world/sparks-robot-refinement/v1/README.md) and [review](../../../pipeline/reviews/2026-10-29-robot-models-and-request-markers.md) document the handoff.

All six models are now in the dev menu’s **Finished** list, awaiting your review. [Finished-list capture](../../../evidence/robot-models/2026-10-29/finished-robots.png). Their tools are detailed posed geometry; additional working animations remain future work.
