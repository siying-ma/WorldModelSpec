"""Pending gaps the operator carries over from an earlier run (`config/deferred_gaps.jsonl`).

A new run binds the declarations of its corpus' laws to the corpus and fixes them; a declaration
that no longer matches stops the start. Every gap view of the run (the plan prompt, the node repair,
the candidate, every validator entry) shows each declaration as a pending context row under its
source identity, so a record that drops the words' gap is refused, and a record that keeps it files
a live gap that records its source (`deferred_from`): R1 blocks its node, its clean sibling is
coded, and a law composing it waits on that live gap, all in the first iteration. The live gap and its
decision stand for the declaration; a rejected or retired one never falls back to pending, and while
the list still declares it no new gap round starts (a new run, `init --fresh`, `gap archive`). The
real loop runs on `test_recovery`'s scripted world."""
import collections
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness import loop
from harness.__main__ import Cli
from harness.checks import validate_a
from harness.model import corpus
from harness.model.blueprint import Node
from harness.phases import candidate as candidate_phase, code as code_phase, plan as plan_phase, review as review_phase, validate as validate_phase
from harness.store import deferred_gaps, owner, paths
from harness.store.gaps import GapLedger, OpenGaps
from harness.store.state import Run
from scripts.tests import test_recovery as rec
from scripts.tests.test_planned_gaps import TEXT, laws, pair, planned_in
from scripts.tests.test_review_routing import ONTO

REAL_PLAN_SESSION = plan_phase.run_plan            # the fixture scripts the plan and repair sessions; the view test runs the real ones
REAL_NODE_REPAIR = plan_phase.run_node_repair
COMMIT = "0123456789abcdef0123456789abcdef01234567"
STOP = (0, 11)                                 # "shall stop." in TEXT, the span the pair's o1 carries its gap on


def declaration(law: str = "L-50", text: str = TEXT, at: tuple[int, int] = STOP, *, run: str = "srcA", gid: str = "G17",
                kind: str = "atom", digest: str | None = None) -> dict:
    d = digest or review_phase.law_digest(text)
    return {"source_commit": COMMIT, "source_run": run, "source_id": gid, "law": law, "law_digest": d,
            "occurrence": f"{law}@{d}:{at[0]}-{at[1]}", "span": text[at[0]:at[1]], "kind": kind,
            "proposal": "`ru.procession_member` | a member of an organized group", "source_state": "proposed"}


class Declared:
    """A declarations file for the test's span, patched in as the operator's list."""

    def __init__(self, rows: list[dict]):
        self.tmp = tempfile.TemporaryDirectory()
        self.file = Path(self.tmp.name) / "deferred_gaps.jsonl"
        self.write(rows)
        self.patch = mock.patch.object(deferred_gaps, "DECLARATIONS", self.file)

    def write(self, rows: list[dict]) -> None:
        self.file.write_text("".join(json.dumps(r) + "\n" for r in rows), encoding="utf-8")

    def __enter__(self):
        self.patch.start()
        return self

    def __exit__(self, *exc):
        self.patch.stop()
        self.tmp.cleanup()
        return False


def kept() -> rec.World:
    """L-50's o1 keeps the declared gap on "shall stop.", its o2 carries none; L-51's node composes o1."""
    w = rec.World({"L-50": TEXT, "L-51": "shall wait."})
    w.plans = {"L-50": list(pair("L-50")), "L-51": [rec.node("L_51", "shall wait.", "L-51", compositions=["L_50_o1"])]}
    return w


kept.opts = {"max_iterations": 1}


def live(f=None) -> list[dict]:
    return GapLedger(paths.GAPS_DIR).live_rows()


def view(run_id: str = "r") -> GapLedger:
    return GapLedger.for_run(paths.GAPS_DIR, Run.load(run_id))


def coded(w: rec.World) -> collections.Counter:
    return collections.Counter({(i, it): c for (k, i, it), c in w.calls.items() if k == "code"})


class Binding(unittest.TestCase):

    def test_a_new_run_fixes_only_the_declarations_of_its_corpus(self):
        rows = [declaration(), declaration("L-77", "shall go.", (0, 9), gid="G18")]
        w = rec.World({"L-50": TEXT})
        with Declared(rows), rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            fixed = json.loads((paths.RESULTS / "r" / deferred_gaps.FIXED).read_text())
            opts = json.loads((paths.RESULTS / "r" / "options.json").read_text())
            ids = [r["id"] for r in view().rows]
        self.assertEqual([deferred_gaps.identity(r) for r in fixed["rows"]], ["srcA:G17"])
        self.assertEqual(fixed["digest"], opts["semantic"]["deferred_gaps"])
        self.assertIn("srcA:G17", ids)
        self.assertNotIn("srcA:G18", ids)

    def test_a_declaration_that_no_longer_matches_stops_the_start(self):
        for name, row in (("digest", declaration(digest="ffffffffffffffff")), ("words", {**declaration(), "span": "shall halt."}),
                          ("occurrence", {**declaration(), "occurrence": "L-50@x:0-11"})):
            with self.subTest(mismatch=name):
                with Declared([row]), rec.Fixture(rec.World({"L-50": TEXT}), staged=True) as f:
                    with self.assertRaises(SystemExit) as ctx:
                        f.drive(max_iterations=1, label_repair=True, label_deferred=True)
                    self.assertFalse((paths.RESULTS / "r").exists())
                    self.assertFalse((paths.RESULTS / "r" / "state.json").exists())
                self.assertTrue("re-binding" in str(ctx.exception) or "not usable" in str(ctx.exception), str(ctx.exception))

    def test_a_missing_or_unreadable_list_is_an_error_never_empty(self):
        with Declared([]) as d:
            self.assertEqual(deferred_gaps.load(), [])
            d.file.write_text("{not json\n")
            with self.assertRaises(deferred_gaps.DeclarationError):
                deferred_gaps.load()
            d.file.unlink()
            with self.assertRaisesRegex(deferred_gaps.DeclarationError, "missing"):
                deferred_gaps.load()
            with rec.Fixture(rec.World({"L-50": TEXT}), staged=True) as f, self.assertRaisesRegex(SystemExit, "missing"):
                f.drive(max_iterations=1, label_repair=True, label_deferred=True)

    def test_a_resume_refuses_a_changed_list(self):
        with Declared([declaration()]) as d, rec.Fixture(rec.World({"L-50": TEXT})) as f:
            f.drive(max_iterations=1)
            d.write([declaration(), declaration(gid="G19", at=(12, 24))])
            with self.assertRaisesRegex(SystemExit, "deferred_gaps changed"):
                f.drive(max_iterations=2)

    def test_the_same_number_from_another_source_digest_or_law_is_never_mixed_up(self):
        other_law = "shall stop. shall merge."
        occ = lambda law, text: f"{law}@{review_phase.law_digest(text)}:0-11"
        with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "RESULTS", Path(t) / "results"):
            (Path(t) / "results").mkdir()
            ctx = (deferred_gaps.context_row(declaration()), deferred_gaps.context_row(declaration(at=(12, 24), run="srcB")),
                   deferred_gaps.context_row(declaration("L-52", other_law, run="srcC")))
            led = GapLedger(Path(t) / "gaps", context=ctx)
            led.dir.mkdir()
            for i in range(17):                                           # a live G17 of this ledger
                led.add({"kind": "atom", "span": f"w{i}", "law_refs": ["L-9"], "proposal": "p"}, "r", 1)
            gid = led.add({"kind": "atom", "span": "shall stop.", "law_refs": ["L-50"], "proposal": "p", "occurrence": occ("L-50", TEXT)}, "r", 1)
            stale = led.add({"kind": "atom", "span": "shall stop.", "law_refs": ["L-50"], "proposal": "p",
                             "occurrence": "L-50@ffffffffffffffff:0-11"}, "r", 1)
            again = led.add({"kind": "atom", "span": "shall stop.", "law_refs": ["L-50"], "proposal": "p", "occurrence": occ("L-50", TEXT)}, "r", 2)
            rows = {r["id"]: r for r in led.rows}
        self.assertEqual((gid, again), ("G18", "G18"))                    # never the live G17, filed once
        self.assertEqual(rows["G18"]["deferred_from"], {"source_run": "srcA", "source_id": "G17", "source_commit": COMMIT})
        self.assertNotIn("deferred_from", rows["G17"])
        self.assertNotIn("deferred_from", rows[stale])                   # another digest: a gap of its own
        self.assertNotIn("srcA:G17", rows)                                 # the live gap stands for it
        self.assertEqual((rows["srcB:G17"]["state"], rows["srcB:G17"]["occurrence"]), ("proposed", declaration(at=(12, 24))["occurrence"]))
        self.assertEqual((rows["srcC:G17"]["state"], rows["srcC:G17"]["law_refs"]), ("proposed", ["L-52"]))


class Rendered(Exception):
    """A reader stopped at its prompt, after it read the run's gap view."""


def readers(run, seen: dict) -> dict:
    """Each reader of the run's gap view, run as far as it reads it: the plan prompt, the loop's
    validator, the node repair, the candidate and the coding prompt. What each was given lands in `seen`."""
    law = corpus.Law("L-50", "L-50", TEXT, "s")
    n = Node(pair("L-50")[1])

    def capture(name):
        def validate(*a, **k):
            seen[name] = k.get("ledger_gaps")
            return []
        return validate

    def render(name, values, **_k):
        if name == "plan.md":
            seen["plan prompt"] = values["gaps"]
            raise Rendered
        return "prompt"

    def plan_prompt():
        with mock.patch.object(plan_phase.render, "render", render):
            try:
                REAL_PLAN_SESSION(run, [law], [], tag="probe")
            except Rendered:
                return

    def loop_validator():
        with mock.patch.object(validate_a, "validate", capture("loop validator")), \
                mock.patch.object(validate_a, "validate_concepts", lambda *a, **k: []):
            (run.iter / "probe").mkdir(parents=True, exist_ok=True)
            (run.iter / "probe" / "blueprint.jsonl").write_text("")
            validate_phase.validate_a_for_run(run, run.iter / "probe", {"L-50": law}, SimpleNamespace(), [], onto=ONTO)

    def node_repair():
        last = run.dir / "last"
        last.mkdir(exist_ok=True)

        def session_run(*_a, cwd=None, **_k):
            (Path(cwd) / "record.jsonl").write_text(json.dumps({k: v for k, v in n.raw.items() if k not in ("node_id", "law_refs", "segmentation")}))
        with mock.patch.object(plan_phase.session, "run", session_run), mock.patch.object(validate_a, "validate", capture("node repair")), \
                mock.patch.object(plan_phase.render, "render", lambda *a, **k: "prompt"), mock.patch.object(run.opts, "dry_run", False):
            REAL_NODE_REPAIR(run, n, ["r"], last, law, [], [], SimpleNamespace(data={"params": []}, params=[],
                                                                                 pending_aggregates=False), ONTO)

    def candidate():
        txn = SimpleNamespace(view=run, reading=SimpleNamespace())
        with mock.patch.object(validate_a, "validate", capture("candidate")), \
                mock.patch.object(candidate_phase, "Path", Path), mock.patch("harness.model.ontology.load", lambda p: ONTO):
            candidate_phase.validate_records(txn, [n], [])

    def coding_prompt():
        def sources(*_a, **_k):                              # read right after the gap view in the prompt's node block
            seen["coding prompt"] = True
            raise Rendered
        with mock.patch.object(code_phase, "task_context", lambda *a, **k: None), \
                mock.patch.object(code_phase, "_finished_verdict", lambda *a, **k: None), \
                mock.patch.object(code_phase, "_task_files", lambda *a, **k: None), mock.patch.object(code_phase, "_start", lambda *a: {}), \
                mock.patch.object(code_phase, "write_skeletons", lambda _n: ("", "")), mock.patch.object(code_phase, "gate_cli", lambda *a: ""), \
                mock.patch.object(code_phase.definitions_mod, "source_records", sources), mock.patch.object(run.opts, "dry_run", True):
            try:
                code_phase.run_code(run, n, SimpleNamespace())
            except Rendered:
                return

    def from_core(call):                                     # the Core text the fixture stands in for is not read
        def run_it():
            with mock.patch.object(plan_phase.surface, "formula_language", lambda: ""), \
                    mock.patch.object(plan_phase.surface, "concept_language", lambda: ""):
                call()
        return run_it
    return {name: from_core(call) for name, call in (("plan prompt", plan_prompt), ("loop validator", loop_validator), ("node repair", node_repair),
                                                     ("candidate", candidate), ("coding prompt", coding_prompt))}


class OneView(unittest.TestCase):
    """The rendered plan prompt and every validator entry are given the same pending row."""

    def test_the_plan_prompt_and_every_validator_entry_see_the_pending_row(self):
        w = rec.World({"L-50": TEXT})
        w.plans = {"L-50": []}
        seen: dict[str, list] = {}
        with Declared([declaration()]), rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            run = Run.load("r")
            run.iteration = 1
            expected = [r for r in view().rows if r["id"] == "srcA:G17"]
            for call in readers(run, seen).values():
                call()
        self.assertIn("srcA:G17", seen["plan prompt"])
        self.assertIn("carried over pending from run srcA (its G17, commit 0123456789ab)", seen["plan prompt"])
        self.assertTrue(seen["coding prompt"])
        self.assertEqual(len(expected), 1)
        for entry in ("loop validator", "node repair", "candidate"):
            with self.subTest(entry=entry):
                self.assertEqual([r for r in seen[entry] if r["id"] == "srcA:G17"], expected)


def tampered(how: str):
    """Change a run's fixed copy as `how` names: its rows emptied, a row altered, the list's text and
    rows changed together (with the copy's own digest restated), the file deleted, or made unreadable."""
    def edit(f: Path) -> None:
        if how == "missing":
            f.unlink()
            return
        if how == "corrupt":
            f.write_text("{not json\n")
            return
        d = json.loads(f.read_text())
        if how == "rows deleted":
            d["rows"] = []
        elif how == "row altered":
            d["rows"][0]["proposal"] = "`kin.speed` | read through the halt"
        elif how == "list and rows altered":
            row = dict(d["rows"][0], proposal="`kin.speed` | read through the halt")
            d["list"], d["rows"] = json.dumps(row) + "\n", [row]
            d["digest"] = hashlib.sha256(d["list"].encode()).hexdigest()[:24]
        f.write_text(json.dumps(d))
    return edit


TAMPERS = ("rows deleted", "row altered", "list and rows altered", "missing", "corrupt")


class FixedCopy(unittest.TestCase):
    """The copy a run fixed is read only whole: every reader of the run's gap view and every resume
    checks it against the list digest the run's saved inputs record and against its corpus, and a copy
    changed, missing or unreadable stops it, never read as no pending rows. Before the run's first
    snapshot (state.json) its initialisation is not complete: a launch then fixes the copy again."""

    def started(self, f) -> Path:
        f.drive(max_iterations=1)
        self.assertTrue((paths.RESULTS / "r" / "state.json").exists())
        return paths.RESULTS / "r" / deferred_gaps.FIXED

    def test_a_missing_input_digest_never_downgrades_an_initialised_run_to_legacy(self):
        for staged in (False, True):
            with self.subTest(staged=staged), Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT}), staged=staged) as f:
                launch = {"label_repair": True, "label_deferred": True} if staged else {}
                f.drive(max_iterations=1, **launch)
                rd = paths.RESULTS / "r"
                snap = rd / deferred_gaps.FIXED
                before = snap.read_bytes()
                if staged:
                    anchor = rd / "stages.jsonl"
                    rows = [json.loads(line) for line in anchor.read_text().splitlines() if line.strip()]
                    rows[-1]["semantic"].pop("deferred_gaps")
                    anchor.write_text("".join(json.dumps(row) + "\n" for row in rows))
                else:
                    anchor = rd / "options.json"
                    saved = json.loads(anchor.read_text())
                    saved["semantic"].pop("deferred_gaps")
                    anchor.write_text(json.dumps(saved))
                run = Run.load("r")
                run.iteration = 1
                entries = {"gap view": lambda: view().rows, **readers(run, {}),
                           "resume": lambda: f.drive(max_iterations=2, **launch)}
                for name, call in entries.items():
                    with self.subTest(reader=name), self.assertRaisesRegex(SystemExit, "deferred.gap"):
                        call()
                self.assertEqual(snap.read_bytes(), before)

    def test_a_stage_and_options_must_agree_on_the_deferred_gap_digest(self):
        with Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT}), staged=True) as f:
            f.drive(max_iterations=1, label_repair=True, label_deferred=True)
            options = paths.RESULTS / "r" / "options.json"
            saved = json.loads(options.read_text())
            saved["semantic"]["deferred_gaps"] = "another digest"
            options.write_text(json.dumps(saved))
            with self.assertRaisesRegex(SystemExit, "deferred.gap"):
                view().rows

    def test_a_legacy_run_with_no_deferred_gap_evidence_keeps_an_empty_view(self):
        with tempfile.TemporaryDirectory() as tmp, mock.patch.object(paths, "RESULTS", Path(tmp)):
            rd = Path(tmp) / "legacy"
            rd.mkdir()
            (rd / "options.json").write_text(json.dumps({"semantic": {"corpus": "old"}}))
            self.assertIsNone(deferred_gaps.recorded_digest(rd))
            self.assertEqual(deferred_gaps.fixed(SimpleNamespace(run_id="legacy")), [])

    def test_an_intact_copy_passes_its_check(self):
        with Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT})) as f:
            snap = self.started(f)
            digest = json.loads((paths.RESULTS / "r" / "options.json").read_text())["semantic"]["deferred_gaps"]
            self.assertEqual(deferred_gaps.fixed_refusal(snap.parent, digest, ["L-50"]), None)
            self.assertEqual(deferred_gaps.recorded_digest(snap.parent), digest)
            self.assertIn("hold other rows", deferred_gaps.fixed_refusal(snap.parent, digest, []))      # another corpus binds none

    def test_every_reader_and_the_resume_refuse_a_changed_missing_or_unreadable_copy(self):
        for how in TAMPERS:
            with self.subTest(copy=how), Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT})) as f:
                snap = self.started(f)
                tampered(how)(snap)
                left = snap.read_bytes() if snap.exists() else None
                run = Run.load("r")
                run.iteration = 1
                entries = {"gap view": lambda: view().rows, **readers(run, {}),
                           "resume": lambda: f.drive(max_iterations=2)}
                for name, call in entries.items():
                    with self.subTest(copy=how, entry=name):
                        with self.assertRaisesRegex(SystemExit, "fixed deferred gap declarations"):
                            call()
                self.assertEqual(snap.read_bytes() if snap.exists() else None, left)     # nothing rewrote it

    def test_the_operator_audit_now_refuses(self):
        """The audit's two cases: the rows emptied under their digest, then the copy deleted from a run with state.json."""
        with Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT})) as f:
            snap = self.started(f)
            digest = json.loads((paths.RESULTS / "r" / "options.json").read_text())["semantic"]["deferred_gaps"]
            rejected = lambda: validate_a.check_gap_resolutions(Node(dropping()), TEXT, GapLedger.for_run(paths.GAPS_DIR, Run.load("r")).rows)
            self.assertEqual(len(rejected()), 1)
            original = snap.read_bytes()
            altered = json.loads(original)
            altered["rows"] = []
            snap.write_text(json.dumps(altered))
            self.assertRaises(SystemExit, rejected)
            self.assertRaisesRegex(SystemExit, "cannot be resumed", f.drive, max_iterations=2)
            self.assertIsNotNone(deferred_gaps.fixed_refusal(snap.parent, digest, ["L-50"]))
            snap.write_bytes(original)
            snap.unlink()
            self.assertRaises(SystemExit, rejected)
            self.assertRaisesRegex(SystemExit, "cannot be resumed", f.drive, max_iterations=3)
            self.assertFalse(snap.exists())
            snap.write_bytes(original)                                    # the copy restored, the run resumes
            self.assertNotIn("crash", f.drive(max_iterations=2))
            self.assertEqual(len(rejected()), 1)

    def test_a_start_cut_short_before_its_first_snapshot_fixes_the_copy_again(self):
        """No state.json yet: initialisation is not complete, so a copy missing, changed or unreadable is
        fixed again from the list the saved inputs record, and the run ends as the uninterrupted one."""
        with Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT})) as f:
            f.drive(max_iterations=1)
            ref = json.loads((paths.RESULTS / "r" / deferred_gaps.FIXED).read_text())
        for how in (None,) + TAMPERS:
            with self.subTest(copy=how), Declared([declaration()]), rec.Fixture(rec.World({"L-50": TEXT})) as f:
                class Cut(Exception):
                    pass
                real = deferred_gaps.fix

                def cut(run_dir, rows, digest):
                    if how is not None:
                        real(run_dir, rows, digest)
                        tampered(how)(Path(run_dir) / deferred_gaps.FIXED)
                    raise Cut
                with mock.patch.object(deferred_gaps, "fix", cut), self.assertRaises(Cut):
                    f.drive(max_iterations=1)
                rd = paths.RESULTS / "r"
                self.assertTrue((rd / "options.json").exists())
                self.assertFalse((rd / "state.json").exists())
                self.assertRaises(SystemExit, view)                         # a reader never reads it before it is fixed whole
                self.assertNotIn("crash", f.drive(max_iterations=1))
                self.assertEqual(json.loads((rd / deferred_gaps.FIXED).read_text()), ref)
                self.assertIn("srcA:G17", [r["id"] for r in view().rows])


def dropping(**over) -> dict:
    """L-50's o1 carrying "shall stop." without the gap: an observable `purpose` reading in its place."""
    o1 = pair("L-50")[0]
    o1.pop("gaps")
    o1["narrowings"] = [{"span": "s1", "kind": "observable_reading", "category": "purpose", "carrier": "kin.speed",
                         "why": "an organisation, read through conduct"}]
    o1.update(over)
    return o1


class Withdrawal(unittest.TestCase):
    """`check_gap_resolutions` on the rows the run's view gives."""

    def rows(self) -> list[dict]:
        with tempfile.TemporaryDirectory() as t:
            return GapLedger(Path(t), context=(deferred_gaps.context_row(declaration()),)).rows

    def errs(self, raw: dict, law_text: str = TEXT) -> list[str]:
        return validate_a.check_gap_resolutions(Node(raw), law_text, self.rows())

    def test_a_reading_in_place_of_the_pending_gap_is_refused(self):
        errs = self.errs(dropping())
        self.assertTrue(any("srcA:G17" in e and "has not decided" in e for e in errs), errs)
        own = dropping(gap_resolutions=[{"gap": "srcA:G17", "span": "s1", "basis": "ordinary following resolves it"}])
        self.assertTrue(any("srcA:G17" in e and "not decided" in e for e in self.errs(own)), self.errs(own))

    def test_a_record_that_keeps_the_gap_passes(self):
        self.assertEqual(self.errs(pair("L-50")[0]), [])

    def test_an_unrelated_mixed_carrier_reading_is_not_affected(self):
        o2 = pair("L-50")[1]                       # the sibling's words, read with a mixed carrier
        o2["narrowings"] = [{"span": "s2", "kind": "observable_reading", "category": "purpose", "carrier": "kin.speed", "why": "w"}]
        self.assertEqual(self.errs(o2), [])
        other = dropping(node_id="L_53_o1", law_refs=["L-53"])
        self.assertEqual(validate_a.check_gap_resolutions(Node(other), TEXT, self.rows()), [])


class Filing(rec.Interruptions, unittest.TestCase):
    """A record that keeps the declared gap files a live gap with its source; R1 and D1 hold on it."""

    def test_a_kept_gap_files_a_live_gap_that_blocks_and_that_a_dependent_waits_on(self):
        w = kept()
        with Declared([declaration()]), rec.Fixture(w, **kept.opts) as f:
            f.drive()
            st = f.state()
            rows = live()
            shown = {r["id"]: r for r in view().rows}
        self.assertEqual([(r["id"], r["occurrence"], r["deferred_from"]) for r in rows],
                         [("G1", declaration()["occurrence"], {"source_run": "srcA", "source_id": "G17", "source_commit": COMMIT})])
        self.assertNotIn("srcA:G17", shown)
        led = laws(st)
        self.assertEqual((led["L-50"]["state"], led["L-50"]["gaps"], led["L-50"]["own_gaps"]), ("blocked", ["G1"], ["G1"]))
        self.assertEqual((led["L-51"]["state"], led["L-51"]["gaps"], led["L-51"]["own_gaps"], led["L-51"]["waits_on"], led["L-51"]["attempts"]),
                         ("blocked", ["G1"], [], ["L-50"], 0))
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_50_o2"])
        self.assertEqual(coded(w), collections.Counter({("L_50_o2", 1): 1}))
        self.assertEqual(planned_in(w, "L-51"), [1])

    def test_every_stop_ends_as_the_uninterrupted_run_without_a_second_import_or_filing(self):
        with Declared([declaration()]):
            ref, _n = self.interrupt_everywhere(kept, never=[("code", "L_50_o1", 1), ("code", "L_51", 1)])
        self.assertEqual(len(ref["gaps"]), 1)
        self.assertEqual(json.loads(ref["gaps"][0])["deferred_from"]["source_id"], "G17")


class Lifecycle(unittest.TestCase):
    """After the live gap's decision the declaration is withdrawn by the operator; until then no new round starts."""

    def filed(self, f, d: Declared) -> None:
        f.drive()
        self.assertEqual([r["id"] for r in live()], ["G1"])

    def starts(self, f) -> dict[str, str]:
        """Each entry that starts a new gap round, with what it raised (empty when it started)."""
        out = {}
        for name, call in (("new run", lambda: f.drive(run_id="r2", max_iterations=1)),
                           ("init --fresh", lambda: Cli().init(fresh=True, reading=str(f.root / "reading.json"))),
                           ("gap archive", lambda: Cli().gap("archive"))):
            before = (paths.GAPS_DIR / "proposals.jsonl").read_text() if (paths.GAPS_DIR / "proposals.jsonl").exists() else ""
            try:
                with mock.patch.object(owner, "acquire_for_command", lambda *_a: None), \
                        mock.patch("harness.__main__.write_template", lambda *_a: None), \
                        mock.patch("harness.__main__.snapshot_library", lambda *_a: []), \
                        mock.patch("harness.__main__.archive_proposals", lambda *_a: {}):
                    call()
                out[name] = ""
            except (SystemExit, OpenGaps) as e:
                out[name] = str(e)
            after = (paths.GAPS_DIR / "proposals.jsonl").read_text() if (paths.GAPS_DIR / "proposals.jsonl").exists() else ""
            if out[name]:
                self.assertEqual(before, after, f"{name} moved the live ledger before it refused")
        return out

    def test_a_stale_declaration_blocks_every_new_round_after_rejected_or_retired(self):
        for state, extra in (("rejected", {"resolved_by": "particular"}), ("retired", {"retired_by": "the atom catalogue update"})):
            with self.subTest(state=state), Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
                self.filed(f, d)
                GapLedger(paths.GAPS_DIR).decide("G1", state, "the words are carried", **extra)
                got = self.starts(f)
                for name, why in got.items():
                    self.assertIn("srcA:G17", why, name)
                    self.assertIn("G1", why, name)
                self.assertFalse((paths.RESULTS / "r2" / "state.json").exists())

    def test_accepted_is_not_resolved(self):
        with Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "accepted", "an atom will carry it")
            got = self.starts(f)
            rows = {r["id"]: r for r in view().rows}
        for name, why in got.items():
            self.assertIn("G1 (accepted)", why, name)
            self.assertNotIn("still declares", why, name)
        self.assertEqual(rows["G1"]["state"], "accepted")
        self.assertNotIn("srcA:G17", rows)
        self.assertEqual(deferred_gaps.conflicts(live(), [declaration()]), [])

    def test_a_decided_live_gap_never_falls_back_to_pending(self):
        with Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read through the halt", resolved_by="particular")
            rows = {r["id"]: r for r in view().rows}
            self.assertEqual((rows["G1"]["state"], "srcA:G17" in rows), ("rejected", False))
            self.assertIn("G1", GapLedger(paths.GAPS_DIR).decided())
            d.write([])                                               # the next baseline withdraws it; the round is archived
            self.assertEqual(GapLedger(paths.GAPS_DIR).start_round(paths.RESULTS), [("G1", "r")])
            rows = {r["id"]: r for r in view().rows}                  # the run fixed the declaration; its archive stands for it
        self.assertNotIn("srcA:G17", rows)
        self.assertNotIn("G1", rows)

    def test_once_withdrawn_archive_and_a_fresh_start_work_and_nothing_pending_comes_back(self):
        with Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "retired", "an atom carries it", retired_by="the atom catalogue update")
            d.write([])
            got = self.starts(f)
            fresh = json.loads((paths.RESULTS / "r2" / deferred_gaps.FIXED).read_text())
            rows = view("r2").rows
        self.assertEqual(got["new run"], "")
        self.assertEqual(fresh["rows"], [])
        self.assertFalse([r for r in rows if r.get("deferred") or r.get("deferred_from")])     # its own plan's gap is a new one

    def test_the_original_run_still_resumes_on_its_unchanged_inputs(self):
        w = kept()
        w.plans = {("L-50", 1): list(pair("L-50")), ("L-51", 1): w.plans["L-51"],
                   ("L-50", 2): [dict(pair("L-50")[0], gaps=[], gap_resolutions=[{"gap": "G1", "span": "s1", "basis": "read through the halt"}])],
                   ("L-51", 2): w.plans["L-51"]}
        with Declared([declaration()]) as d, rec.Fixture(w, **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read through the halt", resolved_by="particular")
            statuses = f.drive(max_iterations=3)
            st = f.state()
            rows = {r["id"]: r for r in view().rows}
        self.assertNotIn("crash", statuses)
        self.assertEqual(laws(st)["L-50"]["state"], "accepted")
        self.assertEqual(laws(st)["L-51"]["state"], "accepted")
        self.assertEqual([r["id"] for r in live_rows_of(st)], ["G1"])
        self.assertNotIn("srcA:G17", rows)

    def test_a_stop_after_the_decision_and_before_the_withdrawal_keeps_the_conflict_visible(self):
        from scripts.diagnostics.doctor import Doctor
        with Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read through the halt", resolved_by="particular")
            with self.assertRaises(OpenGaps):
                GapLedger(paths.GAPS_DIR).start_round(paths.RESULTS)
            (f.root / "config").mkdir(exist_ok=True)
            (f.root / "config" / "deferred_gaps.jsonl").write_text(d.file.read_text())
            res = Doctor(f.root, paths.LIBRARY).deferred_gap_declarations()      # a later process, from the files alone
            again = deferred_gaps.conflicts(GapLedger(paths.GAPS_DIR).live_rows(), deferred_gaps.load())
        self.assertEqual(res.status, "review")
        self.assertTrue(any("G1 (rejected)" in s and "srcA:G17" in s for s in res.sources), res.sources)
        self.assertEqual(len(again), 1)

    def test_a_same_numbered_declaration_of_another_source_is_neither_matched_nor_withdrawn(self):
        other = declaration("L-50", TEXT, (12, 24), run="srcB", gid="G17")
        with Declared([declaration(), other]) as d, rec.Fixture(kept(), **kept.opts) as f:
            self.filed(f, d)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read through the halt", resolved_by="particular")
            self.assertEqual(len(deferred_gaps.conflicts(live(), deferred_gaps.load())), 1)
            d.write([declaration()])                                   # withdrawing the other source's G17 settles nothing
            with self.assertRaisesRegex(OpenGaps, "srcA:G17"):
                GapLedger(paths.GAPS_DIR).start_round(paths.RESULTS)
            d.write([other])                                           # withdrawing this one leaves the other declared
            self.assertEqual(deferred_gaps.conflicts(live(), deferred_gaps.load()), [])
            self.assertEqual(GapLedger(paths.GAPS_DIR).start_round(paths.RESULTS), [("G1", "r")])
            self.assertEqual([deferred_gaps.identity(r) for r in deferred_gaps.load()], ["srcB:G17"])
            shown = {r["id"] for r in view().rows}
        self.assertIn("srcB:G17", shown)


def live_rows_of(st: dict) -> list[dict]:
    return [json.loads(g) for g in st["gaps"]]


class OperatorCommands(unittest.TestCase):

    def test_gap_decide_refuses_a_carried_over_id_and_names_its_live_gap(self):
        with Declared([declaration()]) as d, rec.Fixture(kept(), **kept.opts) as f:
            with self.assertRaisesRegex(SystemExit, "no run has filed it yet"):
                Cli().gap("decide", "srcA:G17", state="rejected", decision="d", resolved_by="particular")
            f.drive()
            with self.assertRaisesRegex(SystemExit, "decide its live gap G1"):
                Cli().gap("decide", "srcA:G17", state="rejected", decision="d", resolved_by="particular")
            self.assertEqual(live()[0]["state"], "proposed")

    def test_a_training_run_refuses_a_declaration_of_a_held_out_law(self):
        with Declared([declaration()]), rec.Fixture(kept(), **kept.opts) as f, \
                mock.patch.object(loop, "held_out_law_ids", lambda: {"L-50"}):
            with self.assertRaisesRegex(SystemExit, r"srcA:G17 \(declared\)"):
                f.drive()


class Export(unittest.TestCase):
    """`scripts/export_deferred_gaps.py` on a ledger read through `git show`."""

    def run_export(self, proposals: list[dict], decisions: list[dict], ids: list[str], texts: dict[str, str]):
        from scripts import export_deferred_gaps as ex
        files = {"proposals.jsonl": proposals, "decisions.jsonl": decisions}

        def git(*args):
            if args[0] == "rev-parse":
                return COMMIT + "\n"
            name = args[1].rsplit("/", 1)[-1]
            return "".join(json.dumps(r) + "\n" for r in files[name])
        with mock.patch.object(ex, "git", git):
            return ex.export("HEAD", "srcA", ids, texts)

    def source(self, gid="G17", law="L-50", at=STOP, text=TEXT, run="srcA") -> dict:
        d = declaration(law, text, at, gid=gid)
        return {"id": gid, "kind": "atom", "span": d["span"], "law_refs": [law], "proposal": d["proposal"],
                "proposed_in": f"{run}/iter-001", "occurrence": d["occurrence"]}

    def test_it_exports_a_matching_pending_gap(self):
        rows, bad = self.run_export([self.source()], [], ["G17"], {"L-50": TEXT})
        self.assertEqual(bad, [])
        self.assertEqual(rows, [declaration()])

    def test_it_refuses_every_mismatch(self):
        cases = {
            "not in the corpus": ([self.source()], [], ["G17"], {}),
            "digest": ([self.source()], [], ["G17"], {"L-50": TEXT + " more"}),
            "words": ([dict(self.source(), span="shall halt.")], [], ["G17"], {"L-50": TEXT}),
            "already decided": ([self.source()], [{"id": "G17", "state": "rejected"}], ["G17"], {"L-50": TEXT}),
            "no gap of the ledger": ([self.source()], [], ["G99"], {"L-50": TEXT}),
            "not by run": ([self.source(run="other")], [], ["G17"], {"L-50": TEXT}),
        }
        for words, args in cases.items():
            with self.subTest(case=words):
                rows, bad = self.run_export(*args)
                self.assertTrue(bad and any(words in b or (words == "words" and "read" in b) for b in bad), bad)

    def test_a_refusal_writes_nothing(self):
        from scripts import export_deferred_gaps as ex
        with tempfile.TemporaryDirectory() as t:
            out = Path(t) / "deferred_gaps.jsonl"
            out.write_text("kept\n")
            with mock.patch.object(ex, "export", lambda *a, **k: ([], ["G99: no gap"])), mock.patch.object(ex.corpus, "load_laws", lambda p: []):
                self.assertEqual(ex.main(["--commit", "x", "--run", "srcA", "--ids", "G99", "--out", str(out)]), 1)
            self.assertEqual(out.read_text(), "kept\n")

    def test_the_repository_list_reads_whole_and_matches_the_training_corpus(self):
        rows = deferred_gaps.load()
        texts = {l.id: l.text for l in corpus.load_laws(paths.REPO / "laws" / "example" / "train" / "laws.jsonl")}
        self.assertEqual(deferred_gaps.bind(rows, texts), rows)
        for r in rows:
            self.assertEqual(deferred_gaps.binding_defects(r, texts.get(r["law"])), [])


if __name__ == "__main__":
    unittest.main()
