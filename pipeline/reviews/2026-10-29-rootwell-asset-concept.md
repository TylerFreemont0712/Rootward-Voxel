# Rootwell landmark concept — 2026-10-29

The user wanted a closer concept study of the square’s central power source, then clarified **no background and multiple views**. The front and opposite rear drawings were approved, with the final destination corrected to **v0.72**.

Selected gallery: [Rootwell beacon](../../docs/concept/v0.72/rootwell-beacon.md). Versioned source: [`art/source/world/square-beacon/concept-v1/`](../../art/source/world/square-beacon/concept-v1/README.md).

## Result

- Two complete 1024×1536 isolated RGBA paintings, front and opposite rear, with transparent backgrounds and soft local amber glow.
- The public pressure gauge, notice board/perch and front-side maintenance door are distinct from the rear service panel, risers and relief hardware.
- The copper crown, glowing living root, glass bell, stone drum, shallow octagonal steps and integral planters preserve the approved Guildhall Square landmark.
- Source paintings and exact generation prompts are preserved. The earlier contextual close-ups and repeated-angle sheet are retained as unselected history. No Python/image-processing edits were used; final PNGs are copied intact.

## Review and checks

The images were inspected at full resolution for complete finials/steps, silhouette, public/service-side distinction and coherent materials. RGBA/alpha metadata and byte-identical gallery copies are checked. This is a concept review; the supplied art does not change the in-game mesh or placement.

The full `scripts/test.sh` passed during this art pass (log `.cache/rootwell-concept-full-test.log`). All five generation records, exact prompt/reference/output hashes, two byte-identical gallery copies, true PNG alpha, gallery links and five protected source/catalog/square files passed verification. The focused handoff check passed 1,373 checks after the documentation updates; `git diff --check` passed. The existing beacon `.blend`/GLB, selected square artwork, catalogs and playable area are preserved.

The accepted next reference is the isolated front/rear pair. Refining the adopted model, its gauge decal and exact construction is future implementation work through the normal world-art pipeline. This concept pass does not mark an unchanged runtime model finished in the asset work queue.
