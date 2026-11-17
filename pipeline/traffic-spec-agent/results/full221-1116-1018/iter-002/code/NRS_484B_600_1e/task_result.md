# NRS_484B_600_1e — task result

**Final verdict: OK** (4 witnesses, 2 names, composes nothing)

## Gate runs
1. `OK` on the first run. Nothing changed afterwards.

## How the rule is written
- Binder `subject` class (g2): `.atom "ru_aggregate" [subject, .lit "DEF-NRS-484A-320::vehicle"] []`.
- Applicability: `.tt`. The only condition span, g4 ("In any event,"), is a residue in the node that adds no condition. The binder class alone decides whether the rule applies.
- Obligation (g1 + g5): `kin_speed(subject) ≤ 80 mph`. The text forbids a speed *greater than* 80 mph, so the duty is "not greater than". The literal is written as `Units.mph 80` in `.metrePerSecond`.
- Operationalizations, assumptions, intentions, compositions: none (the node declares none).

## Choices left open
- None. The g1 reading through controlled motion (kin.speed) is the node's own observable_reading narrowing. It is not restated, and I added no narrowing of my own.

## Witnesses
Each witness is one road user, track 1, heading east, over 3 instants 1 s apart. The witnesses use no structures or devices.
- forbid: motor vehicle at 38 m/s (≈85 mph, above the bound of ≈35.76 m/s). Expected violated.
- permit: motor vehicle at 33 m/s (≈74 mph). Expected compliant.
- idle: pedestrian at 1.4 m/s. The aggregate decides false. Expected not applicable.
- blind: motor vehicle with its speed field unset and `kin.speed` masked in the manifest. Expected unknown.

## Why I finished
The gate returned OK on the first run.
