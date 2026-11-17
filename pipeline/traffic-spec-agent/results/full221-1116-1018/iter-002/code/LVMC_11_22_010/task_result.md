# LVMC_11_22_010 — task result

## Final verdict: OK

## Gate runs
1. `OK` — 5 witnesses, 6 names, composes nothing; 1 coder narrowing. Nothing changed after it.

(Two stray shell calls before the gate run: a no-op `echo` and an attempted `--help` invocation of
the gate, which was denied. Neither touched any file; noted for transparency.)

## The rule
- Class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (h3): `kin_speed(subject) > p.halt_speed_tolerance`.
- Obligation (h2, h4): for every road user `o` other than the subject:
  `not rel_contact(subject, o)` and
  `rel_ahead_behind_in_lane(o, subject) → not (prim_closest_approach_within(subject, o; p.attention_ttc_min)
   ∧ prim_closest_approach_distance(subject, o; p.attention_ttc_min) < p.conflict_centre_clearance)`.

## Choices the node left open
- **`same` guard**: `o` ranges over every road user, the subject included; `rel_contact(subject, subject)`
  is true (a footprint overlaps itself), so the subject is excluded with `.not (.same o subject)`.
- **Argument order of `rel_ahead_behind_in_lane`**: Core's `rel_ahead_behind_in_lane a b` is "a ahead of b",
  so "o ahead of the subject" is written `(o, subject)`.
- **Narrowing (h4, kind `reading`)**: the record's obligation says "in contact with no road user and no
  structure", but Core's `rel_contact` takes two tracks, so contact is read only against other road
  users. Contact with a structure is not read. If the plan wants that limb, it needs an atom that
  relates a track to a region; `rel.contact` has no region form in the accessor table.

## Witnesses
One eastbound lane; passenger cars measuring 5 m × 2 m; scenes every 0.1 s.
- forbid: the subject is at 10 m/s and a halted car is 14 m ahead. The centres meet in 1.2–1.4 s
  (under the 1.5 s threshold) at 0 m (under the 3 m clearance), with no contact. Result: violated.
- permit: the car ahead is 30 m away and both move at 10 m/s, so there is no relative velocity and no
  approach. Result: compliant.
- idle: the subject is halted at a red signal (speed 0). Result: not applicable.
- blind: the forbid geometry with `kin.speed` masked. Result: unknown.
- branch_1: the subject is alone in the lane at 10 m/s. Result: compliant.

## Why I finished
The gate returned OK on the first run.
