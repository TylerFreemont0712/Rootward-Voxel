# Rootwell asset concept — v1

Two selected isolated asset views, approved by the user on 2026-10-29 and placed in [docs/concept/v0.72](../../../../../docs/concept/v0.72/rootwell-beacon.md).

| File | Role |
| --- | --- |
| `rootwell-front-threequarter.png` | Selected public front: pressure gauge, notices/perch and adjacent service door. |
| `rootwell-rear-threequarter.png` | Selected opposite rear: vented service panel, risers, relief fittings and valves. |
| `rootwell-hero-initial.png` | Initial contextual close-up; retained history. |
| `rootwell-hero-refined.png` | Gauge/framing refinement used as the isolated views’ reference. The user then clarified that the final art should have no scenery. |
| `rootwell-turnaround-initial.png` | Unselected first sheet: repeated front angle and insufficient framing gutters. |

The selected views are native 1024×1536 RGBA PNGs, copied intact with real transparency and a soft amber glow. Their documentation copies are byte-identical. The rear is independently generated from the same reference, showing the opposite service faces.

Built with the `image_gen.imagegen` tool. [prompts.json](prompts.json) contains every exact prompt, reference role and original generated path; [provenance.json](provenance.json) records input/output/prompt hashes, dimensions, alpha metadata and selected filenames. No seed or model identifier was exposed by the tool.

This is concept artwork. The adopted `../v1/model.blend`, runtime GLB, world catalog and area document remain authoritative and unchanged. A later model revision should interpret these drawings through the existing world-art build and gameplay-scale review. The earlier square painting remains the setting/composition reference.
