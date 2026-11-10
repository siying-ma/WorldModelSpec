# NRS_484B_769 — task result

## Final verdict

`WITNESS_FAIL` (1 gate run of 6), on the planned `forbid` witness only:

```
WITNESS_FAIL
   forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
```

No other witness was reported failing.

## Gate runs

1. `WITNESS_FAIL`: `forbid` (an electric scooter on a roadway, right indicator lit, no arm signal) came out unknown, not violated, because the scooter's class is unknown. I changed nothing after this run because the defect is in the plan/reading, not in my files (see below).

## The rule as written

- **Class of x (c1–c3):** `ru_aggregate x "DEF-NRS-484A-025::bicycle" ∨ ru_aggregate x "DEF-NRS-484B-017::electric_bicycle" ∨ ru_aggregate x "DEF-NRS-484B-018::electric_scooter"`.
- **Applicability (c4):** `existsRegion "roadway" r (rel_occupies x r)`. The c7 exception adds nothing to the applicability, as the record states.
- **Obligation (c5 + c6, c7):** `(sig_turn_indicator x left → sig_hand_signal x left) ∧ (sig_turn_indicator x right → sig_hand_signal x right)`. The exception is carried by the right-hand conjunct, because `sig.hand_signal` reads only the meaning, so a right-turn arm signal satisfies it whichever arm gives it.
- **Narrowings:** none. The record fixes the obligation exactly, and its own c1 and c5 narrowings are not restated.

## Witnesses

These are the planned forbid / permit / idle / blind / branch_1 / branch_2, plus three I added so that every leaf of the obligation moves a decided witness:
- `branch_3` (compliant): a bicycle with the left indicator and a left arm signal.
- `branch_4` (violated): an electric bicycle with the left indicator and no arm signal.
- `branch_5` (violated): a bicycle with the right indicator and no arm signal. This decides the right-indicator leaf without depending on the scooter.

Geometry: roadway 0–200 m × −5–5 m, sidewalk above it at y 5–8 m, and x riding east at 5 m/s for three instants.

## Why I finished: the node (its reading of c3) is wrong

The run's reading classifies the aggregate `DEF-NRS-484B-018::electric_scooter` as **included: (none)**, and lists `ru.electric_scooter` among the unresolved classes. Under the `ru.aggregate` contract, a road user carrying `ru.electric_scooter` can therefore never be a decided member. The atom is unknown for every electric scooter, so the binder class and the verdict are unknown wherever the subject is a scooter.

Two consequences:
- The planned `forbid` witness ("x, an electric scooter, …", expected violated) cannot be met by any honest scene. I did not swap the scooter for another class, because that would contradict the narrative.
- The c3 element (`ru.aggregate=DEF-NRS-484B-018::electric_scooter`) can never make the rule engage. The span is in effect unexpressed.

What the plan / reading must change (one of these):
- In the run's reading, classify `ru.electric_scooter` as **included** under `DEF-NRS-484B-018::electric_scooter`. Its definition ("a vehicle with handlebars and an electric motor … ridden on in an upright or seated position") is the electric scooter class itself. The motor-vehicle-type classes can stay unresolved.
- Or, if the reading is deliberate, re-plan the `forbid` scenario with a bicycle or an electric bicycle (e.g. the subject of `branch_5`), and record that c3 is undecidable under this reading.

My rule and witness files need no change for either repair. With a scooter included, `forbid` would be violated: indicator right, arm signal no_signal, on the roadway.
