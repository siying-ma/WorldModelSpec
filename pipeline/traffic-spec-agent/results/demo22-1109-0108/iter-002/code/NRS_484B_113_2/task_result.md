# NRS_484B_113_2 — coding session result

**Final verdict: `OK`** (`9 witnesses, 8 names, composes nothing`), on the first gate run.
Budget: 1 of 6 runs used.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing — the rule and the witnesses as first written were accepted; the session finished. |

Before running the gate I wrote both files in one pass from the node: the rule's class formula,
applicability and obligation from the elements and the record's `obligation` prose, and nine
witnesses (the six the node plans plus three branches of my own).

## The rule

- **s1** → `clsV = ru_aggregate v "DEF-NRS-484A-320::vehicle"`; the aggregate id, never its
  classes. The record's own observable reading of "the driver" is not restated.
- **applicability** → `.tt`. The record states the prohibition "has no further trigger: it bites
  at any observation at which the vehicle is travelling rearward", so nothing beyond the binder's
  class gates engagement, and the whole prohibition — the rearward motion included, exactly as
  the record's `obligation` writes it — is the duty.
- **obligation** → `.not (reversing ∧ (a ∨ b ∨ c))` with
  - `reversing = drv_motion_reverse_travel v [p.reverse_speed_tolerance]`,
  - (a) `∃ i : intersection. st_intersection i ∧ .rises (rel_occupies v i)` — the entry event,
  - (b) `∃ cw : crosswalk. st_crosswalk cw ∧ rel_occupies v cw` — the overlap itself,
  - (c) `∃ j : intersection. st_intersection j ∧ rel_occupies v j ∧ (∃ h1 h2 : highway.
    st_highway h1 ∧ st_on_way j h1 ∧ st_highway h2 ∧ ¬ same h1 h2 ∧ st_on_way j h2) ∧
    asm.inside_city_limits ∧ drv_motion_turning v [p.turn_recognition_window,
    p.heading_change_noise_floor]`.
  The limbs are joined by `.or`, so a decided limb decides the duty where another is unknown for
  want of the city-limits declaration, as the record directs. Every claimed atom and concept is
  used; no value of any parameter is in the file; `narrowings` is empty.

## Choices the node left open

- **Where limb (c) lives.** s3 and s4 carry the role `condition`, but the record's `obligation`
  places their content inside the duty ("(c) be turning … while its footprint overlaps the region
  where two highways meet and the assumption … holds"). I followed the `obligation` prose and the
  `applicability` prose ("no further trigger"), so the applicability is `.tt` and limb (c) is a
  disjunct of the prohibition. A scene where the corner limb fails is therefore *compliant*, not
  *not_applicable*; the node's planned verdicts (notably `permit` compliant and `idle`
  not_applicable, the latter decided by the class) agree with that placement.
- **"Two highways meet."** Written as two highway variables held apart by `.not (.same h1 h2)`,
  both tied to the junction by `st_on_way`. The distinctness is what "two … meet" states, so this
  is the record's reading and not a narrowing of it; it is explained in the rule's header.
- **The assumption.** `.asm "asm.inside_city_limits"` is flat (the constructor takes an id only).
  That is faithful because the declared assumption's own words are already region-relative — "the
  highway the road user occupies at the observation lies inside the territorial limits of a city" —
  so no operator is missing and no narrowing is owed.
- **The crosswalk** is read by its kind alone (`st_crosswalk`), which carries both limbs of the
  crossing definition; `st_crosswalk_marked` is not claimed and is not used.
- **Anchoring.** `i`, `cw`, `j` are tied to `v` by `rel_occupies`; `h1`, `h2` to `j` by
  `st_on_way`.
- **Narrowings declared: none.** The readings on s1 (agency) and s2 ("into" as the rise of the
  overlap) are the plan's own and are not restated; I chose nothing narrower than the words.

## Witnesses

All nine are 141 scenes at 50 ms (t = 0 … 7000 ms) and name t = 6000 … 7000 ms as the instants
they speak about, so the three-second window the turning concept looks back over is always
covered. A reversing body's velocity is set against its heading, so the component along the
direction it points is the negative of its speed; stated occupancy matches the footprint
geometry scene by scene.

- `forbid` violated — the car's rear face crosses the junction boundary at t = 6500 ms: the rise
  of `rel_occupies` on the intersection, while reversing at 1.5 m/s.
- `permit` compliant — the same car reverses 10.5 m at mid-block; two junctions and a crossing
  are in the scene and decidedly unoccupied, so limbs (a), (b), (c) are all decided false.
- `idle` not_applicable — a pedal cycle: the aggregate is decided false, not unobserved.
- `blind` unknown — the `forbid` trace with `kin.velocity` absent: limb (a) is true at the entry
  instant and the rearward reading is unknown, so the conjunction is unknown there and compliant
  elsewhere.
- `branch_1` violated — a van's footprint overlaps the mid-block marked crossing while reversing
  at 1 m/s; the trace holds no intersection region, so limbs (a) and (c) are false.
- `branch_2` violated — the car backs around the corner inside the junction of two highways,
  yawing 10 deg/s (half a degree per scene, as an exact rational rotation, its reference point on
  the matching 8.6 m arc) with the city-limits declaration true. It entered the junction before
  the recording, so limb (a) is false and limb (c) alone decides.
- `branch_3` compliant (mine) — the `forbid` geometry driven forward: `drv.motion.reverse_travel`
  is decided false, so the entry into the intersection bites nothing.
- `branch_4` compliant (mine) — `branch_2` with the city-limits declaration false: the assumption
  leaf alone flips the verdict.
- `branch_5` compliant (mine) — the same junction reversed straight through, yaw rate zero: the
  turning leaf alone flips the verdict.

The three added branches make `reverse_travel`, `asm.inside_city_limits` and
`drv.motion.turning` each pivotal between a violated and a compliant witness; `permit` makes each
limb's `rel_occupies` pivotal, and `branch_2` makes every conjunct of the corner limb
(`st_intersection`, `st_highway` twice, `st_on_way` twice, the distinctness) pivotal.

## Why I finished

The gate returned `OK` on the first run: the rule states the node's three limbs with only the
claimed names and the node's parameters, every leaf is exercised by a decided witness, and all
nine witnesses carry their planned verdicts. Nothing in the node looked wrong, so there is no
defect to report and no `dependency_defect.json`: both concepts (`drv.motion.reverse_travel`,
`drv.motion.turning`) behaved exactly as their contracts state on these scenes.
