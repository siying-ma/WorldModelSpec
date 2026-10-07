# CARLA smoke subset — 2 training lines with judgement elements

Two independent lines (neither names the other), chosen to exercise the two ways the pipeline
treats a standard of judgement and to be scored on CARLA captures.

| id | what it is there for |
|---|---|
| `NRS-484B-407` | a concrete duty qualified by standards: a turn that reverses the direction of travel is prohibited "upon any curve, or upon the approach to or near the crest of a grade" where the vehicle "cannot be seen … within 500 feet". The reversal is a concept the plan proposes; "curve" and "near the crest" are `standard` spans operationalized with proposed reading parameters; 500 feet is a stated figure, written as a literal. The node is the law's own rule, not a surrogate |
| `NRS-484B-600-1a` | a duty that is the standard itself: "a rate of speed greater than is reasonable or proper, having due regard for the traffic, surface and width of the highway, the weather and other highway conditions". Any operationalization is a policy choice, so plan rule 4 marks the node `surrogate`; the monitor reports it on its own `surrogate` rows, never in the concrete tallies |

Both lines use the aggregate words "vehicle", "driver" and "traffic", so the plan writes
`aggregates.jsonl` from their definitions.

Expect, with `--plan_batch 1`: one or two concept records (a reversing turn; possibly a speed or
stopping-distance concept), two nodes, several proposed parameters in the reading for the
operator's review, and a review per node in which each operationalized standard is judged
`covered` only when the reading names it as a bound the reading sets.

What a capture must carry for these rules to be decided rather than unknown: speed and velocity
of every road user, road curvature and grade along the route, sight distance or line of sight,
lane width, and the weather and surface state (precipitation, wet road, ice or snow, visibility).
An atom the capture's manifest marks absent makes every verdict that reads it unknown.

`definitions.jsonl` holds the 4 posted definitions whose terms occur in the two lines and whose
applicability clause reaches them (NRS 484A.010: chapters 484A to 484E). Regenerate both files
with

```bash
cd pipeline/ontology_provenance
python -m nrs_tools.subset carla_smoke NRS-484B-407 NRS-484B-600-1a
```
