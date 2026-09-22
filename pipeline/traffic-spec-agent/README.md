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

python -m harness validate --blueprint_file <blueprint.jsonl> --laws <laws.jsonl> --reading <reading.json>   # validator A offline
python -m harness gate --run_id <run> --node_id <node>   # the gate for one node (what a coding session runs)
python -m harness verify                                   # rebuild and run every registered witness
python -m harness index                                    # regenerate the registries
python -m harness status --run_id <run>
```

`--dry_run` renders every prompt and runs the deterministic phases without launching a session.
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
3. **Code** (one session per accepted node): writes the rule and the witness files, runs the gate,
   stops on `OK` or when the budget is spent. The harness re-runs the gate itself.
4. **Integrate**: registries, whole-library build, every witness, composition DAG; reverts newest-first.
5. **Feedback**: `AUTO_NOTES.md` for the next plan, `TO_USER.md` for the operator, gaps merged into the ledger.

**The gate** (`harness/gate.py`), in order: `SCOPE_VIOLATION`, `BUILD_FAIL`, `UNSOUND` (sorry,
axioms, unsafe constructs), `CHECK_FAIL` (`Rule.check`, `Rule.checkReading`),
`DECLARATION_MISMATCH`, `UNCLAIMED_ATOM` / `UNUSED_CLAIM` / `BARE_LITERAL`, `WITNESS_FAIL`,
`VACUOUS` (a leaf no witness exercises), `OK`.

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
