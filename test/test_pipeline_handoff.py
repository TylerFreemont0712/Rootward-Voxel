"""Check the active pipeline boundary and handoff links without art services."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
checks = 0


def check(condition, message):
    global checks
    assert condition, message
    checks += 1


def resource_exists(value):
    return (root / value.removeprefix("res://")).is_file()


art = json.loads((root / "pipeline/art-catalog.json").read_text())
for key in ("template", "source", "provenance", "prompt", "runtime_sheet", "frames", "manifest"):
    check(resource_exists(art["character"][key]), f"Missing selected character {key}")
# Painted interface frames: the authored source is unchanged and the built frame and manifest match it.
for frame_id, frame in art.get("interface_frames", {}).items():
    frame_source = root / frame["source"].removeprefix("res://")
    check(frame_source.is_file() and hashlib.sha256(frame_source.read_bytes()).hexdigest() == frame["source_sha256"], f"Interface frame source changed: {frame_id}")
    check(resource_exists(frame["provenance"]), f"Missing interface frame provenance: {frame_id}")
    check(resource_exists(frame["runtime"]) and resource_exists(frame["manifest"]), f"Interface frame not built: {frame_id}. Run scripts/art.sh.")
    built = json.loads((root / frame["manifest"].removeprefix("res://")).read_text())
    runtime_bytes = (root / frame["runtime"].removeprefix("res://")).read_bytes()
    check(built["source_sha256"] == frame["source_sha256"] and built["runtime_sha256"] == hashlib.sha256(runtime_bytes).hexdigest(), f"Interface frame build is stale: {frame_id}. Run scripts/art.sh.")
skins = json.loads((root / "pipeline/character-catalog.json").read_text())
check(skins["mode"] == "shared_frame_skins", "Inactive pipeline selected")
check(resource_exists(skins["runtime_library"]), "Compiled skin library missing")
world = json.loads((root / "pipeline/world-catalog.json").read_text())
for asset, entry in world["assets"].items():
    check((root / entry["source"]).is_file(), f"Missing world source: {asset}")
    check((root / entry["runtime"]).is_file(), f"Missing world output: {asset}")
textures = json.loads((root / "pipeline/texture-catalog.json").read_text())
for set_name, base in textures["sets"].items():
    for material, entry in textures["materials"].items():
        check(resource_exists(base + entry["texture"] + ".png"), f"Missing {set_name} texture {entry['texture']} for {material}")
catalog_hash = hashlib.sha256((root / "pipeline/texture-catalog.json").read_bytes()).hexdigest()
# Ground-only additions need no rebake. Validate the exact recorded ancestor and every baked recipe;
# edits to a picture, tint, tile or set still invalidate the handoff. Never rewrite adopted sources.
compatible_hash = None
if textures.get("compatible_bake_catalog"):
    ancestor = root / textures["compatible_bake_catalog"]
    previous = json.loads(ancestor.read_text())
    check(previous["sets"] == textures["sets"], "Baked texture set paths changed")
    check(previous["set"] == textures["set"], "Baked texture selection changed")
    for material, recipe in previous["materials"].items():
        current = {key: value for key, value in textures["materials"].get(material, {}).items() if key != "ground"}
        check(current == recipe, f"Baked material {material} changed: retexture and rebuild required")
    compatible_hash = hashlib.sha256(ancestor.read_bytes()).hexdigest()
for asset, entry in world["assets"].items():
    note = (root / entry["source"]).parent / "retexture.json"
    if note.is_file():
        check(json.loads(note.read_text())["texture_catalog_sha256"] in (catalog_hash, compatible_hash),
              f"{asset} was baked from an older texture catalog: run scripts/world-art.sh retexture {asset}, then build")
check(not (root / "assets/characters/DriectionCheck").exists(), "Temporary direction review returned to runtime assets")
check((root / "art/source/archive/.gdignore").is_file(), "Source archives must stay outside Godot import")
retired = ("res://assets/characters/DriectionCheck/", "res://art/cutout_", "res://art/rigs/chibi_v1/",
           "res://assets/characters/adventurer-cutout/", "res://art/adventurer.gd",
           "res://pipeline/build_character.gd", "res://pipeline/seed_character_rig.gd")
for folder in ("app", "core", "scenes", "ui", "art", "pipeline", "scripts", "tools", "assets"):
    for file in (root / folder).rglob("*"):
        if not file.is_file() or file.suffix not in (".gd", ".tscn", ".tres", ".json", ".sh"):
            continue
        if file.is_relative_to(root / "art/source"):
            continue
        text = file.read_text()
        check(not any(path in text for path in retired), f"Active file depends on retired experiment: {file.relative_to(root)}")
documents = ["README.md", "AGENTS.md", "docs/PROJECT_HANDOFF.md", "docs/PROGRAMMING.md",
             "pipeline/README.md", "pipeline/CHARACTERS.md", "pipeline/REVIEW.md",
             "pipeline/BLENDER.md", "pipeline/WORLD_ASSETS.md", "pipeline/AREAS.md", "pipeline/GROUND.md", "pipeline/BUILD.md",
             "reference/README.md", "sandbox/README.md", "pipeline/BUILDER_LIBRARY.md",
             "pipeline/reviews/2026-10-24-builder-library.md", "art/source/world/village-library/v1/README.md",
             "pipeline/DIALOGUE.md", "pipeline/reviews/2026-10-24-village-dialogue.md", "art/source/portraits/v1/README.md"]
for name in documents:
    file = root / name
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", file.read_text()):
        target = target.split("#", 1)[0].strip("<>")
        if not target or "://" in target:
            continue
        check((file.parent / target).exists(), f"Broken handoff link: {name} -> {target}")
check("evidence/*.png" not in (root / ".gitignore").read_text(), "Selected visual evidence must travel with the project")
print(f"Active pipelines and handoff links: {checks} checks passed.")
