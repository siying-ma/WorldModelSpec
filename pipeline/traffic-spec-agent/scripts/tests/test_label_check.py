"""The label check on a synthetic dataset, with stand-in monitor and explain programs: a law's
outcome, the ego filter, judgment calls kept out of the outcome and the evidence, failures never
read as a semantic disagreement, and an evidence block that carries no trace; under label contract
v2, scoring inside each label's interval on the whole trace's reason-carrying segments, unusable
intervals kept unverified, and the interval bound into the run's comparison set."""
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path

from harness.phases import label_check
from recorded import dataset, scoring

# The stand-in monitor reads the recording's verdict per rule from `fake.json` beside the trace:
# {"R1": [["compliant", {"x": 1}], ...], "ego": [1], "fail": "crash"|"sleep"|null} ("fail" may map a rule
# to its own failure, so that one rule fails and the others finish). A grounding may
# give its reasons and its segments, [[from, to, verdict, reasons], ...], from which its episode is
# joined; with `--segments` each grounding's segments line follows the report (a grounding without
# segments is one segment over the whole trace).
FAKE_MONITOR = """#!{py}
import json, sys, time
args = sys.argv[1:]
trace = args[-1]
rules = args[args.index('--rules') + 1].split(',')
spec = json.load(open(trace.rsplit('/', 1)[0] + '/fake.json'))
fail = spec.get('fail')
if isinstance(fail, dict):
    fail = fail.get(rules[0])
if fail == 'crash':
    sys.exit(2)
if fail == 'sleep':
    time.sleep(5)
print(json.dumps({{'kind': 'source', 'instants': 1}}))
seg_lines = []
for r in rules:
    if r not in spec:
        continue
    print(json.dumps({{'kind': 'rule', 'rule': r, 'support': 'supported', 'absent': []}}))
    for v, b, *more in spec[r]:
        why = more[0] if more else []
        segs = more[1] if len(more) > 1 else None
        if segs is not None:
            vs = [x[2] for x in segs]
            v = next((o for o in ('violated', 'unknown', 'compliant', 'not_applicable') if o in vs), 'not_applicable')
            why = list(dict.fromkeys(t for x in segs if x[2] == 'unknown' for t in x[3]))
        print(json.dumps({{'kind': 'grounding', 'rule': r, 'grounding': b, 'episode': {{'verdict': v, 'reasons': why}}}}))
        if '--segments' in args:
            if segs is None:
                ts = [x['t'] for x in json.load(open(trace))['scenes']]
                segs = [[ts[0], ts[-1], v, why]]
            seg_lines.append({{'kind': 'segments', 'rule': r, 'grounding': b,
                              'segments': [{{'from': a, 'to': z, 'verdict': w, 'reasons': rs}} for a, z, w, rs in segs]}})
for d in seg_lines:
    print(json.dumps(d))
print(json.dumps({{'kind': 'subject', 'ego': spec.get('ego', [1]), 'binders': {{r: 'x' for r in rules}}}}))
"""
# The stand-in explain refuses, as the real one does, a binding that does not name every binder of
# the rule (the binders of its groundings in `fake.json`), and can answer with a large report.
FAKE_EXPLAIN = """#!{py}
import json, sys
args = sys.argv[1:]
rule = args[args.index('--rule') + 1]
binds = [args[i + 1] for i, a in enumerate(args) if a == '--bind']
spec = json.load(open(args[-1].rsplit('/', 1)[0] + '/fake.json'))
names = set(spec[rule][0][1])
if {{b.split('=')[0] for b in binds}} != names:
    sys.stderr.write('explain: --bind must name every binder'); sys.exit(2)
window = [int(args[args.index(o) + 1]) for o in ('--from', '--to') if o in args]
print(json.dumps({{'rule': rule, 'bind': sorted(binds), 'scan': [{{'value': 'x' * 300}}] * spec.get('big', 1),
                  **({{'window': window}} if window else {{}})}}))
"""


def write_exe(path: Path, text: str) -> Path:
    path.write_text(text.format(py=sys.executable))
    path.chmod(path.stat().st_mode | stat.S_IEXEC)
    return path


def make_dataset(root: Path, recs: list[tuple[str, str, str, bool, dict]]) -> dataset.Dataset:
    """recs: (recording_id, law, recorded_label, judgment_call, fake monitor spec)"""
    import csv
    (root / "recordings").mkdir(parents=True)
    rows = []
    for rid, law, label, jc, spec in recs:
        d = root / "recordings" / rid
        d.mkdir()
        (d / "trace.json").write_text('{"scenes":[]}')
        (d / "manifest.json").write_text('{"atoms":{}}')
        (d / "label.json").write_text(json.dumps({"law_id": law, "recorded_label": label, "judgment_call": jc}))
        (d / "fake.json").write_text(json.dumps(spec))
        rows.append({"recording_id": rid, "case_id": rid, "law_id": law, "verdict": "", "recorded_label": label,
                     "judgment_call": jc, "revision": "", "scenes": 1, "trace_sha256": "", "manifest_sha256": ""})
    with (root / "INDEX.csv").open("w") as f:
        w = csv.DictWriter(f, dataset.INDEX_FIELDS)
        w.writeheader()
        w.writerows(rows)
    (root / "DATASET.json").write_text(json.dumps({"data_version": "v1"}))
    return dataset.Dataset(root)


LAW_OF = {"R1": "L", "R2": "L"}
OK = {"R1": [["compliant", {"x": 1}]], "R2": [["not_applicable", {"x": 1}]]}
BAD = {"R1": [["compliant", {"x": 1}]], "R2": [["violated", {"x": 1}]]}


class _Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.mon = write_exe(self.root / "monitor", FAKE_MONITOR)
        self.exp = write_exe(self.root / "explain", FAKE_EXPLAIN)
        self.reading = self.root / "reading.json"
        self.reading.write_text("{}")
        self.lim = label_check.Limits(deadline_s=2, memory_gb=4, explain_s=5, jobs=2)

    def tearDown(self):
        self.tmp.cleanup()

    def check(self, recs):
        ds = make_dataset(self.root / "ds", recs)
        return label_check.check_law("L", ["R1", "R2"], LAW_OF, ds, self.mon, self.exp, self.reading, self.lim)


class LabelCheckTests(_Fixture):
    def test_aligned_when_every_plain_label_matches(self):
        c = self.check([("a", "L", "compliant", False, OK), ("b", "L", "Unresolved", False, BAD)])
        self.assertEqual(c.outcome, "aligned")
        self.assertEqual(c.summary["labelled"], 1)
        self.assertEqual(c.evidence, [])

    def test_a_disagreement_is_a_mismatch_with_evidence_and_no_trace(self):
        c = self.check([("a", "L", "compliant", False, OK), ("b", "L", "compliant", False, BAD)])
        self.assertEqual(c.outcome, "mismatch")
        self.assertEqual(sorted(e.rule for e in c.evidence), ["R1", "R2"])
        self.assertTrue(all(e.ok and e.report["bind"] == ["x=1"] for e in c.evidence))
        block = label_check.render_evidence(c)
        self.assertIn("## Label mismatches", block)
        self.assertIn("label compliant, the law's verdict violated, status mismatch", block)
        self.assertNotIn("scenes", block)

    def test_aligned_only_when_every_eligible_label_matches(self):
        blocked = {"R1": [["unknown", {"x": 1}]], "R2": [["not_applicable", {"x": 1}]]}
        c = self.check([("a", "L", "compliant", False, OK), ("b", "L", "compliant", False, blocked)])
        self.assertEqual(c.outcome, "unverified")
        self.assertEqual(c.coverage, {"eligible": 2, "matched": 1})
        # one mismatch of two repaired is progress, not alignment
        import shutil
        shutil.rmtree(self.root / "ds")
        c = self.check([("a", "L", "compliant", False, OK), ("b", "L", "compliant", False, BAD)])
        self.assertEqual(c.outcome, "mismatch")

    def test_a_rule_with_two_binders_is_explained_with_its_whole_binding(self):
        two = {"R1": [["violated", {"x": 1, "other": 2}], ["compliant", {"x": 2, "other": 1}]],
               "R2": [["not_applicable", {"x": 1, "other": 3}]]}
        c = self.check([("a", "L", "compliant", False, two)])
        ev = [e for e in c.evidence if e.rule == "R1"]
        self.assertEqual(len(ev), 1)                                   # only the grounding that judges the ego
        self.assertTrue(ev[0].ok, ev[0].error)
        self.assertEqual(ev[0].report["bind"], ["other=2", "x=1"])

    def test_the_groundings_that_decide_the_verdict_are_explained_first(self):
        # four compliant ego groundings, then the violated one that decides the rule's verdict
        many = {"R1": [["compliant", {"x": 1, "other": k}] for k in (2, 3, 4, 5)] + [["violated", {"x": 1, "other": 6}]],
                "R2": [["not_applicable", {"x": 1, "other": 7}]]}
        c = self.check([("a", "L", "compliant", False, many)])
        ev = [e for e in c.evidence if e.rule == "R1"]
        self.assertEqual(len(ev), 3)
        self.assertEqual(ev[0].binding, {"x": 1, "other": 6})
        self.assertTrue(any("2 of 5 groundings" in n and "0 of them deciding" in n for n in c.notes), c.notes)

    def test_a_large_derivation_stays_valid_json_and_says_what_was_cut(self):
        big = {**BAD, "big": 200}
        ds = make_dataset(self.root / "ds", [("b", "L", "compliant", False, big)])
        lim = label_check.Limits(deadline_s=5, memory_gb=4, explain_s=5, jobs=1, evidence_chars=5000)
        c = label_check.check_law("L", ["R1", "R2"], LAW_OF, ds, self.mon, self.exp, self.reading, lim, self.root / "art")
        e = next(e for e in c.evidence if e.rule == "R2")
        self.assertTrue(e.pruned)
        self.assertEqual(e.report["scan"][-1], {"omitted": 197})
        self.assertEqual(len(json.loads(Path(e.artifact).read_text())["scan"]), 200)
        block = label_check.render_evidence(c)
        for chunk in block.split("```json\n")[1:]:
            json.loads(chunk.split("\n```")[0])                       # every embedded report parses
        self.assertIn("omitted", block)

    def test_only_the_ego_is_judged(self):
        other_violates = {"R1": [["compliant", {"x": 1}], ["violated", {"x": 2}]], "R2": [["not_applicable", {"x": 1}]]}
        c = self.check([("a", "L", "compliant", False, other_violates)])
        self.assertEqual(c.outcome, "aligned")

    def test_judgment_calls_never_decide_and_never_enter_the_evidence(self):
        c = self.check([("a", "L", "compliant", False, OK), ("j", "L", "compliant", True, BAD)])
        self.assertEqual(c.outcome, "aligned")
        self.assertEqual(c.evidence, [])
        self.assertNotIn("j", label_check.render_evidence(c).split("Statuses")[1])
        self.assertEqual(label_check.judgment_table(c), [{"recording_id": "j", "law_id": "L", "recorded_label": "compliant",
                                                          "verdict": "violated", "status": "mismatch"}])

    def test_failures_are_failed_not_mismatches(self):
        for spec, status in (({**OK, "fail": "crash"}, "crash"), ({**OK, "fail": "sleep"}, "deadline"),
                             ({"R1": OK["R1"]}, "incomplete"), ({**OK, "ego": [1, 2]}, "contract_failed")):
            with self.subTest(status=status):
                import shutil
                shutil.rmtree(self.root / "ds", ignore_errors=True)
                c = self.check([("a", "L", "compliant", False, spec)])
                self.assertEqual((c.outcome, c.scored[0].status), ("failed", status))

    def test_unverified_without_a_usable_plain_label(self):
        c = self.check([("j", "L", "violated", True, OK), ("u", "L", "Unresolved", False, OK)])
        self.assertEqual(c.outcome, "unverified")

    def test_the_rules_must_be_the_laws_expected_rules(self):
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, OK)])
        with self.assertRaises(ValueError):
            label_check.check_law("L", ["R1"], LAW_OF, ds, self.mon, self.exp, self.reading, self.lim)


class SiblingsAndFreeze(_Fixture):
    def test_a_sibling_that_was_not_accepted_leaves_the_law_incomplete(self):
        # the plan has R1 and R2; only R1 was accepted. Alone R1 would match: the law is not aligned
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, BAD)])
        c = label_check.check_law("L", ["R1", "R2"], LAW_OF, ds, self.mon, self.exp, self.reading, self.lim,
                                  unavailable={"R2": "not accepted; the law is returned"})
        self.assertEqual(c.outcome, "incomplete")
        self.assertEqual(c.scored[0].status, "incomplete")
        self.assertIn("R2: not run (not accepted; the law is returned)", c.notes)

    def test_a_law_with_no_planned_node_is_incomplete(self):
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, OK)])
        c = label_check.check_law("L", [], {}, ds, self.mon, self.exp, self.reading, self.lim)
        self.assertEqual(c.outcome, "incomplete")

    def test_scoring_refuses_a_library_that_moved_after_the_freeze(self):
        from unittest.mock import patch
        from harness.store import paths
        lib = self.root / "lib"
        for d in ("TrafficSpec/Rules/X", "TrafficSpec/Concepts", "TrafficSpecWitness", "TrafficSpec/Core", "TrafficSpec/Readings"):
            (lib / d).mkdir(parents=True)
        (lib / "TrafficSpec/Rules/X/R1.lean").write_text("rule 1")
        (lib / "TrafficSpec/Core/A.lean").write_text("core")
        run_dir = self.root / "run"
        run_dir.mkdir()
        (run_dir / "reading.json").write_text("{}")
        with patch.multiple(paths, LIBRARY=lib, CORE=lib / "TrafficSpec/Core", RULES_DIR=lib / "TrafficSpec/Rules",
                            CONCEPTS_DIR=lib / "TrafficSpec/Concepts", WITNESS_DIR=lib / "TrafficSpecWitness",
                            READINGS=lib / "TrafficSpec/Readings"):
            self.assertTrue(label_check.drift(run_dir))                       # never frozen: refused
            fdir = label_check.freeze(run_dir)
            self.assertEqual(label_check.drift(run_dir), [])
            self.assertEqual((fdir / "snapshot/TrafficSpec/Rules/X/R1.lean").read_text(), "rule 1")
            (lib / "TrafficSpec/Rules/X/R1.lean").write_text("rule 1, edited")
            (lib / "TrafficSpec/Rules/X/R2.lean").write_text("rule 2")
            (run_dir / "reading.json").write_text('{"params": []}')
            moved = label_check.drift(run_dir)
        self.assertIn("changed since the freeze: TrafficSpec/Rules/X/R1.lean", moved)
        self.assertIn("added since the freeze: TrafficSpec/Rules/X/R2.lean", moved)
        self.assertIn("changed since the freeze: run/reading.json", moved)


# ---------------------------------------------------------------------------------------------
# Label contract v2: a scoring interval per label
# ---------------------------------------------------------------------------------------------
TIMES = list(range(0, 10000, 1000))          # observations at 0, 1000, ..., 9000 ms
IV = {"start_ms": 3000, "end_ms": 6000, "source": "scenario design S", "confirmed": True}
TRUNC = ["window_truncated:since"]


def sg(a, z, v, reasons=()):
    return [a, z, v, list(reasons)]


def label_v2(law, label, jc, interval=IV, **over):
    d = {"law_id": law, "recorded_label": label, "judgment_call": jc, "label_contract": "v2", "subject": "ego"}
    if interval is not None:
        d["scoring_interval"] = interval
    return {**d, **over}


def make_v2_dataset(root: Path, recs: list[tuple[str, dict, dict]]) -> dataset.Dataset:
    """recs: (recording_id, label.json, fake monitor spec), every trace observed at TIMES."""
    import csv
    from recorded import labels
    (root / "recordings").mkdir(parents=True)
    rows = []
    for rid, lab, spec in recs:
        d = root / "recordings" / rid
        d.mkdir()
        (d / "trace.json").write_text(json.dumps({"scenes": [{"t": t} for t in TIMES]}))
        (d / "manifest.json").write_text('{"atoms":{}}')
        (d / "label.json").write_text(json.dumps(lab))
        (d / "fake.json").write_text(json.dumps(spec))
        rows.append({"recording_id": rid, "case_id": rid, "law_id": lab.get("law_id", "L"), "verdict": "",
                     "recorded_label": lab["recorded_label"], "judgment_call": lab["judgment_call"], "revision": "",
                     "scenes": len(TIMES), "trace_sha256": "", "manifest_sha256": ""})
    with (root / "INDEX.csv").open("w") as f:
        w = csv.DictWriter(f, dataset.INDEX_FIELDS)
        w.writeheader()
        w.writerows(rows)
    (root / "DATASET.json").write_text(json.dumps({"data_version": "v2data", "label_contract": labels.CONTRACT_V2}))
    return dataset.Dataset(root)


class IntervalScoring(_Fixture):
    def check2(self, recs):
        import shutil
        shutil.rmtree(self.root / "ds", ignore_errors=True)
        self.ds = make_v2_dataset(self.root / "ds", recs)
        return label_check.check_law("L", ["R1", "R2"], LAW_OF, self.ds, self.mon, self.exp, self.reading, self.lim)

    def one(self, r1_segments, label="compliant", r2=None, jc=False, binding=None):
        spec = {"R1": [["", binding or {"x": 1}, [], r1_segments]],
                "R2": r2 or [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]]}
        c = self.check2([("a", label_v2("L", label, jc), spec)])
        return c, c.scored[0]

    def test_a_violation_outside_the_interval_does_not_change_the_label(self):
        c, s = self.one([sg(0, 2000, "violated"), sg(3000, 6000, "compliant"), sg(7000, 9000, "violated")])
        self.assertEqual((s.verdict, s.status, c.outcome), ("compliant", "match", "aligned"))
        self.assertEqual(s.scope["whole_verdict"], "violated")             # kept as a diagnosis only
        self.assertEqual((s.scope["start_ms"], s.scope["end_ms"], s.scope["source"]), (3000, 6000, "scenario design S"))
        self.assertEqual(c.to_dict()["label_contract"], "v2")

    def test_inside_a_violation_wins_over_an_unknown(self):
        _, s = self.one([sg(0, 3000, "unknown", TRUNC), sg(4000, 4000, "violated"), sg(5000, 9000, "compliant")],
                        label="violation")
        self.assertEqual((s.verdict, s.status, s.blockers), ("violated", "match", []))

    def test_an_unknown_only_in_the_prefix_is_not_joined_and_is_no_blocker(self):
        c, s = self.one([sg(0, 2000, "unknown", TRUNC), sg(3000, 9000, "compliant")])
        self.assertEqual((s.verdict, s.status), ("compliant", "match"))
        self.assertEqual(s.scope["whole_verdict"], "unknown")
        self.assertEqual(s.blockers, [])

    def test_blockers_are_computed_from_the_interval_only(self):
        _, s = self.one([sg(0, 2000, "unknown", ["sampling_gap:once"]), sg(3000, 4000, "unknown", TRUNC),
                         sg(5000, 6000, "compliant"), sg(7000, 9000, "unknown", ["division_by_zero:d"])])
        self.assertEqual(s.status, "unknown")
        self.assertEqual([(b["reason"], b["handling"], b["observations"]) for b in s.blockers],
                         [("window_truncated:since", "time_contract", 2)])

    def test_insufficient_context_before_and_after_stays_unknown(self):
        # history missing at the interval's start, a look-ahead past the trace end at its end: the
        # interval creates neither, and they are blockers of the interval
        c = self.check2([("b", label_v2("L", "compliant", False, {**IV, "start_ms": 0, "end_ms": 9000}),
                          {"R1": [["", {"x": 1}, [], [sg(0, 1000, "unknown", TRUNC), sg(2000, 8000, "compliant"),
                                                       sg(9000, 9000, "unknown", ["window_truncated:eventually"])]]],
                           "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]]})])
        s = c.scored[0]
        self.assertEqual((s.verdict, s.status, c.outcome), ("unknown", "unknown", "unverified"))
        self.assertEqual(sorted((b["reason"], b["observations"]) for b in s.blockers),
                         [("window_truncated:eventually", 1), ("window_truncated:since", 2)])

    def test_the_endpoints_are_inside(self):
        for at, want in ((3000, "violated"), (6000, "violated"), (2000, "compliant"), (7000, "compliant")):
            with self.subTest(at=at):
                segs = [sg(t, t, "violated" if t == at else "compliant") for t in TIMES]
                _, s = self.one(segs, label="violation")
                self.assertEqual(s.verdict, want)

    def test_unusable_intervals_keep_their_place_unverified_and_are_never_run(self):
        bad = {"empty": {**IV, "start_ms": 6000, "end_ms": 3000}, "after": {**IV, "end_ms": 12000},
               "before": {**IV, "start_ms": -1000}, "between": {**IV, "start_ms": 3500},
               "unconfirmed": {**IV, "confirmed": False}, "no_source": {**IV, "source": ""},
               "float": {**IV, "start_ms": 3000.0}}
        recs = [(k, label_v2("L", "compliant", False, v), {**OK, "fail": "crash"}) for k, v in bad.items()]
        recs += [("missing", label_v2("L", "compliant", False, None), {**OK, "fail": "crash"}),
                 ("v1label", {"law_id": "L", "recorded_label": "compliant", "judgment_call": False}, {**OK, "fail": "crash"}),
                 ("ok", label_v2("L", "compliant", False), OK)]
        c = self.check2(recs)
        st = {s.recording_id: s.status for s in c.scored}
        self.assertEqual(st, {**{k: "label_unverified" for k in [*bad, "missing", "v1label"]}, "ok": "match"})
        self.assertEqual(c.coverage, {"eligible": 10, "matched": 1})      # the fixed denominator keeps them
        self.assertEqual(c.outcome, "unverified")                         # never failed (no crash: never run), never aligned
        self.assertEqual(c.summary["counts"]["label_unverified"], 9)
        self.assertEqual(c.evidence, [])
        notes = {s.recording_id: s.note for s in c.scored}
        self.assertIn("empty", notes["empty"])
        self.assertIn("leaves the trace", notes["after"])
        self.assertIn("fall on no observation", notes["between"])
        self.assertIn("not confirmed", notes["unconfirmed"])
        self.assertIn("no scoring interval", notes["missing"])
        self.assertIn("does not state label contract v2", notes["v1label"])

    def test_an_unverified_label_never_reaches_the_evidence(self):
        c = self.check2([("u", label_v2("L", "compliant", False, None), BAD), ("m", label_v2("L", "compliant", False), BAD)])
        self.assertEqual(c.outcome, "mismatch")
        self.assertEqual({e.recording_id for e in c.evidence}, {"m"})
        block = label_check.render_evidence(c)
        self.assertNotIn("Recording u", block)
        self.assertIn("label_unverified 1", block)
        self.assertIn("scoring interval [3000, 6000] ms", block)
        self.assertIn("only the verdicts at observations inside the interval are joined", block)

    def test_only_the_ego_groundings_are_joined(self):
        r1 = [["", {"x": 1, "o": 2}, [], [sg(0, 9000, "compliant")]],
              ["", {"x": 1, "o": 3}, [], [sg(0, 4000, "compliant"), sg(5000, 5000, "violated"), sg(6000, 9000, "compliant")]],
              ["", {"x": 2, "o": 1}, [], [sg(0, 9000, "violated")]]]                                # not the ego
        spec = {"R1": r1, "R2": [["", {"x": 1, "o": 2}, [], [sg(0, 9000, "not_applicable")]]]}
        c = self.check2([("a", label_v2("L", "violation", False), spec)])
        s = c.scored[0]
        self.assertEqual((s.verdict, s.status), ("violated", "match"))
        self.assertEqual(len(s.rules["R1"]["judged"]), 2)
        spec["R1"] = [r1[0], r1[2]]                                     # the other user's violation alone
        c = self.check2([("a", label_v2("L", "compliant", False), spec)])
        self.assertEqual(c.scored[0].status, "match")

    def test_several_rules_join_in_order(self):
        unknown_in = [["", {"x": 1}, [], [sg(0, 9000, "unknown", TRUNC)]]]
        _, s = self.one([sg(0, 9000, "unknown", TRUNC)], label="violation",
                        r2=[["", {"x": 1}, [], [sg(0, 3000, "compliant"), sg(4000, 4000, "violated"), sg(5000, 9000, "compliant")]]])
        self.assertEqual((s.verdict, s.status), ("violated", "match"))   # a violation of one rule wins over the other's unknown
        _, s = self.one([sg(0, 9000, "compliant")], r2=unknown_in)
        self.assertEqual(s.verdict, "unknown")
        _, s = self.one([sg(0, 9000, "compliant")])
        self.assertEqual(s.verdict, "compliant")                          # compliant before not_applicable

    def test_a_judgment_call_is_scored_in_its_interval_and_kept_apart(self):
        c = self.check2([("j", label_v2("L", "compliant", True), {"R1": [["", {"x": 1}, [], [sg(0, 2000, "violated"), sg(3000, 9000, "compliant")]]],
                                                               "R2": OK["R2"]}),
                         ("jbad", label_v2("L", "compliant", True, None), OK),
                         ("a", label_v2("L", "compliant", False), OK)])
        self.assertEqual(c.outcome, "aligned")
        self.assertEqual(c.evidence, [])
        self.assertEqual({r["recording_id"]: r["status"] for r in label_check.judgment_table(c)},
                         {"j": "match", "jbad": "label_unverified"})

    def test_explain_chooses_inside_the_interval(self):
        c, _ = self.one([sg(0, 2000, "compliant"), sg(3000, 6000, "violated"), sg(7000, 9000, "compliant")])
        ev = [e for e in c.evidence if e.rule == "R1"]
        self.assertTrue(ev and all(e.ok and e.report["window"] == [3000, 6000] for e in ev), [e.error for e in ev])

    def test_a_grounding_whose_segments_miss_the_interval_is_refused(self):
        _, s = self.one([sg(0, 3000, "compliant"), sg(5000, 9000, "compliant")])
        self.assertEqual(s.status, "crash")
        self.assertIn("do not cover the scoring interval", s.note)

    def test_v1_runs_without_segments_and_keeps_its_records(self):
        c = self.check([("a", "L", "compliant", False, OK)])
        self.assertEqual(c.scored[0].status, "match")
        d = c.to_dict()
        self.assertNotIn("label_contract", d)
        self.assertNotIn("scope", d["scored"][0])
        self.assertNotIn("segments", d["scored"][0]["rules"]["R1"]["judged"][0])
        self.assertNotIn("label_unverified", c.summary["counts"])
        self.assertIn("over the whole recording; violated", label_check.render_evidence(c))

    def test_a_summary_never_joins_the_two_contracts(self):
        from recorded import scoring
        v1 = self.check([("a", "L", "compliant", False, OK)]).scored
        v2 = self.check2([("b", label_v2("L", "compliant", False), OK)]).scored
        with self.assertRaises(ValueError):
            scoring.summary(v1 + v2)


class IntervalBinding(_Fixture):
    """The interval, its source, its confirmation and the contract are bound into the run's fixed
    comparison set: a change refuses resumption, and a repair compared on another stretch fails."""

    def test_an_interval_change_refuses_resumption(self):
        ds = make_v2_dataset(self.root / "ds", [("a", label_v2("L", "compliant", False), OK)])
        run_dir = self.root / "run"
        run_dir.mkdir()
        ctx = label_check.training_context(run_dir, ["L"], ds.path, self.lim)
        case = ctx.fixed["cases"]["a"]
        self.assertEqual((case["scope"], case["defect"]), ({"start_ms": 3000, "end_ms": 6000, "source": "scenario design S"}, None))
        self.assertIn("label_set", ctx.versions())
        self.assertNotEqual(ctx.fixed["label_contract"], label_check.contract_version("v1"))
        saved = (run_dir / "comparison_set.json").read_bytes()
        label_check.training_context(run_dir, ["L"], ds.path, self.lim)                  # the same inputs resume
        lab = ds.files("a")["label"]
        for change in ({**IV, "end_ms": 5000}, {**IV, "source": "another design"}, {**IV, "confirmed": False}):
            with self.subTest(change=change):
                lab.write_text(json.dumps(label_v2("L", "compliant", False, change)))
                with self.assertRaises(SystemExit):
                    label_check.training_context(run_dir, ["L"], ds.path, self.lim)
        self.assertEqual((run_dir / "comparison_set.json").read_bytes(), saved)

    def test_a_v1_run_does_not_resume_on_a_v2_dataset(self):
        ds1 = make_dataset(self.root / "ds1", [("a", "L", "compliant", False, OK)])
        run_dir = self.root / "run"
        run_dir.mkdir()
        ctx = label_check.training_context(run_dir, ["L"], ds1.path, self.lim)
        self.assertNotIn("label_set", ctx.versions())
        self.assertNotIn("scope", ctx.fixed["cases"]["a"])
        meta = json.loads((ds1.path / "DATASET.json").read_text())
        from recorded import labels
        (ds1.path / "DATASET.json").write_text(json.dumps({**meta, "label_contract": labels.CONTRACT_V2}))
        with self.assertRaises(SystemExit):
            label_check.training_context(run_dir, ["L"], ds1.path, self.lim)

    def test_a_repair_never_gains_by_another_stretch(self):
        def rec(status, start):
            return {"outcome": "x", "scored": [{"recording_id": "a", "label": "compliant", "judgment_call": False, "status": status,
                                                "scope": {"start_ms": start, "end_ms": 6000, "source": "S"}}]}
        moved = label_check.compare(rec("mismatch", 3000), rec("match", 4000), "labelled semantic")
        self.assertFalse(moved["ok"])
        self.assertIn("scored over another stretch of the recording: a", moved["reasons"])
        self.assertTrue(label_check.compare(rec("mismatch", 3000), rec("match", 3000), "labelled semantic")["ok"])


class LabelContractV2(unittest.TestCase):
    def test_validation(self):
        from recorded import labels
        p = lambda **over: labels.parse(label_v2("L", "compliant", False, **over), "v2")
        self.assertIsNone(labels.interval_defect(p(), TIMES, "L"))
        self.assertEqual(p().interval, labels.Interval(3000, 6000, "scenario design S", True))
        self.assertIn("integer", p(interval={**IV, "end_ms": True}).defect)
        self.assertIn("subject", p(subject="track 7").defect)
        self.assertIn("names law", labels.interval_defect(p(), TIMES, "OTHER"))
        self.assertIsNone(labels.interval_defect(p(interval={**IV, "start_ms": 4000, "end_ms": 4000}), TIMES, "L"))
        self.assertIn("no observation", labels.interval_defect(p(), [], "L"))
        self.assertEqual(labels.parse(label_v2("L", "compliant", False)).contract, "v1")     # v1 reads no interval
        self.assertEqual(labels.contract_of(None), "v1")
        self.assertEqual(labels.contract_of(labels.CONTRACT), "v1")
        with self.assertRaises(ValueError):
            labels.contract_of({"scope": "the part we like"})


if __name__ == "__main__":
    unittest.main()


# ---------------------------------------------------------------------------------------------
# A recording on which one rule of the law fails and the other finishes
# ---------------------------------------------------------------------------------------------
FAILS = {"crash": "crash", "sleep": "deadline"}


class PartialRecordings(_Fixture):
    check2 = IntervalScoring.check2

    def assert_partial(self, c, s, finished, failing, kind, verdict, label):
        status = kind if label is not None else "unlabelled"
        self.assertEqual((s.status, s.verdict, s.failure), (status, None, kind))
        self.assertEqual(s.failed, [{"node": failing, "failure": kind}])
        self.assertTrue(s.partial)
        self.assertEqual(sorted(s.rules), [finished])
        self.assertEqual(s.rules[finished]["verdict"], verdict)
        self.assertEqual([g["binding"] for g in s.rules[finished]["judged"]], [{"x": 1}])
        found = {"nodes": [finished], "complete": False, "status": status} if verdict == "violated" else None
        self.assertEqual(s.found_violation, found)
        d = c.to_dict()["scored"][0]
        self.assertEqual((d["partial"], d["failed"], d["found_violation"]), (True, s.failed, found))
        self.assertEqual(c.evidence, [])                                  # no Explain on a recording that did not finish
        summ = c.summary
        self.assertEqual((summ["matched"], summ["partial"], summ["found_violation"]), (0, 1, int(found is not None)))
        self.assertEqual(summ["labelled"], int(label is not None))
        self.assertFalse(scoring.library_actionable(s))
        if label is None:
            self.assertEqual((c.outcome, summ["unlabelled_failures"]), ("unverified", 1))
        else:
            self.assertEqual((c.outcome, summ["counts"][kind]), ("failed", 1))
            text = label_check.render_evidence(c)
            self.assertIn(f"Partial: {failing} did not finish", text)
            self.assertIn(f"- {finished}: verdict {verdict}", text)
            if found:
                self.assertIn(f"the recording stays {status}", text)

    def test_v1_keeps_the_finished_rule_in_both_orders(self):
        for (finished, failing), fail, label in ((o, f, l) for o in (("R1", "R2"), ("R2", "R1")) for f in FAILS
                                                 for l in ("violated", "compliant", None)):
            with self.subTest(finished=finished, fail=fail, label=label):
                import shutil
                shutil.rmtree(self.root / "ds", ignore_errors=True)
                spec = {finished: [["violated", {"x": 1}]], failing: [["compliant", {"x": 1}]], "fail": {failing: fail}}
                c = self.check([("a", "L", label or "", False, spec)])
                self.assert_partial(c, c.scored[0], finished, failing, FAILS[fail], "violated", label)

    def test_v2_keeps_the_finished_rule_cut_to_the_interval_in_both_orders(self):
        inside = [sg(0, 2000, "compliant"), sg(3000, 4000, "violated"), sg(5000, 9000, "compliant")]
        outside = [sg(0, 2000, "violated"), sg(3000, 9000, "compliant")]
        for (finished, failing), fail, label, (segs, verdict, kept) in (
                (o, f, l, x) for o in (("R1", "R2"), ("R2", "R1")) for f in FAILS for l in ("violated", None)
                for x in ((inside, "violated", ["violated", "compliant"]), (outside, "compliant", ["compliant"]))):
            with self.subTest(finished=finished, fail=fail, label=label, verdict=verdict):
                spec = {finished: [["", {"x": 1}, [], segs]], failing: [["", {"x": 1}, [], [sg(0, 9000, "compliant")]]],
                        "fail": {failing: fail}}
                c = self.check2([("a", label_v2("L", label or "", False), spec)])
                s = c.scored[0]
                self.assert_partial(c, s, finished, failing, FAILS[fail], verdict, label)
                self.assertNotIn("whole_verdict", s.scope)
                self.assertEqual([x["verdict"] for x in s.rules[finished]["judged"][0]["segments"]], kept)

    def test_a_rule_whose_segments_miss_the_interval_fails_alone(self):
        spec = {"R1": [["", {"x": 1}, [], [sg(0, 3000, "compliant"), sg(5000, 9000, "compliant")]]],
                "R2": [["", {"x": 1}, [], [sg(0, 9000, "violated")]]]}
        c = self.check2([("a", label_v2("L", "violated", False), spec)])
        self.assert_partial(c, c.scored[0], "R2", "R1", "crash", "violated", "violated")
        self.assertIn("do not cover the scoring interval", c.scored[0].note)

    def test_a_partial_recording_never_counts_as_decided(self):
        import shutil
        shutil.rmtree(self.root / "ds", ignore_errors=True)
        before = self.check([("a", "L", "violated", False, {"R1": [["violated", {"x": 1}]], "R2": [["compliant", {"x": 1}]]}),
                             ("b", "L", "compliant", False, OK)])
        self.assertEqual(before.outcome, "aligned")
        shutil.rmtree(self.root / "ds", ignore_errors=True)
        after = self.check([("a", "L", "violated", False, {"R1": [["violated", {"x": 1}]], "R2": [["compliant", {"x": 1}]],
                                                         "fail": {"R2": "crash"}}),
                            ("b", "L", "compliant", False, OK)])
        self.assertEqual((after.outcome, after.coverage), ("failed", {"eligible": 2, "matched": 1}))
        from harness.loop import LABEL_ROUTES
        self.assertEqual(LABEL_ROUTES[after.outcome], "failed")
        cmp = label_check.compare(before.to_dict(), after)
        self.assertEqual((cmp["ok"], cmp["lost"], cmp["undecided"]), (False, ["a"], ["a"]))
        self.assertEqual(label_check.progress("performance", label_check.eligible_statuses(after),
                                              label_check.eligible_statuses(before))[0], True)
