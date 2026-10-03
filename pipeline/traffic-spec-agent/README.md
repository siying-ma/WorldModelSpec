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
| `library/TrafficSpec/Core/**` | the Core library in five layers (see *Core structure*): three-valued semantics, units and time, the vocabulary and primitives, the language and its static check, grounding and the monitor, witness builders and adequacy. `library/splits/{full,train}/` hold the two variants of the files the split touches; `library/splits/ACTIVE` says which one the Core directory holds (`python -m harness split`) | yes |
| `library/TrafficSpec/Rules/<Body>/<NodeId>.lean`, `library/TrafficSpecWitness/<Body>/<NodeId>.lean` | one rule and its witnesses per node; `Index.lean` and `TrafficSpecWitness.lean` are generated registries | agent-written, gate-accepted |
| `laws/full_list/`, `laws/example/{train,test,demo,smoke}/` | the corpus as posted law (`id`, `title`, `text`, `source`) with its definitions; `demo/` and `smoke/` are reference-closed subsets of the training set (a first run; the smoke test below), made with `python -m nrs_tools.subset`; `laws/audit_and_scripts/` holds the analysis sidecars and the split record | input |
| `readings/<run>.json` | the parameter catalogue: every number a statute did not state, with its unit (the law's own units are accepted: ft, mph, min, …) and the convention its value comes from; `readings/lasvegas.json` is this corpus's base reading; it starts empty and is filled by the planner's proposals, which the operator reviews (the pre-pipeline operator list is archived under `readings/legacy/`). A figure a statute states is never a reading parameter: it is a literal on its law's span. The doctor's `reading figures` check lists every parameter whose value equals a figure some law states, until the entry carries a `figure_review` note | operator-written input |
| `prompts/*.md` | the plan, code, blind-read and alignment-judge templates | yes, law-free |
| `harness/` | the loop, its phases and the modules they share, grouped by role (see *Harness structure*) | code |
| `scripts/gen_ontology.py`, `scripts/diagnostics/` | the ontology generator and the doctor; `prompts vocabulary-free` holds the templates to injected context only (no vocabulary id, parameter or corpus-defined term in a rule) | code |
| `gaps/ledger.jsonl` | what the frozen vocabulary cannot carry (kinds `atom` and `operator` only), proposed by plan sessions, decided by the operator; one ledger for every run, each plan shown only the gaps on its own corpus's laws (and its base run's) | operator-decided |
| `results/<run>/` | per-run artifacts: `ledger.jsonl` (per-law states), `mapping.json`, `accepted_nodes.jsonl`, `AUTO_NOTES.md`, `iter-NNN/{plan,validate,code,integrate}` | run output |

## Harness structure

`harness/` is grouped by role, not by stage: the stages live in `harness/phases/`, and the
modules the stages share sit in one folder each.

| folder | modules | what it holds |
|---|---|---|
| `harness/` | `__main__.py`, `loop.py` | the CLI (`python -m harness …`) and the iteration driver: ledger transitions, dependency order, deferral, stop conditions |
| `harness/phases/` | `plan.py`, `validate.py`, `code.py`, `integrate.py`, `feedback.py` | one module per stage of the loop |
| `harness/model/` | `blueprint.py`, `corpus.py`, `mapping.py`, `nodeid.py`, `ontology.py`, `reading.py`, `units.py` | the pipeline's data: blueprint records, the corpus, the mapping index, derived ids and paths, the closed set, the reading, unit factors |
| `harness/store/` | `paths.py`, `state.py`, `ledger.py`, `gaps.py` | where things live and the run's state: options and run directories, the law and concept ledgers, the gap ledger |
| `harness/lean/` | `lean.py`, `index_sync.py`, `skeleton.py`, `surface.py`, `render_formula.py` | everything that reads or writes `library/`: lake calls, the registries, the skeletons, the Core surface, the formula renderer |
| `harness/agents/` | `runner.py`, `session.py`, `render.py` | Claude sessions (launch, relaunch on refusal) and prompt filling |
| `harness/checks/` | `validate_a.py`, `gate.py`, `aggregates.py` | the deterministic acceptance checks: validator A, the gate, the aggregate validator |
| `harness/tools/` | `split.py`, `score_split.py` | operator commands: the train/full Core swap and the test-run scorer |

Imports point one way. `model/` and `store/` import nothing else in the harness; `lean/` and
`agents/` build on them; `checks/` builds on `model/`, `store/` and `lean/`; `phases/` uses all
of these, and `loop.py` and `__main__.py` sit on top. A new module goes in the folder whose role it
has, and imports only from the folders below it.

## Core structure

`library/TrafficSpec/Core/` is grouped into five layers, one folder each; a module's name is its
path (`TrafficSpec.Core.Language.Rule` is `Core/Language/Rule.lean`). `library/README.md` §1 lists
every file.

| folder | files | what it holds |
|---|---|---|
| `library/TrafficSpec/Core/Foundations/` | `Tri`, `Units`, `Time`, `Handles`, `Unknown`, `Temporal` | three-valued logic with reasons, exact units, time and windows, the temporal operators, the identifiers of tracks, regions, devices and assumptions |
| `library/TrafficSpec/Core/Vocab/` | `Ontology/*`, `World`, `Assumptions`, `Atoms`, `Params`, `Primitives` | the closed vocabulary: the generated enumerations, the scene as data, one accessor per atom, the reading, the primitives |
| `library/TrafficSpec/Core/Language/` | `Formula`, `Semantics`, `Rule`, `Concept`, `RuleEval`, `Export` | the specification language, its meaning, rules and concepts, the static check, JSON export |
| `library/TrafficSpec/Core/Runtime/` | `Grounding`, `Manifest`, `Monitor`, `Decode` | running a rule over data: grounding, source manifests, the monitor, decoding |
| `library/TrafficSpec/Core/Evidence/` | `Builders`, `Adequacy` | witness scenes and scenarios, mutation adequacy |

A Core file imports only from its own layer and the layers above it in this table. A rule file
imports `TrafficSpec.Core.Language.Rule` only, a concept file `TrafficSpec.Core.Language.Concept`
only, and a witness file its rule or concept and `TrafficSpec.Core.Evidence.Builders`.

## Commands

Run from this directory (`lake` is run inside `library/`, where `lean-toolchain` pins the toolchain).

```bash
bash setup.sh                         # elan + toolchain + Python deps
source .venv/bin/activate

python -m harness init                # readings/default.json template, registries, library build
python -m harness init --fresh --snapshot <run>   # first move the library's nodes and concepts to results/<run>/library_snapshot/
python -m harness doctor              # hold every generated artifact to its source
python -m harness split --use train   # swap the training-only Core files in (archives the full ones under library/splits/full/)
python -m harness split --use full    # and back; `python -m harness split` reports which is active

# the smoke test: two laws of one section, the second composing the first by id as an exception; together
# they name the aggregates driver, vehicle and traffic, their stops, yields and intersection entries are
# concepts a fresh library does not have, and one carries a standard the plan bounds with a proposed
# parameter. --plan_batch 1 puts the two laws in separate sessions, root first, so the second is shown the
# first's planned nodes and composes them by id. Expect: concept records gated and reviewed, three
# nodes, one composition, an aggregates.jsonl with the three words, a proposed parameter in the reading,
# and a review per accepted node.
python -m harness init --fresh --snapshot <previous run>   # archives its library and its unreviewed parameter proposals
python -m harness loop --run_id smoke1 --laws laws/example/smoke/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus \
    --max_iterations 3 --plan_batch 1

# a first run on the reference-closed demo subset; archive its library, then the training corpus
python -m harness loop --run_id demo1 --laws laws/example/demo/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 3
python -m harness init --fresh --snapshot demo1
python -m harness loop --run_id train1 --laws laws/example/train/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 4

# a test run on top of the training library: add-only, train1's nodes and concepts read-only
python -m harness loop --run_id test1 --laws laws/example/test/laws.jsonl --mode test --base_run train1 \
    --ontology_file ontology/ATOMS_train.md --reading readings/lasvegas.json --model opus --max_iterations 2
python -m harness score_split --run_id test1     # gap recall / precision / approximation rate

python -m harness validate --run_id <run> [--blueprint_file <blueprint.jsonl>]   # validator A in the run's context (the plan session runs it on its draft)
python -m harness validate --blueprint_file <blueprint.jsonl> --laws <laws.jsonl> --reading <reading.json>   # context-free: no accepted node, concept or mapping is known
python -m harness gate --run_id <run> --node_id <node>   # the gate for one node or concept id (what a coding session runs)
python -m harness surface                                  # the generated Core surface a coding session is shown
python -m harness verify                                   # rebuild and run every registered witness
python -m harness index                                    # regenerate the registries
python -m harness status --run_id <run>
```

**Checkpoints and resume.** The ledgers, the accepted records and the deferred nodes are saved after
every transition, and `results/<run>/iter-NNN/progress.json` records the stage an iteration reached
and the verdict of every concept and node coded so far. A loop started on a run whose latest
iteration is short of `done` rolls back the sessions that were killed mid-way (a task directory
with no verdict), then resumes that iteration: the plan and its validation are reused, decided
concepts and nodes are skipped, the rest are coded. `--restart` discards the incomplete iteration
instead, returning its planned laws to `open`. The doctor runs at every loop start and refuses a
run on a failure. `--max_iterations` counts the iterations of one invocation, the resumed one
included.

**Parallel coding.** `--workers N` codes up to N independent concepts, then N independent nodes, at
once, in dependency waves (a node is coded after every node it composes is accepted). Every gate,
skeleton build and integration holds a library-wide lock while it regenerates the registries,
builds and runs, and a gate registers only the accepted ids plus its own, so a half-written
sibling never enters its build; the scope check tolerates the files of the sessions coding
beside it. `--reader_model` gives the blind reader a smaller model; `--plan_turns` caps a plan or
repair session.

**Do not edit the pipeline tree while a loop runs.** The gate digests the whole tree; an edit to the
harness or the prompts during a coding session is a scope violation charged to that law.

**Sessions are isolated, jailed and allow-listed.** Every agent session runs with no settings
file, no CLAUDE.md, no plugin, no MCP server and no skill: its context is its prompt. It acts under
an allow-list (default permission mode, prompts auto-denied) from a working directory that holds
only its own files: a plan session reads and writes its plan directory and runs the validator
command exactly as given; a coding session reads Core by absolute path, edits its own two files,
writes its task directory and runs the gate command exactly as given; readers and judges have no
tool. Shell rules are exact commands, never prefixes. Deny rules on the frozen trees and the gate's
whole-tree digest sit underneath, so a change anywhere outside the node's two files is
`SCOPE_VIOLATION`, the node is rolled back and the stray files are named in `TO_USER.md`.

**One library per run.** `library/` holds the rules and concepts of exactly one run (and its base
run), because `index_sync` registers every file on disk. `loop` refuses to start
(`loop.check_library_isolation`) when the library holds a node or concept that neither the run
nor its `--base_run` accepted, or lacks one that they did, and names the fix.
`python -m harness init --fresh --snapshot <run>` moves every rule, concept and witness file,
tree layout kept, into `results/<run>/library_snapshot/` (a timestamped name when `--snapshot`
is omitted) and rebuilds the empty library. Resuming a run with the same `--run_id` needs no
snapshot: its accepted records match what is on disk. `--mode test` requires `--base_run`; such a
run adds concepts and supersedes none (the gate returns `TEST_ADD_ONLY`).

**Editing Core under a split.** The Core directory holds the variant `library/splits/ACTIVE` names.
Edit Core only with `full` active (`python -m harness split --use full`), then switch back with
`--use train`: the switch re-archives the full files and regenerates the training variant from
them. The doctor's `core matches split` check fails when Core drifts from its source.

`--dry_run` renders every prompt and runs the deterministic phases without launching a session.
Session options: `--plan_effort`, `--code_effort` (default `high`), `--judge_effort` (default
`medium`) set `claude --effort` per phase; `--max_turns` (80), `--session_budget_usd` (uncapped)
cap a session; `--session_retries` (2) and `--retry_wait` (900 s) relaunch a session the account
or the API refused (a usage limit, an API error); `--plan_batch` (8) is the most laws one plan
session is given; `--judge_samples` (1) the number of independent judges a node's review runs;
`--workers` (1) the coding sessions run at once; `--reader_model` the blind reader's model;
`--plan_turns` (40) the turn cap of a plan or repair session; `--restart` discards an interrupted
iteration; `--concept_attempts` (3) the coding attempts a concept gets, its first and its repairs,
separate from the laws' `--plan_attempts` (2); `--node_attempts` (2) the coding attempts a node gets,
its first and one after a node repair session, before its law is returned to the planner. A session the account or the API refused is never
counted as one of the law's attempts: the law is deferred to `open` and the loop stops after the iteration.
A training or test run needs the training split active (`python -m harness split --use train`);
the doctor's `ontology generated` check follows the active split and its `training split` check
holds the training variant to `ATOMS_train.md` and `split_atoms.json`.

## The loop, briefly

0. **Repair** (one session per concept the gate or the review returned last iteration): sees the
   record, the verdict, the coder's result note and the files the coder left, the ontology and the
   catalogue, no law; writes a revised record or a withdrawal. The laws whose nodes use the concept
   stay `planned` on hold, uncharged, until the concept is decided; a concept that fails repair
   twice fails and only then are they returned.
1. **Plan** (one session per batch of at most `--plan_batch` laws, root laws before the laws whose
   text names them; a law naming a planned or blocked law waits, one naming a failed law fails; the
   prompt carries the definitions the batch's laws cite or whose defined term they use, not the
   folder's): segments each plannable law's verbatim text into spans with roles,
   maps every substantive span to atoms or derived concepts by quoting their contracts,
   operationalizes standards with named reading parameters, plans four witnesses, and files a
   gap where no contract carries a span. Writes `blueprint.jsonl`, `PLAN.md`, `proposed_gaps.jsonl`.
2. **Validate**: A, deterministic (segmentation is a partition; total accounting; closed set;
   standards have parameters in the reading; node id derived from the law id; one node per
   obligation span, an accepted node never re-planned; same words same atoms across the run;
   compositions resolve, no cycles; no residue on a trigger, subject, condition or exception span
   unless it declares `scope: none`; the four witnesses). An obligation carried only by a residue
   fails the law; a gap blocks it whatever else is wrong; errors alone return it. The same check,
   in the run's context, is the draft validator the planner runs (`python -m harness validate
   --run_id <run>`).
3. **Code** (one session per accepted node): starts from the two files the harness wrote from the
   node (`harness/lean/skeleton.py`: every declaration the gate compares, the parameters as terms, the
   four scenarios with their verdicts and masked atoms — they build as written), with the generated
   Core surface (`harness/lean/surface.py`: accessors with the field each reads, derived contracts,
   builders, world records, units), the reading's values for the node's parameters and the most
   recently accepted node as the worked example. Writes the formulas and the scenes, runs the gate,
   stops on `OK` or when the budget is spent. The harness re-runs the gate itself. Core is readable
   in a session and never writable; the harness is neither. **Review**: a node the gate accepts is
   then read blind — the gate exports the `Rule` value and the harness renders its formulas as
   prose with the contracts of every name and the aggregate memberships, no law text and no
   planner prose — and a judge compares that reading with the law span by span, seeing the plan's
   residues and the coder's added residues separately. The judge's answer is held to its schema
   (every span judged once, five verdict words, `carried` only where the plan carries, verbatim
   quotes, a top-level verdict that agrees with the rows), re-asked once, and a surviving defect
   counts against the node; `--judge_samples` runs several judges that must all agree. A node that
   fails is rolled back (its files restored) and its law returned with the judge's rows; a second
   failure closes the law.
4. **Integrate**: registries, whole-library build, every witness, composition DAG; reverts newest-first.
5. **Feedback**: `AUTO_NOTES.md` for the next plan, `TO_USER.md` for the operator, gaps merged into the ledger.

**The gate** (`harness/checks/gate.py`), in order: `SCOPE_VIOLATION`, `BUILD_FAIL`, `UNSOUND` (sorry,
axioms, unsafe constructs — scanned in code only, never in the header comment or the
operationalization strings that carry the law's words), `CHECK_FAIL` (`Rule.check`, which also
rejects a number in an entity position, and `Rule.checkReading`, which holds every aggregate word
a rule names to the reading), the claim checks (a formula's atoms are what the evaluator reads: its
leaves, the clock or path length of every window, and the kind of every quantifier with a literal
kind, so a claimed `kin.time` is used by a time window and a claimed `st.lane` by
`existsRegion (.lit "lane")`; the clock needs no claim; a concept's atoms are taken over every
admissible value of its literal formals), `UNANCHORED_VARIABLE` (a quantified region, device or user related to
no binder through an atom, a derived concept or a composition — a feature the rule reads must be
the subject's, not any in the scene), `DECLARATION_MISMATCH` (the node's residues must all be in
the rule and none added; a reading the coder chose on a carried span is a narrowing `⟨span, why⟩`,
carried to the review, the feedback and the accepted record under its own key),
`SCOPE_NARROWED` (a narrowing on a trigger, subject, condition or exception span: the rule would
apply where the law does not), `UNCLAIMED_ATOM` / `UNUSED_CLAIM` / `BARE_LITERAL`, `WITNESS_FAIL` (a verdict differs
from the planned one, `idle` grounds a binder to a track that never appears, `blind` is unknown for
anything but its masked atoms, or its manifest masks something other than the node's `masked`),
`VACUOUS` (a leaf no decided witness exercises; `blind` does not count), `OK`. A toolchain that did
not run is `INFRA`: the law is deferred without an attempt and the loop stops after the iteration.
The witnesses are the node's tests, written by the same session as the rule from the planner's
narratives; they show the formulas are executable and reach every verdict, and never stand as
evidence that the rule says what the law says — that is the review's job.

**Aggregates.** "Vehicle", "motor vehicle", "traffic" are one atom, `ru.aggregate`, with the word
as its literal argument. Which `ru.*` classes (or other words, expanded transitively) a word
covers is **derived by the run** from the corpus definitions: the plan session writes
`aggregates.jsonl` (word, definition id, classes, justification, unresolved kinds), the harness
validates it (`harness/checks/aggregates.py`: definition given, classes in the ontology, members
resolvable) and merges the accepted records into the run's reading `results/<run>/reading.json`,
which every later phase uses. `TO_USER.md` lists each derived aggregate for review; an operator
entry in the base reading's `aggregates` overrides the derived one. The repository declares no
membership. The planner claims `ru.aggregate=<word>` and never expands it.

**Standards and proposed parameters.** Every operationalization names at least one parameter; the
validator returns a node whose standard is bounded by a structural test with no magnitude behind
it, and the judge marks such a rendering `approximated`. A parameter the reading lacks is proposed
on the node (`param_proposals`: name, unit, provisional value, convention, source); when the node
is accepted the harness enters it in the run's reading and the base reading marked `proposed`, the
node is coded against it, and the doctor's `reading proposals` check lists it until the operator
reviews it by removing the marker or changing the value. A gap is only `atom` or `operator`: the
frozen vocabulary cannot carry the span.

**Composition order.** A node is coded only after every node it composes is accepted; a node whose
composed node is not accepted yet is kept in `results/<run>/deferred_nodes.jsonl` and coded in a
later iteration without re-planning and without an attempt counted, its law staying `planned`
until every node it was planned with is accepted; a node composing a law closed as failed is
closed as failed too, and one composing a law blocked on a gap is blocked on that gap. A node
whose concept was returned is not deferred (concepts are coded before nodes): its law is returned
with the concept's reasons. An accepted node is never coded again: a returned law re-plans its
returned nodes only.

**Per-law termination** (`results/<run>/ledger.jsonl`): `open` → `planned` → `returned` (a fixable
defect; one attempt per law per iteration, however many of its nodes fail; a law returned because a
concept its nodes use failed is charged once per such concept, not once per iteration it waits) → `accepted` | `blocked`
(a gap; waits for the operator, and reopens when every gap is retired or rejected) | `failed`
(budget spent, judge failed twice, the obligation itself is not expressible, or a named law failed). A session or toolchain that did not run defers the law to `open` with
no attempt counted. The planner is shown only `open` and `returned` laws.

## Conventions

- Only `laws/**` and `library/TrafficSpec{,Witness}/**` may name a law. Core, the ontology, the
  prompts, the harness and this file are law-free; the doctor enforces it.
- Every table an agent is shown is generated from the artifact it describes (`harness/lean/surface.py`).
- A rule imports `TrafficSpec.Core.Language.Rule` only; a witness imports its rule and `TrafficSpec.Core.Evidence.Builders`.
- Quantities enter a rule as `.param "<name>"`; values live in the reading. The only literals are
  zero, enumeration spellings, and figures the law itself states, declared on their span in the
  blueprint (`literals`) and written through a `Units` constructor. Validator A returns a node whose
  operationalization bounds a span with a parameter whose reading value is a figure that span states.
- `Index.lean` and `TrafficSpecWitness.lean` are generated (`python -m harness index`).
- Always pass `ensure_ascii=False` to `json.dumps`; law text and Lean sources contain Unicode.
