# Sparks & Machines foliage revision — 2026-10-30

The user requested simple, more recognisable plants in place of the repeated oval/sphere foliage. Thirty-five existing adopted masters now have tapered, gently folded leaves, small branching sprigs, pointed evergreen foliage and five-petal flower heads. This includes the loft and workshop, Spindle Lane's plants and trees, the square's planters and Rootwell planting, shop window boxes and the five modular seaside houses.

The existing `.blend` files remain authoritative. Every edited master has its original `model.pre-plant-style.blend` alongside it and a `plant-style.json` recording source hashes, changed objects and the fingerprint of surviving authored faces. No model was rebuilt from its initial authoring recipe. `revision.json` lists all delivered models. `bench_flower_stems.py` is the small review refinement connecting the bench planter's formerly floating flower heads to the new leafy stems.

`inspect.py` reads connected mesh pieces, using either named foliage materials or the packed house palette's original UV swatches. The older seaside masters use four palette rows; the newer shop/street models use five. Both retain their existing packed textures and UV colours. Fruit and vegetable displays share some flower/leaf swatches: those display groups are deliberately excluded, as are market-stall tomatoes, signs, grass blades, stems, vines and all robot models. The original pot, furniture, building, trunk and mechanical geometry is preserved.

`revise.py` records this deliberate source edit and refuses a second pass over a revised master. Future changes open the current saved model. `verify.py` compares all 35 saved sources with their backups: object identity, parentage, transforms, authored properties, every untouched mesh, protected faces within changed meshes, material values and packed texture hashes. `validation.json` records the passing audit. The audit is read-only for model files.

Normal export remains:

```sh
scripts/world-art.sh build loft-floor-plant
scripts/world-art.sh build lane-planter
scripts/world-art.sh build town-planter-bench
scripts/test.sh
```

The game uses the supplied GLBs, with no new runtime script or dependency. Placements, collision, saves, character art and camera settings retain their existing contracts. Runtime builds record geometry/material audits through the usual manifests.

[Review and selected captures](../../../../../pipeline/reviews/2026-10-30-plant-style.md). The grouped update request is `20261030T011223-8d5180d8`; delivery enters **Finished** for user review, not acceptance by the agent.
