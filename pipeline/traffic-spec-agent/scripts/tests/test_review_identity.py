"""Development regression tests for the review's identities: a duty as an occurrence in the law,
canonical names, a case's identity with its grounding, a ruling's identity, precedents without the
case's own lineage, the admission standard with the history's horizon, joined passes, word-level
items, and streaks."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.model import corpus
from harness.model.blueprint import Node
from harness.phases import review
from harness.store.ledger import Ledger

TWO = corpus.Law("L-2", "", "At a red marker the driver shall stop. At a blue marker the driver shall stop.", "")


def two_nodes():
    seg = lambda first: [{"id": "s1", "role": "condition" if first else "sibling", "text": "At a red marker"},
                         {"id": "s2", "role": "subject" if first else "sibling", "text": "the driver"},
                         {"id": "s3", "role": "obligation" if first else "sibling", "text": "shall stop."},
                         {"id": "s4", "role": "sibling" if first else "condition", "text": "At a blue marker"},
                         {"id": "s5", "role": "sibling" if first else "subject", "text": "the driver"},
                         {"id": "s6", "role": "sibling" if first else "obligation", "text": "shall stop."}]
    return (Node({"node_id": "L_2_o1", "law_refs": ["L-2"], "segmentation": seg(True), "binders": [{"name": "v"}]}),
            Node({"node_id": "L_2_o2", "law_refs": ["L-2"], "segmentation": seg(False), "binders": [{"name": "v"}]}))


class Duty(unittest.TestCase):
    def test_identical_words_are_two_duties(self):
        a, b = two_nodes()
        da, db = review.duty_of(a, TWO), review.duty_of(b, TWO)
        self.assertNotEqual(da["id"], db["id"])
        self.assertEqual(da["words"], db["words"])
        self.assertIn("red marker", da["context"])
        self.assertIn("blue marker", db["context"])

    def test_the_block_names_the_duty_and_its_siblings(self):
        a, _b = two_nodes()
        block = review.duty_block(a, TWO)
        self.assertIn("The duty judged here", block)
        self.assertIn("blue marker", block.split("Judged separately")[1])
        one = Node({"node_id": "L_1", "law_refs": ["L-2"], "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop."}]})
        self.assertEqual(review.duty_block(one, TWO), "")


class Identity(unittest.TestCase):
    CASE = {"and": [{"atom": "ru_motor_vehicle", "args": [{"var": "v"}]}, {"atom": "st_lane", "args": [{"var": "ln"}]},
                    {"forall_region": {"lit": "lane"}, "var": "q", "body": {"same": [{"var": "q"}, {"var": "ln"}]}}]}

    def d(self, **kw):
        return {"trace": {"scenes": [{"t": 0}]}, "entities": {"ln": {"kind": "region", "id": 12}}, "grounding": {"v": 1}, "at": 0, **kw}

    def test_a_renaming_keeps_the_identity(self):
        c1 = review.canonical_case(self.d(), self.CASE, ["v"])
        renamed = json.loads(json.dumps(self.CASE).replace('"v"', '"u"').replace('"ln"', '"lane"').replace('"q"', '"z"'))
        c2 = review.canonical_case(self.d(entities={"lane": {"kind": "region", "id": 12}}, grounding={"u": 1}), renamed, ["u"])
        self.assertEqual(c1["case"], c2["case"])
        self.assertEqual(review.case_id(TWO, self.d(), c1), review.case_id(TWO, self.d(), c2))
        self.assertEqual(c1["grounding"], {"user1": 1})

    def test_another_track_is_another_case(self):
        c1 = review.canonical_case(self.d(), self.CASE, ["v"])
        c2 = review.canonical_case(self.d(grounding={"v": 2}), self.CASE, ["v"])
        self.assertNotEqual(review.case_id(TWO, self.d(), c1), review.case_id(TWO, self.d(grounding={"v": 2}), c2))

    def test_a_ruling_is_a_case_on_a_duty(self):
        self.assertNotEqual(review.ruling_identity({"case_id": "c", "duty": "d1"}), review.ruling_identity({"case_id": "c", "duty": "d2"}))
        self.assertEqual(review.ruling_identity({"finding_id": "f"}), ("finding", "f"))


class Precedents(unittest.TestCase):
    def test_the_case_never_sees_its_own_lineage(self):
        rows = [{"lineage": "A", "iteration": 1, "subject": "n", "item": "a", "ruling": "upheld", "reason": "r1"},
                {"lineage": "B", "iteration": 1, "subject": "n", "item": "b", "ruling": "upheld", "reason": "r2"}]
        ctx = SimpleNamespace(precedents=rows, law=TWO, seg="", definitions=[], record={}, rendering="", params=[], aggregates=[],
                              not_atoms="")
        saved = review.render.render
        review.render.render = lambda name, vals: vals["precedents"]
        try:
            out = review.stage_b_prompt(None, ctx, "item", {}, lineage="A")
        finally:
            review.render.render = saved
        self.assertNotIn("r1", out)
        self.assertIn("r2", out)


class Admission(unittest.TestCase):
    def cert(self, *reasons):
        return {"case_value": {"value": "true"}, "rule_result": {"verdict": "unknown", "unknown_reasons": list(reasons)}}

    def test_a_bounded_window_is_missing_evidence(self):
        need = review._Need(back=5)
        cls, _ = review.admission({"kind": "rule_undecided"}, self.cert("window_truncated:holds_for"), need)
        self.assertEqual(cls, "insufficient")

    def test_an_unbounded_window_is_the_rules(self):
        need = review._Need(to_start=True)
        self.assertEqual(review.admission({"kind": "rule_undecided"}, self.cert("window_truncated:since"), need)[0], "judge")
        self.assertEqual(review.admission({"kind": "rule_permits_unlawful"}, self.cert("window_truncated:since"), need)[0], "insufficient")

    def test_a_false_case_is_invalid(self):
        self.assertEqual(review.admission({}, {"case_value": {"value": "false"}}, review._Need())[0], "invalid")


class Passes(unittest.TestCase):
    def tool(self, answer):
        return SimpleNamespace(answer=answer, attempts=[], certs_of=lambda a: {}, judgeable=lambda *a: ["no"])

    def test_an_over_cap_answer_is_kept_never_truncated(self):
        div = {"kind": "rule_permits_unlawful", "lawful_verdict": "violated"}
        over = self.tool({"verdict": "return", "divergences": [div] * 4})
        fine = self.tool(json.dumps({"verdict": "accept", "divergences": []}))         # a JSON string is parsed
        answer, _c, _n, summary, _e, unusable = review.join_passes([over, fine], TWO, ["v"], 3)
        self.assertEqual([k for k, _w in unusable], [1])
        self.assertEqual(len(summary[0]["items"]), 4)
        self.assertEqual(answer["verdict"], "accept")


class WordLevel(unittest.TestCase):
    def test_an_item_not_in_its_span_is_not_judged(self):
        a, _b = two_nodes()
        self.assertEqual(review.word_level_defects(a, TWO, {"span": "s1", "words": "red marker"}), [])
        self.assertTrue(review.word_level_defects(a, TWO, {"span": "s1", "words": "blue marker"}))
        self.assertTrue(review.word_level_defects(a, TWO, {"span": "s9", "words": "red marker"}))


class Streak(unittest.TestCase):
    def test_a_satisfied_case_resets_its_streak(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l.jsonl", ["L"], 2, repeat_limit=3)
            led.record_outcomes("L", ["behaviour:case:a"]); led.record_outcomes("L", ["behaviour:case:a"])
            led.reset_outcomes("L", ["behaviour:case:a"])
            self.assertEqual(led.record_outcomes("L", ["behaviour:case:a"]), [])
            led.record_outcomes("L", ["behaviour:case:a"])
            self.assertEqual(led.record_outcomes("L", ["behaviour:case:a"]), ["behaviour:case:a ×3"])



class ConceptChallenges(unittest.TestCase):
    """A concept challenge is read at `at`; nat formals are instantiated; upheld challenges are
    replayed through a typed formal correspondence."""
    def rec(self, **kw):
        from harness.model.blueprint import ConceptRecord
        return ConceptRecord({"concept_id": "drv.motion.x_v2", "kind": "formula", "contract": "c holds",
                              "args": [{"name": "u", "sort": "track"}, {"name": "n", "sort": "nat"}], "params": [], **kw})

    def div(self, **kw):
        return {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "nats": {"n": 2}, "params": {}}, "grounding": {"u": 1},
                "trace": {"scenes": [{"t": 0}, {"t": 100}]}, "at": 100, **kw}

    def test_at_must_be_an_observation_and_nats_are_filled(self):
        rec = self.rec()
        self.assertEqual(review.concept_divergence_defects(1, self.div(), rec, "c holds"), [])
        self.assertTrue(review.concept_divergence_defects(1, self.div(at=50), rec, "c holds"))
        self.assertTrue(review.concept_divergence_defects(1, self.div(instance={"literals": {}, "params": {}}), rec, "c holds"))

    def test_a_superseded_concepts_challenge_is_replayed_only_through_its_formals(self):
        with tempfile.TemporaryDirectory() as t:
            run = SimpleNamespace(dir=Path(t), iteration=2, iter=Path(t) / "iter-002", reading_file=Path(t) / "reading.json",
                                  all_nodes=lambda: {}, all_concepts=lambda: {})
            run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
            old = {"key": "concept:drv.motion.x", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld", "obligation": "open",
                   "subject": "drv.motion.x", "iteration": 1, "case_id": "k1", **{f: v for f, v in self.div().items()}}
            review.append_ruling(run, old)
            review.append_ruling(run, {**old, "case_id": "k2", "grounding": {"w": 1}})            # an argument the new concept lacks
            ran = []
            saved = review.execute_concept_divergences
            review.execute_concept_divergences = lambda rec, a, out, dim, reading=None, **_k: (ran.extend(a["divergences"]) or ([], [], [], []))
            try:
                rep = review.replay_concept(run, self.rec(supersedes="drv.motion.x"), Path(t) / "r", None, "b")
            finally:
                review.execute_concept_divergences = saved
            self.assertEqual(len(ran), 1)                                   # the corresponding one is run
            self.assertEqual([c["case_id"] for c in rep.carry], ["k2"])     # the other is an obligation to carry over
            self.assertIn("do not correspond", rep.carry[0]["why"])


class DependencyReports(unittest.TestCase):
    """A coder's report that a concept it reaches is wrong is adjudicated before anyone is charged."""
    CONCEPT = {"concept_id": "drv.motion.x", "kind": "formula", "contract": "c holds", "args": [{"name": "u", "sort": "track"}],
               "params": [], "body_json": {"tt": True}}

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        d = Path(self.tmp.name)
        self.run = SimpleNamespace(dir=d, iteration=3, iter=d / "iter-003", reading_file=d / "reading.json", all_nodes=lambda: {},
                                   all_concepts=lambda: {"drv.motion.x": self.CONCEPT})
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
        self.saved = (review.execute_concept_divergences, review.adjudicate_concept, review.concept_blocks)
        review.concept_blocks = lambda run, rec, extras: ({}, "", "")

    def tearDown(self):
        review.execute_concept_divergences, review.adjudicate_concept, review.concept_blocks = self.saved
        self.tmp.cleanup()

    def report(self, **kw):
        d = {"concept_id": "drv.motion.x", "kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
             "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0, **kw}
        (Path(self.tmp.name) / "dependency_defect.json").write_text(json.dumps(d))

    def judge(self, reached={"drv.motion.x"}):
        return review.dependency_report(self.run, Path(self.tmp.name), reached)

    def test_no_report_unreached_and_agreeing(self):
        self.assertEqual(self.judge().status, "none")
        self.report()
        self.assertEqual(self.judge(reached=set()).status, "protocol")
        review.execute_concept_divergences = lambda *a, **k: ([], ["divergence 1: the body agrees"], [], [])
        self.assertEqual(self.judge().status, "protocol")

    def test_upheld_and_dismissed(self):
        self.report()
        item = {"line": "the case", "div": {}}
        review.execute_concept_divergences = lambda *a, **k: ([item], [], [], [])
        review.adjudicate_concept = lambda *a, **k: [(item, "upheld", "the contract excludes it")]
        self.assertEqual(self.judge().status, "upheld")
        review.adjudicate_concept = lambda *a, **k: [(item, "dismissed", "the contract admits it")]
        self.assertEqual(self.judge().status, "dismissed")

    def test_a_defective_version_is_refused_and_charged_once(self):
        from harness.checks import validate_a
        from harness.store.ledger import Ledger
        from harness.model.blueprint import Node
        n = Node({"node_id": "L_1", "law_refs": ["L-1"], "elements": [{"span": "s1", "derived": ["drv.motion.x"]}], "operationalizations": []})
        onto = SimpleNamespace(knows=lambda i: False, primitive_ids=set(), atom_ids=set())
        errs, _g = validate_a.check_closed_set(n, onto, {"drv.motion.x"}, {"drv.motion.x": {"kind": "concept", "reason": "dependency_defect"}})
        self.assertTrue(any("found defective" in e for e in errs))
        led = Ledger(Path(self.tmp.name) / "l.jsonl", ["L-1"], 3); led.attempt = 1
        led.mark_planned("L-1", ["L_1"], 1)
        led.return_for_concepts("L-1", ["drv.motion.x"], ["defective"], 1)
        led.attempt = 2; led.mark_planned("L-1", ["L_1"], 2)
        led.return_for_concepts("L-1", ["drv.motion.x"], ["defective again"], 2)
        self.assertEqual((led.entries["L-1"].attempts, led.entries["L-1"].dependency_returns), (0, 1))

# ---------------------------------------------------------------------------------------------
# Every name a case formula holds is renamed, in scope, and recorded cases are repaired on read
# ---------------------------------------------------------------------------------------------
def at(a, *args):
    return {"atom": a, "args": [{"var": x} for x in args], "params": []}


def every_site(veh="v", lane="lane", u="u", r="r", k="k"):
    """A case using each place a formula names a variable: a user quantifier of each kind, a
    region quantifier, an aggregate, a path window's vehicle, `distance_while` and a rule map."""
    return {"and": [
        at("ru_motor_vehicle", veh),
        {"forall_user": u, "body": {"or": [{"same": [{"var": u}, {"var": veh}]}, at("ru_pedestrian", u)]}},
        {"exists_user": u, "body": at("rel_occupies", u, lane)},
        {"forall_region": {"lit": "lane"}, "var": r, "body": {"not": at("rel_occupies", veh, r)}},
        {"cmp": "ge", "lhs": {"aggregate": "count", "var": k, "where": at("rel_occupies", k, lane), "of": {"lit": 1}}, "rhs": {"lit": 0}},
        {"holds_for": "path", "length": {"lit": 5}, "subject": veh, "body": at("rel_occupies", veh, lane)},
        {"cmp": "le", "lhs": {"distance_while": veh, "holds": at("rel_occupies", veh, lane)}, "rhs": {"lit": 9}},
        {"rule": "R_1", "map": {"w": veh}}]}


class CaseNames(unittest.TestCase):

    D = {"entities": {"lane": {"kind": "region", "id": 10}}, "grounding": {"v": 1}}

    def consistent(self, case, outer):
        """Every name the case uses is declared by a binder of the case or is one of `outer`."""
        free, _declared = review.case_names(case)
        self.assertLessEqual(set(free), set(outer), case)

    def test_every_site_is_renamed_and_stays_consistent(self):
        c = review.canonical_case(self.D, every_site(), ["v"])
        self.consistent(c["case"], {"user1", "region1"})
        text = json.dumps(c["case"])
        for as_written in ('"v"', '"u"', '"r"', '"k"', '{"var": "lane"}'):          # `{"lit": "lane"}` is a kind, not a name
            self.assertNotIn(as_written, text)
        self.assertEqual(set(c["entities"]), {"region1"})
        self.assertEqual(c["case"]["and"][7]["map"], {"w": "user1"})            # a map's key names the other rule's binder

    def test_a_renaming_of_every_name_changes_nothing(self):
        a = review.canonical_case(self.D, every_site(), ["v"])
        b = review.canonical_case({"entities": {"way": {"kind": "region", "id": 10}}, "grounding": {"car": 1}},
                                  every_site(veh="car", lane="way", u="other", r="strip", k="who"), ["car"])
        self.assertEqual(a["case"], b["case"])

    def test_a_binder_may_shadow_a_free_name(self):
        shadow = {"and": [at("ru_motor_vehicle", "v"), {"exists_user": "v", "body": at("ru_pedestrian", "v")}]}
        c = review.canonical_case({"grounding": {"v": 1}}, shadow, ["v"])["case"]
        self.assertEqual(c["and"][0]["args"], [{"var": "user1"}])
        inner = c["and"][1]
        self.assertNotEqual(inner["exists_user"], "user1")
        self.assertEqual(inner["body"]["args"], [{"var": inner["exists_user"]}])

    def replayed(self, binders):
        c = review.canonical_case(self.D, every_site(), ["v"])
        row = {"case": c["case"], "entities": c["entities"], "grounding": c["grounding"], "kind": "k", "at": 0}
        node_case, why = review._to_node(row, binders)
        self.assertEqual(why, "")
        return node_case

    def test_the_next_nodes_binder_names_are_never_captured(self):
        for name in ("x1", "region1", "veh"):
            got = self.replayed([name])
            self.consistent(got["case"], {name, *got["entities"]})
            self.assertEqual(got["grounding"], {name: 1})
            self.assertEqual(got["case"]["and"][0]["args"], [{"var": name}])
            _free, declared = review.case_names(got["case"])
            self.assertNotIn(name, declared)
            self.assertNotIn(name, got["entities"])

    def test_the_same_facts_compare_equal_whatever_the_bound_names(self):
        f = lambda u: review._grounded_conjuncts({"forall_user": u, "body": at("ru_pedestrian", u)}, {}, {})
        self.assertEqual(f("a"), f("b"))


def broken_row(**extra):
    """A case recorded before every name was renamed: its `var` fields canonical, the declaration of
    its user quantifier and its window's vehicle as written."""
    return {"case": {"and": [at("ru_motor_vehicle", "user1"),
                             {"forall_user": "road_user", "body": {"same": [{"var": "x1"}, {"var": "user1"}]}},
                             {"holds_for": "path", "length": {"lit": 5}, "subject": "v", "body": at("rel_occupies", "user1", "region1")}]},
            "names": {"user1": "v", "region1": "lane", "x1": "road_user"}, "grounding": {"user1": 1},
            "entities": {"region1": {"kind": "region", "id": 10}}, **extra}


class RecordedNames(unittest.TestCase):

    def test_a_recorded_case_is_repaired_once(self):
        row, changed = review.repair_case_names(broken_row())
        self.assertTrue(changed)
        self.assertEqual(row["case"]["and"][1]["forall_user"], "x1")
        self.assertEqual(row["case"]["and"][2]["subject"], "user1")
        self.assertEqual(review.case_names(row["case"])[0], ["user1", "region1"])
        self.assertEqual(review.repair_case_names(row), (row, False))

    def test_a_consistent_case_is_left_alone(self):
        c = review.canonical_case(CaseNames.D, every_site(), ["v"])
        row = {"case": c["case"], "names": c["names"], "grounding": c["grounding"], "entities": c["entities"]}
        self.assertEqual(review.repair_case_names(row), (row, False))

    def rows(self, *extra):
        up = broken_row(ruling_id="a", ruling="upheld", obligation="open", subject="L_1", key="law:L-1", schema=review.CASE_SCHEMA, case_id="c1")
        inv = broken_row(ruling_id="b", supersedes="a", ruling="advisory", obligation="invalidated", route="invalidated",
                         subject="L_1", key="law:L-1", schema=review.CASE_SCHEMA, case_id="c1", reason="case: case: variable `x1` is not bound")
        return [up, inv, *extra]

    def run_with(self, rows, t):
        run = SimpleNamespace(dir=Path(t))
        (Path(t) / "rulings.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
        return run

    def test_an_invalidation_the_names_caused_is_set_aside_through_selection(self):
        with tempfile.TemporaryDirectory() as t:
            got = review.upheld_rows(self.run_with(self.rows(), t), {"L-1"})
            self.assertEqual([r["ruling_id"] for r in got], ["a"])
            self.assertEqual(got[0]["case"]["and"][1]["forall_user"], "x1")         # repaired for its replay

    def test_a_row_that_superseded_it_supersedes_what_it_superseded(self):
        later = broken_row(ruling_id="c", supersedes="b", ruling="upheld", obligation="satisfied", subject="L_1",
                           key="law:L-1", schema=review.CASE_SCHEMA, case_id="c1")
        with tempfile.TemporaryDirectory() as t:
            got = review.upheld_rows(self.run_with(self.rows(later), t), {"L-1"})
            self.assertEqual([(r["ruling_id"], r["supersedes"]) for r in got], [("c", "a")])

    def test_another_invalidation_stands(self):
        with tempfile.TemporaryDirectory() as t:
            up, inv = self.rows()
            undecodable = {**inv, "reason": "case: the trace does not decode"}
            self.assertEqual(review.upheld_rows(self.run_with([up, undecodable], t), {"L-1"}), [])
        with tempfile.TemporaryDirectory() as t:
            up, inv = self.rows()
            fixed_up = review.repair_case_names(up)[0]
            consistent_inv = {**review.repair_case_names(inv)[0]}           # its names were never the cause
            self.assertEqual(review.upheld_rows(self.run_with([fixed_up, consistent_inv], t), {"L-1"}), [])

    def test_a_retired_case_stays_retired(self):
        with tempfile.TemporaryDirectory() as t:
            up, inv = self.rows()
            retired = {"ruling_id": "r", "supersedes": "a", "ruling": "retired", "subject": "L_1", "key": "law:L-1"}
            self.assertEqual(review.upheld_rows(self.run_with([up, retired], t), {"L-1"}), [])


# ---------------------------------------------------------------------------------------------
# One current state per obligation: replays keep the identity they replay
# ---------------------------------------------------------------------------------------------
TRACE = {"scenes": [{"t": 0, "users": [{"track": 1}]}]}


def case_row(rid, case_id, duty, *, lineage="L", case=None, obligation=None, iteration=1, **extra):
    return {"ruling_id": rid, "case_id": case_id, "duty": duty, "lineage": lineage, "key": "law:L-2", "subject": "L_2_o1",
            "schema": review.CASE_SCHEMA, "ruling": "upheld", "obligation": obligation, "iteration": iteration, "trace": TRACE,
            "at": 0, "grounding": {"user1": 1}, "entities": {}, "case": case or at("ru_pedestrian", "user1"), **extra}


class OneStateEach(unittest.TestCase):

    def effective(self, rows):
        return [(r["ruling_id"], r.get("obligation")) for r in review.effective_rows(rows)]

    def test_a_rehashed_state_of_one_obligation_replaces_the_older(self):
        rows = [case_row("a", "old-id", "D"), case_row("b", "new-id", "D", obligation="satisfied", iteration=2)]
        self.assertEqual(self.effective(rows), [("b", "satisfied")])

    def test_the_duty_it_was_carried_from_is_kept(self):
        rows = [case_row("a", "old-id", "D", lineage_from="src|S"), case_row("b", "new-id", "D", obligation="satisfied")]
        self.assertEqual(review.effective_rows(rows)[0]["lineage_from"], "src|S")

    def test_a_split_keeps_each_target_duty_and_the_source(self):
        n1, n2 = two_nodes()
        d1, d2 = review.duty_of(n1, TWO), review.duty_of(n2, TWO)
        whole = [[0, len(TWO.text)]]
        src = case_row("s", "c1", "L-2@old:0-80", duty_ranges=whole, law_digest=d1["law_digest"])
        carried = lambda rid, d, n: case_row(rid, "c1x", d["id"], subject=n.id, obligation="satisfied", iteration=2,
                                            lineage_from="c1|L-2@old:0-80", duty_ranges=d["ranges"], law_digest=d["law_digest"])
        for order in ((d1, n1, d2, n2), (d2, n2, d1, n1)):
            rows = [src, carried("x", order[0], order[1]), carried("y", order[2], order[3])]
            with tempfile.TemporaryDirectory() as t:
                (Path(t) / "rulings.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
                run = SimpleNamespace(dir=Path(t))
                for n, d in ((n1, d1), (n2, d2)):
                    got = review.obligations_of(run, n, TWO)
                    self.assertEqual([(r["duty"], own) for r, own in got], [(d["id"], True)], n.id)

    def test_an_extension_written_before_the_old_cases_marker_stays(self):
        more = {"and": [at("ru_pedestrian", "user1"), at("ru_motor_vehicle", "user1")]}
        rows = [case_row("old", "c1", "D"),
                case_row("ext", "c2", "D", case=more, obligation="open", predecessor="old"),
                case_row("mark", "c1", "D", obligation="extended", supersedes="old")]
        self.assertEqual(self.effective(rows), [("ext", "open"), ("mark", "extended")])

    def test_a_retired_obligation_does_not_revive_its_older_state(self):
        rows = [case_row("a", "old-id", "D"), case_row("b", "new-id", "D", obligation="satisfied"),
                {"ruling_id": "r", "supersedes": "b", "ruling": "retired", "key": "law:L-2", "subject": "L_2_o1"}]
        self.assertEqual(self.effective(rows), [])

    def test_an_inherited_state_and_an_own_state(self):
        rows = [case_row("A/a", "old-id", "D", inherited_from="A"), case_row("b", "new-id", "D", obligation="satisfied")]
        self.assertEqual(self.effective(rows), [("b", "satisfied")])

    def test_other_facts_are_another_obligation(self):
        rows = [case_row("a", "c1", "D"), case_row("b", "c2", "D", case=at("ru_motor_vehicle", "user1"))]
        self.assertEqual(len(review.effective_rows(rows)), 2)


class ReplayTransition(unittest.TestCase):
    """The real replay of a node's own obligation recorded under an identity that today's names
    hash differently: certification and the judges are scripted, naming, selection, routing and
    supersession are the harness's own."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.n = two_nodes()[0]
        self.duty = review.duty_of(self.n, TWO)
        self.run = SimpleNamespace(dir=Path(self.tmp.name), iteration=2)
        old = case_row("a", "recorded-before", self.duty["id"], subject=self.n.id, iteration=1, kind="rule_forbids_lawful",
                       stage_a={"verdict": "compliant", "decisive": True, "law_words": "shall stop"}, stageA_digest="old-digest")
        (Path(self.tmp.name) / "rulings.jsonl").write_text(json.dumps(old) + "\n")
        self.calls = 0
        def stage_a(*_a, **_k):
            self.calls += 1
            return {"verdict": "compliant", "decisive": True, "law_words": "shall stop"}
        cert = {"canonical_case": at("ru_pedestrian", "v"), "case_atoms": [], "rule_result": {"verdict": "compliant"}}
        self.patches = [mock.patch.object(review, "certify", lambda _r, _n, divs, *_a, **_k: {k: cert for k in divs}),
                        mock.patch.object(review, "admission", lambda *_a: ("judge", [])),
                        mock.patch.object(review, "run_stage_a", stage_a),
                        mock.patch.object(review, "stage_a_digest", lambda *_a: "digest"),
                        mock.patch.object(review, "stage_a_prompt", lambda *_a: "prompt"),
                        mock.patch.object(review, "_case_glosses", lambda *_a: {})]
        for x in self.patches:
            x.start()
        self.ctx = review.Context(law=TWO, seg="", definitions=[], record={}, rendering="", rule_glosses={}, params=[],
                                  aggregates=[], precedence_hash="", duty=self.duty)

    def tearDown(self):
        for x in self.patches:
            x.stop()
        self.tmp.cleanup()

    def replay(self):
        return review.replay_obligations(self.run, self.n, self.ctx, None, None, None, Path(self.tmp.name) / "out")

    def rows(self):
        return [json.loads(l) for l in (Path(self.tmp.name) / "rulings.jsonl").read_text().splitlines()]

    def test_the_satisfied_state_supersedes_the_obligation_it_replayed(self):
        self.replay()
        rows = self.rows()
        self.assertEqual(len(rows), 2)
        self.assertEqual((rows[1]["case_id"], rows[1]["supersedes"], rows[1]["obligation"]), ("recorded-before", "a", "satisfied"))
        self.assertEqual([r["ruling_id"] for r in review.upheld_rows(self.run, {"L-2"})], [rows[1]["ruling_id"]])

    def test_a_second_unchanged_replay_adds_no_row_and_no_judge_call(self):
        self.replay()
        calls, n = self.calls, len(self.rows())
        self.replay()
        self.replay()
        self.assertEqual((self.calls, len(self.rows())), (calls, n))


# ---------------------------------------------------------------------------------------------
# Stage A sees the same duties however a segmentation cuts the same words
# ---------------------------------------------------------------------------------------------
class DutyBlock(unittest.TestCase):

    def test_two_cuts_of_the_same_sibling_words_render_alike(self):
        n1, _ = two_nodes()
        recut = Node({**n1.raw, "segmentation": n1.raw["segmentation"][:3] + [
            {"id": "s4", "role": "sibling", "text": "At a blue marker the driver"},
            {"id": "s5", "role": "sibling", "text": "shall stop."}]})
        self.assertEqual(review.duty_block(n1, TWO), review.duty_block(recut, TWO))
        self.assertEqual(review.duty_of(n1, TWO)["id"], review.duty_of(recut, TWO)["id"])   # the duty's identity is untouched

    def test_words_of_the_node_between_siblings_keep_them_apart(self):
        self.assertEqual(review.merged_ranges("a b. c d", [(0, 1), (2, 3), (7, 8)]), [(0, 3), (7, 8)])


if __name__ == "__main__":
    unittest.main()
