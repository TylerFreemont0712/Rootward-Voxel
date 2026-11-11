#!/usr/bin/env python3
"""Offline RIFE authoring: immutable painted keys, alpha-aware loop in-betweens.

Uses the existing ComfyUI IFNet implementation and local weights; no server/API.
Never selects its output or overwrites an existing version directory.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--comfy-root", default=os.environ.get("COMFYUI_ROOT"))
    parser.add_argument("--model", default="models/frame_interpolation/rife_v4.26.safetensors")
    parser.add_argument("--output", default="art/source/adventurer/v3-smooth")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if not args.comfy_root:
        parser.error("Set COMFYUI_ROOT or --comfy-root to an existing authoring installation")
    comfy = Path(args.comfy_root).resolve()
    model_path = (comfy / args.model).resolve()
    out = (root / args.output).resolve()
    if not out.is_relative_to(root / "art/source") or out.exists():
        parser.error("Output must be a NEW version directory inside art/source")
    source = root / "art/source/adventurer/v2-isometric/sheet.png"
    source_hash = sha(source)
    sys.path.insert(0, str(comfy))
    import numpy as np
    from PIL import Image
    import torch
    import torch.nn.functional as F
    from safetensors.torch import load_file
    from comfy_extras.frame_interpolation_models.ifnet import IFNet, detect_rife_config

    device = "cuda" if torch.cuda.is_available() else "cpu"
    torch.set_num_threads(4)
    weights = load_file(str(model_path))
    weights = {k.removeprefix("module.").removeprefix("flownet."): v for k, v in weights.items()}
    for i in range(5):
        weights = {k.replace(f"block{i}.", f"blocks.{i}."): v for k, v in weights.items()}
    weights = {k: v for k, v in weights.items() if not k.startswith(("teacher.", "caltime."))}
    head, channels = detect_rife_config(weights)
    net = IFNet(head_ch=head, channels=channels, operations=torch.nn)
    net.load_state_dict(weights)
    net = net.eval().to(device)

    def intermediate(a, b, t):
        # Estimate flow on neutral-composited RGB, then apply that same flow to
        # premultiplied RGBA. This avoids an opaque backdrop or an extra matting AI.
        def tensor(image):
            arr = np.asarray(image).astype(np.float32) / 255
            rgba = torch.from_numpy(arr).permute(2, 0, 1).unsqueeze(0).to(device)
            rgba = torch.cat((rgba[:, :3] * rgba[:, 3:], rgba[:, 3:]), 1)
            return F.pad(rgba, (0, 0, 0, 32))  # 320×384, divisible by 64
        pa, pb = tensor(a), tensor(b)
        ia, ib = pa[:, :3] + .5 * (1 - pa[:, 3:]), pb[:, :3] + .5 * (1 - pb[:, 3:])
        net._build_warp_grids(ia.shape[2], ia.shape[3], device)
        f0, f1 = net.encode(ia), net.encode(ib)
        timestep = torch.full_like(ia[:, :1], t)
        flow = mask = feat = None
        wa, wb = ia, ib
        for i, block in enumerate(net.blocks):
            if flow is None:
                flow, mask, feat = block(torch.cat((ia, ib, f0, f1, timestep), 1), None, scale=net.scale_list[i])
            else:
                delta, mask, feat = block(torch.cat((wa, wb, net.warp(f0, flow[:, :2]), net.warp(f1, flow[:, 2:]), timestep, mask, feat), 1), flow, scale=net.scale_list[i])
                flow = flow + delta
            wa, wb = net.warp(ia, flow[:, :2]), net.warp(ib, flow[:, 2:])
        rgba = torch.lerp(net.warp(pb, flow[:, 2:]), net.warp(pa, flow[:, :2]), torch.sigmoid(mask))[:, :, :352]
        rgba[:, :3] /= rgba[:, 3:].clamp_min(1 / 255)
        arr = (rgba[0].permute(1, 2, 0).clamp(0, 1).cpu().numpy() * 255).round().astype(np.uint8)
        return Image.fromarray(arr)

    original = Image.open(source).convert("RGBA")
    edges = [0, 329, 635, 937, 1254]
    record = {
        "schema": 1, "method": "RIFE flow applied to premultiplied RGBA; original keys inserted unchanged after integer translation",
        "source": str(source.relative_to(root)), "source_sha256": source_hash,
        "backend": "ComfyUI comfy_extras/frame_interpolation_models/ifnet.py",
        "backend_sha256": sha(comfy / "comfy_extras/frame_interpolation_models/ifnet.py"),
        "weights": model_path.name, "weights_sha256": sha(model_path),
        "authoring_script_sha256": sha(__file__), "device": device,
        "cell_size": [320, 352], "grid": [4, 16], "anchor": [160, 328],
        "fps": 32, "cycle_seconds": .5, "key_indices": [0, 4, 8, 12],
        "directions": {}, "limitations": "In-betweening cannot invent missing opposite-foot poses; review gait before production acceptance. No body-part customization.",
    }
    atlas = Image.new("RGBA", (1280, 5632))
    contact = Image.new("RGBA", (1280, 1408), (218, 226, 214, 255))
    out.mkdir(parents=True)
    with torch.inference_mode():
        for row, direction in enumerate(("se", "sw", "ne", "nw")):
            keys = []
            hashes = []
            for col in range(4):
                frame = original.crop((round(col * original.width / 4), edges[row], round((col + 1) * original.width / 4), edges[row + 1]))
                alpha = frame.getchannel("A").point(lambda v: 255 if v > 63 else 0)
                box = alpha.getbbox()
                dx, dy = 160 - round((box[0] + box[2]) / 2), 328 - box[3]
                # Only translate. Never resize, recolor or re-render the source keys.
                key = Image.new("RGBA", (320, 352))
                key.paste(frame, (dx, dy))
                keys.append(key)
                hashes.append(hashlib.sha256(key.tobytes()).hexdigest())
            record["directions"][direction] = {"row": row * 4, "key_rgba_sha256": hashes}
            frames = []
            for i in range(4):
                frames.append(keys[i])
                for fraction in (.25, .5, .75):
                    frames.append(intermediate(keys[i], keys[(i + 1) % 4], fraction))
                print(f"{direction}: transition {i + 1}/4", flush=True)
            for i, frame in enumerate(frames):
                atlas.paste(frame, ((i % 4) * 320, (row * 4 + i // 4) * 352))
            for col, index in enumerate((0, 2, 4, 6)):
                contact.alpha_composite(frames[index], (col * 320, row * 352))
    atlas.save(out / "sheet.png")
    record["output_sha256"] = sha(out / "sheet.png")
    (out / "provenance.json").write_text(json.dumps(record, indent=2) + "\n")
    cache = root / ".cache/painted-review"
    cache.mkdir(parents=True, exist_ok=True)
    contact.save(cache / "inbetweens.png")
    if sha(source) != source_hash:
        raise RuntimeError("Source changed during authoring")
    print(f"Candidate only: {out}. Source unchanged; runtime selection unchanged.")


if __name__ == "__main__":
    main()
