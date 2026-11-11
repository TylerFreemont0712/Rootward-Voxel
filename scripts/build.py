#!/usr/bin/env python3
"""Builds Rootward Voxel to play without Godot, for Linux and Windows, and its installers (docs/RELEASES.md).

    scripts/build.sh                    build everything into build/release/ (from Linux; a few minutes)
    scripts/build.sh --only linux       one platform (the installers are still built for both)
    scripts/build.sh --publish          then upload build/release/ as the GitHub release v<version>
    scripts/build.sh --set-version X.Y.Z   write a new version into project.godot and both export presets, then stop

build/stage/<os>/    the game as installed: RootwardVoxel(.x86_64|.exe), RootwardVoxel.pck, sandbox/, LICENSES/
build/release/       what the installer downloads, and the installers themselves:
  rootward-voxel-<v>-<os>-game.zip      the executable, the README and the licences (small)
  rootward-voxel-<v>.pck                everything the game shows and reads (one file, the same for both systems)
  rootward-voxel-<v>-<os>-sandbox.zip   wasmtime and CPython, compiled for that system
  Rootward-Voxel-Setup-<v>.exe, rootward-voxel-setup-<v>-linux.tar.gz
  rootward-voxel-manifest.json          every package with its size and SHA-256; the installer reads it first

Needs the game's media (scripts/fetch-media.sh) and Godot 4.7.2 (`godot` on the PATH, or GODOT_BIN). The export
templates are downloaded once, checked against Godot's published SHA-512. The sandbox is built by
scripts/sandbox_dist.py from pinned downloads.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INSTALLER = ROOT / "installer"
BUILD = ROOT / "build"
STAGE = BUILD / "stage"
RELEASE = BUILD / "release"
GODOT = os.environ.get("GODOT_BIN") or shutil.which("godot") or str(Path.home() / "godot")
GODOT_VERSION = "4.7.2"
TEMPLATES = (Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local" / "share") / "godot" / "export_templates"
             / f"{GODOT_VERSION}.stable")
TEMPLATE_FILES = ("linux_debug.x86_64", "linux_release.x86_64", "windows_debug_x86_64.exe",
                  "windows_release_x86_64.exe", "windows_debug_x86_64_console.exe",
                  "windows_release_x86_64_console.exe", "version.txt")
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "rootward-voxel" / "godot"
GODOT_RELEASES = f"https://github.com/godotengine/godot-builds/releases/download/{GODOT_VERSION}-stable"
NAME = "rootward-voxel"
PCK = "RootwardVoxel.pck"
PLATFORMS = {
    "linux": {"preset": "Linux", "exe": "RootwardVoxel.x86_64", "extra": []},
    "windows": {"preset": "Windows", "exe": "RootwardVoxel.exe", "extra": ["RootwardVoxel.console.exe"]},
}
SAVES = {"linux": "~/.local/share/RootwardVoxelLab", "windows": "%APPDATA%\\RootwardVoxelLab"}
EXECUTABLE = 0o100755 << 16
REGULAR = 0o100644 << 16


def sha256(path: Path) -> str:
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def run(*args: str, cwd: Path = ROOT, quiet: bool = False) -> subprocess.CompletedProcess:
    result = subprocess.run(list(args), cwd=cwd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if result.returncode != 0:
        out = (result.stdout + result.stderr).strip()
        if out:
            print(out[-4000:])
        sys.exit(f"failed ({result.returncode}): {' '.join(args)}")
    if not quiet and result.stdout.strip():
        print(result.stdout.strip()[-2000:])
    return result


def version() -> str:
    match = re.search(r'^config/version="([^"]+)"', (ROOT / "project.godot").read_text(encoding="utf-8"), re.M)
    if not match:
        sys.exit("project.godot has no config/version")
    return match.group(1)


def set_version(new: str) -> None:
    if not re.fullmatch(r"\d+\.\d+\.\d+", new):
        sys.exit("a version is three numbers: 0.2.0")
    four = new + ".0"
    project = ROOT / "project.godot"
    project.write_text(re.sub(r'^config/version="[^"]*"', f'config/version="{new}"', project.read_text(), flags=re.M))
    for presets in (ROOT / "export_presets.cfg", INSTALLER / "export_presets.cfg"):
        text = re.sub(r'^application/(file|product)_version="[^"]*"', lambda m: f'application/{m.group(1)}_version="{four}"',
                      presets.read_text(), flags=re.M)
        presets.write_text(text)
    print(f"version {new} written to project.godot, export_presets.cfg and installer/export_presets.cfg")


def check_versions(ver: str) -> None:
    four = ver + ".0"
    for presets in (ROOT / "export_presets.cfg", INSTALLER / "export_presets.cfg"):
        found = set(re.findall(r'^application/(?:file|product)_version="([^"]*)"', presets.read_text(), re.M))
        if found != {four}:
            sys.exit(f"{presets.relative_to(ROOT)} says {sorted(found)}, project.godot says {ver}: "
                     f"run scripts/build.sh --set-version {ver}")


def ensure_templates() -> None:
    if all((TEMPLATES / name).is_file() for name in TEMPLATE_FILES):
        return
    CACHE.mkdir(parents=True, exist_ok=True)
    tpz = CACHE / f"Godot_v{GODOT_VERSION}-stable_export_templates.tpz"
    sums = CACHE / "SHA512-SUMS.txt"
    urllib.request.urlretrieve(f"{GODOT_RELEASES}/SHA512-SUMS.txt", sums)
    want = next(line.split()[0] for line in sums.read_text().splitlines() if line.endswith(f" {tpz.name}"))

    def digest() -> str:
        with tpz.open("rb") as handle:
            return hashlib.file_digest(handle, "sha512").hexdigest()

    if not tpz.is_file() or digest() != want:
        print(f"downloading Godot {GODOT_VERSION}'s export templates (1.3 GB, once)", flush=True)
        urllib.request.urlretrieve(f"{GODOT_RELEASES}/{tpz.name}", tpz)
        if digest() != want:
            sys.exit("the export templates do not match Godot's published SHA-512")
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as archive:  # only what these two platforms need, not every platform's
        for name in TEMPLATE_FILES:
            target = TEMPLATES / name
            target.write_bytes(archive.read(f"templates/{name}"))
            target.chmod(0o755)
    print(f"export templates installed in {TEMPLATES}")


def check_inputs() -> None:
    has = subprocess.run([sys.executable, str(ROOT / "scripts" / "media.py"), "has", "game"], cwd=ROOT)
    if has.returncode != 0:
        sys.exit("the game's pictures and models are not all here: run scripts/fetch-media.sh")


def licences(into: Path) -> None:
    into.mkdir(parents=True, exist_ok=True)
    run(GODOT, "--headless", "--path", str(ROOT), "-s", "res://tools/licenses.gd", "--",
        str(into / "godot-LICENSE.txt"), quiet=True)
    for font in sorted((ROOT / "ui" / "fonts").glob("OFL-*.txt")):
        shutil.copyfile(font, into / f"font-{font.name}")
    shutil.copyfile(ROOT / "LICENSE", into / "rootward-voxel-LICENSE.txt")
    shutil.copyfile(ROOT / "CREDITS.md", into / "CREDITS.md")


README = """Rootward Voxel {version}
==================

Start the game with {exe}. Saves and settings are kept in {saves}.

The sandbox/ folder beside the game runs the Python you write (wasmtime, with CPython compiled to WebAssembly):
your programs cannot reach your files or the network. The game needs that folder next to {exe}.

To check that everything works without playing: {selftest}
It loads every area, finds the models and runs real Python in the sandbox, and ends with OK or FAILED.

Licences of the engine, the sandbox and the fonts are in LICENSES/ and sandbox/LICENSES/.
"""


def clear(path: Path) -> None:
    if path.exists():
        for item in path.rglob("*"):
            if item.is_file():
                item.chmod(0o644)  # the sandbox's library may have been marked read-only by a self-test
        shutil.rmtree(path)


def stage(name: str, ver: str) -> Path:
    spec = PLATFORMS[name]
    out = STAGE / name
    clear(out)
    out.mkdir(parents=True)
    print(f"{name}: exporting", flush=True)
    run(GODOT, "--headless", "--path", str(ROOT), "--export-release", spec["preset"], str(out / spec["exe"]), quiet=True)
    for produced in [spec["exe"], PCK, *spec["extra"]]:
        if not (out / produced).is_file():
            sys.exit(f"{name}: the export did not write {produced}")
    print(f"{name}: sandbox", flush=True)
    run(sys.executable, str(ROOT / "scripts" / "sandbox_dist.py"), "--target", name, "--out", str(out / "sandbox"),
        quiet=True)
    licences(out / "LICENSES")
    selftest = ("RootwardVoxel.console.exe -- --self-test" if name == "windows"
                else "./RootwardVoxel.x86_64 -- --self-test")
    text = README.format(version=ver, exe=spec["exe"], saves=SAVES[name], selftest=selftest)
    (out / "README.txt").write_text(text.replace("\n", "\r\n") if name == "windows" else text, encoding="utf-8")
    return out


def self_test(out: Path) -> None:
    print("linux: self-test of the exported game", flush=True)
    result = run(str(out / "RootwardVoxel.x86_64"), "--headless", "--", "--self-test", cwd=out, quiet=True)
    print("  " + result.stdout.strip().splitlines()[-1])


def zip_dir(out: Path, base: Path, members: list[Path], executables: set[str]) -> None:
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(members):
            arcname = path.relative_to(base).as_posix()
            info = zipfile.ZipInfo(arcname, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = EXECUTABLE if arcname in executables else REGULAR
            archive.writestr(info, path.read_bytes())


def package(name: str, out: Path, ver: str) -> dict:
    spec = PLATFORMS[name]
    executables = {spec["exe"], *spec["extra"], "sandbox/bin/wasmtime"}
    entries = []
    game_zip = RELEASE / f"{NAME}-{ver}-{name}-game.zip"
    game_files = [out / spec["exe"], out / "README.txt", *[out / e for e in spec["extra"]],
                  *[p for p in (out / "LICENSES").rglob("*") if p.is_file()]]
    zip_dir(game_zip, out, game_files, executables)
    entries.append({"id": "game", "file": game_zip.name, "kind": "zip"})
    # The .pck holds no platform's code, so both exports write the same bytes: one download serves both.
    pck = RELEASE / f"{NAME}-{ver}.pck"
    if pck.is_file() and sha256(pck) != sha256(out / PCK):
        pck = RELEASE / f"{NAME}-{ver}-{name}.pck"
    if not pck.is_file():
        shutil.copyfile(out / PCK, pck)
    entries.append({"id": "data", "file": pck.name, "kind": "file", "target": PCK})
    sandbox_zip = RELEASE / f"{NAME}-{ver}-{name}-sandbox.zip"
    zip_dir(sandbox_zip, out, [p for p in (out / "sandbox").rglob("*") if p.is_file()], executables)
    entries.append({"id": "sandbox", "file": sandbox_zip.name, "kind": "zip"})
    for entry in entries:
        path = RELEASE / entry["file"]
        entry["size"] = path.stat().st_size
        entry["sha256"] = sha256(path)
    installed = sum(p.stat().st_size for p in out.rglob("*") if p.is_file())
    return {"executable": spec["exe"], "installed_size": installed, "packages": entries,
            "executables": sorted(executables)}


def build_installers(ver: str) -> list[Path]:
    brand = INSTALLER / "brand"
    brand.mkdir(exist_ok=True)
    for source, target in [
        (ROOT / "docs" / "images" / "installer-backdrop.jpg", "backdrop.jpg"),
        (ROOT / "assets" / "brand" / "icon-256.png", "icon.png"),
        (ROOT / "ui" / "fonts" / "cinzel.ttf", "cinzel.ttf"),
        (ROOT / "ui" / "fonts" / "alegreya.ttf", "alegreya.ttf"),
        (ROOT / "ui" / "fonts" / "OFL-cinzel.txt", "OFL-cinzel.txt"),
        (ROOT / "ui" / "fonts" / "OFL-alegreya.txt", "OFL-alegreya.txt"),
    ]:
        if source.is_file():
            shutil.copyfile(source, brand / target)
        else:
            print(f"warning: {source.relative_to(ROOT)} is missing; the installer goes without it")
    (INSTALLER / "version.txt").write_text(ver + "\n", encoding="utf-8")
    run(GODOT, "--headless", "--editor", "--import", "--quit", "--path", str(INSTALLER), quiet=True)
    made = []
    for name, preset, exe in [("windows", "Windows", "Rootward Voxel Setup.exe"),
                              ("linux", "Linux", "rootward-voxel-setup")]:
        out = BUILD / "installer" / name
        shutil.rmtree(out, ignore_errors=True)
        out.mkdir(parents=True)
        print(f"{name}: exporting the installer", flush=True)
        run(GODOT, "--headless", "--path", str(INSTALLER), "--export-release", preset, str(out / exe), quiet=True)
        if name == "windows":
            target = RELEASE / f"Rootward-Voxel-Setup-{ver}.exe"
            shutil.copyfile(out / exe, target)
        else:
            # A download loses the executable bit; a tar keeps it, so Linux gets the installer in one.
            target = RELEASE / f"{NAME}-setup-{ver}-linux.tar.gz"
            with tarfile.open(target, "w:gz") as archive:
                info = archive.gettarinfo(str(out / exe), arcname=exe)
                info.mode, info.uid, info.gid, info.uname, info.gname = 0o755, 0, 0, "", ""
                with (out / exe).open("rb") as handle:
                    archive.addfile(info, handle)
        made.append(target)
    return made


def repo() -> str:
    for line in (ROOT / "media.lock").read_text().splitlines():
        if line.startswith("repo\t"):
            return line.split("\t")[1].strip()
    sys.exit("media.lock names no repository")


def publish(ver: str, files: list[Path]) -> None:
    tag = f"v{ver}"
    name = repo()
    branch = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=ROOT, capture_output=True,
                            text=True).stdout.strip()
    notes = (f"Rootward Voxel {ver}.\n\n**Windows:** download `Rootward-Voxel-Setup-{ver}.exe` and run it.\n"
             f"**Linux:** download `{NAME}-setup-{ver}-linux.tar.gz`, unpack it and run `./rootward-voxel-setup`.\n\n"
             "The installer downloads the rest. To install without a connection, put the other files of this release "
             "in one folder beside the installer and run it from there.")
    view = subprocess.run(["gh", "release", "view", tag, "-R", name], capture_output=True, text=True)
    if view.returncode != 0:
        run("gh", "release", "create", tag, "-R", name, "--title", f"Rootward Voxel {ver}", "--notes", notes,
            "--target", branch, quiet=True)
    for path in files:
        print(f"uploading {path.name} ({path.stat().st_size / 1e6:.0f} MB)", flush=True)
        run("gh", "release", "upload", tag, "-R", name, str(path), "--clobber", quiet=True)
    print(f"published https://github.com/{name}/releases/tag/{tag}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--publish", action="store_true", help="upload build/release/ as the GitHub release v<version>")
    parser.add_argument("--only", choices=sorted(PLATFORMS), help="build one platform")
    parser.add_argument("--set-version", metavar="X.Y.Z", help="write a new version everywhere it lives, then stop")
    args = parser.parse_args()
    if args.set_version:
        set_version(args.set_version)
        return 0
    ver = version()
    check_versions(ver)
    check_inputs()
    ensure_templates()
    run(GODOT, "--headless", "--editor", "--import", "--quit", "--path", str(ROOT), quiet=True)
    clear(RELEASE)
    RELEASE.mkdir(parents=True)
    manifest = {"name": "Rootward Voxel", "version": ver,
                "built": datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ"), "platforms": {}}
    for name in [args.only] if args.only else sorted(PLATFORMS):
        out = stage(name, ver)
        if name == "linux":
            self_test(out)
        manifest["platforms"][name] = package(name, out, ver)
    (RELEASE / f"{NAME}-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    installers = build_installers(ver)
    files = sorted(RELEASE.iterdir())
    for path in files:
        print(f"  {path.stat().st_size / 1e6:8.1f} MB  {path.name}")
    if args.publish:
        publish(ver, files)
    return 0


if __name__ == "__main__":
    sys.exit(main())
