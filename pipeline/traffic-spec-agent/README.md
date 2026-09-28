# traffic-spec-agent — law-facing autoformalization of traffic law into Lean 4

The pipeline turns statutory obligations (a corpus of posted law) into `Rule` values over a
frozen law-facing ontology and Core library, with witnesses that show each rule firing, holding,
idling and reporting unknown. The loop is plan → validate → code → integrate → feedback; its
design, the termination rules and the gap structure are in
`../DesignFile/PIPELINE_V2_DESIGN.md`. No scene-graph schema, adapter or perception manifest is
part of this pipeline: what a data source can observe is a run-time manifest for the monitor.

## Layout

| path | what it is | frozen? |
|---|---|---|
| `ontology/ATOMS.md`, `ontology/ATOMS_train.md` | the closed set of atoms, values and derived concepts; the training variant omits what only test lines support | yes |
| `library/TrafficSpec/Core/**` | the Core library (three-valued semantics, derived concepts, evaluator, grounding, monitor, static check, adequacy). `library/splits/{full,train}/` hold the two variants of the files the split touches; `library/splits/ACTIVE` says which one the Core directory holds (`python -m harness split`) | yes |
| `library/TrafficSpec/Rules/<Body>/<NodeId>.lean`, `library/TrafficSpecWitness/<Body>/<NodeId>.lean` | one rule and its witnesses per node; `Index.lean` and `TrafficSpecWitness.lean` are generated registries | agent-written, gate-accepted |
| `laws/full_list/`, `laws/example/{train,test,demo}/` | the corpus as posted law (`id`, `title`, `text`, `source`) with its definitions; `demo/` is a reference-closed subset of the training set for a first run; `laws/audit_and_scripts/` holds the analysis sidecars and the split record | input |
| `readings/<run>.json` | the parameter catalogue: every number a statute did not state, with its unit (the law's own units are accepted: ft, mph, min, …) and the convention its value comes from; `readings/lasvegas.json` is the provisional catalogue for this corpus | operator-written input |
| `prompts/*.md` | the plan, code, blind-read and alignment-judge templates | yes, law-free |
| `harness/` | the loop and its phases, the validator, the gate, the ledgers | code |
| `scripts/gen_ontology.py`, `scripts/diagnostics/` | the ontology generator and the doctor | code |
| `gaps/ledger.jsonl` | what the ontology cannot carry, proposed by plan sessions, decided by the operator | operator-decided |
| `results/<run>/` | per-run artifacts: `ledger.jsonl` (per-law states), `mapping.json`, `accepted_nodes.jsonl`, `AUTO_NOTES.md`, `iter-NNN/{plan,validate,code,integrate}` | run output |

## Commands

Run from this directory (`lake` is run inside `library/`, where `lean-toolchain` pins the toolchain).

```bash
bash setup.sh                         # elan + toolchain + Python deps
source .venv/bin/activate

python -m harness init                # readings/default.json template, registries, library build
python -m harness doctor              # hold every generated artifact to its source
python -m harness split --use train   # swap the training-only Core files in (archives the full ones under library/splits/full/)
python -m harness split --use full    # and back; `python -m harness split` reports which is active

# a first run on the reference-closed demo subset, then the training corpus
python -m harness loop --run_id demo1 --laws laws/example/demo/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 3
python -m harness loop --run_id train1 --laws laws/example/train/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 4

# a test run against the frozen training library and ontology
python -m harness loop --run_id test1 --laws laws/example/test/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 2
python -m harness score_split --run_id test1     # gap recall / precision / approximation rate

python -m harness validate --blueprint_file <blueprint.jsonl> --laws <laws.jsonl> --reading <reading.json>   # validator A offline (the plan session runs it on its draft)
python -m harness gate --run_id <run> --node_id <node>   # the gate for one node (what a coding session runs)
python -m harness surface                                  # the generated Core surface a coding session is shown
python -m harness verify                                   # rebuild and run every registered witness
python -m harness index                                    # regenerate the registries
python -m harness status --run_id <run>
```

**Editing Core under a split.** The Core directory holds the variant `library/splits/ACTIVE` names.
Edit Core only with `full` active (`python -m harness split --use full`), then switch back with
`--use train`: the switch re-archives the full files and regenerates the training variant from
them. The doctor's `core matches split` check fails when Core drifts from its source.

`--dry_run` renders every prompt and runs the deterministic phases without launching a session.
Session options: `--plan_effort`, `--code_effort` (default `high`), `--judge_effort` (default
`medium`) set `claude --effort` per phase; `--max_turns` (80), `--session_budget_usd` (uncapped)
cap a session; `--session_retries` (2) and `--retry_wait` (900 s) relaunch a session the account
or the API refused (a usage limit, an API error). Such a session is never counted as one of the
law's attempts: the law is deferred to `open` and the loop stops after the iteration.
A training or test run needs the training split active (`python -m harness split --use train`);
the doctor's `ontology generated` check follows the active split and its `training split` check
holds the training variant to `ATOMS_train.md` and `split_atoms.json`.

## The loop, briefly

1. **Plan** (one session): segments each plannable law's verbatim text into spans with roles,
   maps every substantive span to atoms or derived concepts by quoting their contracts,
   operationalizes standards with named reading parameters, plans four witnesses, and files a
   gap where no contract carries a span. Writes `blueprint.jsonl`, `PLAN.md`, `proposed_gaps.jsonl`.
2. **Validate**: A, deterministic (segmentation is a partition; total accounting; closed set;
   standards have parameters in the reading; node id derived from the law id; one node per
   obligation span; same words same atoms across the run; compositions resolve, no cycles; the
   four witnesses); B, a blind reader writes what the node specifies without seeing the law, and
   a judge compares the reading with the law span by span.
3. **Code** (one session per accepted node): starts from the two files the harness wrote from the
   node (`harness/skeleton.py`: every declaration the gate compares, the parameters as terms, the
   four scenarios with their verdicts and masked atoms — they build as written), with the generated
   Core surface (`harness/surface.py`: accessors with the field each reads, derived contracts,
   builders, world records, units), the reading's values for the node's parameters and the most
   recently accepted node as the worked example. Writes the formulas and the scenes, runs the gate,
   stops on `OK` or when the budget is spent. The harness re-runs the gate itself. Core is readable
   in a session and never writable; the harness is neither.
4. **Integrate**: registries, whole-library build, every witness, composition DAG; reverts newest-first.
5. **Feedback**: `AUTO_NOTES.md` for the next plan, `TO_USER.md` for the operator, gaps merged into the ledger.

**The gate** (`harness/gate.py`), in order: `SCOPE_VIOLATION`, `BUILD_FAIL`, `UNSOUND` (sorry,
axioms, unsafe constructs), `CHECK_FAIL` (`Rule.check`, `Rule.checkReading`, which also holds
every aggregate word a rule names to the reading), `UNANCHORED_VARIABLE` (a quantified region,
device or user related to no binder through an atom, a derived concept or a composition — a
feature the rule reads must be the subject's, not any in the scene), `DECLARATION_MISMATCH`
(the node's residues must all be in the rule; residues the coder appends are carried back into
the accepted node and the feedback), `UNCLAIMED_ATOM` / `UNUSED_CLAIM` / `BARE_LITERAL`,
`WITNESS_FAIL`, `VACUOUS` (a leaf no witness exercises), `OK`.

**Aggregates.** "Vehicle", "motor vehicle", "traffic" are one atom, `ru.aggregate`, with the word
as its literal argument. Which `ru.*` classes (or other words, expanded transitively) a word
covers is **derived by the run** from the corpus definitions: the plan session writes
`aggregates.jsonl` (word, definition id, classes, justification, unresolved kinds), the harness
validates it (`harness/aggregates.py`: definition given, classes in the ontology, members
resolvable) and merges the accepted records into the run's reading `results/<run>/reading.json`,
which every later phase uses. `TO_USER.md` lists each derived aggregate for review; an operator
entry in the base reading's `aggregates` overrides the derived one. The repository declares no
membership. The planner claims `ru.aggregate=<word>` and never expands it.

**Standards and value gaps.** Every operationalization names at least one parameter; the validator
returns a node whose standard is bounded by a structural test with no magnitude behind it, and
the judge marks such a rendering `approximated`. A parameter the reading lacks does not return the
node: the harness files a gap of kind `value` naming the parameter, blocks the law, and retires
the gap (reopening the law) as soon as the operator sets the parameter in the base reading.

**Composition order.** A node is coded only after every node it composes is accepted; a node whose
composed node is not accepted yet is kept in `results/<run>/deferred_nodes.jsonl` and coded in a
later iteration without re-planning and without an attempt counted; a node composing a law closed
as failed is closed as failed too.

**Per-law termination** (`results/<run>/ledger.jsonl`): `open` → `planned` → `returned` (a fixable
defect, attempts counted) → `accepted` | `blocked` (a gap; waits for the operator) | `failed`
(budget spent, judge failed twice, or the obligation itself is not expressible). The planner is
shown only `open` and `returned` laws.

## Conventions

- Only `laws/**` and `library/TrafficSpec{,Witness}/**` may name a law. Core, the ontology, the
  prompts, the harness and this file are law-free; the doctor enforces it.
- Every table an agent is shown is generated from the artifact it describes (`harness/surface.py`).
- A rule imports `TrafficSpec.Core.Rule` only; a witness imports its rule and `TrafficSpec.Core.Builders`.
- Quantities enter a rule as `.param "<name>"`; values live in the reading. The only literals are
  zero, enumeration spellings, and figures the law itself states, declared on their span in the
  blueprint (`literals`) and written through a `Units` constructor.
- `Index.lean` and `TrafficSpecWitness.lean` are generated (`python -m harness index`).
- Always pass `ensure_ascii=False` to `json.dumps`; law text and Lean sources contain Unicode.
