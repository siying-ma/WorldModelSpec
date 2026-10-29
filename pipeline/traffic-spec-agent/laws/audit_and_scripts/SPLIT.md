# Corpus split — demo-overlap-v3

`../example/law-split.json` is the roster: 221 training lines and 28 held-out lines, every corpus
line named once. `python -m nrs_tools.split` (from `pipeline/ontology_provenance/`) writes
`../example/{train,test}/laws.jsonl` from it and `../full_list/laws.jsonl` (records unchanged,
corpus order), writes beside each the posted definitions the pipeline's definition resolver reaches
from its lines (directly cited, resolved or ambiguous, and nested), and regenerates the training
vocabulary (`split_atoms.json`, `../../ontology/ATOMS_train.md`, the training Core). It refuses a
roster under which a training line cites a held-out line, by bracketed id or by a reference recorded
in `laws_meta.jsonl`, and a roster that moves or changes a demo line. Law records are never edited.

## Why this roster

The held-out lines are chosen to interact with the 22 demo lines, so that a formalization developed
on the demo cannot be trivially consistent with what it has not seen: held-out lines cite demo lines
(484B.650(1) aggressive driving cites 13 of them; 250(3) cites 250(4); 403(1) cites 227(1) and 407),
and nine are subsections of a demo line's section (113(1); 250(3); 400(2)(c), (3), (4), (5);
413(1); 600(1)(b); 223(2)). Several are detailed provisions of the kind a city adds to a state code:
LVMC 11.12.020 (turn-course markers in an intersection), 11.12.060 (no U-turn at a fire station),
11.18.030(B) (keep within a marked lane), 11.12.100(C), 11.20.070, 11.42.030.

Training is reference-closed: no training line cites a held-out line. Held-out lines may cite
training lines.

No held-out line was exposed during development: none occurs in an agent session, the gap ledger,
a library or its snapshots, or a development document (fix plans, revisions, scans, run notes), and
none appears in the doctor's definition-resolution report of an earlier run. Four occur only in
the corpus-wide enumerations of 2026-09 that built the ontology and Core, which covered every line.
Lines of the previous roster that failed this test (484A.450(3), 484B.260, 484B.307(8)(a),
484B.603(1), 484B.310(1), 484B.413(3)) or that training lines cite (484B.213(1), 484B.307(2)(a),
484D.100(1)) are training lines.

## Held-out vocabulary

Withheld atoms: `dev.school_bus_signal` (484B.353(1)) and `sig.reverse_lamp` (484D.205(4)).
Withheld values: `dev.regulatory_sign` `lane_use_arrow` and `turn_course_marker` (LVMC 11.12.020).
An atom or value is withheld when every corpus line or training definition that supports it is held
out (keyword lexicon over text and title, plus the statute references in
`ontology_provenance/nrs_atoms_provenance.md`). The held-out rows of `ATOMS.md` are frozen in
`split_atoms.json`. The full Core variant is `library/splits/full`; `library/TrafficSpec/Core`
follows `library/splits/ACTIVE`.

## The 28 held-out lines

NRS 484A: none. NRS 484B: .100; .113(1); .200(1); .207(1), (2); .223(2); .250(3); .310(2);
.353(1); .400(2)(c), (3), (4), (5); .403(1); .413(1); .600(1)(b); .623(1); .650(1); .710; .768(1).
NRS 484D: .205(4); .215(2). LVMC: 11.12.020; 11.12.060; 11.12.100(C); 11.18.030(B); 11.20.070;
11.42.030.

## Scenario data

The corpus partition is distinct from the role a driving scenario plays in `scenario_pipeline`;
its cells follow this roster by its own migration. The evaluation package
`pipeline/datasets/demo-thirteen-latest-share-20261010` covers 13 demo lines, all training lines.
The evaluation package
`pipeline/datasets/held-out-v1-intent-laws` covers LVMC 11.12.100(C) (held out) and LVMC
11.43.010(C)(1), (C)(2) (training lines).
