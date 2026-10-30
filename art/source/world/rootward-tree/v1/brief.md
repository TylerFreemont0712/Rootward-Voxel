# Rootward — the village heart

Ancient oak, approximately 22 m wide and 24 m tall, compared with the 5 m cottage. Ground-centered pivot. Ten tapered roots stay inside the 8.6 m blocking radius (including the ward-stone ring); leafy overhang remains walkable underneath. Twisted bark, forked limbs, deep-to-sunlit layered crown and small amber heartwood fissures. No quest, cutting, climbing or magical command implied.

Original one-time geometry in `../../village-landmarks/v1/author.py`. The saved `model.blend` becomes the editable master. Edit it and run `scripts/world-art.sh build rootward-tree`; never rerun the author over an existing source. Existing painted library pictures are packed into the source/export. No network or authoring tools needed to play.

The user then requested a much larger mystical landmark. `enchant.py` deliberately edits the first saved master, keeping `model.pre-enchantment.blend`. `finish_uvs.py` completes solid-color UV channels and `ground_light.py` fits luminous seams to the actual bark/root surfaces, softens the ward stones and adds small canopy facets. Thirty lanterns, nine garlands, a ward ring and 84 editable wisp anchors are part of this master. `RootwardLight_*` and `RootwardWisp_*` drive the rendering-only `RootwardPresence` adapter; moving anchors in Blender moves the effects.

The subsequent visibility direction uses a permanent trunk-only cutaway during gameplay. The complete master/export remains unchanged. `art/rootward_presence.gd` consumes `extras.part` values `Crown` and `Boughs`; preserve those semantic roles when editing. `art/rootward_cutaway.gdshader` fades the upper visible model in tree-local height from 8 to 10 m, retaining the original surface pictures and emission. Root/ward collision stays at 8.6 m.
