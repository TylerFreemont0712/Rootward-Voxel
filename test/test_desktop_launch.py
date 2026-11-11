"""Desktop argument/exit-code checks without starting a game or touching player saves."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PWSH = shutil.which('pwsh') or shutil.which('powershell')
if not PWSH and (ROOT / '.cache/powershell/pwsh').is_file():
    PWSH = str(ROOT / '.cache/powershell/pwsh')


class DesktopLaunch(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='rootward launcher space ')
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        runtime = self.directory / 'native runtime'
        (runtime / 'bin').mkdir(parents=True)
        (runtime / 'python').mkdir()
        for name in ['wasmtime', 'wasmtime.exe']:
            p = runtime / 'bin' / name
            p.write_text('#!/bin/sh\nexit 0\n')
            p.chmod(0o755)
        (runtime / 'python/python.cwasm').touch()
        self.engine = self.directory / 'fake godot'
        self.engine.write_text('''#!/usr/bin/env python3
import json,os,sys
with open(os.environ['ROOTWARD_TEST_LOG'],'a') as f:
 f.write(json.dumps({'args':sys.argv[1:],'prime':os.environ.get('__NV_PRIME_RENDER_OFFLOAD'),'glx':os.environ.get('__GLX_VENDOR_LIBRARY_NAME')})+'\\n')
sys.exit(int(os.environ.get('ROOTWARD_TEST_ENGINE_EXIT','0')))
''')
        self.engine.chmod(0o755)
        self.log = self.directory / 'arguments.jsonl'
        self.env = dict(os.environ, GODOT_BIN=str(self.engine), ROOTWARD_GPU='default',
                        ROOTWARD_SANDBOX_RUNTIME=str(runtime), ROOTWARD_TEST_LOG=str(self.log))

    def calls(self):
        return [json.loads(row) for row in self.log.read_text().splitlines()] if self.log.exists() else []

    @unittest.skipUnless(sys.platform.startswith('linux'), 'Linux shell launcher')
    def test_linux_literal_arguments_and_default(self):
        literal = 'literal $(touch must-not-execute) ; `echo nope`'
        r = subprocess.run(['bash', str(ROOT/'scripts/play.sh'), '--gpu', 'default', '--resolution', literal], env=self.env, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual(self.calls()[-1]['args'][-2:], ['--resolution', literal])
        self.assertIn('gl_compatibility', self.calls()[-1]['args'])

    @unittest.skipUnless(sys.platform.startswith('linux'), 'Linux shell launcher')
    def test_linux_explicit_index_requires_modern_renderer(self):
        r = subprocess.run(['bash', str(ROOT/'scripts/play.sh'), '--gpu', '1'], env=self.env, capture_output=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.calls(), [])
        r = subprocess.run(['bash', str(ROOT/'scripts/play.sh'), '--renderer', 'mobile', '--gpu', '1'], env=self.env, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('--gpu-index', self.calls()[-1]['args'])
        self.assertIn('vulkan', self.calls()[-1]['args'])

    @unittest.skipUnless(sys.platform.startswith('linux'), 'Linux shell launcher')
    def test_linux_failed_import_never_launches_game(self):
        r = subprocess.run(['bash', str(ROOT/'scripts/play.sh')], env=dict(self.env, ROOTWARD_TEST_ENGINE_EXIT='7'), capture_output=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(len(self.calls()), 1)

    @unittest.skipUnless(PWSH, 'PowerShell is unavailable')
    def test_powershell_scripts_parse(self):
        code = '''foreach ($file in @('scripts/play.ps1','scripts/setup-runtime.ps1','scripts/test.ps1')) {
 $errors=$null; $tokens=$null
 [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $file).Path,[ref]$tokens,[ref]$errors) | Out-Null
 if ($errors.Count) { throw ($errors | Out-String) }
}'''
        r = subprocess.run([PWSH, '-NoProfile', '-Command', code], cwd=ROOT, env=self.env, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)

    @unittest.skipUnless(PWSH and sys.platform.startswith('linux'), 'Portable PowerShell argument harness')
    def test_windows_launcher_arguments_with_portable_powershell(self):
        code = '''& ./scripts/play.ps1 -Renderer mobile -GpuIndex 1 -GodotArgs @('--resolution','1600x1000')'''
        r = subprocess.run([PWSH, '-NoProfile', '-Command', code], cwd=ROOT, env=self.env, capture_output=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        args = self.calls()[-1]['args']
        self.assertIn('--gpu-index', args)
        self.assertIn('mobile', args)
        self.assertEqual(args[-2:], ['--resolution','1600x1000'])

    @unittest.skipUnless(PWSH and sys.platform.startswith('linux'), 'Portable PowerShell argument harness')
    def test_windows_invalid_gpu_choice(self):
        r = subprocess.run([PWSH, '-NoProfile', '-Command', '& ./scripts/play.ps1 -GpuIndex 1'], cwd=ROOT, env=self.env, capture_output=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == '__main__':
    unittest.main()
