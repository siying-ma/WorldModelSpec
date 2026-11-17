# NRS_484B_307_2a — task result

## Final verdict
**OK** (7 witnesses, 14 names, composes nothing). Gate runs used: 1 of 6.

## Gate runs
1. `OK`: first run, on the rule and witnesses as written. Nothing changed after it.

## How the rule is written
- **Class (s2/s5):** `ru_aggregate subject DEF-NRS-484A-285::traffic` ∧ `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability (s1, s2, s3):** there exist an intersection `i`, a travel region `c` and a traffic signal `d` such that:
  - `st_lane_enters c i`, and
  - `dev_governs d c`, and
  - `d` shows `circular_green` and none of the other 22 state spellings (one negated disjunction), and
  - `since (rel_occupies subject i) (rel_occupies subject c)`.
- **Obligation (s6–s10):** the obligation re-binds `i`, `c` and `d` with the applicability's whole selection, using `forallRegion`/`forallDevice` with `implies`. Under that selection, for every road user `u` that is not the subject:
  - `u` is a party when it is a vehicle or pedestrian aggregate member, and it occupies `i` or occupies a crosswalk `x` with `st_entrance_of x c2` and `st_lane_enters c2 i`.
  - For every party, it is not the case that `kin_speed subject > p.halt_speed_tolerance` while either:
    - `prim_closest_approach_within(subject,u;p.conflict_horizon)` holds and `prim_closest_approach_distance(subject,u;p.conflict_horizon) < p.conflict_centre_clearance`, or
    - `rel_contact(subject,u)` holds.
- **s4:** a residue (the node's).

## Choices the node left open
- **"Alone" (s1):** this means no other state spelling is shown. I counted the `unknown` state as "another state", so a head showing green and `unknown` together does not count as green alone. s1 is a trigger and cannot be narrowed, so I am recording this here rather than as a narrowing.
- **"occupies c, or occupies i continuously since occupying c" (s2/s3):** I wrote this as one Core `since`. Core's `since` is `ψ ∨ (φ ∧ since')`, so it is exactly the record's two cases. This is not a narrowing.
- **Narrowings:** none declared.

## Witnesses
The map has:
- an intersection, (0,0)–(20,20);
- a northbound approach lane governed by the signal;
- an eastbound approach lane from the west;
- a west crosswalk marking that lane's entrance.

The scenarios:
- **forbid:** the subject turns west at 6 m/s and gets to about 0.99 m of a pedestrian in the crosswalk.
- **permit:** the subject halts in the intersection until the pedestrian has left the crosswalk. While it moves with a party present, the approach is outside the 3 s horizon.
- **idle:** the signal shows red.
- **blind:** the signal is masked.
- **branch_1:** the subject is alone.
- **branch_2:** the signal shows green plus `green_arrow(left)`.
- **branch_3:** an oncoming vehicle in the intersection comes to about 1.72 m in 1.2 s.

## Process note
I ran one shell command (`ls` of the Core directory) besides the gate command, to find which Core file to read. It changed nothing.

## Why I finished
The gate returned `OK` on the first run.
