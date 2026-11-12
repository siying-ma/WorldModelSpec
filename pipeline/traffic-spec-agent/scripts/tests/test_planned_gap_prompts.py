"""The plan, code and node repair prompts state the contract of a record that carries a gap: it
is not coded, its gaps are filed when it is registered and block its law until a later validated
record carries the span without them, and a record that answers a decided gap names it in
`gap_resolutions`. The sentences of the contract they replaced are gone."""
import re
import unittest

from harness.store import paths


def prompt(name: str) -> str:
    text = (paths.PROMPTS / name).read_text(encoding="utf-8")
    return " ".join(text.split())


class PromptTexts(unittest.TestCase):
    """The three prompts state the contract above, and no longer the one it replaced."""
    PRESENT = {
        "plan.md": [
            "A gap is not a carrier: it annotates a span that an element or an operationalization maps to its nearest atoms (step 6) "
            "only to show why they do not carry the span's distinction, never as the way the span is coded. A node that carries a gap "
            "is not coded, and its law stays blocked until a later record, validated, carries the span without that gap.",
            "and map the span to those nearest atoms or concepts only so that every span is accounted for: they show why the "
            "vocabulary falls short, never how the span is coded. A node that carries a gap is not coded: its gaps are filed when it is "
            "registered, and its law stays blocked until a later record, validated, carries the span without that gap. Propose a gap "
            "only where no atom, concept or allowed reading carries the words.",
            "A gap a node carries is filed when the node is registered, and blocks its law until a later record, validated, carries "
            "the span without that gap; the coding session does not write that node. Where a record carries no gap on a span and the "
            "coding session cannot write the span with the atoms and operators you map it to, it declares the span unstatable and the "
            "node goes to its repair session, which re-maps the span or withdraws it as a gap; a second such declaration on the same "
            "words files the gap. Nothing else is a gap.",
            "A gap the operator has retired or rejected is answered by a record that carries its words without it. Such a record "
            "names, in `gap_resolutions`, each such gap: its id, the span that now carries the words, and the basis of the new "
            "representation (the atom or revision that retired it, or the reading the rejection allows). A record that leaves out "
            "the gap of an earlier record on the same words of the law, without naming a gap the operator has decided, is returned.",
            "gap_resolutions[{gap, span, basis}]",
        ],
        "node_repair.md": [
            "its nearest atoms with a gap. A record that carries a gap is not coded: its gaps are filed and block the law until a "
            "later record, validated, carries the span without that gap. A record that answers a decided gap names it in "
            "`gap_resolutions` as the plan does.",
            "gap_resolutions[{gap, span, basis}]",
        ],
        "code.md": [
            "are a defect of the node's mapping: you never declare `no_atom` on them",
        ],
    }
    ABSENT = {
        "plan.md": ["the coding session tries them, and the gap is filed only if it confirms",
                    "only when the coding session confirms the span cannot be written",
                    "carries with its nearest atoms (step 6). Two"],
        "code.md": ["Where the record carries a gap on a span", "files the plan's gap at once",
                    "whether or not the record carries a gap on the span"],
        "node_repair.md": [],
    }

    def test_the_new_texts_are_present_and_the_old_ones_gone(self):
        for name, texts in self.PRESENT.items():
            body = prompt(name)
            for t in texts:
                self.assertIn(t, body, f"{name}: {t[:60]}")
            for t in self.ABSENT[name]:
                self.assertNotIn(t, body, f"{name}: {t[:60]}")

    def test_the_prompts_render(self):
        from harness.agents import render
        for name in ("plan.md", "code.md", "node_repair.md"):
            raw = (paths.PROMPTS / name).read_text(encoding="utf-8")
            out = render.render(name, {k: "" for k in set(re.findall(r"\{([a-z_]+)\}", raw))})
            self.assertIn("gap_resolutions" if name != "code.md" else "no_atom", out)


if __name__ == "__main__":
    unittest.main()
