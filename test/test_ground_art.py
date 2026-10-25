"""Independent validation of the authored ground-art handoff (offline authoring Python)."""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / "art/source/world/ground/v1/manifest.json").read_text())
checks = 0


def check(ok, message):
    global checks
    assert ok, message
    checks += 1


check(len(manifest["records"]) == 12, "Six heights and six reference paintings are preserved")
for record in manifest["records"]:
    for role in ("native", "master", "candidate", "runtime", "reference", "albedo"):
        if role not in record:
            continue
        artifact = record[role]
        path = root / artifact["path"]
        check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == artifact["sha256"], f"Stale {role}: {path}")
    master = Image.open(root / record["master"]["path"]).convert("RGB")
    check(master.size == (1024, 1024), "All masters are 1024 square")
    if record["kind"] == "ref":
        reference = Image.open(root / record["reference"]["path"]).convert("RGB")
        check(reference.size == (512, 512), "Reference sheets are 512 square")
        check(reference.tobytes() == master.resize((512, 512), Image.Resampling.BOX).tobytes(), "References derive from their masters")
        check("runtime" not in record, "Concept reference stays outside runtime")
        continue
    final = Image.open(root / record["candidate"]["path"]).convert("RGB")
    pixels = np.array(final)
    check(final.size == (128, 128), "Height is 128 square")
    check(np.array_equal(pixels[:, :, 0], pixels[:, :, 1]) and np.array_equal(pixels[:, :, 1], pixels[:, :, 2]), "Height is grayscale")
    check(len(final.getcolors(256) or []) <= 8, "Height uses at most eight gray levels")
    check(np.array_equal(pixels[0], pixels[-1]) and np.array_equal(pixels[:, 0], pixels[:, -1]), "Opposite height edges match")
    check(final.tobytes() == master.resize((128, 128), Image.Resampling.BOX).tobytes(), "Height is the exact master BOX average")
    rgb = np.asarray(Image.open(root / record["albedo"]["path"]).convert("RGB"), dtype=float)
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
    blur = sum(np.roll(np.roll(lum, x, 1), y, 0) for x in (-1, 0, 1) for y in (-1, 0, 1)) / 9
    correlation = float(np.corrcoef(blur.ravel(), pixels[:, :, 0].ravel())[0, 1])
    check(abs(correlation - record["correlation"]) < 1e-9, "Correlation record matches the actual pixels")
    check(record["accepted"] == (correlation >= 0.55), "Only aligned heights are accepted")
print(f"Ground art handoff: {checks} checks passed.")
