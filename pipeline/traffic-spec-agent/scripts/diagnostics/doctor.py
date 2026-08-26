"""Cross-check every agent-facing claim against the artifact it describes.

The pipeline's output quality depends on two prose artifacts — `carla/schema.json`
and `prompts/*.txt` — that describe things they do not own: the Lean core, the
adapter, the scene-graph generator, the gate's verdict set. Prose drifts. Every
one of these checks corresponds to a drift that actually happened:

* Both prompts told the coding agent to read a worked example at a path that had
  stopped existing, and that example was its only in-context source for the
  formula notation.
* The gate gained two verdicts the coding prompt's branch table never listed, so
  an agent could receive a verdict with no instruction for it.
* `CLAUDE.md` described the report format without a line the report had started
  emitting, and described a schema tier that had been deleted.
* `attribute_keys` claimed vehicle light booleans exist on the ego, which the
  generator never emits for it.

None of those is subtle; all of them are mechanically detectable; none was
detected, because nothing compared the description with the thing described.

Run it as `python -m scripts.run_spec doctor`. Exit status is 1 if any check
fails, so it belongs in CI. Checks that need the sibling CARLA repo are skipped
rather than failed when it is absent, so this runs anywhere.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

OK, FAIL, SKIP = "ok", "FAIL", "skip"


@dataclass
class Result:
    name: str
    status: str
    detail: str
    #: Where the two sides of the comparison live, so a failure is actionable
    #: without re-deriving what was compared.
    sources: tuple[str, ...] = ()


class VacuousCheck(RuntimeError):
    """A check extracted nothing, so it would have passed by finding nothing.

    This is the failure mode a comparison-based checker is most exposed to: a
    regex that stops matching because the file it reads was reformatted returns
    an empty set, an empty set is a subset of everything, and the check reports
    `ok`. Every extraction below is therefore asserted non-empty first, so a
    broken extractor fails loudly instead of certifying silence. Two of my own
    ad-hoc checks during this project gave false results exactly this way.
    """


def _nonempty(value, what: str):
    """Return `value`, or raise if it is empty — see `VacuousCheck`."""
    if not value:
        raise VacuousCheck(f"extracted nothing for {what}; the extractor is "
                           f"broken or the file it reads has moved")
    return value


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _lean_ctors(scene_src: str, inductive: str) -> list[str]:
    """Constructor names of a Lean `inductive`, in declaration order."""
    m = re.search(rf"inductive {inductive}\b(.*?)(?=\ninductive |\ndef |\nnamespace |\Z)",
                  scene_src, re.S)
    return re.findall(r"^\s*\|\s*(\w+)", m.group(1), re.M) if m else []


def _lean_list(src: str, name: str) -> list[str]:
    """The `.ctor` names in a `def name : List EntityType := [...]`."""
    m = re.search(rf"def {name}\s*:[^:=]*:=\s*\[(.*?)\]", src, re.S)
    return re.findall(r"\.(\w+)", m.group(1)) if m else []


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
}

# Only the frozen artifacts. The prompts legitimately name pipeline roles and
# the files a session writes — that is what they are for.
FROZEN_ONLY_PATTERNS = {
        # Pipeline roles and capture scripts. Neither is generator source,
        # and a frozen file that names one asserts a pipeline behaviour it
        # cannot verify.
        "pipeline internals": r"\b(?:plan agent|coding agent"
                              r"|capture_sensor_data|node_report"
                              r"|verdict\.json|PROGRESS\.md)\b",
}


class Doctor:
    def __init__(self, repo_root: Path, library_root: Path):
        self.repo = repo_root
        self.lib = library_root
        core = library_root / "TrafficSpec" / "Core"
        self.scene = _read(core / "Scene.lean")
        self.vocab = _read(core / "Vocab.lean")
        self.grounding = _read(core / "Grounding.lean")
        self.formula = _read(core / "Formula.lean")
        self.adapter = _read(repo_root / "carla" / "adapter.py")
        self.gate = _read(repo_root / "tools" / "check_spec.py")
        self.schema_text = _read(repo_root / "carla" / "schema.json")
        self.schema = json.loads(self.schema_text)
        self.prompt_code = _read(repo_root / "prompts" / "prompt_code.txt")
        self.prompt_plan = _read(repo_root / "prompts" / "prompt_plan.txt")

    # ── schema ↔ Lean core ──────────────────────────────────────────────

    def entity_types(self) -> Result:
        core = _lean_ctors(self.scene, "EntityType")
        claimed = self.schema["entity_types"]["tier_a"]
        src = ("carla/schema.json → entity_types.tier_a",
               "library/TrafficSpec/Core/Scene.lean → inductive EntityType")
        if set(core) != set(claimed):
            return Result("entity types", FAIL,
                          f"schema-only={sorted(set(claimed)-set(core))} "
                          f"core-only={sorted(set(core)-set(claimed))}", src)
        return Result("entity types", OK, f"{len(core)} constructors agree", src)

    def relation_labels(self) -> Result:
        core = _lean_ctors(self.scene, "RelLabel")
        claimed = self.schema["relation_labels"]["tier_a"]
        src = ("carla/schema.json → relation_labels.tier_a",
               "library/TrafficSpec/Core/Scene.lean → inductive RelLabel")
        if set(core) != set(claimed):
            return Result("relation labels", FAIL,
                          f"schema-only={sorted(set(claimed)-set(core))} "
                          f"core-only={sorted(set(core)-set(claimed))}", src)
        return Result("relation labels", OK, f"{len(core)} labels agree", src)

    def source_labels(self) -> Result:
        """Every RSV label the adapter accepts, as the schema records it."""
        m = re.search(r"REL_LABELS[^{]*\{(.*?)\n\}", self.adapter, re.S)
        inverted: dict[str, set[str]] = {}
        for raw, lean in re.findall(r'"([^"]+)"\s*:\s*"([^"]+)"', m.group(1) if m else ""):
            inverted.setdefault(lean, set()).add(raw)
        claimed = {k: set(v) for k, v in
                   self.schema["relation_labels"]["rsv_source_labels"].items()}
        src = ("carla/schema.json → relation_labels.rsv_source_labels",
               "carla/adapter.py → REL_LABELS")
        if inverted != claimed:
            diff = [k for k in set(inverted) | set(claimed)
                    if inverted.get(k) != claimed.get(k)]
            return Result("rsv source labels", FAIL,
                          f"disagree for {sorted(diff)}", src)
        return Result("rsv source labels", OK,
                      f"{len(claimed)} mappings agree", src)

    def proximity_bands(self) -> Result:
        m = re.search(r"def distanceBands.*?\[(.*?)\]", self.scene, re.S)
        core = [(a, int(b)) for a, b in re.findall(r"\.(\w+),\s*(\d+)", m.group(1) if m else "")]
        claimed = [(a, b) for a, b in
                   self.schema["relation_labels"]["proximity_bands_closest_first"]]
        src = ("carla/schema.json → relation_labels.proximity_bands_closest_first",
               "library/TrafficSpec/Core/Scene.lean → distanceBands")
        if core != claimed:
            return Result("proximity bands", FAIL,
                          f"core={core} schema={claimed}", src)
        return Result("proximity bands", OK,
                      f"{len(core)} bands agree, closest first", src)

    def capture_rate(self) -> Result:
        m = re.search(r"def captureHz : Nat := (\d+)", self.scene)
        core = int(m.group(1)) if m else -1
        claimed = self.schema["time_base"]["capture_hz"]
        m2 = re.search(r"ASSUMED_CAPTURE_HZ = (\d+)", self.adapter)
        adapter = int(m2.group(1)) if m2 else -1
        src = ("carla/schema.json → time_base.capture_hz",
               "library/TrafficSpec/Core/Scene.lean → captureHz",
               "carla/adapter.py → ASSUMED_CAPTURE_HZ")
        if not (core == claimed == adapter):
            return Result("capture rate", FAIL,
                          f"core={core} schema={claimed} adapter={adapter} — a "
                          f"mismatch rescales every duration in every rule", src)
        return Result("capture rate", OK, f"{core} Hz in all three", src)

    def capture_rate_has_one_owner(self) -> Result:
        """No description restates the capture rate as a figure.

        The rate had five copies — `time_base.capture_hz`, the precondition
        prose, a `partially_available` entry as "50 ms", `Core/Scene.lean`
        and `adapter.py`. `capture_rate` above cross-checks the first, fourth and
        fifth against each other. The two prose copies were checked by nothing,
        so they were the ones free to drift, and a drifted rate rescales every
        duration in every rule silently.

        Scoped to the rate ON PURPOSE. Hunting every owned literal through free
        prose is not sound: `capture_preconditions.no_effect_on_this_abstraction`
        legitimately says `segment_length / inflation = 4 m` and
        `angular_precision=[1, 2.5, 5, 7.5, 10]`, whose numbers collide with the
        proximity band metres while denoting something else entirely. The rate is
        checkable because it always carries a unit.
        """
        hz = self.schema["time_base"]["capture_hz"]
        ms = int(1000 / hz)
        patterns = {
            rf"\b{hz}\s*(?:Hz|hz)\b": f"{hz} Hz",
            rf"\b{hz}\s+frames?\b": f"{hz} frames",
            rf"\bat\s+{hz}\b": f"at {hz}",
            rf"\b{ms}\s*(?:ms|milliseconds?)\b": f"{ms} ms",
        }
        src = ("carla/schema.json -> every description outside time_base",
               "carla/schema.json -> time_base.capture_hz")
        bad = []
        # `time_base` owns the value, but only in `capture_hz`. Its own prose
        # used to restate it twice more ("secondsToFrames 1 = 20", "50 ms
        # frames") — inside the section this check was trusting, and the
        # millisecond spelling is derived, so a changed rate would have left it
        # quietly wrong. Every field except the owner is checked.
        for section in ("time_base", "capture_preconditions",
                        "partially_available", "entity_types",
                        "relation_labels", "relation_coverage",
                        "attribute_keys", "available_not_exposed",
                        "deciding_unsupported"):
            for key, entry in self.schema[section].items():
                if key.startswith("$") or (section == "time_base"
                                           and key == "capture_hz"):
                    continue
                stack = [entry]
                while stack:
                    it = stack.pop()
                    if isinstance(it, dict):
                        stack += list(it.values())
                    elif isinstance(it, list):
                        stack += it
                    elif isinstance(it, str):
                        for pat, shown in patterns.items():
                            if re.search(pat, it):
                                bad.append(f"{section}.{key} says {shown!r}")
        if bad:
            return Result("capture rate one owner", FAIL,
                          f"{'; '.join(sorted(set(bad)))} — name "
                          f"time_base.capture_hz instead; a second copy nothing "
                          f"cross-checks is the copy that drifts", src)
        return Result("capture rate one owner", OK,
                      f"{len(patterns)} spellings of the rate appear in no "
                      f"description; time_base.capture_hz is the only copy", src)

    def proximity_types(self) -> Result:
        lean = _lean_list(self.scene, "proximityTypes")
        rename = {"pedestrian": "person"}
        lean_named = {rename.get(x, x) for x in lean}
        claimed = set(self.schema["relation_coverage"]
                      ["proximity_and_angular_pairs"]["covered_base_classes"])
        src = ("carla/schema.json → relation_coverage…covered_base_classes",
               "library/TrafficSpec/Core/Scene.lean → proximityTypes")
        if lean_named != claimed:
            return Result("proximity-capable types", FAIL,
                          f"core={sorted(lean_named)} schema={sorted(claimed)} — a "
                          f"binder outside this set can never carry a distance", src)
        return Result("proximity-capable types", OK,
                      f"{len(claimed)} base classes agree", src)

    # ── schema/prompts ↔ vocabulary ─────────────────────────────────────

    def predicates_exist(self) -> Result:
        defined = _nonempty(set(re.findall(r"^\s*(?:private )?def (\w+)", self.vocab, re.M)),
                            "Vocab.lean predicate definitions")
        named = _nonempty(set(re.findall(r"Pred\.(\w+)",
                              self.schema_text + self.prompt_code + self.prompt_plan)),
                          "Pred.* references in schema/prompts")
        ghosts = sorted(n for n in named - defined if n not in ("attr", "attrMilli"))
        src = ("carla/schema.json + prompts/*.txt → Pred.* references",
               "library/TrafficSpec/Core/Vocab.lean → def")
        if ghosts:
            return Result("predicate references", FAIL,
                          f"named but not defined: {ghosts}", src)
        return Result("predicate references", OK,
                      f"all {len(named)} references resolve", src)

    def binders_cover_the_data_model(self) -> Result:
        """Every entity type and named type group is bindable or declared not.

        The binder set had the defect `partially_available` was re-keyed to fix:
        no defined extent. Nothing said whether it was finished, so it grew only
        when a law needed something — and it ended up describing the corpus that
        had been formalized rather than the model the generator emits. The tell
        was `stopSignBinder` existing while `speedLimitSignBinder` did not,
        which left `Pred.isSpeedLimitSign` and `Pred.postedLimitSignAtMostKph`
        callable by no rule at all.

        A binder is a claim that the type is worth ranging over; membership of
        `unboundEntityTypes` is a claim that it is not, with a data reason. What
        this enforces is that a decision was made about every type.
        """
        types = set(_lean_ctors(self.scene, "EntityType"))
        groups = set(re.findall(r"^def (\w+Types) : List EntityType :=", self.scene, re.M))
        bound: set[str] = set()
        for _, arg in re.findall(r"^def (\w+Binder) \(label : String\) : Binder := \u27e8label, ([^\u27e9]+)\u27e9",
                                 self.grounding, re.M):
            arg = arg.strip()
            if arg.startswith("["):
                bound |= {x.strip().lstrip(".") for x in arg.strip("[]").split(",") if x.strip()}
            else:
                bound.add(arg)
        # A group binder makes every member bindable too.
        for g in list(bound & groups):
            m = re.search(r"^def " + re.escape(g) + r" : List EntityType :=\n\s+\[([^\]]*)\]",
                          self.scene, re.M)
            if m:
                bound |= {x.strip().lstrip(".") for x in m.group(1).replace("\n", " ").split(",") if x.strip()}
        m = re.search(r"^def unboundEntityTypes : List EntityType :=\n\s+\[([^\]]*)\]",
                      self.scene + self.grounding, re.M)
        declared = ({x.strip().lstrip(".") for x in m.group(1).replace("\n", " ").split(",") if x.strip()}
                    if m else set())
        src = ("library/TrafficSpec/Core/Grounding.lean \u2192 def *Binder, unboundEntityTypes",
               "library/TrafficSpec/Core/Scene.lean \u2192 EntityType, *Types")
        problems = []
        stranded = sorted(_nonempty(types, "EntityType constructors") - bound - declared)
        if stranded:
            problems.append(f"no binder ranges over, and not declared unbound: {stranded}")
        both = sorted(bound & declared)
        if both:
            problems.append(f"declared unbound yet bindable: {both}")
        ghost = sorted(declared - types)
        if ghost:
            problems.append(f"declared unbound but not an EntityType: {ghost}")
        orphan = sorted(groups - bound)
        if orphan:
            problems.append(f"type group in Scene.lean with no binder: {orphan}")
        if problems:
            return Result("binders cover the model", FAIL, "; ".join(problems), src)
        return Result("binders cover the model", OK,
                      f"{len(types)} types: {len(types) - len(declared)} bindable, "
                      f"{len(declared)} declared unbound; all {len(groups)} groups bound", src)

    def binder_census_keys(self) -> Result:
        """The gate's grounding budget must know every binder helper."""
        defined = _nonempty(set(re.findall(r"^def (\w+Binder)", self.grounding, re.M)),
                            "binder helpers in Grounding.lean")
        known = _nonempty(set(re.findall(r'"(\w+Binder)":', self.gate)),
                          "BINDER_CENSUS_KEY entries in check_spec.py")
        # The census is a measurement of one capture, not a fact about the
        # scene-graph format, so it lives with the tool that uses it rather than
        # in the schema — see check_spec.CAPTURE_ENTITY_CENSUS. Imported rather
        # than regex-parsed: a regex over a dict literal reads whatever the
        # formatting happens to allow, and mine silently saw one key per line.
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "_gate", self.repo / "tools" / "check_spec.py")
        gate_mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gate_mod)
        census = set(gate_mod.CAPTURE_ENTITY_CENSUS)
        mapped = set(re.findall(r'"\w+Binder":\s*"(\w+)"', self.gate))
        src = ("library/TrafficSpec/Core/Grounding.lean → def *Binder",
               "tools/check_spec.py → BINDER_CENSUS_KEY",
               "tools/check_spec.py → CAPTURE_ENTITY_CENSUS")
        if defined - known:
            return Result("binder budget coverage", FAIL,
                          f"binders the grounding budget cannot size: "
                          f"{sorted(defined - known)} — their cost is silently "
                          f"estimated as 1", src)
        if mapped - census:
            return Result("binder budget coverage", FAIL,
                          f"census keys referenced but absent: {sorted(mapped - census)}", src)
        return Result("binder budget coverage", OK,
                      f"{len(defined)} binders all sized from the census", src)

    # ── gate ↔ prompts ↔ report format ──────────────────────────────────

    def verdicts_documented(self) -> Result:
        emitted = {v for v in
                   set(re.findall(r'emit\("([A-Z_]+)"', self.gate))
                   | set(re.findall(r'finish\("([A-Z_]+)"', self.gate))
                   if v != "OK"}
        emitted = _nonempty(emitted, "verdict tokens in check_spec.py")
        table = _nonempty(set(re.findall(r"\|\s*`([A-Z_]+)`\s*\|", self.prompt_code)),
                          "the verdict table in prompt_code.txt")
        src = ("tools/check_spec.py → emit()/finish()",
               "prompts/prompt_code.txt → the verdict branch table")
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
        pairs = (("prompts/prompt_code.txt", "scripts/phases/code.py"),
                 ("prompts/prompt_plan.txt", "scripts/phases/plan.py"))
        bad = []
        for tmpl, filler in pairs:
            ph = _nonempty(set(re.findall(r"\{([a-z_]+)\}", _read(self.repo / tmpl))),
                           f"placeholders in {tmpl}")
            keys = _nonempty(_format_kwargs(_read(self.repo / filler)),
                             f"format kwargs in {filler}")
            if ph - keys:
                bad.append(f"{tmpl}: {sorted(ph - keys)} not supplied by {filler}")
        src = ("prompts/*.txt → {placeholders}",
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

    # ── docs ────────────────────────────────────────────────────────────

    def doc_paths_resolve(self) -> Result:
        """Cross-repo paths in the docs must exist from where their commands run."""
        broken = []
        for rel in ("CLAUDE.md", "GETTING_STARTED.md"):
            text = _read(self.repo / rel)
            for path in set(re.findall(r"(\.\.[./A-Za-z0-9_\-]+)", text)):
                if any(c in path for c in "*{}") or path.endswith("."):
                    continue
                if not (self.repo / path).exists():
                    broken.append(f"{rel}: {path}")
        src = ("CLAUDE.md, GETTING_STARTED.md → ../ references",
               "resolved relative to the repo root")
        if broken:
            return Result("documented paths", FAIL,
                          f"{len(broken)} do not resolve: {broken[:4]}", src)
        return Result("documented paths", OK, "all resolve", src)

    # ── schema content actually reaches the agent ───────────────────────

    #: Schema paths that exist for audit and provenance, not for the agent. Every
    #: other long-form entry must render into the prompt: a schema entry nobody
    #: reads is worse than no entry, because it looks like a delivered warning.
    #: Measured before this check existed: 55 of 118 long-form entries were never
    #: rendered, including that parked map geometry becomes a `.car` with full
    #: proximity edges — a finding that cost a day to establish and reached no
    #: agent.
    AUDIT_ONLY = (
        "provenance.",                      # which generator, which abstraction
        "time_base.evidence",               # the file:line behind the rate
        "capture_preconditions.how_to_fix", # an operator action, not the agent's
        "attribute_keys.no_float_ever",     # restated by decimal_note
        "time_base.how_to_use",             # restated in the time-base line
    )

    def schema_is_delivered(self) -> Result:
        from scripts.phases.plan import summarize_schema
        rendered = summarize_schema(self.schema, self.lib)
        src = ("carla/schema.json → every long-form entry",
               "scripts/phases/plan.py → summarize_schema()")

        def leaves(obj, path=""):
            if isinstance(obj, dict):
                for k, v in obj.items():
                    if k == "$comment":
                        continue
                    yield from leaves(v, f"{path}.{k}" if path else k)
            elif isinstance(obj, list):
                for v in obj:
                    yield from leaves(v, path)
            elif isinstance(obj, str) and len(obj) > 40:
                yield path, obj

        entries = _nonempty(list(leaves(self.schema)), "long-form schema entries")
        undelivered = sorted({
            p for p, text in entries
            if text[:40] not in rendered
            and not p.startswith(self.AUDIT_ONLY)
            and not p.endswith((".source", ".meaning"))
        })
        if undelivered:
            return Result("schema delivery", FAIL,
                          f"{len(undelivered)} entries render nowhere, so they "
                          f"warn nobody: {undelivered[:4]}", src)
        return Result("schema delivery", OK,
                      f"{len(entries)} entries: all delivered or audit-only", src)

    # ── generator, when available ───────────────────────────────────────

    def generator_agreement(self) -> Result:
        src = ("carla/schema.json → proximity bands + covered classes",
               "carla_sgg/sgg_abstractor.py → DEFAULT_PROXIMITY_* (sibling repo)")
        try:
            from carla_sgg import sgg_abstractor as ab
            from carla_sgg.actors import base_type_map, get_base_type
        except Exception as exc:            # noqa: BLE001
            return Result("generator agreement", SKIP,
                          f"carla_sgg not importable ({type(exc).__name__}); "
                          f"run with PYTHONPATH=../sg/carla_scene_graphs", src)
        bands = [[a, int(b)] for a, b in ab.DEFAULT_PROXIMITY_THRESHOLDS]
        claimed = [[a, b] for a, b in
                   self.schema["relation_labels"]["proximity_bands_closest_first"]]
        rename = {"safety_hazard": "safetyHazard", "near_coll": "nearCollision",
                  "super_near": "superNear", "very_near": "veryNear"}
        bands = [[rename.get(a, a), b] for a, b in bands]
        if bands != claimed:
            return Result("generator agreement", FAIL,
                          f"generator={bands} schema={claimed}", src)
        reachable = set(base_type_map.values()) | {"person", "speed_limit"}
        table = {pair[1] for pair in ab.DEFAULT_PROXIMITY_RELATIONS}
        covered = sorted(reachable & table)
        claimed_cov = sorted(self.schema["relation_coverage"]
                             ["proximity_and_angular_pairs"]["covered_base_classes"])
        if covered != claimed_cov:
            return Result("generator agreement", FAIL,
                          f"generator={covered} schema={claimed_cov}", src)
        return Result("generator agreement", OK,
                      f"bands and {len(covered)} covered classes match the generator", src)

    def unlifted_keys_are_unlifted(self) -> Result:
        """A key declared unlifted must really not be read by the adapter.

        `surface partitioned` proves the two sides are disjoint and complete
        against the generator. This proves the unlifted side is TRUE against the
        adapter — the two could agree with each other and both be wrong about
        what carla/adapter.py actually does.

        Every group must also give a reason, and the reason has to generalise:
        volume, redundancy with a lifted key, a value that is not a measurement,
        or a version-conditional branch. "No statute refers to it" was the old
        style of reason and describes one corpus, not the link.
        """
        ane = self.schema["available_not_exposed"]
        groups = {g: b for g, b in ane.items()
                  if not g.startswith("$") and isinstance(b, dict)}
        claimed = [k for b in groups.values() for k in (b.get("keys") or [])]
        src = ("carla/schema.json -> available_not_exposed.*.keys",
               "carla/adapter.py -> the keys it reads")
        quoted = set(re.findall(r"[\"'](\w+)[\"']", self.adapter))
        read = sorted(_nonempty(set(claimed), "declared unlifted keys") & quoted)
        dupes = sorted({k for k in claimed if claimed.count(k) > 1})
        unreasoned = sorted(g for g, b in groups.items()
                            if not any(isinstance(v, str) and len(v) > 40
                                       for k, v in b.items() if k != "keys"))
        problems = ([f"adapter DOES read: {read}"] if read else []) + \
                   ([f"declared twice: {dupes}"] if dupes else []) + \
                   ([f"no reason given: {unreasoned}"] if unreasoned else [])
        if problems:
            return Result("unlifted keys", FAIL, "; ".join(problems), src)
        return Result("unlifted keys", OK,
                      f"{len(claimed)} keys in {len(groups)} groups, none read "
                      f"by the adapter, every group reasoned", src)

    def reading_notes_cover_the_data_model(self) -> Result:
        """Every entity type and relation label is explained or declared plain.

        `partially_available` used to be keyed by statutory concept — one entry
        per thing the eight example laws happened to ask about. A concept-keyed
        list has no defined extent: nothing says whether it is finished, and it
        grows only when a new law exposes a gap. Keyed by the data element, the
        extent IS defined — Core/Scene.lean enumerates the whole model — so this
        check can hold the section to it.

        A `covers` entry is a claim that the element is explained. An element in
        `no_note_needed` is a claim that the enumeration alone is enough. Both
        are decisions someone made; what the check enforces is that a decision
        was made about every element, rather than about the ones a corpus
        happened to reach.
        """
        entity = set(_lean_ctors(self.scene, "EntityType"))
        rel = set(_lean_ctors(self.scene, "RelLabel"))
        section = self.schema["partially_available"]
        plain = section.get("no_note_needed", {})
        covered = {c for key, entry in section.items()
                   if not key.startswith("$") and key != "no_note_needed"
                   for c in (entry.get("covers") or [])}
        declared = set(plain.get("entity_types", [])) | set(
            plain.get("relation_labels", []))
        src = ("carla/schema.json -> partially_available.*.covers",
               "library/TrafficSpec/Core/Scene.lean -> EntityType, RelLabel")
        model = _nonempty(entity | rel, "Scene.lean enumerations")
        missing = sorted(model - covered - declared)
        unknown = sorted((covered | declared) - model)
        problems = ([f"neither covered nor declared plain: {missing}"]
                    if missing else []) + \
                   ([f"not in Scene.lean at all: {unknown}"] if unknown else [])
        if problems:
            return Result("reading notes cover the model", FAIL,
                          "; ".join(problems), src)
        return Result("reading notes cover the model", OK,
                      f"{len(model)} elements: {len(model & covered)} explained, "
                      f"{len(declared)} declared plain", src)

    def generator_surface_is_partitioned(self) -> Result:
        """Every key carla_sgg emits is on exactly ONE of two sides.

        `attribute_keys` is the lifted side, `available_not_exposed` the present-
        but-unlifted side. Disjoint and complete over the surface
        scripts/diagnostics/sgg_surface.py derives from `carla_sgg/*.py` — never from a
        capture. There is no third side: a tier of ABSENCES can only be written
        by imagining which laws would want them, so it cannot be frozen before
        the corpus, and absence is derivable anyway — these two sides enumerate
        everything that exists.

        Both sides must DECLARE their keys, in `tier_a`/`from_generator_key` and
        in a `keys` list. An earlier version of this check accepted a key
        mentioned anywhere in the section's prose, and that was too weak to be
        worth running: it passed while five keys sat on both sides at once and
        two (`light_All`, `light_NONE`) sat on neither.
        """
        from scripts.diagnostics.sgg_surface import surface, base_graph_only_keys
        src = ("scripts/diagnostics/sgg_surface.py -> derived from carla_sgg/*.py",
               "carla/schema.json -> attribute_keys, available_not_exposed")
        try:
            emitted = _nonempty(set(surface()), "carla_sgg attribute surface")
        except OSError as exc:
            return Result("surface partitioned", FAIL,
                          f"cannot read the generator: {exc}", src)

        kinds = self.schema["attribute_keys"]["kinds"]
        lifted = (set(self.schema["attribute_keys"]["tier_a"])
                  | {v["from_generator_key"] for v in kinds.values()
                     if isinstance(v, dict) and "from_generator_key" in v})
        unlifted: set[str] = set()
        for group, body in self.schema["available_not_exposed"].items():
            if group.startswith("$") or not isinstance(body, dict):
                continue
            unlifted |= set(body.get("keys") or [])

        both = sorted((emitted & lifted) & unlifted)
        neither = sorted(emitted - lifted - unlifted)
        # a declared key that the generator does not emit is a stale entry
        ghost = sorted(unlifted - emitted)
        problems = ([f"on BOTH sides: {both}"] if both else []) + \
                   ([f"on NEITHER side: {neither}"] if neither else []) + \
                   ([f"declared unlifted but not emitted: {ghost}"]
                    if ghost else [])
        if problems:
            return Result("surface partitioned", FAIL, "; ".join(problems), src)
        collapsed = base_graph_only_keys()
        note = json.dumps(self.schema["deciding_unsupported"])
        missed = sorted(k for k in collapsed if k not in note)
        if missed:
            return Result("surface partitioned", FAIL,
                          f"base-graph-only keys not accounted for: {missed}",
                          src)
        return Result("surface partitioned", OK,
                      f"{len(emitted)} keys emitted: "
                      f"{len(emitted & lifted)} lifted + "
                      f"{len(emitted & unlifted)} unlifted, disjoint and "
                      f"complete; {len(collapsed)} base-graph-only keys noted",
                      src)

    def preconditions_cover_the_parameters(self) -> Result:
        """Every caller-supplied generator parameter is accounted for.

        `capture_preconditions` used to be a hand-picked list, so its extent was
        whatever someone thought of — and it missed `ego_id` (which vehicle the
        privileged ego node is) and `ego_control` (whose dict form makes the
        control channels arrive ABSENT rather than wrong, and an absent decimal
        reads false, which is the missed-violation direction).

        Bounded now by the generator's own signature: scripts/diagnostics/sgg_surface.py
        reads the keyword arguments of SGG.__initialization, init_to_world,
        generate_graph_for_frame and process_to_junction_rsv, and each entry here
        declares the parameters it covers. A new parameter in carla_sgg fails
        this check instead of passing unnoticed.
        """
        from scripts.diagnostics.sgg_surface import parameters
        src = ("scripts/diagnostics/sgg_surface.py -> parameters() from carla_sgg/*.py",
               "carla/schema.json -> capture_preconditions.*.parameters")
        try:
            params = _nonempty(set(parameters()), "carla_sgg parameters")
        except OSError as exc:
            return Result("preconditions cover parameters", FAIL,
                          f"cannot read the generator: {exc}", src)
        declared = {p for v in self.schema["capture_preconditions"].values()
                    if isinstance(v, dict)
                    for p in (v.get("parameters") or [])}
        missing = sorted(params - declared)
        # a declared name that is not a parameter is either the simulator-side
        # note or a stale entry; only flag it when it looks like a bare name
        stale = sorted(d for d in declared - params if "(" not in d)
        problems = ([f"generator parameters accounted for nowhere: {missing}"]
                    if missing else []) + \
                   ([f"declared but not a generator parameter: {stale}"]
                    if stale else [])
        if problems:
            return Result("preconditions cover parameters", FAIL,
                          "; ".join(problems), src)
        return Result("preconditions cover parameters", OK,
                      f"{len(params)} caller-supplied parameters, all "
                      f"accounted for", src)

    def schema_cross_references_resolve(self) -> Result:
        """Every dotted schema pointer in a FROZEN file names something real.

        Core cites schema sections by dotted path. Those are prose, so nothing
        breaks when a section is renamed or removed — the pointer simply stops
        resolving, and a reader following it finds nothing. That is how
        `partially_available.which_half_of_the_roadway` outlived the schema's
        move to data-element keys: the section was gone, Core still pointed at
        it, and every other check stayed green.

        Scoped to the frozen artifacts and the prompts. Extending `sources` to
        `Rules/**` is one line, and worth doing once the rule corpus has been
        swept — it currently reports pointers into `unavailable` and
        `partially_lifted`, two top-level sections that were deliberately
        deleted, which is a corpus repair rather than a frozen-artifact one.
        """
        schema = json.loads(self.schema_text)
        # A pointer may name a top-level section, or a section one level down
        # written without its parent (`inter_lane_left_right_edges.do_not_use`).
        heads: dict[str, object] = dict(schema)
        for value in schema.values():
            if isinstance(value, dict):
                for k, v in value.items():
                    heads.setdefault(k, v)
        sources = sorted((self.lib / "TrafficSpec" / "Core").glob("*.lean")) + \
            sorted((REPO_ROOT / "prompts").glob("*.txt"))
        # Anything written AS a schema path: `schema.json` -> `a.b.c`, or a
        # dotted path whose head is a section name.
        cited = re.compile(r"schema\.json`?\s*(?:\u2192|->)\s*`?([A-Za-z_]\w*(?:\.\w+)*)")
        dotted = re.compile(r"\b(" + "|".join(map(re.escape, sorted(heads)))
                            + r")((?:\.\w+)+)")
        bad: list[str] = []
        seen = 0
        for path in sources:
            text = path.read_text(encoding="utf-8", errors="replace")
            paths = {m.group(1) for m in cited.finditer(text)}
            paths |= {m.group(0) for m in dotted.finditer(text)}
            for dotted_path in sorted(paths):
                seen += 1
                parts = dotted_path.split(".")
                node = heads.get(parts[0], ...)
                if node is ...:
                    bad.append(f"{path.name} {dotted_path} (no such section)")
                    continue
                for part in parts[1:]:
                    node = node.get(part) if isinstance(node, dict) else None
                    if node is None:
                        bad.append(f"{path.name} {dotted_path}")
                        break
        src = ("library/TrafficSpec/Core/*.lean, prompts/*.txt \u2192 schema paths",
               "carla/schema.json")
        if bad:
            return Result("schema cross-references", FAIL,
                          "pointer resolves to nothing: " + "; ".join(bad[:6]), src)
        return Result("schema cross-references", OK,
                      f"all {seen} dotted schema pointers resolve", src)

    def frozen_artifacts_are_law_free(self) -> Result:
        """Core and the schema carry no law, no rule, and no simulator outcome.

        Both are frozen BEFORE the pipeline sees a corpus or records anything, so
        neither may reference a particular statute or rule file, and neither may
        state a figure obtained by running the simulator. The failure this
        prevents is subtle: such a reference is not wrong, it is unfalsifiable
        later — the rule it cites can be deleted and re-formalized by the loop,
        and the capture it measured can be re-recorded, while the frozen file
        goes on asserting the old number.

        A worked EXAMPLE is still not mechanically separable from a format
        illustration — `sem_class` is documented by showing the shape of a
        blueprint id, and that is the file's job — so nothing here tries to
        catch one. What IS separable is the vocabulary that only appears when a
        frozen file was written with a particular law, rule, or evaluation in
        view, and each pattern below is chosen so that a legitimate DISCLAIMER
        does not trip it: a file may say a threshold is "a statute's business,
        not ours", but may not quote statutory text, describe applying a law to
        a driver, name a rule by its subject, or reason about how its own output
        will be scored.
        """
        import itertools
        targets = list((self.lib / "TrafficSpec" / "Core").glob("*.lean")) + \
            [REPO_ROOT / "carla" / "schema.json"]
        patterns = dict(LAW_FREE_PATTERNS, **FROZEN_ONLY_PATTERNS)
        src = ("library/TrafficSpec/Core/*.lean, carla/schema.json",
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
        targets = sorted((REPO_ROOT / "prompts").glob("*.txt"))
        patterns = dict(LAW_FREE_PATTERNS, **CAPTURE_FIGURE_PATTERNS)
        src = ("prompts/*.txt",
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

    def fixture_matches_its_generator(self) -> Result:
        """The checked-in fixture is what `sample_sync` emits today.

        `Carla/Sample.lean` is generated from `Core/Scene.lean`. Generated and
        checked in is a combination that drifts silently: the file keeps
        compiling and keeps passing the coverage check while describing an older
        data model, and the gate goes on measuring reachability against it. This
        compares the bytes rather than trusting that someone re-ran the sync.
        """
        from scripts import sample_sync
        path = self.lib / "TrafficSpec" / "Carla" / "Sample.lean"
        src = ("library/TrafficSpec/Carla/Sample.lean",
               "scripts/sample_sync.py \u2190 library/TrafficSpec/Core/Scene.lean")
        if not path.exists():
            return Result("fixture is current", FAIL,
                          "Sample.lean missing \u2014 run `run_spec sample`", src)
        current = path.read_text(encoding="utf-8")
        if sample_sync.HEADER_MARK not in current:
            return Result("fixture is current", FAIL,
                          "Sample.lean is hand-authored \u2014 run `run_spec sample` to "
                          "replace it with the derived one", src)
        if current != sample_sync.render(self.lib):
            return Result("fixture is current", FAIL,
                          "Sample.lean differs from what sample_sync emits \u2014 the data "
                          "model moved and the fixture did not; run `run_spec sample`", src)
        return Result("fixture is current", OK, "matches sample_sync output", src)

    def fixture_covers_every_type_and_label(self) -> Result:
        """The coverage fixture contains every EntityType and every RelLabel.

        `Carla/Sample.lean` is what the gate measures reachability against: a
        zero grounding count there is reported as "this rule cannot fire on real
        scene graphs". That verdict is only true if the fixture can express every
        binder, so a gap in it becomes a false accusation against a correct rule.

        The previous fixture was a hand-written narrative and carried three of
        the actor types the generator emits, which made every rule over a
        pedestrian, cyclist, bus, truck, motorcycle or van look unable to ground.
        Nothing detected that, because the fixture was judged by whether it
        looked realistic rather than by whether it covered the model.
        """
        fixture = self.lib / "TrafficSpec" / "Carla" / "Sample.lean"
        src = ("library/TrafficSpec/Carla/Sample.lean",
               "library/TrafficSpec/Core/Scene.lean -> EntityType, RelLabel")
        if not fixture.exists():
            return Result("fixture coverage", FAIL, "Sample.lean missing", src)
        text = fixture.read_text(encoding="utf-8")
        entity = _nonempty(set(_lean_ctors(self.scene, "EntityType")),
                           "EntityType constructors")
        rel = _nonempty(set(_lean_ctors(self.scene, "RelLabel")),
                        "RelLabel constructors")
        # a type is covered by `.ctor` in a builder call or a dedicated mk*
        builder_for = {"lane": "mkLane", "road": "mkRoad",
                       "junction": "mkJunction", "offRoad": "mkOffRoad",
                       "trafficLight": "mkTrafficLight", "stopSign": "mkStopSign",
                       "speedLimitSign": "mkSpeedLimitSign",
                       "landmark": "mkSpeedLimitLandmark"}
        missing_e = sorted(t for t in entity
                           if f".{t}" not in text
                           and builder_for.get(t, "\0") not in text)
        missing_r = sorted(l for l in rel if f".{l}" not in text)
        problems = ([f"entity types absent: {missing_e}"] if missing_e else []) \
            + ([f"relation labels absent: {missing_r}"] if missing_r else [])
        if problems:
            return Result("fixture coverage", FAIL, "; ".join(problems), src)
        return Result("fixture coverage", OK,
                      f"all {len(entity)} entity types and {len(rel)} relation "
                      f"labels appear in the fixture", src)

    # ── run ─────────────────────────────────────────────────────────────

    def checks(self) -> list[Callable[[], Result]]:
        return [self.entity_types, self.relation_labels, self.source_labels,
                self.proximity_bands, self.capture_rate,
                self.capture_rate_has_one_owner, self.proximity_types,
                self.predicates_exist, self.binder_census_keys,
                self.binders_cover_the_data_model,
                self.verdicts_documented, self.report_tags_parsed,
                self.placeholders_supplied, self.example_rule_exists,
                self.formula_operators, self.doc_paths_resolve,
                self.schema_is_delivered,
                self.generator_agreement,
                self.unlifted_keys_are_unlifted,
                self.reading_notes_cover_the_data_model,
                self.generator_surface_is_partitioned,
                self.preconditions_cover_the_parameters,
                self.frozen_artifacts_are_law_free,
                self.prompts_are_law_free,
                self.schema_cross_references_resolve,
                self.fixture_covers_every_type_and_label,
                self.fixture_matches_its_generator]

    def run(self, verbose: bool = False) -> int:
        results: list[Result] = []
        for check in self.checks():
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
