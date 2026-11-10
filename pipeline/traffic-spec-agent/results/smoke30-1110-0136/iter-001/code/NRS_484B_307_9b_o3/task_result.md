# NRS_484B_307_9b_o3 — task result

**Final verdict: OK** (9 witnesses, 15 names, composes nothing)

## Gate runs

1. **Skeleton, output discarded (my error).** I ran the gate command piped to `head -0` instead of
   the exact command, on the untouched skeleton. Its verdict was not seen, and it may have used one run.
2. **UNUSED_CLAIM (skeleton, my error).** I ran the gate again before writing anything. It listed
   every claimed name as unused, which is what the placeholder `.tt` formulas give. A third
   non-gate command was also attempted and denied by the permission layer; it did not run.
3. **WITNESS_FAIL.** Every turning witness was rejected as a trace no adapter can produce: the
   heading stayed fixed while the yaw rate turned it 3° per interval. The harness takes the rate at a
   scene to apply over the interval before it.
   Change: the trajectories were rebuilt. The yaw rate is nonzero on scenes 6–35 (after the entry at
   scene 5). The heading is rotated 3° per step (sin/cos of multiples of 3° in 10⁻¹² fixed point,
   Taylor series). Positions are integrated along the heading. The exit is moved to scene 38, after
   two scenes in which the body straddles the intersection and the exit lane.
4. **BUILD_FAIL.** Nat/Int mismatches in the fixed-point helpers. Fixed with explicit `Int` casts.
5. **WITNESS_FAIL (blind only).** The verdict was unknown because of `absent_atom:dev_zone_sign_conditions`.
   Masking `dev.regulatory_sign` only adds the kind to every device's `unobservedKinds`, so the
   signal head becomes a candidate regulatory sign. Its `conditions` is `none`, and
   `prim_conditions_hold` reports that as `dev_zone_sign_conditions`, an atom the manifest does not mask.
   Change: in the blind scene the signal head carries `conditions := some {}` (a face with no legend
   restriction). Only the masked kind and the code stay unknown.
6. **OK.**

## How the rule is written

- **Class of x (b2–b4):** the five admitted aggregates (`ru_aggregate` with each id) or `ru_motorcycle`.
- **At the entry:** `atEntry φ := since (¬ rises (occupies x i)) (rises (occupies x i) ∧ φ)`, which
  reads φ at the observation where x's overlap with i last became true. This is the past operator
  the record names.
- **Facing the signal (b1, b5):** at the entry, some `traffic_signal` s shows `circular_red` and
  `green_arrow(dir)`, and governs either i or a `travel_region` c that x occupies and that enters i
  (`st_lane_enters c i`).
- **Applicability:** ∃ intersection i such that all three hold:
  - (b1/b5) red with a left or right arrow;
  - (b6) straight through, or a right turn under a left arrow, or a left turn under a right arrow;
  - (b11) a left or right turn.
- **Obligation (b10):** for every intersection i:
  - a right turn opposite a left arrow → at the entry, no `regulatory_sign` coded `no_right_turn`
    that governs i or the approach and whose `prim_conditions_hold` holds;
  - a left turn opposite a right arrow → the same with `no_left_turn`.

  Each case repeats the applicability's whole selection of i: the turn concept and the signal at
  the entry.

## Choices the node left open

- **Straight concept's `max_angle`:** the node names no bound for a straight crossing. I passed
  `p.left_turn_min_angle`, the threshold below which a crossing is not a turn. It decides no verdict:
  b11 requires a turn, and a turn excludes a straight crossing.
- **Turn concepts:** `min_angle` is that side's turn minimum and `max_angle` is
  `p.reversal_min_angle`. The step is `p.heading_since_step_carla_scene_graph`.
- **Approach carrier:** read as one x occupies at the entry, following the record's applicability
  ("at its entry"). The element justifications say "the observation before entry", but a body that
  is entering straddles the carrier and the intersection.
- **No narrowings declared.** These choices are on trigger and condition spans or are parameter
  bindings, and none narrows the words.

## Witnesses

| name | expected | scene |
|---|---|---|
| forbid | violated | as planned |
| permit | compliant | as planned |
| idle | not applicable | as planned |
| blind | unknown | as planned |
| branch_1 | violated | left turn under red + green_arrow(right); signal and a `no_left_turn` sign govern the intersection itself |
| branch_2 | not applicable | left turn with the left arrow (the turn the arrow permits) |
| branch_3 | compliant | the forbid turn; the `no_right_turn` sign is restricted to trucks, so its conditions do not hold |
| branch_4 | not applicable | the forbid turn under circular_green + green_arrow(left) |
| branch_5 | compliant | the forbid turn with a `no_left_turn` sign |

Every witness uses window 50–2200 ms, which leaves out the first scene, where `rises` and `since`
look back past the trace start.

## Notes for the harness and Core

- **Core reason quirk:** for any device with `conditions = none`, `prim_conditions_hold` reports
  `absent_atom:dev_zone_sign_conditions`. That includes a device that may be a regulatory sign only
  because `dev.regulatory_sign` is masked. A blind witness masking `dev.regulatory_sign` therefore
  needs every other device's legend set. Core could name the reason after the kind actually read.
- The record's gap on b3 ("trimobile") stands. It is written with `ru_motorcycle` as the record maps it.

## Why I finished

The gate returned OK on the sixth run.
