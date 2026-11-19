"""The launcher's status handling at a handover, with a staged run on a temporary git repository with a
local bare remote: `awaiting_review` and `awaiting_labels` end the launches with status 0 at a pushed
checkpoint, and the run enters the next stage itself (a stage commit `auto-<stage>-<kind>` on the same
code, then the next launch with that stage's options) only when the harness's `stage handover` says
so; it waits at its checkpoint when the harness gives reasons, is the operator's (4) on a round trip
without progress, is never moved from generation to labels, and a run without a stage record is
handed over by hand. A transition stopped midway is continued by the `stage-enter` command the launcher
logged.

The harness is `test_s24_d_launcher`'s stand-in; its `stage handover` answers as `FAKE_HANDOVER` says."""
import json
import unittest
from pathlib import Path

from scripts.tests import test_s24_d_launcher as staged
from scripts.tests.test_split_launcher import git


class Handover(unittest.TestCase):
    setUp_base, launch, loops, remote_files = staged.Staged.setUp_base, staged.Staged.launch, staged.Staged.loops, staged.Staged.remote_files
    setUp, make_base, py, adopt = staged.Staged.setUp, staged.Staged.make_base, staged.Staged.py, staged.Staged.adopt
    stage_calls, head, clean = staged.Staged.stage_calls, staged.Staged.head, staged.Staged.clean

    def handovers(self):
        f = Path(str(self.log) + ".handover")
        return [json.loads(x)["argv"] for x in f.read_text().splitlines()] if f.exists() else []

    def launcher_log(self):
        return (self.agent / ".runtime" / "t1" / "launcher.log").read_text()

    def subjects(self):
        return git(self.remote, "log", "--format=%s", "runs/t1").stdout.splitlines()

    def test_the_run_enters_each_stage_the_harness_allows_and_goes_on(self):
        ds = self.t / "ds"; ds.mkdir()
        base = self.head()
        out = self.launch("resume", [{"status": "awaiting_review"}, {"status": "awaiting_labels"}, {"status": "complete"}],
                          FAKE_HANDOVER=json.dumps({"review": 0, "labels": 0}), LABEL_DATASET=str(ds))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        argvs = [x["argv"] for x in self.loops()[1:]]
        self.assertIn("--label_deferred", argvs[0])
        self.assertIn("--review_stage", argvs[1])
        self.assertFalse({"--label_deferred", "--label_stage"} & set(argvs[1]))
        self.assertEqual(argvs[2][argvs[2].index("--label_dataset") + 1], str(ds))
        self.assertNotIn("--label_repair", argvs[1] + argvs[2])                       # the run keeps its policy
        enters = [c["argv"] for c in self.stage_calls() if c["argv"][1] == "enter"]
        self.assertEqual([(a[a.index("--kind") + 1], a[a.index("--from") + 1], a[a.index("--transition") + 1]) for a in enters],
                         [("review", "G0", "auto-G0-review"), ("labels", "R1", "auto-R1-labels")])
        self.assertEqual([a[a.index("--to") + 1] for a in self.handovers()], ["review", "labels"])
        self.assertEqual(self.handovers()[1][self.handovers()[1].index("--dataset") + 1], str(ds))
        subjects = self.subjects()
        self.assertEqual(sum(s.startswith("stage R1: baseline ") for s in subjects), 1)
        self.assertEqual(sum(s.startswith("stage L2: baseline ") for s in subjects), 1)
        self.assertEqual(git(self.work, "diff", "--stat", base, "HEAD", "--", "pipeline/agent/harness").stdout, "")   # the same code
        self.assertTrue(self.clean())
        self.assertEqual(self.head(), git(self.remote, "rev-parse", "runs/t1").stdout.strip())

    def test_the_reviewer_is_named_only_on_a_review_entry(self):
        """BEHAVIOUR_REVIEWER reaches `stage handover --to review` and `stage enter --kind review` only:
        no loop launch, no labels handover or entry; unset, no command names a reviewer."""
        ds = self.t / "ds"; ds.mkdir()
        out = self.launch("resume", [{"status": "awaiting_review"}, {"status": "awaiting_labels"}, {"status": "complete"}],
                          FAKE_HANDOVER=json.dumps({"review": 0, "labels": 0}), LABEL_DATASET=str(ds), BEHAVIOUR_REVIEWER="fake")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        argvs = [x["argv"] for x in self.loops()[1:]]
        self.assertEqual(len(argvs), 3)
        self.assertTrue(all("--behaviour_reviewer" not in a for a in argvs), argvs)   # no generation, review or labels launch
        named = lambda a: a[a.index("--behaviour_reviewer") + 1] if "--behaviour_reviewer" in a else None
        self.assertEqual([(a[a.index("--to") + 1], named(a)) for a in self.handovers()], [("review", "fake"), ("labels", None)])
        enters = [c["argv"] for c in self.stage_calls() if c["argv"][1] == "enter"]
        self.assertEqual([(a[a.index("--kind") + 1], named(a)) for a in enters], [("review", "fake"), ("labels", None)])

    def test_unset_no_command_names_a_reviewer(self):
        out = self.launch("resume", [{"status": "awaiting_review"}, {"status": "complete"}], FAKE_HANDOVER=json.dumps({"review": 0}))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        argvs = [x["argv"] for x in self.loops()] + self.handovers() + [c["argv"] for c in self.stage_calls()]
        self.assertTrue(argvs and all("--behaviour_reviewer" not in a for a in argvs), argvs)

    def test_a_handover_that_cannot_be_made_here_waits_at_its_checkpoint(self):
        out = self.launch("resume", [{"status": "awaiting_review"}, {"status": "complete"}])
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), 2)                                        # no further launch
        self.assertEqual([c for c in self.stage_calls() if c["argv"][1] == "enter"], [])
        self.assertIn("waits at its checkpoint for the review stage", self.launcher_log())
        self.assertIn("the stand-in's answer for review", self.launcher_log())
        self.assertIn("awaiting_review", self.subjects()[0])                          # its checkpoint is pushed
        self.assertEqual(self.head(), git(self.remote, "rev-parse", "runs/t1").stdout.strip())

    def test_a_round_trip_without_progress_is_the_operators(self):
        out = self.launch("resume", [{"status": "awaiting_review"}], FAKE_HANDOVER=json.dumps({"review": 4}))
        self.assertEqual(out.returncode, 4, out.stdout + out.stderr)
        self.assertIn("operator decision needed", self.launcher_log())
        self.assertEqual([c for c in self.stage_calls() if c["argv"][1] == "enter"], [])

    def test_a_stop_of_the_runs_sends_ends_the_launches_for_the_operator(self):
        """`RunStopped` ends a launch `awaiting_operator` with its stop in `stops`: the launcher exits 4
        after pushing the checkpoint, asks no handover and enters no stage, whatever a handover would say."""
        before = len(self.loops())
        stop = {"id": "stop-1", "kind": "wrong_model", "cause": "`A`: another model", "clears": "acknowledge --stop stop-1"}
        out = self.launch("resume", [{"status": "awaiting_operator", "stops": [stop]}, {"status": "complete"}],
                          FAKE_HANDOVER=json.dumps({"review": 0, "labels": 0}))
        self.assertEqual(out.returncode, 4, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), before + 1)                              # no further launch
        self.assertIn("operator decision needed; see stop_reason and TO_USER.md", self.launcher_log())
        self.assertEqual(self.handovers(), [])
        self.assertEqual([c for c in self.stage_calls() if c["argv"][1] == "enter"], [])
        self.assertIn("awaiting_operator", self.subjects()[0])                        # its checkpoint is pushed
        self.assertEqual(self.head(), git(self.remote, "rev-parse", "runs/t1").stdout.strip())

    def test_a_complete_run_with_an_open_stop_is_not_moved(self):
        """`complete` ends the launches with 0 and is never handed to another stage, a stop in `stops` or not."""
        before = len(self.loops())
        stop = {"id": "defect-1", "kind": "paused_defect", "cause": "x", "clears": "resume"}
        out = self.launch("resume", [{"status": "complete", "stops": [stop]}, {"status": "complete"}],
                          FAKE_HANDOVER=json.dumps({"review": 0, "labels": 0}))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), before + 1)
        self.assertEqual(self.handovers(), [])
        self.assertEqual([c for c in self.stage_calls() if c["argv"][1] == "enter"], [])

    def test_generation_is_never_moved_to_labels(self):
        out = self.launch("resume", [{"status": "awaiting_labels"}], FAKE_HANDOVER=json.dumps({"labels": 0}))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("only by the operator's stage-enter", self.launcher_log())
        self.assertEqual([c for c in self.stage_calls() if c["argv"][1] == "enter"], [])

    def test_a_run_without_a_stage_record_is_handed_over_by_hand(self):
        git(self.work, "rm", "-q", "--cached", "pipeline/agent/results/t1/stages.jsonl", "pipeline/agent/results/t1/stage_transition.json")
        for f in ("stages.jsonl", "stage_transition.json"):
            (self.agent / "results" / "t1" / f).unlink()
        git(self.work, "commit", "-q", "-m", "no stage record"); git(self.work, "push", "-q", "origin", "runs/t1")
        for status, says in (("awaiting_review", "run STAGE=review"), ("awaiting_labels", "run STAGE=labels")):
            with self.subTest(status):
                out = self.launch("resume", [{"status": status}], FAKE_HANDOVER=json.dumps({"review": 0, "labels": 0}))
                self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
                self.assertIn(says, self.launcher_log().splitlines()[-1])
        self.assertEqual(self.handovers(), [])

    def test_a_stopped_handover_is_continued_by_the_logged_stage_enter(self):
        out = self.launch("resume", [{"status": "awaiting_review"}], FAKE_HANDOVER=json.dumps({"review": 0}),
                          FAKE_STAGE=json.dumps({"at": "committed"}))
        self.assertEqual(out.returncode, 1, out.stdout + out.stderr)
        line = next(x for x in self.launcher_log().splitlines() if "entering the review stage" in x)
        env = dict(kv.split("=", 1) for kv in line.split("(", 1)[1].split() if "=" in kv and kv.split("=", 1)[0].isupper())
        self.assertEqual((env["KIND"], env["FROM"], env["TRANSITION"]), ("review", "G0", "auto-G0-review"))
        again = self.launch("resume", [{"status": "complete"}], STAGE="review")           # refused while the transition stands
        self.assertEqual(again.returncode, 2, again.stdout + again.stderr)
        done = self.launch("stage-enter", [], **{k: env[k] for k in ("NEW_BASE", "KIND", "FROM", "TRANSITION")})
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
        out = self.launch("resume", [{"status": "complete"}], STAGE="review")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn("--review_stage", self.loops()[-1]["argv"])


if __name__ == "__main__":
    unittest.main()
