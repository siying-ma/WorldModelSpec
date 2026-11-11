# NRS_484B_250_4_o1 — task result

**Final verdict: OK** (11 witnesses, 18 names, composes nothing; 1 narrowing declared by the coder). 4 of 6 gate runs used.

## Gate runs

1. **UNUSED_CLAIM** (every claimed name). I ran this one by mistake on the harness's skeleton, before writing anything, so it wasted a run. Then I wrote the rule and the witnesses.
2. **WITNESS_FAIL**: every witness except branch_3 was "not one the adapter can produce". Lane c and intersection i listed `ways` (highways 30/31) that existed only in branch_3's scene. Fix: `ways` is now set only in the scene that maps the highways (`wayScene`).
3. **VACUOUS** on two obligation leaves:
   - `dev_governs d c`: it can only move a *violated* witness. Fix: in branch_1 (violated), d now governs c instead of i.
   - `prim_region_offset_along x i c > 0`: this is in the approach-start test for place (3), and no violated witness used place (3). Fix: added branch_6 (violated). In it, x halts 6 m short of i where no crossing way is in view, then enters i.
4. **OK**.

## How the rule is written

- **Class:** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (`approach i c`)** has these parts:
  - x enters i (`drv_motion_entering_region`).
  - x is on carrier c, a region of kind `travel_region`, with `st_lane_enters c i`.
  - Some `traffic_signal` d that governs i or c is `dev_inoperative`.
- **Obligation:** the halt is owed at the place the words name, in their order. Each place is reached only when the earlier ones are excluded: some stop line marks c, or no stop line marks c and a crosswalk does, or neither marks c.
  - Each place's halt is searched for with `since (¬boundary) halt`.
  - The boundary is either the approach start, or x's exit from i after a previous entry. The approach start is x on c, not on the place, short of it along c, and farther from it than `p.stop_point_tolerance`.
  - Place (3) also accepts a halt farther upstream when s8 holds: a highway that i lies on and c does not is in view for at least `p.intersection_sight_distance` (`st_sight_along_way`).
- **Several carriers:** where x enters i through several carriers, the rule takes `definedWhen (every ∨ ¬some) every`. So the verdict is decided where all carriers agree and unknown where they differ, as the record requires.

## Choices the node left open

1. **c ≠ i (`.not (.same c i)`).** Intersections are a `travel_region`, so the carrier quantifier also ranges over i itself. On i, `st_lane_enters i i` reads no lane record and is therefore unknown, which would have made the applicability and obligation unknown. An intersection is the region a carrier runs into, never its own approach. This is not a narrowing, because it is not a choice among the words' meanings; it is explained in the rule header.
2. **Narrowing (s4, kind `reading`).** The "previous entry into i" bound is read at x's exit from i after that entry (`rises (¬ rel_occupies x i)`). The language has no "previous observation" operator, and the current entry would otherwise end its own search. As a result, a halt made while x still overlaps i after a previous entry does not count for this entry.

## Remark for the plan (not a blocker)

For place (3), the record's history bound cancels most of the sight alternative ("or farther upstream where the crossing way is in view"). A halt outside the 2 m stopping zone is itself outside the zone, so any later observation still outside the zone starts a new approach and the halt is owed again. The sight alternative therefore counts only when the next observation is already inside the zone; branch_3 shows this case. If the plan wants a halt at a sight point farther upstream to count, the stopping zone for place (3) needs to be redefined.

## Why I finished

The gate returned OK on both files.
