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
| `ontology/ATOMS.md`, `ontology/ATOMS_train.md` | the closed set of atoms (126; 117 in the training variant), enumeration values and primitives, each with its contract; the training variant omits what only test lines support. Concepts are not in the ontology: they are records the plan proposes and the library holds (`library/TrafficSpec/Concepts/`) | yes |
| `library/TrafficSpec/Core/**` | the Core library in five layers (see *Core structure*): three-valued semantics, units and time, the vocabulary and primitives, the language and its static check, grounding and the monitor, witness builders and adequacy. `library/splits/{full,train}/` hold the two variants of the files the split touches; `library/splits/ACTIVE` says which one the Core directory holds (`python -m harness split`) | yes |
| `library/TrafficSpec/Rules/<Body>/<NodeId>.lean`, `library/TrafficSpecWitness/<Body>/<NodeId>.lean` | one rule and its witnesses per node; `Index.lean` and `TrafficSpecWitness.lean` are generated registries | agent-written, gate-accepted |
| `laws/full_list/`, `laws/example/{train,test,demo,carla_smoke}/` | the corpus as posted law (`id`, `title`, `text`, `source`) with its definitions; `demo/` and `carla_smoke/` are reference-closed subsets of the training set (a first run; lines with standards of judgement, scored on simulator captures), made with `python -m nrs_tools.subset`, older subsets in git history; `laws/audit_and_scripts/` holds the analysis sidecars and the split record | input |
| `library/TrafficSpec/Readings/<run>.json` | the parameter catalogue: every number a statute did not state, with its unit (the law's own units are accepted: ft, mph, min, …) and the convention its value comes from; `library/TrafficSpec/Readings/lasvegas.json` is this corpus's base reading; it starts empty and is filled by the planner's proposals, which the operator reviews (the pre-pipeline operator list is archived under `library/TrafficSpec/Readings/legacy/`). A figure a statute states is never a reading parameter: it is a literal on its law's span. The doctor's `reading figures` check lists every parameter whose value equals a figure some law states, until the entry carries a `figure_review` note | operator-written input |
| `prompts/*.md` | twelve templates: `plan`, `plan_aggregates`, `code`, `code_concept`, `concept_repair`, `node_repair`, the second vendor's `review_code`, `review_concept` and `verify_aggregate`, and the judges `judge_case`, `adjudicate` and `adjudicate_concept` | yes, law-free |
| `harness/` | the loop, its phases and the modules they share, grouped by role (see *Harness structure*) | code |
| `scripts/gen_ontology.py`, `scripts/diagnostics/`, `scripts/setup_reviewer.sh` | the ontology generator, the doctor (`prompts vocabulary-free` holds the templates to injected context only: no vocabulary id, parameter or corpus-defined term in a rule) and the reviewer's one-time key setup | code |
| `library/TrafficSpec/Gaps/ledger.jsonl` | what the frozen vocabulary cannot carry (kinds `atom` and `operator` only), proposed by plan and repair sessions, decided by the operator (`retired` when the ontology or Core now carries it, `rejected` when the span is carried as it is); one ledger for every run, each plan shown only the gaps on its own corpus's laws (and its base run's); ids come from `counter.txt` beside it, which only grows | operator-decided |
| `results/<run>/` | per-run artifacts: `options.json`, `reading.json` (the run's reading, with the admitted aggregates), `definition_resolution.json`, `aggregate_selection.jsonl`, `aggregate_certificates.jsonl`, `rulings.jsonl`, the law, concept and node ledgers (`ledger.jsonl`, `concept_ledger.jsonl`, `node_ledger.jsonl`), `accepted_nodes.jsonl`, `accepted_concepts.jsonl`, `deferred_nodes.jsonl`, `mapping.json`, `AUTO_NOTES.md`, `TO_USER.md`, `summary.json`, and per iteration `iter-NNN/{plan,repair,validate,review,code,integrate}` with `progress.json` | run output |

## Harness structure

`harness/` is grouped by role, not by stage: the stages live in `harness/phases/`, and the
modules the stages share sit in one folder each.

| folder | modules | what it holds |
|---|---|---|
| `harness/` | `__main__.py`, `loop.py` | the CLI (`python -m harness …`) and the iteration driver: ledger transitions, dependency order, deferral, stop conditions |
| `harness/phases/` | `plan.py`, `aggregate.py`, `validate.py`, `review.py`, `code.py`, `integrate.py`, `feedback.py` | one module per stage of the loop (`plan.py` also runs the concept and node repair sessions; `validate.py` also a concept's judge; `review.py` is the second vendor's behaviour review and the adjudicator) |
| `harness/model/` | `blueprint.py`, `corpus.py`, `definitions.py`, `mapping.py`, `nodeid.py`, `ontology.py`, `reading.py`, `units.py` | the pipeline's data: blueprint records, the corpus and its mechanically resolved definition graph, the mapping index, derived ids and paths, the closed set, the reading, unit factors |
| `harness/store/` | `paths.py`, `state.py`, `ledger.py`, `gaps.py` | where things live and the run's state: options and run directories, the law, concept and node ledgers, the gap ledger |
| `harness/lean/` | `lean.py`, `index_sync.py`, `skeleton.py`, `surface.py`, `render_formula.py` | everything that reads or writes `library/`: lake calls, the registries, the skeletons, the Core surface, the formula renderer |
| `harness/agents/` | `runner.py`, `session.py`, `render.py`, `openai_runner.py` | agent sessions (launch, relaunch on refusal, jail and allow-list), prompt filling and JSON extraction; `openai_runner.py` makes one OpenAI Responses API call per tool-less session, in JSON mode, and one request at a time of a reviewer's tool session (`session.run_tools`) |
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

python -m unittest discover scripts/tests # the harness's own tests: the certificate protocol, review routing, definition resolver, aggregate gate and run-budget integrity
bash scripts/setup_reviewer.sh            # once: the openai package, the API key in ~/.config/traffic-spec/openai.env (mode 600), a test call
source ~/.config/traffic-spec/openai.env  # in the shell that runs a loop with --reviewer_model

python -m harness init                # library/TrafficSpec/Readings/default.json template, registries, library build
python -m harness init --fresh --snapshot <run>   # first move <run>'s nodes and concepts to results/<run>/library_snapshot/,
                                                  # its unreviewed proposals to reading_proposals.json, undecided gaps to gaps_undecided.jsonl
python -m harness doctor              # hold every generated artifact to its source
python -m harness split --use train   # swap the training-only Core files in (archives the full ones under library/splits/full/)
python -m harness split --use full    # and back; `python -m harness split` reports which is active

# a run: archive the previous run's library and unreviewed proposals, then loop over a corpus folder
# (`laws/example/train/` or a subset of it; without --laws and --ontology_file a run uses the
# training split and ATOMS_train.md); with a reviewer, source the key file first
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

**The behaviour review and its two judges.** `--reviewer_model <model>` is required (a model of
another vendor than the agents', such as an OpenAI model; `--allow_same_vendor` overrides the check;
`OPENAI_API_KEY` must be set in the loop's shell, and no Claude session is launched with it; only
`--dry_run` runs without it). The *behaviour review*, one per node the gate accepts, writes each
divergence between the rule and the law as a trace in the decoder's format, a grounding of the
rule's binders, and a *case*: a formula of the specification language (`{case_language}`, generated
from `Core/Language/Export.lean`) over the catalogue of atoms and primitives a case may name
(`{case_vocabulary}`, generated from the active Core and the run's ontology), true at one
observation `at`, that states the facts the law's verdict turns on. A case names concrete classes,
never an aggregate, a parameter, an assumption, a rule or a concept; its units must agree
(`Dimensions.lean`, generated from ATOMS.md §10–§11). A Lean program
(`Certificate.record`, one `CERT` line per divergence it is given, run on each check and on each
submitted divergence) decodes the trace and the case strictly,
runs the trace check (`Core/Evidence/TraceLint.lean`: identity, a static map, valid geometry,
path length, heading against yaw rate — exact, no tolerance; the occupancy of an observed track
is not written by the reviewer but derived from its footprint and the boundaries, over closed
sets, before the check), the witness check, the case check and the case at `at`, and then the rule's verdict at
`at` with each referenced aggregate's membership forced true and false; when the case is not true at
`at`, it names the conjunct that is not, and within a conjunct over every road user the fact and
the user. The reviewer runs this program itself before it answers. Its session has two function
tools and no other:
- `check_divergence` runs one divergence, in a directory of its own under `review/checks/`, and
  returns what the harness would make of it, with the messages. No judge is asked.
- `submit_review` runs the schema checks and the same program on the exact answer. An answer with
  a schema defect, or a divergence that cannot be evaluated, comes back while submissions remain;
  the last submission stands.

A rule is reviewed by `--review_passes` (2) such sessions at once, independent of each other: the
same prompt, each its own checks, submissions and evidence (`review/pass<k>/`). Their challenges
are joined, and one whose certified case repeats an earlier one is judged once. A pass that
submitted no usable answer is dropped when the other did, and the review defers only when none
did. A single session misses a real defect about one time in five, whatever its effort, so a
second sample is what lowers the miss rate. A concept is reviewed by one session.

`--review_checks` (8) and `--review_submissions` (3) are counted apart, so a submission is always
possible once the checks are spent; a session may make up to four requests more than its checks and
submissions, for answers that call no tool. A divergence is run once per session (a divergence with
a schema defect is not run at all): the rule, the concepts and the reading do not change while the
session runs. Each launch keeps its evidence in its own directories (`review/checks/L<launch>/`,
`review/submissions/L<launch>/`). Each request is reserved and recorded on its own
(`<label>:<subject>:L<launch>.r<n>` in `usage.jsonl`; the judges' rows also carry the node), and the
session has one deadline, `--session_timeout`. A request the API refuses or fails relaunches the
whole session, as for any session, with no retry inside the request; the API's reason, sanitized,
is kept in the session's stream. A certificate program that does not run defers at stage
`certificate`, for a rule or a concept; the diagnosis of a case that is not true is an aid only,
and when it does not run the certificate stands without it. A case whose execution refutes the
reviewer (the rule already gives the verdict claimed for the law) is an advisory; a challenge that
is still defective leaves the review undecided, and unless another case is upheld it defers the law at stage
`reviewer`, as an invalid judge does below. Before the reviewer is asked, the harness computes the
history the rule's verdict at an observation reads (nested windows added up, one observation more
per `rises`, a window ahead counted ahead, a concept read with its call's values) and states it with
the parameters; a truncated look-back's message repeats it. A message on a sparsely sampled
look-back names the rule's time and distance parameters with their values. Every advisory or divergence
situation of the reviewer that names a proposed parameter of the rule by its id is copied to
`TO_USER.md` under that parameter's review line, labelled with what became of it (information
only; it routes nothing). An admitted divergence goes to *stage A*
(`prompts/judge_case.md`, a tool-less session of the agents' vendor), which decides the law's
verdict on the rendered case from the law, the posted definitions that apply to it and the case's
contracts — never seeing the rule, the record, the reviewer's prose or any mapping. Where the
rule's verdict at `at` differs (compliant and not applicable count alike), *stage B*
(`prompts/adjudicate.md`) decides whether the mismatch is a defect (`upheld`, the only outcome that
returns the node), a disclosed reading the words permit, a size-dependent mismatch on a reviewed
parameter (dismissed) or an unreviewed one (`parameter_question`, a question in `TO_USER.md`; the
node proceeds), or a membership the aggregate gate admitted (`verified_aggregate`, available only
when the forced memberships mechanically show it). A rule unknown only because an admitted
aggregate leaves a class unresolved is an advisory before either judge. A judge whose answer stays
invalid after one re-ask defers the law (its node is coded again next iteration, no attempt
counted); a second consecutive deferral closes it (`judge_protocol_failure`). Each digest hashes
the exact request a judge was sent. Every certified case is kept in `results/<run>/rulings.jsonl`
(append-only; a re-judgment appends a row that supersedes the case's previous one); before the
reviewer is asked about a later rule of the same node id, every upheld case of that node is
certified and judged again where a judge's input changed, and one still upheld returns the node
without a review. The plan and node repair sessions are shown these cases as regression
obligations, never as mapping instructions. An operator who finds a ruling wrongly upheld sets its
`ruling` to `retired`. The reviews of a coding wave run in parallel, and their outcomes are applied
once all have finished. `--review_effort` (high) sets the reviewer's reasoning effort.

**The concept review.** A concept the gate accepts is reviewed the way a rule is: the second vendor
(`prompts/review_concept.md`) reads the contract, the record with the coder's readings, and the body
rendered as prose, and writes every situation in which the body decides differently from the
contract as a trace with an instance (a spelling for each literal formal, a value for each
parameter, a track for each track formal); the harness runs the concept on it as a rule
(`Concept.asRule`), so a divergence counts only where the body's executed verdict differs from the
contract's. The reviewer runs each divergence first with `run_instance`, and submits with
`submit_review`, under the same counts as the rule review. One on which the body gives the
contract's verdict is an advisory, and a challenge that still cannot be run
(a schema defect, a trace that does not decode, an incomplete trace) defers the concept at stage
`reviewer` unless an item is upheld. The record shown names the literal formals the instance fills
(none: `instance.literals` is `{}`). A concept of kind `quantity` returns a value: its divergence
states the interval the contract's words put the value in (`contract_value`, `lo` and `hi` with
their units, of the value's dimension as inferred from the body), which the harness passes as the
instance's `bounds`, so the value outside the interval confirms it, as a quantity's witnesses are
checked. A parameter value outside the domain its meaning states is an advisory. Each confirmed
divergence, and each `not_general` item (words of the contract or the body tuned to one use), goes
to the concept adjudicator (`prompts/adjudicate_concept.md`), which rules by the contract's words and
by its own earlier rulings on the concept; an upheld item returns the concept to concept repair. The
dismissed items and the reviewer's advisories are recorded on the accepted concept and shown in the
catalogue beside its contract. The reviews of a concept wave run in parallel. A concept that has
failed in a run stays failed: a plan that names it again is returned
and charged, and only `reopen` of the laws that used it clears it. Plan validation returns a node or concept record that claims a region's property (an atom of regions only, other than a region kind) without claiming `rel.occupies` and a region kind: the place where the road user reads it. Validator A returns a concept
whose contract states a figure its `literals` do not declare, and one with a literal formal whose
values are region or device kinds that does not claim the kind atom of each (the body reads them all).

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
run), because `index_sync` registers every file on disk. At start (`loop.check_library_isolation`)
a node or concept on disk that neither the run nor its `--base_run` accepted is moved into the
snapshot of the run that accepted it, the base run tried first, never over an archived copy (else
into a dated `results/library_strays_*`); one they accepted that is missing is restored from the
run's snapshot, and the run refuses to start only when it cannot be.

**Subset runs.** A development run that reruns part of a corpus (see `CLAUDE.md`, Development
runs) takes its laws from `python -m scripts.subset_laws <run> <corpus laws.jsonl> <law id>…`,
which writes `results/<run>/laws/laws.jsonl` and the `definitions.jsonl` beside it, and is launched
with `--base_run <previous run>`. A base node whose law the subset lists is not reused: the law is
planned again. A base node that composes such a node stops the run until its law is listed too.
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
   segmentation. Each writes a revised record or a withdrawal naming the missing atom or operator;
   a concept repair may also split the concept into new records under new ids. A concept is
   repaired only while a held node claims it, or a returned concept repaired for its own users calls
   it, directly or through others; one nothing uses
   waits, returned, until a plan claims it again. A withdrawn or split concept returns every law
   whose held nodes claim it now to the planner (a withdrawal files a gap for the operator to see,
   which blocks nothing); a node repair's withdrawn span files a gap. Laws whose
   nodes wait on a repair stay `planned` on hold, uncharged. A repair that keeps a defect returns the
   law with the reasons that sent the node to repair ahead of the repair's own, and the law's held
   nodes go back with it. The sessions run in parallel (`--workers`); a law's own node repairs run
   in order, each seeing its siblings' revised records.
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
   verdicts), and proposes a gap where no contract carries a span, still mapping the span to its
   nearest atoms. It is shown the ontology, the catalogue and the formula language: an atom gap may
   not propose an atom the ontology has, nor an operator gap an operator the language has. Writes
   `blueprint.jsonl`, `PLAN.md`, `aggregates.jsonl`.
2. **Validate**: A, deterministic (segmentation is a partition; total accounting; closed set;
   standards have parameters in the reading or proposed; no zero literal declared; plan narrowings
   only on carried obligation or standard spans, except an `observable_reading` — a word with no
   observable counterpart (an intention, a perception or a knowledge, a purpose, the legal status of
   a feature on the road, who or what controls a vehicle) read through the conduct or feature it refers to, of one of those five
   categories, on any carried span, which `TO_USER.md` lists for review; node id derived from the law id; one node per
   obligation span, an accepted node never re-planned; the role of a law's words fixed once a node of
   the law is accepted;
   compositions resolve, no cycles; no residue on a trigger, subject, condition or exception span
   unless it declares `scope: none`; the four witnesses; the occasion of an act observed over time,
   with its witnesses). An obligation carried only by a residue
   fails the law; errors return it; a proposed gap does not block: the node is coded, and the gap is
   filed only when the coder declares the span unexpressible (`UNEXPRESSED`). The same check,
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
rejects a number in an entity position, `Rule.checkReading`, which holds every aggregate id
a rule names to the run's admitted aggregates, and no division by a term that reads a measurement, which can be
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
apply where the law does not; an `observable_reading` the plan declared on that span is the plan's
own reading and is not one), `UNEXPRESSED` (a narrowing of kind `no_atom` or `no_operator`: the
coder says the words cannot be stated; the repair withdraws the span as a gap or re-maps it, and a
second such declaration files the gap; a concept with such a narrowing gets the same verdict, and its
repair retypes the formal the body cannot honour or withdraws the concept, which files a gap), `UNCLAIMED_ATOM` / `UNUSED_CLAIM` / `BARE_LITERAL` (the set of literals a formula writes must equal the declared set; a figure counts once however often it is written), `PARAM_MISMATCH` (a concept call passes a
parameter that is neither a reading parameter, or for a concept body one of its own formals, in the
unit the concept declares, nor a figure the record declares in that unit — a literal zero included), `WITNESS_FAIL` (a planned scenario
has no witness, a verdict differs from the planned one, `idle` grounds a binder to a track that never appears, `blind` is unknown for
anything but its masked atoms, or its manifest masks something other than the node's `masked`),
`VACUOUS` (a leaf no decided witness exercises; `blind` does not count), `GATE_TIMEOUT` (the harness
ran out of time evaluating the formulas on the witnesses; the details give the rule's deepest chain of
quantifiers under window operators, and the law returns to the planner, since a repair cannot change
the shape the mapping decides), `OK`; a session that spends its gate runs ends `BUDGET_EXHAUSTED`. A
toolchain that did not run (a missing `lake`, a build that timed out, a harness that stopped with no
error) is `INFRA`: the law is deferred without an attempt and the loop stops after the iteration.
The witnesses are the node's tests, written by the same session as the rule from the planner's
narratives; they show the formulas are executable and reach every verdict, and never stand as
evidence that the rule says what the law says — that is the review's job.

**Budget and run status.** Every session of either vendor appends a row to `results/<run>/usage.jsonl`
(tokens, reasoning tokens, cost; OpenAI costs from the operator's `config/model_prices.json`).
`--openai_budget_usd` limits the second vendor's calls run-wide: each call's worst case is reserved
before it is launched, and a call that does not fit pauses the run (`paused_budget`), resumed under
the same run id once the limit is raised. A reviewer's tool session makes several requests, each
reserved at its whole input (the prompt and everything sent back) and the output limit, and settled
as it returns. `--reviewer_max_output_tokens` (64000) bounds each OpenAI request, reasoning
included; `--max_divergences` (3) bounds each review answer. `--stall_stop` (on) ends
the run after any iteration from the second on that accepts neither a node nor a concept and leaves no remedy
awaiting its first try — a law or a node or a concept returned once, or a law or a concept deferred once
(`incomplete`, stalled). A run ends `complete`,
`incomplete`, `infrastructure_failure`, `paused_budget`, `stale_aggregate` (an aggregate's inputs
changed under nodes that claim it: start a new run) or `data_integrity_failure` (an audit file —
`rulings.jsonl`, the aggregate selection or certificates — cannot be read as written; it is named and
left as it is); `summary.json` records it, and the command exits non-zero unless `complete`.

**Definitions and aggregates.** Which posted definition applies to a law's words is resolved
mechanically (`harness/model/definitions.py`) from the run's `laws.jsonl` and the `definitions.jsonl`
beside it, by the operator's declared precedence (`config/definition_precedence.json`, option
`--definition_precedence`): a definition the law cites inline or a section-only one of its section,
then its own chapter, then its code's general chapter, then the general chapter of the code it falls
back to; the table is `results/<run>/definition_resolution.json`, and the doctor reports the
training laws' unresolved and ambiguous terms. The same precedence resolves defined terms used
inside each reached definition from that definition's own place; this finite dependency closure is
shown to planning and judgment and is part of every aggregate's invalidation digest. Before any law is planned, one planner session
(`prompts/plan_aggregates.md`) marks each (definition, term) `aggregate`, `not_aggregate` or `gap`
(`aggregate_selection.jsonl`) and classifies every road-user class under each aggregate as included,
excluded or unresolved, with quotes; one second-vendor session per aggregate
(`prompts/verify_aggregate.md`) checks each class (supported, contradicted, underdetermined), a
contradiction goes back to the planner once, and what it cannot support is admitted as unresolved
(`aggregate_certificates.jsonl`). The admitted aggregate enters the run's reading under its id,
`<definition id>::<term>`; a plan claims `ru.aggregate=<id>` and never expands it, and writes a
law-local aggregate (`<law id>:<span>::<term>`) only where its clause defines its own members.

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
