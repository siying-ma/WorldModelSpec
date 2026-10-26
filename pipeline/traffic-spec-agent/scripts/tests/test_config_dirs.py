"""Development regression tests: the Claude Code configuration directories every session is denied."""
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.agents import session


class ConfigDirs(unittest.TestCase):

    def test_both_the_named_account_and_the_default_are_denied(self):
        with tempfile.TemporaryDirectory() as t:
            home, other = Path(t) / "home", Path(t) / "home" / ".claude-acct2"
            (home / ".claude").mkdir(parents=True); other.mkdir()
            with mock.patch.dict(os.environ, {"CLAUDE_CONFIG_DIR": str(other)}), mock.patch.object(Path, "home", return_value=home):
                got = {str(d) for d in session.config_dirs()}
            self.assertIn(str(other), got)
            self.assertIn(str(home / ".claude"), got)

    def test_without_a_named_account_the_default_is_denied(self):
        with tempfile.TemporaryDirectory() as t:
            home = Path(t) / "home"; (home / ".claude").mkdir(parents=True)
            env = {k: v for k, v in os.environ.items() if k != "CLAUDE_CONFIG_DIR"}
            with mock.patch.dict(os.environ, env, clear=True), mock.patch.object(Path, "home", return_value=home):
                self.assertEqual({str(d) for d in session.config_dirs()}, {str(home / ".claude")})

    def test_the_deny_rules_carry_both(self):
        with tempfile.TemporaryDirectory() as t:
            home, other = Path(t) / "home", Path(t) / "acct2"
            (home / ".claude").mkdir(parents=True); other.mkdir()
            with mock.patch.dict(os.environ, {"CLAUDE_CONFIG_DIR": str(other)}), mock.patch.object(Path, "home", return_value=home):
                rules = " ".join(session.deny_rules("plan"))
            self.assertIn(f"Read(/{home / '.claude'}/**)", rules)
            self.assertIn(f"Read(/{other}/**)", rules)


if __name__ == "__main__":
    unittest.main()
