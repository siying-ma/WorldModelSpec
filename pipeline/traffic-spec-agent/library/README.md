# `library/` — the TrafficSpec Lean library

Three parts, with different owners:

| part | path | written by | changes when |
|---|---|---|---|
| **Core** | `TrafficSpec/Core/**` | hand, before any law is seen (the ontology files are generated from `ontology/ATOMS*.md`) | only by an explicit ontology or Core change, never during a run |
| **Nodes** | `TrafficSpec/Rules/<Body>/<NodeId>.lean`, `TrafficSpecWitness/<Body>/<NodeId>.lean` | one coding session per node, accepted only by the harness's own gate call | a node is accepted, or reverted by integrate |
| **Concepts** | `TrafficSpec/Concepts/<family>/<name>.lean`, `TrafficSpecWitness/Concepts/<family>/<name>.lean` | one coding session per concept record, gated and then reviewed | a concept is accepted; never edited afterwards (a fix is a superseding concept) |
| **Registries** | `TrafficSpec/Index.lean`, `TrafficSpecWitness.lean` | `harness/lean/index_sync.py` | every gate and integrate run; never by hand |

`TrafficSpec/Tests/**` pins Core's arithmetic and semantics at build time; `Main.lean` is the
`monitor` executable; `splits/` holds the full and training variants of the split Core files.

---

## 1. Core, bottom-up

Core is five layers, one folder each under `TrafficSpec/Core/`. A file imports only files of its own
layer or of the layers above it, and every file imports only files above it in this table.

| layer | file | what it is |
|---|---|---|
| `Foundations/` | `Foundations/Tri.lean` | Strong-Kleene truth `t / f / u`; `and f u = f`, `and t u = u`, proved. |
|  | `Foundations/Units.lean` | Exact rationals `Q` over SI units and the only way to write a number: `Units.feet`, `Units.mph`, `Units.seconds`, … No `Float`. |
|  | `Foundations/Time.lean` | `Measure` (`time` or `path`), `Duration`, the adequacy rule (observations in a window of length d at most d/2 apart), per-instant window sweeps. |
| | `Foundations/Handles.lean` | `TrackId`, `RegionId`, `DeviceId`, `AsmId`: the identifiers by which a scene, a formula and a reason for unknown name a track, a region, a device and an assumption. |
|  | `Foundations/Unknown.lean` | `UnknownReason` (why a value is `u`), `R` = value + reasons, `QR` = quantity or reason, `RangeAgg`. |
|  | `Foundations/Temporal.lean` | Whole-trace operators (always, eventually, until, since, holdsFor, within, untilWithin, edge counts, distance-while), one pass each. |
| `Vocab/` | `Vocab/Ontology/Ids.lean` | `atomIds`, `primitiveIds`. **Generated.** |
|  | `Vocab/Ontology/{RoadUser,Structure,Device,Signal}.lean` | Enumerations the ontology lists (`RoadUserClass`, `StructureKind`, `DeviceKind`, `SignalIndication`, …) with their string codecs. **Generated.** |
|  | `Vocab/World.lean` | The scene as data: `Scene`, `RoadUser`, `Kin`, `Structure`, `LaneInfo`, `Device`, `Env`, `MeasuredRelation`, `Trace`. Every observable field is `Option`; `none` means *not observed*. |
|  | `Vocab/Assumptions.lean` | `asm.*` ids: legal region and calendar classes a scene supplies true, false or not at all. |
|  | `Vocab/Atoms.lean` | One accessor per atom id (§2). |
|  | `Vocab/Params.lean` | `Reading`: parameter values, operationalizations, legal aggregates (§2). |
|  | `Vocab/Primitives.lean` | The evaluation context and one definition per primitive (§2): computations the language cannot express. |
| `Language/` | `Language/Formula.lean` | The specification language as data: `Term` (with `sinceRise`, `aggregate`), `Formula` (with `rises`, `definedWhen`, `same`, quantifiers whose kind is an `Arg`), `Arg`, `CmpOp`, `AggOp`, and the inspectors the gate uses (`atoms`, `params`, `literals`, `composed`, `leaves`, `replaceLeaf`). |
|  | `Language/Semantics.lean` | `evalAll`: a formula's value at every instant; dispatches atom and primitive names; the finite-trace policy. |
|  | `Language/Rule.lean` | `Binder`, `Rule`, `Verdict`, `verdictAt`. **The only Core module a rule file imports.** |
|  | `Language/Concept.lean` | `Concept` (contract, typed formals, formal parameters, a `Formula` or `Term` body), capture-avoiding `expand`, cycle detection, `Instance` and `asRule` for a concept's witnesses. **The only Core module a concept file imports.** |
|  | `Language/RuleEval.lean` | `Rule.verdicts`, `wellFormed`, the static checks `check` and `checkReading`, and `Concept.check`. |
|  | `Language/Export.lean` | `Formula`, `Term`, `Concept`, `Rule` → JSON, for the renderer, the duplicate check and program synthesis. |
| `Runtime/` | `Runtime/Grounding.lean` | Binder assignments over a trace, track re-identification, per-grounding timelines, episode verdicts. |
|  | `Runtime/Manifest.lean` | A source's capability per atom id (`exact`, `estimate`, `absent`, or `subject` for an atom observed on the subject's own vehicle alone), `support` from syntax alone, and `mask` (a trace as a weaker source would give it). |
|  | `Runtime/Monitor.lean` | The report, as tab-separated text (the gate's contract) and JSON lines. |
|  | `Runtime/Decode.lean` | JSON → `Trace`, `Reading`, `Manifest`. The only place an outside string becomes a typed value. |
| `Evidence/` | `Evidence/Builders.lean` | `Build.*` scene and trace constructors and `Scenario`. Witnesses and tests only. |
|  | `Evidence/Adequacy.lean` | Mutation adequacy of a node's witnesses. Gate only. |

`Core.lean` imports all of them, layer by layer.

## 2. The vocabulary: five kinds of name, each with one home

A rule reads the world through names, never through fields or closures. Every name has exactly
one kind, and the kind decides where it is defined, who supplies its value and which check
holds it.

| kind | id / Lean name | defined in | its value comes from | a rule uses it as |
|---|---|---|---|---|
| **atom** | `family.name` / `family_name` (families `ru kin st dev sig env rel`) | `Atoms.lean`, one `def` per id; attribute accessors carry a suffix (`dev_traffic_signal_shows`) | the scene, through `World` | `Formula.atom`, `Term.measure` |
| **concept** | `drv.<family>.<name>` / `drv_<family>_<name>` | a concept node under `Concepts/`, planned, gated and reviewed like a rule; its body is a `Formula` or `Term` over its formals, expanded into the caller before evaluation | atoms, through the body; formal parameters filled by the caller | `Formula.derived`, `Term.quantity` |
| **primitive** | `prim.name` / `prim_name` | `Primitives.lean`, one `def` per id: a geometric computation the language cannot express | atoms, plus parameters passed as arguments | `Formula.derived`, `Term.quantity` |
| **parameter** | a free name | nowhere in Core | the run's reading (`library/TrafficSpec/Readings/*.json`, decoded to `Params.Reading`) | `Term.param` |
| **assumption** | `asm.name` | nowhere in Core; declared per node | the scene's `assumptions` list | `Formula.asm` |
| **another rule** | its node id | the other node's file | its verdict | `Formula.rule`, `Formula.ruleApplies` |

**Atoms** read one `World` field each. They compare nothing against a constant and look at no
other instant. The `rel_*` atoms may compute geometry from kinematics when the source does not
supply the relation measured.

**Concepts** are the vocabulary of manoeuvres, states and configurations. A concept is data:
`Concept.expand` substitutes the caller's arguments and parameter terms into its body and
renames the body's bound variables, so evaluation, support and adequacy see atoms and
primitives only. A body references only its own formals, never a reading parameter.

**Primitives** are the five computations the language cannot express (a heading change over a
window, the closest approach of two bodies, a sign legend's conditions). Like atoms they are a
closed set with a contract each; a need for another is a gap for the operator.

A number the statute states is written through a `Units` constructor and declared in the node's
blueprint; any other number is a parameter. Core carries no threshold.

These are the six clauses of the termination rule in `ontology/ATOMS.md`. They are held by:

- **doctor** (`scripts/diagnostics/library_v2.py`): the `Ontology/*` files match the generator;
  `atomIds` ↔ `Atoms.lean` ↔ the dispatch in `Semantics.lean`; `primitiveIds` ↔ `Primitives.lean` ↔
  `primitiveNames` ↔ `reads`.
- **`RuleEval.check`**: every name resolves, with the right arity, literals and argument sorts.
- **the gate**: `UNCLAIMED_ATOM`, `UNUSED_CLAIM`, `BARE_LITERAL`, `DECLARATION_MISMATCH`.

## 3. A node

A rule node is two files, with paths and namespaces derived from the node id (`harness/model/nodeid.py`).
The harness writes both as skeletons from the blueprint before the coding session starts. Every
declaration the gate compares is already filled in; the session writes the formulas and the
scenes.

```lean
-- TrafficSpec/Rules/<Body>/<NodeId>.lean
import TrafficSpec.Core.Language.Rule                 -- the only import allowed

namespace TrafficSpec.Rules.<NodeId>
def rule : Rule :=
  { id := "<NodeId>", laws := [...], binders := [...]      -- subject first
    applicability := ..., obligation := ...
    assumptions := [...], operationalizations := [...]
    residues := [...], surrogate := false }
end TrafficSpec.Rules.<NodeId>
```

```lean
-- TrafficSpecWitness/<Body>/<NodeId>.lean
import TrafficSpec.Rules.<Body>.<NodeId>
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.<NodeId>
def scenarios : List Scenario := [ ... ]     -- forbid, permit, idle, blind
end TrafficSpecWitness.<NodeId>
```

| role | expected episode verdict | shows |
|---|---|---|
| `forbid` | `violated` | the formula says something (it is not `□ ⊤`) |
| `permit` | `compliant` | trigger and obligation are satisfiable together |
| `idle` | `not_applicable` | the applicability can be false |
| `blind` | `unknown` | masking the atoms the blueprint names under the manifest yields unknown, not a verdict |

**Rule and witness are separate files** because a witness is evidence *about* a rule. Nothing that
runs the library imports `TrafficSpecWitness`, and a rule cannot import `Builders`. A rule that
could build its own evidence would prove nothing.

**A concept node** is also two files. The concept file imports `TrafficSpec.Core.Language.Concept` only
and declares `def concept : Concept`; the witness file declares `def instances : List
Concept.Instance` (the formals filled with the witness's own figures) and `def scenarios`, whose
roles are `holds` (`compliant`), `fails` (`violated`) and `blind` (`unknown`), plus
`counterexample` for a supersession. The gate turns each instance into a rule (`Concept.asRule`)
and runs the scenarios against it.

**Verdicts.** Applicability and obligation are separate formulas: a rule whose situation never
arises is `not_applicable`, not compliant. Per instant, `verdictAt` combines the binder classes,
the applicability and the obligation. Over a trace, `Grounding.episode` gives the episode verdict:

- any `violated` → violated;
- else any `unknown` → unknown;
- else any `compliant` → compliant;
- else not applicable.

A `surrogate` rule (the whole duty is an operationalized standard) is reported apart from the
concrete rules and never summed with them.

## 4. Who reads what

| step | reads | through |
|---|---|---|
| plan | no Lean; the ontology text the Core vocabulary is generated from, and the reading's catalogue | `harness/phases/plan.py` |
| validate A | `Primitives.reads`, the atom ids and the concept catalogue | `harness/lean/surface.py`, `harness/checks/validate_a.py` |
| validate B | the ontology rows of the claimed atoms | `harness/phases/validate.py` |
| code | a surface cut from `Formula`, `Time`, `Rule`, `Concept`, `Params`, `Builders`, `World`, `Ontology/*`, `Atoms`, `Semantics`, `Primitives`, `Units`, cited to each file, plus the concept catalogue | `harness/lean/surface.py` |
| gate | a generated Lean harness that imports `TrafficSpec`, `Adequacy`, `Decode` and the node; runs `Rule.check` (on the expanded rule), `checkReading`, `Scenario.run`, `Adequacy.unexercised` over `allConcepts`; for a concept, `Concept.check`, the instances, the supersession diff and the export of the expanded body | `harness/checks/gate.py` |
| integrate | the whole library build, including `Tests`, and `TrafficSpecWitness.failures` | `harness/phases/integrate.py` |
| monitor | `Main` → `Decode` → `Manifest` → `Grounding` → `Monitor` over `allRules` | `lake exe monitor` |

Gate verdicts, in order: `SCOPE_VIOLATION`, `BUILD_FAIL`, `UNSOUND`, `CHECK_FAIL`,
`UNANCHORED_VARIABLE`, `DECLARATION_MISMATCH`, `UNCLAIMED_ATOM`, `UNUSED_CLAIM`, `BARE_LITERAL`,
`WITNESS_FAIL`, `VACUOUS`, `OK`.

**Scope.** Before a session, the gate hashes every `.lean` file except the two registries. Any
change outside the node's two files is reported as `SCOPE_VIOLATION`.

## 5. Training split

The Core directory holds either the full or the training variant of the files that depend on
held-out atoms: `Atoms`, `Ontology/*`, `World`, `Decode`, `Manifest`, `Semantics`, `Primitives` and
`Grounding`. `splits/ACTIVE` records which one. `splits/full/` archives the full files and
`splits/train/` holds the generated training variants.

Swap with `python -m harness split --use train|full`, never by hand. Edit Core only while `full`
is active. A training run must also pass `--ontology_file ontology/ATOMS_train.md`, so that the
plan sees the same atom set Core defines.

## 6. Build and run

Run from `library/`:

```
lake build                                   # Core, Tests, registered rules and witnesses
lake exe monitor --manifest <m.json> [--reading <r.json>] [--rules id,id] [--json] <trace.json>...
```

The monitor exits with status 2 on a decode error and 0 otherwise; verdicts are in the report.

The JSON formats of traces, readings and manifests are documented at the top of `Decode.lean`.
