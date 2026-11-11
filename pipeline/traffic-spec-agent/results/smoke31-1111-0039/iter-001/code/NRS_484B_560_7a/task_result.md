# NRS_484B_560_7a — task result

**Final verdict: OK** (7 witnesses, 11 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs
1. `UNUSED_CLAIM drv_motion_entering_region`: the applicability called only
   `drv.position.within_clearance_since_entry`, which reaches the entry concept internally. The gate
   wants the claimed concept named in the formula itself. Change: the applicability became
   `∃ r : railway_crossing, entering_region(x, r) ∨ within_clearance_since_entry(x, r, 15 ft)`.
   By the clearance concept's contract ("It becomes true at an entry"), the disjunct adds no
   instant. It writes the element's words: crossing from the entry until it has completely crossed.
2. `OK`.

## The rule
- Class: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (s2, s4): some railway crossing r that x has entered, or is entering, and is still
  within 15 ft of (`Units.feet 15`, the text's literal) since that entry.
- Obligation (s3): `¬ halted(x, p.speed_resolution)`, or some human direction d with role
  `police_officer` and indication `stop` that governs a travel region l x occupies.

## Choices the node left open
None beyond the record's own narrowings. No narrowing was added. The only writing choice was the
redundant entry disjunct above, which the `UNUSED_CLAIM` check forced. It is explained in the
rule header.

## Witnesses
- The roadway is region 10 and the crossing is region 20, from x = 0 to 6 m. The car is 4.5 m long.
- Occupancy is stated from the car's outline.
- Each trace starts more than 12 m short of the crossing, so the first observation decides "not entered".

The scenes:
- **forbid:** the car halts on the crossing, with a truck queued beyond it.
- **blind:** the same as forbid, with `kin.speed` masked.
- **permit:** the car crosses at 5 m/s and halts with its rear end 16.75 m past the crossing.
- **idle:** there is no crossing; the car halts at a stop line.
- **branch_1:** the car halts with its rear end 2 m past the crossing, which is under 4.572 m.
- **branch_2:** as forbid, but a police officer directing stop governs the roadway.
- **branch_3:** the car halts alone with its rear end 6 m past the crossing.

## Why I finished
The gate returned OK.
