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


# Pictures and models live in release packs (media.lock), fetched by scripts/fetch-media.sh; the art sources are in
# the `dev` packs, which a player's checkout need not fetch. A file counts as present when it is on disk or pinned in
# the lock, so a link to a source nobody fetched is still checked to exist somewhere.
LOCKED = {line.split("\t")[4] for line in (root / "media.lock").read_text().splitlines() if line.startswith("file\t")}


def present(path):
    path = Path(path)
    if path.exists():
        return True
    try:
        rel = path.resolve().relative_to(root).as_posix()
    except ValueError:
        return False
    return rel in LOCKED or any(name.startswith(rel + "/") for name in LOCKED)


def resource_exists(value):
    return present(root / value.removeprefix("res://"))


art = json.loads((root / "pipeline/art-catalog.json").read_text())
for key in ("template", "source", "provenance", "prompt", "runtime_sheet", "frames", "manifest"):
    check(resource_exists(art["character"][key]), f"Missing selected character {key}")
# Painted interface frames: the authored source is unchanged and the built frame and manifest match it.
for frame_id, frame in art.get("interface_frames", {}).items():
    frame_source = root / frame["source"].removeprefix("res://")
    if frame_source.is_file():
        check(hashlib.sha256(frame_source.read_bytes()).hexdigest() == frame["source_sha256"], f"Interface frame source changed: {frame_id}")
    else:
        check(resource_exists(frame["source"]), f"Missing interface frame source: {frame_id}")
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
    check(present(root / entry["source"]), f"Missing world source: {asset}")
    check(present(root / entry["runtime"]), f"Missing world output: {asset}")
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
        baked = {key: value for key, value in recipe.items() if key != "ground"}
        check(current == baked, f"Baked material {material} changed: retexture and rebuild required")
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
# Every maintained manual, concept note and review: a link to a file that no longer exists is a failure.
documents = [root / name for name in ("README.md", "AGENTS.md", "reference/README.md", "sandbox/README.md", "test/README.md")]
for folder in ("docs", "pipeline"):
    documents += sorted((root / folder).rglob("*.md"))
for file in documents:
    if not file.is_file():
        continue
    name = file.relative_to(root)
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", file.read_text()):
        target = target.split("#", 1)[0].strip("<>").split(" ")[0]
        if not target or "://" in target or target.startswith("mailto:"):
            continue
        check(present(file.parent / target), f"Broken handoff link: {name} -> {target}")
lines = (root / ".gitignore").read_text().splitlines()
media_block = lines[lines.index("# >>> media"):lines.index("# <<< media")]
check("*.png" in media_block and "*.glb" in media_block and "*.blend" in media_block, "Pictures and models must stay out of git (media.lock)")
check(any(name.startswith("evidence/") for name in LOCKED), "Linked review captures must stay pinned in media.lock")
print(f"Active pipelines and handoff links: {checks} checks passed.")
