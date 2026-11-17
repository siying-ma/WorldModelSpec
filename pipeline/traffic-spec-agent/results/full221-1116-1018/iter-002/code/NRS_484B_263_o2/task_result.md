# NRS_484B_263_o2: task result

## Final verdict
`WITNESS_FAIL` (blind). **The node is wrong**: you can't build the `blind` scenario the plan asks for (masked `rel.bearing`, expected unknown) as an admissible trace. Details below.

## Gate runs
1. **Run 1 (my mistake).** I ran the gate command with a pipe attached (`… | head -5 >/dev/null; echo skip`), which breaks the "exactly this command" rule. The files were still the harness skeletons, and I never saw the output. It probably counted against the budget.
2. **Run 2: `CHECK_FAIL`.** `measure rel_bearing: component`. The measure form takes `x`/`y`, not `longitudinal`. I switched to the Boolean atom `rel_bearing v subject "ahead"`. Its accessor is exactly "longitudinal component positive", which is what the record says.
3. **Run 3: `WITNESS_FAIL`.** blind: expected unknown, got violated. `Mask.relation "rel.bearing"` drops only a *measured* bearing. Core recomputes the bearing from `kin.position` and `kin.heading` (`relFrame`), so masking the atom changes nothing.
4. **Run 4: `WITNESS_FAIL`.** I tried a blind trace where v's heading is unobserved and the source supplies a measured bearing. Admission rejected it: "track 2 is in occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is undefined".

After run 4 I put `blindTrace` back on the forbid geometry (admissible, builds) and stopped. On these files the gate will report blind violated. As far as runs 2–4 show, forbid, permit, idle and branch_1 pass. The gate seems to report only the first failure, so I can't confirm the adequacy check (VACUOUS).

## The rule as written
- **Subject class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** the subject is moving (`kin_speed > p.halt_speed_tolerance`), and some region c of kind `controlled_access` has `0 < sinceRise(E) ≤ p.merge_window`. E is `rises(occupies subject c) ∨ rises(¬ occupies subject c)`: an entry, or an exit right after an overlap. This is the record's "latest entry or exit".
- **Obligation:** for every `controlled_access` c with the same selection (rule 3c), and for every v that:
  - is not the subject,
  - belongs to the traffic aggregate and the vehicle aggregate,
  - has `kin_speed > p.halt_speed_tolerance`,
  - occupies c,
  - and has `rel_bearing v subject "ahead"`,

  the subject and v are not in contact, and it is not the case that `prim_closest_approach_within subject v [p.conflict_horizon]` and `prim_closest_approach_distance subject v [p.conflict_horizon] < p.conflict_centre_clearance`.
- **`kin.time`** is read through `Term.sinceRise`, which measures time on the observation instants. No explicit `kin_time` measure appears. The gate never reached the claim check, so I don't know whether it accepts this as a use of the claim.
- **Narrowings:** none of my own. Every choice above is in the record's applicability and obligation text.

## Witnesses
- **Layout:** carriageway c is x ∈ [0, 1000], y ∈ [0, 10]. All bodies are cars heading east at y = 5. Scenes are 1 s apart. The subject runs at 20 m/s from x = −30 and enters c at t = 2 s.
- **Windows:** every witness judges a window after the entry. Before the entry, `sinceRise` is unknown because the trace doesn't reach back far enough.
- **forbid:** v at 30 m/s closes from 20 m, then 10 m. Closest approach is reached in 2 s, then 1 s, at distance 0. Window t = 3–4 s.
- **permit:** v at the same speed, 25 m behind. No relative motion, so no approach within the horizon.
- **idle:** the forbid closing, but in window t = 13–14 s, which is 11–12 s after the entry.
- **branch_1:** the subject alone.

## Why I finished: the node is wrong
- **Span a4, planned scenario `blind` (masked `["rel.bearing"]`).** In Core, `rel.bearing` comes from a measurement only when the source can't compute it from v's position and heading. The rule also needs `rel.occupies v c` decided, and admission requires a footprint for every track whose occupancy is observed. A footprint needs position, a non-zero heading and an extent. So any trace that decides v's occupancy lets Core compute the bearing, and masking `rel.bearing` can't make it unknown. If v's occupancy is left unobserved instead, the unknown comes from `rel.occupies`, which isn't masked, and the gate rejects it.
- **What the plan agent must change:** mask an atom in blind that Core reads as a plain field and never recomputes. `kin.speed` would work: it is claimed in a2/a4 and read only from the speed field. The closest-approach primitives read `kin.velocity`, so the conflict stays decided. Then the applicability is unknown (subject speed), the v antecedent is unknown (v speed) and the consequent is false, so the verdict is unknown for the masked atom only. If whether v approaches must stay the undecided part, the blind scene needs some atom other than `rel.bearing` to leave it unknown.
