# City cycle and civic lobby — source records

- `revise.py`: guarded deliberate edit of the existing Rootwell and guild hall masters, preserving `model.pre-city-cycle.blend` and recording before/after hashes beside each source.
- `finish_gauge.py`: recorded follow-up retaining UVs on the two added gauge bands and keeping the coloured scale behind the original moving needle. Refuses a second application.
- `shared_clock.py`: separates the hall’s two original hands, preserving their geometry/UVs and `model.pre-shared-clock.blend`. Refuses repeat application.
- `author_lobby.py`: one-time creation of `city-hall-shell`, `city-hall-help-desk`, `city-hall-job-desk`, using the existing square/lane kits and painted materials. Refuses any selected existing master. The shell’s first save succeeded before a provenance-path typo was corrected; its metadata records this.

Editable authority is each asset’s `art/source/world/<id>/v1/model.blend`, not these scripts. Runtime output uses the existing `scripts/world-art.sh build <id>` exporter and geometry/material audit. Layout, service approaches, collision, lights and reciprocal room links live in `content/areas/`.

Review: `pipeline/reviews/2026-11-02-city-clock-evening-and-hall.md`. No external image service, AI provider or new runtime dependency is required.
