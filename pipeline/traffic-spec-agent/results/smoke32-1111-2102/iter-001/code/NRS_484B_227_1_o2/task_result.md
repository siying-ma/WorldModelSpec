# NRS_484B_227_1_o2 — task result

**Final verdict: OK** (6 witnesses, 8 names, composes nothing). 2 of 6 gate runs used.

## Gate runs
1. **VACUOUS** — obligation leaves `st_on_way r h` and `rel_occupies ego r`, from the roadway limb of "ego upon h", which I had restated in the obligation's re-selection of `h`. That limb cannot change the obligation's value. The duty's antecedent ("ego overlaps a median or divider lying on h") already implies "ego upon h" through its median limb.
   *Change:* the obligation now re-selects `h` only as a divided highway (`divided`: some median or divider lies on `h`). It no longer repeats `upon`. The header comment explains this.
2. **OK**.

## How the rule is written
- Class (d1): `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- Applicability (d2): there is a highway `h` with some median or divider on it (`st_on_way md h`), and ego's footprint overlaps a roadway or a median or divider lying on `h` (`st_on_way`, `rel_occupies`). The kinds `st.highway`, `st.roadway`, `st.median_or_divider` and `st.intersection` are written as region quantifier kinds.
- Obligation (d5, d7, d8): for every divided highway `h`, and for every median or divider `m` on `h` that ego overlaps, one of these holds:
  - `st_median_or_divider_opening m` (d7, and d8's crossover limb), or
  - ego also overlaps an intersection `i` lying on `h` (d8).

## Choices the node left open
- **Re-selecting `h` in the obligation (rule 3c):** I kept "divided highway" but dropped "ego upon h" (see gate run 1). This loses nothing, because the duty's antecedent includes it.
- **No narrowings declared.** The record's own agency and status readings are not restated.

## Witnesses
- **Layout:** a highway at y ∈ [-12, 12], an eastbound roadway at [-10, -2], a median at [-2, 2] and a westbound roadway at [2, 10], all on the highway.
- **forbid / blind:** ego crosses the median northbound, which has no opening. In blind, `rel.occupies` is masked.
- **permit:** ego stays on the eastbound roadway.
- **idle:** the same layout without a median.
- **branch_1:** the median has `opening := some true`.
- **branch_2:** an intersection on the highway, x ∈ [-15, 15], covers the median where ego crosses it.

## Why I finished
The gate returned OK.
