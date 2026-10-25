# v0.6 — How AI voxel art can become a playable game

Current implementation update, 2026-10-23: the [Blender handoff](../../../pipeline/BLENDER.md) is now working for house shells and static land. Existing `.blend` files are visually editable masters; selected GLBs are audited runtime outputs. The [character decision/research](../../../pipeline/research/2026-10-23-character-animation.md) records why the layered rig is inactive: preserve the approved painted sprite, smooth its whole-body playback, and correct missing gait poses before expanding. The initial exploration below remains context; current paths/selections are in [the active pipeline](../../../pipeline/README.md).


Research checked 2026-10-22 against publisher documentation, model cards and this machine's existing files. This is a tool/pipeline recommendation, not a claim that any new generation workflow has been benchmarked here. The staged build is in the [prototype spec](04-voxel-world-prototype-spec.md).

## 1. The answer to the YouTube question

**Yes: the impressive voxel scenes made with Claude or ChatGPT can be useful for game creation. The crucial question is what files and structure the AI produced.**

No specific videos were supplied, so their exact tools cannot be identified. The following are common technical routes that can produce similar-looking results; they are not an identification of the user's videos.

| What the demonstration may be doing | Where the scene actually lives | Can it become game content? |
|---|---|---|
| AI writes JavaScript that assembles boxes and lights | Three.js in a browser, possibly inside a chat preview | Yes: actual meshes can be exported or regenerated. Browser gameplay code and special shaders need a separate Godot implementation. |
| AI writes a Python script that builds a scene | Blender, controlled by script or an optional integration | Yes: save editable source, export geometry/materials/animations, then add Godot behaviors and collision. This is the preferred starting route here. |
| AI writes voxel data or a generator for a voxel editor | A `.vox` file or another volume/scene format | Yes: keep the source voxel data, then convert/export using a verified tool. The game still needs semantics for parts and edits. |
| AI image generation paints a voxel-looking scene | A raster image, such as PNG | Useful as concept art, textures, sprites or a background. It has no 3D geometry merely because it looks three-dimensional. |
| A separate image-to-3D model reconstructs an object | ComfyUI or another 3D-generation pipeline | Produces a mesh candidate. Inspect and clean it, split moving parts, define pivots and add gameplay data before accepting it. |

For example, code can describe a cottage as a plaster volume, beams, window recesses, roof segments and a separate hinged door. Blender or Three.js builds those objects. The AI is writing modeling instructions; it does not need to generate an image first. That cottage can be rotated, lit, reused and animated after export.

A whole diorama can also be one fused decorative mesh. It is genuine 3D but may offer little usable structure for programming. Real geometry, separately addressable parts, and a world simulation are three different deliverables.

## 2. How to recognize a reusable result

Ask these questions when assessing a video or downloadable example:

1. Does the result include source code, `.blend`, `.vox`, `.glb` or `.gltf`, rather than only a screenshot or rendered video?
2. Can the camera inspect the back and sides? Are those surfaces modeled and coherent?
3. Are the door, wheel, bridge sections and other moving parts separate and named? Do they have useful pivots?
4. Can the project regenerate an asset at an exact size and palette, rather than require another unrelated prompt?
5. Does it remain readable at the game camera's actual size, with ordinary runtime lighting?
6. Does interacting with it affect occupancy, state and saved data, or only play a visual animation?
7. How much cleanup, draw-call cost and manual authoring sits outside the edited demonstration?

The most transferable AI deliverable is usually **a small generator plus editable models and a catalog**, not a single spectacular scene. A model file still does not contain the programming game: its state rules, quest facts, UI and persistence must be designed.

## 3. Recommended toolchain for this game

```text
Style reference and a modular asset contract
                  ↓
Claude Code or Codex writes/revises a Blender generator
                  ↓
Editable, unsheared geometry + shared materials + named parts
                  ↓
GLB export + footprint/pivot/socket metadata
                  ↓
Godot prefab + logical entity components + simple collision
                  ↓
In-game movement, programming, lighting and performance review
```

The original Rootward world pipeline demonstrates scripted Blender modeling, but its generator shears the result to make 2D oblique sprites. This project builds real unsheared geometry in an independent pipeline.

### Blender as the main production tool

Start with flat/palette materials and parameterized primitives. AI is useful for generating beams, roofs, blocky trees, bridge modules, fences, lamp bodies and mechanical assemblies to exact dimensions. Manual edits and the source generator remain available. Build one attractive small kit and expand its vocabulary after the playable slice works.

Export `.glb` as the runtime handoff. Godot supports glTF scenes; it can also import `.blend` by invoking Blender's exporter. Explicit GLB export makes the runtime input clear and avoids requiring Blender whenever someone opens the game. See [Godot's supported 3D formats](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

Do not treat a Blender render as the acceptance image. The accepted result is the asset in Godot, at gameplay distance, with the game's character, shadows, selection and code panel.

### Three.js as a sketch tool

Three.js is a plausible explanation for a browser-based AI voxel demo. Its [GLTFExporter](https://threejs.org/docs/pages/GLTFExporter.html) exports scene data to glTF/GLB. That makes a geometry transfer possible; it does not export a complete Godot game. JavaScript systems, engine-specific effects, collision, input and UI need implementation in the destination engine.

If a reference scene is already in Three.js, preserve its object/generator data and test export. For new production assets here, generating directly in Blender avoids maintaining an additional browser pipeline. A Three.js sketch remains useful for quickly comparing shapes and composition.

### Dedicated voxel editors

[MagicaVoxel](https://ephtracy.github.io/mv_main.html) is a free voxel editor/renderer whose official downloads target Windows and macOS. It is an optional art tool, not a required Linux dependency for this project. The developer publishes the [VOX file format](https://github.com/ephtracy/voxel-model/blob/master/MagicaVoxel-file-format-vox.txt), so a coding agent can also write a generator that outputs voxel data.

A `.vox` source is not the selected Godot runtime format in this proposal. Validate an exporter/converter and preserve the original data if using that route. Dense sculptural voxel models may need merging, hidden-face removal or remeshing before they meet runtime budgets. Voxel-looking modular meshes made in Blender can achieve the selected style without requiring `.vox` files at all.

## 4. Claude versus ChatGPT/Codex

For this task the important distinction is the tool's job, not a claim that one vendor always makes better voxel art.

| Job | Recommended use |
|---|---|
| Establish the look | Use the selected v0.6 image as the reference. ChatGPT image generation or local ComfyUI can help explore shapes, materials and characters. |
| Produce editable geometry | Ask Claude Code or Codex to write a Blender Python generator with explicit units, named parts, pivots and GLB output. Run it, inspect the model, then revise the source. |
| Build the playable prototype | Use a coding agent with repository, shell and Godot access to implement one stage at a time and inspect actual output. |
| Review consistency | Give the agent gameplay-scale captures and the asset contract; have it identify mismatched proportions, missing parts and import issues. Human review still selects the art. |

[Claude Code's official overview](https://code.claude.com/docs/en/overview) documents codebase access, file editing and command execution. OpenAI's [Codex game-building example](https://learn.chatgpt.com/use-cases/browser-games) documents a code/run/inspect game workflow. These support the proposed roles; they do not establish a comparative voxel-modeling quality benchmark. There is no evidence here for buying another subscription to get a particular voxel look.

OpenAI's documented [image-generation tool](https://developers.openai.com/api/docs/guides/tools-image-generation) returns image output. Treat that workflow as image creation; an image-to-3D system or a modeling step is a separate handoff. The proposed geometry workflow does not require calling an image API.

Use whichever coding assistant already fits the workspace, and compare results on the same small asset brief if desired. Save the generator and intermediate model so changing assistants does not discard the work. Optional Blender/Godot integrations can improve feedback, but a script, CLI and screenshot loop is sufficient to start. The game itself remains local and does not require Claude, ChatGPT or ComfyUI to run.

### Example asset brief for either coding assistant

> Build an editable voxel-inspired fantasy cottage in Blender using Python. Use real, unsheared geometry, one logical cell per world unit, and a 4 × 4-cell footprint. Use a 1/8-cell modeling increment, chunky readable shapes, cream plaster, warm timber, muted violet roof and amber window accents. Keep roof, walls, door leaf and door frame separately named. Put the door pivot on its hinge and the asset root at the declared ground anchor. Use shared simple materials. Export GLB and an asset record with dimensions, footprint, pivot, orientation, material roles and interaction sockets. Preserve the generator and editable source. Produce a gameplay-scale Godot review before accepting it.

This is a production brief for the assistant, not executable code or a guarantee of first-pass quality. Revise it around the actual kit after stage 3 establishes scale and camera.

## 5. What is already installed locally

Read-only inventory on 2026-10-22:

| Item | Observed state | Implication |
|---|---|---|
| Godot | `4.7.2.stable.official.ed1daf0bf` | Use the installed build for the initial experiment. |
| GPU | NVIDIA RTX 3070 Ti Laptop GPU, 8,192 MiB VRAM | Use an 8 GB local memory budget. Free memory at inspection was about 7,766 MiB, not an inference benchmark. |
| ComfyUI | Existing installation at `~/personal-project/ComfyUI` | No reason to create another installation before testing its existing capabilities. |
| SDXL base | `models/checkpoints/sd_xl_base_1.0.safetensors` | A known base for optional SDXL style-reference experiments. |
| Existing image style | Nova Anime XL/Illustrious checkpoint and Pixel Art XL v1.1 LoRA | Current pipeline assets, not a voxel production requirement. |
| Native 3D code | `comfy_extras/nodes_trellis2.py`, `nodes_hunyuan3d.py` | Node source exists on disk; successful node loading/generation has not been checked in this task. |
| TRELLIS.2 model | `diffusion_models/trellis_2_int8_convrot.safetensors` | Present, about 4.89 GiB on disk. File size is not total VRAM use. |
| TRELLIS.2 shape/texture VAEs | `vae/trellis_2_shape_vae_bf16.safetensors`, `trellis_2_texture_vae_bf16.safetensors` | Both present. |
| Image encoder/background removal | `clip_vision/dino_v3_L_naf_fp32.safetensors`, `background_removal/birefnet.safetensors` | Present. |
| Voxel/isometric LoRAs below | Not found in the local LoRA inventory | Optional candidates, not installed or quality-tested. |

The existing world style file explicitly discourages `isometric` and `3d render`, and adds Pixel Art XL. A voxel concept workflow needs its own prompts/settings; reusing that file unchanged would work against the desired look. The earlier Rootward world style manifest favored flat pixel art and is kept as historical reference only.

Do not run Blender and ComfyUI at the same time on this laptop. The existing GPU guard is in `scripts/gpu-guard.sh` in the original Rootward project. This research did not start either application, install nodes, download weights or generate new large assets.

## 6. Do we need voxel LoRAs?

**No LoRA is required for the recommended game-asset pipeline.** Claude/Codex generating geometry through Blender does not use a diffusion LoRA. A LoRA can help produce consistent *pictures* for art direction; it does not supply modular topology, hinges, collision or a world API.

If local concept generation is useful, test a no-LoRA SDXL baseline first and then one style adapter at a time:

| Candidate | Documented base / trigger | Intended use and status |
|---|---|---|
| [Fictiverse / Voxel XL](https://huggingface.co/Fictiverse/Voxel_XL_Lora) | SDXL 1.0; `voxel style`; file `VoxelXL_v1.safetensors` | Optional blocky style references. Publisher card labels the license `openrail`. Not installed or benchmarked here. |
| [ntc-ai / isometric-view slider](https://huggingface.co/ntc-ai/SDXL-LoRA-slider.isometric-view) | SDXL; `isometric view`; file `isometric view.safetensors` | Optional camera/composition exploration. Publisher card labels it MIT. It encourages a view; it cannot enforce exact game grid projection. Not installed or benchmarked here. |
| Existing Pixel Art XL v1.1 | Local metadata identifies SDXL 1.0 | Keep available for sprite experiments. It is not necessary for the 3D world, and a strong pixel treatment may obscure the desired material/shape study. |

Use adapters with the documented base family. An SDXL adapter is not interchangeable with a FLUX or TRELLIS model. Do not assume that a checkpoint built on a related XL architecture will respond identically. The SDXL base and each adapter have their own terms/provenance to record with accepted work; the table is not a complete release-license review.

### Optional ComfyUI 2D reference workflow

The [official LoRA guide](https://docs.comfy.org/tutorials/basic/lora) describes installing an adapter in `ComfyUI/models/loras` and loading it with `Load LoRA` between the checkpoint and downstream model/CLIP consumers.

Proposed graph:

```text
Load Checkpoint: SDXL base
  → optional Load LoRA: Voxel XL
  → positive/negative CLIP text encodes
  → KSampler with an Empty Latent Image
  → VAE Decode
  → Save Image
```

Connect the adjusted MODEL output to the sampler and the adjusted CLIP output to both text encoders; use the checkpoint VAE for decode. This is a graph recipe, not a supplied or tested workflow JSON.

For an initial comparison, use batch 1, a fixed seed, a single centered object, about 768 × 768 then 1024 × 1024 if memory permits. Compare no adapter against a few moderate strengths, initially around 0.4–0.8, with the same prompt and seed. These are test settings, not publisher-recommended optimal values. Test the isometric slider separately before combining adapters.

Example subject prompt: `voxel style, orthographic three-quarter view of a small fantasy timber and cream-plaster workshop, muted violet roof, chunky coherent forms, separate readable doorway, restrained detail, neutral plain background, full object visible`. Avoid a whole village when evaluating a single reusable asset. Save model/version, seed, settings, prompt and workflow with the accepted reference.

## 7. Can ComfyUI make actual 3D?

**Yes.** Its 3D workflows are separate from ordinary image generation and image LoRAs.

### TRELLIS.2: the first optional test here

The [official ComfyUI tutorial](https://docs.comfy.org/tutorials/3d/trellis2) describes native image-to-3D generation, using structure, shape and texture stages followed by mesh processing. The resulting asset is a textured mesh candidate, even though the model uses a sparse voxel representation internally. It is not automatically an editable Minecraft-style game volume.

Several files named in that workflow are already on this machine. However, the tutorial's combined Pixal3D/TRELLIS.2 template lists both diffusion checkpoints, and the local inventory did not find Pixal3D. Either provide that template's dependencies later or make an isolated TRELLIS-only graph and check it loads. Having most weights on disk does not establish a working workflow.

The upstream [Microsoft TRELLIS.2 reference implementation](https://github.com/microsoft/TRELLIS.2) specifies at least 24 GB of GPU memory. ComfyUI's native path uses a different implementation and quantized weights; that reference requirement does not prove the local path impossible, nor does a quantized checkpoint prove it fits in 8 GB. The reviewed ComfyUI tutorial does not state an 8 GB guarantee. Measure the local path in a small, bounded experiment before depending on it.

Use one isolated prop as input. Prefer a sculpture, rock or organic decorative object where free-form reconstruction might save work. A hinged gate or exact bridge is usually a better procedural modeling task. Inspect back faces, underside, dimensions, texture seams, fused parts and polygon/material cost. Simplification and baking can reduce rendering cost; they do not infer useful hinges or gameplay components.

### Hunyuan3D: a fallback candidate, not another installation task now

The [Hunyuan3D-2 publisher repository](https://github.com/Tencent-Hunyuan/Hunyuan3D-2) reports approximately 6 GB for shape generation and 16 GB for shape plus texture in its reference pipeline. That makes a shape-only trial potentially relevant to this laptop, with simple materials applied afterward. Do not generalize those numbers to every Hunyuan version or assume the complete textured workflow fits.

Local Hunyuan node source exists; this inventory did not establish that the required model weights are installed. Evaluate an exact model/workflow only if the existing TRELLIS.2 test or procedural route leaves a useful unmet need.

### Local versus remote nodes

ComfyUI also contains partner/API nodes. Their appearance in the node list does not mean inference runs locally. For this proposal, use local weights and local workflows. No new hosted art service, credit balance, model purchase or always-online game dependency is required.

## 8. The small art experiment to run later

This is an optional stage 4 experiment after the graybox establishes camera and scale. Run the AI trials only if they address an unmet art need and their dependencies are available. The procedural kit can pass the art gate independently. This is a plan, not completed work.

1. **Procedural baseline:** make a lamp and hinged gate from the same Blender palette/material kit. Preserve source code, dimensions and named moving parts; export to Godot.
2. **Reference test:** make a voxel concept for one decorative prop with SDXL, first without a LoRA and then with one optional candidate. Decide whether the style adapter improves consistency enough to keep.
3. **3D trial:** feed one clean single-object reference into an isolated local TRELLIS.2 workflow. Start at the lowest offered useful settings. Record peak memory, time, failures and output size; change one variable at a time. Stop escalating resolution if the local workflow is impractical.
4. **Cleanup:** inspect and simplify the generated mesh in Blender after ComfyUI releases the GPU. Assign the kit's materials or preserve textures only if they fit. Set scale, anchor, collision and metadata; split parts if required.
5. **Game review:** compare both methods in the same Godot review scene, under the same camera/lighting. Check several instances and a state change. A transparent or smooth-turntable preview does not count as a gameplay review.
6. **Decision:** compare complete effort, repeatability, useful separation, style, runtime cost and regeneration. Keep procedural modeling for exact modules; keep image-to-3D only where it measurably helps. If it fails the 8 GB gate, the main art pipeline still works.

Record a compact result table:

| Asset/method | Generation time | Cleanup time | Peak VRAM | Mesh/material cost | Separate useful parts? | In-game result | Keep? |
|---|---|---|---|---|---|---|---|
| Procedural lamp/gate | Pending | Pending | Pending | Pending | Pending | Pending | Pending |
| Optional generated prop | Pending | Pending | Pending | Pending | Pending | Pending | Pending |

For accepted assets, preserve the generator or workflow, source/model identifiers, seed/settings when applicable, editable source, runtime export, metadata and one useful review image. Keep caches and rejected takes out of the durable concept folder. Add production assets to the existing asset-provenance record when there are actual assets to integrate.

## 9. Recommendation and what remains unknown

Use **Godot + modular voxel-inspired 3D + an AI-assisted Blender kit** as the first implementation hypothesis. Treat clean sprite characters as a testable art choice. Use image generation for direction and optional local 3D generation for selected props, rather than making either a dependency for world construction.

The ability to program the world comes from the [state and command contract](04-voxel-world-prototype-spec.md#4-the-authoritative-world-model). The art must expose parts and interactions that support that contract. Neither a voxel LoRA nor changing the camera replaces that design work.

Unresolved until the prototype: which character treatment reads best, how much height adds to play, whether local TRELLIS.2 completes within practical memory/time, which optional adapter improves the actual style, and whether authoring a second area is easier in practice. The exact tools used in the user's YouTube examples also remain unknown without those examples.
