"""Meaningful destructive-rebuild guards; no Blender installation is needed to reject these calls."""
from pathlib import Path
import hashlib
import os
import subprocess

root = Path(__file__).resolve().parents[1]
sources = [*root.glob('art/source/world/*/*/model.blend'), root/'art/source/adventurer/v2-isometric/sheet.png', root/'art/source/adventurer/v3-smooth/sheet.png']
sources += list((root/'art/source/adventurer/v9-directional-walk').glob('*.png'))
sources += list(root.glob('art/source/characters/*/sparks-*/*.png'))
sources += list(root.glob('art/source/robots/v0.72/*/movement-v1/*.png'))
before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in sources}
commands = [
    [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(root), '-s', 'res://pipeline/prepare_robot_movement.gd', '--', '--source', 'res://art/source/robots/v0.72/wick/movement-v1'],
    [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(root), '-s', 'res://pipeline/reflow_cast_source.gd', '--', '--source', 'res://art/source/characters/nell/sparks-v1', '--output', 'res://art/source/characters/nell/sparks-v2'],
    [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(root), '-s', 'res://pipeline/prepare_cast_source.gd', '--', '--source', 'res://art/source/characters/nell/sparks-v1', '--stage', 'references'],
    [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(root), '-s', 'res://pipeline/prepare_cast_source.gd', '--', '--source', 'res://art/source/characters/mira/sparks-v1', '--stage', 'assemble'],
    [os.environ.get('GODOT_BIN', 'godot'), '--headless', '--path', str(root), '-s', 'res://pipeline/prepare_directional_walk.gd', '--', '--source', 'res://art/source/adventurer/v9-directional-walk'],
    ['scripts/world-art.sh', 'init', 'cottage'],
    ['scripts/world-art.sh', 'seed', 'cottage'],
    ['scripts/world-art.sh', 'init', 'log-cabin'],
    ['scripts/world-art.sh', 'seed', 'log-cabin'],
    ['scripts/world-art.sh', 'init', 'lamppost'],
    ['scripts/world-art.sh', 'seed', 'lamppost'],
]
for command in commands:
    result = subprocess.run(command, cwd=root, capture_output=True, text=True)
    assert result.returncode != 0 and any(text in result.stdout + result.stderr for text in ('already exists', 'NEW version directory')), (command, result.stdout, result.stderr)
    assert all(hashlib.sha256(path.read_bytes()).hexdigest() == sha for path, sha in before.items()), 'An artist source changed during a rejected seed/init'
print(f'Authoring source protection: {len(commands)} checks passed.')
