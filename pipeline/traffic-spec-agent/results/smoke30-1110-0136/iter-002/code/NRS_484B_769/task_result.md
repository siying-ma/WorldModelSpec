# NRS_484B_769 — task result

**Final verdict: OK** (8 witnesses, 5 names, composes nothing)

## Gate runs
1. `OK`: the first run, so nothing changed after it.

## How the node was written
- **Class of x (c1–c3):** `ru_aggregate x "DEF-NRS-484A-025::bicycle"` ∨ `ru_aggregate x "DEF-NRS-484B-017::electric_bicycle"` ∨ `ru_aggregate x "DEF-NRS-484B-018::electric_scooter"`.
- **Applicability (c4):** `existsRegion (lit "roadway") r (rel_occupies x r)`. The quantifier kind `roadway` carries st.roadway, and kinds that refine it, such as a one-way roadway, are covered.
- **Obligation (c5, with c6 borrowed):** `(sig_turn_indicator x left → sig_hand_signal x left) ∧ (sig_turn_indicator x right → sig_hand_signal x right)`.
- **Exception (c7):** c7 is carried by the right limb of the obligation. A right-arm signal reads as `sig_hand_signal right`, which is the same leaf as the right-turn posture of the borrowed manner. The exception adds no applicability condition.

## Choices the node left open
- I made no choice beyond the record's own narrowings, so `narrowings` is empty.
- In the class of x, I used the aggregate ids directly as literal arguments, as rule 3 requires.

## Witnesses
The road is a roadway rectangle with a sidewalk next to it, separated by a 2 m verge. In every scenario the rider moves east over three instants. All seven planned witnesses are built to their narratives. I added `branch_4` (compliant): a bicycle with its left indicator on and a left arm signal. It exercises the case where a lamp signal is matched by a decided arm signal of the same meaning.

## Why I finished
The gate returned `OK` on the first run.
