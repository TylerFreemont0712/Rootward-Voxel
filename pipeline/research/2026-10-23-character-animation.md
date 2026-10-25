# Character animation decision — 2026-10-23

## User requirement and outcome

The user liked the original painted sprite and wanted smoother walking and diagonal views. They then explored reusable bones/clothes, but rejected the appearance of our assembled layered character. Their latest constraint is explicit: **keep the character the same as the original**. The original whole-body art is restored and remains the selected basis. Native cutout code is preserved as an inactive experiment, not adopted production infrastructure.

This supersedes earlier enthusiasm for a reusable character skeleton. A tool's ability to animate parts does not prove its resulting artwork meets the brief. Blender remains selected for editing world geometry; it is not being used to replace the approved painted character with a 3D model.

## What the researched approaches actually offer

| Approach | Useful capability | Cost for this character | Decision |
|---|---|---|---|
| Whole-body painted frames in AnimatedSprite3D | Preserves authored silhouette, face, shading and depth integration | New poses/outfits need drawing; no automatic hand/clothing layers | Selected. Improve motion around the existing approved design. |
| Godot native cutout/bones | Animate related nodes, reuse motion, attach parts/items | Needs matched, registered art, hidden overlaps, pivots, draw order and view-specific shapes | Tested but visually rejected; inactive. |
| Specialist 2D rig tool, e.g. Spine | Deformation, skins/attachments and animation tooling | Still requires a faithful layered source; adds authoring/runtime integration | Possible later evaluation; not installed or adopted. |
| 3D character rendered or displayed in the scene | Reusable skeletal motion and equipment | A new model/shading design may differ substantially from the approved sprite | Does not solve the present art-preservation request. |
| Optical-flow in-betweening | Additional temporal samples between existing whole-body pictures | Can warp outlines/occlusions; cannot invent a missing opposite-foot pose | Used offline for a narrower prototype improvement, with exact keys preserved. |

Godot's [cutout documentation](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html) describes assembling/animating parts and mixing animation styles. [Spine's Godot runtime documentation](https://esotericsoftware.com/spine-godot) describes its exported skeleton/skin integration. These capabilities support possible workflows; they do not guarantee fidelity to a painted reference.

[RIFE's primary repository](https://github.com/hzwer/ECCV2022-RIFE) provides video frame interpolation. Here the authoring implementation is the existing local ComfyUI IFNet, with backend and weight hashes in the output provenance. The project's alpha handling is explicit: estimate flow from neutral-composited RGB, apply it to premultiplied RGBA, and insert original keys unchanged. This is an authoring experiment, not a runtime model or a claim that RIFE generates anatomically correct new animation keys.

## Why our cutout study failed visually

Independent front/back body-part sheets did not establish an assembled idle matching the original first. Sleeve overlaps, proportions, connection points and silhouette changed. Mirroring two view sources was also insufficient proof of four faithful diagonal views or asymmetric equipment. Passing animation/slot tests established mechanics; it did not establish accepted art. The user feedback is the decisive visual evidence.

This is a failure of that asset/method execution, not proof that Godot cannot render good cutout characters. A future test must start with a registered layered painting of the original character, verify one assembled idle, then one walk before expanding skins or items.

## Current animation boundaries

The original v2 atlas has four painted keys in each of four diagonal directions. v3 inserts three optical-flow frames per transition, including the loop seam: sixteen display frames at 32 FPS, with the original half-second cycle. All sixteen original key drawings are byte-exact after integer padding. Turning retains phase; stopping settles to one of two existing passing drawings; restart uses the same drawing. Idle is a fixed hold, not a new full idle animation.

The source repeats the same leading foot in several directions. More frames smooth the transition but do not create the absent alternating contact sequence. Correcting those source keys while retaining the face/proportions/clothes is the next visual gate. Do not call character production solved, start a large sprite library, or reactivate the rejected rig to make that claim.

See [the working character guide](../CHARACTERS.md) for paths, optional authoring, normal builds and review. See [the latest review](../reviews/2026-10-23-painted-and-blender.md) for actual checks and evidence.
