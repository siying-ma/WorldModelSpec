# Evaluation scenarios — what a trace must show before a line can be judged

`scenarios.jsonl` and `../example/test/scenarios.jsonl` together carry **one record per line of
`../full_list/laws.jsonl`** — 249 records, same ids, each file in corpus order. The test lines'
records sit beside the test split so that development, which does not read the test split, does
not read them either; the records of the lines that left the corpus on 2026-10-13 are kept in
`scenarios_excluded.jsonl`. Each record says what an evaluator needs from a trace before it can decide that
line: which observations the line requires, when the line is active, what the text excepts, and
what it demands of timing.

This is a **reading aid for evaluation, not a formalization**. It records what the text asks for;
it fixes no threshold, decides no verdict, and is not an answer key for the planner. Every
quantity the law leaves open is named as a residue, not filled in.

Written from the verbatim text of each line and the ontology in `../../ontology/ATOMS.md`
(draft of 2026-10-03). Check it with `python validate.py`.

## Record format

```json
{"id": "NRS-484A-450-2",
 "title": "Designation of through highways and intersections requiring stop or yield (2)",
 "source": "NRS 484A.450(2)",
 "subject": "driver", "theme": "intersections_and_right_of_way", "tier": "C",
 "required_observations": [{"atom": "dev.stop_sign", "note": "a stop sign at the intersection"}],
 "activation_conditions": ["the subject is approaching an intersection indicated by a stop sign"],
 "exceptions": [],
 "timing_requirements": [{"kind": "ordering", "requirement": "the halt occurs before the footprint crosses the halting reference"}],
 "residue": ["which of the three halting references applies is a map question"]}
```

- `id`, `title`, `source` — copied from the corpus line; `subject`, `theme`, `tier` — copied from
  its analysis record in `../audit_and_scripts/laws_meta.jsonl`; `validate.py` fails if any of
  them drifts.
- **`required_observations`** — what a source must observe for the line to be decidable, as
  `{atom, note}`. `atom` is an id from `ATOMS.md` (§1–§7 atoms and §9 derived concepts); `note`
  says what that atom stands for *in this line*. An atom that a source declares absent makes the
  rule report `unknown`, never compliance (`ATOMS.md` termination rule, clause 6) — so this list
  doubles as the per-line capability requirement. Of the 126 atoms and 5 primitives of `ATOMS.md`,
  120 are required by at least one line; the most frequent are `rel.occupies` (137 lines),
  `dev.regulatory_sign` (53) and `kin.speed` (51). Required by no line: the primitives (a line
  names the concept, not the computation under it), `ru.aggregate` and `st.region_geometry`
  (how a rule reads a word or a region, not what a line asks to see), `sig.compression_brake`
  (its line left the corpus), and the three control inputs `kin.gear`, `kin.throttle` and
  `kin.service_brake`, which exist so that the vocabulary covers what an instrumented source
  supplies. Where a line needs the subject's own controls or line of sight (`kin.engine_running`,
  `kin.parking_brake`, `kin.steer_angle`, `rel.visible`), a source that has them for the subject
  alone declares the capability `subject`, and the rule is decided for the subject only.
- **`activation_conditions`** — the antecedent: what must hold for the line to bind at all. A
  trace in which none of them holds does not test the line, it merely fails to engage it.
- **`exceptions`** — the carve-outs the text itself states, in the text's own terms (253 across
  133 lines). An exception is not a separate rule here: it is what an evaluator must rule out
  before calling a violation.
- **`timing_requirements`** — what the line demands of time, as `{kind, requirement}`. `kind` is
  one of eight: `point_event` (decided at one instant), `continuous` (holds at every instant while
  active), `duration` (a minimum or maximum elapsed time), `ordering` (event A before event B),
  `until` (persists until a stated release), `advance` (something must precede an act by a stated
  distance or time), `civil_time` (a calendar or clock window), `span` (the trace itself must cover
  a window, or the line cannot be decided). 440 entries; `continuous` (179) and `ordering` (84) are
  the commonest, and `span` (53) is the one that says a short clip is not enough.
- **`residue`** — what the text asks for that no atom supplies: a judgement standard needing an
  operationalization claim, a legal region class, a purpose or interior state, an administrative
  fact. Present on 187 of the 249 lines. `ATOMS.md` §8 and §9 say how each kind is handled.

## How to use it

- **Before a run** — filter the corpus to the lines whose `required_observations` a source can
  actually supply, and treat the rest as ungrounded rather than unformalized.
- **When scoring** — a capture in which a line's `activation_conditions` never hold does not test
  that line. Counting it as a pass is how a library of vacuous rules scores perfectly.
- **When a clip is too short** — the `span` entries name the lines that cannot be decided from a
  fragment (two signal cycles, a mile of continuous driving, half an hour of parking).
- **When a verdict disagrees with a label** — `residue` is the first place to look: the two sides
  may have quantified the same standard differently.

## Regenerating

The records are written by hand from the text, not generated, so there is no build step. After any
change to the corpus or to `ATOMS.md`, run:

```bash
python validate.py      # from laws/evaluation_scenario
```
