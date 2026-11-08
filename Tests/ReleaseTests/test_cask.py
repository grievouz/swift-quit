import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/update-homebrew-cask.py"


class CaskTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.tap = self.root / "tap"
        self.dmg = self.root / "swift-quit-1.0.0-universal.dmg"
        self.dmg.write_bytes(b"release fixture")

    def run_updater(self, tag="v1.0.0", dmg=None):
        return subprocess.run([sys.executable, str(SCRIPT), tag, str(dmg or self.dmg), str(self.tap)],
                              text=True, capture_output=True)

    def test_uses_downloaded_bytes_and_is_idempotent(self):
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        target = self.tap / "Casks/swift-quit.rb"
        original = target.read_text()
        self.assertIn(hashlib.sha256(self.dmg.read_bytes()).hexdigest(), original)
        self.assertIn('app "Swift Quit.app"', original)
        self.assertEqual(self.run_updater().returncode, 0)
        self.assertEqual(target.read_text(), original)

    def test_invalid_tag_cannot_write_a_cask(self):
        result = self.run_updater('v1.0.0"; puts "bad')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.tap.exists())

    def test_filename_must_match_the_version(self):
        result = self.run_updater("v2.0.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.tap.exists())

    def test_old_release_cannot_downgrade_tap(self):
        future = self.root / "swift-quit-2.0.0-universal.dmg"
        future.write_bytes(b"new release")
        self.assertEqual(self.run_updater("v2.0.0", future).returncode, 0)
        target = self.tap / "Casks/swift-quit.rb"
        original = target.read_text()
        self.assertNotEqual(self.run_updater().returncode, 0)
        self.assertEqual(target.read_text(), original)
