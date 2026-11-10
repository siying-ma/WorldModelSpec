# NRS_484B_227_1_o2 — task result

## Final verdict
**OK** (6 witnesses, 7 names, composes nothing).

## Gate runs
1. `OK`: first run, so nothing changed after it.

## Rule as written
- **Class (s1):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s2):** some `highway` region `h` with `rel_occupies(x, h)`, and some `median_or_divider` region `m` with `st_on_way(m, h)`.
- **Obligation (s4, with s6 and s7 as its consequent, as the record writes them):** for every `median_or_divider` region `m`,
  if `rel_occupies(x, m)` and m lies on a highway that `x` occupies, then either
  `st_median_or_divider_opening(m)` holds or some `intersection` region `i` has `rel_occupies(x, i)`.
  Rule 3c needs the obligation to state the highway selection again in full, so it does.

## Choices the node left open
- None needed a narrowing. The record states the applicability and the obligation in full.
  The record's own observable readings (s2 agency, s7 status) are carried as they are and are not restated.
- One structural choice: in the applicability, `m` only shows that the highway is divided. The obligation
  quantifies over every divider that x occupies, which follows the record's `forallRegion`.

## Witnesses
The highway is region 10. Medians are regions 11, 13 and 14 and lie on 10. The intersection is region 12.
- `forbid`: the car crosses median 11 (opening false) and occupies no intersection, giving **violated**.
- `permit`: the car travels east on the south roadway and occupies only the highway, giving **compliant**.
- `idle`: the highway has no median and the car crosses its centre line, giving **not applicable**.
- `blind`: like `permit` but beside the median, with `rel.occupies` masked, giving **unknown**.
- `branch_1`: the car crosses through median section 13 (opening true), giving **compliant**.
- `branch_2`: the car clips the nose of median 11 (opening false) while inside intersection 12, giving **compliant**.

## Why I finished
The gate returned `OK` on the first run.
