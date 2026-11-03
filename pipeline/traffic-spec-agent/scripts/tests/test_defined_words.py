"""The rule on words a posted definition defines reaches every session that plans a node, both ways:
a definition's exclusions are carried, and the law's own qualifying words still limit which of the
defined members the duty reads. Checked on the node-repair prompt as the harness renders it, beside
a posted definition that excludes something, and on the plan prompt, which states the same rule."""
import re
import shutil
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness.agents import render
from harness.model import corpus
from harness.phases import plan as plan_phase
from harness.store import paths
from harness.store.gaps import GapLedger
from scripts.tests.test_operator_decisions import record, LAW
from scripts.tests.test_review_routing import ONTO

DEFINITION = {"id": "DEF-STA-900A-050", "title": "Junction defined", "source": "STA 900A.050",
              "text": "“Junction” means the area where two ways meet. The meeting of a lane with a way is not a junction."}
OPENING = "A word a posted definition defines is read with that definition's inclusions and exclusions"
EXCLUSIONS = ("an exclusion that the contract of the atom or concept does not already make is carried by the rule as a "
              "condition beside it")
QUALIFIERS = "The law's own words that qualify the word"
LIMIT = "limit which of its members the duty reads: the justification quotes them and names the members they leave out."


def flat(text: str) -> str:
    return " ".join(text.split())


def rule_of(text: str) -> str:
    """The rule as a prompt states it, from its opening words to the end of its qualifier sentence;
    empty when the prompt does not state it."""
    m = re.search(re.escape(OPENING) + r".*?" + re.escape(LIMIT), flat(text))
    return m.group(0) if m else ""


def two_way(text: str) -> bool:
    rule = rule_of(text)
    return EXCLUSIONS in rule and QUALIFIERS in rule


def rendered_repair(prompts: Path | None = None) -> str:
    """The node-repair prompt `run_node_repair` writes, with the pieces outside the template stubbed
    and one posted definition that applies to the law."""
    with tempfile.TemporaryDirectory() as t:
        d = Path(t) / "run"
        run = NS(iter=d, dir=d, iteration=2, mapping_file=d / "mapping.json",
                 opts=NS(dry_run=True, run_id="t", laws=d / "laws.jsonl"), all_nodes=lambda: {}, all_concepts=lambda: {})
        last = d / "last"
        last.mkdir(parents=True)
        with mock.patch.object(paths, "PROMPTS", prompts or paths.PROMPTS), \
                mock.patch.object(plan_phase, "definitions_for", lambda _run, _laws: [DEFINITION]), \
                mock.patch.object(plan_phase, "GapLedger", NS(for_run=lambda *_a: NS(cited_block=lambda _r: ""))), \
                mock.patch.object(plan_phase, "repair_context", lambda *_a: ""), \
                mock.patch.object(plan_phase.review_phase, "upheld_block", lambda *_a, **_k: ""), \
                mock.patch.object(plan_phase, "parameter_catalogue", lambda *_a: ""), \
                mock.patch.object(plan_phase, "declaration_catalogue", lambda *_a: ""), \
                mock.patch.object(plan_phase.surface, "formula_language", lambda: ""), \
                mock.patch.object(plan_phase.surface, "concept_language", lambda: ""), \
                mock.patch.object(plan_phase.surface, "concepts_table", lambda *_a: ""):
            out = plan_phase.run_node_repair(run, record({"span": "s2", "why": "w"}), ["r"], last, LAW, [], [], NS(), ONTO)
            return (out / "prompt.md").read_text(encoding="utf-8")


def with_template(text: str) -> Path:
    """A copy of the prompts directory in which `node_repair.md` reads `text`."""
    t = Path(tempfile.mkdtemp())
    shutil.copytree(paths.PROMPTS, t / "prompts")
    (t / "prompts" / "node_repair.md").write_text(text, encoding="utf-8")
    return t / "prompts"


class DefinedWords(unittest.TestCase):

    def test_the_repair_prompt_states_the_rule_both_ways_beside_the_definition(self):
        text = rendered_repair()
        self.assertIn("## Definitions that apply", text)
        self.assertIn("The meeting of a lane with a way is not a junction.", text)
        self.assertTrue(two_way(text))
        self.assertEqual(flat(text).count(OPENING), 1)

    def test_the_plan_and_the_repair_state_the_same_rule(self):
        plan = (paths.PROMPTS / "plan.md").read_text(encoding="utf-8")
        self.assertTrue(two_way(plan))
        self.assertEqual(rule_of(plan), rule_of(rendered_repair()))

    def test_a_repair_prompt_without_the_rule_or_with_one_half_fails(self):
        source = (paths.PROMPTS / "node_repair.md").read_text(encoding="utf-8")
        rule = rule_of(source)
        self.assertTrue(rule)
        flat_source = flat(source)
        one_way = rule.split(" " + QUALIFIERS)[0]
        for variant in (flat_source.replace(rule + " ", ""), flat_source.replace(rule, one_way)):
            prompts = with_template(variant)
            try:
                self.assertFalse(two_way(rendered_repair(prompts)))
            finally:
                shutil.rmtree(prompts.parent)


if __name__ == "__main__":
    unittest.main()
