"""A test run (`--mode test` over a training run) is a staged run of its own kind: its first stage is
`T0`, a test stage that names its base run, allows only test launches, is never reviewed, label-checked,
handed over or left by a transition, and is no training evidence.

On the real loop with stand-in sessions: a training run `A` is generated (`--label_deferred`); a new
test run `T` over it starts in `T0` (base run and its digest recorded, marker written), stops at its
iteration bound and resumes in the same stage, and is scored by `score_split`. Refused, writing
nothing: a test run launched with a label option; a run of either kind built on `T`; a transition out
of `T0`; a handoff export of `T`. A test run made as before stages existed is unchanged."""
import json
import unittest
from unittest import mock

from harness import loop
from harness.store import paths, stages
from harness.tools import handoff, stage
from harness.tools.score_split import score
from scripts.subset_laws import subset
from scripts.tests.test_recovery import Fixture, World, node


def world() -> World:
    w = World({"L-1": "shall stop.", "L-2": "shall yield."})
    w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")], "L-2": [node("L_2", "shall yield.", "L-2")]}
    return w


def laws(f, run_id, ids):
    return subset(run_id, f.root / "corpus" / "laws.jsonl", ids)


def files(f) -> dict:
    return {p.relative_to(f.root).as_posix(): p.read_bytes() for p in sorted(f.root.rglob("*")) if p.is_file()}


class TestRun(unittest.TestCase):

    def training(self, f):
        self.assertEqual(f.drive(1, run_id="A", laws=laws(f, "A", ["L-1"]), label_repair=True, label_deferred=True),
                         ["awaiting_labels"])

    def test_a_test_run_starts_in_t0_resumes_there_and_is_scored(self):
        with Fixture(world(), staged=True) as f:
            self.training(f)
            t_laws = laws(f, "T", ["L-2"])
            f.drive(1, run_id="T", laws=t_laws, mode="test", base_run="A", max_iterations=1)
            rd = paths.run_dir("T")
            rows = stages.read_stages(rd)
            self.assertEqual(len(rows), 1)
            t0 = rows[0]
            self.assertEqual((t0["stage_id"], t0["stage_kind"], t0["launch_kinds"]), ("T0", "test", ["test"]))
            sem = loop.semantic_inputs(f.options(run_id="T", laws=t_laws, mode="test", base_run="A"))
            self.assertEqual(t0["base_run"], {"run_id": "A", "digest": sem["base_run"]})
            self.assertEqual(t0["acceptance_policy"]["label_repair"], False)
            self.assertEqual(json.loads((rd / "options.json").read_text())["stage_policy"], loop.STAGE_POLICY)
            # resumed past its iteration bound, in the same stage
            f.drive(1, run_id="T", laws=t_laws, mode="test", base_run="A", max_iterations=3)
            self.assertEqual(stages.read_stages(rd), rows)
            atoms = f.tmp / "split_atoms.json"
            atoms.write_text(json.dumps({"test_only_atoms": [], "test_only_values": []}))
            scored = score("T", atoms)
            self.assertIsInstance(scored, dict)

    def test_what_a_test_run_refuses_writes_nothing(self):
        with Fixture(world(), staged=True) as f:
            self.training(f)
            split = "a split run .* does not carry a base_run chain"
            for flags, words in (({"label_repair": True, "label_deferred": True}, split),
                                 ({"label_repair": True, "label_stage": True, "label_dataset": "ds"}, split),
                                 ({"label_repair": True, "label_dataset": "ds"}, "a test run checks no labels")):
                with self.subTest(flags=flags):
                    before = files(f)
                    with self.assertRaisesRegex(SystemExit, words):
                        loop.run_loop(f.options(run_id="T1", laws=laws(f, "T1", ["L-2"]), mode="test", base_run="A", **flags))
                    self.assertEqual({k for k in files(f) if "/T1/" not in k and not k.startswith("results/T1")},
                                     {k for k in before if not k.startswith("results/T1")})
                    self.assertFalse((paths.run_dir("T1") / "options.json").exists())
            f.drive(1, run_id="T", laws=laws(f, "T", ["L-2"]), mode="test", base_run="A")
            before = files(f)
            for opts in (dict(run_id="U", laws=laws(f, "U", ["L-1"]), label_repair=True, label_deferred=True, base_run="T"),
                         dict(run_id="V", laws=laws(f, "V", ["L-2"]), mode="test", base_run="T")):
                with self.subTest(base_of=opts["run_id"]), self.assertRaisesRegex(SystemExit, "is a test run: .*no training evidence"):
                    loop.run_loop(f.options(**{k: v for k, v in opts.items()}))
            self.assertEqual({k: v for k, v in files(f).items() if k in before}, before)
            with self.assertRaises(SystemExit):
                stage.enter("T", "generation", "T0", "t1")
            with self.assertRaisesRegex(SystemExit, "base_run"):
                handoff.export("T")
            self.assertEqual(stages.read_stages(paths.run_dir("T"))[0]["stage_id"], "T0")
            self.assertIsNone(stages.transition_state(paths.run_dir("T")))

    def test_a_test_run_made_before_stages_is_unchanged(self):
        with Fixture(world()) as f:
            f.drive(1, run_id="A", laws=laws(f, "A", ["L-1"]))
            f.drive(1, run_id="T", laws=laws(f, "T", ["L-2"]), mode="test", base_run="A")
            self.assertFalse((paths.run_dir("T") / stages.STAGES_FILE).exists())
            self.assertNotIn("stage_policy", json.loads((paths.run_dir("T") / "options.json").read_text()))


if __name__ == "__main__":
    unittest.main()
