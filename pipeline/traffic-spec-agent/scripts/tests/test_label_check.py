"""The label check on a synthetic dataset, with stand-in monitor and explain programs: a law's
outcome, the ego filter, judgment calls kept out of the outcome and the evidence, failures never
read as a semantic disagreement, and an evidence block that carries no trace; a label judges the
whole recording, scored on the reason-carrying segments of the whole trace, and a dataset or a label
that states another label contract is refused."""
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
# segments is one segment over the whole trace, observed at TIMES).
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
# the rule (the binders of its groundings in `fake.json`), and can answer with a large report. It
# reports the grounding's truncated windows as `fake.json` gives them for the rule
# (`"windows": {rule: section}`), echoes an interval it is given (`window`), or fails where
# `"explain_fail"` names the rule.
FAKE_EXPLAIN = """#!{py}
import json, sys
args = sys.argv[1:]
rule = args[args.index('--rule') + 1]
binds = [args[i + 1] for i, a in enumerate(args) if a == '--bind']
spec = json.load(open(args[-1].rsplit('/', 1)[0] + '/fake.json'))
names = set(spec[rule][0][1])
if {{b.split('=')[0] for b in binds}} != names:
    sys.stderr.write('explain: --bind must name every binder'); sys.exit(2)
if rule in spec.get('explain_fail', []):
    sys.stderr.write('explain: failed'); sys.exit(2)
window = [int(args[args.index(o) + 1]) for o in ('--from', '--to') if o in args]
wins = spec.get('windows', {{}}).get(rule)
grounds = [{{'binding': {{b.split('=')[0]: int(b.split('=')[1]) for b in binds}}, 'windows': wins}}] if wins else []
print(json.dumps({{'rule': rule, 'bind': sorted(binds), 'scan': [{{'value': 'x' * 300}}] * spec.get('big', 1),
                  **({{'window': window}} if window else {{}}), **({{'groundings': grounds}} if grounds else {{}})}}))
"""


def write_exe(path: Path, text: str) -> Path:
    path.write_text(text.format(py=sys.executable))
    path.chmod(path.stat().st_mode | stat.S_IEXEC)
    return path


#: The observation times (ms) of every synthetic trace: 0, 1000, ..., 9000.
TIMES = list(range(0, 10000, 1000))


def make_dataset(root: Path, recs: list[tuple[str, str, str, bool, dict]], trace: dict | None = None,
                 manifest: dict | None = None) -> dataset.Dataset:
    """recs: (recording_id, law, recorded_label, judgment_call, fake monitor spec), every trace observed
    at TIMES unless `trace` is given. The dataset is built from a synthetic delivery of one source
    (`manifest`, by default `{"atoms": {}}`, under a library whose split has exactly its atoms), so
    every recording reads the same source manifest."""
    import shutil
    from scripts.tests.test_recorded_dataset import fake_library, make_delivery
    raw = json.dumps(trace or {"scenes": [{"t": t} for t in TIMES]}).encode()
    for side in (".delivery", ".lib"):
        shutil.rmtree(root.with_name(root.name + side), ignore_errors=True)
    dl = make_delivery(root.with_name(root.name + ".delivery"),
                       [{"rid": rid, "law": law, "label": label or None, "jc": jc, "trace": raw} for rid, law, label, jc, _ in recs],
                       shared=manifest or {"atoms": {}})
    lib = fake_library(root.with_name(root.name + ".lib"), ", ".join(json.dumps(a) for a in (manifest or {}).get("atoms", {})))
    dataset.build(dl, root, lib, jobs=1)
    for rid, _law, _label, _jc, spec in recs:
        (root / "recordings" / rid / "fake.json").write_text(json.dumps(spec))
    return dataset.Dataset(root)


def set_label(ds: dataset.Dataset, rid: str, recorded_label: str, judgment_call: bool | None = None) -> None:
    """Rewrite one recording's label in the dataset's index (its verdict normalized from it)."""
    import csv
    from recorded import labels
    f = ds.path / "INDEX.csv"
    rows = list(csv.DictReader(f.open()))
    for r in rows:
        if r["recording_id"] == rid:
            r["recorded_label"], r["verdict"] = recorded_label, labels.verdict_of(recorded_label) or ""
            if judgment_call is not None:
                r["judgment_call"] = judgment_call
    with f.open("w", newline="") as fh:
        w = csv.DictWriter(fh, dataset.INDEX_FIELDS)
        w.writeheader()
        w.writerows(rows)


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
# The whole recording, on the reason-carrying segments of the whole trace
# ---------------------------------------------------------------------------------------------
TRUNC = ["window_truncated:since"]


def sg(a, z, v, reasons=()):
    return [a, z, v, list(reasons)]


class WholeRecording(_Fixture):
    def fresh(self, recs):
        import shutil
        shutil.rmtree(self.root / "ds", ignore_errors=True)
        return self.check(recs)

    def one(self, r1_segments, label="compliant", r2=None, binding=None):
        spec = {"R1": [["", binding or {"x": 1}, [], r1_segments]],
                "R2": r2 or [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]]}
        c = self.fresh([("a", "L", label, False, spec)])
        return c, c.scored[0]

    def test_a_violation_anywhere_decides_the_recording(self):
        for segs in ([sg(0, 2000, "violated"), sg(3000, 9000, "compliant")], [sg(0, 8000, "compliant"), sg(9000, 9000, "violated")]):
            with self.subTest(segs=segs):
                c, s = self.one(segs)
                self.assertEqual((s.verdict, s.status, c.outcome), ("violated", "mismatch", "mismatch"))

    def test_a_violation_wins_over_an_unknown(self):
        _, s = self.one([sg(0, 3000, "unknown", TRUNC), sg(4000, 4000, "violated"), sg(5000, 9000, "compliant")], label="violation")
        self.assertEqual((s.verdict, s.status, s.blockers), ("violated", "match", []))

    def test_an_unknown_anywhere_is_joined_and_every_reason_is_a_blocker(self):
        c, s = self.one([sg(0, 2000, "unknown", ["sampling_gap:once"]), sg(3000, 4000, "unknown", TRUNC),
                         sg(5000, 6000, "compliant"), sg(7000, 8000, "unknown", ["division_by_zero:d"]),
                         sg(9000, 9000, "unknown", ["window_truncated:eventually"])])
        self.assertEqual((s.verdict, s.status), ("unknown", "unknown"))
        self.assertEqual(sorted((b["reason"], b["handling"]) for b in s.blockers),
                         [("division_by_zero:d", "library"), ("sampling_gap:once", "data"),
                          ("window_truncated:eventually", "time_contract"), ("window_truncated:since", "time_contract")])
        self.assertEqual(c.outcome, "undecided")                          # the library's blocker routes it

    def test_only_the_ego_groundings_are_joined(self):
        r1 = [["", {"x": 1, "o": 2}, [], [sg(0, 9000, "compliant")]],
              ["", {"x": 1, "o": 3}, [], [sg(0, 4000, "compliant"), sg(5000, 5000, "violated"), sg(6000, 9000, "compliant")]],
              ["", {"x": 2, "o": 1}, [], [sg(0, 9000, "violated")]]]                                # not the ego
        spec = {"R1": r1, "R2": [["", {"x": 1, "o": 2}, [], [sg(0, 9000, "not_applicable")]]]}
        c = self.fresh([("a", "L", "violation", False, spec)])
        s = c.scored[0]
        self.assertEqual((s.verdict, s.status), ("violated", "match"))
        self.assertEqual(len(s.rules["R1"]["judged"]), 2)
        spec["R1"] = [r1[0], r1[2]]                                     # the other user's violation alone
        c = self.fresh([("a", "L", "compliant", False, spec)])
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

    def test_explain_is_given_the_whole_trace(self):
        c, _ = self.one([sg(0, 2000, "compliant"), sg(3000, 6000, "violated"), sg(7000, 9000, "compliant")])
        ev = [e for e in c.evidence if e.rule == "R1"]
        self.assertTrue(ev and all(e.ok and "window" not in e.report for e in ev), [e.error for e in ev])

    def test_the_record_keeps_the_judged_segments_and_no_other_contract(self):
        c = self.fresh([("a", "L", "compliant", False, {**OK, "R1": [["compliant", {"x": 1}], ["violated", {"x": 2}]]})])
        self.assertEqual(c.scored[0].status, "match")
        d = c.to_dict()
        self.assertNotIn("label_contract", d)
        self.assertNotIn("scope", d["scored"][0])
        r1 = d["scored"][0]["rules"]["R1"]
        self.assertEqual(r1["judged"][0]["segments"], [{"from": 0, "to": 9000, "verdict": "compliant", "reasons": []}])
        self.assertNotIn("segments", r1["others"][0])                    # another user's grounding: reported, its timeline not kept
        self.assertEqual(set(c.summary["counts"]), set(scoring.STATUSES))
        self.assertIn("over the whole recording; violated", label_check.render_evidence(c))


class LabelContract(_Fixture):
    """Only label contract v1 is read: a dataset that states another is refused, loudly, never read
    as v1, and no comparison set is written on it (the labels themselves are checked when the
    dataset is built)."""

    def test_a_dataset_stating_another_contract_is_refused(self):
        from recorded import labels
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, OK)])
        meta = json.loads((ds.path / "DATASET.json").read_text())
        for ok in ("v1", labels.CONTRACT):
            (ds.path / "DATASET.json").write_text(json.dumps({**meta, "label_contract": ok}))
            self.assertEqual(dataset.Dataset(ds.path).label("a").verdict, "compliant")
        run_dir = self.root / "run"
        run_dir.mkdir()
        for bad in ("v2", {"version": "v2", "subject": "ego", "scope": "scoring interval"}):
            with self.subTest(bad=bad):
                (ds.path / "DATASET.json").write_text(json.dumps({**meta, "label_contract": bad}))
                with self.assertRaisesRegex(dataset.DatasetError, "is refused"):
                    dataset.Dataset(ds.path)
                with self.assertRaisesRegex(dataset.DatasetError, "is refused"):
                    label_check.training_context(run_dir, ["L"], ds.path, self.lim)
        self.assertFalse((run_dir / "comparison_set.json").exists())

    def test_the_old_dataset_layout_is_refused_before_anything_runs(self):
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, OK)])
        meta = json.loads((ds.path / "DATASET.json").read_text())
        (ds.path / "DATASET.json").write_text(json.dumps({k: v for k, v in meta.items() if k != "layout"}))
        run_dir = self.root / "run"
        run_dir.mkdir()
        with self.assertRaisesRegex(dataset.DatasetError, "rebuild the dataset from one delivery"):
            label_check.training_context(run_dir, ["L"], ds.path, self.lim)
        self.assertFalse((run_dir / "comparison_set.json").exists())

    def test_the_monitor_and_explain_read_the_source_manifest(self):
        ds = make_dataset(self.root / "ds", [("a", "L", "compliant", False, BAD), ("b", "L", "compliant", False, BAD)])
        log = self.root / "args.log"
        for name, text in (("monitor", FAKE_MONITOR), ("explain", FAKE_EXPLAIN)):
            write_exe(self.root / name, text.replace("args = sys.argv[1:]",
                                                     f"args = sys.argv[1:]\nopen({str(log)!r}, 'a').write(json.dumps(args) + '\\n')", 1))
        label_check.check_law("L", ["R1", "R2"], LAW_OF, ds, self.mon, self.exp, self.reading, self.lim)
        calls = [json.loads(l) for l in log.read_text().splitlines()]
        src = str(ds.files("a")["manifest"])
        self.assertEqual(src, str(ds.path / "sources" / ds.row("a")["source"] / "manifest.json"))
        self.assertTrue(calls and all(c[c.index("--manifest") + 1] == src for c in calls))
        self.assertTrue(any("--scan" in c for c in calls) and any("--segments" in c for c in calls))


if __name__ == "__main__":
    unittest.main()


# ---------------------------------------------------------------------------------------------
# A recording on which one rule of the law fails and the other finishes
# ---------------------------------------------------------------------------------------------
FAILS = {"crash": "crash", "sleep": "deadline"}


class PartialRecordings(_Fixture):

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
                self.assertEqual([x["verdict"] for x in c.scored[0].rules[finished]["judged"][0]["segments"]], ["violated"])

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
