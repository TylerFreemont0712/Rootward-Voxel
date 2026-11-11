# Spindle Lane gate and garden revision

Direct user revision, 2026-11-02. `haverlund-lane-set/v1/model.blend` and `haverlund-lane-surround/v1/model.blend` remain the adopted editable masters. Each retains `model.pre-lane-believability.blend` and a hash record.

`refine.py` is a guarded, one-time source edit, not a regenerator. It removes only damaged gate pieces, copies the complete intact pieces from `model.pre-square-gate.blend`, and gives the two leaves separate hinge pivots (`door_leaf_lane_left/right`, `swing` extras). Stair travel drives them through the existing DoorSwing/room-link contract. Added handrails follow the original treads on both sides; the old high solid cheeks on the first short flight are removed. Garden-edge guards protect the visible drops.

The surrounding master's existing flat top faces are subdivided with interpolated UVs and reassigned to complete garden parcels, house yards and connecting streets. Retaining walls, levels, treads and power inlays stay in the adopted geometry. The area document removes thirteen of 31 background house placements and adds orchards, planting, a shed, barrel and bench. Houses and their masters are not deleted. `finish_uv.py` supplies explicit UV layers on the untextured new handrails so the normal geometry audit includes them.

Export only through `scripts/world-art.sh build haverlund-lane-set` and `scripts/world-art.sh build haverlund-lane-surround`. Further edits should use the saved masters. Review: `pipeline/reviews/2026-11-02-lane-errands-and-development.md`. The accepted boy, camera, existing house artwork and player saves are preserved.
