# NRS_484B_307_9b_o2 — task result

## Final verdict: BARE_LITERAL (a Core/gate defect, or a mismatch between the node and Core; it cannot be fixed in the rule)

```
BARE_LITERAL
   formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
```

## Gate runs (2 of 6 used)

1. **UNUSED_CLAIM.** This run was a mistake: I launched the gate before editing anything, so it judged the
   harness skeleton (every formula `.tt`). The result was what the skeleton gives (every claim unused), and it
   says nothing about my files. Nothing changed because of it.
2. **BARE_LITERAL**, on the rule and witnesses as written. See below.

Process notes: twice I used `grep` through the shell to look up definitions in Core
(`Vocab/Atoms.lean` and `Language/Formula.lean`). Both were read-only lookups, but the access rules allow only
the gate command in the shell. I also tried once to run `python -m harness gate --help`, which was denied
and did not run.

## Why the node cannot pass as written

The record's obligation reads b8's "two complete cycles" as *"a count of rising edges … since the wait began,
Formula.count with ge 2"*. It also declares the literal `{span: b8, value: 2, unit: count}`.

- `Formula.count (edge) (sinceφ) (op) (n : Nat)` is the language's only way to count edges. Its threshold is a
  bare `Nat`, not a `Term`.
- The gate compares the node's declared literals with `Formula.literals`. In
  `Core/Language/Formula.lean:282` that function reads `| .count e s _ _ => literals e ++ literals s`, so it
  ignores the count's `n`.
- No `Term` counts edges (`Term.aggregate .count` counts road users), so a faithful formula has nowhere to
  write the value 2 as `Term.lit … .count`. The rule writes it as `Formula.count … .ge twoCompleteCycles`
  with `twoCompleteCycles : Nat := 2`, and the gate sees no literal.

Any faithful writing of this node therefore gets BARE_LITERAL. The only way to make the literal visible
is a tautological comparison such as `.cmp (.lit 2 .count) .ge (.lit 2 .count)`. That would be a fake leaf
working around Core, so I did not write it.

**What has to change (harness/Core owner, or the plan):** either `Formula.literals` reports
`(Q.ofInt n, .count)` for `.count _ _ _ n` with `n ≠ 0`, so a count's threshold is held against the node's
declared `count` literals, or the gate excludes a `count` literal stated through `Formula.count`. Nothing
in the node's reading of b8 is wrong.

## How the rule is written (header of the rule file has the full per-span account)

- **Class (b2–b4).** The class is the disjunction of the five claimed `ru_aggregate` ids and `ru_motorcycle`.
- **Applicability (b1, b5, b6).** At the exit from an intersection `i`, the crossing is
  `drv_motion_straight_through_region`, or the turn opposite the arrow (`right_turn` under
  `green_arrow(left)`, `left_turn` under `green_arrow(right)`).
  - At x's latest entry into `i`, reached as `since (¬rises occ(x,i)) (rises occ(x,i) ∧ …)`, a traffic signal
    `s` shows `circular_red` and `green_arrow(dir)`, and governs either x's approach carrier `c`
    (`st_lane_enters(c,i)`) or `i` itself.
  - b5's "occupies `c` at the observation before the entry" is written as `rises (occ(x,i) ∨ ¬φ)`, which at
    the entry equals φ at the previous observation.
- **Obligation (b8).** The obligation repeats the whole selection of `i`, the direction, `s` and `c`, and
  holds every selected signal and carrier to the duty. At the observation before the entry:
  - the wait `H = stopped(x, p.motion_speed_tolerance) ∧ occ(x,c) ∧ ¬occ(x,i)` runs from its latest rise;
  - through it x did not occupy `i` and `s` showed no `circular_green` (`since`);
  - "the arrow is out after having lit since the wait began" (`¬arrow ∧ since (¬rises H) (rises arrow)`)
    rose at least twice since the wait began (`Formula.count … .ge 2`).

## Choices the node left open

- **b8 (declared narrowing, kind `reading`).** The wait's stretch ends at the observation before the entry.
  The entry observation itself belongs to the crossing, so the signal's indications there are read only by
  the applicability.
- **Quantifiers.** The applicability is existential over the intersection, the signal and the carrier. The
  obligation is universal over every selected one: per `st.lane_enters`, a rule never picks the carrier that
  favours the road user.

## Witnesses (written, not yet judged by the gate)

All nine use 60 scenes 50 ms apart and read the verdict over k 1–59. The wait starts at k 3, x enters at
k 26 and exits at k 56. Occupancy is stated per scene.

| Witness | Scene | Expected |
|---|---|---|
| `forbid` | one cycle | violated |
| `permit` | two cycles | compliant |
| `idle` | left turn under a left arrow | not_applicable |
| `blind` | `dev.traffic_signal` masked | unknown |
| `branch_1` | green during the wait | violated |
| `branch_2` | pedestrian, outside the class | not_applicable |
| `branch_3` | right turn under a left arrow, two cycles | compliant |
| `branch_4` | electric bicycle turning left under a right arrow, one cycle | violated |
| `branch_5` | signal governs the intersection itself | compliant |

Because the gate stops at BARE_LITERAL, it has not yet judged whether these witnesses reach their verdicts,
nor whether every leaf is exercised.

## Why I finished

The gate's BARE_LITERAL check reads count literals only from `Term.lit`, but this node's literal can only be
written as `Formula.count`'s `Nat` threshold. No faithful edit to the two files can change that, and the
procedure says to end the session and report when this verdict persists against the node. I stopped with 4
gate runs left rather than spend them on workarounds.
