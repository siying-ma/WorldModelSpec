# LVMC_11_52_030_B — task result

## Final verdict: WITNESS_FAIL (the node's two exception branches can't be reached under the run's reading)

## Gate runs
1. Skeleton, unchanged (by mistake I piped the command into `head` on this run): `UNUSED_CLAIM`
   (dev_governs, dev_zone_sign, drv_motion_complete_halt, prim_conditions_hold). This was expected for `.tt` placeholders.
2. A second, accidental run on the unchanged skeleton (it went to the background and its output was not read).
   No change was made between runs 1 and 2.
3. Rule and witnesses written: `WITNESS_FAIL`
   - branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-070::commercial_vehicle, aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]
   - branch_2: same
   forbid, permit, idle, blind and branch_3 all pass.

## The rule as written
- Class (s1): `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- Applicability: `∃ curb_zone z. rel_occupies(subject, z) ∧ st_curb_zone_colour(z, yellow)` (s2/s3)
  ∧ ¬( commercial ∨ taxicab ). Here commercial is `ru_aggregate(subject, DEF-LVMC-11-02-070::commercial_vehicle)`
  and taxicab is `ru_aggregate(subject, DEF-LVMC-11-02-140::taxicab)`, each ∧ `∃ zone_sign d. dev_zone_sign_kind(d, parking_restricted)
  ∧ (∃ travel_region r. dev_governs(d, r) ∧ rel_occupies(subject, r)) ∧ prim_conditions_hold(d, subject)` (s4–s7).
- Obligation (s3): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`. It is judged only at observations
  where the subject occupies the yellow zone, so the halt judged is a halt in z.
- I chose no narrowings. The record states every element, so the node left no choice open.

## Why branch_1 and branch_2 can't pass (a defect in the reading, not in the Lean)
The run's reading classifies both exception aggregates with **no included class**:
- `DEF-LVMC-11-02-070::commercial_vehicle`: included (none); every vehicle class is unresolved.
- `DEF-LVMC-11-02-140::taxicab`: included (none); every vehicle class, ru.taxicab included, is unresolved.

`ru_aggregate` (Core `Vocab/Atoms.lean`) is true only when the user carries an included class. With none included,
the atom is unknown for every vehicle and never true. So the s4/s6 exceptions can never be decided true. A commercial van or a
taxicab that halts within the sign's conditions makes the applicability `yellow ∧ ¬unknown` = unknown, not
not_applicable. The node itself plans branch_1 and branch_2 as not_applicable, and they can't reach that.
The formula is the record's; the only way to make the branches pass would be to replace the admitted aggregates
with ru.commercial_motor_vehicle or ru.taxicab. Both the record and the hard rules forbid that.

**What must change (reading / plan):** the reading of the two aggregates must resolve the classes the
definitions name:
- DEF-LVMC-11-02-140::taxicab should at least include `ru.taxicab`.
- DEF-LVMC-11-02-070::commercial_vehicle should include the classes its definition covers (e.g. `ru.commercial_motor_vehicle`, `ru.truck`).

If the definitions really don't settle membership, the plan must re-plan branch_1 and branch_2 as unknown or withdraw them. The witnesses are
built as the narratives state:
- branch_1: van of classes motor_vehicle + commercial_motor_vehicle, Tuesday 10:00, sign legend Mon–Fri 08:00–18:00, class commercial_motor_vehicle.
- branch_2: taxicab in a taxicab_stand yellow zone, sign legend class taxicab, any time.

In both, the sign's conditions hold (prim_conditions_hold true). Only the aggregate atom keeps the verdict unknown.

## Choices the node left open
None of substance. These are witness-only choices:
- Sign legend windows: Mon–Fri 08:00–18:00.
- Vehicle class on the freight sign: `commercialMotorVehicle`, so the private car of forbid fails the condition. The exceptions are then decided false for it, even though its commercial and taxicab membership is unknown.
- branch_3's Sunday: weekday 6.

## Why I finished
The only remaining failure comes from the reading's classification of the two exception aggregates. I can't fix it
in the two files without writing the exceptions with weaker or different atoms than the record states, which the rules forbid.
Three of six gate runs were used; two were wasted by my own command mistakes, not by changes to the files.
