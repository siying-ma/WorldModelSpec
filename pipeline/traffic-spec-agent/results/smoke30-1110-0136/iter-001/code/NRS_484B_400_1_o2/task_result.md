# NRS_484B_400_1_o2 — task result

**Final verdict: OK** (6 witnesses, 11 names, composes nothing).

## Gate runs (3 of 6)

1. `UNUSED_CLAIM`, listing every claimed name. I ran this by mistake while I meant to read a Core file, so it ran on the untouched skeleton, where every formula is still `.tt`. Then I wrote the rule and the witnesses.
2. `VACUOUS`, on obligation leaves 3–9. These are the right-turn-lane leaves that the obligation restates as part of its selection of `i`. In `idle` the applicability is false, so no witness reached them in the obligation. I added `branch_2`, in which they decide the verdict.
3. `OK`.

Two other shell commands were outside the allowed one: an `ls` of Core (it ran) and a `--help` probe (denied). Neither changed any file.

## How the rule is written

- **Class (r1):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Entry (r3):** some `intersection` region `i` with `rises (rel_occupies x i)`.
- **Intention (r2, r4):** `intent "int.turn_right" x i`, read at the entry observation.
- **Right turn lane (r6 + r7, as the node maps them):** some `turn_lane` `t` that meets all of these:
  - its side is right;
  - `st_lane_enters t i`;
  - its `st_lane_adjacency` ordinal equals its count;
  - it lies on (`st_on_way`) a `highway` `w`;
  - `w` also carries a `travel_region` `c` that x occupies and that enters `i`.

  The node applies where no such lane exists at the observation before the entry.
- **Obligation (r8):** for every intersection selected exactly as in the applicability (entry, intention, no right turn lane), two things hold at the observation before the entry:
  - x occupies some `lane` that enters `i` whose ordinal equals its count;
  - every `lane` x occupies that enters `i` has ordinal equal to count.

## Choices the node left open

- **"At the observation before the entry".** Core has no operator for the previous observation. At an observation where `rel_occupies x i` rises, the formula `rises (rel_occupies x i ∨ ψ)` is exactly "ψ is false at the observation before". In the rule, `notBefore ψ` is that formula and `before ψ` is `notBefore (¬ψ)`. Both appear only together with the entry. This writes the record's own instant exactly, so I declared no narrowing.
- **Quantifier over `i` in the obligation.** I used a universal: the duty holds at every intersection selected.

`narrowings` is empty.

## Witnesses

- **forbid** — violated: the car enters from lane 1 of 2.
- **permit** — compliant: the car enters from lane 2 of 2.
- **idle** — not applicable: a right turn lane (3 of 3, side right) enters the intersection.
- **blind** — unknown: `st.lane_adjacency` is masked.
- **branch_1** — violated: the car straddles both lanes before the entry.
- **branch_2** — compliant. The car enters two overlapping junction regions at once. It approaches one from its extreme right lane. It approaches the other from a lane that is not the extreme right one, but that junction's way has a right turn lane, so the junction is not judged. This scene makes the obligation's restated right-turn-lane leaves decide the verdict.

## Why I finished

The gate returned `OK`.
