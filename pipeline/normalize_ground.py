#!/usr/bin/env python3
"""Offline ground-art normalization, called by scripts/art.sh. Never a runtime dependency."""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image, PngImagePlugin

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/world/ground/v1"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    info = PngImagePlugin.PngInfo()
    info.add(b"sRGB", b"\x00")
    image.save(path, pnginfo=info)
    return {"path": str(path.relative_to(ROOT)), "sha256": digest(path), "size": list(image.size)}


def main():
    generation = json.loads((SOURCE / "generation.json").read_text())
    manifest_path = SOURCE / "manifest.json"
    if manifest_path.exists():
        for record in json.loads(manifest_path.read_text())["records"]:
            path = ROOT / record["native"]["path"]
            if digest(path) != record["native"]["sha256"]:
                raise SystemExit(f"Approved ground native changed: {path}. Author a new source version.")
    records = []
    prose = ["# Ground v1: image-generation record", "", "Tool: built-in `image_gen.imagegen`. Model and random seed are not exposed.", "",
             "Native outputs are preserved unchanged. Heights: nearest samples to 32×32, matching opposite-edge pairs averaged (no repainting), quantized to eight gray levels, enlarged with nearest to a 1024 master and BOX averaged to 128. Reference sheets: nearest samples to 64×64, nearest enlargement to a 1024 master and BOX average to 512; references never enter runtime assets.", "",
             "Each height is accepted only with matching opposite edges and Pearson correlation ≥0.55 against periodic 3×3-blurred sRGB albedo luminance at 128×128. Rejected candidates remain source artifacts; runtime computes its luminance fallback. Solid textures always use their own luminance fallback.", ""]
    for entry in generation["items"]:
        name, kind = entry["name"], entry["kind"]
        native_path = SOURCE / "native" / f"{kind}-{name}.png"
        native = Image.open(native_path).convert("RGB")
        if kind == "height":
            pixels = np.asarray(native.convert("L").resize((32, 32), Image.Resampling.NEAREST), dtype=float).copy()
            pixels[:, 0] = pixels[:, -1] = (pixels[:, 0] + pixels[:, -1]) / 2
            pixels[0, :] = pixels[-1, :] = (pixels[0, :] + pixels[-1, :]) / 2
            pixels = np.rint(np.rint(pixels / 255 * 7) * 255 / 7).astype("uint8")
            grid = Image.fromarray(pixels).convert("RGB")
        else:
            grid = native.resize((64, 64), Image.Resampling.NEAREST)
        master = grid.resize((1024, 1024), Image.Resampling.NEAREST)
        raw = save(master, SOURCE / "raw" / f"{kind}-{name}-1024.png")
        final = master.resize((128, 128) if kind == "height" else (512, 512), Image.Resampling.BOX)
        record = {"kind": kind, "name": name, "prompt": entry["prompt"], "native": {"path": str(native_path.relative_to(ROOT)), "sha256": digest(native_path), "size": list(native.size)}, "master": raw}
        if kind == "height":
            albedo_path = ROOT / f"assets/world/textures/lush/{name}.png"
            rgb = np.asarray(Image.open(albedo_path).convert("RGB"), dtype=float) / 255
            lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
            blurred = sum(np.roll(np.roll(lum, dx, 1), dy, 0) for dx in (-1, 0, 1) for dy in (-1, 0, 1)) / 9
            values = np.asarray(final.convert("L"), dtype=float)
            correlation = float(np.corrcoef(blurred.ravel(), values.ravel())[0, 1])
            edges = bool(np.array_equal(values[0], values[-1]) and np.array_equal(values[:, 0], values[:, -1]))
            accepted = edges and correlation >= 0.55
            record.update(albedo={"path": str(albedo_path.relative_to(ROOT)), "sha256": digest(albedo_path)}, correlation=correlation, edges_match=edges, accepted=accepted, fallback=not accepted)
            record["candidate"] = save(final, SOURCE / "height-candidates" / f"{name}.png")
            if accepted:
                record["runtime"] = save(final, ROOT / f"assets/world/ground/height/{name}.png")
            print(f"height {name}: r={correlation:.4f}, edges={edges}, {'accepted' if accepted else 'luminance fallback'}")
        else:
            record["reference"] = save(final, SOURCE / "reference" / f"{name}.png")
        records.append(record)
        prose += [f"## {kind}: {name}", "", f"Native SHA-256: `{record['native']['sha256']}`; master SHA-256: `{raw['sha256']}`.", "", "```text", entry["prompt"], "```", ""]
        if kind == "height":
            prose += [f"Correlation {correlation:.6f}; opposite edges match: {edges}; accepted: {accepted}.", ""]
    manifest_path.write_text(json.dumps({"version": 1, "tool": generation["tool"], "model": generation["model"], "seed": generation["seed"], "records": records}, indent=2) + "\n")
    (SOURCE / "prompts.md").write_text("\n".join(prose))


if __name__ == "__main__":
    main()
