"""Development regression test: a command's integer result is the process's exit status, so a
caller of `python -m harness <command>` (a session, a script, the operator's shell) sees a failed
gate, validation or doctor as a failure."""
import subprocess
import sys
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def status(result: str) -> int:
    code = ("import harness.__main__ as m\n"
            f"m.Cli.probe = lambda self: {result}\n"
            "m.main()\n")
    return subprocess.run([sys.executable, "-c", code, "probe"], cwd=REPO, capture_output=True, text=True).returncode


class ExitStatus(unittest.TestCase):
    def test_the_result_is_the_exit_status(self):
        self.assertEqual(status("0"), 0)
        self.assertEqual(status("1"), 1)
        self.assertEqual(status("3"), 3)

    def test_a_command_without_an_integer_result_exits_zero(self):
        self.assertEqual(status("None"), 0)
        self.assertEqual(status("'text'"), 0)


if __name__ == "__main__":
    unittest.main()
