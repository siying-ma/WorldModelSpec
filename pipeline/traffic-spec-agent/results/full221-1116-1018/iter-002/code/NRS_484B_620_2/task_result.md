# NRS_484B_620_2 — task result

**Final verdict: OK** (13 witnesses, 13 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` (dev_governs, dev_speed_limit_sign, dev_zone_sign, kin_speed). This run was on
   the harness skeleton before I made any edit. I started it by mistake, and its command also had a
   `| head -5` pipe added. After it I wrote the rule and the witnesses.
2. `OK`. Nothing changed after this run.

## The rule
- Class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- t3 (on the road): `.not (.asm "asm.within_incorporated_city")`.
- The region selection is the same in the applicability and in the obligation (t1 + t4). It is a
  `travel_region` r that meets all of these:
  - the subject occupies r (`rel_occupies`);
  - r lies on a `highway` h (`st_on_way r h`);
  - a `zone_sign` z governs r (`dev_governs`), its kind is `speed_zone` (`dev_zone_sign_kind`), and it is not an end sign (`¬dev_zone_sign_end`).
- Applicability: the place is on the road (t3), and some selected r is governed by a `speed_limit_sign` of kind zone or maximum.
- Obligation (t5): for every selected r and every speed limit sign s of kind zone or maximum that governs r, `kin_speed subject ≤ dev_speed_limit_sign_value s`.

## Choices the node left open
None. I added no narrowing: the record's three narrowings already cover the readings (t1 status,
t2 agency, t5 sign kinds), so the rule's `narrowings` list is empty.

## Witnesses
The five planned ones are forbid, permit, idle, blind (masks `kin.speed`) and branch_1 (place
inside a city → n/a). I added eight more so that every leaf is exercised:
- branch_2: the zone sign is an end sign → n/a.
- branch_3: the lane lies on no highway → n/a.
- branch_4: the only speed limit sign is a minimum sign → n/a.
- branch_5: the zone sign is of kind school → n/a.
- branch_6: the signs govern a lane the car does not occupy → n/a.
- branch_7: the road user is a bicycle → n/a.
- branch_8: a maximum sign of 30 and a zone sign of 20, car at 25 → violated.
- branch_9: only a maximum sign of 20, car at 25 → violated.

## Why I finished
The gate returned OK.
