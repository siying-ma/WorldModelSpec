"""While a stage transition is begun and not finished, no other command writes the library, a run or
the gap ledger; read-only commands still answer, and the transition is still finished by running it
again.

At every write point of a real `stage enter` where the transition is left short of `done`, each
writing command (`reopen`, `reopen --admission`, `gap decide`, `gap archive`, `init`, `index`,
`verify`, `split`, `gate`, `label_check`, a standalone `handoff export`) is refused before it takes
the library, and the whole repository (the run, the library, the gap ledger) is byte for byte as it
was; `gap list`, `stage show` and `status` still answer. Then the same `stage enter` finishes the
transition. With no transition in progress the check lets every command through to the library."""
import io
import json
import unittest
from contextlib import redirect_stdout
from unittest import mock

from harness import __main__ as cli_mod
from harness.store import owner, paths, stages
from harness.tools import handoff, stage
from scripts.tests import test_s24_a2_stage as a2
from scripts.tests.s24_helpers import real_ownership, released

REAL_ACQUIRE_FOR_COMMAND = owner.acquire_for_command


def writing_commands(cli):
    return {"reopen": lambda: cli.reopen("r", laws="L-1"),
            "reopen --admission": lambda: cli.reopen("r", laws="L-1", admission=True),
            "gap decide": lambda: cli.gap("decide", "G1", state="rejected", decision="particular"),
            "gap archive": lambda: cli.gap("archive"),
            "init": lambda: cli.init(),
            "index": lambda: cli.index(),
            "verify": lambda: cli.verify("r"),
            "split": lambda: cli.split("train"),
            "gate": lambda: cli.gate("r", "L_1"),
            "label_check": lambda: cli.label_check("r"),
            "handoff export": lambda: cli.handoff("export", "r")}


def read_commands(cli):
    return {"gap list": lambda: cli.gap("list"), "stage show": lambda: stage.show("r"), "status": lambda: cli.status("r")}


class TransitionHoldsWriters(unittest.TestCase):

    def test_every_writer_is_refused_at_every_unfinished_state_and_the_transition_still_finishes(self):
        k, finished, states = 0, False, set()
        while not finished and k < 30:
            k += 1
            with self.subTest(stop_after=k), a2.world() as w:
                w.change("scripts/run-generation.sh")
                pw, pr, _n = a2.StoppedTransition.counting(k)
                try:
                    with real_ownership(), pw, pr:                    # the transition takes the library for real
                        stage.enter("r", "generation", "G0", "t1")
                    finished = True
                except a2.Crash:
                    pass
                if finished:
                    break
                st = stages.transition_state(w.rd)
                if st is None or st.get("status") == "done":
                    continue
                states.add(st["status"])
                released()                                            # the stopped transition's process has ended
                before = a2.tree_bytes(w.root)
                cli = cli_mod.Cli()
                with real_ownership():                                # each command takes the library as its own process
                    for name, run in writing_commands(cli).items():
                        with self.subTest(stop_after=k, command=name):
                            with self.assertRaisesRegex(SystemExit, "stage transition `t1` stopped at"), redirect_stdout(io.StringIO()):
                                run()
                            self.assertFalse(owner.holds(), name)     # refused before the library was taken
                            released()
                            self.assertEqual(a2.tree_bytes(w.root), before, name)
                    for name, run in read_commands(cli).items():
                        with self.subTest(stop_after=k, command=name), redirect_stdout(io.StringIO()):
                            self.assertEqual(run(), 0)
                self.assertEqual(a2.tree_bytes(w.root), before)
                with real_ownership():                                # the transition is still finished by running it again
                    rec = stage.enter("r", "generation", "G0", "t1")
                    released()
                    self.assertEqual(rec["status"], "exported")
                    stage.confirm("r", "t1", w.push())
                self.assertIsNone(stages.unfinished_transitions(paths.RESULTS))
        self.assertTrue(finished)
        self.assertTrue({"prepared", "applied"} <= states, states)

    def test_with_no_transition_in_progress_the_writers_reach_the_library(self):
        took = []
        with a2.world() as w:
            cli = cli_mod.Cli()
            with mock.patch.object(owner, "acquire_for_command", REAL_ACQUIRE_FOR_COMMAND), \
                    mock.patch.object(owner, "acquire", lambda name: took.append(name) or (_ for _ in ()).throw(SystemExit("taken"))):
                for name, run in writing_commands(cli).items():
                    if name in ("gap decide", "handoff export"):      # no library lock / the export is stood in for here
                        continue
                    with self.subTest(command=name), self.assertRaisesRegex(SystemExit, "^taken$"), redirect_stdout(io.StringIO()):
                        run()
        self.assertEqual(len(took), len(writing_commands(cli_mod.Cli())) - 2)

    def test_another_runs_unfinished_transition_holds_a_transitions_own_export(self):
        """A transition's own export goes on past its own unfinished state, never past another run's."""
        with a2.world() as w:
            (w.rd.parent / "other").mkdir()
            (w.rd.parent / "other" / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": "t9", "status": "applied"}))
            self.assertIn("run `other`", stages.unfinished_transitions(paths.RESULTS, ("r", "t1")))
            (w.rd / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": "t1", "status": "applied"}))
            self.assertNotIn("run `r`", stages.unfinished_transitions(paths.RESULTS, ("r", "t1")))
            self.assertIn("run `r`", stages.unfinished_transitions(paths.RESULTS, ("r", "t-other")))


if __name__ == "__main__":
    unittest.main()
