# Core v2 — a law-facing Lean library, and the validate / diagnosis pipeline around it

Status: **design plan, 2026-09-18**. Nothing in this document is implemented yet. It is the
plan the user asked for before any real change is made to `traffic-spec-agent/library/`.

Inputs it is built from:

- `traffic-spec-agent/ontology/ATOMS.md` (second draft, 2026-09-18): 136 atoms in eight
  families plus 31 derived concepts, enumerated from the Las Vegas corpus (state statute and
  municipal code), with `local` flags.
- `traffic-spec-agent/laws/example/laws.jsonl`: 322 obligations (NRS 484A/484B/484D, NRS 486,
  LVMC Title 11, after overlapping pairs were resolved to the narrower text), the first corpus
  Core v2 has to express.
- `CORE_V2_PLAN.md` §2.8 (file-by-file verdicts on the archived Core) and §3 (time without a
  frame rate). Those two sections are the *only* parts of the archived design this plan carries
  forward; the archived Core's types, enumerations and predicates are not a reference.

The library is **law-facing**: every type in Core is an ontology concept, every predicate is an
atom or a derived concept, and nothing in Core names a data source, a scene-graph field, a
simulator or a capture rate. Sources adapt to Core through a capability manifest, never the
reverse.

---

## 0. Design goals, stated as things the type system or the harness must make impossible

| goal | mechanism |
|---|---|
| G1 A rule cannot read the world except through atoms | rules import `Atoms`, `Derived`, `Formula`, `Reading` only; `World` is not importable from `Rules/` (gate + a Lean `private` boundary) |
| G2 An unobserved atom can never produce compliance or violation | atoms return `Option`; evaluation is Kleene three-valued; the manifest masks absent atoms to `none` before any frame is read |
| G3 No frame rate anywhere | every `Scene` carries a timestamp; temporal operators are metric over time **or over path length**; sampling adequacy is checked per operator application and reports `unknown` |
| G4 A rule states what it could not express | `Rule.residues` is a mandatory field; the gate cross-checks it with the plan's residues; the report prints it beside the verdict |
| G5 A judgement standard is operationalized, never read | there is no `jdg` family in Core; a standard in a clause is mapped by the plan to a §9 derived concept with concrete parameter values, recorded as an *operationalization claim* (standard, concept, values, convention); a rule whose only content is such a claim is marked `surrogate` |
| G6 Legal region classes are assumptions | `asm.*` ids are declared per run from the planner's claims and supplied per trace by the adapter (or `none`); rules reference them through one constructor whose evaluation is three-valued |
| G7 Four verdicts, not two | `Verdict := violated ∣ compliant ∣ notApplicable ∣ unknown (reason)`; applicability and obligation are separate formulas |
| G8 Identity is a track, not an id | groundings bind tracks with a bounded re-identification gap; a broken track inside a temporal window yields `unknown (identity)` rather than a false verdict |
| G9 Every `unknown` has a cause | `UnknownReason := absentAtom id ∣ samplingGap op ∣ identityGap ∣ assumptionMissing id ∣ parameterMissing name ∣ windowTruncated ∣ compositionUnknown ruleId`; diagnosis aggregates over it |
| G10 The atom set and the library agree in both directions | doctor: every `\`family.name\`` in `ATOMS.md` has exactly one `def` in `Atoms.lean`/`Derived.lean`, and every def there has exactly one line in `ATOMS.md` |

Non-goals: efficiency of the grounding cross-product (unchanged from v1; a later item), proofs of
rule properties beyond the kernel guards in `Tests/`, any RL reward interface.

---

## 1. Module map

The file decomposition, with the reason for each file, is fixed in **`CORE_V2_FILES.md`**
(2026-09-20), which supersedes the tree that stood here. In summary, in dependency order:

```
Core/Tri.lean          three-valued truth, Kleene, once
Core/Units.lean        exact milli-unit arithmetic; the only place a statute's unit meets a scene's
Core/Time.lean         timestamps, path length, Measure, Duration, sampling adequacy; no rate
Core/Ontology/*.lean   the attribute enumerations of ATOMS.md, generated from it
Core/World.lean        Scene and Trace as data, every field Option; not importable from Rules/
Core/Atoms.lean        the bijection with ATOMS.md §1–§7: one def per atom, reads one field, no arithmetic
Core/Assumptions.lean  asm.* lookup: the one door for legal region classes
Core/Params.lean       Reading and Operationalization: every number the statute did not state
Core/Formula.lean      the specification AST: inspectable, serializable, mutable; no `next`
Core/Derived.lean      the bijection with ATOMS.md §9, including the operationalization concepts
Core/Semantics.lean    Tri evaluation with metric operators and typed unknown reasons
Core/Rule.lean         applicability + obligation, four verdicts, surrogate flag, composition
Core/Grounding.lean    binders over classes, groundings over tracks with a re-identification gap, timelines
Core/Manifest.lean     what a source observes; mask before evaluation; support per rule
Core/Monitor.lean      the report, text and JSON
Core/Builders.lean     scenarios for witnesses and tests; not importable from Rules/
Core/Decode.lean       traces from JSON at run time; "none, not false" enforced once
Core/Export.lean       a rule as a program specification for the VLM visual-programming stage
Tests/*.lean           the concrete assertions Core cannot carry
Main.lean              the monitor executable
```

`Rules/<theme>/<slug>.lean` import `Atoms`, `Derived`, `Formula`, `Params`, `Rule` only;
`Witness/<slug>.lean` may add `Builders`. The type sketches in §2–§7 below stand.

## 2. Foundations: `Tri`, `Units`, `Time`

### 2.1 `Tri`

```lean
inductive Tri | t | f | u deriving DecidableEq, Repr
namespace Tri
def and : Tri → Tri → Tri   -- f dominates, then u, then t
def or  : Tri → Tri → Tri   -- t dominates, then u, then f
def not : Tri → Tri
def ofOption : Option Bool → Tri
def implies (a b : Tri) : Tri := or (not a) b
end Tri
```
Kleene strong logic. `and .f .u = .f` is what lets an applicability that is definitely false
decide `notApplicable` even when the obligation is unknown; `and .t .u = .u` is what makes an
unobserved atom in a conjunction poison the verdict rather than default it.

### 2.2 `Units`

Everything is an `Int` in a milli-unit: lengths in **mm**, speeds in **mm/s**, accelerations in
mm/s², angles in **millidegrees**, times in **ms**. Exact conversion functions:
`mph : Int → Int` (miles per hour → mm/s, exact as 4470.4 · v / 10 → use `(v * 44704) / 100`,
which is exact for integer v), `kmh`, `feet`, `inches`, `miles`, `seconds`, `minutes`.
Rules never write a raw literal next to an atom; they write `feet 500`, `mph 15`. The gate
enforces this syntactically (a decimal literal is allowed only as the argument of a `Units`
function or a `Reading` default). What survives from `Decimal.lean` is exactly this: the
milli-unit convention and exact integer conversion. String parsing does not.

### 2.3 `Time`

```lean
abbrev Timestamp  := Int         -- ms, monotone within a trace
abbrev PathLength := Int         -- mm, monotone per track (kin.path_length)
inductive Measure | time | path  -- what a window is measured in
structure Duration where (m : Measure) (d : Int)   -- ms or mm
```
Metric windows follow `CORE_V2_PLAN.md` §3 and add the path measure, because the corpus states
windows in both: "remain stopped until the green signal is shown" (time), "continuously during
not less than the last 100 feet traveled" (path), "within the course of 1 mile" (path), "waits
for two complete cycles" (event count). **Adequacy**: a window of length d over measure m is
*adequate* on a span iff every consecutive pair of observations in the span is at most d/2 apart
in m; otherwise the operator returns `.u` with `samplingGap`. Path adequacy uses the subject
track's `kin.path_length`; if that atom is `none` the path operators return `.u`
(`absentAtom kin.path_length`).

`next` is dropped (§2.8). `since`, `untilWithin`, `holdsFor`, `within` are kept and made metric;
`count` is added for event counting.

---

## 3. The world: `Ontology/*`, `World.lean`

### 3.1 Enumerations mirror `ATOMS.md` attribute lists — and nothing else

Each attribute enumeration in `ATOMS.md` becomes one inductive type. Examples:

```lean
inductive SignalIndication
  | circularGreen | circularYellow | circularRed
  | greenArrow (d : ArrowDir) | yellowArrow (d : ArrowDir) | redArrow (d : ArrowDir)
  | flashingYellowArrow (d : ArrowDir) | flashingRed | flashingYellow | dark
inductive ArrowDir | left | right | straight | uTurn
inductive LampColour | red | blue | amber | white
inductive LampMode   | flashing | rotating | steady
inductive ZoneKind   | school | schoolCrossing | pedestrianSafety | temporaryTrafficControl
                     | noPassing | highOccupancyLane | heavyVehicleLane | speedZone
                     | narrowHighway | hazardousPlace | parkingRestricted
```
A signal head displays a **set** of indications (`List SignalIndication`), because the corpus has
"circular green with a green turn arrow" and "steady red with a green turn arrow" as distinct
states. The doctor checks that every value listed in an `ATOMS.md` contract has a constructor
and vice versa (a string match on the contract's `{…}` lists; the enumerations are the one
place where `ATOMS.md` and Lean must agree token for token).

### 3.2 `World.lean`

```lean
abbrev TrackId := Nat
structure Kin where
  position  : Option (Int × Int)          -- mm, world frame
  heading   : Option (Int × Int)          -- unit vector × 1000
  velocity  : Option (Int × Int)          -- mm/s
  speed     : Option Int
  accelLong : Option Int
  yawRate   : Option Int                  -- millideg/s
  extent    : Option (Int × Int × Int)    -- half-length, half-width, half-height, mm
  steer     : Option Int                  -- millideg
  pathLen   : Option PathLength

structure Signals where
  turn : Option TurnIndicator; brake : Option Bool; hazard : Option Bool
  headlamp : Option HeadlampState; position : Option Bool; reverse : Option Bool
  warning : Option (List (LampColour × LampMode × Facing))
  siren : Option Bool; horn : Option Bool; hand : Option HandSignal
  door : Option (List DoorSide); smvEmblem : Option Bool

structure RoadUser where
  track   : TrackId
  classes : Option (List RoadUserClass)   -- a user may be several (school bus ∧ bus)
  eKind   : Option EmergencyKind; oKind : Option OfficialKind; eBike : Option EBikeClass
  occupants : Option Nat
  kin : Kin; sig : Signals

structure Structure where
  id : RegionId; kind : StructureKind; attrs : StructureAttrs     -- typed per kind
structure Device where
  id : DeviceId; kind : DeviceKind; state : DeviceState           -- typed per kind
  position : Option (Int × Int); governs : List RegionId; inoperative : Option Bool

structure Scene where
  t : Timestamp
  users : List RoadUser
  structures : List Structure
  devices : List Device
  occupies : List (TrackId × RegionId)
  relations : List MeasuredRelation      -- rel.* supplied measured, if the source has them
  env : Env
  asm : List (AsmId × Bool)              -- reading assumptions the adapter could supply
abbrev Trace := List Scene               -- sorted by t, strictly increasing
```
Everything a source might not have is `Option`. A source never writes `false` for "did not
look"; the adapter's contract is `none`, and the manifest tells the monitor which fields it
will *always* be `none` on.

### 3.3 Identity

A `TrackId` is stable while the source tracks the same body. Groundings (§7) bind tracks; when
a track ends and another begins within a re-identification gap g at a compatible position, the
adapter may link them, and Core treats the link as the same grounding; an unlinked gap inside a
temporal window is `unknown (identityGap)`. CARLA gives perfect tracks; video does not; the
rules are the same.

---

## 4. `Atoms.lean` — the bijection

One definition per atom id. Naming: `family.name` → `Atoms.family_name`. Signatures by kind:

```lean
-- class atoms (ru.*): a predicate on a road user
def ru_motor_vehicle (s : Scene) (x : TrackId) : Option Bool
def ru_emergency_vehicle (s : Scene) (x : TrackId) : Option Bool
def ru_emergency_vehicle_kind (s : Scene) (x : TrackId) : Option EmergencyKind   -- attribute accessor
-- measured atoms (kin.*, rel.*, st.* quantities): Option Int in milli-units
def kin_speed (s : Scene) (x : TrackId) : Option Int
def rel_surface_gap (s : Scene) (x y : TrackId) : Option (Int × Int)              -- longitudinal, lateral
-- structure and occupancy
def st_intersection (s : Scene) (r : RegionId) : Option Bool
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool
-- devices
def dev_traffic_signal_shows (s : Scene) (d : DeviceId) (i : SignalIndication) : Option Bool
def dev_governs (s : Scene) (d : DeviceId) (r : RegionId) : Option Bool
-- environment
def env_darkness (s : Scene) : Option Bool
```
Rules of the file:

- Every def reads `World` fields directly and does nothing else; no arithmetic beyond unit
  bookkeeping, no thresholds. A threshold is a rule's or a derived concept's business.
- Attribute accessors are the atom's id with a `_kind`/`_state`/`_colour` suffix; the doctor
  treats them as belonging to their atom.
- There is no `jdg` family. A judgement standard reaches Core only as a §9 derived concept
  with bound parameters (`drv.time_to_conflict`, `drv.time_gap`, `drv.sight_distance_adequate`,
  `drv.forced_halt`, …); the standard's words live on the plan node's operationalization claim.
- `Atoms.lean` is the only file `Rules/` may use to touch the scene. `World.lean` is imported by
  `Atoms.lean`, `Derived.lean`, `Grounding.lean`, `Builders.lean`, and by nothing under `Rules/`.

What survives from the archived `Vocab.lean` (§2.8): the squared-distance and heading-dot idioms,
the extent-aware surface-gap computation, the unit-checked speed comparison. They move into the
`rel_*` atoms and into `Derived.lean`; every line is rewritten under the `none` rule.

---

## 5. `Formula.lean`, `Semantics.lean`, `Derived.lean`

### 5.1 AST

```lean
inductive Formula
  | atom   (a : AtomRef)                          -- an Atoms.* def applied to binder variables, yielding Option Bool
  | cmp    (lhs : Term) (op : CmpOp) (rhs : Term) -- Term: measured atom | Reading param | Units literal | arithmetic on Terms
  | asm    (id : AsmId)                           -- reading assumption (three-valued)
  | not | and | or | implies
  | always | eventually | until                   -- untimed, over the rest of the trace
  | holdsFor (d : Duration) (φ)                   -- φ observed .t on every observation of a span of length ≥ d ending now
  | within   (d : Duration) (φ)                   -- φ observed .t at some observation ≤ d after now
  | since    (φ ψ)                                -- ψ held at some past observation and φ since then
  | untilWithin (d : Duration) (φ ψ)
  | count    (e : Event) (sinceψ : Formula) (n : Nat) (op : CmpOp)   -- number of rising edges of e since ψ last held
  | derived  (d : DerivedRef) (params : List Term) -- a Derived.* concept with its parameters bound
  | rule     (r : RuleId) (map : BinderMap)        -- another rule's obligation verdict, as Tri (composition)
```
Deliberately absent: `next` (§2.8), any frame count, any numeric literal without a `Units`
constructor (a `Term.lit` carries a unit tag and the gate rejects `lit` outside `Units`).

### 5.2 Semantics

`eval (φ : Formula) (τ : Trace) (i : Nat) (γ : Env) (ρ : Reading) : Tri`, structurally recursive,
with the metric cases reading `τ[j].t` for time and `Atoms.kin_path_length τ[j] (γ subject)` for
path. Each metric case first checks adequacy on the span it inspects; inadequate → `.u` and the
reason `samplingGap` is recorded on a side channel (`evalR : … → Tri × List UnknownReason`, the
version the monitor uses; `eval` is its first projection and what the unfolding lemmas are
stated about).

`count` gives "waits for two complete cycles": `count (edge (dev_traffic_signal_shows d circularGreen)) (since drv_stopped) 2 ≥`.

`rule r map` evaluates the referenced rule's obligation on the mapped binders at the same
instant and returns its Tri; the gate requires the reference graph to be acyclic and the
referenced rule to be accepted. This is how "lawfully within the crosswalk" and aggressive
driving (a conjunction of other rules' violations within one mile) are expressed without
duplicating any rule.

### 5.3 `Derived.lean`

Each `drv.*` in `ATOMS.md` §9 is one definition returning a `Formula` (so it can be inspected by
the gate and evaluated by the same semantics) or, for the few that are functions of the trace
(`drv.arrival_order`, `drv.queue_behind`, `drv.signal_cycles`, `drv.distance_while`), a
trace function wrapped as a `Term`. Parameters are explicit arguments; **defaults live in
`Reading`, not in `Derived`**:

```lean
def drv_stopped (x : Binder) (ε d : Term) : Formula :=
  .holdsFor ⟨.time, d⟩ (.cmp (.atom (kin_speed x)) .le ε)
def drv_cleared_line (x : Binder) (l : RegionId) (d : Term) : Formula := …   -- trailing end ≥ d past l
def drv_within_signed_zone (x : Binder) (k : ZoneKind) : Formula := …         -- since a begin sign governing x's lane, and no end sign since
def drv_distance_while (x : Binder) (φ : Formula) : Term                       -- path length over which φ has held continuously up to now
```
`drv_responding_emergency`, `drv_vulnerable_road_user`, `drv_priority_roadway`,
`drv_slower_than_posted`, `drv_extreme_lane` are pure compositions of atoms and are one-liners.

---

## 6. `Reading.lean` and `Assumptions.lean`

A **reading** is the quantification of what the statute leaves open, shared by the rule and by
the label. It is no longer human-authored: the *plan* proposes each value as an operationalization
claim, the review phase checks it, and the harness records it. Two kinds of entries:

```lean
structure Operationalization where
  standard : String          -- the clause's words, e.g. "so close as to constitute an immediate hazard"
  concept  : DerivedRef      -- the §9 concept that bounds it, e.g. drv.time_to_conflict
  params   : List (ParamName × Int × Unit)   -- concrete values, e.g. ("ttc.bound", 4000, ms)
  convention : String        -- where the value comes from (gap acceptance, headway, sight distance model)
  surrogate : Bool           -- true when the standard is the whole duty (ATOMS.md §8)

structure Reading where
  params : List (ParamName × Int × Unit)          -- every bound a rule uses, e.g. ("stop.rest_speed", 100, mm/s)
  ops    : List Operationalization                -- one per standard per rule
  classes: List (LegalAggregate × List RoadUserClass)  -- "vehicle" := {…}, "traffic" := {…}
```
- A rule references a parameter by name (`Term.param "ttc.bound"`); the gate checks the name
  exists in the run's reading and that every standard the plan node listed has an
  `Operationalization` whose concept the rule actually uses. A missing parameter at monitor time
  is `unknown (parameterMissing)`, never a default.
- A rule with `surrogate = true` is compiled and monitored like any other but is reported in its
  own column: its violations are evidence about a standard, not the law's own verdict, and the
  evaluation never counts them with the concrete rules.
- The evaluation reports, per operationalized parameter, a sensitivity sweep over the declared
  range; a verdict that flips inside the range on a labelled trace is *reading-sensitive*, a
  property of the law and not a defect of the rule.

**Assumptions** (`asm.*`) are the legal region classes of `ATOMS.md` §9: a plan node that needs
one declares it in `elements` with kind `assumption` and an id `asm.<snake_case>`; the harness
collects the run's assumption ids into `state/<run>/assumptions.json`; the adapter supplies a
value per scene where it can (map metadata, clock), otherwise `none`. There is no whitelist of
assumption names: the harness only enforces consistency (one id per element across the run) and
that every `asm.*` a rule uses was declared by its plan node. Evaluation: `Formula.asm id` →
`Tri.ofOption (scene.asm.lookup id)`.

---

## 7. `Rule.lean`, `Grounding.lean`, `Manifest.lean`, `Monitor.lean`

### 7.1 Rule and verdict

```lean
structure Rule where
  id        : String                     -- e.g. "NRS_484B_270_2b"
  lawRefs   : List String
  binders   : List Binder                -- subject first; each Binder names a class formula over ru.* atoms
  applicability : Formula                -- when the obligation is live
  obligation    : Formula                -- what must hold while live
  params    : List ParamName
  assumptions : List AsmId
  residues  : List Residue               -- {element, reason}: what the rule does not express
  uses      : List RuleId                -- rules referenced through Formula.rule

inductive Verdict | violated | compliant | notApplicable | unknown (why : List UnknownReason)
def verdictAt (r : Rule) (τ) (i) (γ) (ρ) : Verdict :=
  match evalR r.applicability …, evalR r.obligation … with
  | (.f, _),  _        => .notApplicable
  | (.u, w),  _        => .unknown w
  | (.t, _),  (.t, _)  => .compliant
  | (.t, _),  (.f, _)  => .violated
  | (.t, _),  (.u, w)  => .unknown w
```
Splitting applicability from obligation is what makes `notApplicable` honest: a red-light rule
on a trace with no signal is not "compliant", it is not engaged. It also gives the review phase
a place to check the antecedent separately from the consequent (the four-question decomposition
of `CORE_V2_PLAN.md` §2.6).

### 7.2 Grounding

What stays from the archived `Grounding.lean` (§2.8): a schema is a formula over binders,
groundings are distinct co-present tuples, `check` is ∀ groundings, liveness separates engaged
from vacuous. What changes: binders range over **class formulas** built from `ru.*` atoms
(`Binder.subject`, `Binder.any (classes)`), with no source-shaped restriction; groundings are
over tracks with the re-identification rule of §3.3; the per-grounding result is a
**timeline** `List (Timestamp × Verdict)` folded to an episode verdict by the monitor
(`violated` if any instant violated; else `unknown` if any instant unknown while applicable;
else `compliant` if applicable at some instant; else `notApplicable`). Liveness: a rule whose
applicability is never `.t` on a trace is reported `notApplicable (vacuous)` for that trace and
the witness check (§8.4) guarantees it is not vacuous everywhere.

### 7.3 Manifest

```lean
inductive Capability | exact | estimate (errorClass : String) | absent
abbrev Manifest := AtomId → Capability
def mask (m : Manifest) : Scene → Scene         -- sets every field of every absent atom to none
inductive Support | supported | partial (unknownAtoms : List AtomId) | unsupported
def support (r : Rule) (m : Manifest) : Support -- from the atoms r's formulas mention (syntactic)
```
The manifest is a JSON file per source, complete over every atom id (doctor check). `support`
is computed before any frame is read and printed in the report: it is the honest per-source
statement "this rule can be judged here / only partly / not at all".

### 7.4 Monitor

`check : List Rule → Trace → Reading → Manifest → Report`, where a `Report` row is
`(rule, support, grounding, episodeVerdict, timeline, unknownReasons histogram, residues)`.
The tab-separated text format of v1 is kept as one renderer; a JSONL renderer is added because
the diagnosis tooling reads it.

---

## 8. The pipeline around the library: validate and diagnose

The library alone terminates nothing; these are the checks that make the termination rule bite,
in the order a node passes through them.

### 8.1 Plan validation (`scripts/plan_validate.py`, extend what exists)

Already implemented: `elements` claims — atom ids exist in `ATOMS.md`; the same element maps to
the same atoms across the run; the mapping index is written on acceptance. To add:

- an element may be of kind `atom` (→ `family.name` ids), `derived` (→ `drv.*`), `assumption`
  (→ one `asm.*` id, and the harness records it), `operationalization` (→ a judgement standard's
  words, a `drv.*` concept, parameter values and their convention), or `residue` (→ a reason
  string). Every element of the clause the node
  formalizes must appear in exactly one kind. "Residue" is the only way to leave something out,
  and it is visible.
- the subject binder's class must be declared (`driver`, `rider`, `pedestrian` …) as a set of
  `ru.*` ids, so that a `pedestrian`-subject line does not silently get a vehicle subject.
- a node that names a judgement standard among its elements must carry an `operationalization`
  claim for it (standard, §9 concept, parameter values, convention, surrogate flag); a standard
  without one is rejected ("a standard is not a scene read"), and a node whose every element is a
  surrogate operationalization is accepted only with `surrogate: true`.
- `uses`: a node may declare that its rule composes another accepted rule (by node id); the
  harness checks acyclicity across the run.

### 8.2 Gate (`tools/check_spec.py`, rewrite)

Syntactic checks on the generated `Rules/<theme>/<slug>.lean` before Lean runs:

1. Imports ⊆ {`Core.Atoms`, `Core.Derived`, `Core.Formula`, `Core.Reading`, `Core.Rule`}.
   `Core.World`, `Core.Builders`, `Core.Grounding` are forbidden in `Rules/`.
2. Every identifier under `Atoms.` / `Derived.` resolves to a def whose id is in `ATOMS.md`
   (structural termination: v1 checked predicates against `Vocab.lean`; v2 checks against the
   ontology, which the doctor has already tied to the Lean file).
3. Numeric literals appear only inside `Units.*` calls or as `Term.param` defaults; no bare
   `Int` next to an atom.
4. `applicability` and `obligation` are both present and non-trivial (not `⊤`/`⊥`).
5. `params` ⊆ the run reading; every `jdg`-labelled param the plan declared is used.
6. `assumptions` ⊆ the node's declared `asm.*`; `residues` ⊇ the node's declared residues
   (the rule may discover more, never fewer).
7. `uses` ⊆ accepted rules, acyclic.
8. Witness file exists under `Witness/`, not under `Rules/` (kept from v1).
9. Operator set ⊆ the operators the prompt teaches (kept from v1's `formula_operators`).

### 8.3 Lean build (`scripts/lean_check.py`, unchanged in role)

`lake build` of the rule and its witness; kernel errors go back to the coding session as today.

### 8.4 Witness evaluation (new, replaces v1's two-valued `permit`/`forbid`)

Each rule ships a `permit` and a `forbid` scenario built with `Builders`. The harness evaluates
both under three manifests:

| manifest | permit must be | forbid must be |
|---|---|---|
| full (every atom `exact`) | `compliant` | `violated` |
| each used atom masked in turn | `unknown (absentAtom a)` for at least one instant | same |
| applicability-false variant of permit | `notApplicable` | — |

The first row is v1's evidence that the formula says something. The second row is new and is
the test of G2: if masking an atom the rule uses does *not* make the verdict unknown, the rule
is not really reading that atom (a proxy or a constant slipped in). The third row checks that
the rule can disengage.

### 8.5 Review phase (`prompts/prompt_review.md`, new; design in `CORE_V2_PLAN.md` §2.6)

Blind back-translation of the rule to prose, compared against the clause; burden of proof on
the mapping with contract citations; the four-question decomposition (subject right? trigger
right? obligation right? exceptions right?); a second model only where mutation testing shows
the first misses. Bounded retry K (default 2) → `disputed`, which is added to
`scripts/coverage.py::STATUSES`, the PROGRESS template and the plan prompt (the doctor's
`coverage_vocabulary` check then enforces it). Mutation operators used to calibrate the
reviewer: same-family atom substitution, proxy substitution taken from the "not a stand-in for"
clauses, atom deletion, relation argument swap, applicability/obligation swap, window measure
swap (time ↔ path), threshold sign flip.

### 8.6 Doctor v2 (`scripts/diagnostics/doctor.py`, extend the 14 checks)

Keep: prompts law-free, frozen artifacts law-free, ontology neutral, coverage vocabulary,
witness roles, witnesses outside the spec, file links, placeholders, formula operators. Replace
`predicates_exist` (prompt `Pred.*` ↔ `Vocab.lean`) with:

- **atoms bijection**: ids in `ATOMS.md` §1–§7 ↔ defs in `Atoms.lean` (both directions);
  `drv.*` ↔ `Derived.lean`; `jdg.*` ↔ `Reading.JdgLabel`; attribute value lists ↔ inductive
  constructors.
- **rules import whitelist**: no file under `Rules/` imports `World`/`Builders`/`Grounding`.
- **manifest completeness**: every registered source's `capabilities.json` names every atom id
  exactly once with a valid capability.
- **reading integrity**: every `ParamName` used by an accepted rule exists in the run reading with
  a unit; every operationalization names a `drv.*` concept of `ATOMS.md` §9.
- **index sync**: `Index.lean` lists exactly the accepted rules (kept from `index_sync.py`).
- **assumption registry**: every `asm.*` used by a rule is in `state/<run>/assumptions.json`.

### 8.7 Monitor and diagnosis (`scripts/run_spec.py monitor`, rebuilt; `scripts/diagnostics/*`, new)

Inputs: a trace set (adapter output), its manifest, the run reading, optional labels. Outputs
under `results/<run>/<source>/`:

- `support.json` — per rule: supported / partial (which atoms) / unsupported. Computed before
  any frame; this is the first number a source gets.
- `verdicts.jsonl` — per rule × trace × grounding: episode verdict and timeline.
- `unknown_reasons.json` — histogram of `UnknownReason` per rule; this is what says whether the
  gap is the source (absent atoms), the sampling (gaps), the reading (missing parameters), the
  adapter (identity) or the composition.
- `ablation.json` — for each atom the source supplies, mask it and count rules that flip to
  unknown: the atom's criticality on this corpus, which prioritises collector and perception
  work.
- `disagreements.md` — where labels exist, each (rule, trace) with verdict ≠ label, triaged by a
  fixed procedure: (1) *atom check* — recompute the atoms the rule used from the label's own
  annotation; if they differ from the adapter's, the fault is grounding; (2) *reading sweep* —
  vary the rule's parameters over the reading's declared ranges; if the label is reachable, the
  fault is quantification and the reading is what changes, for both rule and label; (3) *formal
  check* — otherwise the disagreement goes to the review phase as a mutation candidate with the
  trace as evidence; (4) *label check* — if review upholds the rule, the label is queried.
  Confusion matrices treat `unknown` and `notApplicable` as classes of their own; collapsing
  them into compliance is the error G2 exists to prevent.

---

## 9. What the first corpus needs from Core, checked line by line

Walking the 322 lines against §4–§6 above (the municipal and motorcycle lines were walked in the
same way; the atoms they added are listed in the provenance file §14):

- **Expressible with atoms and derived concepts alone, no residue**: right-half and lane
  discipline, overtaking left/right, no-passing zones, one-way, divided highway, stop and yield
  sign position, signal indications (all of 484B.307 and .310, including flashing yellow arrow,
  red-X/green-arrow lane signals and inoperative signals), school-bus stop, school-zone speeds
  when the beacon is present, U-turn prohibitions by device or median, turn positions, signal
  distances (path windows), parking distances from hydrants / crosswalks / rails / driveways
  and the parallel-within-18-inches rule, railroad stops and the completely-cross rule, headlamp
  and beam use, backup lamps, warning-lamp colours, HOV lane presence, centre-turn-lane distance
  limits, bicycle 3-ft clearance, move-over for stopped emergency and incident vehicles,
  following fire apparatus, slow vehicle turnout with five in queue, e-scooter speed; from the
  municipal code: the curb colour code, fire lanes, the fifteen-foot intersection setback,
  roundabout direction and exit-lane discipline, lane splitting and riding abreast, the
  taxistand right turn, reversible lanes, the pedestrian-mall and trail prohibitions where signed.
- **Expressible with a reading parameter standing for a `jdg` atom**: following too closely,
  reasonable speed, safe backing/turning/starting/U-turn, "immediate hazard" yields, due-care
  duties, impeding traffic, obstructed view.
- **Expressible only with an `asm.*` assumption**: business/residence district (U-turns, alley
  parking, signal distance 100 vs 300 ft, caravan spacing, stop before the sidewalk), city/town
  limits (left-lane rule), school in session / hours (when no beacon; every LVMC school rule),
  urban area, mountain highway, hours a curb zone or truck restriction is in effect, the City
  Clerk's street schedules where the sign is not observed, through-street designation, park
  grounds, the Pedestrian Mall and Central Traffic District boundaries.
- **Expressible only with a stated residue**: purpose of another's stop (283(1)(c), 353's
  "to receive or discharge", loading-zone "expeditious loading"), driver knowledge (208),
  intent (270(1)), horn use "when necessary", reckless, careless or inattentive driving (NRS
  653, LVMC 11.22.010/.020), occupant count (323) on every planned source, siren on sources
  without audio, unladen weight and passenger age (LVMC truck and motorcycle rules), protective
  footwear.
- **Requires rule composition** (`Formula.rule`): "lawfully within" clauses in 484B.307,
  aggressive driving 484B.650(1).

Nothing in the corpus needs an element outside `ATOMS.md`; where a line seemed to, the
provenance file §12 records where it went. That is the check that the second draft of the atom
set is complete *for this corpus*; the same walk is the acceptance test for any future corpus.

---

## 10. Implementation phases (two people; estimates are working days)

| phase | deliverable | acceptance | est. |
|---|---|---|---|
| A. Core skeleton | `Tri`, `Units`, `Time`, `Ontology/*`, `World`, `Atoms` (all 131), `Formula`, `Semantics`, `Derived` (31), `Reading`, `Assumptions`, `Rule`, `Grounding`, `Manifest`, `Monitor`, `Builders`; `Tests/*` | `lake build`; doctor atoms-bijection passes; `Tests` cover Kleene laws, adequacy boundary (time and path), one witness per derived concept | 8 |
| B. Harness | `plan_validate` element kinds + assumptions registry; gate rewrite; witness three-manifest evaluation; doctor v2 checks; `disputed` in coverage | doctor 20/20 on an empty library; a synthetic plan with a proxy substitution is rejected; a synthetic rule whose masked-atom witness stays `compliant` is rejected | 5 |
| C. Reading | `readings/nv_default.json`: the non-judgement defaults only (stop rest speed and dwell, darkness offsets, simultaneity τ, legal aggregates); judgement bounds are proposed per node by the planner as operationalization claims and land here on acceptance | every operationalization in the run has a concept, values and a convention; the reading is cited by both rule and label templates | 1 |
| D. Review | `prompt_review.md`, back-translation, mutation calibration set, K-bounded retry | recall ≥ 0.9 on the mutation set for same-family and proxy substitutions before the reviewer is trusted alone | 4 |
| E. First run | the 227 `driver` lines through plan → code → gate → witness → review | coverage report with counts per terminal status; residue list; `support.json` against the CARLA collector manifest and against a real-data manifest draft | 6 (wall clock; mostly agent time) |
| F. Diagnosis | monitor on collector traces with labels; `unknown_reasons`, `ablation`, `disagreements` | at least one disagreement of each triage class documented, and the reading revised once from evidence | 5 |

Order A → B → C → D → E → F; C can run beside A; D beside B.

---

## 11. Decisions this plan takes, and what it leaves to the user

Taken here (reverse any of them before phase A starts):

1. `drv.through_highway` is renamed `drv.priority_roadway` and admits yield-sign entrances.
2. Temporal windows have two measures, time and path; `next` is gone.
3. Applicability and obligation are separate formulas; four verdicts with typed unknown reasons.
4. Rule composition (`Formula.rule`) is allowed, acyclic, and gated.
5. Legal region classes are `asm.*` ids declared by the planner per element, not a curated list.
6. There is no `jdg` family; standards are operationalized per node as claims on §9 derived concepts, and standard-only rules are marked surrogate.
7. Witnesses are evaluated under masked manifests, and a rule that stays decisive when an atom it
   uses is masked is rejected.

Left open:

- whether `pedestrian`-, `rider`-, `motorcyclist`- and device-operator-subject lines (95 of
  322) are in the first run's coverage denominator or a later one;
- (resolved 2026-09-19) overlapping NRS/LVMC pairs are not formalized twice: the corpus keeps
  the narrower text and records the dropped id in `supersedes`; the five partial overlaps stay
  as separate lines (`laws/example/OVERLAPS.md`);
- the identity re-identification gap default for video sources (a manifest field, not a Core
  constant), to be set when the first real-data adapter exists;
- whether `count` (event counting) should be an operator or a derived concept — this plan makes
  it an operator because two corpus lines need it and a derived concept would have to re-implement
  edge detection.
