"""Cross-check every agent-facing claim against the artifact it describes.

The pipeline's output quality depends on prose artifacts — the prompt templates,
the frozen ontology, the Core docstrings — that describe things they do not own:
the Lean core, the gate's verdict set, the witness roles, the coverage statuses.
Prose drifts. Every check here compares a description with the thing described
and names both sources on failure, so a failure is actionable without re-deriving
what was compared.

The frozen artifacts (Core, the ontology, the prompts) are fixed BEFORE the
pipeline sees any law corpus or records any capture, and two checks hold them to
that: no statute, no rule named by its subject, no figure from a capture.

Run it as `python -m scripts.run_spec doctor`. Exit status is 1 if any check
fails, so it belongs in CI. No model, no Lean, no simulator.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

from .doctor_result import Result, OK, FAIL, SKIP, VacuousCheck, _nonempty  # noqa: F401
from .library_v2 import LibraryV2Checks


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _read_opt(path: Path) -> str:
    """The file's text, or empty when it does not exist (a v1 artifact the redraft removed)."""
    return path.read_text(encoding="utf-8") if path.exists() else ""



def _format_kwargs(src: str, marker: str = "template.format(") -> set[str]:
    """Keyword names passed to a `template.format(...)` call."""
    if marker not in src:
        return set()
    body, depth, out = src.split(marker, 1)[1], 1, []
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                break
        out.append(ch)
    return set(re.findall(r"(\w+)\s*=", "".join(out)))


# Vocabulary that only appears in a file written with a particular law, rule, or
# capture in view. Shared by the frozen artifacts and by the prompt templates:
# both are fixed BEFORE the pipeline sees a corpus or records anything, so
# neither may name a statute, a rule, or a figure obtained by running the
# simulator. Each pattern is chosen so that a legitimate DISCLAIMER does not
# trip it — a file may say a threshold is a statute's business, but may not
# quote one.
# This file lives in `scripts/diagnostics/`, so three hops reach the repo root.
REPO_ROOT = Path(__file__).resolve().parent.parent.parent

LAW_FREE_PATTERNS = {
        "rule id": r"\bR\d{4}\b",
        "law id": r"\b[A-Z]{2,}-[A-Z]+-\d{3,}\b",
        "rule path": r"Rules/\w+/\w+",
        "map name": r"\bTown\d+\b",
        "measurement": r"[Mm]easured (?:on|against|across)\b|MEASURED\b"
                       r"|recorded captures?\b",
        # Statutory text quoted verbatim. A deontic verb inside quotation
        # marks is law being cited, not a concept being named.
        "quoted statute": r'"[^"\n]{0,80}?\b(?:shall|must not|no person'
                          r"|no driver|it is an offence)\b[^\"\n]{0,80}?\"",
        # Applying a law to a person. Distinct from naming one: a frozen
        # file may say what it refuses to decide, but not decide it.
        "adjudication": r"\b(?:convict|acquit|prosecut|offence|offense"
                        r"|guilty|culpab)\w*\b",
        # A rule named by its subject matter — "following-distance rule",
        # "stop-on-red rule" — which can only be written once the corpus is
        # known.
        # A compound counting or structuring something ("two-binder rule",
        # "single-clause rule") is about the machinery, not about a subject matter,
        # and is excluded so the check does not push prose around for nothing.
        # A rule named by its subject matter — the whole hyphenated compound, so
        # "right-of-way rules" is caught and not just its tail. Excluded, so the
        # check does not push prose around for nothing: compounds that count or
        # structure something ("two-binder rule") and the machinery ones
        # ("end-of-trace rules"), neither of which names a subject matter.
        "named rule family": r"(?<![-\w])(?!(?:one|two|three|four|multi|single|per"
                            r"|sub|non|no|first|second|last|top|end-of-trace)\b)"
                            r"(?:[a-z]+-)+[a-z]+ rules?\b",
        # Reasoning about how the specification will be graded. The test
        # database does not exist when these files are frozen.
        "evaluation coupling": r"\b(?:capture_eval|capture_bench"
                               r"|agreeing result|scores? it as"
                               r"|the Python side)\b",
}

# Numbers that can only come from having run a capture. A prompt that quotes one
# goes on asserting it after a re-measurement, and the calibration it quotes
# belongs to `tools/check_spec.py`, which renders it into the prompt at run time.
CAPTURE_FIGURE_PATTERNS = {
    "capture length": r"\b\d+[- ]frames?\b(?![^.]*\bat least\b)",
    "entity census": r"\b\d+\s+(?:vehicles|lanes|roads|junctions|traffic lights"
                     r"|pedestrians)\b",
    # A figure obtained by measuring THIS PROJECT'S OWN artifacts — a library, a
    # run, a set of witnesses. Subtler than a capture figure and caught by none
    # of the patterns above, because it names nothing from the scene graph: a
    # prompt read "it held for 55 of 55 such traces while accounting for more
    # than half of all trace-writing work", which was true of one library on one
    # day and is unfalsifiable in the template afterwards. The reason a rule
    # holds belongs in a frozen prompt; the count that showed it does not.
    "own measurement": r"\b\d+\s+of\s+\d+\b"
                       r"|\bmore than half\b"
                       r"|\b(?:most|almost all|nearly all|hardly any)\s+"
                       r"(?:rules|captures|traces|nodes|runs|sessions)\b"
                       r"|\bever recorded\b"
                       r"|\b(?:one|another|a previous|an earlier)\s+run\b",
}

# Only the frozen artifacts. The prompts legitimately name pipeline roles and
# the files a session writes — that is what they are for.
FROZEN_ONLY_PATTERNS = {
        # Pipeline roles and run artifacts. A frozen file that names one asserts
        # a pipeline behaviour it cannot verify.
        "pipeline internals": r"\b(?:plan agent|coding agent"
                              r"|capture_sensor_data|node_report"
                              r"|verdict\.json|PROGRESS\.md)\b",
}

# The ontology is the termination rule and is read by every planning session, so
# it may name no statute, no clause, no corpus, no data source and no figure: a
# section number or a quantity with a unit is a clause leaking in, and a named
# simulator or dataset is a source deciding the vocabulary. Wider than the
# law-free set above because the ontology is prose about the world, where a
# deontic verb or a metre figure has no legitimate place.
ONTOLOGY_PATTERNS = {
    "section reference": r"\bs{1,2}\.\s*\d|\bPart\s*\d|\b\d{3}(?:\.\d+)?(?:\(\d+\))+",
    "deontic verb": r"\b(?:must|shall|may not|must not|is required to|offence|liable|prescribed)\b",
    "figure with unit": r"\b\d+(?:\.\d+)?\s*(?:m|km/h|km|cm|mph|seconds?|secs?|metres?|meters?|hours?)\b|\b1/2\b",
    "named corpus or source": r"\b(?:MVA|Motor Vehicle Act|British Columbia|Vienna|UVC|MUTCD|CARLA|RSV|OpenDRIVE|nuPlan|Waymo)\b",
}

class Doctor:
    def __init__(self, repo_root: Path, library_root: Path):
        self.repo = repo_root
        self.lib = library_root
        core = library_root / "TrafficSpec" / "Core"
        #: The v1 library (Vocab.lean, the SPAN/SCEN report) is gone; the checks that describe it
        #: are skipped until the gate and the prompts are redrafted against Core v2.
        self.v1_library = (core / "Vocab.lean").exists()
        self.vocab = _read_opt(core / "Vocab.lean")
        self.grounding = _read_opt(core / "Grounding.lean")
        self.v2 = LibraryV2Checks(repo_root, library_root)
        self.gate = _read(repo_root / "tools" / "check_spec.py")
        self.prompt_code = _read(repo_root / "prompts" / "prompt_code.md")
        self.prompt_plan = _read(repo_root / "prompts" / "prompt_plan.md")

    def predicates_exist(self) -> Result:
        defined = _nonempty(set(re.findall(r"^\s*(?:private )?def (\w+)", self.vocab, re.M)),
                            "Vocab.lean predicate definitions")
        named = _nonempty(set(re.findall(r"Pred\.(\w+)",
                              self.prompt_code + self.prompt_plan)),
                          "Pred.* references in the prompts")
        ghosts = sorted(n for n in named - defined if n not in ("attr", "attrMilli"))
        src = ("prompts/*.md → Pred.* references",
               "library/TrafficSpec/Core/Vocab.lean → def")
        if ghosts:
            return Result("predicate references", FAIL,
                          f"named but not defined: {ghosts}", src)
        return Result("predicate references", OK,
                      f"all {len(named)} references resolve", src)

    def verdicts_documented(self) -> Result:
        emitted = {v for v in
                   set(re.findall(r'emit\("([A-Z_]+)"', self.gate))
                   | set(re.findall(r'finish\("([A-Z_]+)"', self.gate))
                   if v != "OK"}
        emitted = _nonempty(emitted, "verdict tokens in check_spec.py")
        table = _nonempty(set(re.findall(r"\|\s*`([A-Z_]+)`\s*\|", self.prompt_code)),
                          "the verdict table in prompt_code.md")
        src = ("tools/check_spec.py → emit()/finish()",
               "prompts/prompt_code.md → the verdict branch table")
        if emitted - table:
            return Result("verdict coverage", FAIL,
                          f"emitted but undocumented: {sorted(emitted - table)} — "
                          f"the agent receives these with no instruction", src)
        # And the other direction: a row for a verdict the gate cannot produce is
        # a branch the agent may plan around and never reach. Both halves are the
        # same failure — a description that no longer matches the thing.
        # `OK` is filtered out of `emitted` above and is legitimately a row.
        if table - emitted - {"OK"}:
            return Result("verdict coverage", FAIL,
                          f"documented but never emitted: {sorted(table - emitted - {'OK'})}"
                          f" — a branch the gate cannot reach", src)
        return Result("verdict coverage", OK,
                      f"all {len(emitted)} verdicts have a branch, and no "
                      f"branch is stale", src)

    def report_tags_parsed(self) -> Result:
        produced = _nonempty(set(re.findall(r's!"([A-Z]+)\\t', self.grounding)),
                             "report tags emitted by Grounding.lean")
        parsed = _nonempty(set(re.findall(r'tag == "([A-Z]+)"', self.gate)),
                           "report tags parsed by NodeReport")
        # These are emitted for humans and deliberately ignored by the parser.
        informational = {"NODE", "NAME", "LAWREFS", "SCENARIOS"}
        src = ("library/TrafficSpec/Core/Grounding.lean → report()",
               "tools/check_spec.py → NodeReport")
        unparsed = produced - parsed - informational
        if unparsed:
            return Result("report format", FAIL,
                          f"Lean emits {sorted(unparsed)} that NodeReport ignores", src)
        return Result("report format", OK,
                      f"{len(produced)} tags emitted, {len(parsed)} parsed", src)

    # ── prompts ↔ what fills them ───────────────────────────────────────

    def placeholders_supplied(self) -> Result:
        pairs = (("prompts/prompt_code.md", "scripts/phases/code.py"),
                 ("prompts/prompt_plan.md", "scripts/phases/plan.py"))
        bad = []
        for tmpl, filler in pairs:
            ph = _nonempty(set(re.findall(r"\{([a-z_]+)\}", _read(self.repo / tmpl))),
                           f"placeholders in {tmpl}")
            keys = _nonempty(_format_kwargs(_read(self.repo / filler)),
                             f"format kwargs in {filler}")
            if ph - keys:
                bad.append(f"{tmpl}: {sorted(ph - keys)} not supplied by {filler}")
        src = ("prompts/*.md → {placeholders}",
               "scripts/phases/{plan,code}.py → template.format(...)")
        if bad:
            return Result("prompt placeholders", FAIL,
                          "; ".join(bad) + " — would raise KeyError mid-run", src)
        return Result("prompt placeholders", OK,
                      "every placeholder in both templates is supplied", src)

    def example_rule_exists(self) -> Result:
        """The worked-example block names a rule that exists, or names none.

        An empty library is the state everything here is FROZEN in — Core, the
        schema and both prompts are fixed before any law is seen — so "no rule
        to show" is correct rather than broken, and the check is that the block
        the agent receives agrees with the disk either way. What it catches is
        the failure that shipped for a while: a path interpolated into "read
        this finished rule" that resolved to nothing.
        """
        from scripts.phases.plan import pick_example_rule, summarize_example
        src = ("scripts/phases/plan.py → summarize_example()",
               "library/TrafficSpec/Rules/**")
        path = pick_example_rule(self.lib)
        block = summarize_example(self.lib)
        if not path:
            if ".lean" in block:
                return Result("worked example", FAIL,
                              "the library has no rules, but the block still "
                              "names a rule file", src)
            return Result("worked example", SKIP,
                          "library carries no rules yet; the block says so "
                          "instead of naming one", src)
        if not Path(path).exists():
            return Result("worked example", FAIL,
                          f"prompts point at {path}, which does not exist — it is "
                          f"the agent's only in-context source for the notation", src)
        if path not in block:
            return Result("worked example", FAIL,
                          f"{Path(path).name} exists but the rendered block does "
                          f"not name it", src)
        return Result("worked example", OK, f"{Path(path).name}", src)

    def formula_operators(self) -> Result:
        """Every operator the rules use must appear in the generated table."""
        from scripts.phases.plan import summarize_formula
        table = summarize_formula(self.lib)
        rules = "".join(_read(p) for p in
                        (self.lib / "TrafficSpec" / "Rules").rglob("*.lean"))
        ops = ["□", "◇", "◯", "𝒰", "ℛ", "¬ₛ", "⋀", "⋁", "⟹"]
        missing = [o for o in ops if rules.count(o) and o not in table]
        src = ("scripts/phases/plan.py → summarize_formula()",
               "library/TrafficSpec/Core/Formula.lean → scoped notation")
        if missing:
            return Result("formula language", FAIL,
                          f"used by rules but absent from the generated table: {missing}", src)
        used = [o for o in ops if rules.count(o)]
        return Result("formula language", OK,
                      f"{len(used)} operators in use, all shown to the agent", src)

    # ── file links ──────────────────────────────────────────────────────

    #: Path prefixes that name something OUTSIDE this repository. The schema
    #: cites the generator by file and line — that is the point of it (nothing
    #: here may be asserted from memory) — and those files live in
    #: `carla_scene_graphs`, which is not required to be checked out. A bare
    #: basename (`sgg.py`, `actors.py`) is prose for the same reason, so only a
    #: token whose FIRST segment names a real entry of this repo is resolved.
    FOREIGN_PREFIXES = ("carla_sgg/", "carla_scene_graphs/")

    def repo_paths_resolve(self) -> Result:
        """Every in-repo file path named by an agent-facing artifact exists.

        Scoped to the artifacts a session is handed — the repo-root documents,
        the prompt templates and the ontology — and to paths whose first segment
        names an entry of this repository. A pointer that resolves to nothing is
        not an error the agent can see: it reads as a citation, and the claim it
        supports becomes unverifiable.
        """
        sources = sorted(self.repo.glob("*.md")) + \
            sorted((self.repo / "prompts").glob("*.md")) + \
            sorted((self.repo / "ontology").glob("*.md"))
        # A repo-root entry, so `scripts/...` is resolved and `carla_sgg/...`
        # is not. Recomputed from disk: a directory that is added or removed
        # changes what this resolves without an edit here.
        roots = {p.name for p in self.repo.iterdir() if not p.name.startswith(".")}
        token = re.compile(r"[A-Za-z0-9_][A-Za-z0-9_./\-]*\.[A-Za-z]{2,6}\b")
        seen, broken = 0, []
        for doc in sources:
            if not doc.exists():
                broken.append(f"{doc.name}: the source itself is missing")
                continue
            text = doc.read_text(encoding="utf-8", errors="replace")
            for raw in sorted({m.group(0) for m in token.finditer(text)}):
                path = raw.rstrip(".")
                if any(c in path for c in "*{}") or "/" not in path:
                    continue
                if path.startswith(self.FOREIGN_PREFIXES):
                    continue
                if path.startswith("../"):
                    seen += 1
                    if not (self.repo / path).exists():
                        broken.append(f"{doc.name}: {path}")
                    continue
                head = path.split("/", 1)[0]
                if head not in roots and head != "TrafficSpec":
                    continue
                seen += 1
                if not ((self.repo / path).exists()
                        or (self.repo / "library" / path).exists()):
                    broken.append(f"{doc.name}: {path}")
        _nonempty(seen, "file paths in the docs, prompts and ontology")
        src = (f"{', '.join(d.name for d in sources)} \u2192 file paths",
               "resolved against the repo root and library/")
        if broken:
            return Result("file links", FAIL,
                          f"{len(broken)} name nothing on disk: "
                          f"{sorted(set(broken))[:4]}", src)
        return Result("file links", OK,
                      f"{len(sources)} artifact(s), all {seen} in-repo file "
                      f"path(s) resolve", src)

    # ── frozen artifacts ────────────────────────────────────────────────

    def frozen_artifacts_are_law_free(self) -> Result:
        """Core and the ontology carry no law, no rule, and no capture figure.

        Both are frozen BEFORE the pipeline sees a corpus or records anything, so
        neither may reference a particular statute or rule file, and neither may
        state a figure obtained by running a simulator. Such a reference is not
        wrong, it is unfalsifiable later: the rule it cites can be re-formalized
        and the capture re-recorded while the frozen file goes on asserting it.
        Each pattern is chosen so that a legitimate DISCLAIMER does not trip it.
        """
        import itertools
        targets = sorted((self.lib / "TrafficSpec" / "Core").rglob("*.lean")) + \
            sorted((REPO_ROOT / "ontology").glob("*.md")) + \
            sorted((REPO_ROOT / "ontology").glob("*.jsonl"))
        patterns = dict(LAW_FREE_PATTERNS, **FROZEN_ONLY_PATTERNS)
        src = ("library/TrafficSpec/Core/**/*.lean, ontology/*",
               "frozen before any law or capture exists")
        bad = []
        for path in targets:
            if not path.exists():
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in patterns.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("frozen artifacts law-free", FAIL,
                          "; ".join(bad[:5]), src)
        return Result("frozen artifacts law-free", OK,
                      f"{len(targets)} frozen files clear on all "
                      f"{len(patterns)} categories", src)

    def ontology_is_neutral(self) -> Result:
        """The ontology names no statute, no clause, no source and no figure.

        `ATOMS.md` is the whole termination rule and every planning session reads
        it, so a clause leaking into it pre-decides that clause's formalization,
        and a data source named in it lets the source define the vocabulary. The
        law-free check above catches rule and statute vocabulary; this one adds
        what is specific to prose about the world — section numbers, deontic
        verbs, quantities with units, named simulators and datasets.
        """
        import itertools
        files = sorted((self.repo / "ontology").glob("*.md")) + \
            sorted((self.repo / "ontology").glob("*.jsonl"))
        src = ("ontology/*", "frozen before any corpus is seen")
        if not files:
            return Result("ontology neutral", SKIP, "no ontology directory yet", src)
        bad = []
        for path in files:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in ONTOLOGY_PATTERNS.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("ontology neutral", FAIL, "; ".join(bad[:5]), src)
        return Result("ontology neutral", OK,
                      f"{len(files)} file(s) clear on all {len(ONTOLOGY_PATTERNS)} "
                      f"categories", src)

    def prompts_are_law_free(self) -> Result:
        """The prompt templates carry no law, no rule, and no capture figure.

        The templates are frozen alongside Core and the schema, and for the same
        reason: an example written from a particular statute teaches the shape of
        that statute's rules, and a figure copied out of a capture is a claim
        the prompt cannot re-check. Both belong to something that regenerates —
        the corpus, the library summary, or the gate's own calibration, which
        `summarize_binders` renders in at run time.

        Scoped to the template text only. Everything a session actually reads is
        interpolated from an artifact, and an artifact is allowed to name what it
        measured.
        """
        import itertools
        targets = sorted((REPO_ROOT / "prompts").glob("*.md"))
        patterns = dict(LAW_FREE_PATTERNS, **CAPTURE_FIGURE_PATTERNS)
        src = ("prompts/*.md",
               "frozen before any law or capture exists")
        bad = []
        for path in targets:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in patterns.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("prompts law-free", FAIL, "; ".join(bad[:5]), src)
        return Result("prompts law-free", OK,
                      f"{len(targets)} templates clear on all "
                      f"{len(patterns)} categories", src)

    def captures_stay_out_of_the_rule_tree(self) -> Result:
        """No converted capture sits under `library/TrafficSpec/`.

        The evaluation set is Lean traces and belongs in the library; where it
        sits is the whole of this check. `library/TrafficSpec/` is the tree both
        formalization prompts send an agent into — Core, the vocabulary, the
        builders — and an agent with a shell reads the rest of that directory.
        A capture it can read becomes an argument: "this attribute occurs in the
        trace, so the predicate is not dead" is a claim about one recording
        wearing the clothes of a claim about the data model, and it inverts the
        pipeline, since a capture is what a rule is TESTED against.

        `run_spec loop` refuses to start on the same condition. This exists
        because the loop's refusal only fires when someone runs the loop, and
        the invariant is easiest to break between runs — by a `monitor`
        invocation with a hand-written `--output`, or by moving a file.

        Also checks that the lakefile declares the root the harness imports.
        """
        from ..lean_check import captures_under
        src = ("library/TrafficSpec/**",
               "captures are decoded at run time by the monitor and never live in the library")
        tree = self.lib / "TrafficSpec"
        stray = list(captures_under(tree))
        stray += [p for ext in ("*.json", "*.jsonl", "*.pkl")
                  for p in tree.rglob(ext)]
        if stray:
            names = ", ".join(str(p.relative_to(self.lib)) for p in stray[:5])
            return Result("captures out of the rule tree", FAIL,
                          f"agent-readable capture(s): {names}", src)
        lakefile = _read(self.lib / "lakefile.lean")
        if "lean_lib «TrafficSpecEval»" in lakefile:
            return Result("captures out of the rule tree", FAIL,
                          "library/lakefile.lean still declares a compiled-capture root; "
                          "Core v2 decodes traces at run time (Core/Decode.lean)", src)
        return Result("captures out of the rule tree", OK,
                      "no capture under library/TrafficSpec/, no compiled-capture root", src)

    def witnesses_are_outside_the_specification(self) -> Result:
        """Every rule has a witness file, and none of them is inside `Rules/`.

        Two claims, because both halves can rot independently. A rule with no
        witness file has no evidence that its formula says anything: it is the
        `□ ⊤` case, which grounds, engages and holds on every capture ever
        recorded and is therefore invisible to capture-based evaluation. And a
        `def scenarios` back inside a rule file means the specification has
        started carrying its own evidence again, which is what put trace
        literals into the artifact an application loads.

        Also checks the shipped index does not reach the witnesses: the
        dependency runs `TrafficSpecWitness -> TrafficSpec`, never the reverse.
        """
        rules_dir = self.lib / "TrafficSpec" / "Rules"
        wit_dir = self.lib / "TrafficSpecWitness"
        src = ("library/TrafficSpec/Rules/**.lean",
               "library/TrafficSpecWitness/**.lean, Index.lean")
        rules = sorted(rules_dir.rglob("*.lean")) if rules_dir.exists() else []
        if not rules:
            return Result("witnesses outside the spec", SKIP,
                          "library carries no rules yet", src)
        bad = []
        for rule in rules:
            text = _read(rule)
            if re.search(r"^\s*def scenarios\b", text, re.M):
                bad.append(f"{rule.name} declares `def scenarios`")
            wit = wit_dir / rule.relative_to(rules_dir)
            if not wit.exists():
                bad.append(f"{rule.name} has no witness file")
            elif "def scenarios" not in _read(wit):
                bad.append(f"{wit.name} declares no `def scenarios`")
        # And the other direction. A witness file with no rule is a trace
        # nothing evaluates — the residue of a rule that was renamed, which
        # keeps building and keeps looking like evidence for something.
        expected = {(wit_dir / r.relative_to(rules_dir)).resolve() for r in rules}
        for stray in sorted(wit_dir.rglob("*.lean")) if wit_dir.exists() else []:
            if stray.resolve() not in expected:
                bad.append(f"{stray.relative_to(self.lib)} witnesses no rule")
        # A DEPENDENCY, not a mention: the index says in prose where the
        # witnesses went, and should. What must not appear is an import or a
        # use of one of their declarations.
        index = _read(self.lib / "TrafficSpec" / "Index.lean")
        if re.search(r"^\s*import\s+TrafficSpecWitness", index, re.M) or \
                re.search(r"\bTrafficSpecWitness\.\w", index):
            bad.append("Index.lean depends on TrafficSpecWitness — the shipped "
                       "library would carry its own evidence")
        if bad:
            return Result("witnesses outside the spec", FAIL,
                          "; ".join(bad[:5]), src)
        return Result("witnesses outside the spec", OK,
                      f"{len(rules)} rule(s), each with a witness file, none "
                      f"inside the specification", src)

    def witness_roles_agree(self) -> Result:
        """The roles the validator accepts are the roles both prompts teach.

        The third role this pipeline used to require — a trace showing the rule
        imposes nothing when the situation is absent — was removed after it was
        measured: for a formula shaped `□ (A ⟹ B)` it is a theorem of the
        semantics, and it held for every such trace in the library while
        costing more than half of all trace-writing work. A prompt still asking
        for it would be asking for work the validator then rejects.
        """
        from ..plan_validate import MAX_SCENARIOS, SCENARIO_ROLES
        src = ("scripts/plan_validate.py::SCENARIO_ROLES",
               "prompts/prompt_plan.md, prompts/prompt_code.md")
        bad = []
        for role in SCENARIO_ROLES:
            if f"`{role}`" not in self.prompt_plan:
                bad.append(f"prompt_plan.md does not name the `{role}` role")
            if f"`{role}`" not in self.prompt_code:
                bad.append(f"prompt_code.md does not name the `{role}` role")
        for text, name in ((self.prompt_plan, "prompt_plan.md"),
                           (self.prompt_code, "prompt_code.md")):
            for m in re.finditer(r"`antecedent_off`", text):
                line = text[:m.start()].count("\n") + 1
                # One historical mention is allowed, and wanted: a session that
                # has seen the old shape needs to be told it is gone. More than
                # one reads as a live requirement.
                pass
            if len(re.findall(r"`antecedent_off`", text)) > 1:
                bad.append(f"{name} mentions `antecedent_off` more than once; "
                           f"it reads as a live requirement rather than a "
                           f"retired one")
        if len(SCENARIO_ROLES) != MAX_SCENARIOS:
            bad.append(f"{len(SCENARIO_ROLES)} roles but MAX_SCENARIOS is "
                       f"{MAX_SCENARIOS} — one witness per role is the shape "
                       f"both prompts describe")
        if bad:
            return Result("witness roles agree", FAIL, "; ".join(bad[:5]), src)
        return Result("witness roles agree", OK,
                      f"{len(SCENARIO_ROLES)} roles ({', '.join(SCENARIO_ROLES)}) "
                      f"taught in both prompts, and the retired one is not", src)

    def coverage_vocabulary(self) -> Result:
        """The statuses the harness reads are the statuses the prompt teaches.

        Three artifacts have to agree on this word list: `scripts/coverage.py`
        decides convergence from it, `PROGRESS.md`'s template documents it, and
        the plan prompt tells a session which words to write. When they drifted
        the cost was not cosmetic — the prompt blessed an outcome (`partial`)
        that the completion condition could not accept, so the usual correct
        result was also a state no run could converge from, and one run ended
        with 19 of 21 clauses in it.

        Also asserts the retired word is gone. `partial` living on in a prompt
        while the harness no longer accepts it would be read, written, and then
        reported as a defect on every row.
        """
        from ..coverage import STATUSES
        from ..state import PROGRESS_TEMPLATE
        src = ("scripts/coverage.py::STATUSES",
               "prompts/prompt_plan.md, scripts/state.py::PROGRESS_TEMPLATE")
        missing = []
        for status in STATUSES:
            if status not in self.prompt_plan:
                missing.append(f"prompt_plan.md does not mention `{status}`")
            if status not in PROGRESS_TEMPLATE:
                missing.append(f"the PROGRESS template does not mention `{status}`")
        for stale in ("`partial`", "| partial |"):
            if stale in self.prompt_plan:
                missing.append(f"prompt_plan.md still offers {stale}, which the "
                               f"harness no longer accepts")
            if stale in PROGRESS_TEMPLATE:
                missing.append(f"the PROGRESS template still offers {stale}")
        if missing:
            return Result("coverage vocabulary", FAIL, "; ".join(missing[:5]), src)
        return Result("coverage vocabulary", OK,
                      f"all {len(STATUSES)} statuses taught in both artifacts, "
                      f"and `partial` is gone from both", src)

    #: Checks written against the v1 library and gate; skipped while `v1_library` is false.
    V1_CHECKS = {"predicates_exist", "verdicts_documented", "report_tags_parsed",
                 "example_rule_exists", "formula_operators",
                 "witnesses_are_outside_the_specification", "witness_roles_agree",
                 "coverage_vocabulary"}

    def checks(self) -> list[Callable[[], Result]]:
        return self.v2.checks() + [self.predicates_exist,
                self.verdicts_documented, self.report_tags_parsed,
                self.placeholders_supplied, self.example_rule_exists,
                self.formula_operators, self.repo_paths_resolve,
                self.frozen_artifacts_are_law_free,
                self.ontology_is_neutral,
                self.prompts_are_law_free,
                self.captures_stay_out_of_the_rule_tree,
                self.witnesses_are_outside_the_specification,
                self.witness_roles_agree,
                self.coverage_vocabulary]

    def run(self, verbose: bool = False) -> int:
        results: list[Result] = []
        for check in self.checks():
            if check.__name__ in self.V1_CHECKS and not self.v1_library:
                results.append(Result(check.__name__.replace("_", " "), SKIP,
                                      "describes the v1 library; awaiting the gate/prompt redraft"))
                continue
            try:
                results.append(check())
            except VacuousCheck as exc:
                results.append(Result(check.__name__, FAIL,
                                      f"VACUOUS — {exc}"))
            except Exception as exc:                        # noqa: BLE001
                results.append(Result(check.__name__, FAIL,
                                      f"the check itself raised: "
                                      f"{type(exc).__name__}: {exc}"))
        width = max(len(r.name) for r in results)
        colour = {OK: "\033[32m", FAIL: "\033[91m", SKIP: "\033[33m"}
        for r in results:
            print(f"  {colour[r.status]}{r.status:<4}\033[0m {r.name:<{width}}  {r.detail}")
            if verbose or r.status == FAIL:
                for s in r.sources:
                    print(f"       · {s}")
        failed = [r for r in results if r.status == FAIL]
        skipped = [r for r in results if r.status == SKIP]
        print(f"\n{len(results) - len(failed) - len(skipped)}/{len(results)} checks pass"
              f"{f', {len(skipped)} skipped' if skipped else ''}"
              f"{f', {len(failed)} FAILED' if failed else ''}.")
        if failed:
            print("\nEach failure is a description that no longer matches the thing "
                  "it describes. Fix the description, or the thing — not the check.")
        return 1 if failed else 0



def run(repo_root: Path, library_root: Path, verbose: bool = False) -> int:
    sys.path.insert(0, str(repo_root))
    return Doctor(repo_root, library_root).run(verbose)


if __name__ == "__main__":                    # python -m scripts.diagnostics.doctor
    # Runnable without `fire`, so the CARLA-capable interpreter — which has
    # `carla_sgg` but not the CLI's dependencies — can exercise the generator
    # checks that are otherwise skipped.
    root = REPO_ROOT
    sys.exit(run(root, root / "library", "--verbose" in sys.argv))
