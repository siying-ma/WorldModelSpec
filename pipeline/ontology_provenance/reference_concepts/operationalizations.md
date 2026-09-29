# Operationalization table — reference copy (moved out of ATOMS.md §8 on 2026-09-28)

Not agent-readable. Used only to score a finished run's operationalizations against what a human
reviewer once wrote; never rendered into a prompt (it would be a seed list).

## 8. Judgement standards — not atoms; how a rule gives them a concrete meaning

Traffic law states many duties as standards: a manoeuvre made "with safety", a speed that is
"reasonable", a distance that is "practicable", a vehicle "so close as to be a hazard", a stop
"when necessary". No scene contains a reasonableness. A specification that bottoms out in such a
word detects nothing, so a standard is never an atom and never a leaf of a rule.

**Operationalization.** The plan maps every standard in a clause to a derived concept of §9 with
concrete parameter values, and records an *operationalization claim*: the standard's words, the
derived concept, the values, and the engineering convention the values come from (a headway
convention, a gap-acceptance convention, a stopping-distance model, a sight-distance model). The
harness rejects a node that maps a standard to nothing; the review phase checks that the claim
bounds the standard rather than replacing an observable the clause states outright. The same
claim is what a label uses, so specification and label quantify the standard exactly once.

**Two kinds of rule follow.** Where the standard qualifies an otherwise concrete duty (a yield
that is owed when the other vehicle is "so close as to be a hazard"), the operationalization is a
bound on one element and the rule is the law's own rule. Where the standard *is* the duty ("due
care", "careless", "reasonable speed"), any operationalization is a policy choice, not a reading
of the text: such a rule is marked **surrogate**, its verdicts are evidence and not a legal
conclusion, and it is evaluated separately.

Recurring standards and the derived concepts that operationalize them:

| standard, as law phrases it | operationalized by | parameter the claim states |
|---|---|---|
| so close as to be a hazard; approaching so closely as to be in danger; hazardous proximity | `drv.time_to_conflict` below a bound at the conflict point | the time bound |
| safe distance; safely clear; with safety (of a pass, a lane change, a turn) | `rel.surface_gap` (lateral clearance) and `drv.time_gap` after the manoeuvre above bounds; `drv.time_to_conflict` with every affected user above a bound | the clearance, the gap, the time bound |
| reasonable and prudent following | `drv.time_gap` above a bound | the headway |
| clearly visible for a sufficient distance; view obstructed | `drv.sight_distance_adequate` at the subject's speed | the stopping- or passing-distance model |
| as near / as close as practicable | a lateral offset from the edge or line below a bound | the offset |
| if possible; unless unsafe (a lane change away from a hazard) | `drv.lane_change_feasible` for the adjacent lane | the gap the adjacent lane offers |
| appropriate signal | `sig.turn_indicator` or `sig.hand_signal` shown over `drv.distance_while` before the manoeuvre | the distance |
| so slow as to impede | `drv.speed_below_traffic` with `drv.queue_behind` | the speed margin, the queue size, the duration |
| when necessary to avoid conflict with other traffic (as an excuse for a halt) | `drv.forced_halt` | the gap ahead |
| otherwise directed by an officer | `drv.officer_directed` | — |
| expeditious loading or unloading; temporarily | `drv.standing_or_parked` with `sig.door_open` or a passenger exchange, below a duration bound | the duration |
| suddenly decrease speed | `drv.hard_deceleration` | the deceleration bound |
| knows or ought to know (of a faster vehicle behind) | replaced by the observable the standard is about: `drv.slower_than_posted` with a following vehicle closing | the closing rate |
| due care; proper caution; careless; reckless; full attention; intentionally | **surrogate only**: `drv.time_to_conflict` with any user below a bound, or `drv.hard_deceleration`, or contact | the bounds |
