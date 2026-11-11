"""The version note "[Effective ...]" of a section never reaches its title or text."""
import contextlib
import importlib
import os
from pathlib import Path
import re
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parent
SOURCES = TOOLS / "sources"


def load_make_laws():
    """make_laws reads the chapter files from the working directory at import."""
    with tempfile.TemporaryDirectory() as tmp, contextlib.chdir(tmp):
        for f in sorted(SOURCES.glob("*.json")):
            if f.name != "lvmc.json":
                os.symlink(f, f.name)
        os.mkdir("lvmc")
        os.symlink(SOURCES / "lvmc.json", "lvmc/lvmc.json")
        sys.path.insert(0, str(TOOLS))
        try:
            return importlib.import_module("make_laws")
        finally:
            sys.path.remove(str(TOOLS))


class VersionNoteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.make_laws = load_make_laws()

    def test_no_section_keeps_its_version_note(self):
        for ch, sections in self.make_laws.NRS.items():
            for sec in sections:
                title, tree, _ = self.make_laws.section("NRS", ch, sec)
                for part in (title, tree["text"]):
                    with self.subTest(section=f"{ch}.{sec}"):
                        self.assertNotIn("[Effective", part)
                        self.assertIsNone(re.match(r"[^\[]*\]", part), part[:120])

    def test_wrapped_note_is_cut_at_its_closing_bracket(self):
        split_title = self.make_laws.split_title
        self.assertEqual(split_title("“X” defined. [Effective on the date",
                                     "a notice is given.]  “X” means a thing."),
                         ("“X” defined", "“X” means a thing."))
        self.assertEqual(split_title("Y. [Effective through June 30, 2028.]", "1. Z."), ("Y", "1. Z."))


if __name__ == "__main__":
    unittest.main()
