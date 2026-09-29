# Derived-concept table — reference copy (ATOMS.md §9 as of 2026-09-28)

Not agent-readable. The 40 concepts Core carried before concepts became pipeline nodes; the Lean
bodies are in `Derived_full_2026-09-28.lean`. Used for choosing the primitives (plan phase 1), for
differential tests against the Formula rewrites, and for scoring a run's concept catalogue by
contract. Never rendered into a prompt.

**Derived concepts** (`drv`) — defined once in Core from atoms, with parameters exposed; rules
may use them, and a rule never redefines them:

| id | definition sketch | parameters |
|---|---|---|
| `drv.stopped` | speed ≤ ε for a span ≥ d | ε, d |
| `drv.standing_or_parked` | stopped, not in a queue of moving traffic, for ≥ d | d |
| `drv.moving_off` | stopped then speed > ε | ε |
| `drv.turning` | heading change ≥ θ within a window w, left or right | θ, w |
| `drv.u_turn` | heading reversal within a window w while on the roadway | w, tolerance |
| `drv.lane_change` | the start of a lane change: a lane adjacent to those occupied at the previous observation is entered | — |
| `drv.lane_change_feasible` | the adjacent lane on a given side has no user within gap g ahead and behind the subject's projected position; undefined while the body occupies several lanes | side, g |
| `drv.overtaking` | same direction (heading cosine at least a tolerance), b was ahead of a and is behind it | cosine tolerance |
| `drv.passing_side` | which side the overtaken vehicle was on while the bodies overlapped, same direction | side, cosine tolerance |
| `drv.entering_intersection` | the footprint crosses the boundary of a region (an intersection, a crosswalk, a zone) from outside to inside | — |
| `drv.in_intersection` | the footprint overlaps the region | — |
| `drv.approaching` | the body is within distance d, along its lane, of the region's boundary and moving toward it | d |
| `drv.crossing_line` | footprint crosses a stop line / crosswalk boundary | — |
| `drv.cleared_line` | the body's trailing end is at least d past a line or rail | d |
| `drv.backing` | velocity opposed to heading | — |
| `drv.following` | same lane, behind, within gap g | g |
| `drv.time_gap` | `rel.surface_gap` (longitudinal) ÷ follower's speed | — |
| `drv.time_to_conflict` | time until the subject's and another user's projected paths occupy the same point, at current velocities; infinite when they do not | projection horizon |
| `drv.meeting` | oncoming vehicles whose paths overlap within t | t |
| `drv.yields_to` | a slows or stops so that b passes first (a's arrival order after b) | — |
| `drv.arrival_order` | which of two approaching users reaches the intersection boundary first, with a simultaneity tolerance τ | τ |
| `drv.wrong_way` | heading opposed to `st.lane_direction` of the lane occupied | tolerance |
| `drv.straddles_marking` | footprint on both sides of a marking | — |
| `drv.responding_emergency` | `ru.emergency_vehicle` ∧ (`sig.warning_lamp` red or blue ∨ `sig.siren`) | — |
| `drv.vulnerable_road_user` | `ru.pedestrian` ∨ person on `ru.bicycle` / `ru.electric_bicycle` / `ru.electric_scooter` ∨ classes a reading adds | — |
| `drv.laned_roadway` | roadway with two or more marked lanes in one direction | — |
| `drv.extreme_lane` | the leftmost / rightmost lane among those of the subject's direction | side |
| `drv.priority_roadway` | roadway whose entrances carry `dev.stop_sign` or `dev.yield_sign`; undefined while the body occupies several lanes | — |
| `drv.distance_while` | path length over which a condition has held continuously up to now | — |
| `drv.within_signed_zone` | between a `dev.zone_sign` and its matching end sign governing the subject's lane, of a given kind | kind |
| `drv.condition_in_effect` | a device's structured conditions hold at the observation: `env.civil_time` falls in one of its time windows on one of its days (a calendar class such as a school day or a public holiday is an assumption), and any occupancy or class condition is met by the subject | — |
| `drv.civil_night` | `env.civil_time` is later than sunset plus an offset or earlier than sunrise minus an offset, for the date and the location the reading declares **Not a stand-in for:** `env.darkness`, which is the observed light level; a rule states which one it reads | offsets |
| `drv.queue_behind` | at least n vehicles in line behind the subject, each following the one ahead within gap g | n, g |
| `drv.signal_cycles` | the number of transitions of the governing signals into an indication permitting a movement (straight, left or right) since the subject stopped | movement, stop speed |
| `drv.slower_than_posted` | speed below the governing `dev.speed_limit_sign` value by at least a margin | margin |
| `drv.speed_below_traffic` | speed below the median speed of same-direction users within range r by at least a margin | r, margin |
| `drv.sight_distance_adequate` | `st.sight_distance` at the subject's position ≥ the distance a stopping- or passing-distance model gives for the subject's speed | model, deceleration |
| `drv.stopping_distance` | the distance a body at the subject's speed needs to halt under a deceleration a, plus a reaction distance | a, reaction time |
| `drv.hard_deceleration` | `kin.accel_longitudinal` below a negative bound | bound |
| `drv.forced_halt` | the subject halts while a user ahead in its lane within gap g is halted, a governing signal shows a halt, a governing stop sign's line or post is within g, or a governing officer signals a halt | g, stop speed |
| `drv.officer_directed` | a `dev.human_direction` with role police governs the subject's approach and gives an indication | — |
