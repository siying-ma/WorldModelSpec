# Evaluation scenarios — what a trace must show before a line can be judged

`scenarios.jsonl` carries **one record per line of `pipeline/traffic-spec-agent/laws/full_list/laws.jsonl`** — 249 records, same
ids, same order; the records of the lines that left the corpus on 2026-10-13 are kept in
`scenarios_excluded.jsonl`. This folder is the instruction set for the developers of the adapter
(what a trace must show before each law can be judged); the pipeline and its development sessions
do not read it. Each record says what an evaluator needs from a trace before it can decide that
line: which observations the line requires, when the line is active, what the text excepts, and
what it demands of timing.

This is a **reading aid for evaluation, not a formalization**. It records what the text asks for;
it fixes no threshold, decides no verdict, and is not an answer key for the planner. Every
quantity the law leaves open is named as a residue, not filled in.

Written from the verbatim text of each line and the ontology in `pipeline/traffic-spec-agent/ontology/ATOMS.md`
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
  its analysis record in `pipeline/traffic-spec-agent/laws/audit_and_scripts/laws_meta.jsonl`; `validate.py` fails if any of
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

## Changes the pipeline requires of the adapter

What follows is owed by the adapter, not by the pipeline: each item is a place where the trace
misreports the scene, or declares as unobservable what the source can tell. The pipeline is never
changed to fit a dataset; Core already gives the meaning each item relies on. Entries are added
when a change to Core or the ontology changes what a trace must carry, and marked done when the
adapter ships them.

| # | Change | Why (what Core does with the trace as it is) | Status |
|---|---|---|---|
| 1 | **Export the highway.** Write one region of kind `highway` per public road of the map (an OpenDRIVE road), its boundary covering every lane, shoulder and sidewalk of that road, and declare `st.highway` `exact`. | A rule reads "upon a highway" as a quantifier over `highway` regions. With `st.highway` declared absent, every structure is a region whose highway-ness is unknown, so every such rule is unknown wherever it applies, and on carla_new the manifest declares it absent. | open |
| 2 | **Declare absent only what the adapter cannot tell.** For every region and device kind the adapter enumerates completely from the map (all junctions, crosswalks, lanes, shoulders, sidewalks, medians, …), declare the kind `exact`, including when the map holds no instance: then "no such region here" is decided. Declare a kind `absent` only when the adapter does not read it at all. | A kind declared absent makes every structure of the scene a candidate for that kind, with its membership unknown: a quantifier over the kind is unknown wherever a candidate could decide it, and the monitor evaluates every structure against it. The carla_new manifest declares 24 region kinds absent, which made each case take about 20 minutes to monitor. | open |
| 3 | **Write the turn indicator's state on every frame**: `off`, `left` or `right` from CARLA's `VehicleLightState` (both blinkers lit: `off`, with `hazard` true). | `sig.turn_indicator` is a state with `off` since 2026-10-13, so "no signal was given" can be decided. The carla_new traces report `left` in every scene of every case while the manifest declares the atom `exact`, so every rule that requires a signal is falsely satisfied; the evaluation scripts declare the atom absent until this is fixed. | open |
| 4 | **Export what the simulator knows**: the weather (`env.precipitation`, `env.wet_road`, `env.ice_or_snow`, `env.visibility`), each lane's width from the map (`st.lane_width`), and the ego's engine state (`kin.engine_running`). | Rules on speed and conditions read them; while they are absent those rules are unknown. `pipeline/evaluation/eval_carla_new_filled.sh` fills them with assumed values only to show what the verdicts would be. | open |
| 5 | **Write the arm signal as `no_signal`** on every road user (CARLA renders none). | `sig.hand_signal` has the value `no_signal` since 2026-10-14. A rule that accepts an arm signal as a signal reads "the indicator, or the arm, showed the side"; with the arm signal absent that is unknown whenever the indicator is off, so such a rule can never be `violated`. | open |
| 6 | **Write `ways` on every structure region** (`st.on_way`): a lane, roadway, shoulder, crosswalk, stop line and median carry the `highway` region of their road, a junction every highway whose road connects there. An OpenDRIVE road ends at each junction, so the roads on the two sides of a junction that form one public way (by road name, or by straight continuation through the junction) must share one `highway` region; where the adapter cannot group them, declare `st.on_way` absent. Depends on item 1. | Since 2026-10-14 "of this way", "the intersecting highway" and "from different highways" are read through `st.on_way`. Without it those rules are unknown on that limb. | open |
| 7 | **Write `sight_along_way`** on the road users the adapter can cast rays from: along each way meeting the junction ahead, both directions, the smaller kept. Otherwise declare `st.sight_along_way` absent. | A rule that asks for a view of traffic on another way reads it; absent, that limb is unknown, which is the honest verdict. | open |
| 8 | **None (information).** `curvature` may be written with either sign. | Since 2026-10-15 Core reads `st.curvature` as a magnitude (the absolute value of what the trace stores): a bend to either hand has the same curvature, since a region has no direction of travel. | none required |

## Regenerating

The records are written by hand from the text, not generated, so there is no build step. After any
change to the corpus or to `ATOMS.md`, run:

```bash
python validate.py      # from pipeline/evaluation/evaluation_scenario
```
