# traffic-spec-agent — law-facing autoformalization of traffic law into Lean 4

The pipeline formalizes posted traffic law as Lean 4 rules that a monitor evaluates on driving
traces. A rule gives one of four verdicts at each observation: `violated`, `compliant`,
`not_applicable` or `unknown`.

- **Inputs.**
  - The corpus (`laws/`): Nevada traffic law, scoped to ordinary urban Las Vegas driving and judged
    for a vehicle driver. Each line holds its posted text, with the posted definitions beside it.
  - The frozen vocabulary: the ontology (`ontology/ATOMS.md`) and the Core library
    (`library/TrafficSpec/Core/`).
  - The frozen prompts (`prompts/`).
  - The operator's reading, which holds the parameter values (`library/TrafficSpec/Readings/`), and
    the operator's definition precedence (`config/`).
- **Outputs.**
  - For each obligation of a law, a *node*: a rule file and a witness file under `library/`. A node
    is accepted only when the harness's gate and a behaviour review both pass it.
  - *Concepts*: reusable derived predicates that rules call, each reviewed against its own
    contract.
  - Per run, the ledgers, rulings and records under `results/<run>/`.
- **Roles.**
  - The *planner*, a Claude session, segments a law and maps each span to atoms or concepts. It
    also decides open readings and proposes parameters.
  - The *coder*, a Claude session, writes the Lean the record states.
  - The *reviewer*, a model of another vendor (a GPT model through the OpenAI API), writes situations
    as traces in which the rule and the law decide differently. The harness executes them.
  - Two *judges*: stage A decides the law's verdict on a certified case without seeing the rule,
    and stage B decides whether a confirmed mismatch is a defect.
  - The *harness* validates, gates, executes and routes; it decides nothing a role above decides.
  - The *operator* decides gaps, parameter values and definition precedence.
- **The loop.** Each iteration runs repair → plan → validate → code (gate, review) → integrate →
  feedback. The run ends when every law is accepted, blocked on a gap or failed, or when the
  iteration bound is reached. Its state lives in one snapshot, `results/<run>/state.json`, so a
  stopped run resumes where it stopped.
- **Out of scope.** No scene-graph schema, adapter or perception manifest is part of this pipeline:
  what a data source can observe is a run-time manifest for the monitor. Evaluation on driving data
  lives in `../evaluation/`, outside the pipeline.

The design documents are kept locally, unversioned, under `../DesignFile/`; the loop's design is
in `PIPELINE_V2_DESIGN.md`.

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
| `ontology/ATOMS.md`, `ontology/ATOMS_train.md` | the closed set of atoms (128; 119 in the training variant), enumeration values and primitives, each with its contract; the training variant omits what only test lines support. Concepts are not in the ontology: they are records the plan proposes and the library holds (`library/TrafficSpec/Concepts/`) | yes |
| `library/TrafficSpec/Core/**` | the Core library in five layers (see *Core structure*): three-valued semantics, units and time, the vocabulary and primitives, the language and its static check, grounding and the monitor, witness builders and adequacy. `library/splits/{full,train}/` hold the two variants of the files the split touches; `library/splits/ACTIVE` says which one the Core directory holds (`python -m harness split`) | yes |
| `library/TrafficSpec/Rules/<Body>/<NodeId>.lean`, `library/TrafficSpecWitness/<Body>/<NodeId>.lean` | one rule and its witnesses per node; `Index.lean` and `TrafficSpecWitness.lean` are generated registries | agent-written, gate-accepted |
| `laws/full_list/`, `laws/example/{train,test,demo,carla_smoke}/` | the corpus as posted law (`id`, `title`, `text`, `source`) with its definitions; `demo/` and `carla_smoke/` are reference-closed subsets of the training set (a first run; lines with standards of judgement, scored on simulator captures), made with `python -m nrs_tools.subset`, older subsets in git history; `laws/audit_and_scripts/` holds the analysis sidecars and the split record | input |
| `library/TrafficSpec/Readings/<run>.json` | the parameter catalogue: every number a statute did not state, with its unit (the law's own units are accepted: ft, mph, min, …) and the convention its value comes from; `library/TrafficSpec/Readings/lasvegas.json` is this corpus's base reading; it starts empty and is filled by the planner's proposals, which the operator reviews (the pre-pipeline operator list is archived under `library/TrafficSpec/Readings/legacy/`). A figure a statute states is never a reading parameter: it is a literal on its law's span. The doctor's `reading figures` check lists every parameter whose value equals a figure some law states, until the entry carries a `figure_review` note | operator-written input |
| `prompts/*.md` | thirteen templates: `plan`, `plan_aggregates`, `code`, `code_concept`, `concept_repair`, `node_repair`, the second vendor's `review_code`, `review_concept` and `verify_aggregate`, and the judges `judge_case`, `adjudicate`, `adjudicate_concept` and `recheck_concept` | yes, law-free |
| `harness/` | the loop, its phases and the modules they share, grouped by role (see *Harness structure*) | code |
| `scripts/gen_ontology.py`, `scripts/diagnostics/`, `scripts/setup_reviewer.sh` | the ontology generator, the doctor (`prompts vocabulary-free` holds the templates to injected context only: no vocabulary id, parameter or corpus-defined term in a rule) and the reviewer's one-time key setup | code |
| `library/TrafficSpec/Gaps/proposals.jsonl`, `decisions.jsonl` | what the frozen vocabulary cannot carry (kinds `atom` and `operator` only), proposed by plan and repair sessions, decided by the operator (`retired` when the ontology or Core now carries it, `rejected` when the span is carried as it is); one ledger for every run, each plan shown only the gaps on its own corpus's laws (and its base run's); ids come from `counter.txt` beside it, which only grows | operator-decided |
| `results/<run>/` | per-run artifacts: `options.json`, `reading.json` (the run's reading, with the admitted aggregates), `definition_resolution.json`, `aggregate_selection.jsonl`, `aggregate_certificates.jsonl`, `rulings.jsonl`, `recheck_answers.jsonl` (each valid concept recheck answer, under the digest of its full prompt, model and effort, taken again in any later iteration or restart of the run instead of a new session; never a ruling), the law, concept and node ledgers (`ledger.jsonl`, `concept_ledger.jsonl`, `node_ledger.jsonl`), `accepted_nodes.jsonl`, `accepted_concepts.jsonl`, `state.json` (the run's authoritative state: the current iteration's progress, the ledgers, the accepted and held records, the aggregate failures and the concept versions found defective), `mapping.json`, `AUTO_NOTES.md`, `TO_USER.md`, `summary.json`, `usage.jsonl` (each session's spend, a `pending` row before a reviewer request and a `settled` row after it), `validator_fault.txt` (only when the validator itself failed), and per iteration `iter-NNN/{plan,repair,validate,review,code,integrate}` (a coding task's directory keeps its `baseline.json` and `toolchain.jsonl`, each lake or Lean call of its gates with the attribution) | run output |

## Harness structure

`harness/` is grouped by role, not by stage: the stages live in `harness/phases/`, and the
modules the stages share sit in one folder each.

| folder | modules | what it holds |
|---|---|---|
| `harness/` | `__main__.py`, `loop.py` | the CLI (`python -m harness …`) and the iteration driver: ledger transitions, dependency order, deferral, stop conditions |
| `harness/phases/` | `plan.py`, `aggregate.py`, `validate.py`, `review.py`, `code.py`, `integrate.py`, `feedback.py` | one module per stage of the loop (`plan.py` also runs the concept and node repair sessions; `validate.py` also holds the judge sessions' launcher and the contracts table every reviewer and judge is shown; `review.py` is the second vendor's behaviour review of rules and concepts, the judges, the replay of earlier rulings and the dependency-defect reports) |
| `harness/model/` | `blueprint.py`, `corpus.py`, `definitions.py`, `mapping.py`, `nodeid.py`, `ontology.py`, `reading.py`, `units.py` | the pipeline's data: blueprint records, the corpus and its mechanically resolved definition graph, the mapping index, derived ids and paths, the closed set, the reading, the units (read from Core: factors, dimensions, spellings) and the parser of the figures a law states |
| `harness/store/` | `paths.py`, `state.py`, `ledger.py`, `gaps.py`, `budget.py`, `owner.py`, `jsonl.py` | where things live and the run's state: options and run directories, the law, concept and node ledgers, the gap ledger, the durable spend record, the owner of the library and its processes, the append-only JSON-lines files |
| `harness/lean/` | `lean.py`, `index_sync.py`, `skeleton.py`, `surface.py`, `render_formula.py`, `relations.py` | everything that reads or writes `library/`: lake calls, the registries, the skeletons, the Core surface, the formula renderer, the check of a trace's supplied relations against Core's computation |
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
                                                  # its unreviewed proposals to reading_proposals.json, resolved gaps to their runs' gaps.jsonl
                                                  # (it refuses while a gap is open)
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
python -m harness verify --run_id <run>                    # today's gates on every record of the run and its base chain, the active library's witnesses, changed contexts; fenced records reported apart
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
that names another is shown the other's planned nodes and composes them by id). `--model <id>` pins
the Claude model of every planning, coding and judge session (unset, the CLI's default, which may
change between launches: pin it); `--model_prices` names the operator's price table (default
`config/model_prices.json`).

**Checkpoints and resume.** `results/<run>/state.json` is the run's one authority: after every
transition it is replaced atomically with the current iteration's progress (its stage, the outcome
of every concept and node decided so far, the records it carries from the iteration before, its
notes), the three ledgers, and the accepted and held records; the ledger and accepted files are
then written from it as projections, and a loop start completes them from it first. A loop started
on a run whose current iteration is short of `done` rolls back the sessions that were killed
mid-way (a task directory with no verdict), then resumes that iteration: its registration, repair
outcomes and integration are applied once, decided concepts and nodes keep their outcome (a saved
gate verdict is applied, not coded again), the rest are coded. `--max_iterations` counts iterations,
not launches: an unfinished iteration always resumes, and a new one is allocated only below the
bound. A resume takes the saved options for every option not given, and stops before rewriting
anything when the corpus, ontology, Core, prompts, base reading or base run differ from the saved
run. `--restart` discards the incomplete iteration instead, returning its planned laws to `open`.
One process owns the library at a time: the flock on `library/.run.lock`, whose file never changes,
with the owner's record (its nonce and its live child process groups) in the library's `.run.owner.json`,
replaced atomically. `init`, `split`, `reopen`, `verify` and `index` take it too, and so does a gate
run outside any session; a gate a coding session runs passes only under the owner that started the
session, on the same library. Every session and toolchain run has its own process group and carries
the owner's nonce and the library's path in its environment. A timeout ends the group. A new owner
refuses to start while a process of the previous one is alive, and `--force_takeover` ends them. A
process counts as the previous owner's only when its own environment carries that owner's nonce or
this library's path: a recorded process-group number is a hint, never a reason to end a group.
When the record cannot be read, a process carrying this library's path still blocks the takeover,
and one whose library cannot be told is named and never ended. No session may write these files,
and the gate's scope check ignores them. SIGTERM or SIGINT stops every launch and relaunch and ends every
child. The doctor runs at every loop start and refuses a run on a failure.

**Parallel coding.** `--workers N` codes up to N independent concepts, then N independent nodes, at
once, in dependency waves (a node is coded after every node it composes is accepted). Every gate
and skeleton build holds a library-wide lock while it regenerates the registries and builds, and
a gate registers only the accepted ids plus its own, so a half-written sibling never enters its
build; the scope check tolerates the files of the sessions coding beside it. A gate's evaluation,
and every Lean program of a review, runs after that lock is released, beside the others: each
imports Core and the modules of its own registry (those its gate registered) instead of the
generated one, which another gate may be rewriting, so one slow evaluation holds no other gate up.
They share an evaluation lock that only the isolated rerun of a resource failure takes alone.
Integration holds the library-wide lock throughout. `--plan_turns` caps a plan or
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
never an aggregate, a parameter, an assumption, a rule or a concept; its units must agree (Core's
dimension check, `DimCheck` in `Certificate.lean`, with the units of `Dimensions.lean`, generated
from the units ATOMS.md states). A Lean program
(`Certificate.record`, one `CERT` line per divergence it is given, run on each check and on each
submitted divergence) decodes the trace and the case strictly,
runs the trace check (`Core/Evidence/TraceLint.lean`: identity, a static map, valid geometry,
path length, heading against yaw rate — exact, no tolerance; the occupancy of an observed track
is not written by the reviewer but derived from its footprint and the boundaries, over closed
sets, before the check; a fresh hand-written trace holding a key the decoder does not read is refused,
naming the key; a relation Core can compute from the scene is never supplied: a fresh trace
that supplies one is refused, and a saved trace replayed later has it stripped and the case
certified again, invalid when it rested on the supplied value), the witness check, the case check and the case at `at`, and then the rule's verdict at
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
submitted no usable answer, or whose answer cannot be evaluated, defers the review at stage
`reviewer` unless an item of the other pass is upheld; its items are kept as evidence, never
truncated. A single session misses a real defect about one time in five, whatever its effort, so a
second sample is what lowers the miss rate. A concept is reviewed by one session.

`--review_checks` (8) and `--review_submissions` (3) are counted apart, so a submission is always
possible once the checks are spent; a session may make up to four requests more than its checks and
submissions, for answers that call no tool. A divergence is run once per session (a divergence with
a schema defect is not run at all): the rule, the concepts and the reading do not change while the
session runs. Each launch keeps its evidence in its own directories (`review/checks/L<launch>/`,
`review/submissions/L<launch>/`). Each request is reserved and recorded on its own
(`<label>:<subject>:L<launch>.r<n>` in `usage.jsonl`; the judges' rows also carry the node), and the
session has one deadline, `--session_timeout`. A request the API refuses or fails relaunches the
whole session, as for any session, with no retry inside the request (the first relaunch after the
API failed a request, a 5xx, a timeout or a lost answer, comes after a minute); the API's reason, sanitized,
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
the exact request a judge was sent.

**Duties, rulings and obligations.** A *duty* is an occurrence of words in the law (its span
offsets and the law's content digest), not a node id: stage A is shown which occurrence it judges,
the sentence around it and the duties judged separately. A case is identified by its facts: the
law's content, the trace, the canonical case and entities (every name renamed in order of appearance,
in scope: a quantifier's variable, a window's vehicle and a rule map's names as well as each `var`),
the instant `at` and the grounding; a case carried to a later record keeps its lineage. Every certified case is kept in
`results/<run>/rulings.jsonl` (append-only; a ruling is identified by its case and duty, or by its
structural finding, and a re-judgment appends a row that supersedes the previous one). An upheld
case is an obligation of its duty. Before the reviewer is asked about a later rule of the node,
every obligation of the duty, and every upheld case of an earlier duty whose words overlap it (a
candidate), is admitted again by the standard fresh evidence meets (`admission`) and judged again
where a judge's input changed: a case that is no longer valid (it does not decode, fails a check or
is not true) leaves, with a note to the operator; one whose evidence no longer suffices (a look-back
it does not cover where the rule's history is bounded, a sampling gap, an absent observation, road
users the binders do not correspond to) stays, and the reviewer is shown it under *Cases to extend*
(a divergence that `extends` it; the harness accepts it as the same case only when its trace keeps
every old scene and field, its binders keep their tracks, its instant is the same and it states
every old fact, and the review defers at stage `evidence` when no such extension comes back); one still upheld returns the node without a review; one the rule now meets stays as a
`satisfied` obligation. Stage B is shown the earlier rulings on the same duty, a snapshot without
the case's own lineage, and decides a situation they decided the same way unless the record changed
on the point they turned on. A *structural evidence* item (the law's verbatim words and the clause of
a broader contract the record carries for them, where no contract makes the distinction, so no trace
can show it) is judged by stage B on the words and the contracts alone, labelled as such in the
rulings and in what the planner sees; upheld, it is an obligation decided again on every later
record. A case's streak counts consecutive reviews in which it stays upheld (keyed by its lineage,
or by the finding) and resets when it is satisfied; `--repeat_limit` consecutive counts block the law
for the operator. The plan and node repair sessions are shown these cases as regression
obligations, never as mapping instructions. An operator who finds a ruling wrongly upheld sets its
`ruling` to `retired`. The reviews of a coding wave run in parallel, and their outcomes are applied
once all have finished. `--review_effort` (high) sets the reviewer's reasoning effort.

**The concept review.** A concept the gate accepts is reviewed the way a rule is: the second vendor
(`prompts/review_concept.md`) reads the contract, the record with the coder's readings, and the body
rendered as prose, and writes every situation in which the body decides differently from the
contract as a trace with an instance (a spelling for each literal formal, a value for each
parameter, a value for each `nat` formal, a track for each track formal) and the observation `at`
the verdict is read at; the harness runs the concept on it as a rule (`Concept.asRule`), so a
divergence counts only where the body's executed verdict at `at` differs from the contract's. The reviewer runs each divergence first with `run_instance`, and submits with
`submit_review`, under the same counts as the rule review. One on which the body gives the
contract's verdict is an advisory, and a challenge that still cannot be run
(a schema defect, a trace that does not decode, an incomplete trace) defers the concept at stage
`reviewer` unless an item is upheld. The record shown names the literal formals the instance fills
(none: `instance.literals` is `{}`). A concept of kind `quantity` returns a value: its divergence
states the interval the contract's words put the value in (`contract_value`, `lo` and `hi` with
their units, of the value's dimension as inferred from the body), which the harness passes as the
instance's `bounds`, so the value outside the interval confirms it, as a quantity's witnesses are
checked; the value the body computes at `at` is shown beside the interval. A parameter value outside
the domain its meaning states is an advisory. Every ruling on a concept is kept with its instance, so
before a later version of the concept is reviewed its upheld items are run on it again (each formal
matched by its type), each from its effective row. A challenge decided under the current contract
(the same `contract_digest`) is satisfied where the body gives its claim and goes to the adjudicator
where it does not. One decided under another contract, or recorded without a digest, is rechecked
(`prompts/recheck_concept.md`): shown only the current contract, the contracts of the names its
words use, the parameters with their values and the executed facts, never the body or the recorded
claim, it answers what the contract decides there (`holds`, `fails`, an interval for a quantity, or
`undecided`). The body within the answer satisfies the challenge (under a new id, with `lineage` the
old case, when the answer is not the recorded claim). A body outside it sends the case, renewed under
the current contract (the answer as its claim, the recheck's quote as its words), to the concept
adjudicator in the same review. `undecided` becomes the challenge's claim: it is carried to the
reviewer, never compared; the answer may say whether the facts it turns on are missing or the contract
does not decide (`undecided_by`), and the review's outcome counts the two apart. What the recheck
records carries the current digest, so the challenge is not rechecked until the contract changes
again. A challenge that cannot be run on the new version
(its formals, its trace, its history, a unit or its grounding) is shown to the reviewer under
*Challenges to carry over*, as is one whose claim is `undecided`. An extension of it must keep its
trace, each old formal's value and its claim (unless the claim is `undecided`), and its contract words
unless they are no longer verbatim in the contract (new words or a new claim make a new case id with
lineage), and the review defers at stage `evidence` until one comes. Each confirmed divergence, and each valid `not_general` item
(words of the contract or the body tuned to one use), goes to the concept adjudicator (`prompts/adjudicate_concept.md`), with the
executed facts rendered from the trace (`render_formula.trace_facts`, keys the decoder reads only; a
saved trace's other keys are listed apart as unverified annotations) apart from the reviewer's prose.
It rules by the contract's words and by its own earlier rulings on the concept, and an upheld item
returns the concept to concept repair. An upheld `not_general` item is a structural obligation
(`concept_structural/1`), decided again before every later review of the concept's lineage. The
dismissed items and the reviewer's advisories are recorded on the accepted concept and shown in the
catalogue beside its contract. The reviews of a concept wave run in parallel. A concept that has
failed in a run stays failed: a plan that names it again is returned
and charged, and only `reopen` of the laws that used it clears it.

**A defect of a concept found by its caller.** A coder (of a node or a concept), or a node repair
withdrawing with kind `concept`, that finds an accepted concept it reaches computing what that
concept's contract excludes writes `dependency_defect.json`: a concept divergence. The harness
checks its form and that the task reaches the concept, runs the concept on it, and sends a
disagreement to the concept adjudicator. Upheld, the concept version is fenced in the run's state
(`fenced`, reason `dependency_defect`: no new record may call it, and a later version is not
fenced), its accepted callers are
listed in `TO_USER.md` with the subset command that re-runs their laws, a reporting node's law
returns to the planner to supersede the concept or map around it, and a reporting concept waits for
the successor. A report that is malformed, names a concept the task does not reach, or shows no
disagreement is noted, and the task's own outcome stands (a repair that withdrew on it returns its
law).

**Dependency contexts.** Each accepted record keeps the version of what it was judged with, built
from:
- the record itself;
- its files;
- the concepts it reaches and the nodes it composes, with their versions and fences;
- its reading values with their units and their reviewed or proposed status;
- its aggregates;
- Core, the ontology and the review configuration.

A coding task stores the version its gate ran on, and a saved verdict is reused only when the
version is unchanged. Before integration, a record whose context changed has all its obligations
certified again; one that fails is fenced (reason `context`), and so is every record that calls it.

**Fences and the active library.** A fenced record (`state.json`, `fenced`: its reason, evidence,
the record version it fenced and the run that accepted that version) stays visible to the planner,
as a repair subject, but is out of the operational library: the library's `.inactive.json`,
rewritten at loop start and whenever a fence changes, keeps it out of every registry build. A fence
applies only while that version is the effective record. A replacement accepted under the same id
is active, and the old fence moves to `fence_history`.

At loop start, before any session, the run:
1. restores its base chain's aggregate admissions;
2. holds each inherited and accepted record to today's gates (the admission recheck). Verdicts are
   cached in `admission.json` under what each rests on: the record's context and the gate's
   implementation. A record the run's own gate accepted is entered there when it is accepted, so it
   is gated again only when something its verdict rests on changes;
3. checks every record whose context is new or changed against its obligations.

Each admission gate registers only its subject and the records it needs, so an unrelated broken
file cannot stop another record's check. Each record is checked against its own law, from whichever
corpus of the chain holds it. A check that cannot be made because the toolchain does not run stops
the run before any spend. An accepted record whose evaluation exceeds the gate's deadline, or panics
in isolation (named as a Core defect), is not judged: it stays as accepted, with a notice, and is
checked again at the next launch. Notices found
at start are kept in the snapshot until `TO_USER.md` receives them.
- **A failure is fenced** (reason `gate`), and so is every record that calls it (reason
  `dependency`).
- **A kept node that is fenced or calls a fenced record** (one whose law the subset does not list)
  stops the run before any spend, with the exact `scripts/subset_laws` command that adds its law.
- **A successor of a fenced version** keeps its contract and needs no counterexample: the fence
  stands for it. The gate's duplicate check leaves fenced versions out.
- **A pending candidate that uses a fenced record** is not coded, or is held at integration. Its law
  returns to the planner, uncharged.

Plan validation returns a node or concept record that claims a region's property (an atom of regions only, other than a region kind) without claiming the kind of region it is read on; how the region is tied to the road user is the formula's, checked at the gate (`UNANCHORED_VARIABLE`). Validator A returns a concept
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
`SCOPE_VIOLATION`, the node is rolled back and the stray files are named in `results/<run>/TO_USER.md`,
with the task's `baseline.json`, which holds each library file's digest before the session: only
those files are restored, never the whole tree.

**One library per run.** `library/` holds the rules and concepts of exactly one run (and its base
chain), because `index_sync` registers every file on disk that `.inactive.json` does not exclude. At start (`loop.check_library_isolation`)
a node or concept on disk that neither the run nor its `--base_run` accepted is moved into the
snapshot of the run that accepted it, the base run tried first, never over an archived copy (else
into a dated `results/library_strays_*`); one they accepted that is missing is restored from the
run's snapshot, and the run refuses to start only when it cannot be.

**Subset runs.** A development run that reruns part of a corpus (see `CLAUDE.md`, Development
runs) takes its laws from `python -m scripts.subset_laws <run> <corpus laws.jsonl> <law id>…`,
which writes `results/<run>/laws/laws.jsonl` and the `definitions.jsonl` beside it, and is launched
with `--base_run <previous run>`. The base is the whole chain of base runs, each generation's
listed laws excluded from its ancestors' records before its own acceptances are added; fences are
inherited along it. A base node whose law the subset lists is not reused: the law is planned again.
A base node that composes such a node stops the run until its law is listed too. The upheld
obligations of an inherited record are read, read-only, from the run that holds them (with ids
qualified by that run); no ruling of a law the subset re-plans carries over.
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
cap a session; `--session_retries` (2) is each task's operational retry budget within one loop
launch: at most `session_retries + 1` launches per task, counted from the launch records kept in its
directory, each recorded before its call starts; a new loop launch grants a fresh allowance. The
relaunches are of a session the account or the API refused (a usage limit, an API error, a
timeout with no answer), made `--retry_wait` (900 s) apart for the limit or the outage to clear (the
first relaunch of a reviewer session whose request the API failed comes after a minute), and of a
coding session cut off by its turn cap, budget or timeout, relaunched at once: its files keep the
candidate the cut-off launch left, its prompt says so with the verdict of that launch's last gate
run (`last_gate.json`; the note is kept as `relaunch_note.md`), and it may run the gate at least
half of `--gate_budget` again. A
session the account refused holds its task, uncharged, once its relaunches are spent, and the loop
stops after the iteration. A coding session that ran and was cut off at every launch is no outage:
its task is judged by the harness's own gate on what the last launch left (a candidate too slow
to evaluate is `GATE_TIMEOUT`), and the run goes on. A plan session cut off before it wrote a law's node returns
that law once uncharged. A request the API rejects as such (400, 404, 422) is a harness defect,
reported and never sent again until the effective request (its input, model, tools, effort and
output cap) changes. `--plan_batch` (8) is the most laws one plan
session is given; `--workers` (1) the coding sessions run at once;
`--plan_turns` (80) the turn cap of a plan or repair session; `--restart` discards an interrupted
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
   segmentation and, read-only, the law's other nodes in the records it is validated with, their
   states, and the nodes the records compose. Each writes a revised record or a withdrawal naming the missing atom or operator;
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
   not propose an atom the ontology has, nor an operator gap an operator the language has. A law
   planned again is shown every node of its latest plan, those never coded included, with each later
   repaired or coded version, its state (the validator's, the gate's and the review's verdicts,
   accepted or not) and the nodes it composes, each matched by the occurrence of its duty in the
   law, never by its id's ordinal; these records are context, not authority. A condition that refers
   to words stated elsewhere may change its representation (a composition, a concept, the fact in
   full), never its referent or the qualifications its words retain. Writes
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
   builders, world records, units), the ontology contracts of what the record claims and of the
   atoms its claimed primitives and concepts read (the contracts its reviewer judges by), the
   reading's values for the node's parameters and the most recently accepted node as the worked
   example. A concept's session gets the same contracts for what its elements map to. Writes the formulas and the scenes, runs the gate,
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
   for a decision with the `reopen` command, every law that failed in the iteration with its
   reason, scope violations, sessions that did not run); each decision is listed once however often
   it was raised. `summary.json` counts the gaps this run filed and the ledger's total; a gap is one
   occurrence of words in a law, so the same words filed again are the same gap.

**The gate** (`harness/checks/gate.py`) returns one verdict on the coder's files: `SCOPE_VIOLATION`,
`BUILD_FAIL`, `UNSOUND` (sorry, axioms, unsafe constructs, and the commands that run code while the
file is elaborated: `#eval`, `run_cmd`, `initialize`, `elab` — scanned in code only, never in the header comment or the
operationalization strings that carry the law's words), `CHECK_FAIL` (`Rule.check`, which also
rejects a number in an entity position, `Rule.checkReading`, which holds every aggregate id
a rule names to the run's admitted aggregates, Core's dimension check of every comparison and call,
no cosine tolerance outside [-1, 1], and no division by a term that reads a measurement, which can be
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
literal for a parameter that is no figure the record declares in the unit the concept declares — a
literal zero included; the units of what a call passes are the dimension check's), `WITNESS_FAIL` (a planned scenario
has no witness, a verdict differs from the planned one, `idle` grounds a binder to a track that never appears, `blind` is unknown for
anything but its masked atoms, or its manifest masks something other than the node's `masked`; a measured relation a witness
supplies that Core, computing it from the same scene, contradicts; a window holding no observation),
`VACUOUS` (a leaf no decided witness exercises; `blind` does not count), `GATE_TIMEOUT` (the harness
ran out of time evaluating the formulas, the details giving the part it was stopped in, the witnesses
that passed, did not pass or never ran with their times, and for the adequacy check its size, or a
resource failure or a panic recurred in isolation), `OK`;
a session that spends its gate runs ends `BUDGET_EXHAUSTED`. A `GATE_TIMEOUT` judges the evaluation,
not the mapping: it never accepts and never counts a plan, node or concept attempt. The record is held,
and the next iteration gates its saved candidate again, without a session, at the same deadline (the
gate harness's 900 s) when the candidate's context (the record, what it calls and composes, the
reading values it reads, Core, the ontology, the gate's implementation) is unchanged, or codes it again
when that changed. A second one holds it for the operator; a panic holds it at once as a Core defect.
A held node blocks its law on `decision:<law>`; a held concept blocks every law whose nodes reach it,
directly or through other concepts, and is not coded again, nor are the concepts that call it, while
it is held. The candidate (`final/`), the gate harness, the reading and the harness's output stay in
the task directory as the evidence, and `summary.json` (`gate_costs`) and `TO_USER.md` count them
apart. `TO_USER.md` names the one `reopen` command for every law a hold paused (a law already blocked
or failed for another reason is not paused, and never keeps the hold); a held concept's counts are
released once none of the laws it paused is still paused, whether they are reopened together or one at
a time, and a `reopen` that leaves it held names the laws it still waits on. A law reopened by a gap
decision starts its counts again as after `reopen`, and releases a concept by the same rule. An
error the build or the harness locates in the candidate's files, or on a line of a generated
registry or harness that names the candidate's declarations, is the candidate's (`BUILD_FAIL`). A
located error elsewhere, a failure with no located error, a missing toolchain, a deadline before
evaluation or the run's stop is `INFRA`, which names no candidate verdict: the law is deferred
without an attempt and the loop stops after the iteration. A resource failure or a panic is run
once more in isolation, and is the candidate's `GATE_TIMEOUT` only when it recurs.
The gate harness runs in two phases of one program. The first evaluates everything up to and
including the witnesses (for a concept, its supersession check too); the gate then runs every check
that comes before adequacy on that output, in the order and with the verdicts above, and only when
none rejects does the second phase run the adequacy check, the costliest part. Both phases share the
900 s: the second has what the first left. When the first phase is stopped at the deadline, the same
checks run on the rows it printed: a row that already decides a rejection gives that verdict (a
witness that never ran is named and never counted as passed); only when none does is the verdict
`GATE_TIMEOUT`, as it is for a stop in the second phase. Every toolchain call of a gate is recorded in the
task's `toolchain.jsonl`, with its wall time and how long each lock was waited for and held; the
gate harness also prints a `TIME` line per part of its evaluation (the rule checks, the trace lint,
each witness scenario, the witnesses in all, the adequacy check's start and its end), flushed as it
is printed, so a run stopped at its deadline keeps the lines before it. Integration records its build and witness run
the same way.
The witnesses are the node's tests, written by the same session as the rule from the planner's
narratives; they show the formulas are executable and reach every verdict, and never stand as
evidence that the rule says what the law says — that is the review's job.

**Budget and run status.** Every session of either vendor appends a row to `results/<run>/usage.jsonl`
(tokens, reasoning tokens, cost; OpenAI costs from the operator's `config/model_prices.json`, keyed
by the model name the run requests; a name without a price launches no call).
`--openai_budget_usd` limits the second vendor's calls run-wide: each call's worst case (its input
estimated at three characters a token) is reserved and written as a `pending` row before it is
sent. A request's rows fold into one state:
- **`settled`:** its actual cost, idempotent.
- **`unknown`:** a request that may have run (a timeout after sending, a dropped connection, an
  ambiguous server error, a response without usage), kept at its reservation.
- **Never sent:** a request refused before execution, settled at zero.

A pending request the process did not settle counts at its reservation. A call that does not fit pauses the run (`paused_budget`), resumed under
the same run id once the limit is raised. A reviewer's tool session makes several requests, each
reserved at its whole input (the prompt and everything sent back) and the output limit, and settled
as it returns. `--reviewer_max_output_tokens` (64000) bounds each OpenAI request, reasoning
included; `--max_divergences` (3) bounds each review answer. A run continues while any repairable
work has budget left; the attempt budgets, the case streaks and `--max_iterations` bound it. A run ends `complete`,
`incomplete`, `infrastructure_failure` (a session, the toolchain or the validator itself did not
run; uncharged, resumable; a validator fault leaves `validator_fault.txt`), `paused_budget`,
`protocol_failure` (the aggregate selection stayed defective for the same pair twice),
`stale_aggregate` (an aggregate's inputs
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
(`aggregate_certificates.jsonl`). A selection still defective after its re-ask holds the laws that
use the pair for the iteration, uncharged, and is asked again next iteration; a verifier answer that
stays malformed admits nothing and is verified again, like a session that did not run. The admitted aggregate enters the run's reading under its id,
`<definition id>::<term>`; a plan claims `ru.aggregate=<id>` and never expands it, and writes a
law-local aggregate (`<law id>:<span>::<term>`) only where its clause defines its own members; its
admission is bound to the record, and the draft validator treats the draft's own well-formed ones as pending.

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
composed node is not accepted yet is held in the run's state and coded in a
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
outcome drawn `--repeat_limit` times in a row across a law's plans and repairs (one upheld case,
followed by its lineage, or one upheld structural finding, counted once per review and reset when
the case is satisfied) blocks the law on `decision:<law>`
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
