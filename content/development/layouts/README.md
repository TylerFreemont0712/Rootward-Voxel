# Player-authored layout drafts

In Sparks & Machines, open **Layout · B** in Rootward Square. Paint paths, place park pieces and arrange barriers, then choose **Done**. The campaign saves the edit layer; in a writable source checkout, the builder also writes **`haverlund-square.json` here**.

The snapshot contains `schema`, `area`, `base_version`, `edits` and the effective `document`. It is for review and handoff to the coding assistant, and never automatically replaces `content/areas/haverlund-square.json`. The campaign save remains authoritative for Continue. Do not overwrite a user's draft with review fixtures; native tools write to `.cache/` instead.

[Controls](../../../docs/concept/v0.8/square-layout.md).

The v7 flat-layout sketch is preserved through the v8 terrace restoration. Its byte-identical backup is `content/areas/archive/haverlund-square-v7-layout-sketch.json`. Campaign saves retain retired edits in layout metadata; new edits apply to the restored terrace.
