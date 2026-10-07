# traffic-spec-agent — law-facing autoformalization of traffic law into Lean 4

The pipeline turns statutory obligations (a corpus of posted law) into `Rule` values over a
frozen law-facing ontology and Core library, with witnesses that show each rule firing, holding,
idling and reporting unknown. The loop is repair → plan → validate → code (gate,
review) → integrate → feedback; after the gate, a reviewer of another vendor than the agents' (a
GPT model through the OpenAI API) reviews the behaviour of each coded rule on situations it writes
as traces, which the harness executes, and an adjudicator of the agents' vendor rules on the law's
side of every divergence the execution confirms. Its design, the termination rules and
the gap structure are in `../DesignFile/PIPELINE_V2_DESIGN.md`. No scene-graph schema, adapter or perception manifest is
part of this pipeline: what a data source can observe is a run-time manifest for the monitor.

**Every change must earn its place.** Before adding or changing an agent, a phase, a script, a
check, an option or a prompt rule, think twice about whether the pipeline needs it. The first
requirement is that the pipeline completes the formalization of its corpus without a hand on it:
no structural defect that only an operator can route around (the corpus has been scanned in full,
so every line is in principle formalizable, and the only legitimate stops are a gap decision, a
parameter review, and a law closed after repeated failure). The second is that the pipeline stays
small: a feature is not better for being there; every agent, script and check must have a reason
to exist that can be stated in one sentence; two checks that catch the same defect are one too
many; a fix that removes a cause beats one that adds a mechanism. A part found without a reason is
removed, not kept.

## Layout

| path | what it is | frozen? |
|---|---|---|
| `ontology/ATOMS.md`, `ontology/ATOMS_train.md` | the closed set of atoms (135; 121 in the training variant), enumeration values and primitives, each with its contract; the training variant omits what only test lines support. Concepts are not in the ontology: they are records the plan proposes and the library holds (`library/TrafficSpec/Concepts/`) | yes |
| `library/TrafficSpec/Core/**` | the Core library in five layers (see *Core structure*): three-valued semantics, units and time, the vocabulary and primitives, the language and its static check, grounding and the monitor, witness builders and adequacy. `library/splits/{full,train}/` hold the two variants of the files the split touches; `library/splits/ACTIVE` says which one the Core directory holds (`python -m harness split`) | yes |
| `library/TrafficSpec/Rules/<Body>/<NodeId>.lean`, `library/TrafficSpecWitness/<Body>/<NodeId>.lean` | one rule and its witnesses per node; `Index.lean` and `TrafficSpecWitness.lean` are generated registries | agent-written, gate-accepted |
| `laws/full_list/`, `laws/example/{train,test,demo,smoke,carla_*}/` | the corpus as posted law (`id`, `title`, `text`, `source`) with its definitions; `demo/`, `smoke/` and the `carla_*` folders are reference-closed subsets of the training set (a first run; a small test of composition and aggregates; lines with standards of judgement, scored on simulator captures), made with `python -m nrs_tools.subset`, older subsets under `laws/example/archive/`; `laws/audit_and_scripts/` holds the analysis sidecars and the split record | input |
| `library/TrafficSpec/Readings/<run>.json` | the parameter catalogue: every number a statute did not state, with its unit (the law's own units are accepted: ft, mph, min, …) and the convention its value comes from; `library/TrafficSpec/Readings/lasvegas.json` is this corpus's base reading; it starts empty and is filled by the planner's proposals, which the operator reviews (the pre-pipeline operator list is archived under `library/TrafficSpec/Readings/legacy/`). A figure a statute states is never a reading parameter: it is a literal on its law's span. The doctor's `reading figures` check lists every parameter whose value equals a figure some law states, until the entry carries a `figure_review` note | operator-written input |
| `prompts/*.md` | eight templates: `plan`, `code`, `code_concept`, `concept_repair`, `node_repair`, `concept_judge`, the second vendor's `review_code`, and `adjudicate` | yes, law-free |
| `harness/` | the loop, its phases and the modules they share, grouped by role (see *Harness structure*) | code |
| `scripts/gen_ontology.py`, `scripts/diagnostics/`, `scripts/setup_reviewer.sh` | the ontology generator, the doctor (`prompts vocabulary-free` holds the templates to injected context only: no vocabulary id, parameter or corpus-defined term in a rule) and the reviewer's one-time key setup | code |
| `library/TrafficSpec/Gaps/ledger.jsonl` | what the frozen vocabulary cannot carry (kinds `atom` and `operator` only), proposed by plan and repair sessions, decided by the operator (`retired` when the ontology or Core now carries it, `rejected` when the span is carried as it is); one ledger for every run, each plan shown only the gaps on its own corpus's laws (and its base run's); ids come from `counter.txt` beside it, which only grows | operator-decided |
| `results/<run>/` | per-run artifacts: `options.json`, `reading.json` (the run's reading), the law, concept and node ledgers (`ledger.jsonl`, `concept_ledger.jsonl`, `node_ledger.jsonl`), `accepted_nodes.jsonl`, `accepted_concepts.jsonl`, `deferred_nodes.jsonl`, `mapping.json`, `AUTO_NOTES.md`, `TO_USER.md`, `summary.json`, and per iteration `iter-NNN/{plan,repair,validate,review,code,integrate}` with `progress.json` | run output |

## Harness structure

`harness/` is grouped by role, not by stage: the stages live in `harness/phases/`, and the
modules the stages share sit in one folder each.

| folder | modules | what it holds |
|---|---|---|
| `harness/` | `__main__.py`, `loop.py` | the CLI (`python -m harness …`) and the iteration driver: ledger transitions, dependency order, deferral, stop conditions |
| `harness/phases/` | `plan.py`, `validate.py`, `review.py`, `code.py`, `integrate.py`, `feedback.py` | one module per stage of the loop (`plan.py` also runs the concept and node repair sessions; `validate.py` also a concept's judge; `review.py` is the second vendor's behaviour review and the adjudicator) |
| `harness/model/` | `blueprint.py`, `corpus.py`, `mapping.py`, `nodeid.py`, `ontology.py`, `reading.py`, `units.py` | the pipeline's data: blueprint records, the corpus, the mapping index, derived ids and paths, the closed set, the reading, unit factors |
| `harness/store/` | `paths.py`, `state.py`, `ledger.py`, `gaps.py` | where things live and the run's state: options and run directories, the law, concept and node ledgers, the gap ledger |
| `harness/lean/` | `lean.py`, `index_sync.py`, `skeleton.py`, `surface.py`, `render_formula.py` | everything that reads or writes `library/`: lake calls, the registries, the skeletons, the Core surface, the formula renderer |
| `harness/agents/` | `runner.py`, `session.py`, `render.py`, `openai_runner.py` | agent sessions (launch, relaunch on refusal, jail and allow-list), prompt filling and JSON extraction; `openai_runner.py` makes one OpenAI Responses API call per tool-less session, in JSON mode |
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
| `library/TrafficSpec/Core/Language/` | `Formula`, `Semantics`, `Rule`, `Concept`, `RuleEval`, `Export` | the specification language (with `Term.cond`, a quantity selected by a guard; a comparison over it is decided wherever both selections agree), its meaning, rules and concepts, the static check, JSON export |
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

bash scripts/setup_reviewer.sh            # once: the openai package, the API key in ~/.config/traffic-spec/openai.env (mode 600), a test call
source ~/.config/traffic-spec/openai.env  # in the shell that runs a loop with --reviewer_model

python -m harness init                # library/TrafficSpec/Readings/default.json template, registries, library build
python -m harness init --fresh --snapshot <run>   # first move <run>'s nodes and concepts to results/<run>/library_snapshot/,
                                                  # its unreviewed proposals to reading_proposals.json, undecided gaps to gaps_undecided.jsonl
python -m harness doctor              # hold every generated artifact to its source
python -m harness split --use train   # swap the training-only Core files in (archives the full ones under library/splits/full/)
python -m harness split --use full    # and back; `python -m harness split` reports which is active

# a run: archive the previous run's library and unreviewed proposals, then loop over a corpus folder
# (`laws/full_list/` or a subset under `laws/example/`); with a reviewer, source the key file first
python -m harness init --fresh --snapshot <previous run>
source ~/.config/traffic-spec/openai.env
python -m harness loop --run_id <run> --laws laws/example/<subset>/laws.jsonl \
    --ontology_file ontology/ATOMS_train.md --reading library/TrafficSpec/Readings/lasvegas.json \
    --reviewer_model <model> --review_effort high \
    --plan_batch <n> --max_iterations <n> --workers <n>

# a test run on top of a training run: add-only, the training run's nodes and concepts read-only
python -m harness loop --run_id <test run> --laws laws/example/test/laws.jsonl --mode test --base_run <training run> \
    --ontology_file ontology/ATOMS_train.md --reading library/TrafficSpec/Readings/lasvegas.json --max_iterations <n>
python -m harness score_split --run_id <test run>   # gap recall / precision / approximation rate

python -m harness validate --run_id <run> [--blueprint_file <blueprint.jsonl>]   # validator A in the run's context (the plan session runs it on its draft)
python -m harness validate --blueprint_file <blueprint.jsonl> --laws <laws.jsonl> --reading <reading.json>   # context-free: no accepted node, concept or mapping is known
python -m harness gate --run_id <run> --node_id <node>   # the gate for one node or concept id (what a coding session runs)
python -m harness surface                                  # the generated Core surface a coding session is shown
python -m harness verify                                   # rebuild and run every registered witness
python -m harness index                                    # regenerate the registries
python -m harness status --run_id <run>
python -m harness reopen --run_id <run> --laws <id>[,<id>]   # a law not accepted and not blocked on a gap back to open with a fresh
                                                             # budget; its held nodes, node-ledger entries and failed concepts are dropped

# the monitor: decide accepted rules on a capture (a Core trace and its manifest); run it with the full split active
python -m harness split --use full
cd library && lake build monitor && lake exe monitor --manifest <case>/manifest.json \
    --reading ../results/<run>/reading.json [--rules <node id>,...] [--json] <case>/trace.json; cd ..
python -m harness split --use train                        # before the next training run
```

Pass the run options explicitly rather than relying on the defaults: `--workers` is 1 (one concept
or node coded at a time; set it to the parallelism wanted), `--max_iterations` is 3, and
`--plan_batch` is 8 (`--plan_batch 1` plans each law in its own session, root laws first, so a law
that names another is shown the other's planned nodes and composes them by id).

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
beside it. `--plan_turns` caps a plan or
repair session.

**The behaviour review and the adjudicator.** `--reviewer_model <model>` is required (a model of
another vendor than the agents', such as an OpenAI model; `--allow_same_vendor` overrides the check;
`OPENAI_API_KEY` must be set in the loop's shell, and no Claude session is launched with it; only
`--dry_run` runs without it). The *behaviour review*, one per node the gate accepts, writes each
divergence between the rule and the law as a trace in the decoder's format with the law's verdict,
and is shown every atom the rule reads with the trace key that writes it; the harness runs the rule
on every trace. A trace that is incomplete (an atom left out, occupancy not observed, a look-back
not covered or sampled) is asked for once more and otherwise recorded as unconfirmed; gap
candidates (a factor the law names that no contract carries) go to `TO_USER.md`. Execution
confirms what the rule does, never the reviewer's verdict for the law: every confirmed divergence,
from either of the review's answers, goes to the *adjudicator* (`prompts/adjudicate.md`, a tool-less
session of the agents' vendor), which upholds it, dismisses it (a reasonable reading gives the
rule's verdict, or an open magnitude, a disclosed narrowing or a surrogate's open standard makes it
an advisory), or sends it to the operator as a question about an aggregate word's membership. Only
an upheld divergence returns the node; a ruling the adjudicator leaves defective stands as upheld.
`--review_effort` (high) sets the reviewer's reasoning effort.

**The concept review.** A concept the gate accepts is rendered as prose from its body and a judge
(`prompts/concept_judge.md`) compares that rendering, with the coder's narrowings, against the
contract. `contradicted` (a plain instance of the notion decided the other way), `not_general` or a
misfiled family returns it; `approximated` (a nearby reading, or a narrowing the coder disclosed)
accepts it with the judge's reasons recorded on the concept and shown in the catalogue beside its
contract. A concept that has failed in a run stays failed: a plan that names it again is returned
and charged, and only `reopen` of the laws that used it clears it. Validator A returns a concept
whose contract states a figure its `literals` do not declare.

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
`SCOPE_VIOLATION`, the node is rolled back and the stray files are named in `results/<run>/TO_USER.md`.

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
session is given; `--workers` (1) the coding sessions run at once;
`--plan_turns` (40) the turn cap of a plan or repair session; `--restart` discards an interrupted
iteration; `--gate_budget` (6) the gate runs a coding session gets; `--concept_attempts` (3) the
coding attempts a concept gets, its first and its repairs, separate from the laws' `--plan_attempts`
(2); `--node_attempts` (2) the coding attempts a node gets, its first and one after a node repair
session, before its law is returned to the planner; `--repeat_limit` (3) the times the same review
outcome may recur across a law's plans and repairs before the law is blocked for the operator's
decision; `--reviewer_model`, `--review_effort`, `--allow_same_vendor` as above. A session the account or the API refused is
never counted as one of the law's attempts: the law is deferred to `open` and the loop stops after
the iteration.
A training or test run needs the training split active (`python -m harness split --use train`);
the doctor's `ontology generated` check follows the active split and its `training split` check
holds the training variant to `ATOMS_train.md` and `split_atoms.json`.

## The loop, briefly

0. **Repair** (one session per concept, and one per node, the gate or a review returned last
   iteration while it has budget): a concept repair sees the record, the verdict, the coder's result
   note and files, the ontology and the catalogue, no law; a node repair also sees its law and
   segmentation. Each writes a revised record or a withdrawal naming the missing atom or operator
   (a gap). Laws whose nodes wait on a repair stay `planned` on hold, uncharged. A repair that keeps
   a defect returns the law with the reasons that sent the node to repair ahead of the repair's own.
1. **Plan** (one session per batch of at most `--plan_batch` laws, root laws before the laws whose
   text names them; a law naming a planned or blocked law waits, one naming a failed law fails; the
   prompt carries the definitions the batch's laws cite or whose defined term they use, not the
   folder's): segments each plannable law's verbatim text into spans with roles,
   maps every substantive span to atoms or derived concepts by quoting their contracts,
   operationalizes standards with named reading parameters (proposing those the reading lacks) and
   reads each factor a standard names by its degree, declares when each trigger, condition and
   exception span is read where the obligation is an act observed over time (`occasion`: where the
   act is recognized, at some moment while it is under way, or throughout it; what marks the act
   under way is an element that reads the road user's motion), plans four witnesses (and, for each
   span read while the act is under way, an `occasion_<span>` witness where it holds for part of the
   act and an `occasion_<span>_outside` witness where it holds only outside it, with different
   verdicts), and files a gap
   where no contract carries a span. Writes `blueprint.jsonl`, `PLAN.md`, `proposed_gaps.jsonl`,
   `aggregates.jsonl`.
2. **Validate**: A, deterministic (segmentation is a partition; total accounting; closed set;
   standards have parameters in the reading or proposed; no zero literal declared; plan narrowings
   only on carried obligation or standard spans; node id derived from the law id; one node per
   obligation span, an accepted node never re-planned; same words same atoms across the run;
   compositions resolve, no cycles; no residue on a trigger, subject, condition or exception span
   unless it declares `scope: none`; the four witnesses; the occasion of an act observed over time,
   with its witnesses). An obligation carried only by a residue
   fails the law; a gap blocks it whatever else is wrong; errors alone return it. The same check,
   in the run's context, is the draft validator the planner runs (`python -m harness validate
   --run_id <run>`).
3. **Code** (one session per concept, then per node, in dependency waves of `--workers`): a node's
   session starts from the two files the harness wrote from the
   node (`harness/lean/skeleton.py`: every declaration the gate compares, the parameters as terms,
   every planned scenario with its verdict and masked atoms — they build as written), with the generated
   Core surface (`harness/lean/surface.py`: accessors with the field each reads, derived contracts,
   builders, world records, units), the reading's values for the node's parameters and the most
   recently accepted node as the worked example. Writes the formulas and the scenes, runs the gate,
   stops on `OK` or when the budget is spent. The harness re-runs the gate itself. Core is readable
   in a session and never writable; the harness is neither. **Review**: the behaviour review and the
   adjudicator (see above); a node with an upheld divergence is rolled back (its files restored)
   and goes to a node repair session while it has budget; then its law is returned and charged.
4. **Integrate**: registries, whole-library build, every witness, composition DAG; reverts this
   iteration's nodes newest first, then its concepts, until the library verifies.
5. **Feedback**: `AUTO_NOTES.md` for the next plan (the iteration's notes, returned laws and
   concepts with their reasons, coder narrowings, gaps filed); `results/<run>/TO_USER.md` for the
   operator, one section per iteration, kept across iterations (gaps awaiting a decision, gap
   candidates, compositions, parameter proposals and derived aggregates to review, laws blocked
   for a decision with the `reopen` command, scope violations, sessions that did not run).

**The gate** (`harness/checks/gate.py`), in order: `SCOPE_VIOLATION`, `BUILD_FAIL`, `UNSOUND` (sorry,
axioms, unsafe constructs — scanned in code only, never in the header comment or the
operationalization strings that carry the law's words), `CHECK_FAIL` (`Rule.check`, which also
rejects a number in an entity position, `Rule.checkReading`, which holds every aggregate word
a rule names to the reading, and no division by a term that reads a measurement, which can be
zero — a comparison is written with products), the claim checks (a formula's atoms are what the evaluator reads: its
leaves, the clock or path length of every window, and the kind of every quantifier with a literal
kind, so a claimed `kin.time` is used by a time window and a claimed `st.lane` by
`existsRegion (.lit "lane")`; the clock needs no claim; a concept's atoms are taken over every
admissible value of its literal formals), `UNANCHORED_VARIABLE` (a quantified region, device or user related to
no binder through an atom, a derived concept or a composition — a feature the rule reads must be
the subject's, not any in the scene), `DECLARATION_MISMATCH` (the node's residues must all be in
the rule and none added; a reading the coder chose on a carried span is a narrowing `{span, why, kind}`,
carried to the review, the feedback and the accepted record under its own key),
`SCOPE_NARROWED` (a narrowing on a trigger, subject, condition or exception span: the rule would
apply where the law does not), `UNEXPRESSED` (a narrowing of kind `no_atom` or `no_operator`: the
coder says the words cannot be stated; the repair withdraws the span as a gap or re-maps it, and a
second such declaration files the gap), `UNCLAIMED_ATOM` / `UNUSED_CLAIM` / `BARE_LITERAL` (the set of literals a formula writes must equal the declared set; a figure counts once however often it is written), `WITNESS_FAIL` (a planned scenario
has no witness, a verdict differs from the planned one, `idle` grounds a binder to a track that never appears, `blind` is unknown for
anything but its masked atoms, or its manifest masks something other than the node's `masked`),
`VACUOUS` (a leaf no decided witness exercises; `blind` does not count), `OK`; a session that spends
its gate runs ends `BUDGET_EXHAUSTED`. A toolchain that did
not run is `INFRA`: the law is deferred without an attempt and the loop stops after the iteration.
The witnesses are the node's tests, written by the same session as the rule from the planner's
narratives; they show the formulas are executable and reach every verdict, and never stand as
evidence that the rule says what the law says — that is the review's job.

**Aggregates.** "Vehicle", "motor vehicle", "traffic" are one atom, `ru.aggregate`, with the word
as its literal argument. Which `ru.*` classes (or other words, expanded transitively) a word
covers is **derived by the run** from the corpus definitions: the plan session writes
`aggregates.jsonl` (word, definition id, classes, justification, unresolved kinds), the harness
validates it (`harness/checks/aggregates.py`: definition given, classes in the ontology, members
resolvable, one record per word in an iteration — a second record with other classes is rejected) and merges the accepted records into the run's reading `results/<run>/reading.json`,
which every later phase uses. The run's `TO_USER.md` lists each derived aggregate for review; an operator
entry in the base reading's `aggregates` overrides the derived one. The repository declares no
membership. The planner claims `ru.aggregate=<word>` and never expands it.

**Standards and proposed parameters.** Every operationalization names at least one parameter; the
validator returns a node whose standard is bounded by a structural test with no magnitude behind
it. A parameter the reading lacks is proposed
on the node (`param_proposals`: name, unit, provisional value, convention, source); before the node
is coded the harness enters it in the run's reading and the base reading marked `proposed` (with
the run, iteration and node), the node is coded against it, and the doctor's `reading proposals`
check lists it until the operator reviews it by removing the marker or changing the value. A
catalogued value is named as it is, except one a node of the same law proposed and the operator has
not reviewed, which that law's repair or re-plan may propose again with another value (unless a
node of another law names it). Each factor a standard names is read by its degree — a measured
magnitude enters the bound, a condition selects among bounds — never by one fixed bound that any
factor switches on. A gap is only `atom` or `operator`: the
frozen vocabulary cannot carry the span.

**Composition order.** A node is coded only after every node it composes is accepted; a node whose
composed node is not accepted yet is kept in `results/<run>/deferred_nodes.jsonl` and coded in a
later iteration without re-planning and without an attempt counted, its law staying `planned`
until every node it was planned with is accepted; a node composing a law closed as failed is
closed as failed too, and one composing a law blocked on a gap is blocked on that gap. A node
whose concept was returned is held while the concept is repaired, uncharged; when the concept
fails or cannot be repaired, its law is returned with the concept's reasons. An accepted node is never coded again: a returned law re-plans its
returned nodes only.

**Per-law termination** (`results/<run>/ledger.jsonl`): `open` → `planned` → `returned` (a fixable
defect; one attempt per law per iteration, however many of its nodes fail; a law returned because a
concept its nodes use failed is charged once per such concept, not once per iteration it waits) → `accepted` | `blocked`
(a gap; waits for the operator, and reopens when every gap is retired or rejected) | `failed`
(budget spent, the obligation itself is not expressible, or a named law failed). The same review
outcome drawn `--repeat_limit` times across a law's plans and repairs (the behaviour review's
divergence kind on the same quoted words of one node, counted once per review, upheld by the
adjudicator) blocks the law on `decision:<law>`
for the operator, who reopens it with `python -m harness reopen`. A session or toolchain that did
not run defers the law to `open` with no attempt counted. The planner is shown only `open` and `returned` laws.

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
