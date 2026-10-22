"""Cross-check every agent-facing artifact against the thing it describes (`python -m harness doctor`).

The pipeline's output quality depends on prose artifacts — the prompt templates,
the frozen ontology, the Core docstrings — that describe things they do not own:
the Lean core, the gate's verdict set, the witness roles, the coverage statuses.
Prose drifts. Every check here compares a description with the thing described
and names both sources on failure, so a failure is actionable without re-deriving
what was compared.

The frozen artifacts (Core, the ontology, the prompts) are fixed BEFORE the
pipeline sees any law corpus or records any capture, and two checks hold them to
that: no statute, no rule named by its subject, no figure from a capture.

Run it as `python -m harness doctor`. Exit status is 1 if any check
fails, so it belongs in CI. No model, no Lean, no simulator.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Callable

from .doctor_result import Result, OK, FAIL, SKIP, REVIEW, VacuousCheck, _nonempty  # noqa: F401
from .library_v2 import LibraryV2Checks


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _read_opt(path: Path) -> str:
    """The file's text, or empty when it does not exist (a v1 artifact the redraft removed)."""
    return path.read_text(encoding="utf-8") if path.exists() else ""



def rule_matches(rule: str, tool: str, path: Path) -> bool:
    """Whether a permission rule `Tool(//abs/pattern)` covers `path` for `tool`: `**` spans
    directories, `*` one path segment, a pattern without a wildcard is exact."""
    import re
    if not rule.startswith(tool + "(//") or not rule.endswith(")"):
        return False
    pat = rule[len(tool) + 3:-1]
    rx = re.escape(pat).replace(r"\*\*", "\x00").replace(r"\*", "[^/]*").replace("\x00", ".*")
    return re.fullmatch(rx, str(Path(path).resolve()).lstrip("/")) is not None


def permitted(allow: list[str], deny: list[str], tool: str, path: Path) -> bool:
    """The allow-list model: a deny rule that matches refuses; else an allow rule must match."""
    if any(rule_matches(r, tool, path) for r in deny):
        return False
    return any(rule_matches(r, tool, path) for r in allow)


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
        "law id": r"\b(?:NRS|LVMC)-\d+[A-Z]?(?:-[A-Za-z0-9]+)+\b",
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

# Capture measurements belong to evaluation inputs, never to frozen prompt templates.
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
        self.v2 = LibraryV2Checks(repo_root, library_root)
        self.prompts = sorted((repo_root / "prompts").glob("*.md"))

    # ── prompts ──────────────────────────────────────────────────────────

    def placeholders_supplied(self) -> Result:
        """Every `{placeholder}` of a prompt template is supplied by the phase that renders it."""
        import importlib
        sys.path.insert(0, str(self.repo))
        owners = {"plan.md": ("harness.phases.plan", "PLACEHOLDERS"),
                  "code.md": ("harness.phases.code", "PLACEHOLDERS"),
                  "code_concept.md": ("harness.phases.code", "PLACEHOLDERS_CONCEPT"),
                  "concept_repair.md": ("harness.phases.plan", "PLACEHOLDERS_REPAIR"),
                  "node_repair.md": ("harness.phases.plan", "PLACEHOLDERS_NODE_REPAIR"),
                  "review_code.md": ("harness.phases.review", "PLACEHOLDERS_REVIEW_CODE"),
                  "adjudicate.md": ("harness.phases.review", "PLACEHOLDERS_ADJUDICATE"),
                  "review_concept.md": ("harness.phases.review", "PLACEHOLDERS_REVIEW_CONCEPT"),
                  "adjudicate_concept.md": ("harness.phases.review", "PLACEHOLDERS_ADJUDICATE_CONCEPT"),
                  "judge_case.md": ("harness.phases.review", "PLACEHOLDERS_JUDGE_CASE"),
                  "plan_aggregates.md": ("harness.phases.aggregate", "PLACEHOLDERS_PLAN_AGGREGATES"),
                  "verify_aggregate.md": ("harness.phases.aggregate", "PLACEHOLDERS_VERIFY_AGGREGATE")}
        src = ("prompts/*.md → {placeholders}", "harness/phases/*.py → PLACEHOLDERS tables")
        bad, n = [], 0
        for tmpl, (mod, attr) in owners.items():
            path = self.repo / "prompts" / tmpl
            if not path.exists():
                bad.append(f"{tmpl}: missing"); continue
            ph = _nonempty(set(re.findall(r"\{([a-z_]+)\}", _read(path))), f"placeholders in {tmpl}")
            supplied = set(getattr(importlib.import_module(mod), attr))
            if ph != supplied:
                bad.append(f"{tmpl}: template {sorted(ph)} vs renderer {sorted(supplied)}")
            n += len(ph)
        if bad:
            return Result("prompt placeholders", FAIL, "; ".join(bad), src)
        return Result("prompt placeholders", OK, f"{n} placeholders across {len(owners)} templates all supplied", src)

    def skeleton_tokens(self) -> Result:
        """The rule skeleton the harness writes for any law of the corpus uses no forbidden keyword
        in code: a law's words live in the header comment and in the operationalization strings,
        which the gate's soundness scan leaves out."""
        from harness.lean import skeleton
        from harness.checks.gate import forbidden_tokens
        from harness.model import corpus, blueprint
        src = ("harness/lean/skeleton.py → rule_skeleton", "harness/checks/gate.py → forbidden_tokens over lean.code_only")
        laws_file = self.repo / "laws" / "full_list" / "laws.jsonl"
        laws = _nonempty(corpus.load_laws(laws_file), "laws of the corpus")
        bad = []
        for l in laws:
            node = blueprint.Node({"node_id": l.id.replace("-", "_"), "law_refs": [l.id],
                                   "segmentation": [{"id": "s1", "text": l.text, "role": "obligation"}], "elements": [],
                                   "binders": [{"name": "x", "class_elements": []}],
                                   "operationalizations": [{"span": "s1", "standard": l.text, "concepts": ["rel.surface_gap"],
                                                            "params": ["p.x"], "convention": l.text}],
                                   "applicability": "", "obligation": "", "scenarios": []})
            hits = forbidden_tokens((("rule", skeleton.rule_skeleton(node)),))
            if hits:
                bad.append(f"{l.id}: {'; '.join(hits)}")
        if bad:
            return Result("skeleton tokens", FAIL, "; ".join(bad[:5]), src)
        return Result("skeleton tokens", OK, f"{len(laws)} skeletons carry no forbidden keyword in code", src)

    def sessions_are_isolated(self) -> Result:
        """Every agent session is launched with the flags that keep the developer's CLAUDE.md,
        settings, plugins, MCP servers and skills out of it, and the phases pass their deny rules."""
        import importlib
        sys.path.insert(0, str(self.repo))
        runner = importlib.import_module("harness.agents.runner")
        flags = list(getattr(runner, "ISOLATION_FLAGS", []))
        src = ("harness/agents/runner.py → ISOLATION_FLAGS, run_claude", "harness/phases/*.py → session.run(deny=…)")
        need = {"--setting-sources", "--strict-mcp-config", "--disable-slash-commands"}
        missing = sorted(need - set(flags))
        if missing:
            return Result("session isolation", FAIL, f"runner lacks {missing}", src)
        body = _read(self.repo / "harness" / "agents" / "runner.py")
        if "*ISOLATION_FLAGS" not in body or "*PERMISSION_FLAGS" not in body:
            return Result("session isolation", FAIL, "run_claude does not pass ISOLATION_FLAGS and PERMISSION_FLAGS", src)
        if '"--tools"' not in body or 'env["CLAUDE_CODE_DISABLE_AUTO_MEMORY"] = "1"' not in body:
            return Result("session isolation", FAIL, "run_claude does not fix each session's tool set or does not disable auto memory", src)
        perm = list(getattr(runner, "PERMISSION_FLAGS", []))
        if perm[:4] != ["--permission-mode", "default", "--permission-prompts", "none"]:
            return Result("session isolation", FAIL, f"sessions do not run under an allow-list: {perm}", src)
        phases = {"plan.py": ["allow=session.plan_allow(", "cwd=plan_dir"], "code.py": ["allow=session.code_allow(", "cwd=d"],
                  "validate.py": ["allow=[]", "tools=[]"]}
        bad = [f"{f}: {n}" for f, needles in phases.items() for n in needles if n not in _read(self.repo / "harness" / "phases" / f)]
        if bad:
            return Result("session isolation", FAIL, f"phases launch sessions outside the allow-list model: {bad}", src)
        oai = _read(self.repo / "harness" / "agents" / "openai_runner.py")
        if 'any(t.get("type") != "function" for t in tools)' not in oai:
            return Result("session isolation", FAIL, "a reviewer's tool session may carry tools other than the harness's functions", src)
        sess = importlib.import_module("harness.agents.session")
        wild = [r for r in sess.code_allow([Path("/x/a.lean")], Path("/x/t"), "python -m harness gate --run_id r --node_id n")
                if r.startswith("Bash(") and "*" in r]
        if wild:
            return Result("session isolation", FAIL, f"a shell rule carries a wildcard: {wild}", src)
        if not any(r.startswith("Read(") and ".claude" in r for r in sess.deny_rules("code")):
            return Result("session isolation", FAIL, "the Claude configuration and memory directory is not denied to reading", src)
        # the rules admit what each session exists to write, and deny the run's records
        plan_dir = self.repo / "results" / "r" / "iter-001" / "plan" / "batch-01"
        task_dir = self.repo / "results" / "r" / "iter-001" / "code" / "N"
        own = [self.repo / "library" / "TrafficSpec" / "Rules" / "X" / "N.lean"]
        p_allow, p_deny = sess.plan_allow(plan_dir, "python -m harness validate"), sess.deny_rules("plan")
        c_allow, c_deny = sess.code_allow(own, task_dir, "python -m harness gate"), sess.deny_rules("code")
        must_permit = [(p_allow, p_deny, plan_dir / "blueprint.jsonl"), (p_allow, p_deny, plan_dir / "PLAN.md"),
                       (c_allow, c_deny, task_dir / "task_result.md"), (c_allow, c_deny, own[0])]
        must_refuse = [(p_allow, p_deny, self.repo / "results" / "r" / "ledger.jsonl"), (p_allow, p_deny, self.repo / "results" / "r" / "reading.json"),
                       (c_allow, c_deny, self.repo / "results" / "r" / "accepted_nodes.jsonl"), (c_allow, c_deny, self.repo / "harness" / "loop.py"),
                       (c_allow, c_deny, self.repo / "results" / "r" / "iter-001" / "plan" / "blueprint.jsonl")]
        wrong = [str(p.relative_to(self.repo)) for a, d, p in must_permit if not permitted(a, d, "Write", p)] + \
                [str(p.relative_to(self.repo)) for a, d, p in must_refuse if permitted(a, d, "Write", p)]
        if wrong:
            return Result("session isolation", FAIL, f"the write rules admit or refuse the wrong paths: {wrong}", src)
        return Result("session isolation", OK, f"{len(need)} isolation flags; allow-list permissions; plan and code sessions jailed to their task directory with one exact shell command; readers and judges have no tool; reviewers have only the harness's checks and submission", src)

    def prompts_are_law_free(self) -> Result:
        """The templates carry no law, no rule named by its subject, no figure."""
        import itertools
        patterns = dict(LAW_FREE_PATTERNS, **CAPTURE_FIGURE_PATTERNS)
        src = ("prompts/*.md", "frozen before any corpus is seen")
        if not self.prompts:
            return Result("prompts law-free", FAIL, "no prompt templates found", src)
        bad = []
        for path in self.prompts:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in patterns.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("prompts law-free", FAIL, "; ".join(bad[:5]), src)
        return Result("prompts law-free", OK, f"{len(self.prompts)} templates clear on all {len(patterns)} categories", src)

    def prompts_are_vocabulary_free(self) -> Result:
        """Everything project-specific reaches an agent through injected context, never through
        the template: no atom, primitive or concept id, no Lean atom name, no reading parameter,
        no enumeration spelling as a literal, and no term the corpus defines (the two compounds
        the pipeline owns, "road user" and "stand-in", excepted)."""
        import itertools
        sys.path.insert(0, str(self.repo))
        from harness.model import ontology as onto_mod
        src = ("prompts/*.md", "ontology/ATOMS.md ids; laws/full_list/definitions.jsonl terms")
        onto = onto_mod.load(self.repo / "ontology" / "ATOMS.md")
        ids = sorted(set(onto.atoms) | set(onto.primitives), key=len, reverse=True)
        lean = [i.replace(".", "_") for i in ids]
        patterns = {
            "vocabulary id": r"\b(?:" + "|".join(re.escape(i) for i in ids) + r")\b",
            "Lean atom name": r"\b(?:" + "|".join(re.escape(i) for i in lean) + r")\b",
            "concept id": r"\bdrv\.[a-z_]+\.[a-z_]+\b",
            "reading parameter": r"\bp\.[a-z_]+\b",
            "enumeration literal": r'\.lit "[a-z_]+"',
        }
        def defined_term(d: dict) -> list[str]:
            """The term a record names: its text's first quoted phrase, and the title's subject when the
            title reads "<term> defined"."""
            out = []
            m = re.search(r"“([^”]+)”|\"([^\"]+)\"", d.get("text", ""))
            if m:
                out.append((m.group(1) or m.group(2)).strip().lower())
            t = d.get("title", "").strip()
            if t.lower().endswith(" defined"):
                out.append(t[:-8].strip().lower())
            return sorted(set(out))
        terms = set()
        defs_file = self.repo / "laws" / "full_list" / "definitions.jsonl"
        if defs_file.exists():
            for line in defs_file.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    for t in defined_term(json.loads(line)):
                        t = t.strip(" ,;:.").lower()
                        if len(t) > 3 and " / " not in t:
                            terms.add(t)
        bad = []
        for path in self.prompts:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in patterns.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    bad.append(f"{path.name}:{text[:m.start()].count(chr(10)) + 1} {label} {m.group(0)!r}")
            low = re.sub(r"\broad users?\b|\bstand-in\b", " ", text.lower())
            for t in sorted(terms):
                m = re.search(r"\b" + re.escape(t) + r"\b", low)
                if m:
                    bad.append(f"{path.name}:{low[:m.start()].count(chr(10)) + 1} defined term {t!r}")
        if bad:
            return Result("prompts vocabulary-free", FAIL, "; ".join(bad[:6]) + (f" (+{len(bad) - 6})" if len(bad) > 6 else ""), src)
        return Result("prompts vocabulary-free", OK,
                      f"{len(self.prompts)} templates name none of {len(ids)} ids and {len(terms)} defined terms", src)

    # ── frozen artifacts ─────────────────────────────────────────────────

    def frozen_artifacts_are_law_free(self) -> Result:
        """Core and the ontology carry no law, no rule, and no capture figure."""
        import itertools
        targets = sorted((self.lib / "TrafficSpec" / "Core").rglob("*.lean")) + \
            sorted((self.repo / "ontology").glob("*.md"))
        patterns = dict(LAW_FREE_PATTERNS, **FROZEN_ONLY_PATTERNS)
        src = ("library/TrafficSpec/Core/**/*.lean, ontology/*", "frozen before any law exists")
        bad = []
        for path in targets:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in patterns.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("frozen artifacts law-free", FAIL, "; ".join(bad[:5]), src)
        return Result("frozen artifacts law-free", OK, f"{len(targets)} frozen files clear on all {len(patterns)} categories", src)

    def ontology_is_neutral(self) -> Result:
        """The ontology names no statute, no clause, no source and no figure."""
        import itertools
        files = sorted((self.repo / "ontology").glob("*.md"))
        src = ("ontology/*", "frozen before any corpus is seen")
        bad = []
        for path in files:
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pat in ONTOLOGY_PATTERNS.items():
                for m in itertools.islice(re.finditer(pat, text), 3):
                    line = text[:m.start()].count("\n") + 1
                    bad.append(f"{path.name}:{line} {label} {m.group(0)!r}")
        if bad:
            return Result("ontology neutral", FAIL, "; ".join(bad[:5]), src)
        return Result("ontology neutral", OK, f"{len(files)} file(s) clear on all {len(ONTOLOGY_PATTERNS)} categories", src)

    def rule_files_carry_only_posted_law_ids(self) -> Result:
        """Only the corpus and the rule files may name a law; the harness and the docs may not."""
        import itertools
        targets = [p for p in self.repo.rglob("*.py") if "harness" in p.parts or "scripts" in p.parts] + \
            [self.repo / "README.md"]
        pat = LAW_FREE_PATTERNS["law id"]
        # the pattern must recognise a real id, or the check certifies silence
        corpus_ids = re.findall(r'"id": "([^"]+)"', _read_opt(self.repo / "laws" / "full_list" / "laws.jsonl")[:20000])
        _nonempty(corpus_ids, "corpus ids")
        unmatched = [i for i in corpus_ids[:50] if not re.fullmatch(pat.strip("\\b"), i)]
        if unmatched:
            return Result("harness law-free", FAIL, f"the law-id pattern does not match corpus ids such as {unmatched[:3]}", ("doctor LAW_FREE_PATTERNS", "laws/full_list/laws.jsonl"))
        bad = []
        for path in targets:
            if not path.exists():
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            for m in itertools.islice(re.finditer(pat, text), 2):
                bad.append(f"{path.relative_to(self.repo)}: {m.group(0)}")
        src = ("harness/**, scripts/**, README.md", "law ids belong to laws/** and Rules/** only")
        if bad:
            return Result("harness law-free", FAIL, "; ".join(bad[:5]), src)
        return Result("harness law-free", OK, f"{len(targets)} files name no law id", src)

    def code_cites_no_document(self) -> Result:
        """A comment of the harness, the scripts or Core states its contract in its own words: it cites
        no design document, section, revision or plan part."""
        pat = re.compile(r"§ ?\d|\bdesign §|\b[A-Z][A-Z0-9_]*_(?:PLAN|DESIGN)(?:_[\d-]+)?(?:\.md)?\b|\b[Rr]evision[- ]\d+|\b[Pp]art \d+\b|\brev\.? ?\d+\b")
        for sample in ("design §4", "DERIVED_CONCEPTS_PLAN §5", "Revision 33", "revision-32", "part 27", "rev 33"):
            if not pat.search(sample):          # the pattern must recognise a citation, or the check certifies silence
                raise VacuousCheck(f"the citation pattern misses {sample!r}")
        targets = [p for d in ("harness", "scripts") for p in (self.repo / d).rglob("*.py")
                   if p.resolve() != Path(__file__).resolve()]          # this file holds the samples above
        targets += sorted((self.lib / "TrafficSpec" / "Core").rglob("*.lean"))
        bad = []
        for path in targets:
            for i, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if pat.search(line):
                    bad.append(f"{path.relative_to(self.repo)}:{i}")
        src = ("harness/**/*.py, scripts/**/*.py, library/TrafficSpec/Core/**/*.lean", "a comment states its contract in full")
        if bad:
            return Result("code cites no document", FAIL, "; ".join(bad[:8]), src)
        return Result("code cites no document", OK, f"{len(targets)} files cite no document, section or revision", src)

    def captures_stay_out_of_the_rule_tree(self) -> Result:
        """No trace or capture sits under `library/TrafficSpec/`; traces are decoded at run time."""
        tree = self.lib / "TrafficSpec"
        stray = [p for ext in ("*.json", "*.jsonl", "*.pkl") for p in tree.rglob(ext) if not {"Gaps", "Readings"} & set(p.relative_to(tree).parts)]
        src = ("library/TrafficSpec/** (TrafficSpec/Gaps/ and TrafficSpec/Readings/ are the gap ledger and the parameter catalogues, not captures)", "traces reach the monitor through Decode, never the library")
        if stray:
            return Result("captures out of the rule tree", FAIL,
                          "agent-readable capture(s): " + ", ".join(str(p.relative_to(self.lib)) for p in stray[:5]), src)
        return Result("captures out of the rule tree", OK, "no capture under library/TrafficSpec/", src)

    def repo_paths_resolve(self) -> Result:
        """Every in-repo path a document or template names exists."""
        sources = [self.repo / "README.md"] + self.prompts + sorted((self.repo / "ontology").glob("*.md"))
        entries = {p.name for p in self.repo.iterdir()}
        bad, n = [], 0
        for src_path in sources:
            if not src_path.exists():
                continue
            text = src_path.read_text(encoding="utf-8", errors="replace")
            for m in re.finditer(r"`((?:[A-Za-z_][\w.-]*/)+[\w.-]+\.(?:py|md|lean|json|jsonl|toml|sh))`", text):
                token = m.group(1)
                if token.split("/")[0] not in entries or "<" in token or "*" in token:
                    continue
                n += 1
                if not (self.repo / token).exists():
                    bad.append(f"{src_path.name}: {token}")
        src = ("README.md, prompts/*.md, ontology/*.md → in-repo paths", "the file system")
        if bad:
            return Result("file links", FAIL, "; ".join(bad[:6]), src)
        return Result("file links", OK, f"{n} in-repo path(s) resolve", src)

    def core_matches_active_split(self) -> Result:
        """The Core directory holds exactly the variant `splits/ACTIVE` names: the archived full files
        when `full` is active, the training files regenerated from that archive when `train` is —
        so an edit made to Core under one variant cannot be lost by the next swap."""
        sys.path.insert(0, str(self.repo))
        from harness.tools import split as split_mod
        src = ("library/splits/ACTIVE, library/splits/full/** (archive)", "library/TrafficSpec/Core/** (harness/tools/split.py)")
        full = self.lib / "splits" / "full" / "TrafficSpec" / "Core"
        core = self.lib / "TrafficSpec" / "Core"
        if not (full / split_mod.ATOMS).exists():
            return Result("core matches split", SKIP, "no archive yet: the Core directory is the full variant", src)
        which = split_mod.active()
        files = [split_mod.ATOMS] + split_mod.DEPENDENT
        if which == "full":
            drift = [f for f in files if (core / f).read_text(encoding="utf-8") != (full / f).read_text(encoding="utf-8")]
        else:
            import tempfile
            with tempfile.TemporaryDirectory() as td:
                out = Path(td)
                split_mod.generate_train(full, out)
                drift = [f for f in split_mod.DEPENDENT if (core / f).read_text(encoding="utf-8") != (out / f).read_text(encoding="utf-8")]
            train_atoms = self.lib / "splits" / "train" / "TrafficSpec" / "Core" / split_mod.ATOMS
            if train_atoms.exists() and (core / split_mod.ATOMS).read_text(encoding="utf-8") != train_atoms.read_text(encoding="utf-8"):
                drift.append(split_mod.ATOMS)
        if drift:
            return Result("core matches split", FAIL, f"`{which}` is active but Core differs from its source in {drift}: edit Core with `full` active, then `python -m harness split --use train`", src)
        return Result("core matches split", OK, f"`{which}` active, {len(files)} split files match their source", src)

    def held_out_rows_frozen(self) -> Result:
        """Each atom the test split holds out keeps the ATOMS.md row it had when the split was made:
        that row is the one added back when a test run proposes the atom, so it must not be reshaped
        by development. A held-out row changes only by regenerating the split."""
        import hashlib
        split = self.repo / "laws" / "audit_and_scripts" / "split_atoms.json"
        atoms_md = self.repo / "ontology" / "ATOMS.md"
        src = ("laws/audit_and_scripts/split_atoms.json → held_out_rows", "ontology/ATOMS.md → the held-out rows")
        frozen = json.loads(_read(split)).get("held_out_rows", {})
        if not frozen:
            return Result("held-out rows frozen", SKIP, "the split records no held-out rows", src)
        rows = {}
        for line in _read(atoms_md).splitlines():
            m = re.match(r"^\| `([a-z]+\.[a-z_]+)` \|", line)
            if m and m.group(1) in frozen and m.group(1) not in rows:     # its contract row, not its row in the units table
                rows[m.group(1)] = hashlib.sha256(line.encode("utf-8")).hexdigest()
        bad = [a for a, f in frozen.items() if rows.get(a) != f.get("sha256")]
        if bad:
            return Result("held-out rows frozen", FAIL, f"ATOMS.md rows differ from the split's frozen copy: {bad}; "
                          "restore them, or regenerate the split (nrs_tools.split) as a recorded decision", src)
        return Result("held-out rows frozen", OK, f"{len(frozen)} held-out ATOMS.md row(s) match the split's frozen copy", src)

    def reading_figures_reviewed(self) -> Result:
        """A reading holds the numbers no statute states. A parameter whose value is a figure some law of
        the corpus states may be that statute's figure entering every rule through the reading; each such
        parameter is listed for the operator until its entry carries a `figure_review` note saying why
        the value is a convention and not the statute's figure. A number phrase before a unit that the
        figure parser cannot read fails the check: the validator would return every record on it."""
        sys.path.insert(0, str(self.repo))
        from harness.model.units import stated_figures, to_core, unsupported_figures
        corpus = self.repo / "laws" / "full_list" / "laws.jsonl"
        src = [f"{corpus.relative_to(self.repo)} → stated figures", "library/TrafficSpec/Readings/*.json → params (value, unit, figure_review)"]
        stated: dict[tuple, list[tuple[str, str]]] = {}
        unreadable: list[str] = []
        for line in _read(corpus).splitlines():
            if line.strip():
                law = json.loads(line)
                for f in stated_figures(law["text"]):
                    stated.setdefault((f.core, f.value), []).append((law["id"], f.words))
                unreadable += [f"{law['id']}, character {u.start}" for u in unsupported_figures(law["text"])]
        _nonempty(stated, "figures stated by the corpus")
        if unreadable:                       # located by id and offset only: the corpus file holds the test split too
            return Result("reading figures", FAIL, f"{len(unreadable)} number phrase(s) before a unit that the figure parser "
                          "(harness/model/units.py) cannot read; extend it", tuple(unreadable) + tuple(src))
        readings = sorted((self.lib / "TrafficSpec" / "Readings").glob("*.json"))
        from harness.model.reading import reading_defects
        broken = [f"{rf.name}: {e}" for rf in readings for e in reading_defects(json.loads(_read(rf)))]
        if broken:
            return Result("reading figures", FAIL, f"{len(broken)} defect(s) keep a reading from being read whole", tuple(broken) + tuple(src))
        flagged, reviewed, n = [], 0, 0
        for rf in readings:
            for p in json.loads(_read(rf)).get("params", []):
                n += 1
                key = to_core(p["value"], p["unit"])
                if key not in stated:
                    continue
                if str(p.get("figure_review", "")).strip():
                    reviewed += 1; continue
                laws = sorted({i for i, _ in stated[key]})
                flagged.append(f"{rf.name}: `{p['name']}` = {p['value']} {p['unit']}, stated as `{stated[key][0][1]}` by "
                               f"{len(laws)} law(s): {', '.join(laws[:4])}{' …' if len(laws) > 4 else ''}")
        if flagged:
            return Result("reading figures", REVIEW, f"{len(flagged)} of {n} parameter(s) equal a figure the corpus states "
                          f"and carry no `figure_review` note", tuple(flagged) + tuple(src))
        return Result("reading figures", OK, f"{n} parameter(s) across {len(readings)} reading(s); "
                      f"{reviewed} equal a stated figure and carry a review note", tuple(src))

    def reading_proposals_reviewed(self) -> Result:
        """A parameter a plan session proposed enters the reading marked `proposed` (run, iteration and
        node) with its convention and source, and is listed here until the operator reviews it by
        removing the marker or changing the value. Nothing evaluated against the reading is final
        while a proposal stands."""
        src = ("library/TrafficSpec/Readings/*.json → params[].proposed",)
        rows, n = [], 0
        for path in sorted((self.lib / "TrafficSpec" / "Readings").glob("*.json")):
            try:
                data = json.loads(_read(path))
            except json.JSONDecodeError as e:
                return Result("reading proposals", FAIL, f"{path.name}: {e}", src)
            for prm in data.get("params", []):
                n += 1
                if prm.get("proposed"):
                    rows.append(f"{path.name}: `{prm.get('name')}` = {prm.get('value')} {prm.get('unit')} proposed by {prm.get('proposed')}: {str(prm.get('convention', ''))[:90]}")
        if rows:
            return Result("reading proposals", REVIEW, f"{len(rows)} proposed parameter(s) await the operator's review", tuple(rows) + src)
        return Result("reading proposals", OK, f"{n} parameter(s), none proposed and unreviewed", src)

    def case_blocks_cover(self) -> Result:
        """The two blocks a reviewer is taught a case from are generated and cover what `Case.check`
        admits: every Boolean atom of the dispatch tables (`ru_aggregate` aside), every class atom of
        the codecs, every measured atom with a unit (`Dimensions.ofMeasure`) and every primitive, each
        with a contract; every measured atom the dispatch knows has a unit; every admitted JSON form
        of the case language has its keys."""
        sys.path.insert(0, str(self.repo))
        from harness.lean import surface
        from harness.model import ontology as onto_mod
        src = ("library/TrafficSpec/Core/** (Semantics, Vocab/Ontology/Dimensions, Export)", "harness/lean/surface.py")
        onto = onto_mod.load(self.repo / ("ontology/ATOMS_train.md" if self._active() == "train" else "ontology/ATOMS.md"))
        rows = surface.case_catalogue(onto)
        bad = [f"`{r['name']}` has no contract" for r in rows if not str(r.get("contract", "")).strip()]
        sem = (self.lib / "TrafficSpec" / "Core" / "Language" / "Semantics.lean").read_text(encoding="utf-8")
        listed = re.findall(r'"(\w+)"', re.search(r"measureNames : List String := \[(.*?)\]", sem, re.S).group(1))
        dims, prims = surface._dimensions()
        bad += [f"measured atom `{m}` has no unit in Dimensions.lean (the units table of ATOMS.md)" for m in listed if m not in dims]
        names = {r["name"] for r in rows}
        bad += [f"primitive `{p}` is missing from the catalogue" for p in prims if p not in names]
        lang = surface.case_language()
        bad += [f"the case language lacks the `{k}` form" for k in ("atom", "cmp", "holds_for", "measure", "lit") if f'"{k}"' not in lang]
        if bad:
            return Result("case blocks cover", FAIL, "; ".join(bad[:6]), src)
        return Result("case blocks cover", OK, f"{len(rows)} catalogue entries with contracts; {len(dims)} measured atoms with units", src)

    def _active(self) -> str:
        f = self.lib / "splits" / "ACTIVE"
        return f.read_text().strip() if f.exists() else "full"

    def held_out_absent_from_training_tables(self) -> Result:
        """No atom the test split holds out appears in the training `Dimensions.lean` or, under the
        training split, in the case vocabulary a reviewer is shown."""
        sys.path.insert(0, str(self.repo))
        src = ("laws/audit_and_scripts/split_atoms.json → test_only_atoms", "library/splits/train/**/Dimensions.lean; harness/lean/surface.py")
        split = self.repo / "laws" / "audit_and_scripts" / "split_atoms.json"
        if not split.exists():
            return Result("held-out atoms stay out", SKIP, "no split", src)
        held = json.loads(_read(split)).get("test_only_atoms", [])
        names = [h.replace(".", "_") for h in held]
        bad = []
        train_dims = self.lib / "splits" / "train" / "TrafficSpec" / "Core" / "Vocab" / "Ontology" / "Dimensions.lean"
        if train_dims.exists():
            t = _read(train_dims)
            bad += [f"training Dimensions.lean names `{n}`" for n in names if re.search(rf'"{re.escape(n)}(?:_\w+)?"', t)]
        if self._active() == "train":
            from harness.lean import surface
            from harness.model import ontology as onto_mod
            vocab = surface.case_vocabulary(onto_mod.load(self.repo / "ontology" / "ATOMS_train.md"))
            bad += [f"the case vocabulary names `{h}`" for h, n in zip(held, names) if re.search(rf"`{re.escape(h)}`|`{re.escape(n)}[(`_]", vocab)]
        if bad:
            return Result("held-out atoms stay out", FAIL, "; ".join(bad[:6]), src)
        return Result("held-out atoms stay out", OK, f"none of {len(held)} held-out atoms in the training tables", src)

    def definition_resolution_report(self) -> Result:
        """Which defined terms of the training laws the operator's declared precedence leaves without
        an applicable definition, or with several: a report, read from the posted training files and
        the configuration only."""
        sys.path.insert(0, str(self.repo))
        from harness.model import corpus, definitions as definitions_mod
        src = ("laws/example/train/{laws,definitions}.jsonl", "config/definition_precedence.json")
        laws_file = self.repo / "laws" / "example" / "train" / "laws.jsonl"
        if not laws_file.exists():
            return Result("definition resolution", SKIP, "no training corpus", src)
        table = definitions_mod.resolve_table(corpus.load_laws(laws_file), corpus.load_definitions(laws_file), definitions_mod.load_precedence())
        rows = [(law, r) for law, rs in table["laws"].items() for r in rs]
        open_ = [f"{law}: \"{r['term']}\" {r['status']}" + (f" ({', '.join(r['candidates'])})" if r.get("candidates") else "") + (f" — {r['why']}" if r.get("why") else "")
                 for law, r in rows if r["status"] != "resolved"]
        nested_open = [f"definition `{definition}` uses \"{d['term']}\" {d['status']}"
                       + (f" ({', '.join(d['candidates'])})" if d.get("candidates") else "")
                       + (f" — {d['why']}" if d.get("why") else "")
                       for definition, dependencies in table["dependencies"].items() for d in dependencies
                       if d["status"] != "resolved"]
        open_ += nested_open
        nested = sum(len(dependencies) for dependencies in table["dependencies"].values())
        summary = (f"{sum(1 for _l, r in rows if r['status'] == 'resolved')} of {len(rows)} defined-term uses resolved; "
                   f"{nested - len(nested_open)} of {nested} nested uses resolved")
        if open_:
            return Result("definition resolution", REVIEW, f"{summary}; {len(open_)} unresolved or ambiguous", tuple(open_) + src)
        return Result("definition resolution", OK, summary, src)

    def checks(self) -> list[Callable[[], Result]]:
        return self.v2.checks() + [self.core_matches_active_split, self.held_out_rows_frozen, self.case_blocks_cover,
                                   self.held_out_absent_from_training_tables, self.definition_resolution_report,
                                   self.placeholders_supplied, self.skeleton_tokens,
                                   self.sessions_are_isolated, self.prompts_are_law_free, self.prompts_are_vocabulary_free,
                                   self.frozen_artifacts_are_law_free, self.ontology_is_neutral,
                                   self.rule_files_carry_only_posted_law_ids, self.code_cites_no_document,
                                   self.captures_stay_out_of_the_rule_tree, self.repo_paths_resolve,
                                   self.reading_figures_reviewed, self.reading_proposals_reviewed]

    def run(self, verbose: bool = False) -> int:
        results: list[Result] = []
        for check in self.checks():
            try:
                results.append(check())
            except VacuousCheck as exc:
                results.append(Result(check.__name__, FAIL, f"VACUOUS — {exc}"))
            except Exception as exc:                        # noqa: BLE001
                results.append(Result(check.__name__, FAIL, f"the check itself raised: {type(exc).__name__}: {exc}"))
        width = max(len(r.name) for r in results)
        colour = {OK: "\033[32m", FAIL: "\033[91m", SKIP: "\033[33m", REVIEW: "\033[35m"}
        for r in results:
            print(f"  {colour[r.status]}{r.status:<6}\033[0m {r.name:<{width}}  {r.detail}")
            if verbose or r.status in (FAIL, REVIEW):
                for s_ in r.sources:
                    print(f"       · {s_}")
        failed = [r for r in results if r.status == FAIL]
        skipped = [r for r in results if r.status == SKIP]
        review = [r for r in results if r.status == REVIEW]
        print(f"\n{len(results) - len(failed) - len(skipped) - len(review)}/{len(results)} checks pass"
              f"{f', {len(skipped)} skipped' if skipped else ''}{f', {len(review)} for review' if review else ''}"
              f"{f', {len(failed)} FAILED' if failed else ''}.")
        return 1 if failed else 0


def run(repo_root: Path, library_root: Path, verbose: bool = False) -> int:
    sys.path.insert(0, str(repo_root))
    return Doctor(repo_root, library_root).run(verbose)


if __name__ == "__main__":
    root = REPO_ROOT
    sys.exit(run(root, root / "library", "--verbose" in sys.argv))
