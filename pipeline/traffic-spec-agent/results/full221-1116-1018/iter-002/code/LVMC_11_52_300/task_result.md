# LVMC_11_52_300 — task result

## Final verdict

`BARE_LITERAL` (gate run 1 of 6). The node is wrong, and that is why I stopped. Two problems in the
record mean the rule cannot be written faithfully or witnessed as planned. Both are described below.

## Gate runs

1. `BARE_LITERAL`: formula literals `[60 s, 1800 s, 3600 s, 21600 s]` ≠ declared
   `[1800 s, 3600 s, 21600 s]`. The extra 60 s is the unit of `env.civil_time`'s `minute_of_day`
   field (see defect 1). I made no change after this run because the fix belongs in the record.

## The rule as written (files left in this state)

- s3 → binder class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- s1 → `¬ ru_aggregate(subject, "DEF-NRS-484A-130::motor_vehicle")` in the applicability.
- s4 → `existsRegion highway street (rel_occupies subject street)`, written in the applicability
  and again inside the obligation's window.
- s6 → `minute_of_day × 1 min ≥ Units.hours 1 ∧ < Units.hours 6`, in the applicability and inside
  the window.
- s2, s5 → obligation `¬ holdsFor(time, Units.minutes 30, subject, drv_motion_parked(subject;
  p.halt_speed_tolerance, p.parking_min_duration) ∧ on street ∧ within hours)`.
- I declared no narrowing. The witnesses use a 60 s sampling interval, a 20 m × 8 km street, and
  windows that start 35 min into each trace, so the 30 min + 3 min look-back is always covered.

## Defect 1 — s6 cannot be stated with the declared literals

`env.civil_time` gives the time of day only as `minute_of_day`, a count of minutes
(`Semantics.evalMeasure`: `qn (ct.map (·.minuteOfDay))`). The node declares "one a.m." and
"six a.m." as `1 h` and `6 h`, which become 3600 s and 21600 s. To compare the two, the formula
needs a conversion factor of 60 s per minute, and that literal is not declared, so the gate returns
`BARE_LITERAL`. Comparing `minute_of_day` directly with `Units.hours 1` would be wrong: 70 ≥ 3600 is
false, so no time of day would ever fall within the hours. The only other way to get the factor is
to build 60 from the declared figures by arithmetic, e.g. `6·2·(2+3)`. That would be a disguised
bare literal, so I did not use it.

**What the plan must change:** declare the hours in the unit the civil-time field reads (e.g.
"one a.m." as minute of day 60, "six a.m." as 360). Alternatively, declare the minute unit
(`1 min`) as a literal of s6, or have the harness accept a time-of-day measure in seconds.

## Defect 2 — the planned trailer witnesses cannot be decided under the run's reading

The narratives for `forbid`, `permit`, `blind` and `branch_1` use "a trailer (vehicle aggregate,
not a motor vehicle)". The run's reading lists `ru.trailer_or_combination` as **unresolved** under
`DEF-NRS-484A-130::motor_vehicle`. By `aggregateMembership`, a road user with only that class is
therefore *unknown* as a motor vehicle, never false. The s1 exception is unknown, so the
applicability is unknown, so `forbid` can never be `violated`.

The only classes that are decidedly a vehicle and decidedly not a motor vehicle in this reading are
`taxicab`, `commercial_motor_vehicle`, `emergency_vehicle`, `fire_apparatus` and
`official_vehicle`. In reality each of these is a motor vehicle and would carry `motor_vehicle`
alongside it. Using one alone would make a false scene, so I did not.

In practice, then, the rule can never be violated. Every realistic vehicle makes s1 either true
(a motor vehicle) or unknown (a trailer).

**What the plan must change:** either the reading resolves `ru.trailer_or_combination` for
DEF-NRS-484A-130 (a trailer that is not self-propelled is excluded), or the node and its scenarios
are re-planned with a subject class that the reading decides is a non-motor vehicle.

## Choices the node left open

None beyond the record's mapping. The "at or after one a.m. / before six a.m." bounds and the
"time window of thirty minutes" are as the record states them.

## Why I finished

The node is wrong. Defect 1 blocks the static literal check, and the only workaround is a disguised
literal. Defect 2 would make the planned `forbid` witness fail even if defect 1 were fixed. Neither
can be repaired in Lean within the record.
