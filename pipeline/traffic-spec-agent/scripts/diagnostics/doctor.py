"""Cross-check every agent-facing claim against the artifact it describes.

The pipeline's output quality depends on two prose artifacts — `carla/schema.json`
and `prompts/*.md` — that describe things they do not own: the Lean core, the
adapter, the scene-graph generator, the gate's verdict set. Prose drifts. Every
one of these checks corresponds to a drift that actually happened:

* Both prompts told the coding agent to read a worked example at a path that had
  stopped existing, and that example was its only in-context source for the
  formula notation.
* The gate gained two verdicts the coding prompt's branch table never listed, so
  an agent could receive a verdict with no instruction for it.
* A repo-root operator doc described the report format without a line the report
  had started emitting, and described a schema tier that had been deleted.
* `attribute_keys` claimed vehicle light booleans exist on the ego, which the
  generator never emits for it.
* `capture_preconditions` cited `scripts/sgg_surface.py` after that module moved
  under `scripts/diagnostics/`, and the only path-resolving check read the
  repo-root `*.md` alone — so the schema, which the agent is handed verbatim,
  had its file references checked by nothing.

No check here asks whether a rule grounds on a bundled sample trace. That
fixture was hand-built from `Core/Builders.lean` rather than recorded, so it
could only ever confirm that a rule binds against data written to make it bind;
whether a spec fires correctly is asked of a real capture and its human labels,
by `scripts/diagnostics/capture_eval.py`.

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
        self.prompt_code = _read(repo_root / "prompts" / "prompt_code.md")
        self.prompt_plan = _read(repo_root / "prompts" / "prompt_plan.md")

    # ── schema ↔ Lean core ──────────────────────────────────────────────

    def source_labels(self) -> Result:
        """Every Lean label the adapter maps onto exists in `Core/Scene.lean`.

        The schema used to hold its own copy of this mapping and this check
        compared the two. The copy listed 18 of the adapter's 21 generator
        spellings — `controlsTrafficOf` among the missing — so it was an
        incomplete duplicate of something in-repo and derivable. What is worth
        checking is the direction that can actually break a build: the adapter
        emitting a constructor Core does not declare.

        The mapping is many-to-one by necessity, not by choice: the generator
        emits more than one spelling for some relations, so no exact
        one-to-one naming exists to be adopted.
        """
        sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "carla"))
        from adapter import REL_LABELS                  # noqa: E402
        core = _nonempty(set(_lean_ctors(self.scene, "RelLabel")),
                         "RelLabel constructors")
        used = set(REL_LABELS.values())
        src = ("carla/adapter.py -> REL_LABELS",
               "library/TrafficSpec/Core/Scene.lean -> inductive RelLabel")
        unknown = sorted(used - core)
        if unknown:
            return Result("rsv source labels", FAIL,
                          f"adapter maps onto labels Core does not declare: "
                          f"{unknown}", src)
        unmapped = sorted(core - used)
        return Result("rsv source labels", OK,
                      f"{len(REL_LABELS)} generator spellings map onto "
                      f"{len(used)} of Core's {len(core)} labels"
                      + (f"; {len(unmapped)} label(s) the adapter never emits: "
                         f"{unmapped}" if unmapped else ""), src)

    def capture_rate(self) -> Result:
        """`Core/Scene.lean::captureHz` and `adapter.py::ASSUMED_CAPTURE_HZ` agree.

        Two copies, and both have to exist: Core needs the value to turn seconds
        into frames, and the adapter needs it to refuse a capture recorded at
        another rate. Neither can read the other. A disagreement rescales every
        duration in every rule silently, so this is the one duplicate worth
        keeping and therefore worth checking. The schema used to hold a third
        copy; it now points at Core instead.
        """
        m = re.search(r"def captureHz : Nat := (\d+)", self.scene)
        core = int(m.group(1)) if m else -1
        m2 = re.search(r"ASSUMED_CAPTURE_HZ = (\d+)", self.adapter)
        adapter = int(m2.group(1)) if m2 else -1
        src = ("library/TrafficSpec/Core/Scene.lean -> captureHz",
               "carla/adapter.py -> ASSUMED_CAPTURE_HZ")
        if core != adapter or core < 0:
            return Result("capture rate", FAIL,
                          f"core={core} adapter={adapter} — a mismatch rescales "
                          f"every duration in every rule", src)
        return Result("capture rate", OK, f"{core} Hz in both copies", src)

    def capture_rate_has_one_owner(self) -> Result:
        """No description restates the capture rate as a figure.

        The rate had several copies — a schema key, the precondition
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
        m = re.search(r"def captureHz : Nat := (\d+)", self.scene)
        hz = int(m.group(1)) if m else 0
        ms = int(1000 / hz)
        patterns = {
            rf"\b{hz}\s*(?:Hz|hz)\b": f"{hz} Hz",
            rf"\b{hz}\s+frames?\b": f"{hz} frames",
            rf"\bat\s+{hz}\b": f"at {hz}",
            rf"\b{ms}\s*(?:ms|milliseconds?)\b": f"{ms} ms",
        }
        src = ("carla/schema.json -> every description",
               "library/TrafficSpec/Core/Scene.lean -> captureHz")
        bad = []
        # Core owns the value. The schema's own prose
        # used to restate it twice more ("secondsToFrames 1 = 20", "50 ms
        # frames") — inside the section this check was trusting, and the
        # millisecond spelling is derived, so a changed rate would have left it
        # quietly wrong. Every field except the owner is checked.
        # Every section, enumerated from the file. A hard-coded list here was
        # its own maintenance liability: it broke twice as sections were
        # removed, and it would silently stop checking a section that was added.
        for section, body in self.schema.items():
            if section.startswith("$") or not isinstance(body, dict):
                continue
            for key, entry in body.items():
                if key.startswith("$"):
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
            return Result("rate never restated", FAIL,
                          f"{'; '.join(sorted(set(bad)))} — name "
                          f"Core/Scene.lean::captureHz instead; a copy nothing "
                          f"cross-checks is the copy that drifts", src)
        return Result("rate never restated", OK,
                      f"{len(patterns)} spellings of the rate appear in no "
                      f"description; Core/Scene.lean::captureHz is the only "
                      f"declaration", src)

    def predicates_exist(self) -> Result:
        defined = _nonempty(set(re.findall(r"^\s*(?:private )?def (\w+)", self.vocab, re.M)),
                            "Vocab.lean predicate definitions")
        named = _nonempty(set(re.findall(r"Pred\.(\w+)",
                              self.schema_text + self.prompt_code + self.prompt_plan)),
                          "Pred.* references in schema/prompts")
        ghosts = sorted(n for n in named - defined if n not in ("attr", "attrMilli"))
        src = ("carla/schema.json + prompts/*.md → Pred.* references",
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
        # Both spellings of a `Binder` literal, and across a line break: the
        # anonymous constructor `\u27e8label, X\u27e9` and the structure instance
        # `{ label, types := X }`. Core has used each in turn, and when the
        # extractor knew only one it reported every EntityType as stranded —
        # a loud failure, but one that named the wrong artifact. The union is
        # asserted non-empty below so the next spelling fails as VACUOUS
        # instead, which names this extractor.
        binder_defs = re.findall(
            r"^def (\w+Binder) \(label : String\) : Binder :=\s*"
            r"(?:\u27e8\s*label\s*,\s*([^\u27e9]+?)\s*\u27e9"
            r"|\{\s*label\s*,\s*types\s*:=\s*(.+?)\s*\})",
            self.grounding, re.M | re.S)
        for _, angle, brace in binder_defs:
            arg = (angle or brace).strip()
            if arg.startswith("["):
                bound |= {x.strip().lstrip(".") for x in arg.strip("[]").split(",") if x.strip()}
            else:
                bound.add(arg)
        _nonempty(bound, "binder definitions in Grounding.lean")
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

    def binders_reach_the_agent(self) -> Result:
        """Every binder helper must appear in the table the agent is shown.

        `binder_census_keys` above reads the `def` line, so it stays green
        however the binder's BODY is written. The prompt's table is generated by
        matching the body, and when `Binder` gained a field the constructions
        moved to named fields and the table silently rendered empty — twenty
        binders known to the gate, none offered to the agent, and every check
        passing. A rule cannot use a binder it is never told about, so this
        compares the rendered table against the same set the gate sizes.
        """
        from scripts.phases.plan import summarize_binders
        defined = _nonempty(set(re.findall(r"^def (\w+Binder)", self.grounding, re.M)),
                            "binder helpers in Grounding.lean")
        rendered = set(re.findall(r"^- `(\w+Binder)`",
                                  summarize_binders(self.lib), re.M))
        src = ("library/TrafficSpec/Core/Grounding.lean → def *Binder",
               "scripts/phases/plan.py → summarize_binders")
        missing = sorted(defined - rendered)
        if missing:
            return Result("binders reach the agent", FAIL,
                          f"defined but never shown to the agent: {missing} — "
                          f"a binder the prompt omits cannot be used", src)
        return Result("binders reach the agent", OK,
                      f"all {len(defined)} binder helpers appear in the "
                      f"generated table", src)

    def portability_covers_the_data_model(self) -> Result:
        """Every lifted key and every relation label has exactly one portability
        class — or the ledger is silently partial.

        `perception/portability.json` is frozen on the same terms as the schema
        and answers a different question: not what the generator emits, but
        which of it a camera could recover. Its usefulness rests entirely on
        being COMPLETE — a key with no class reads, to anyone consulting it, as
        a key with nothing to worry about. Completeness was checked by hand when
        the file was written, and a hand check does not survive the next entity
        type someone adds to `Core/Scene.lean`.

        Both directions are checked: a class listing a key that no longer
        exists is as much a divergence as a key with no class.
        """
        path = self.repo / "perception" / "portability.json"
        src = ("perception/portability.json",
               "carla/schema.json → attribute_keys",
               "library/TrafficSpec/Core/Scene.lean → RelLabel")
        if not path.exists():
            return Result("portability covers the model", FAIL,
                          "perception/portability.json is missing — the prompt "
                          "renders a block saying nothing is known", src)
        try:
            led = json.loads(path.read_text(encoding="utf-8"))
        except ValueError as exc:
            return Result("portability covers the model", FAIL,
                          f"not valid JSON: {exc}", src)

        def keyed(node, name=None):
            if isinstance(node, dict):
                if "kind" in node and name:
                    yield name
                for k, v in node.items():
                    yield from keyed(v, k)
            elif isinstance(node, list):
                for v in node:
                    yield from keyed(v, name)

        lifted = _nonempty(set(keyed(self.schema["attribute_keys"])),
                           "lifted attribute keys in carla/schema.json")
        labels = _nonempty(set(_lean_ctors(self.scene, "RelLabel")),
                           "RelLabel constructors in Scene.lean")

        classed_keys, classed_labels = [], []
        for blk in (led.get("attribute_keys") or {}).values():
            classed_keys += (blk or {}).get("keys") or []
        for blk in (led.get("relation_labels") or {}).values():
            classed_labels += (blk or {}).get("labels") or []

        problems = []
        for what, model, classed in (("attribute key", lifted, classed_keys),
                                     ("relation label", labels, classed_labels)):
            cset = set(classed)
            if model - cset:
                problems.append(f"{what}s with no class: {sorted(model - cset)}")
            if cset - model:
                problems.append(f"{what}s classed but absent from the model: "
                                f"{sorted(cset - model)}")
            dupes = sorted({x for x in classed if classed.count(x) > 1})
            if dupes:
                problems.append(f"{what}s in more than one class: {dupes}")
        if problems:
            return Result("portability covers the model", FAIL,
                          "; ".join(problems), src)
        return Result("portability covers the model", OK,
                      f"{len(lifted)} attribute keys and {len(labels)} relation "
                      f"labels, each in exactly one class", src)

    # ── gate ↔ prompts ↔ report format ──────────────────────────────────

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

        Its predecessor read the repo-root `*.md` only, and inside those only
        `../`-prefixed cross-repo paths. So the two artifacts the agent is
        actually handed — `carla/schema.json` and both prompt templates — had
        their file references checked by nothing, and `capture_preconditions`
        went on pointing at `scripts/sgg_surface.py` for a whole release after
        that module moved into `scripts/diagnostics/`. A pointer that resolves
        to nothing is not an error the agent can see: it reads as a citation,
        and the claim it was supposed to support becomes unverifiable.

        Deliberately NOT a source here: `carla/adapter.py` and
        `tools/check_spec.py`, whose paths are CLI examples naming files the run
        PRODUCES (`library/TrafficSpecEval/Captured.lean` is generated and
        git-ignored), so their absence on a clean tree is correct rather than
        drift.
        """
        sources = sorted(self.repo.glob("*.md")) + \
            sorted((self.repo / "prompts").glob("*.md")) + \
            [self.repo / "carla" / "schema.json"]
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
        _nonempty(seen, "file paths in the docs, prompts and schema")
        src = (f"{', '.join(d.name for d in sources)} \u2192 file paths",
               "resolved against the repo root and library/")
        if broken:
            return Result("file links", FAIL,
                          f"{len(broken)} name nothing on disk: "
                          f"{sorted(set(broken))[:4]}", src)
        return Result("file links", OK,
                      f"{len(sources)} artifact(s), all {seen} in-repo file "
                      f"path(s) resolve", src)

    # ── schema content actually reaches the agent ───────────────────────

    #: Schema paths that exist for audit and provenance, not for the agent. Every
    #: other long-form entry must render into the prompt: a schema entry nobody
    #: reads is worse than no entry, because it looks like a delivered warning.
    #: Measured before this check existed: 55 of 118 long-form entries were never
    #: rendered, including that parked map geometry becomes a `.car` with full
    #: proximity edges — a finding that cost a day to establish and reached no
    #: agent.
    AUDIT_ONLY = (
        # `matches` is how doctor assigns a derived key to a reason group. The
        # agent is handed the reason, never the regex.
        ".matches",
        # "declared in Core" pointers: provenance for a reader of this file,
        # not something the agent needs — it is handed the value itself.
        "relation_coverage.proximity_and_angular_pairs.covered_base_classes_declared_in_core",
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
            and not p.endswith(".matches")
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
        """`Core/Scene.lean` agrees with the generator's own default tables.

        THE check that matters once the schema stops duplicating Core: Core is
        now the single declaration of the bands and the proximity-capable types,
        and this is what keeps that declaration true to the thing it describes.

        Reads the tables as source literals instead of importing `carla_sgg`.
        The import drags in `carla`, which lives only in the simulator's own
        environment on an interpreter too old for `ast.unparse` — so the
        diagnostics used to need a second interpreter, and under it the derived
        surface came back quietly smaller. One interpreter, no simulator.
        """
        from .sgg_surface import proximity_bands, proximity_base_classes
        from .sgg_surface import _src as sgg_src
        src = ("library/TrafficSpec/Core/Scene.lean -> distanceBands, "
               "proximityTypes",
               "carla_sgg/sgg_abstractor.py -> DEFAULT_PROXIMITY_* literals")
        try:
            gen_bands = proximity_bands()
            table = set(proximity_base_classes())
            actors = sgg_src("actors.py")
        except (OSError, RuntimeError) as exc:
            return Result("generator agreement", SKIP,
                          f"generator not readable ({type(exc).__name__})", src)

        # The generator's band names are snake_case; Core's are the Lean
        # constructors. Compare the METRES, which is what a rule depends on,
        # and the count, which is what a missing band would change.
        m = re.search(r"def distanceBands.*?\[(.*?)\]", self.scene, re.S)
        core_bands = [(n, int(v)) for n, v in
                      re.findall(r"\.(\w+),\s*(\d+)", m.group(1) if m else "")]
        if [v for _, v in core_bands] != [v for _, v in gen_bands]:
            return Result("generator agreement", FAIL,
                          f"band metres differ: core={[v for _, v in core_bands]} "
                          f"generator={[v for _, v in gen_bands]}", src)

        # Which of the generator's table entries a CARLA blueprint can actually
        # reach: `base_type_map`'s values plus the branches of `get_base_type`.
        reachable = set(re.findall(r":\s*'([a-z_ ]+)'", actors)) | {
            "person", "speed_limit"}
        covered = sorted(reachable & table)
        core_prox = re.search(r"def proximityTypes.*?\[(.*?)\]", self.scene, re.S)
        core_types = sorted(
            {"person" if t == "pedestrian" else t
             for t in re.findall(r"\.(\w+)", core_prox.group(1) if core_prox else "")})
        if core_types != covered:
            return Result("generator agreement", FAIL,
                          f"proximity-capable types differ: core={core_types} "
                          f"generator={covered}", src)
        return Result("generator agreement", OK,
                      f"{len(core_bands)} band metres and {len(covered)} "
                      f"proximity-capable types match the generator", src)

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
        """Every key carla_sgg emits is lifted, or matched by a documented reason.

        Neither side is a list any more. The lifted side is
        `carla/adapter.py::CONSUMED_ATTRS`, the generator-side keys the adapter
        actually reads; the unlifted side is the remainder, and each group in
        `available_not_exposed` claims a family of it with a REGEX rather than an
        enumeration. So a key the generator gains falls into a group by itself,
        and only a key matching nothing — or matching two groups, which would
        make the reason ambiguous — fails here.

        Both sides used to be hand-written lists in the schema. They were exactly
        right, which was the problem: correct today, with nothing keeping them
        correct tomorrow, and an omission that no check could see because the
        check compared the list against itself.
        """
        from .sgg_surface import surface, base_graph_only_keys
        sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "carla"))
        from adapter import CONSUMED_ATTRS             # noqa: E402
        src = ("scripts/diagnostics/sgg_surface.py -> derived from carla_sgg",
               "carla/adapter.py -> CONSUMED_ATTRS; carla/schema.json -> "
               "available_not_exposed.*.matches")
        try:
            emitted = _nonempty(set(surface()), "carla_sgg attribute surface")
        except OSError as exc:
            # The generator is a sibling repository and may not be checked out.
            # That is a legitimate configuration — the loop needs nothing from
            # it — so this is a skip, not a failure.
            return Result("surface partitioned", SKIP,
                          f"generator not present ({type(exc).__name__}); the "
                          f"schema's reason patterns are what the gate falls "
                          f"back to", src)
        lifted = emitted & set(CONSUMED_ATTRS)
        unlifted = sorted(emitted - set(CONSUMED_ATTRS))
        groups = {g: b.get("matches") or []
                  for g, b in self.schema["available_not_exposed"].items()
                  if not g.startswith("$") and isinstance(b, dict)}
        unmatched, ambiguous = [], []
        for key in unlifted:
            hits = [g for g, pats in groups.items()
                    if any(re.search(p, key) for p in pats)]
            if not hits:
                unmatched.append(key)
            elif len(hits) > 1:
                ambiguous.append(f"{key}->{hits}")
        stale = sorted(set(CONSUMED_ATTRS) - emitted)
        problems = ([f"no reason group matches: {unmatched}"] if unmatched else []) \
            + ([f"matched by two groups: {ambiguous}"] if ambiguous else []) \
            + ([f"adapter consumes keys the generator never emits: {stale}"]
               if stale else [])
        collapsed = base_graph_only_keys()
        note = json.dumps(self.schema["partially_available"])
        missed = sorted(k for k in collapsed if k not in note)
        if missed:
            problems.append(f"base-graph-only keys not accounted for: {missed}")
        if problems:
            return Result("surface partitioned", FAIL, "; ".join(problems), src)
        return Result("surface partitioned", OK,
                      f"{len(emitted)} keys emitted: {len(lifted)} lifted + "
                      f"{len(unlifted)} unlifted, every unlifted key matched by "
                      f"exactly one of {len(groups)} reason groups", src)

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
            return Result("preconditions cover parameters", SKIP,
                          f"generator not present ({type(exc).__name__})", src)
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
            sorted((REPO_ROOT / "prompts").glob("*.md"))
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
        src = ("library/TrafficSpec/Core/*.lean, prompts/*.md \u2192 schema paths",
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

        Also checks that the adapter and the harness agree on the root's name,
        which is the way this arrangement would break silently: an adapter
        writing to a root the harness does not import, or the reverse.
        """
        from ..lean_check import ADAPTER_BANNER, EVAL_LIB_ROOT, captures_under
        src = ("library/TrafficSpec/**.lean, carla/adapter.py",
               f"captures belong to {EVAL_LIB_ROOT}/, its own library root")
        stray = captures_under(self.lib / "TrafficSpec")
        if stray:
            names = ", ".join(str(p.relative_to(self.lib)) for p in stray[:5])
            return Result("captures out of the rule tree", FAIL,
                          f"agent-readable capture(s): {names}", src)
        adapter = self.adapter
        if f'EVAL_NAMESPACE = "{EVAL_LIB_ROOT}"' not in adapter:
            return Result("captures out of the rule tree", FAIL,
                          "carla/adapter.py does not declare EVAL_NAMESPACE = "
                          f"\"{EVAL_LIB_ROOT}\", so the module it writes is not "
                          "the one the harness imports", src)
        if ADAPTER_BANNER not in adapter:
            return Result("captures out of the rule tree", FAIL,
                          "carla/adapter.py no longer writes the banner this "
                          "check recognises a capture by; a capture in the rule "
                          "tree would now go unnoticed", src)
        lakefile = _read(self.lib / "lakefile.lean")
        if f"lean_lib «{EVAL_LIB_ROOT}»" not in lakefile:
            return Result("captures out of the rule tree", FAIL,
                          f"library/lakefile.lean declares no {EVAL_LIB_ROOT} "
                          "library root, so a capture written there cannot be "
                          "built by name", src)
        n = len(captures_under(self.lib / EVAL_LIB_ROOT))
        return Result("captures out of the rule tree", OK,
                      f"{n} converted capture(s), all under {EVAL_LIB_ROOT}/; "
                      f"adapter, lakefile and harness agree on the root", src)

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

    def gap_ledger_is_sound(self) -> Result:
        """The gap ledger parses, and its owners and states mean what they say.

        `scripts/gaps.py` holds the invariants; this runs them outside a run, so
        a hand-edited ledger is caught before the loop reads it. The one worth
        naming: a gap whose owner is `generator` must be `permanently_blocked`,
        because `carla_sgg/` is frozen byte-wise and a gap scheduled against it
        would sit open forever while the clauses it blocks looked merely
        pending.
        """
        from ..gaps import CLOSED_STATES, OWNERS, load
        src = ("gaps/ledger.jsonl", "scripts/gaps.py::OWNERS, STATES")
        ledger, problems = load(self.repo)
        if problems:
            return Result("gap ledger", FAIL, "; ".join(problems[:4]), src)
        if not ledger:
            return Result("gap ledger", SKIP,
                          "no gap has been recorded yet", src)
        retired = sum(1 for g in ledger.values() if g.state == "retired")
        closed = sum(1 for g in ledger.values() if g.state in CLOSED_STATES)
        owners = sorted({g.owner for g in ledger.values()})
        return Result("gap ledger", OK,
                      f"{len(ledger)} gap(s) across owners {', '.join(owners)}; "
                      f"{retired} retired, {closed} closed, all invariants hold",
                      src)

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

    def portability_origins_are_sound(self) -> Result:
        """Every element the ledger says video has, and the graph does not,
        declares WHERE it stops — and only one origin means "unsupported".

        The failure this prevents was real and silent. With a single axis the
        ledger said `video_only` about elements CARLA exposes and this pipeline
        simply does not take, and a planning session reading that records the
        clause `unsupported` — the one verdict that is inherited and never
        re-examined — when the honest verdict is a capability gap with an owner.
        Weather is the clean case: the simulator sets it through
        `carla.WeatherParameters` and the capture script writes it beside every
        capture.

        So: each entry needs an `origin` from the declared set, and an
        `evidence` string, because an origin nobody can check is a claim about
        the simulator made from memory. The origin vocabulary must also match
        the gap ledger's owners, which is what lets "what is missing" and "who
        supplies it" be one question.
        """
        path = self.repo / "perception" / "portability.json"
        src = ("perception/portability.json",
               "scripts/gaps.py::OWNERS, carla_sgg source, CARLA API reference")
        if not path.exists():
            return Result("portability origins", FAIL,
                          "perception/portability.json is missing", src)
        led = json.loads(path.read_text(encoding="utf-8"))
        origins = led.get("origins") or {}
        if not origins:
            return Result("portability origins", FAIL,
                          "the ledger declares no `origins` vocabulary, so "
                          "nothing says where an element stops being available",
                          src)
        bad = []
        entries = {k: v for k, v in (led.get("video_only") or {}).items()
                   if not k.startswith("$")}
        if not entries:
            return Result("portability origins", SKIP,
                          "the ledger names nothing video has and the graph "
                          "does not", src)
        for name, entry in entries.items():
            if not isinstance(entry, dict):
                bad.append(f"{name}: not an object, so it can carry no origin")
                continue
            origin = entry.get("origin")
            if origin not in origins:
                bad.append(f"{name}: origin {origin!r} is not one of "
                           f"{', '.join(origins)}")
            if not entry.get("evidence"):
                bad.append(f"{name}: no `evidence` — an origin nobody can check "
                           f"is a claim about the simulator made from memory")
            if entry.get("class") == "video_only" \
                    and origin != "absent_from_carla":
                bad.append(f"{name}: class `video_only` with origin "
                           f"`{origin}` — the simulator has it, so a clause "
                           f"needing it is blocked on a gap, not unsupported")
        if bad:
            return Result("portability origins", FAIL, "; ".join(bad[:5]), src)
        absent = sum(1 for e in entries.values()
                     if e.get("origin") == "absent_from_carla")
        return Result("portability origins", OK,
                      f"{len(entries)} element(s) the graph lacks: {absent} "
                      f"absent from the simulator, {len(entries) - absent} "
                      f"a capability gap with a named owner", src)

    def checks(self) -> list[Callable[[], Result]]:
        return [ self.source_labels, self.capture_rate,
                self.capture_rate_has_one_owner,
                self.predicates_exist, self.binder_census_keys,
                self.binders_reach_the_agent,
                self.portability_covers_the_data_model,
                self.portability_origins_are_sound,
                self.binders_cover_the_data_model,
                self.verdicts_documented, self.report_tags_parsed,
                self.placeholders_supplied, self.example_rule_exists,
                self.formula_operators, self.repo_paths_resolve,
                self.schema_is_delivered,
                self.generator_agreement,
                self.reading_notes_cover_the_data_model,
                self.generator_surface_is_partitioned,
                self.preconditions_cover_the_parameters,
                self.frozen_artifacts_are_law_free,
                self.prompts_are_law_free,
                self.captures_stay_out_of_the_rule_tree,
                self.witnesses_are_outside_the_specification,
                self.witness_roles_agree,
                self.coverage_vocabulary,
                self.gap_ledger_is_sound,
                self.schema_cross_references_resolve]

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
