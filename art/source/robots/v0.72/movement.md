# Detailed Wick / Tender rolling sheets

`wick/movement-v1/` and `tender/movement-v1/` contain separately painted SE, SW, NE and NW movement sheets, four rolling keys each. They extend the first v0.72 concepts without replacing those sources or the subsequently adopted Blender models.

## Physical-side contract

- Wick carries the stowed upright lantern pole in his own **left hand**, with a clamp on the left flank. The free arm stays on the right. In both front views the pole appears toward viewer-right; in both rear views it appears toward viewer-left, with different near/far overlaps. His small front guide caster is hidden from the rear.
- Tender’s moss/blossom patch and service coupling stay at the **rear-right seam**. The near left shell is plain; moss partly peeks across the far edge when seen from that side. The rear has a service cover, not another face. Arm fittings stay on their physical sides.
- Every direction is a genuine separate painting. **Do not apply the human template’s mirrored-pair convention to these robots.** Renderers must not use `flip_h` to obtain another view.
- All frames show rolling travel with fixed wheel support. Tools stay stowed; these sheets do not depict lighting a lamp or servicing a valve.

## Files and provenance

`SE-generated.png`, `SW-generated.png`, `NE-generated.png` and `NW-generated.png` are native 1254-square RGBA paintings, each containing a 2×2 grid of full silhouettes. Matching `.generation.json` files preserve the exact prompts, reference/output hashes and original tool output paths. All painting and corrections used the built-in imagegen tool. Model identifier and seed were not exposed.

Tender’s first SE attempt faced the opposite diagonal and is retained as `SE-first-attempt.png`. Its selected correction establishes the front-right view before the remaining sides are painted. Wick’s rear first attempts showed a guide caster at the rear as well as at the front; those attempts are retained, and targeted corrections hide the front caster correctly from behind. The edits preserve the anatomical left-hand pole.

`movement-atlas.png` and `movement.json` register the sixteen complete keys into four rows of four 704-square cells, in SE/SW/NE/NW order. Wheel contact origin is `[352,660]`; the lower chassis silhouette owns horizontal registration, so an asymmetric pole does not shift the body. Source pixels are translated by integers without resampling. The original paintings remain unchanged. The manifest records input/output hashes, source rectangles, offsets and the authoring adapter hash at the time of registration. Each folder keeps an exact `registration-adapter.gd` snapshot matching that historical hash.

For a new source version:

```sh
godot --headless --path . -s res://pipeline/prepare_robot_movement.gd -- \
  --source res://art/source/robots/v0.72/<id>/<NEW-movement-version>
godot --headless --path . -s res://test/test_robot_movement_art.gd
```

The adapter refuses an existing atlas/registration. It is a guarded source preparation step for this review pack, not a second runtime build command. Normal selected game art still uses `scripts/art.sh`; these candidates are not selected in the runtime catalog or wired into the square’s existing 3D actors.

## Review outputs

```sh
godot --headless --path . -s res://tools/wick_tender_review.gd
scripts/play.sh --resolution 1600x1000 -s res://tools/wick_tender_review.gd
```

The headless tool writes documentation contact sheets and four GIF input frames per robot under `.cache/wick-tender-preview/`. Native mode plays the candidates as unmirrored billboards in the game camera beside the approved boy, with 704-cell atlas regions and wheel anchors. GIF previews use eight frames per second. Preview resizing never modifies the source atlas. The [gallery](../../../../docs/concept/v0.72/wick-tender-movement.md) links all full-resolution views and the complete atlases.
