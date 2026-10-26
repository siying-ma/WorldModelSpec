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

    def test_source_manifest_mask_and_unwritten_indicator(self):
        lib = Path(__file__).resolve().parents[2] / "traffic-spec-agent/library"
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            source.mkdir()
            scenes = [{"t": 0, "subject": 1, "users": [{"track": 1, "sig": {"brake_lamp": False}},
                                                      {"track": 2, "sig": {"brake_lamp": False}}]},
                      {"t": 50, "subject": 1, "users": [{"track": 1, "sig": {"turn_indicator": "left"}}]},
                      {"t": 100, "subject": 1, "users": [{"track": 1}]}]
            (source / "trace.json").write_text(json.dumps({"scenes": scenes}))
            shared = Path(tmp) / "source_manifest.json"
            shared.write_text(json.dumps({"source": "test", "atoms": {"sig.turn_indicator": "exact", "sig.hazard": "exact"}}))
            out = Path(tmp) / "out"
            with patch("sys.argv", ["prepare_cases", str(source), str(out), "--library", str(lib), "--manifest", str(shared),
                                    "--mask", "sig.hazard=reported wrongly", "--indicator-off"]):
                main()
            got = json.loads((out / "trace.json").read_text())["scenes"]
            self.assertEqual(got[0]["users"][0]["sig"]["turn_indicator"], "off")
            self.assertNotIn("turn_indicator", got[0]["users"][1]["sig"])   # not the subject
            self.assertEqual(got[1]["users"][0]["sig"]["turn_indicator"], "left")
            self.assertNotIn("sig", got[2]["users"][0])                      # signals not reported: unknown stays unknown
            manifest = json.loads((out / "manifest.json").read_text())
            self.assertEqual(manifest["atoms"]["sig.hazard"], "absent")
            self.assertEqual(manifest["atoms"]["sig.turn_indicator"], "exact")
            conversion = json.loads((out / "conversion.json").read_text())
            self.assertEqual(conversion["masked_atoms"], {"sig.hazard": "reported wrongly"})
            self.assertEqual(conversion["assumptions"], {"unwritten_turn_indicator": "off"})
            self.assertEqual(conversion["manifest"], str(shared.resolve()))

    def test_mask_of_unknown_atom_rejected(self):
        lib = Path(__file__).resolve().parents[2] / "traffic-spec-agent/library"
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            source.mkdir()
            (source / "trace.json").write_text('{"scenes":[{"t":0}]}')
            (source / "manifest.json").write_text(json.dumps({"source": "test", "atoms": {}}))
            with patch("sys.argv", ["prepare_cases", str(source), str(Path(tmp) / "out"), "--library", str(lib),
                                    "--mask", "sig.no_such_atom=typo"]):
                with self.assertRaises(ValueError):
                    main()

    def test_demo13_manifest_is_complete(self):
        lib = Path(__file__).resolve().parents[2] / "traffic-spec-agent/library"
        atoms = json.loads((Path(__file__).parent / "demo13_manifest.json").read_text())["atoms"]
        self.assertEqual(set(atoms), set(atom_ids(lib)))


if __name__ == "__main__":
    unittest.main()
