# LVMC_11_52_300 — task result

## Final verdict

`WITNESS_FAIL` (gate run 2). **The node is wrong against the run's reading** (see below): its
planned `forbid`, `permit`, `blind` and `branch_1` witnesses cannot be decided by any rule written
from its elements, so I stopped rather than spend the budget or bend the witnesses.

## Gate runs

1. `UNUSED_CLAIM` — run by mistake on the untouched skeleton (every formula `.tt`). Nothing changed
   because of it.
2. `WITNESS_FAIL` — rule and six witnesses written. It built, passed the static check, raised no
   claim, literal or anchoring complaint, and `idle` and `branch_2` passed. `forbid`, `permit`,
   `blind` and `branch_1` all came back unknown for
   `aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle`.

That is 2 of 6 runs used.

## The rule as written

- class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- applicability: `¬ ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"` ∧
  `∃ highway street. rel_occupies subject street` ∧ `60 ≤ env_civil_time.minute_of_day < 360`.
  The hours bounds are written as `Units.ratio 60 1` and `Units.ratio 360 1` with `.count`.
- obligation: `¬ holdsFor time (30 min) subject (drv_motion_parked(subject; p.halt_speed_tolerance,
  p.parking_min_duration) ∧ street ∧ hours)`. The street selection and the hours are written out
  again inside the window, because the applicability's region is not in scope there.
- narrowings: none. The node left no reading open.

## Witnesses

- Street: a highway rectangle. Samples are 60 s apart, and each witness has a `window` so that no
  look-back is truncated.
- The planned witnesses: `forbid`, `permit`, `idle`, `blind` and `branch_1`.
- One added witness: `branch_2` (not applicable), a trailer parked on a private lot off the street.
  It makes the street leaf of the applicability decide something.

## Why the node is wrong

- **Span s1, "Except for a motor vehicle".** It is carried as
  `¬ ru.aggregate=DEF-NRS-484A-130::motor_vehicle`. Its justification leaves the trailer's
  membership to "the run's reading of that id".
- **The reading leaves trailers undecided.** The run's reading lists `ru.trailer_or_combination`
  as **unresolved** under `DEF-NRS-484A-130::motor_vehicle`, so for a trailer the exception is
  always unknown. That makes the whole applicability unknown.
- **The scenarios contradict this.** Every planned trailer scenario (`forbid`, `permit`, `blind`,
  `branch_1`) assumes the trailer is decidedly not a motor vehicle. The gate confirms each one
  evaluates to unknown.
- **No honest substitute exists.** Under this reading, a road user is decidedly a vehicle and not
  a motor vehicle only if it carries nothing but a "covered" class: taxicab, official vehicle,
  emergency vehicle, fire apparatus or commercial motor vehicle. Each of those is in fact a motor
  vehicle and contradicts the narratives, so I did not build witnesses on them.
- **Consequence.** As planned, the rule can never engage for the vehicles the ordinance is aimed
  at (trailers and other non-self-propelled vehicles). Every such recording would report unknown.

**What the plan agent must change.** It needs a way to decide that a non-self-propelled vehicle
is not a motor vehicle. Either of these would do:

- the reading classifies a drawn trailer as excluded from `DEF-NRS-484A-130::motor_vehicle`;
- `trailer_or_combination` is split into a trailer and a self-propelled combination.

Otherwise the node should state that s1 cannot be decided for any representable vehicle and
re-plan its scenarios to match. The rule's formulas need no change once the reading decides
trailers.

## Why I finished

The gate's failure comes from the node's mapping meeting the run's reading, not from the Lean.
The only way to reach the planned verdicts would be to change the subject's class to one that
contradicts the narratives and the facts. The rules say to report a wrong node instead.
