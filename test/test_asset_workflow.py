"""Real source-checkout request lifecycle and destructive operations in isolated project fixtures."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('asset_workflow', ROOT / 'pipeline/asset_workflow.py')
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
AssetWorkflow, WorkflowError = module.AssetWorkflow, module.WorkflowError


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='asset-workflow-', dir=ROOT / '.cache')
        self.root = Path(self.temp.name)
        (self.root / 'project.godot').write_text('; isolated test checkout')
        (self.root / 'pipeline').mkdir()
        self.catalog = {'schema': 1, 'assets': {}, 'areas': {}}
        self.add_asset('fixture-model')
        self.flow = AssetWorkflow(self.root)

    def tearDown(self):
        self.temp.cleanup()

    def add_asset(self, asset_id):
        source = self.root / f'art/source/world/{asset_id}/v1/model.blend'
        runtime = self.root / f'assets/world/{asset_id}/model.glb'
        for path in [source, runtime]:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'test source' if path == source else b'test runtime')
        (source.parent / 'README.md').write_text('Versioned authoring notes')
        (runtime.parent / 'model.glb.import').write_text('Test import sidecar')
        (runtime.parent / 'manifest.json').write_text(json.dumps({'source_sha256': module.digest(source), 'runtime_sha256': module.digest(runtime)}))
        self.catalog['assets'][asset_id] = {'label': 'Fixture model', 'authority': 'blender', 'version': 'v1',
                                          'source': str(source.relative_to(self.root)), 'runtime': str(runtime.relative_to(self.root))}
        self.write_catalog()

    def write_catalog(self):
        (self.root / 'pipeline/world-catalog.json').write_text(json.dumps(self.catalog, indent=2))

    def review(self):
        path = self.root / 'pipeline/reviews/fixture.md'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('Built and reviewed in the isolated fixture.')
        return str(path.relative_to(self.root))

    def finish(self, record):
        return self.flow.transition(record['id'], 'finish', {'assets': ['fixture-model'], 'summary': 'Updated and checked', 'review': self.review()})

    def test_update_notes_context_references_and_cli(self):
        self.add_asset('style-reference')
        notes = 'Loosen the straps.\nKeep the brass. `$(touch NO)` and "quotes" are literal. 日本語'
        record = self.flow.submit({'kind': 'update', 'asset_id': 'fixture-model', 'notes': notes, 'references': ['style-reference', 'style-reference']})
        self.assertEqual(record['notes'], notes)
        self.assertEqual(len(record['references']), 1)
        self.assertEqual(record['asset']['source'], 'art/source/world/fixture-model/v1/model.blend')
        brief = (self.flow.queue / (record['id'] + '.md')).read_text()
        self.assertIn(notes, brief)
        self.assertIn('scripts/asset-requests.sh finish', brief)
        self.assertIn('README.md', brief)
        result = subprocess.run([sys.executable, str(ROOT / 'pipeline/asset_workflow.py'), '--root', str(self.root), 'show', record['id']], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(json.loads(result.stdout)['data']['notes'], notes)
        self.assertFalse((self.root / 'NO').exists())

    def test_new_request_optional_notes_and_multiple_results(self):
        with self.assertRaises(WorkflowError):self.flow.submit({'kind': 'new', 'title': '  '})
        record = self.flow.submit({'kind': 'new', 'title': 'Weathered seaside house'})
        self.assertEqual(record['status'], 'requested')
        self.assertEqual(record['notes'], '')
        self.assertEqual(record['asset'], {})
        self.flow.transition(record['id'], 'start', {})
        self.add_asset('second-result')
        finished = self.flow.transition(record['id'], 'finish', {'assets': ['fixture-model', 'second-result'], 'summary': 'Both results built and checked', 'review': self.review()})
        self.assertEqual(finished['status'], 'finished')
        self.assertEqual(len(finished['result']['fingerprints']), 2)
        self.assertTrue(self.flow.overview()['requests'][0]['review_current'])
        self.assertEqual(self.flow.transition(record['id'], 'accept', {})['status'], 'accepted')

    def test_finished_requires_review_and_current_normal_build(self):
        record = self.flow.submit({'kind': 'update', 'asset_id': 'fixture-model'})
        with self.assertRaises(WorkflowError):self.flow.transition(record['id'], 'finish', {'assets': ['fixture-model']})
        runtime = self.root / self.catalog['assets']['fixture-model']['runtime']
        runtime.write_bytes(b'changed after export')
        with self.assertRaises(WorkflowError):self.finish(record)
        runtime.write_bytes(b'test runtime')
        self.finish(record)
        runtime.write_bytes(b'changed after review')
        self.assertFalse(self.flow.overview()['requests'][0]['review_current'])
        with self.assertRaises(WorkflowError):self.flow.transition(record['id'], 'accept', {})
        self.assertEqual(self.flow.record(record['id'])['status'], 'finished')

    def test_requesting_changes_removes_previous_finished_queue_entry(self):
        record = self.flow.submit({'kind': 'update', 'asset_id': 'fixture-model'})
        self.finish(record)
        new = self.flow.submit({'kind': 'update', 'asset_id': 'fixture-model', 'notes': 'One more detail'})
        self.assertEqual(self.flow.record(record['id'])['status'], 'changes_requested')
        self.assertEqual(self.flow.record(new['id'])['status'], 'requested')

    def test_delete_removes_owned_source_history_runtime_sidecars_and_catalog(self):
        self.add_asset('keep-neighbour')
        old = self.root / 'art/source/world/fixture-model/v0/model.blend'
        old.parent.mkdir(parents=True)
        old.write_bytes(b'previous source')
        before = (self.root / 'assets/world/keep-neighbour/model.glb').read_bytes()
        plan = self.flow.plan_delete('fixture-model')
        self.assertFalse(plan['blockers'])
        self.assertIn(str(old.relative_to(self.root)), plan['files'])
        deleted = self.flow.delete('fixture-model', plan['token'])
        self.assertEqual(deleted['status'], 'deleted')
        self.assertFalse((self.root / 'art/source/world/fixture-model').exists())
        self.assertFalse((self.root / 'assets/world/fixture-model').exists())
        self.assertNotIn('fixture-model', self.flow.catalog()['assets'])
        self.assertEqual((self.root / 'assets/world/keep-neighbour/model.glb').read_bytes(), before)
        self.assertFalse(any((self.root / '.cache/asset-deletion').iterdir()))
        self.assertTrue((self.flow.queue / (deleted['id'] + '.md')).is_file())

    def test_live_content_code_and_area_variants_block_delete(self):
        paths = ['content/areas/room.json', 'scenes/asset_user.gd', 'test/fixture_usage.gd']
        for relative in paths:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('"fixture-model"')
        self.catalog['areas'] = {'room': {'presentation': {'post_lamp': 'fixture-model'}}}
        self.write_catalog()
        plan = self.flow.plan_delete('fixture-model')
        self.assertTrue(set(paths).issubset({item['path'] for item in plan['blockers']}))
        self.assertIn('pipeline/world-catalog.json', {item['path'] for item in plan['blockers']})
        with self.assertRaises(WorkflowError):self.flow.delete('fixture-model', plan['token'])
        record = self.flow.submit({'kind': 'delete', 'asset_id': 'fixture-model', 'notes': 'Remove the old design'})
        self.assertEqual(record['status'], 'requested')
        self.assertEqual(len(record['dependencies']), len(plan['blockers']))
        with self.assertRaises(WorkflowError):self.finish(record)
        for relative in paths:(self.root / relative).unlink()
        self.catalog['areas'] = {}
        self.write_catalog()
        deleted = self.flow.delete('fixture-model', self.flow.plan_delete('fixture-model')['token'], record['id'])
        self.assertEqual(deleted['id'], record['id'])
        self.assertEqual(deleted['notes'], 'Remove the old design')

    def test_stale_delete_plan_cannot_remove_changed_source(self):
        plan = self.flow.plan_delete('fixture-model')
        path = self.root / 'art/source/world/fixture-model/v1/model.blend'
        path.write_bytes(b'new artist work')
        with self.assertRaises(WorkflowError):self.flow.delete('fixture-model', plan['token'])
        self.assertEqual(path.read_bytes(), b'new artist work')

    def test_shared_and_symlink_paths_are_not_deleted(self):
        self.catalog['assets']['shared-variant'] = dict(self.catalog['assets']['fixture-model'])
        self.write_catalog()
        self.assertTrue(self.flow.plan_delete('fixture-model')['blockers'])
        self.assertTrue(self.flow.plan_delete('shared-variant')['blockers'])
        link = self.root / 'art/source/world/fixture-model/v1/link'
        link.symlink_to(self.root / 'project.godot')
        self.assertTrue(self.flow.plan_delete('fixture-model')['blockers'])

    def test_failed_catalog_write_rolls_back_exact_catalog_and_files(self):
        plan = self.flow.plan_delete('fixture-model')
        before = self.flow.catalog_path.read_bytes()
        with patch.object(module, 'atomic_json', side_effect=OSError('simulated write failure')):
            with self.assertRaises(OSError):self.flow.delete('fixture-model', plan['token'])
        self.assertEqual(self.flow.catalog_path.read_bytes(), before)
        self.assertTrue((self.root / 'assets/world/fixture-model/model.glb').is_file())
        self.assertTrue((self.root / 'art/source/world/fixture-model/v1/model.blend').is_file())

    def test_failed_receipt_write_also_rolls_back_catalog_files_and_queue(self):
        record = self.flow.submit({'kind': 'delete', 'asset_id': 'fixture-model'})
        before = {path: path.read_bytes() for path in self.flow.queue.iterdir()}
        catalog = self.flow.catalog_path.read_bytes()
        original_save = self.flow.save
        def interrupted_save(data):
            original_save(data)
            raise OSError('simulated interruption after receipt write')
        with patch.object(self.flow, 'save', side_effect=interrupted_save):
            with self.assertRaises(OSError):self.flow.delete('fixture-model', self.flow.plan_delete('fixture-model')['token'], record['id'])
        self.assertEqual(self.flow.catalog_path.read_bytes(), catalog)
        self.assertEqual({path: path.read_bytes() for path in self.flow.queue.iterdir()}, before)
        self.assertTrue((self.root / 'assets/world/fixture-model/model.glb').is_file())

    def test_request_paths_lock_and_validation(self):
        for path in ['../outside', '/tmp/outside']:
            with self.assertRaises(WorkflowError):self.flow.safe(path)
        with self.assertRaises(WorkflowError):self.flow.record('../outside')
        with self.flow.lock():
            with self.assertRaises(WorkflowError):self.flow.submit({'kind': 'new', 'title': 'House'})
        self.assertFalse((self.root / 'asset-requests/.write-lock').exists())
        for data in [{'kind': 'no'}, {'kind': 'update', 'asset_id': 'unknown'}, {'kind': 'new', 'title': 'House', 'references': ['missing']}]:
            with self.assertRaises(WorkflowError):self.flow.submit(data)


if __name__ == '__main__':
    unittest.main()
