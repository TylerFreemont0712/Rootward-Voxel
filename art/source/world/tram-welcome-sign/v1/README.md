# Tram welcome sign — saved Blender master

`model.blend` is the adopted editable authority. New geometry: cream enamel frame, brass bezel/feet/rivets, teal posts/weather hood, dark two-row glass, physical SPINDLE LANE nameplate, service enclosure/socket and a small painter's tool rest. No bitmap texture or network service is required.

`author.py` records the protected one-time initialization and the separate deliberate garden-gate extraction. It refuses existing source; do not use it to regenerate the adopted model. `detail.py` records the subsequent saved-master nameplate/socket revision and also refuses a repeat. Make further changes to the saved master.

Blender +X/+Y correspond to area x/y; Z is up. Front is Blender −Y. `SignFace` is the text centre; `SlateSocket` is the cord endpoint. Both export as named empty anchors. The presenter attaches fixed-advance warm lettering to SignFace and reads only committed/preview card data. Source posts stand one cell either side of centre; the area document owns their collision rectangles and the reachable approach. The current asset placement is `[9,7]`, height 1, west of the tram steps; writing approach is `[9,6]`. The user's rearrangement reuses this unchanged master. [Latest placement/interface review](../../../../../pipeline/reviews/2026-11-02-tram-stop-and-shared-slate.md).

Build with `scripts/world-art.sh build tram-welcome-sign`. Audited output is `assets/world/tram-welcome-sign/model.glb` plus its normal manifest. `pipeline/world-catalog.json` registers it through the existing world pipeline.

The garden gate uses the lane's existing master, preserved pre-edit backup and `welcome-gate.json` record. `welcome-gate-scope.py` gives its parent an explicit `door_group` extra so opening the town steps never opens the garden gate. Braum's presentation controller opens it as he approaches; logical passages remain area-owned.

Requests: `20261102T071738-e41675af` (new sign), `20261102T071738-826a7b45` (garden hinge). [Gameplay/asset review](../../../../../pipeline/reviews/2026-11-02-welcome-quest-and-property.md).
