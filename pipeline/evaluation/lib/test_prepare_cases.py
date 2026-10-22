"""Offline checks for evidence-preserving migration of historical trace exports."""
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from prepare_cases import atom_ids, iter_scenes, main, migrate_scene


class PreparationTests(unittest.TestCase):
    def test_stream_round_trip(self):
        scenes = [{"t": 0, "users": [], "structures": []},
                  {"t": 50, "env": {"wet_road": False}, "name": 'quoted " scene'}]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "trace.json"
            path.write_text(json.dumps({"scenes": scenes}))
            for chunk_size in (16, 32, 64, 65536):
                self.assertEqual(list(iter_scenes(path, chunk_size)), scenes)

    def test_truncation_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "trace.json"
            path.write_text('{"scenes":[{"t":0}')
            with self.assertRaises(ValueError):
                list(iter_scenes(path))

    def test_migration_preserves_measurements(self):
        scene = {"t": 50, "users": [{"track": 58, "classes": ["motor_vehicle"],
                 "unobserved_classes": ["animal_or_animal_drawn", "electric_scooter"],
                 "kin": {"extent": [2.4, 1.1, .7], "yaw_rate": -8.5}}],
                 "occupies": [[58, 1]], "structures": [{"id": 1, "sight_distance": 150.0}]}
        before = json.loads(json.dumps(scene))
        before["users"][0]["unobserved_classes"] = ["electric_scooter"]
        self.assertEqual(migrate_scene(scene), before)

    def test_retired_positive_class_is_not_dropped(self):
        with self.assertRaises(ValueError):
            migrate_scene({"users": [{"classes": ["animal_or_animal_drawn"]}]})

    def test_atom_list_excludes_primitives(self):
        lib = Path(__file__).resolve().parents[2] / "traffic-spec-agent/library"
        ids = atom_ids(lib)
        self.assertIn("st.sight_along_way", ids)
        self.assertFalse(any(i.startswith("prim.") for i in ids))

    def test_cli_completes_manifest_without_filling_observations(self):
        lib = Path(__file__).resolve().parents[2] / "traffic-spec-agent/library"
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            source.mkdir()
            trace = '{"scenes":[{"t":0,"env":{"wet_road":false},"users":[]}]}'
            (source / "trace.json").write_text(trace)
            (source / "manifest.json").write_text(json.dumps({"source": "test", "atoms": {
                "env.wet_road": "exact", "ru.animal_or_animal_drawn": "absent"}}))
            out = Path(tmp) / "out"
            with patch("sys.argv", ["prepare_cases", str(source), str(out), "--library", str(lib)]):
                main()
            self.assertEqual(json.loads((out / "trace.json").read_text()), json.loads(trace))
            self.assertEqual((source / "trace.json").read_text(), trace)
            manifest = json.loads((out / "manifest.json").read_text())
            self.assertEqual(set(manifest["atoms"]), set(atom_ids(lib)))
            self.assertEqual(manifest["atoms"]["env.visibility"], "absent")
            self.assertEqual(manifest["atoms"]["env.wet_road"], "exact")
            self.assertEqual(json.loads((out / "conversion.json").read_text())["assumptions"], {})


if __name__ == "__main__":
    unittest.main()
