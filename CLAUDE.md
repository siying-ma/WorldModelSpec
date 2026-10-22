# CLAUDE.md

Guidance for Claude Code in this repository. The working pipeline is
`pipeline/traffic-spec-agent/` (see its `README.md`); its design documents are under
`pipeline/DesignFile/` (`PIPELINE_V2_DESIGN.md` for the loop, `CORE_V2_FILES.md` for the Lean
library). The CARLA-first generation of this project lives on the branch
`archive/carla-first-2026-09-15`; nothing on `main` depends on it.

## Working agreement

**The repository is incomplete by design and updated continuously.** Only the artifacts named
frozen below are finished; elsewhere a missing piece is work not yet done, not a decision taken.

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

Before changing anything, in this order:

1. **State the plan first.** Name every file you intend to touch and the change, and for each
   addition say in one sentence why the pipeline cannot do without it and which existing part, if
   any, it replaces.
2. **Separate what exists from what does not** (implemented, partial, absent), naming files.
3. **Make the suggestion concrete**: the file, the function, and every artifact that must change
   with it — a Core change drags the generated tables, the prompts, the doctor and the tests.
4. **Only then edit**, and report what landed against the plan.

**Reporting a finding.** A defect found by a check, an audit or a run is reported to the operator
under three headings, in this order:

1. **Is it sound, and does it matter for the library's quality?** Whether the defect is real
   (verified on the code or the recorded run, not inferred), and what it costs the accepted rules:
   wrong rules accepted, sound rules lost, or only run cost.
2. **A simple example.** The smallest concrete case that shows the cause and its result.
3. **The recommended solution.** The change and where it lies (frozen or not), why it removes
   the cause for every law, and how it is checked offline before a run depends on it.

## Who does what

Each agent of the loop has one responsibility, and a defect is routed back to the role that owns
it, never fixed by the role that found it. Every role, phase and check exists for one stated use: a
feature is not better for being there, and one whose use cannot be stated is removed.

- **The planner** (the plan session, and the node and concept repair sessions, which re-plan)
  decides everything a rule or a concept means: the segmentation, which atoms, concepts and
  operators each span maps to, the readings of open words, the occasion of an act, the parameters
  it proposes, and every concept's contract. Only a planning session changes a mapping or a
  contract. It decides law-local readings, and derives aggregate membership from posted
  definitions: an aggregate denotes an extensional set of tracked road-user classes, not a
  relational role such as who controls a vehicle; for an aggregate it classifies every road-user
  class of the active ontology split as included, excluded or unresolved, quoting the controlling
  definition words, and marks a class unresolved where those words do not decide it. Only a
  planning session proposes that mapping.
- **The coder** (a node or a concept coding session) writes the Lean the record states. Where the
  record leaves the writing open it may choose only among meanings the words already allow, and
  discloses each choice as a `reading`. A span it cannot write with the planned atoms and operators
  it reports (`no_atom`, `no_operator`) and stops; it never approximates, re-maps or plans.
- **The reviewer** (a second vendor's model) shows, as executable traces, situations in which the
  code and the words it formalizes (the law for a node, the contract for a concept) decide
  differently. It supplies certified cases that challenge a rule or a disclosed reading. It
  proposes neither a fix nor a replacement mapping. The one exception to traces is **structural
  evidence**: where no trace can show a difference (a word carried by a contract broader than it,
  with no contract that makes the distinction), the reviewer may file a word-level item naming the
  law's verbatim words and the contract clause they contradict. Stage B judges it on the words and
  the contracts alone; it is labelled structural evidence in the rulings and in what the planner
  sees, its words are validated against the law, an upheld item is an obligation decided again on
  every later record of the node, and it is identified by the occurrence of its words in the law.
- **The judges.**
  - **Stage A** determines the law's verdict on the canonical case without seeing the rule, the
    record, the reviewer's prose or any proposed repair. It judges the duty occurrence the node
    formalizes, and sees which occurrence that is (its words and qualifying sentence, and the duties
    judged separately), nothing else of the record. It is shown the posted definitions that apply,
    never an aggregate mapping.
  - **Stage B** decides whether a confirmed mismatch:
    - is a formalization defect;
    - is permitted by a disclosed law-local reading;
    - follows an aggregate mapping admitted by the independent aggregate gate;
    - depends on an operator-owned parameter value;
    - or is structural: a structural mismatch is reported `upheld`.

    It never chooses a reading, an aggregate member or a parameter value, and never judges the
    code or re-plans.
- **The harness** validates, gates, executes and routes each outcome to the role that owns it; it
  decides nothing a role above decides. Before any node may use an aggregate, it validates the
  aggregate's provenance, completeness and representation and obtains an independent semantic
  verification of every decided classification. It decides no membership itself: a classification
  the gate cannot verify is downgraded to `unresolved`, never changed to included or excluded. An
  unrepresentable member is filed as a gap for the operator.
- **The operator** decides gaps, the values of parameters, and the corpus's definition precedence
  (which posted definition governs a law: its own section's or chapter's, then its code's general
  chapter, then a fallback code), declared once in `pipeline/traffic-spec-agent/config/` and never
  by the harness or the planner. An aggregate mapping that cannot
  faithfully represent a posted definition becomes a gap for the operator; the operator does not
  otherwise choose or override the membership of a legally defined aggregate.

## What is frozen, and what that means

- `ontology/ATOMS.md` (and the derived `ATOMS_train.md`), `library/TrafficSpec/Core/**`, and
  `prompts/*.md` are fixed before the pipeline sees a law. They carry no statutory text, no law
  id, no rule named by its subject, no worked value, no threshold. `python -m harness doctor`
  enforces this; extend its patterns rather than arguing an exception.
- The corpus under `laws/**` is posted law only: `id`, `title`, `text`, `source`. Every analysis
  field (tier, theme, references, overlap decisions) lives in `laws/audit_and_scripts/` sidecars.
  The one exception to verbatim text is a scope edit the operator decides: words naming an item
  outside the scope are removed by the generator from
  `pipeline/ontology_provenance/nrs_tools/tiers.py` (`SCOPE_EDITS`), recorded as `scope_edit` in
  the sidecar and listed in `laws/README.md` (Laws changed for the scope). Never edit a corpus
  line by hand.
- The reading (`library/TrafficSpec/Readings/<run>.json`) is the only place a number the statute did not state may
  appear. A rule names parameters; it never carries a value. A parameter the reading lacks is
  proposed by the plan (`param_proposals`: name, unit, a provisional value, its convention and
  source) and the harness enters it in the reading marked `proposed`, where it stays until the
  operator reviews it; the doctor lists every unreviewed proposal, and `init --fresh` archives
  the unreviewed ones with the run's library, so a new run is never guided by the last run's
  guesses. A figure the statute states is
  declared on its span in the blueprint and written through a `Units` constructor.
- The Core directory holds either the full or the training variant of the split files
  (`library/splits/ACTIVE`); swap with `python -m harness split --use train|full`, never by hand.
  Edit Core only while `full` is active, then switch back: the switch re-archives and
  regenerates, and the doctor's `core matches split` check catches an edit made under `train`.
- The test split (`laws/example/test/`: its laws and definitions) is held out from development:
  a development session does not read it, and never shapes a prompt, an ontology rule or Core
  around a test law. The held-out atoms' rows of `ontology/ATOMS.md` are
  frozen in `laws/audit_and_scripts/split_atoms.json` and the doctor fails when one changes; they
  change only by regenerating the split. The harness defaults to the training split.
  The driving data a run is evaluated on (`pipeline/datasets/**`, read only by
  `pipeline/evaluation/` after a run) is test data in the same sense: no pipeline session reads
  it, and no change to the prompts, the ontology, Core or the harness is made because of what a
  dataset contains or lacks. A defect an evaluation reveals is fixed where it lies: in the adapter
  when the trace misreports the scene, in the pipeline only when the defect holds whatever the
  data.
- Everything that evaluates a run lives in `pipeline/evaluation/`, outside the pipeline: the
  scripts that run the monitor on driving data, and `evaluation_scenario/`, the instruction set for
  the developers of the adapter (what a trace must show before each law can be judged). Nothing in
  the pipeline reads `pipeline/evaluation/`. Development sessions of the pipeline do not read or
  edit `evaluation_scenario/`, with two exceptions: its `README.md` and its `adapter/` folder (the
  trace format and the adapter's contract), which a development session may read and edit when a
  change to Core or the ontology changes what a trace carries, and where the changes the pipeline
  requires of the adapter are recorded.
- The corpus covers ordinary urban Las Vegas driving, judged for a vehicle driver. A law leaves
  only by the rule in `laws/README.md` (Scope), recorded in
  `pipeline/ontology_provenance/nrs_tools/tiers.py` (`EXCLUDED`);
  the corpus before the scope is that of commit `300f115`.
- Legal aggregate words ("vehicle", "traffic") are the atom `ru.aggregate`. Its argument is a
  definition-scoped aggregate id, `<definition id>::<term>`, or `<law id>:<span>::<term>` for a
  genuinely law-local definition. A rule never expands a word into classes.
  - **Membership is derived from the posted corpus definition** that applies to the law, resolved
    from the posted corpus by the operator's declared definition precedence, never from the audit
    sidecars under `laws/audit_and_scripts/`.
    It is never invented by a rule, never freely overridden in the reading, and never chosen by the
    planner among competing definitions.
    A defined term used inside that definition is resolved mechanically by the same precedence
    from the definition's own place; its posted definition joins the mapping evidence and digest.
  - **Every class is classified.** Every road-user class of the active ontology split is included,
    excluded or unresolved, quoting the deciding definition words.
  - **Digests.** The accepted mapping records its definition and ontology digests. A change to
    either invalidates the mapping and every affected review, including the witnesses of accepted
    nodes that reference it.
  - **Context is not membership.** A contextual condition that a class list cannot express is not
    discarded: it becomes a predicate the rule or a concept carries, an unresolved classification,
    or a gap.
- A node is two files, `Rules/<Body>/<NodeId>.lean` and `TrafficSpecWitness/<Body>/<NodeId>.lean`,
  with the node id derived from the law id. Acceptance is the harness's own gate call, never an
  agent's claim.

## Development runs

To save budget, a restart between full runs reruns only a subset, until the pipeline issues it
exposes are fixed:
- **Which laws.** The laws the previous run did not accept (failed, blocked, returned or still
  planned), plus every accepted law whose node an audit found defective. The review missed those
  defects, so they are how a change to the review is measured.
- **When the subset is most of the corpus.** When the laws to rerun, with the nodes that compose a
  defective accepted node, cover most of the corpus, the restart is a fresh full run.
- **How.** Launch the run with `--base_run <previous run>`: its accepted nodes and concepts are
  reused read-only, and the library keeps that run's files, so there is no `init --fresh`. A new
  run id starts a new `rulings.jsonl`. No ruling of a law the subset re-plans carries over; the
  upheld obligations of a record the run inherits are carried, read-only.
- **The subset files.** Its `laws.jsonl`, with the `definitions.jsonl` beside it, is written by a
  script from the corpus file into `results/<run>/laws/`, never by hand and never under `laws/`.
- **After a change to Core or the ontology.** `python -m harness verify` must pass on the base
  run's nodes; a node that no longer builds or passes its witnesses joins the subset.
- **Full runs.** Acceptance counts of subset runs are not comparable between runs. A full fresh
  run is made before any figure is reported and before the test split is run.
- **Before a bigger corpus, minimize the returns to fix the pipeline.** Moving from a smoke to the
  demo or the training split multiplies the cost of every pipeline defect. A defect found mid-run
  that needs a change to Core, a prompt or the harness means relaunching the whole corpus. Every
  fix made before such a run:
  - removes the cause for every law, not only for the case that exposed it;
  - is checked offline on the sessions already recorded (saved reviewer answers re-certified,
    saved prompts replayed against a new model) before a run depends on it.

  A smoke is run on the changed pipeline before the larger run is launched.

## Editing Lean files

- Change the code, and a doc comment only when the contract it states changes. Never write a
  history of past defects, a rationale block or a "previously …" note into a `.lean` file: that
  belongs in the commit message or `pipeline/DesignFile/CORE_V2_FILES.md`. `Core/**` is read by
  the plan and code agents; keep every file short, organized and tidy.

## Documents and comments

- A header or comment in a `.lean` or `.py` file never cites a markdown file or a section of one:
  it states the contract the code implements, in full, in its own words.
- The documents under `pipeline/DesignFile/` are local and unversioned; the history of a defect
  and its fix goes to the commit message.
- A design or audit document under `pipeline/DesignFile/` is written for a reviewer who reads it
  alone: every fact it relies on (what a check does, what a rule requires, what a phase is shown)
  is stated in the document, never delegated to another document or a section number. Code
  locations (`path:line`) are the only cross-references.

## Never

- Special-case a law in Core, the ontology, the prompts, the harness or the doctor.
- Approximate a span the ontology cannot carry with a neighbouring atom: file a gap. The one
  exception is a word with no observable counterpart (an intention, a perception or a knowledge,
  a purpose, the legal status of a feature on the road, who or what controls a vehicle): it is read through the conduct or the
  feature it refers to and disclosed as an `observable_reading` narrowing (`ontology/ATOMS.md`,
  the section on what is not an atom), because the rules exist to check conduct on traces.
- Decompose below an obligation span, or re-plan a law the ledger has closed.
- Copy from the archived prototype; borrow ideas, cite nothing from it.

## Commands

From `pipeline/traffic-spec-agent/`: `python -m harness init | doctor | loop | validate | gate |
surface | verify | index | status | reopen | gap | split | score_split` (see `README.md`). Run `lake` only inside `library/`.
Regenerate the ontology's Lean files with `python -m scripts.gen_ontology`; regenerate the
corpus and its split from `pipeline/ontology_provenance/nrs_tools/` (`make_laws`, `publish`,
`split`, `atoms_train`), never by hand.

## Lean library

`library/TrafficSpec/Core/**` is the frozen Core; tests in `library/TrafficSpec/Tests/*.lean` run
at build time (`lake build`) and pin the arithmetic and semantics with `#guard`. Rules import
`TrafficSpec.Core.Language.Rule` only; evaluation, checking and grounding are in files no rule may import.
`Index.lean` and `TrafficSpecWitness.lean` are generated.

## Driving data

The CARLA dataset is built top-down and problem-driven: its scenarios are designed from the laws
the pipeline formalizes, not collected and then matched to laws, and they are added gradually
until the dataset covers most of the corpus. `pipeline/datasets/carla_new/` is its first part.
Other sources (nuPlan, filtered SAVeD) are added the same way.
