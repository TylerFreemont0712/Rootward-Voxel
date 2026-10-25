#!/usr/bin/env python3
"""Prepare or install this checkout's Linux application and desktop shortcuts."""

import argparse
import os
from pathlib import Path
import shutil
from string import Template
import subprocess


ROOT = Path(__file__).resolve().parents[1]
FILENAME = "rootward-voxel.desktop"
MARKER = "X-Rootward-Voxel-Launcher=true"


def desktop_value(value):
    """Escape a Desktop Entry string value (before Exec argument quoting)."""
    return str(value).replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")


def exec_argument(value):
    # Exec is an argument list, not a shell command. Escape its reserved characters,
    # then the Desktop Entry string layer; literal percent signs are field escapes.
    value = str(value).replace("%", "%%")
    for character in ('\\', '"', '`', '$'):
        value = value.replace(character, "\\" + character)
    return '"' + desktop_value(value) + '"'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepare-only", action="store_true", help="Write a reviewable .cache/desktop launcher without installing it")
    args = parser.parse_args()
    godot = shutil.which(os.environ.get("GODOT_BIN", "godot"))
    if not godot:
        parser.error("Godot was not found. Set GODOT_BIN to the Godot 4.7.2 executable.")
    icon = ROOT / "assets/brand/icon-512.png"
    if not icon.is_file():
        parser.error("The selected icon is missing. Run scripts/art.sh first.")
    entry = Template((ROOT / "packaging/rootward-voxel.desktop.in").read_text()).substitute(
        EXEC=" ".join(exec_argument(part) for part in (
            "/usr/bin/env", f"GODOT_BIN={godot}", ROOT / "scripts/play.sh")),
        GODOT=desktop_value(godot),
        PROJECT=desktop_value(ROOT),
        ICON=desktop_value(icon),
    )
    prepared = ROOT / ".cache/desktop" / FILENAME
    prepared.parent.mkdir(parents=True, exist_ok=True)
    prepared.write_text(entry)
    prepared.chmod(0o755)
    if shutil.which("desktop-file-validate"):
        subprocess.run(["desktop-file-validate", str(prepared)], check=True)
    print(f"Prepared: {prepared}")
    if args.prepare_only:
        return

    data_home = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    if not data_home.is_absolute():
        parser.error("XDG_DATA_HOME must be an absolute path.")
    destinations = [data_home / "applications" / FILENAME]
    if shutil.which("xdg-user-dir"):
        result = subprocess.run(["xdg-user-dir", "DESKTOP"], capture_output=True, text=True, check=True)
        desktop = Path(result.stdout.strip())
    else:
        desktop = Path.home() / "Desktop"
    # XDG uses HOME to signal that a desktop folder is disabled.
    if desktop.is_absolute() and desktop.is_dir() and desktop != Path.home():
        destinations.append(desktop / FILENAME)
    for destination in destinations:
        if destination.exists() and MARKER not in destination.read_text():
            parser.error(f"Refusing to replace an unrelated launcher: {destination}")
    for destination in destinations:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(prepared, destination)
        destination.chmod(0o755)
        if destination.parent == desktop and shutil.which("gio"):
            # Use the desktop's GIO build so its GVfs metadata backend is available.
            gio = "/usr/bin/gio" if Path("/usr/bin/gio").is_file() else "gio"
            subprocess.run([gio, "set", str(destination), "metadata::trusted", "true"], check=False)
        print(f"Installed: {destination}")
    if shutil.which("update-desktop-database"):
        subprocess.run(["update-desktop-database", str(destinations[0].parent)], check=True)


if __name__ == "__main__":
    main()
