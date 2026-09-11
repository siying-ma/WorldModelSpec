# evalkit — a jurisdiction-neutral evaluation pipeline for traffic-rule monitors

Built to answer one question at the scale the project actually needs: **if the
target is every obligation in BC MVA Part 3 (ss.119–214, ~96 sections), and a
user may swap in another city's code, how does the ground truth get produced
without O(rules × captures) human labelling?**

The answer is a layering, not a labelling effort.

```
L0  trace      rsv/*.pkl + ego_logs.json            what the monitor sees
L1  facts      facts.jsonl, jurisdiction-neutral    what physically happened
L2  readings   readings/<jurisdiction>.jsonl        what the law demands
L3  labels     DERIVED, never hand-written          the ground truth
```

Human effort is spent on **L2 only**: O(obligations), once per jurisdiction,
~10 minutes of review each. Adding a jurisdiction re-uses every capture
unchanged. Re-reading a clause relabels the whole corpus in seconds.

## Why not just label per rule

Because a per-rule label is a *second formalization* of the same statute. If it
is written independently of the specification under test, the two are two
readings of one ambiguous sentence: agreeing proves nothing (the same misreading
twice is indistinguishable from a correct one) and disagreeing does not say
which is wrong. This is not hypothetical — in this repository the clause "at
least two seconds of space" was quantified as **20 m centre-to-centre** in the
Lean rule and **4 m bumper-to-bumper** in the label script.

A *reading* makes the quantification happen exactly once, in a place both
consumers cite. The specification and the label stay independent where it
matters — the spec is written over the scene graph, the reading over privileged
physical state — while sharing the one thing that must not vary.

## Measured facts this pipeline encodes

All verified against the 33-capture SceneFlowLang corpus (44,455 frames of real
`carla_sgg` output), not taken from documentation.

| finding | evidence |
|---|---|
| **Replay kills all dynamics.** Any capture from a CARLA recorder log has `carla_speed == 0` on every frame while the vehicle moves. | 882 of 882 moving frames report stationary on `HazardAtSideLaneTwoWays` |
| Differencing `vertex` recovers it | mean abs error **0.039 m/s** vs the ego log, once aligned |
| **The agent log leads the scene graph by exactly +10 frames** (`AGENT_TICK_DELAY`). Pairing frame *i* with record *i* evaluates rules on data 0.5 s apart. | +10 on **3 of 3** logged captures; error 0.68–1.17 → 0.039–0.057 m/s |
| **No non-ego actor ever carries a velocity.** `copy_carla_actor_state` runs for the ego node only. | `actor.speed_mps` is ABSENT in the SG view, permanently |
| **`ego -isIn-> Lane` is one-to-many** (5 lane nodes in one checked frame). "Same lane" is a set intersection; written as equality it never fires. | — |
| **Posted controls *are* monitorable.** Lights reach lanes by `controlsTrafficOf` with `light_state`; landmarks by `mayAffect` with `landmark_type` (206 stop, 274 speed limit, 1000001 signal) and `landmark_value`. | `landmark_OpenDRIVE_274_30` → `landmark_value: 30.0` |
| **`landmark_unit` reads `'mph'`** on CARLA speed-limit signs while the towns are authored in km/h. Believing it scales every limit by 1.61. | pinned in `extract_sg.SPEED_LIMIT_UNIT` |
| **10 of 33 captures do not load** under shapely 1.8 — they were pickled with shapely 2. | `ModuleNotFoundError: shapely.io` |

## What it produces

```bash
export PYTHONPATH=../carla_scene_graphs:../carla_scene_graphs/sim/PythonAPI/carla:.
PY=../carla_scene_graphs/.carlasg/bin/python
DS=../datasets/sceneflowlang/study_data

$PY -m evalkit report --corpus $DS --readings readings/bc_mva_part3.jsonl
$PY -m evalkit mutate --corpus $DS --readings readings/bc_mva_part3.jsonl
$PY -m evalkit label  --corpus $DS --readings readings/demo_eu_urban.jsonl
$PY tests/test_pipeline.py
```

**`report`** needs no monitor and no labels. Run it first on any corpus — it
says what that corpus can and cannot be used to test. On the SceneFlowLang data:

```
captures found 33, usable 23, frames 9200, 4.3 min of driving
Bench2Drive scenario coverage: 3 of 44
  witnessed 8/10 obligations, two-sided 3/10, untestable everywhere 2
  ego.lane.wrong_way            blocks: BC-MVA-150-1
  ego.posted.crosswalk_ahead_m  blocks: BC-MVA-179-1
```

Every uncovered obligation prints the Bench2Drive scenarios that would witness
it, so a coverage hole is a work item rather than a percentage.

**`mutate`** scores the *dataset*, with no labels and no monitor: perturb a
constant, re-derive, and see whether any capture notices. A surviving mutant is
a constant the corpus cannot pin down.

```
overall mutation score: 0.442
  BC-MVA-157-1  36/36 killed   1.00
  BC-MVA-162-1  12/12 killed   1.00
  BC-MVA-186-1   0/12 killed   0.00   <- no capture near the stop threshold
```

**`score`** compares a monitor's alarms against the derived labels: per-rule
episode precision/recall/F1, **latency**, and a `MonitorScore` that is the
product of two-sided rulebook coverage and mean quality — so covering 3 of 96
obligations caps the score at 0.031 however good the monitor is.

## Layout

```
evalkit/facts.py       L1 schema + per-field provenance (SIM/SG/DERIVED/ABSENT)
evalkit/reading.py     L2 expression language, three-valued (UNKNOWN ≠ False)
evalkit/evaluate.py    L3 label derivation, as intervals not verdicts
evalkit/metrics.py     detection + latency + coverage + MonitorScore
evalkit/mutation.py    label-free dataset discrimination
evalkit/extract_sg.py  L1 from scene graphs — the monitor's view
evalkit/corpus.py      discovery, Bench2Drive's 44, coverage reporting
readings/              one file per jurisdiction
tests/                 24 unit tests, no CARLA required
```

## Design rules

1. **UNKNOWN is not False.** A missing fact propagates as UNKNOWN, so a rule can
   never be satisfied by a gap in the data.
2. **UNTESTABLE is not NOT_APPLICABLE.** The first is a claim about the
   recording, the second about the world. Conflating them lets a corpus with a
   missing field report full coverage.
3. **Physics in L1, thresholds in L2.** `headway_s` is computed in the fact
   layer, so the expression language needs no arithmetic and stays reviewable at
   a glance — which is the only property that makes L2 worth having.
4. **Every constant declares its provenance**: `statute` (in the text),
   `reading` (a human judgement, the thing being reviewed), or `borrowed` (taken
   from the implementation under test, and therefore unfalsifiable by this
   label).
5. **Never trust a docstring over a measurement.** Every claim in the table
   above was checked against the corpus.

## Not yet done

- `extract_sim.py` — the privileged-state extractor. Needs a running CARLA
  server; the schema and provenance contract are in place for it.
- Crosswalk polygons (`carla.Map.get_crosswalks()`) and lane heading, the two
  ABSENT fields that block the most obligations.
- Structural mutation. `BC-MVA-129-1` has no numeric constants, so numeric
  mutation reports `-` for it; falsifying it needs operator-level mutants.
