"""The label-repair path end to end, through the real loop: a run launched with `--label_repair` and
the training recordings of a synthetic dataset plans and codes its laws, checks each on a candidate
library (`label_route`), and repairs each law awaiting its label repair (`run_repairs`): the
repair session's answer re-asked on its defects, applied to a candidate, gated, checked again with
the label hook on every law whose rules read the changed file and with the concept review on a
changed concept, then committed or rolled back; a law with its attempts or the run's repair budget
spent is held or waits; a stop at any point of the repair transaction resumes to the same end, with
no paid session asked twice for the same inputs and no attempt counted twice.

The runs are made as before stages existed (`test_recovery.legacy_run`): a new run with a stage record
starts in its generation stage and reaches its labels only through a review stage, which does not
exist yet, so the staged path cannot reach a label check today. The loop, the ledgers, the snapshot,
the candidate transaction, its label hook and concept-review hook, the label check, its scoring and
its evidence, and the dataset are the real ones; the sessions (plan, coder, label repair), the gates,
the concept review and the library's build are scripted (`test_recovery.Fixture`). The monitor is a
stand-in that reads each recording's verdict from the dataset (`fake.json`, what the coded rule
computes) unless a `-- VERDICT <rule> <recording> <verdict> [reasons]` line in a rule or concept file
of the library it was built for says otherwise, so a repair's Lean change changes the verdicts the
label check sees."""
import collections
import difflib
import json
import re
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import render, session
from harness.model import nodeid
from harness.phases import candidate as cand
from harness.phases import label_check
from harness.phases import label_repair as lr
from harness.phases import review as review_phase
from harness.store import jsonl, owner, paths
from scripts.tests.test_label_check import FAKE_EXPLAIN, make_dataset, write_exe
from scripts.tests.test_recovery import Crash, Fixture, World, _iteration_of, concept, node

#: The stand-in monitor of one library (`{lib}`): the recording's verdicts from `fake.json`, each
#: overridden by the library's `-- VERDICT` lines for the rule and the recording.
MONITOR = """#!{py}
import json, pathlib, sys
LIB = pathlib.Path({lib!r})
args = sys.argv[1:]
trace = args[-1]
rule = args[args.index('--rules') + 1]
rid = pathlib.Path(trace).parent.name
spec = json.load(open(pathlib.Path(trace).parent / 'fake.json'))
if spec.get('fail') == 'crash':
    sys.exit(2)
for d in ('TrafficSpec/Rules', 'TrafficSpec/Concepts'):
    for f in sorted((LIB / d).rglob('*.lean')):
        for line in f.read_text().splitlines():
            w = line.split()
            if len(w) >= 5 and w[:2] == ['--', 'VERDICT'] and w[2] == rule and w[3] == rid:
                spec[rule] = [[w[4], {{'x': 1}}, w[5:]]]
print(json.dumps({{'kind': 'source', 'instants': 1}}))
segs = []
if rule in spec:
    print(json.dumps({{'kind': 'rule', 'rule': rule, 'support': 'supported', 'absent': [], 'abstractions': []}}))
    ts = [x['t'] for x in json.load(open(trace))['scenes']]
    for v, b, *more in spec[rule]:
        why = more[0] if more else []
        print(json.dumps({{'kind': 'grounding', 'rule': rule, 'grounding': b, 'episode': {{'verdict': v, 'reasons': why}}}}))
        segs.append({{'kind': 'segments', 'rule': rule, 'grounding': b,
                      'segments': [{{'from': ts[0], 'to': ts[-1], 'verdict': v, 'reasons': why}}]}})
for s in segs:
    print(json.dumps(s))
print(json.dumps({{'kind': 'subject', 'ego': spec.get('ego', [1]), 'binders': {{rule: 'x'}}}}))
"""

C = "drv.motion.slow"
CPATH = nodeid.concept_path(C)
#: The one reason whose tag alone points at the library (a rule's own division by zero).
LIBRARY_REASON = "division_by_zero:div"
#: A candidate's id, as it appears in paths and states.
CAND_ID = re.compile(r"\d{8}-\d{6}-[0-9a-f]{6}")


def v(rule: str, verdict: str, *reasons: str) -> dict:
    return {rule: [[verdict, {"x": 1}, list(reasons)]]}


def verdict_lines(rel: str, *lines: str):
    """An answer: a `lean.diff` adding `-- VERDICT` lines to the library file `rel`, written against
    the file as the candidate holds it."""
    def answer(lib: Path) -> dict[str, str]:
        old = (lib / rel).read_text()
        new = old + "".join(f"-- VERDICT {x}\n" for x in lines)
        return {"lean.diff": "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), rel, rel))}
    return answer


def comment(rel: str, text: str = "a comment"):
    """An answer whose Lean change changes no verdict."""
    def answer(lib: Path) -> dict[str, str]:
        old = (lib / rel).read_text()
        new = old + f"-- {text}\n"
        return {"lean.diff": "".join(difflib.unified_diff(old.splitlines(True), new.splitlines(True), rel, rel))}
    return answer


def files(**out: str):
    return lambda lib: dict(out)


class LabelFixture(Fixture):
    """`test_recovery.Fixture` with a synthetic training dataset, the stand-in monitor, and the label
    repair sessions and the concept reviews inside a candidate scripted:
    - `answers[(law, repair dir, label)]`: what that repair session writes (a function of the
      candidate's library); a call with no answer writes nothing;
    - `reviews[cid]`: the outcomes of that concept's reviews inside candidates, in order
      (`accepted`, `returned`, `outage`); `accepted` once they are spent.
    Every repair session ticks the world before it answers (a stop there is a session that died) and
    after its completion record (a stop there is a process that died after a paid session); the
    commit point, the library pointer and each replacement of a commit tick too."""

    def __init__(self, world: World, recs, answers=None, reviews=None, **opt):
        super().__init__(world, **opt)
        self.ds = make_dataset(self.tmp / "ds", recs)
        self.explain = write_exe(self.tmp / "explain", FAKE_EXPLAIN)
        self.opt.setdefault("label_repair", True)
        self.opt.setdefault("label_dataset", str(self.ds.path))
        self.answers = answers or {}
        self.reviews = {k: list(x) for k, x in (reviews or {}).items()}
        self.repair_calls: list[tuple[str, str, str]] = []           # (law, repair dir, label), each launch of a session
        self.completed = collections.Counter()                        # (law, repair dir, label) → completion records written
        self.prompts: list[dict] = []                                 # the parts of every repair prompt, in order
        self.candidate_reviews: list[str] = []
        self.opened: list[Path] = []                                  # every candidate's directory, in the order opened

    def __enter__(self):
        super().__enter__()
        w, s = self.w, self.stack
        coder = session.run

        def repair_session(prompt, cwd=None, out_dir=None, **k):
            d = Path(cwd)
            if "label_repair" not in d.parts:
                return coder(prompt, cwd=cwd, out_dir=out_dir, **k)
            key = (d.parent.name, d.name, k.get("label", "session"))
            self.repair_calls.append(key)
            w.call("label_repair", "/".join(key), _iteration_of(d))
            rules = next(a for a in k["allow"] if a.startswith("Read(") and a.endswith("/TrafficSpec/Rules/**)"))
            lib = Path(rules[len("Read("):-len("/TrafficSpec/Rules/**)")])
            for name, text in (self.answers[key](lib) if key in self.answers else {}).items():
                (d / name).write_text(text)
            (d / f"{key[2]}_result.json").write_text(json.dumps({"result": {}, "code": 0, "cost_usd": 1.0}))
            self.completed[key] += 1
            w.tick("label_repair_done", "/".join(key))
            return {}
        s.enter_context(mock.patch.object(session, "run", repair_session))

        def build_tools(lib: Path):
            w.tick("label_build")
            d = self.tmp / "tools" / f"{len(list((self.tmp / 'tools').glob('*'))) if (self.tmp / 'tools').exists() else 0}"
            d.mkdir(parents=True, exist_ok=True)
            write_exe(d / "monitor", MONITOR.replace("{lib!r}", repr(str(lib))))
            return d / "monitor", self.explain
        s.enter_context(mock.patch.object(label_check, "build_tools", build_tools))
        s.enter_context(mock.patch.object(cand, "validate_records", lambda txn, nodes, concepts: []))
        for name in ("formula_language", "concept_language"):
            s.enter_context(mock.patch.object(lr.surface, name, lambda: ""))
        s.enter_context(mock.patch.object(lr.surface, "concepts_table", lambda *a, **k: ""))
        real_render = render.render

        def render_(template, parts=None, *a, **k):
            if template == "node_repair.md":
                self.prompts.append(dict(parts))
            return real_render(template, parts, *a, **k)
        s.enter_context(mock.patch.object(render, "render", render_))
        real_review = review_phase.review_concept

        def review_concept(run, c, extras, out_dir):
            if "candidate" not in Path(out_dir).parts:
                return real_review(run, c, extras, out_dir)
            o = self.reviews.get(c.id, []).pop(0) if self.reviews.get(c.id) else "accepted"
            self.candidate_reviews.append(c.id)
            w.call("candidate_review", c.id, run.iteration)
            if o == "outage":
                raise session.SessionUnavailable("scripted review outage")
            if o == "returned":
                return review_phase.ReviewOutcome("returned", reasons=[f"scripted upheld on {c.id}"])
            return review_phase.ReviewOutcome("accepted")
        s.enter_context(mock.patch.object(review_phase, "review_concept", review_concept))
        real_write = jsonl.write_atomic

        def write_atomic(path, text):
            real_write(path, text)
            if Path(path).name == cand.JOURNAL:                       # the commit point, then the journal applied
                w.tick("write", cand.JOURNAL, json.loads(text).get("status"))
            elif Path(path).name == owner.PENDING_FILE:
                w.tick("write", owner.PENDING_FILE)
        s.enter_context(mock.patch.object(jsonl, "write_atomic", write_atomic))
        from harness.phases import integrate
        scripted_contexts = integrate.recheck_contexts

        def recheck_contexts(run, reading, base, laws, only=None):        # the candidate's context check names the records it rechecks
            return scripted_contexts(run, reading, base, laws)
        s.enter_context(mock.patch.object(integrate, "recheck_contexts", recheck_contexts))
        real_open = cand.Candidate.open.__func__

        def open_(cls, run, **k):
            txn = real_open(cls, run, **k)
            self.opened.append(txn.area)
            return txn
        s.enter_context(mock.patch.object(cand.Candidate, "open", classmethod(open_)))
        real_replace = cand._replace

        def replace(src, dst):
            if w.dead:
                raise Crash("dead")
            real_replace(src, dst)
            w.tick("replace", Path(dst).name)
        s.enter_context(mock.patch.object(cand, "_replace", replace))
        return self

    def drive(self, launches: int = 4, **over) -> list[str]:
        """`Fixture.drive`, each launch a new process: no candidate of an earlier launch is open."""
        statuses = []
        for _ in range(launches):
            cand._OPEN.clear()
            self.w.launch += 1
            try:
                res = loop.run_loop(self.options(**over))
            except Crash:
                self.w.dead, self.w.crash_at = False, None
                statuses.append("crash")
                continue
            statuses.append(res["status"])
            if res["status"] not in ("infrastructure_failure",):
                break
        cand._OPEN.clear()
        return statuses

    # -- what the run left
    @property
    def rd(self) -> Path:
        return paths.RESULTS / "r"

    def snap(self) -> dict:
        return json.loads((self.rd / "state.json").read_text())

    def labels(self) -> dict:
        return self.snap().get("label_states") or {}

    def ledger(self) -> dict:
        return {e["law"]: e for e in self.snap()["ledger"]}

    def library(self) -> dict[str, str]:
        return {str(p.relative_to(paths.LIBRARY)): p.read_text() for p in sorted(paths.LIBRARY.rglob("*.lean")) if paths.CORE not in p.parents}

    def to_user(self) -> str:
        f = self.rd / "TO_USER.md"
        return f.read_text() if f.exists() else ""

    def checks(self) -> list[dict]:
        """Every check result of every candidate the repairs opened, in the order opened."""
        out = []
        for a in self.opened:
            f = a / "checks.jsonl"
            if f.exists():
                out += [{**json.loads(l), "candidate": a.name} for l in f.read_text().splitlines() if l.strip()]
        return out

    def statuses(self) -> list[tuple[str, dict]]:
        """(id, status record) of each candidate that changed the library, in the order opened (a label
        check's candidate changes nothing and is closed)."""
        out = [(a.name, json.loads((a / "status.json").read_text())) for a in self.opened if (a / "status.json").exists()]
        return [(i, s) for i, s in out if s["status"] != "closed"]

    def used(self) -> int:
        return sum(int(s.get("repairs", 0)) for s in self.labels().values())

    def settled(self) -> dict:
        """What a stop and a resume must leave as an uninterrupted run leaves it: the ledger, the
        records, the label states (a candidate's id named, not its value), the library's files and
        the filed requests; the counts of completed repair sessions."""
        st = self.snap()
        out = {k: st.get(k) for k in ("ledger", "accepted_nodes", "accepted_concepts", "fenced", "label_states")}
        out["library"] = self.library()
        for name in (lr.OUTER_FILE, lr.OPERATOR_FILE):
            out[name] = (self.rd / name).read_text() if (self.rd / name).exists() else ""
        gaps = paths.GAPS_DIR / "proposals.jsonl"
        out["gaps"] = sorted(json.dumps({k: x for k, x in json.loads(l).items() if k not in ("proposed_at", "time")}, sort_keys=True)
                             for l in gaps.read_text().splitlines() if l.strip()) if gaps.exists() else []
        out["completed"] = sorted(self.completed.items())
        text = CAND_ID.sub("<candidate>", json.dumps(out, sort_keys=True).replace(str(self.tmp), "<tmp>"))
        return json.loads(re.sub(r'"check_sha": "[0-9a-f]+"', '"check_sha": "<sha>"', text))


RULE5, RULE6, RULE7 = nodeid.rule_path("L_5"), nodeid.rule_path("L_6"), nodeid.rule_path("L_7")


def two_laws() -> World:
    """L-1's node agrees with its labels; L-5's disagrees with one."""
    w = World({"L-1": "shall slow.", "L-5": "shall stop."})
    w.plans = {"L-1": [node("L_1", "shall slow.", "L-1")], "L-5": [node("L_5", "shall stop.", "L-5")]}
    return w


TWO_RECS = [("r1a", "L-1", "compliant", False, v("L_1", "compliant")),
            ("r5a", "L-5", "compliant", False, v("L_5", "violated")),        # the mismatch
            ("r5b", "L-5", "violation", False, v("L_5", "violated")),        # a match
            ("r5j", "L-5", "compliant", True, v("L_5", "violated"))]         # a judgment call the rule disagrees with


def shared_concept() -> World:
    """L-5's and L-6's nodes both call the concept C; L-1's calls nothing."""
    w = World({"L-1": "shall slow.", "L-5": "shall stop.", "L-6": "shall yield."})
    w.plans = {"L-1": [node("L_1", "shall slow.", "L-1")],
               "L-5": [concept(C, users=["L_5", "L_6"]), node("L_5", "shall stop.", "L-5", derived=[C])],
               "L-6": [node("L_6", "shall yield.", "L-6", derived=[C])]}
    return w


SHARED_RECS = TWO_RECS + [("r6a", "L-6", "compliant", False, v("L_6", "compliant")),
                          ("r6b", "L-6", "violation", False, v("L_6", "violated"))]
FIX5 = verdict_lines(RULE5, "L_5 r5a compliant")
FIX5_IN_C = verdict_lines(CPATH, "L_5 r5a compliant")
BREAK6_IN_C = verdict_lines(CPATH, "L_5 r5a compliant", "L_6 r6a violated")


class LabelCheck(unittest.TestCase):
    """1. The label check on the synthetic dataset, inside the loop."""

    def test_a_plain_label_mismatch_is_a_mismatch_its_evidence_carries_no_trace_and_judgment_calls_stay_out(self):
        with LabelFixture(two_laws(), TWO_RECS) as f:
            self.assertEqual(f.drive(1, label_repair_attempts=1), ["complete"])
            check = json.loads((f.rd / "iter-001/label/laws/L-5.json").read_text())
            self.assertEqual(check["outcome"], "mismatch")
            scored = {s["recording_id"]: (s["status"], s["judgment_call"]) for s in check["scored"]}
            self.assertEqual(scored["r5a"], ("mismatch", False))
            self.assertEqual(scored["r5b"], ("match", False))
            self.assertTrue(scored["r5j"][1])
            evidence = (f.rd / "iter-001/label/evidence/L-5.md").read_text()
            self.assertIn("## Label mismatches", evidence)
            self.assertIn("### Recording r5a: label compliant, the law's verdict violated, status mismatch", evidence)
            self.assertIn("Fixed comparison set: 2 labelled recording(s)", evidence)
            self.assertNotIn("r5j", evidence)                                    # the judgment call is not evidence
            self.assertNotIn("r5b", evidence.split("Statuses:")[1])              # nor a match
            for word in ("scenes", "recordings/", ".json", ".mp4", "video", "mapping", str(f.ds.path)):
                self.assertNotIn(word, evidence)
            # what the repair session was shown is that evidence, and its prompt carries no trace either
            self.assertEqual(len(f.prompts), 1)
            self.assertTrue(f.prompts[0]["evidence"].startswith(evidence))
            self.assertIn("1 of 2 plain label(s) match", f.prompts[0]["verdict"])
            self.assertNotIn("scenes", "".join(x for x in f.prompts[0].values() if isinstance(x, str)))
            self.assertEqual(f.labels()["L-1"]["outcome"], "aligned")
            self.assertEqual(f.ledger()["L-1"]["state"], "accepted")
            jc = json.loads((f.rd / "iter-001/label/judgment_calls/L-5.json").read_text())
            self.assertEqual([r.get("recording_id") for r in jc], ["r5j"])


class Repair(unittest.TestCase):
    """2. The repair session through the candidate: re-ask, gate, label hook, commit or rollback."""

    def test_a_repair_that_fixes_the_mismatch_is_kept_after_one_reask(self):
        answers = {("L-5", "repair-01", "session"): files(**{"record.jsonl": "not JSON"}),
                   ("L-5", "repair-01", "session_again"): FIX5}
        with LabelFixture(two_laws(), TWO_RECS, answers) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual(f.repair_calls, [("L-5", "repair-01", "session"), ("L-5", "repair-01", "session_again")])
            d = f.rd / "iter-001/label_repair/L-5/repair-01"
            self.assertEqual((d / "first" / "record.jsonl").read_text(), "not JSON")        # the first answer kept apart
            self.assertTrue((d / "prompt_again.md").exists())
            st = f.labels()["L-5"]
            self.assertEqual((st["state"], st["outcome"], st["repairs"], st["sessions"]), ("accepted", "aligned", 1, 1))
            self.assertNotIn("active", st)
            self.assertEqual(st["coverage"], {"eligible": 2, "matched": 2})
            self.assertEqual(f.ledger()["L-5"]["state"], "accepted")
            self.assertIn("-- VERDICT L_5 r5a compliant", f.library()[RULE5])
            [(cid, status)] = f.statuses()
            self.assertEqual(status["status"], "committed")
            self.assertTrue(st["check"].startswith(f"iter-001/candidate/{cid}/label/"))
            label = [(c["subject"], c["status"]) for c in f.checks() if c["check"] == "label_non_regression"]
            self.assertEqual(label, [("L-5", "pass")])                          # L-1 reads no changed file: not checked again
            self.assertEqual(f.labels()["L-1"]["check"], "iter-001/label/laws/L-1.json")
            self.assertEqual([c["subject"] for c in f.checks() if c["check"] == "gate"], ["L_5"])
            self.assertEqual(f.used(), 1)

    def test_a_shared_concept_change_is_checked_on_every_law_that_reads_it_and_a_regression_is_rolled_back(self):
        answers = {("L-5", "repair-01", "session"): BREAK6_IN_C,             # fixes L-5, loses L-6's r6a
                   ("L-5", "repair-02", "session"): FIX5_IN_C}               # fixes L-5 alone
        with LabelFixture(shared_concept(), SHARED_RECS, answers) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual([k[1] for k in f.repair_calls], ["repair-01", "repair-02"])
            (c1, s1), (c2, s2) = f.statuses()
            self.assertEqual((s1["status"], s2["status"]), ("rolled_back", "committed"))
            by = collections.defaultdict(dict)
            for c in f.checks():
                if c["check"] == "label_non_regression":
                    by[c["candidate"]][c["subject"]] = c["status"]
            self.assertEqual(dict(by[c1]), {"L-5": "pass", "L-6": "fail"})     # both laws that read C checked; L-1 not
            self.assertEqual(dict(by[c2]), {"L-5": "pass", "L-6": "pass"})
            self.assertIn("match lost: r6a", [x for c in f.checks() if c["candidate"] == c1 and c["subject"] == "L-6"
                                              for x in c["details"]])
            # the second session was shown what the first candidate failed
            self.assertIn("match lost: r6a", f.prompts[1]["verdict"])
            self.assertIn("Label repair 2 of 2", f.prompts[1]["verdict"])
            labels, ledger = f.labels(), f.ledger()
            self.assertEqual((labels["L-5"]["outcome"], labels["L-5"]["repairs"], ledger["L-5"]["state"]), ("aligned", 2, "accepted"))
            self.assertEqual((labels["L-6"]["outcome"], ledger["L-6"]["state"]), ("aligned", "accepted"))
            self.assertTrue(labels["L-6"]["check"].startswith(f"iter-001/candidate/{c2}/label/"))   # L-6 checked again by the commit
            self.assertEqual(labels["L-6"].get("repairs", 0), 0)
            self.assertEqual(labels["L-1"]["check"], "iter-001/label/laws/L-1.json")
            lib = f.library()[CPATH]
            self.assertIn("-- VERDICT L_5 r5a compliant", lib)
            self.assertNotIn("L_6 r6a violated", lib)                           # the rolled-back change never reached production


    def test_a_law_that_composes_a_caller_of_the_changed_concept_is_checked_again(self):
        """L-9's node composes L-5's, which calls C; L-6's node calls C and composes L-9's (so L-6 is
        coded, and repaired, after L-9 is accepted). A change of C in L-6's repair reaches L-9 through
        the composition: L-9 is checked again, and a change that loses its match is rolled back."""
        w = World({"L-5": "shall stop.", "L-6": "shall yield.", "L-9": "shall wait."})
        w.plans = {"L-5": [concept(C, users=["L_5", "L_6"]), node("L_5", "shall stop.", "L-5", derived=[C])],
                   "L-6": [node("L_6", "shall yield.", "L-6", derived=[C], compositions=["L_9"])],
                   "L-9": [node("L_9", "shall wait.", "L-9", compositions=["L_5"])]}
        recs = [("r5b", "L-5", "violation", False, v("L_5", "violated")),
                ("r6a", "L-6", "compliant", False, v("L_6", "violated")),
                ("r9a", "L-9", "compliant", False, v("L_9", "compliant"))]
        answers = {("L-6", "repair-01", "session"): verdict_lines(CPATH, "L_6 r6a compliant", "L_9 r9a violated"),
                   ("L-6", "repair-02", "session"): verdict_lines(CPATH, "L_6 r6a compliant")}
        with LabelFixture(w, recs, answers) as f:
            self.assertEqual(f.drive(1), ["complete"])
            (c1, s1), (c2, s2) = f.statuses()
            self.assertEqual((s1["status"], s2["status"]), ("rolled_back", "committed"))
            by = collections.defaultdict(dict)
            for c in f.checks():
                if c["check"] == "label_non_regression":
                    by[c["candidate"]][c["subject"]] = c["status"]
            self.assertEqual(dict(by[c1]), {"L-5": "pass", "L-6": "pass", "L-9": "fail"})
            self.assertEqual(dict(by[c2]), {"L-5": "pass", "L-6": "pass", "L-9": "pass"})
            self.assertEqual({l: e["state"] for l, e in f.ledger().items()}, {"L-5": "accepted", "L-6": "accepted", "L-9": "accepted"})
            self.assertTrue(f.labels()["L-9"]["check"].startswith(f"iter-003/candidate/{c2}/label/"), f.labels()["L-9"]["check"])


class Coverage(unittest.TestCase):
    """3. A coverage repair for an undecided law."""

    def test_kept_only_when_more_recordings_are_decided_and_none_undone(self):
        w = World({"L-7": "shall keep right."})
        w.plans = {"L-7": [node("L_7", "shall keep right.", "L-7")]}
        recs = [("r7a", "L-7", "compliant", False, v("L_7", "unknown", LIBRARY_REASON)),
                ("r7b", "L-7", "compliant", False, v("L_7", "compliant")),
                ("r7c", "L-7", "violation", False, v("L_7", "violated"))]
        answers = {("L-7", "repair-01", "session"): comment(RULE7),                                   # decides nothing
                   ("L-7", "repair-02", "session"): verdict_lines(RULE7, "L_7 r7a compliant", "L_7 r7b violated"),  # undoes r7b
                   ("L-7", "repair-03", "session"): verdict_lines(RULE7, "L_7 r7a violated"),       # decides r7a (a mismatch)
                   ("L-7", "repair-04", "session"): comment(RULE7)}                                   # fixes nothing
        with LabelFixture(w, recs, answers) as f:
            self.assertEqual(f.drive(1, label_repair_attempts=4), ["complete"])
            first = json.loads((f.rd / "iter-001/label/laws/L-7.json").read_text())
            self.assertEqual(first["outcome"], "undecided")
            self.assertIn("Repair goal: coverage", f.prompts[0]["verdict"])
            outcomes = [s["status"] for _c, s in f.statuses()]
            self.assertEqual(outcomes, ["rolled_back", "rolled_back", "committed", "rolled_back"])
            details = [x for c in f.checks() if c["check"] == "label_non_regression" for x in c["details"]]
            self.assertTrue(any("repair goal `coverage` not met: decided 2 → 2" in x for x in details), details)
            self.assertTrue(any("match lost: r7b" in x for x in details), details)
            st = f.labels()["L-7"]
            # the kept coverage repair made r7a a mismatch: goal met, and the law now awaits a semantic repair
            self.assertEqual(f.statuses()[2][1]["status"], "committed")
            self.assertIn("goal `coverage`: decided 2 → 3", [x for c in f.checks() if c["candidate"] == f.statuses()[2][0]
                                                             and c["check"] == "label_non_regression" for x in c["details"]])
            self.assertIn("Repair goal: labelled semantic", f.prompts[3]["verdict"])
            self.assertEqual((st["repairs"], f.ledger()["L-7"]["state"]), (4, "blocked"))   # its fourth (semantic) one did not fix it
            self.assertNotEqual(st["state"], "accepted")
            self.assertIn("-- VERDICT L_7 r7a violated", f.library()[RULE7])
            self.assertNotIn("r7b violated", f.library()[RULE7])


class ConceptReview(unittest.TestCase):
    """4. A concept change inside a label repair is reviewed before its candidate commits."""

    def test_a_concept_change_is_reviewed_before_the_commit_and_a_returned_review_publishes_nothing(self):
        answers = {("L-5", "repair-01", "session"): FIX5_IN_C, ("L-5", "repair-02", "session"): FIX5_IN_C}
        with LabelFixture(shared_concept(), SHARED_RECS, answers, reviews={C: ["returned", "accepted"]}) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual(f.candidate_reviews, [C, C])
            (c1, s1), (c2, s2) = f.statuses()
            self.assertEqual((s1["status"], s2["status"]), ("rolled_back", "committed"))
            first = [(c["check"], c["subject"], c["status"]) for c in f.checks() if c["candidate"] == c1]
            self.assertIn(("concept_review", C, "fail"), first)
            self.assertFalse([x for x in first if x[0] == "label_non_regression"])   # a failed review ends the checks
            second = [(c["check"], c["subject"], c["status"]) for c in f.checks() if c["candidate"] == c2]
            self.assertLess(second.index(("concept_review", C, "pass")), second.index(("label_non_regression", "L-5", "pass")))
            # the review's call came before the commit point of the candidate that published the change
            log = f.w.log
            review_at = [i for i, e in enumerate(log) if e[:2] == ("call", "candidate_review")]
            commit_at = [i for i, e in enumerate(log) if e == ("write", cand.JOURNAL, "committed")]
            self.assertEqual(len(review_at), 2)
            self.assertEqual(len(commit_at), 1)                                 # one commit: the second candidate's
            self.assertLess(review_at[1], commit_at[0])
            self.assertIn("scripted upheld on", " ".join(f.prompts[1]["verdict"].splitlines()))
            self.assertEqual(f.labels()["L-5"]["repairs"], 2)

    def test_a_review_that_did_not_run_charges_nothing_and_the_answer_is_taken_up_again(self):
        answers = {("L-5", "repair-01", "session"): FIX5_IN_C}
        with LabelFixture(shared_concept(), SHARED_RECS, answers, reviews={C: ["outage", "accepted"]}) as f:
            statuses = f.drive(3)
            self.assertEqual(statuses[-1], "complete", statuses)
            self.assertEqual(f.repair_calls, [("L-5", "repair-01", "session")])     # one paid session, its answer taken up again
            self.assertEqual(f.candidate_reviews, [C, C])
            st = f.labels()["L-5"]
            self.assertEqual((st["state"], st["repairs"], st["sessions"]), ("accepted", 1, 1))
            self.assertEqual([s["status"] for _c, s in f.statuses()], ["rolled_back", "committed"])


def resumed_world():
    """The scenario every stop is made in: L-5's first repair breaks L-6 (rolled back, counted); its
    second is re-asked once, changes the shared concept, is reviewed, and is kept, checking L-6 again."""
    return shared_concept()


RESUME_ANSWERS = {("L-5", "repair-01", "session"): BREAK6_IN_C,
                  ("L-5", "repair-02", "session"): files(**{"record.jsonl": "not JSON"}),
                  ("L-5", "repair-02", "session_again"): FIX5_IN_C}


def filing_world():
    """The second scenario: L-5's repair files a change request for the operator (the law held), L-8's
    withdraws a span for a missing atom (a gap filed, the law blocked)."""
    w = World({"L-5": "shall stop.", "L-8": "shall wait."})
    w.plans = {"L-5": [node("L_5", "shall stop.", "L-5")], "L-8": [node("L_8", "shall wait.", "L-8")]}
    return w


FILING_RECS = TWO_RECS[1:3] + [("r8a", "L-8", "compliant", False, v("L_8", "violated"))]
REQUEST = {"type": "semantic", "object": "label", "target": "r5a", "words": "not applicable", "evidence": "r5a: the derivation"}
FILING_ANSWERS = {("L-5", "repair-01", "session"): files(**{"change_request.json": json.dumps([REQUEST])}),
                  ("L-8", "repair-01", "session"): files(**{"record.jsonl": json.dumps(
                      {"node_id": "L_8", "withdraw": {"kind": "atom", "span": "s1", "missing": "a lamp state", "nearest": []}})})}


def gap_then_commit_world():
    """The third scenario: L-3's repair withdraws a span for a missing atom (a gap filed, the law
    blocked), then L-5's repair is kept, its commit publishing L-3's state with its own."""
    w = World({"L-3": "shall wait.", "L-5": "shall stop."})
    w.plans = {"L-3": [node("L_3", "shall wait.", "L-3")], "L-5": [node("L_5", "shall stop.", "L-5")]}
    return w


GAP_RECS = [("r3a", "L-3", "compliant", False, v("L_3", "violated"))] + TWO_RECS[1:3]
GAP_ANSWERS = {("L-3", "repair-01", "session"): files(**{"record.jsonl": json.dumps(
                   {"node_id": "L_3", "withdraw": {"kind": "atom", "span": "s1", "missing": "a lamp state", "nearest": []}})}),
               ("L-5", "repair-01", "session"): FIX5}


class StopAndResume(unittest.TestCase):
    """5. A stop at each step of the repair transaction resumes to the uninterrupted run's end."""

    def reference(self, build=resumed_world, recs=SHARED_RECS, answers=RESUME_ANSWERS):
        with LabelFixture(build(), recs, dict(answers)) as f:
            self.assertEqual(f.drive(1), ["complete"])
            said = f.snap()["prog"]["to_user"]
            self.assertEqual(len(said), len(set(said)), "an uninterrupted run says a line twice")
            return f.settled(), list(f.w.log), list(f.repair_calls), set(f.to_user().splitlines())

    def sweep(self, build, recs, answers) -> dict:
        """Stopped at every tick from the label check of the first law on, and resumed: the same end as the
        uninterrupted run (ledger, records, label states, library, filed requests and gaps), every paid
        session completed once. (The operator's notices are checked apart, `test_no_notice_is_lost_*`.)"""
        ref, log, _calls, _notices = self.reference(build, recs, answers)
        start = next(i for i, e in enumerate(log) if e == ("label_build",))
        points = range(start + 1, len(log) + 1)
        self.assertGreater(len(points), 10)
        for k in points:
            w = build()
            w.crash_at = k
            with LabelFixture(w, recs, dict(answers)) as f:
                statuses = f.drive(4)
                where = f"a stop at tick {k}/{len(log)} {log[k - 1]}"
                self.assertEqual((statuses[0], statuses[-1]), ("crash", "complete"), where)
                got = f.settled()
            completed = got.pop("completed")
            for key in ref:
                if key != "completed":
                    self.assertEqual(got[key], ref[key], f"{key} differs after {where}")
            # no paid session ran to its end twice for the same answer, and none is missing
            self.assertEqual(sorted(k for k, _n in completed), sorted(k for k, _n in ref["completed"]), where)
            self.assertEqual({n for _k, n in completed}, {1}, f"a session completed twice after {where}: {completed}")
        return ref

    def test_the_reference_scenario(self):
        ref, log, calls, _ = self.reference()
        self.assertEqual(calls, [("L-5", "repair-01", "session"), ("L-5", "repair-02", "session"), ("L-5", "repair-02", "session_again")])
        st = ref["label_states"]["L-5"]
        self.assertEqual((st["state"], st["repairs"], st["sessions"]), ("accepted", 2, 2))
        for step in (("call", "candidate_review", C, 1), ("write", cand.JOURNAL, "committed"), ("replace", "state.json"),
                     ("write", cand.JOURNAL, "applied"), ("label_repair_done", "L-5/repair-02/session_again")):
            self.assertIn(step, log)

    def test_an_uninterrupted_run_says_each_notice_once_in_order(self):
        """What the operator is told by each scenario run without a stop, line for line: committing the
        notices with a kept repair changes neither their text nor their order, and says none twice."""
        head = "## Iteration 1\n\n"
        mismatch = "- `{l}`: label check mismatch ({n}/{m} plain label(s) match); awaiting its label repair, evidence in iter-001/label/evidence/{l}.md\n"
        aligned5 = "- `L-5`: label check aligned (2/2 plain label(s) match); accepted\n"
        kept5 = "- `L-5`: label repair kept (goal met); the law is aligned\n"
        expected = {
            resumed_world: (SHARED_RECS, RESUME_ANSWERS, head + "- `L-1`: label check aligned (1/1 plain label(s) match); accepted\n"
                            + mismatch.format(l="L-5", n=1, m=2) + "- `L-6`: label check aligned (2/2 plain label(s) match); accepted\n"
                            "- `L-5`: label repair rolled back (label_non_regression L-6: fail (match lost: r6a)); the law awaits its next repair\n"
                            + aligned5 + "- `L-6`: checked again by the repair of `L-5`: aligned; its law is accepted\n" + kept5),
            filing_world: (FILING_RECS, FILING_ANSWERS, head + mismatch.format(l="L-5", n=1, m=2) + mismatch.format(l="L-8", n=0, m=1)
                           + f"- `L-5`: change request on label `r5a` filed in {lr.OPERATOR_FILE}\n"),
            gap_then_commit_world: (GAP_RECS, GAP_ANSWERS, head + mismatch.format(l="L-3", n=0, m=1) + mismatch.format(l="L-5", n=1, m=2)
                                    + aligned5 + kept5)}
        for build, (recs, answers, text) in expected.items():
            with LabelFixture(build(), recs, dict(answers)) as f:
                self.assertEqual(f.drive(1), ["complete"])
                self.assertEqual(f.to_user(), text, build.__name__)

    def test_a_stop_at_every_step_of_a_rollback_a_reask_a_review_and_a_commit(self):
        ref = self.sweep(resumed_world, SHARED_RECS, RESUME_ANSWERS)
        self.assertEqual(ref["label_states"]["L-5"]["repairs"], 2)

    def test_a_stop_at_every_step_of_a_filed_request_and_a_filed_gap(self):
        ref = self.sweep(filing_world, FILING_RECS, FILING_ANSWERS)
        self.assertEqual(len(ref[lr.OPERATOR_FILE].splitlines()), 1)                 # filed once
        self.assertEqual(len(ref["gaps"]), 1)
        self.assertEqual({l: e["state"] for l, e in {e["law"]: e for e in ref["ledger"]}.items()}, {"L-5": "blocked", "L-8": "blocked"})
        self.assertEqual({l: s["repairs"] for l, s in ref["label_states"].items()}, {"L-5": 1, "L-8": 1})

    def lost_notices(self, build, recs, answers, step) -> set[str]:
        """The operator's notices of the uninterrupted run missing after a stop at `step` and a resume;
        the resumed run's notices are the uninterrupted run's, none said twice."""
        _ref, log, _calls, notices = self.reference(build, recs, answers)
        w = build()
        w.crash_at = log.index(step) + 1
        with LabelFixture(w, recs, dict(answers)) as f:
            self.assertEqual(f.drive(4), ["crash", "complete"])
            said = f.snap()["prog"]["to_user"]
            self.assertEqual(len(said), len(set(said)), f"a resumed run says a line twice: {said}")
            self.assertEqual(set(f.to_user().splitlines()) - notices, set())
            return notices - {""} - set(f.to_user().splitlines())

    def test_no_notice_is_lost_by_a_stop_past_a_repairs_commit_point(self):
        lost = self.lost_notices(resumed_world, SHARED_RECS, RESUME_ANSWERS, ("write", cand.JOURNAL, "committed"))
        self.assertEqual(lost, set())

    def test_no_notice_is_lost_by_a_stop_after_a_filed_request(self):
        lost = self.lost_notices(filing_world, FILING_RECS, FILING_ANSWERS, ("call", "label_repair", "L-8/repair-01/session", 1))
        self.assertEqual(lost, set())

    def test_no_filed_gap_is_lost_by_a_stop_past_a_later_repairs_commit_point(self):
        """A gap filed by one law's repair is listed in the iteration's notes after a stop past the commit
        point of a later law's repair, which publishes the first law's state with its own."""
        step = ("write", cand.JOURNAL, "committed")
        with LabelFixture(gap_then_commit_world(), GAP_RECS, dict(GAP_ANSWERS)) as f:
            self.assertEqual(f.drive(1), ["complete"])
            filed, log = f.snap()["prog"]["gaps_filed"], list(f.w.log)
            notes = (f.rd / "AUTO_NOTES.md").read_text()
        self.assertEqual([g["law_refs"] for g in filed], [["L-3"]])
        self.assertEqual(log.count(step), 1)
        self.assertEqual(self.lost_notices(gap_then_commit_world, GAP_RECS, GAP_ANSWERS, step), set())
        w = gap_then_commit_world()
        w.crash_at = log.index(step) + 1
        with LabelFixture(w, GAP_RECS, dict(GAP_ANSWERS)) as f:
            self.assertEqual(f.drive(4), ["crash", "complete"])
            self.assertEqual(f.snap()["prog"]["gaps_filed"], filed)
            self.assertEqual((f.rd / "AUTO_NOTES.md").read_text(), notes)

    def test_a_stop_after_a_paid_session_reuses_its_answer(self):
        """The input digest: a stop right after the repair session's completion record, before anything
        is committed; the resumed launch takes the answer up instead of asking again."""
        ref, log, _calls, _ = self.reference()
        k = log.index(("label_repair_done", "L-5/repair-02/session_again")) + 1
        w = resumed_world()
        w.crash_at = k
        with LabelFixture(w, SHARED_RECS, dict(RESUME_ANSWERS)) as f:
            self.assertEqual(f.drive(4), ["crash", "complete"])
            self.assertEqual(f.repair_calls.count(("L-5", "repair-02", "session_again")), 1)
            self.assertEqual(f.repair_calls.count(("L-5", "repair-02", "session")), 1)
            self.assertEqual(f.settled()["label_states"], ref["label_states"])


class Limits(unittest.TestCase):
    """6. The attempt limit and the run's repair budget stop routing; a failed repair accepts no law."""

    def test_the_attempts_spent_hold_the_law_unaccepted(self):
        answers = {("L-5", f"repair-0{i}", "session"): comment(RULE5, f"try {i}") for i in (1, 2, 3)}
        with LabelFixture(two_laws(), TWO_RECS, answers) as f:
            self.assertEqual(f.drive(1, label_repair_attempts=2), ["complete"])
            self.assertEqual([k[1] for k in f.repair_calls], ["repair-01", "repair-02"])     # never a third
            st, e = f.labels()["L-5"], f.ledger()["L-5"]
            self.assertEqual((st["repairs"], st["state"], st["outcome"]), (2, "awaiting_label_repair", "mismatch"))
            self.assertEqual((e["state"], e["gaps"]), ("blocked", ["decision:L-5"]))
            self.assertEqual([s["status"] for _c, s in f.statuses()], ["rolled_back", "rolled_back"])
            self.assertNotIn("try", f.library()[RULE5])
            self.assertIn("its label repairs are spent", f.to_user())
            self.assertEqual(f.drive(1, label_repair_attempts=2), ["complete"])                  # a relaunch asks nothing more
            self.assertEqual(len(f.repair_calls), 2)

    def test_the_run_budget_spent_pauses_the_laws_left_and_a_raised_budget_resumes_them(self):
        w = World({"L-5": "shall stop.", "L-8": "shall wait."})
        w.plans = {"L-5": [node("L_5", "shall stop.", "L-5")], "L-8": [node("L_8", "shall wait.", "L-8")]}
        recs = TWO_RECS[1:3] + [("r8a", "L-8", "compliant", False, v("L_8", "violated"))]
        rule8 = nodeid.rule_path("L_8")
        answers = {("L-5", "repair-01", "session"): comment(RULE5),
                   ("L-5", "repair-02", "session"): FIX5,
                   ("L-8", "repair-01", "session"): verdict_lines(rule8, "L_8 r8a compliant")}
        with LabelFixture(w, recs, answers) as f:
            # an unsplit run reports a spent label repair budget as `incomplete` (`write_status`: `paused_budget` is a split stage's)
            statuses = f.drive(1, label_repair_budget=1)
            self.assertEqual(statuses, ["incomplete"])
            self.assertIn("the run's label repair budget (1) is spent; the law waits", f.to_user())
            self.assertEqual(f.repair_calls, [("L-5", "repair-01", "session")])
            labels, ledger = f.labels(), f.ledger()
            self.assertEqual((labels["L-5"]["repairs"], labels["L-8"].get("repairs", 0)), (1, 0))
            self.assertEqual({l: ledger[l]["state"] for l in ("L-5", "L-8")}, {"L-5": "planned", "L-8": "planned"})
            self.assertEqual(f.drive(1, label_repair_budget=1), ["incomplete"])               # the same budget: nothing more
            self.assertEqual(len(f.repair_calls), 1)
            self.assertEqual(f.labels()["L-5"]["repairs"], 1)                                 # not counted twice
            self.assertEqual(f.drive(1, label_repair_budget=3), ["complete"])                 # raised explicitly, resumed
            self.assertEqual(f.repair_calls[1:], [("L-5", "repair-02", "session"), ("L-8", "repair-01", "session")])
            labels, ledger = f.labels(), f.ledger()
            self.assertEqual({l: (labels[l]["repairs"], ledger[l]["state"]) for l in ("L-5", "L-8")},
                             {"L-5": (2, "accepted"), "L-8": (1, "accepted")})


if __name__ == "__main__":
    unittest.main()
