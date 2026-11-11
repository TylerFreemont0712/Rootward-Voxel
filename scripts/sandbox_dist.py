#!/usr/bin/env python3
"""Builds the Python sandbox for one platform: what a shipped game puts in `sandbox/` beside its executable.

    python3 scripts/sandbox_dist.py --target linux|windows --out <dir>

    <dir>/bin/wasmtime[.exe]        the WebAssembly engine for the target
    <dir>/python/python.cwasm       CPython for WASI, compiled ahead of time for the target
    <dir>/python/lib/               its standard library, with bytecode that never goes stale
    <dir>/LICENSES/                 wasmtime's and CPython's licences
    <dir>/VERSIONS

Runs on Linux or Windows (from either, for either). Downloads are pinned by SHA-256, the same versions as
scripts/setup-runtime.sh, and cached in ~/.cache/rootward-voxel/sandbox.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "rootward-voxel" / "sandbox"
WASMTIME = "v49.0.0"
PYTHON = "3.14.7"
DOWNLOADS = {
    "wasmtime-linux": (f"https://github.com/bytecodealliance/wasmtime/releases/download/{WASMTIME}/wasmtime-{WASMTIME}-x86_64-linux.tar.xz",
                       "a956c279ac6e80109369a285db30fc46f68239fa1bbeb03ccfa8e913bbca85fc", f"wasmtime-{WASMTIME}-x86_64-linux.tar.xz"),
    "wasmtime-windows": (f"https://github.com/bytecodealliance/wasmtime/releases/download/{WASMTIME}/wasmtime-{WASMTIME}-x86_64-windows.zip",
                         "7f2a583694aac3dfeecc43ce51248155e72eaa695733d803c6923ef27103681a", f"wasmtime-{WASMTIME}-x86_64-windows.zip"),
    "python": (f"https://github.com/brettcannon/cpython-wasi-build/releases/download/v{PYTHON}/python-{PYTHON}-wasi_sdk-24.zip",
               "2e064d3fb8172471d39d741348efa722349c40b96301f69968dff714999c584b", f"python-{PYTHON}-wasi_sdk-24.zip"),
}
# A .cwasm is machine code for one operating system and CPU. Naming the target triple compiles for that OS with only
# the baseline x86-64 instruction set, so one build runs on every player's PC, not just on the one that built it.
TRIPLES = {"linux": "x86_64-unknown-linux-gnu", "windows": "x86_64-pc-windows-msvc"}


def sha256(path: Path) -> str:
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def fetch(key: str) -> Path:
    url, sha, name = DOWNLOADS[key]
    path = CACHE / name
    if path.is_file() and sha256(path) == sha:
        return path
    CACHE.mkdir(parents=True, exist_ok=True)
    print(f"downloading {name}", flush=True)
    part = path.with_suffix(path.suffix + ".part")
    urllib.request.urlretrieve(url, part)
    if sha256(part) != sha:
        part.unlink()
        sys.exit(f"checksum mismatch for {name}")
    os.replace(part, path)
    return path


def wasmtime_for(system: str, into: Path) -> Path:
    """Unpacks wasmtime (and its LICENSE) for `system` into `into` and returns the binary."""
    exe = "wasmtime.exe" if system == "windows" else "wasmtime"
    into.mkdir(parents=True, exist_ok=True)
    if system == "windows":
        with zipfile.ZipFile(fetch("wasmtime-windows")) as archive:
            for member in ("wasmtime.exe", "LICENSE"):
                (into / member).write_bytes(archive.read(f"wasmtime-{WASMTIME}-x86_64-windows/{member}"))
    else:
        with tarfile.open(fetch("wasmtime-linux")) as archive:
            for member in ("wasmtime", "LICENSE"):
                source = archive.extractfile(f"wasmtime-{WASMTIME}-x86_64-linux/{member}")
                assert source is not None
                (into / member).write_bytes(source.read())
        (into / exe).chmod(0o755)
    return into / exe


def make_writable(root: Path) -> None:
    for path in root.rglob("*"):
        if path.is_file():
            path.chmod(0o644)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--target", choices=sorted(TRIPLES), required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    out: Path = args.out.resolve()
    host_system = "windows" if platform.system() == "Windows" else "linux"
    with tempfile.TemporaryDirectory() as scratch_name:
        scratch = Path(scratch_name)
        host = wasmtime_for(host_system, scratch / "host")
        if out.exists():
            make_writable(out)  # the standard library was made read-only last time
            shutil.rmtree(out)
        (out / "LICENSES").mkdir(parents=True)
        shipped = wasmtime_for(args.target, out / "bin")
        shutil.move(str(shipped.parent / "LICENSE"), out / "LICENSES" / "wasmtime-LICENSE.txt")
        with zipfile.ZipFile(fetch("python")) as archive:
            archive.extractall(out / "python")
        if (out / "python" / "LICENSE").is_file():
            shutil.move(str(out / "python" / "LICENSE"), out / "LICENSES" / "cpython-LICENSE.txt")
        python_wasm = scratch / "python.wasm"
        shutil.move(str(out / "python" / "python.wasm"), python_wasm)
        # By default a .pyc remembers its source's modification time and is thrown away when that differs. A zip
        # keeps times only to two seconds, in local time, so on another machine every .pyc would look stale and each
        # run would compile the library again in memory (the sandbox may not write). An unchecked-hash .pyc is
        # trusted as it is: the library never changes after it ships.
        print("compiling the Python standard library to bytecode", flush=True)
        subprocess.run([str(host), "run", "-W", "timeout=900s", "--dir", f"{out / 'python' / 'lib'}::/lib",
                        "--env", "PYTHONHOME=/", str(python_wasm), "-m", "compileall", "-q",
                        "--invalidation-mode", "unchecked-hash", f"/lib/python{PYTHON.rsplit('.', 1)[0]}"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"compiling CPython for {args.target}", flush=True)
        subprocess.run([str(host), "compile", "-W", "epoch-interruption=y", "--target", TRIPLES[args.target],
                        str(python_wasm), "-o", str(out / "python" / "python.cwasm")], check=True)
    (out / "VERSIONS").write_text(f"{args.target}-x86_64; wasmtime {WASMTIME}, cpython {PYTHON}\n", encoding="utf-8")
    (out / ".gdignore").write_text("", encoding="utf-8")
    size = sum(p.stat().st_size for p in out.rglob("*") if p.is_file())
    print(f"sandbox for {args.target}: {out} ({size / 1e6:.0f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
