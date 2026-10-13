# Ontology provenance — NOT agent-readable

How `traffic-spec-agent/ontology/` was built, kept **outside** `traffic-spec-agent/` so that no
prompt, gate or agent session can read it. Reviewers use it to check completeness of the atom
set against the target statute; nothing in it may be rendered into a prompt, and nothing in it
is an answer key: the plan agent's own `elements` claims, validated by the harness and read by
the review phase, are the only element → atom mapping the pipeline scores.

Current (2026-09-18, Nevada Revised Statutes target):

- `nrs_atoms_provenance.md` — for every atom and derived concept in `ATOMS.md`: the NRS
  provisions that motivated it, why the `local` ones are Nevada-specific, grounding notes per
  planned source, the NRS elements deliberately *not* made atoms and where they went, and open
  review items.
- `nrs_tools/nrs_tree.py` — parses the NRS chapter pages (section → subsection tree);
  `nrs_tools/lvmc_tree.py` — the same for Las Vegas Municipal Code sections from Municode.
- `nrs_tools/make_laws.py` — the selection list and generator that produced
  `traffic-spec-agent/laws/full_list/laws.jsonl` (285 obligations as of 2026-09-20, verbatim: NRS 484A/484B/484D,
  NRS 486, LVMC Title 11, after `overlaps.py` drops the broader text of each overlapping pair). The `SPEC` list in this script is the record of which subsections were
  included, which paragraphs were appended to which, which subject/theme each line was given, and
  which lines were flagged as overlapping before resolution.
- `nrs_tools/overlaps.py` — every overlap decision (kept id, dropped id, reason) and the
  criterion; `laws/audit_and_scripts/OVERLAPS.md` is generated from it.
- `nrs_tools/references.py` — reference resolution: the id annotations inserted into line text
  (`REFS`), the extra appended subsections (`APP_MORE`, `XAPP`), the definitions rendered to the
  planner (`DEFS` → `laws/full_list/definitions.jsonl`) and the `unresolved` marks.
- `nrs_tools/tiers.py` — the classification of every line into the four views (excluded / unresolvable /
  judgement S-Q / concrete C) with the reason for each exclusion and each blocking mark.
- `nrs_tools/sources/` — the parsed section files the generator reads (`484A.json`, `484B.json`,
  `484D.json`, `486.json`, `lvmc.json`) and the text of the City's Transportation Engineering Fact
  Sheets (March 2025), which were read and found to contribute no obligations of their own.
- `LONGTAIL_ENCOUNTER_RATES_2026-10-12.md` and `NICHE_VOCABULARY_SURVEY_2026-10-02.md` — the
  external evidence behind the scope of 2026-10-13 (which laws lie outside ordinary urban Las Vegas
  driving); the decisions are `EXCLUDED` in `nrs_tools/tiers.py`.

Regenerating the corpus: run `make_laws.py` from a directory that holds the four NRS chapter files
(`484A.json` … `486.json`) and `lvmc/lvmc.json` (links to `nrs_tools/sources/`), then
`python -m nrs_tools.publish`, `python -m nrs_tools.split` and, with the full Core split active,
`python -m nrs_tools.atoms_train`, all from `pipeline/ontology_provenance/` except the first.

Superseded (first draft, BC MVA Part 3 target, kept for the record):

- `atoms_provenance_bcmva_2026-09-15.md` — the first atom tables with Part 3 sections, the
  Vienna/UVC cross-check and the grounding survey.
- `concepts_provenance_bcmva_2026-09-15.jsonl` — the first concept draft with `sections` and
  quoted `phrasings`, including the clause-shaped composites removed for being pre-formalizations.

Removed: `expected_mappings.jsonl` (a reviewer-written element → atom "answer key"). Deleted on
2026-09-18 because a Claude-written expected mapping is not ground truth and its existence
invited scoring the planner against it; mapping quality is judged by the review phase and by
evaluation accuracy on labelled traces instead.
