# LVMC_11_52_030_B — task result

**Final verdict: VACUOUS** (the node and its reading are wrong; see below). Gate runs used: 2 of 6.

## Gate runs

1. **UNUSED_CLAIM**: I ran this on the harness skeleton before I had edited anything (all `.tt`), which used up one run. Every claimed name was reported unused, as expected.
2. **VACUOUS**: `applicability leaf 2: atom ru_aggregate [subject, "DEF-LVMC-11-02-070::commercial_vehicle"] (one of 2 literal variants of this atom; none exercised)`. Every other leaf was exercised, and all eight witnesses matched their expected verdicts.

(Before the first gate run I also tried to run the gate command with `--help` and a pipe. The sandbox denied it and it did not run. It was not a gate run.)

## How the rule is written

- Class (s1): `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Zone (s2/s3): `∃ z : curb_zone. st_curb_zone_colour(z, yellow) ∧ rel_occupies(subject, z)`.
- Accompanying sign (s5/s7): `∃ d : zone_sign. dev_zone_sign_kind(d, parking_restricted) ∧ (∃ r : travel_region. dev_governs(d, r) ∧ rel_occupies(subject, r)) ∧ prim_conditions_hold(d, subject)`.
- Exceptions (s4, s6): each is a membership (`ru_aggregate` with `…070::commercial_vehicle` or `…140::taxicab`) **and** the sign formula. In the applicability they are `¬exc1 ∧ ¬exc2`.
- Obligation: `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`. The record says the halt is judged where the applicability holds, so the yellow-zone location stays in the applicability and is not repeated.
- I made no narrowings of my own. I made one structural choice: one shared sign formula used in both exceptions, which is what the record says.

## Witnesses

There are eight: forbid, permit, idle, blind, branch_1 and branch_2 as planned, plus two I added:

- **branch_3** (violated): the sign governs the lane across the street. This exercises `dev_governs` and `rel_occupies(subject, r)`.
- **branch_4** (violated): a school zone sign whose conditions hold. This exercises `dev_zone_sign_kind`.

All eight evaluate as expected.

## Why the node is wrong

In the run's reading, `DEF-LVMC-11-02-070::commercial_vehicle` and `DEF-LVMC-11-02-140::taxicab` have **no included class**. Every class that `DEF-NRS-484A-320::vehicle` includes is *unresolved* for both of them. As a result:

- For any subject that passes the binder class (a decided vehicle), both exception memberships are **unknown**, never true or false.
- In three-valued (Kleene) logic, if a formula is decided while one leaf is unknown, it stays decided whatever value that leaf takes. So a membership that is unknown in every admissible scene can never change a decided verdict.
- The only scenes where the membership matters are those where the sign's conditions hold. There the applicability, and so the verdict, is `unknown`. Rule 7 forbids a branch witness that expects `unknown`, so I did not add one.

No rule text and no witness can satisfy the adequacy check. This is not a coding defect.

**What the plan or reading agent must change** (spans s4 and s6, aggregates `DEF-LVMC-11-02-070::commercial_vehicle` and `DEF-LVMC-11-02-140::taxicab`):

- **Preferred fix:** the reading classifies at least one class as *included* in each aggregate where the definition's words allow it. For example, `ru.commercial_motor_vehicle` or `ru.truck` under commercial_vehicle ("a motor vehicle … used primarily for the furtherance of a commercial enterprise"), and `ru.taxicab` under taxicab (a licensed taxicab). Then a branch witness can show the exception excusing a halt (not_applicable).
- **Alternative:** if the definitions really cannot be resolved for any class, the plan accepts that s4 and s6 can never decide anything. It then withdraws them as a gap or residue instead of mapping them to atoms no witness can exercise.

## Why I finished

The only remaining failure is VACUOUS on the exception memberships, and no witness or rule change can fix it under the run's reading. Using more gate runs would not change the result. I left both files in their final, correct form, with all eight witnesses matching their expected verdicts.
