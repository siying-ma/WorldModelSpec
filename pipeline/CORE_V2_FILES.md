# Core v2 — the Lean files, and the reason for each

Status: **design, 2026-09-20**. Nothing here is implemented. This document fixes the file
decomposition of `library/TrafficSpec/Core/` and gives, for every file, what it holds, why it is
a file of its own, what it may not contain, and what fails if it is merged into a neighbour or
left out. It supersedes the module map in `CORE_V2_LEAN_DESIGN.md` §1; the type sketches there
(§2–§7) still apply and are referenced, not repeated.

Three facts about the downstream use drive the decomposition:

1. **The specs are consumed by a VLM visual-programming stage, not only by a Lean monitor.** A
   rule has to be exportable as a structured description — which atoms it observes, which derived
   concepts it computes with which parameter values, what temporal shape it has — so that a
   program can be synthesized to detect it from video. Anything that is only readable as Lean
   syntax is unusable there. This is why atoms, derived concepts, parameters and the formula AST
   are data, not Lean functions hidden in a rule, and why there is an `Export.lean`.
2. **Detection accuracy is the measure, so every source of a wrong verdict has to be attributable.**
   Unobserved atom, sampling too coarse, broken track, missing parameter, standard operationalized
   as a surrogate — each is a different file's responsibility, and each reports a distinct reason.
3. **The library is frozen before any law is seen.** Nothing in Core names a statute, a clause, a
   corpus, a data source, a threshold or a frame rate. The doctor enforces this over every file
   below, and the ontology file `ATOMS.md` is the only vocabulary Core may realize.

Dependency order (each file imports only files above it):

```
Tri → Units → Time → Ontology/* → World → Atoms → Assumptions → Params → Formula → Derived
    → Semantics → Rule → Grounding → Manifest → Monitor → Builders → Decode → Export → Main
```

`Rules/**` may import `Atoms`, `Derived`, `Formula`, `Params`, `Rule` and nothing else. `World`,
`Grounding`, `Builders`, `Decode` are never imported by a rule: a rule that could reach the scene
representation directly could bypass the atom contract, and one that could reach the grounding
could tune itself to the census. The gate checks the import list; Lean's `private` marks the
constructors of `World` so that even an import would not expose them.

---

## `Core/Tri.lean` — three-valued truth

**Holds.** `inductive Tri | t | f | u`; strong Kleene `and`, `or`, `not`, `implies`; `ofOption :
Option Bool → Tri`; the lemmas the semantics needs (`and_f_left`, `or_t_left`, De Morgan,
associativity, `and_u_iff`).

**Why its own file.** Every other file depends on the meaning of *unknown*, and the meaning must
be fixed once. Kleene strong logic is a choice with consequences: `and .f .u = .f` is what lets a
definitely-false applicability yield `notApplicable` when the obligation cannot be read, and
`and .t .u = .u` is what makes one unobserved atom in a conjunction poison the verdict rather than
default it to compliance. If a second author ever wrote a different `and` in a rule file, two
rules would disagree about the same missing observation. The file is short, has no dependencies,
and its lemmas are what `Tests/Tri.lean` checks by `decide`.

**Must not contain.** Anything about scenes, atoms or time. It is pure logic.

**If left out.** `Option Bool` arithmetic would be re-derived in every predicate, and the
"unknown never equals compliance" guarantee would rest on convention instead of a type.

## `Core/Units.lean` — exact quantities

**Holds.** The milli-unit convention (`Millimetres`, `MilliMetresPerSecond`, `Millideg`, `Ms` as
`Int` newtypes or abbreviations); exact conversion functions from the units law is written in
(miles per hour, kilometres per hour, feet, inches, miles, seconds, minutes) to the internal unit;
comparison helpers; no `Float`.

**Why its own file.** A statute states "3 feet", "500 feet", "15 miles per hour"; a scene states
metres per second. The conversion must be exact integer arithmetic (a foot is 304.8 mm exactly, a
mile per hour is 447.04 mm/s exactly), done in one place, so that a threshold written in a rule and
the same threshold written in a label cannot round differently. Keeping the constructors here also
gives the gate a syntactic rule: a numeric literal may appear in a rule only as the argument of a
`Units` function or a parameter default. That single rule prevents unit errors and undocumented
thresholds at once.

**Carried over from the archive.** The milli-unit idea and exact integer conversion (§2.8 of
`CORE_V2_PLAN.md`); the decimal-string parser is not carried over, because typed attributes arrive
from the adapter already parsed.

**If merged into World.** Rules would import World to reach the units, which the import whitelist
forbids for other reasons.

## `Core/Time.lean` — metric windows without a frame rate

**Holds.** `Timestamp` (ms), `PathLength` (mm), `inductive Measure | time | path`, `Duration :=
Measure × Int`, and the **adequacy predicate**: a span is adequate for a duration *d* in measure *m*
when consecutive observations are at most *d/2* apart in *m*. Also `spanBack`, `spanForward` over a
list of timestamps or path lengths.

**Why its own file.** The corpus states windows in two measures — "remain stopped until the green
signal is shown" (time), "continuously during not less than the last 100 feet traveled" (path),
"within the course of 1 mile" (path) — and both video and simulation sample irregularly. The only
honest semantics is over the observed instants with an explicit adequacy check; the check has to be
one definition, because it decides when the monitor says `unknown (samplingGap)` rather than
inventing a verdict between frames. Separating it from `Semantics` lets `Tests/Time.lean` probe the
boundary cases (a gap exactly *d/2*, a window that starts before the trace) without a formula in
sight.

**Must not contain.** Any constant rate. `captureHz` and `secondsToFrames` from the archive are
gone; there is no `next` operator anywhere.

## `Core/Ontology/RoadUser.lean`, `Structure.lean`, `Device.lean`, `Signal.lean`, `Env.lean` — the enumerations

**Hold.** One inductive type per attribute enumeration in `ATOMS.md`: `RoadUserClass`,
`EmergencyKind`, `OfficialKind`, `EBikeClass`, `Posture`; `StructureKind`, `MarkingType`,
`MarkingColour`, `ReservedClass`, `TurnSide`, `ParkingDesignation`, `CurbZoneKind`, `CurbColour`,
`ObstructionKind`; `SignalIndication` (with `ArrowDir`), `PedSignalState`, `LaneControlState`,
`SpeedSignKind`, `SignCode`, `ZoneKind`, `GateState`, `HumanRole`, `HumanIndication`;
`HeadlampState`, `LampColour`, `LampMode`, `Facing`, `HandSignal`, `DoorSide`; the `Env` record.

**Why five files, and why generated.** These are the one place where `ATOMS.md` and Lean must agree
token for token, and the doctor checks the agreement in both directions. Generating them from
`ATOMS.md` with a script makes the bijection hold by construction rather than by review, and
splitting them along the atom families keeps a change to a sign catalogue from recompiling the
kinematics. The VLM export (below) also reads these enumerations to know the value set a perception
query must return — a `SignalIndication` is a closed set of labels a classifier can be asked for.

**Must not contain.** Definitions. `SignalIndication.flashingYellowArrow` is a constructor with no
meaning attached; what it obliges is a rule's business.

## `Core/World.lean` — the scene, as data

**Holds.** `TrackId`, the `Kin` record (every field `Option`), the `Signals` record, `RoadUser`,
`Structure`, `Device`, `MeasuredRelation`, `Scene` (timestamp, users, structures, devices,
`occupies`, measured relations, environment, supplied assumptions), `Trace := List Scene` with the
monotone-timestamp invariant.

**Why its own file, and why unreachable from rules.** This is the adapter's output type and the
only place a data source's honesty is recorded: a source writes `none` for what it did not
observe, never `false`. Rules must not see it, because a rule that pattern-matches on `Scene`
fields has bypassed the atom contract — the exact failure the archived Core had, where 1,148 lines
of predicates read generator keys. `World` therefore sits below `Atoms` and above nothing a rule may
import; its constructors are `private` to the `Atoms`, `Derived`, `Grounding`, `Builders` and
`Decode` namespaces.

**Identity.** A `TrackId` is a source's track, not a persistent object id. Re-identification across
a track break is the adapter's claim, recorded as a link the grounding may follow (`Grounding`).

**If merged with Atoms.** The import whitelist could no longer separate "reads an atom" from
"reads the scene", and the doctor's bijection check would have nothing to bite on.

## `Core/Atoms.lean` — the bijection with `ATOMS.md`

**Holds.** Exactly one definition per atom id of `ATOMS.md` §1–§7, named `Atoms.family_name`, each
reading one field of `World` and nothing else: class atoms `Scene → TrackId → Option Bool`,
attribute accessors (`Atoms.ru_emergency_vehicle_kind : … → Option EmergencyKind`), measured atoms
`Option Int` in milli-units, structure atoms over `RegionId`, device atoms over `DeviceId` and an
indication, `rel_occupies`, and the environment atoms `Scene → Option Bool`.

**Why its own file.** It *is* the termination rule in Lean: a rule reads the world only through
these names, the doctor requires every `\`family.name\`` in `ATOMS.md` to have exactly one `def`
here and every `def` here to have exactly one line there, and the gate requires every identifier a
rule uses under `Atoms.` to resolve. Putting a threshold or a derived quantity in this file would
turn an atom into a rule fragment; the file therefore has a second doctor rule — no arithmetic
beyond unit bookkeeping, no comparison, no temporal lookback.

**For the VLM stage.** Each `Atoms.*` is the unit of perception: the export lists, per rule, the
atoms it reads and their contract text, and that list is the specification of the perception
programs a rule needs. An atom that is not observable on a source is what the manifest masks.

## `Core/Assumptions.lean` — legal region classes

**Holds.** `AsmId := String` (validated `asm.*`), `Scene → AsmId → Option Bool` lookup into the
scene's supplied assumptions, and nothing else.

**Why its own file.** A business district, a school day, a park's administrative speed limit are
facts a rule needs and no camera sees. They must reach the rule through one narrow door that says
so, that the manifest can declare `absent`, and that the export can list separately as "context
the deployment must supply". Folding them into `Atoms` would let a region class masquerade as an
observation; folding them into `Params` would make a per-trace fact look like a per-rule constant.
The ids are not enumerated here — the planner declares them per node and the harness records
them — so this file has no list to go stale.

## `Core/Params.lean` — readings and operationalizations

**Holds.** `ParamName`, `Unit`, `Reading` (named parameter values with units, legal aggregates such
as which classes count as "vehicle"), and `Operationalization` (the standard's words, the `drv`
concept that bounds it, the parameter values, the convention they cite, the `surrogate` flag).
`Term.param` in `Formula` resolves against a `Reading` at evaluation time.

**Why its own file.** This is where every number the statute did not state lives, and it is the
one artifact the rule and the label both cite, so that a standard is quantified exactly once. It
must be separate from the rule (a rule names a parameter, it does not own the value: the same rule
is evaluated under a sensitivity sweep) and separate from the atoms (a bound is not an
observation). The `Operationalization` record is what gives "reasonable and prudent" its concrete
meaning: without it a rule could name a standard and stop, which detects nothing. The gate rejects
a rule whose plan listed a standard without a matching `Operationalization` whose concept the rule
actually uses.

**Must not contain.** Default values. Defaults belong in the run's reading file; a default in Core
would be a threshold frozen before the law was seen.

## `Core/Formula.lean` — the specification language, as data

**Holds.** `Term` (measured atom, parameter, unit literal, arithmetic), `Formula`: atom, comparison,
assumption, boolean connectives, untimed temporal operators (`always`, `eventually`, `until`,
`since`), metric operators over a `Duration` in either measure (`holdsFor`, `within`,
`untilWithin`), `count` of rising edges since a condition, `derived` (a §9 concept applied to
binder variables and terms), and `rule` (another rule's obligation verdict under a binder map).

**Why an AST and not Lean propositions.** Three reasons, all downstream. The gate must inspect a
rule syntactically (which atoms, which operators, which parameters, is there a bare literal); the
export must serialize it for program synthesis; and mutation testing of the review phase must be
able to generate variants (swap a relation's arguments, change the measure of a window, delete an
atom). None of that is possible on an opaque `Prop`. The AST is also what keeps the operator set
closed: the prompt teaches exactly the constructors that exist, and the doctor checks the two agree.

**Deliberately absent.** `next` (frame-relative and meaningless under irregular sampling), any
numeric literal without a unit tag, any way to call an arbitrary Lean function.

## `Core/Derived.lean` — the concepts defined once

**Holds.** One definition per `drv.*` id of `ATOMS.md` §9, each returning a `Formula` over its
binder arguments and parameter terms, or, for the handful that are trace functions
(`arrival_order`, `queue_behind`, `signal_cycles`, `distance_while`, `time_to_conflict`,
`sight_distance_adequate`), a `Term`. Parameters are arguments; there are no defaults.

**Why its own file, below Semantics.** A derived concept is the vocabulary of manoeuvres and of
operationalized standards — stopped, turning, overtaking, yields-to, time-to-conflict, forced
halt. If rules built these inline, two rules would define "stopped" differently and the labels a
third way; if they were atoms, a source would be asked to observe "overtaking", which no source
does. Defining them once as `Formula` macros means the same semantics evaluates them, the gate can
see through them, and the export can hand the VLM stage a single implementation of each concept
with the parameter values a rule chose. The doctor holds this file to `ATOMS.md` §9 in both
directions, as `Atoms.lean` is held to §1–§7.

**The operationalization concepts** (`time_to_conflict`, `stopping_distance`,
`sight_distance_adequate`, `hard_deceleration`, `speed_below_traffic`, `lane_change_feasible`,
`forced_halt`, `officer_directed`) live here because they are exactly the derived quantities the
`Operationalization` records point at. They are the reason a standard can be given a concrete
meaning without a `jdg` atom: the standard maps to one of these, with values.

## `Core/Semantics.lean` — evaluation, three-valued and metric

**Holds.** `eval : Formula → Trace → Nat → Env → Reading → Tri`, structurally recursive on the
formula, with the metric cases consulting `Time.adequate` and the identity of the bound tracks;
`evalR`, the same evaluation returning also the list of `UnknownReason`s it accumulated (absent
atom, sampling gap, identity gap, missing assumption, missing parameter, truncated window,
composition unknown); the unfolding lemmas per operator.

**Why its own file.** The formula is data; its meaning is here and only here. Splitting syntax from
semantics is what allows the gate and the export to consume the syntax without the evaluator, and
allows `Tests/Semantics.lean` to state, per operator, the lemma the archived Core proved and the
new three-valued cases it did not: unknown propagation through each connective, the metric
operator at an inadequate span, `rule` composition when the referenced rule is itself unknown.
`evalR` exists because a monitor that says `unknown` without saying why is useless for diagnosis;
the reason list is what `Monitor` aggregates and what the disagreement triage reads.

## `Core/Rule.lean` — what a specification is

**Holds.** `Rule` (id, law references, binders with their class formulas, `applicability`,
`obligation`, the parameters, assumptions, operationalizations and residues it declares, the rules
it composes, the `surrogate` flag), `Verdict` (violated, compliant, notApplicable, unknown with
reasons), `verdictAt` combining applicability and obligation under Kleene logic, and
`UnknownReason`.

**Why applicability and obligation are two formulas.** A red-light rule on a trace with no signal
is not compliant, it is not engaged; a rule that says only `signal red → stopped` cannot tell the
two apart. The split gives `notApplicable` an honest meaning, gives the witness check a third
scenario to demand (applicability false), and gives the review phase the antecedent and the
consequent as separate objects to question. It is also what the VLM stage needs: the applicability
is the trigger a detector watches for, the obligation is what it verifies once triggered.

**Why `surrogate` is here.** A rule whose only content is an operationalized standard is compiled
and monitored like any other, but its verdicts are evidence, not the law's own verdict, and the
evaluation must never sum them with the concrete rules. The flag on the rule is what the monitor
and the export propagate.

## `Core/Grounding.lean` — binders, tracks, and the per-grounding timeline

**Holds.** `Binder` (a name and a class formula over `ru.*` atoms; the subject first), `Grounding`
(an assignment of tracks to binders, distinct and co-present within the window), enumeration of
groundings over a trace with the re-identification links the adapter supplied and a bounded gap,
`timeline : Rule → Trace → Grounding → List (Timestamp × Verdict)`, folding to an episode verdict,
and the liveness test (applicability true at some instant for some grounding).

**Why its own file.** This is the one part of the archived Core whose architecture survives
(§2.8): a schema is a formula over binders, groundings are distinct co-present tuples, `check` is
∀ groundings, liveness separates engaged from vacuous. What changes is the vocabulary (ontology
classes, no source-shaped binder tables) and identity (tracks with a bounded gap rather than one id
per trace, because a video tracker breaks where a simulator does not). It stays separate from
`Semantics` because evaluation is per instant and per assignment, while grounding is about *which*
assignments exist over a whole trace and how a broken track is treated; and separate from `Monitor`
because the cross-product cost is the known efficiency item and must be optimizable without
touching the report.

**Not importable from rules.** A rule that could see the census of tracks could special-case it.

## `Core/Manifest.lean` — what a source can observe

**Holds.** `Capability` (exact, estimate with an error class, absent), `Manifest := AtomId →
Capability` complete over `ATOMS.md`, `mask : Manifest → Scene → Scene` setting every field of an
absent atom to `none`, and `support : Rule → Manifest → Support` (supported, partial with the
unknown atoms, unsupported) computed from the rule's syntax before any frame is read.

**Why its own file.** The same rules run on CARLA, on an annotated real dataset and on perception
over video, and the only thing that differs is what each can see. That difference has to be a
declared input, checked complete by the doctor, and applied *before* evaluation, so that a rule
never reads a value a source could not have produced. `support` is the first number a source gets
and the most honest one: it says which rules this source can be judged against at all. For the VLM
stage the manifest is the interface the other way round — the list of atoms its perception programs
have to deliver, with the error class each is allowed.

## `Core/Monitor.lean` — the report

**Holds.** `check : List Rule → Trace → Reading → Manifest → Report`; a `Report` row per rule and
grounding with support, episode verdict, timeline, the histogram of unknown reasons, the residues
and the surrogate flag; two renderers, tab-separated text (kept from v1 for the gate) and JSON
lines (for the diagnosis tooling).

**Why its own file.** It composes everything below it and owns nothing else; the row format is a
contract with `tools/check_spec.py` and with `scripts/diagnostics/`, so changing it is a
cross-artifact change and must be visible as one. It also enforces the surrogate separation: a
report never mixes surrogate rows into the concrete tallies.

## `Core/Builders.lean` — scenarios for witnesses and tests

**Holds.** Constructors that build a `Scene` and a `Trace` from a few named quantities (a road user
of a class at a position with a speed, a signal in a state governing a lane, a crosswalk region),
time-based padding, and helpers to mask a trace under a manifest.

**Why its own file.** A witness must be indistinguishable from adapter output to a predicate, so
scenarios are built through the same `World` constructors, but a rule must never import the
builders (a rule that could build its own evidence proves nothing). The file is therefore reachable
from `Witness/**` and `Tests/**` only. It replaces the archived `Builders.lean` on the new `World`,
with padding by timestamp rather than frame count (§2.8).

## `Core/Decode.lean` — traces from JSON

**Holds.** `Trace` decoding from `Lean.Json` (the adapter's output format), with strict typing: an
absent key is `none`, a malformed value is a decode error, never `false`.

**Why its own file, and why it exists at all.** The archive converted every capture into a Lean
module and recompiled; that does not scale to thousands of video traces and it lets a capture sit
inside the library. With a decoder the monitor is an executable that reads traces at run time, the
library stays free of captures, and the adapter's contract is one JSON schema instead of a Lean
source template. The decoder is the *only* place a string from outside becomes a typed value, so
the "none, not false" rule is enforced in one function.

## `Core/Export.lean` — the rule as a program specification

**Holds.** Serialization of a `Rule` to a structured description: its binders and their classes;
the atoms it reads with their contract text (from a table generated from `ATOMS.md`); the derived
concepts it uses, each with its definition and the parameter values bound by the reading; its
assumptions; its operationalizations with convention and surrogate flag; its applicability and
obligation as the formula AST; its composed rules; its residues. Output as JSON.

**Why its own file.** This is the interface to the downstream task. A VLM visual-programming stage
does not read Lean; it needs, per rule, the list of perception primitives (atoms), the computations
over them (derived concepts with values), and the temporal program (the formula) — exactly the data
the AST design preserves. Keeping the export in Core, generated from the same `Rule` value the
monitor evaluates, is what guarantees that the program synthesized for detection and the formula
used for labelling are the same specification. It is also how spec quality becomes measurable in
the downstream sense the project cares about: a rule that exports with a standard left
unoperationalized, or with a residue at its trigger, is visibly not detectable before any video is
processed.

## `Tests/Tri.lean`, `Tests/Units.lean`, `Tests/Time.lean`, `Tests/Semantics.lean`, `Tests/Atoms.lean`, `Tests/Grounding.lean`

**Hold.** `#guard` and `example … := by decide` assertions: the Kleene laws; conversions exact for
representative values; adequacy at *d/2*; each operator's unfolding and its unknown propagation;
every atom exercised on a `Builders` scene with the attribute present and absent (generated from
`ATOMS.md`); re-identification across a gap, co-presence, liveness.

**Why outside Core.** Core carries no concrete values; the arithmetic still has to be pinned down
where `lake build` checks it (the archived `Tests/CoreArith.lean` had this role). Being a second
default target, a regression fails the build.

## `Main.lean` — the monitor executable

**Holds.** Argument parsing (trace files, manifest, reading, rule set), `Decode` → `Monitor.check`
→ renderer.

**Why.** The evaluation loop and the VLM stage both call the monitor as a program on many traces;
neither should need `lake env lean` on a generated harness. `Index.lean` (generated) supplies the
rule list.

---

## What is deliberately not a file

- **No `Vocab.lean`.** The archived vocabulary mixed atoms, derived predicates, thresholds and
  generator keys in one 1,148-line file; those roles are now `Atoms`, `Derived`, `Params` and the
  adapter respectively, and the doctor can hold each to its source.
- **No `Decimal.lean`.** Typed attributes arrive parsed; only the milli-unit arithmetic survives, in
  `Units`.
- **No `Scene.lean` enumerations from a generator.** Entity and relation kinds come from the
  ontology, in `Ontology/*`, generated from `ATOMS.md`.
- **No judgement family.** There is no `jdg` type and no `Reading.JdgLabel`; a standard reaches Core
  only as an `Operationalization` pointing at a `Derived` concept with values.

## How the doctor holds the files to their sources

| check | files |
|---|---|
| every atom id in `ATOMS.md` §1–§7 ↔ one `def` in `Atoms.lean`; every `drv.*` in §9 ↔ one `def` in `Derived.lean`; every attribute value in a contract ↔ one constructor in `Ontology/*` | Atoms, Derived, Ontology |
| `Rules/**` import only `Atoms`, `Derived`, `Formula`, `Params`, `Rule` | Rules |
| no numeric literal in a rule outside a `Units` constructor or a parameter default | Rules, Units |
| every `Formula` constructor is taught by the prompt and no other operator is | Formula, prompts |
| every registered manifest is complete over the atom ids | Manifest, `sources/*.json` |
| `Monitor` row format ↔ `check_spec.NodeReport` and the diagnostics parsers | Monitor, tools |
| `Export` field set ↔ the downstream consumer's schema (recorded in `pipeline/`) | Export |
| Core, `ATOMS.md` and prompts are law-free and source-free | all |

## Build order for the implementation

`Tri`, `Units`, `Time` (a day, with tests) → generator for `Ontology/*` from `ATOMS.md` and the
doctor bijection check → `World`, `Atoms`, `Assumptions`, `Params` → `Formula`, `Derived`,
`Semantics` with the unfolding lemmas → `Rule`, `Grounding`, `Manifest`, `Monitor` → `Builders`,
`Decode`, `Main` → `Export`, whose schema is agreed with the VLM stage before it is written.

---

## Implementation notes — batches 1–6 landed (2026-09-20)

Everything above `Export` is implemented and builds (`lake build` in `library/`: the `TrafficSpec`
library, `TrafficSpecTests`, `TrafficSpecWitness`, and `lake build monitor` for the executable).
`Export` is deliberately not written. Where the implementation departs from the file plan above,
this section is the record; the plan text is left as written.

- **`Core/Unknown.lean` is an extra file.** `UnknownReason` and the reason-carrying result `R`
  (with `settle`, which keeps reasons only while the value is undecided and de-duplicates them)
  sit between `Tri`/`World` and `Formula`, because `Derived`, `Semantics` and `Rule` all need them
  and `Rule` is above `Semantics`. `Rule.lean` therefore holds `Verdict` and `verdictAt` only.
- **Quantities are exact rationals, not milli-integers.** `Units.Q` is `num : Int / den : Nat > 0`;
  km/h and mph are not integer-exact in milli-units and the derived concepts divide. The one
  square root (`Geom.norm`) is an integer square root at micrometre resolution.
- **Formula bindings are `Binding`, not `Env`.** `Env` is the world's environment record
  (`env.*` atoms); the variable environment of a formula is `Binding`.
- **Finite-trace policy in `Semantics`.** `holdsFor` needs its window covered and adequate;
  `within`/`untilWithin` are true on a witness, false only when the window is covered, otherwise
  `windowTruncated`; unbounded `eventually`/`until` carry the unobserved future as an unknown
  disjunct and `always` as an unknown conjunct, so on a finite trace `always φ` is never true
  (`eval_always_ne_t`). A rule's obligation is written for an instant; the sweep over instants in
  `Grounding.timeline` is the "always".
- **`count edge sinceφ op n`** counts rising edges of `edge` since the *start of the latest run*
  of `sinceφ` (Semantics.runStart), so "since the vehicle stopped" reads as intended.
- **Derived concepts with a mode take it as a literal argument**, not as a second concept:
  `drv_arrival_order [a, b, kind, "before"|"same"]`, `drv_turning [x, "left"|"right"]`,
  `drv_extreme_lane [x, side]`, `drv_passing_side [a, b, side]`. `Derived.derivedNames` and
  `Derived.reads` (the atoms each concept reads) are the tables the doctor holds against
  `derivedIds`.
- **Per-class unobservability.** `RoadUser.unobservedClasses` makes membership in a class the
  source cannot tell `none` rather than `false`; `Manifest.mask` uses it for absent `ru.*` atoms
  and drops structures/devices of an absent kind.
- **Rule composition** (`Formula.rule id map`) reads the composed rule as complied-with (true),
  violated (false) or unknown; a rule that is not engaged counts as complied with. Composition is a
  callback built by `Rule.context` with fuel equal to the library size.
- **Grounding identity.** Links are accepted when the new track first appears after the old one
  was last seen, within `Manifest.reidGap`; instants inside an accepted gap are
  `identityGap`, a binder absent outside its identity's span leaves the rule not engaged.
- **`Scenario.window`.** A witness names the closed timestamp range its expected episode verdict
  speaks about, because a lookback window is truncated at the start of every finite trace.
- **Monitor text format** (tab-separated): `SOURCE`, `RULE`, `GROUND`, `TL` (runs of equal
  verdict), `UNK`, `RESIDUE`, `SUMMARY concrete|surrogate` — see the header of `Monitor.lean`.
  `tools/check_spec.py` still parses the v1 format and must be redrafted to this one.
- **Decode JSON**: field names are the snake_case of `World.lean`; numbers decode exactly from
  mantissa/exponent; an absent or `null` key is `none`, a malformed value is an error with its
  path. Reading and manifest documents are decoded in the same file.
- **Helpers in `Atoms.lean` that are not atoms** carry non-atom names (`regionsOfKind`,
  `devicesOfKind`, `regionPosition`, `regionBoundary`) so the doctor's bijection is exact.
- **Doctor.** `scripts/diagnostics/library_v2.py` adds: ontology generated in sync, atoms
  bijection (ids ↔ defs ↔ Semantics dispatch), derived bijection (ids ↔ defs ↔ `derivedNames` ↔
  `reads`), rule import whitelist, manifests complete (`library/manifests/*.json`, none yet). The
  eight v1 checks that describe `Vocab.lean` and the v1 gate/prompts are skipped until the redraft.
- **Not yet redrafted against v2:** `tools/check_spec.py`, `prompts/*.md`, `scripts/index_sync.py`
  (Index.lean now declares `allRules : List Rule`; the witness root declares `allScenarios`).

- **Training split (2026-09-20).** `traffic-spec-agent/library/splits/train/TrafficSpec/Core/{Atoms.lean,
  Ontology/*}` are the training-only variants of the two split files, derived by
  `ontology_provenance/nrs_tools/atoms_train.py` from `ontology/ATOMS_train.md` and
  `laws/example/split_atoms.json`; a training run swaps them over the full files. Nothing imports
  them in place. What the unsplit Core files carry only because of a test line is recorded in
  `laws/example/SPLIT_AUDIT.md`; the doctor's `training split` check holds the three artifacts to
  their sources.
