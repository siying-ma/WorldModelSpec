# NRS_484B_227_1_o2 — task result

## Final verdict

**OK** (6 witnesses, 9 names, composes nothing).

## Gate runs

1. `OK`: this was the first run, so nothing changed after it.

## The rule

- **Class of x (a1):** `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- **Applicability (a2):** some `highway` region h satisfies `selection h`, which has two parts. First, some `median_or_divider` region d lies on h (`st_on_way(d, h)`). Second, x occupies (`rel_occupies`) a `roadway` region or a `median_or_divider` region that lies on h.
- **Obligation (a5, with a7/a8/a9 as the record's "unless"):** for every `highway` h that meets the same `selection h` (written out again in full), the following must hold:
  - **Either one of the exceptions applies:**
    - x occupies a `median_or_divider` region that lies on h and carries the opening attribute (`st_median_or_divider_opening`; this covers both the opening and the crossover).
    - x occupies an `intersection` region that lies on h.
  - **Or both of these hold:**
    - (a) x occupies no `median_or_divider` region that lies on h.
    - (b) x occupies no `roadway` region w that lies on h while `drv_motion_against_carrier_direction(x, w)` holds, using `p.speed_resolution` and `p.opposed_direction_cosine`.
- **Narrowings:** none declared. I added no reading beyond the record. Its own narrowings on a1, a5 and a9 are not restated, as the rules require.

## Choices the node left open

- **Where the exceptions go:** a7, a8 and a9 are written in the obligation, as the record's obligation text places them ("unless …"). They are not in the applicability.
- **"Re-binding h with the same selection":** I wrote this as the duty at every selected highway (`forallRegion` with `implies selection`). x occupies a roadway or median of only one highway, so this is the same h the applicability selects.
- **Variable names:** each quantifier variable gets its own name (d, r, m, o, i, s, w).

## Witnesses

All six run on one geometry: a divided highway running east–west with an eastbound and a westbound roadway. The dividing section between them is cut into regions without an opening plus one opening region. A north–south highway crosses it, and the two meet in an intersection.

- **forbid:** the car drives north across a median region that has no opening. The instant on the median is violated.
- **permit:** the car crosses through the opening region and then drives west on the westbound roadway. This exercises the opening exception.
- **idle:** a U-turn on an undivided highway, where no dividing section lies on the way. The verdict is not applicable.
- **blind:** `rel.occupies` is masked, so the verdict is unknown.
- **branch_1:** a U-turn within the eastbound roadway, ending with the car moving west on it. Violated through limb (b).
- **branch_2:** a U-turn inside the intersection, with one instant moving north-west (cosine −0.8 to east) on the eastbound roadway inside the intersection. Compliant only because of the intersection exception.

## Why I finished

The gate returned `OK` on the first run.
