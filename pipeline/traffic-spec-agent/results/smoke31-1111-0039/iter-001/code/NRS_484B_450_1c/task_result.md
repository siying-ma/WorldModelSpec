# NRS_484B_450_1c — task result

## Final verdict

`UNANCHORED_VARIABLE` (on the user quantifier of span h5). The node is wrong at h5; the session ends here.

## Gate runs

1. `UNUSED_CLAIM` (every claimed name). By mistake I ran the gate on the untouched skeleton before writing anything. Nothing changed after it except that I then wrote the files.
2. `UNANCHORED_VARIABLE`: "the quantified variable `e` shares no atom with a binder, nor with a variable that does". I wrote the rule and ten witnesses (forbid, permit, idle, blind, branch_1 to branch_6), then stopped (see below).

That is 2 of 6 runs used.

## How the rule is written

- **h2 (class):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **h8 (applicability):** `existsRegion intersection i (rel_occupies x i)`.
- **h1:** `drv_motion_halted x [p.speed_resolution]`. The obligation is `¬halted ∨ conflict ∨ emergency ∨ directed`.
- **h3 + h4:** `existsUser y (¬ same y x ∧ ru_aggregate y "DEF-NRS-484A-285::traffic" ∧ rel_bearing x y "ahead" ∧ rel_surface_gap x y ≤ p.stopping_conflict_gap)`. The gap is read as a distance because the record names no component.
- **h5:** `existsUser e (ru_emergency_vehicle e ∧ (sig_warning_lamp e <colour> flashing|rotating, over all four colours ∨ sig_siren e))`.
- **h6:** In the obligation, the intersection is selected again by its whole selection, and the exception is required at every such intersection: `forallRegion intersection i (rel_occupies x i → directed i)`.
  - `directed i` is `existsRegion travel_region c ((same c i ∨ (rel_occupies x c ∧ st_lane_enters c i)) ∧ directsStopAt c)`.
  - `directsStopAt c` is true for any of these that governs `c` (`dev_governs`):
    - a human direction with role police_officer and indication stop;
    - a traffic signal showing circular_red, red_arrow (any direction) or flashing_red;
    - a stop sign.
  - Writing the "i itself or the carrier x entered i through" choice once over `c` means each device leaf appears only once.
- **Choice the record left open:**
  - Where x overlaps several intersections, I require the exception at each one (`forallRegion`). Each intersection x is in is a place the words name.
- **Narrowings:** none of my own.

## Witnesses

| Witness | Scene | Expected |
|---|---|---|
| forbid | x halted inside the intersection, nothing else present | violated |
| permit | x crosses at 10 m/s | compliant |
| idle | x halted in approach lane 2, 50 m short of the intersection | not applicable |
| blind | x halted at the intersection's edge, `rel.occupies` masked | unknown |
| branch_1 | a halted car 2 m ahead | compliant |
| branch_2 | a police officer directing stop governs the intersection | compliant |
| branch_3 | an emergency vehicle behind x with a red flashing lamp, siren silent | compliant |
| branch_4 | the same vehicle with its siren sounding and no lamp lit | compliant |
| branch_5 | a circular-red signal governs the intersection | compliant |
| branch_6 | a stop sign governs approach lane 2, which x's rear still occupies | compliant |

Branches 3 to 6 were added to reach the h5 and h6 leaves. Because the gate stopped at the anchoring check, it never ran these witnesses.

## Why I finished: the node is wrong at span h5

The node maps h5 ("or in compliance with law") to "a `ru.emergency_vehicle` showing `sig.warning_lamp` flashing or rotating or sounding `sig.siren` **is in the scene**". In Lean, that is a road-user quantifier whose variable has no relation to x or to the intersection. The gate rejects it as `UNANCHORED_VARIABLE`.

I could not anchor it within the record:

- Tying the emergency vehicle to x or to the intersection with a claimed anchoring atom (for example `rel_occupies e i`, or `rel_bearing` / `rel_surface_gap` between x and e) would add a condition the record does not state. That narrows an exception span, which the rules forbid.
- `rel_bearing` and `rel_surface_gap` are claimed only for the h3 standard and have no h5 parameter.
- Excluding x itself (`¬ same e x`) is also an unstated narrowing of the exception, and it is not an atom anyway.

**What the plan agent must change:** give h5's emergency vehicle a relation to the subject or to the intersection it is in, and claim the atoms and any parameter it needs. Examples:

- the emergency vehicle occupies the intersection x is in, or a carrier entering it (`rel_occupies`, `st_lane_enters`); or
- it lies within a stated distance of x (`rel_surface_gap` or `rel_centre_distance` with a new parameter).

Alternatively, withdraw h5 to its recorded gap (`Formula.haltRequired`) if no such relation states "in compliance with law".

Once h5 is anchored, the rest of the rule and its witnesses are written as above and should need only the h5 disjunct changed.
