# LVMC_11_46_030_o2 — task result

**Final verdict: OK** (8 witnesses, 14 names, composes nothing)

## Gate runs
1. `WITNESS_FAIL` — blind: unknown for `window_truncated:since`, not for the masked `dev.governs`
   (the trace also set `governsObserved := false`, so it was unknown even with nothing masked).
   Change: in the blind trace, the guard shows `proceed` at the first instant so the past the
   `since` reads is decided false there. It shows `stop` after that. What the guard governs is left
   observed in the scene, so the manifest mask alone makes the verdict unknown.
2. `OK`.

(An earlier stray shell call with `--help` was denied by the permission layer and never ran. It did
not count as a gate run.)

## Rule
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability: there is a travel region g that the subject occupies, a highway w with
  `st_on_way(g,w)`, and a crosswalk c with `st_on_way(c,w)` that is the nearest one ahead. In
  addition, either a `crossing_warning_signal` d or a `human_direction` d satisfies
  `since(warns(d) ∧ ahead(c), complete_halt ∧ st_region_geometry_distance(subject,c) ≥ 50 ft ∧ warns(d) ∧ ahead(c))`.
  Here `warns(d)` is `dev_governs(d,g) ∧ active(d)` for the signal and
  `dev_governs(d,g) ∧ indication(d, stop)` for the person. `ahead(c)` is
  `prim_region_offset_along(subject,c,g) > 0`.
- Obligation: `drv_motion_complete_halt(subject)` with `p.halt_speed_tolerance`.

## Choices the node left open
- **"Nearest"**: c is the nearest crosswalk ahead when no crosswalk c2 on w that is ahead along g
  has a smaller `prim_region_offset_along` than c. I used the same offset the record uses for
  "ahead". This span is a condition, so I did not declare it as a narrowing. It is explained in the
  rule header.
- **"Removed / left the locality"**: the device quantifier ranges over the devices present at the
  judged observation. A device that has left the scene therefore no longer satisfies the
  applicability.
- I declared no narrowings.

## Witnesses
- The planned ones are forbid, permit, idle, blind and branch_1–3.
- I added **branch_4** (not_applicable). It has a nearer crosswalk c1 within fifty feet of the
  halt, while c is more than fifty feet away. Without it, the "nearest" condition would have no
  witness that exercises it.
- Every applicable trace starts with the subject already halted under the warning, or with the
  warning off. That way the `since` is decided at the first instant and no witness is unknown
  because its window is cut off at the start of the trace.

## Why I finished
The gate returned OK on the second run.
