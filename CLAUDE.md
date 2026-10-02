# CLAUDE.md

Guidance for Claude Code in this repository. The working pipeline is
`pipeline/traffic-spec-agent/` (see its `README.md`); its design documents are under
`pipeline/DesignFile/` (`PIPELINE_V2_DESIGN.md` for the loop, `CORE_V2_FILES.md` for the Lean
library). The CARLA-first generation of this project lives on the branch
`archive/carla-first-2026-09-15`; nothing on `main` depends on it.

## Working agreement

**The repository is incomplete by design and updated continuously.** Only the artifacts named
frozen below are finished; elsewhere a missing piece is work not yet done, not a decision taken.

Before changing anything, in this order:

1. **State the plan first.** Name every file you intend to touch and the change.
2. **Separate what exists from what does not** (implemented, partial, absent), naming files.
3. **Make the suggestion concrete**: the file, the function, and every artifact that must change
   with it — a Core change drags the generated tables, the prompts, the doctor and the tests.
4. **Only then edit**, and report what landed against the plan.

## What is frozen, and what that means

- `ontology/ATOMS.md` (and the derived `ATOMS_train.md`), `library/TrafficSpec/Core/**`, and
  `prompts/*.md` are fixed before the pipeline sees a law. They carry no statutory text, no law
  id, no rule named by its subject, no worked value, no threshold. `python -m harness doctor`
  enforces this; extend its patterns rather than arguing an exception.
- The corpus under `laws/**` is posted law only: `id`, `title`, `text`, `source`. Every analysis
  field (tier, theme, references, overlap decisions) lives in `laws/audit_and_scripts/` sidecars.
- The reading (`readings/<run>.json`) is the only place a number the statute did not state may
  appear. A rule names parameters; it never carries a value. A parameter the reading lacks is
  proposed by the plan (`param_proposals`: name, unit, a provisional value, its convention and
  source) and the harness enters it in the reading marked `proposed`, where it stays until the
  operator reviews it; the doctor lists every unreviewed proposal. A figure the statute states is
  declared on its span in the blueprint and written through a `Units` constructor.
- The Core directory holds either the full or the training variant of the split files
  (`library/splits/ACTIVE`); swap with `python -m harness split --use train|full`, never by hand.
  Edit Core only while `full` is active, then switch back: the switch re-archives and
  regenerates, and the doctor's `core matches split` check catches an edit made under `train`.
- Legal aggregate words ("vehicle", "traffic") are the atom `ru.aggregate` with the word as its
  argument; the reading declares membership. A rule never expands a word into classes.
- A node is two files, `Rules/<Body>/<NodeId>.lean` and `TrafficSpecWitness/<Body>/<NodeId>.lean`,
  with the node id derived from the law id. Acceptance is the harness's own gate call, never an
  agent's claim.

## Editing Lean files

- Change the code, and a doc comment only when the contract it states changes. Never write a
  history of past defects, a rationale block or a "previously …" note into a `.lean` file: that
  belongs in the commit message or `pipeline/DesignFile/CORE_V2_FILES.md`. `Core/**` is read by
  the plan and code agents; keep every file short, organized and tidy.

## Documents and comments

- A header or comment in a `.lean` or `.py` file never cites a markdown file or a section of one:
  it states the contract the code implements, in full, in its own words.
- A design or audit document under `pipeline/DesignFile/` is written for a reviewer who reads it
  alone: every fact it relies on (what a check does, what a rule requires, what a phase is shown)
  is stated in the document, never delegated to another document or a section number. Code
  locations (`path:line`) are the only cross-references.

## Never

- Special-case a law in Core, the ontology, the prompts, the harness or the doctor.
- Approximate a span the ontology cannot carry with a neighbouring atom: file a gap.
- Decompose below an obligation span, or re-plan a law the ledger has closed.
- Copy from the archived prototype; borrow ideas, cite nothing from it.

## Commands

From `pipeline/traffic-spec-agent/`: `python -m harness init | doctor | loop | validate | gate |
verify | index | status | score_split` (see `README.md`). Run `lake` only inside `library/`.
Regenerate the ontology's Lean files with `python -m scripts.gen_ontology`; regenerate the
corpus and its split from `pipeline/ontology_provenance/nrs_tools/` (`make_laws`, `publish`,
`split`, `atoms_train`), never by hand.

## Lean library

`library/TrafficSpec/Core/**` is the frozen Core; tests in `library/TrafficSpec/Tests/*.lean` run
at build time (`lake build`) and pin the arithmetic and semantics with `#guard`. Rules import
`TrafficSpec.Core.Language.Rule` only; evaluation, checking and grounding are in files no rule may import.
`Index.lean` and `TrafficSpecWitness.lean` are generated.
