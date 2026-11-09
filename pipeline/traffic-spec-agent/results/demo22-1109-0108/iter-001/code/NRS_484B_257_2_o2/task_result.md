# NRS_484B_257_2_o2 — coding session result

**Final verdict: `OK`** (16 witnesses, 17 names, composes nothing, 4 coder narrowings).

## Gate runs

| # | verdict | what it said | what changed after it |
|---|---|---|---|
| 1 | `WITNESS_FAIL` | `blind` was unknown for `absent_atom:st_lane_enters`, not for the masked `dev.governs`; `branch_10`'s trace was not producible (a `Build.sparseUser` in `occupancy_observed` has no footprint) | Added `¬ same c j` to `signErectedAtAnEntrance`, so the junction region is not read as one of its own entrances (where `st.lane_enters` is unrecorded and therefore unknown). Replaced the sparse-user scene with a full-geometry one. |
| 2 | `VACUOUS` | obligation leaf 11 `rel_occupies [u, j]` and leaf 12 the headway comparison did no work in any decided witness | Restructured the clearance test (see below) so that a breach of the duty no longer entails the hazard; modified `branch_9` and added `branch_11`, `branch_12`. |
| 3 | `WITNESS_FAIL` | `branch_11`'s trace was not producible: a structure without a boundary where occupancy is observed | Rebuilt `branch_11` with the junction outlined as usual and the van's **motion** unobserved instead (its outline and pose are mapped, its speed and velocity are not). |
| 4 | `OK` | — | — |

## Why leaf 11/12 were vacuous, and what I changed

The first writing followed the record's st2 convention literally: the hazard was
`distance ≤ speed·p.yield_headway_time ∨ (centres' closest approach < clearance) ∨ (nearest-point
gap < clearance)`, and the duty was `¬contact ∧ ¬(centres' closest approach < clearance)`. Under
that shape every breach of the duty *implies* the hazard — contact means a nearest-point gap of
zero, and a centre conflict is itself a hazard limb — so "which are within the intersection"
(`rel_occupies u j`) and the headway comparison can never decide a verdict: no scene exists in
which they are the only thing protecting a vehicle whose duty is breached. The two atoms are
claimed and used; the dead leaves came from the overlap between ob1's protected set and ob1's
breach conditions.

I resolved it inside the record's own words rather than by dropping a reading. ob1's justification
names all three atoms for "yielding" (`prim.closest_approach_within`,
`prim.closest_approach_distance` *and* `rel.surface_gap` "measures between the nearest points of
the bodies"), so the nearest-point figure now measures the **clearance of the duty**:

- `clearanceBreached` (ob1) = the two draw together within `p.yield_conflict_horizon` **and**
  (centre distance at that closest approach `<` `p.yield_min_clearance` **or** present
  nearest-point gap `<` `p.yield_min_clearance`);
- `immediateHazard` (st2) = ground distance to the junction `≤` the vehicle's own speed `×`
  `p.yield_headway_time` **or** the centres' closest approach below the clearance.

Every atom and parameter of both operationalizations is still read, and each limb is now
exercised by a decided witness.

## Choices the node left open (declared as `narrowings`)

1. **ob1 — how the clearance is measured.** No primitive gives the closest approach between the
   *nearest points* of two bodies; `prim.closest_approach_distance` gives the centre distance. The
   duty is breached where either that centre figure or the present nearest-point gap
   (`rel.surface_gap`) falls below `p.yield_min_clearance`, and only while the two draw together
   (`prim.closest_approach_within`): a road user moving away is granted precedence.
2. **st2 — two figures, read as alternatives.** The distance-to-junction bound and the conflict
   figure each alone make an approach an immediate one. The nearest-point figure is not read a
   second time here; it measures the duty's clearance, so the protected set is decided by the
   approach and not by the breach.
3. **ob1 — the duty at every junction the selection picks.** A region bound in the applicability is
   not in scope in the obligation, so the obligation quantifies universally over regions of kind
   `st.intersection` and rewrites the whole selection (the subject's footprint on the junction, its
   moving, a stop or yield sign at one of the junction's entrances) as the guard.
4. **ob1 — the protected vehicle's approach carrier** is a travel region other than the junction
   itself.

Not narrowings, and not declared as such (both are the contracts' own content, explained in the
rule's header): that the junction is not among its own entrances in c1 (`st.lane_enters` is the
entry topology of a carrier running into an intersection), and the record's own observable
readings for s1 and c1, which stay on the plan's record.

Other decisions the record left to the writing, all carried as the record maps them (no narrowing,
since they are trigger/condition/exception spans): e1 is read with both limbs the justification
names — a police officer or a traffic signal governing the junction itself (`same cc j`) or the
subject's own approach carrier (`st.lane_enters` + `rel.occupies`) — with "traffic" as a road user
of `DEF-NRS-484A-285::traffic` whose footprint overlaps that junction; c1 as an existential over the
entrances of that junction, the sign's presence being its erection; c3 as occupancy of the junction
with speed above `p.standstill_speed_tolerance`.

## Witnesses

The four planned ones plus the three planned branches, and five more so that every leaf moves a
decided witness: `branch_4` the yield-sign limb of c1; `branch_5` the police officer on the
junction; `branch_6` the traffic signal on the subject's own approach carrier; `branch_7` a yield
sign on the other vehicle's carrier; `branch_8` a hazard through the conflict figure alone (van
40 m from the junction, beyond the headway bound); `branch_9` a hazard through the headway bound
alone with a contact while the centres draw apart; `branch_10` the compliant path with a protected
vehicle present; `branch_11` a vehicle protected only because it lies within the junction (its
motion unobserved, so both hazard limbs are unknown); `branch_12` a clearance breached by the
nearest-point figure while the centres stay three metres apart.

## Why I finished

The gate returned `OK` on run 4 of 6: the rule builds and checks, every claimed atom, primitive and
parameter is read and every claimed name is used, no leaf is vacuous, and all 16 witnesses carry the
verdicts their narratives state. Nothing in the node looked wrong to me: the only defect I found was
the redundancy between ob1's protected set and its breach conditions described above, which the
record's own justification for ob1 let me write out without changing the reading. No
`dependency_defect.json` — the node calls no concept.
