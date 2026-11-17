# NRS_484B_260 — task result

**Final verdict: OK** (6 witnesses, 13 names, composes nothing). 2 of 6 gate runs used.

## Gate runs
1. `CHECK_FAIL` — `obligation: measure rel_bearing: component`. I had written s6's "subject ahead
   of v" as `.measure "rel_bearing" [v, subject, "longitudinal"] > 0`. The measure only takes the
   `x`/`y` component selectors, so it rejected `"longitudinal"`. I replaced it with the Boolean atom
   `.atom "rel_bearing" [v, subject, .lit "ahead"] []`, which is exactly "longitudinal component of
   the bearing from v to the subject, in v's frame, > 0" (`rel_bearing_ahead`, Vocab/Atoms.lean).
2. `OK`.

## How the record is written
- Class (s1): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s2, s3):
  - the subject is moving: `kin_speed subject > p.halt_speed_tolerance`
  - it occupies no `alley` region
  - ∃ `highway` h, ∃ `roadway` r, ∃ `driveway_or_alley_entrance` e such that:
    - `st_on_way r h`
    - the subject occupies r and occupies e
    - `since (occ e) (occ e ∧ ¬occ r)`: it came onto the entrance from off the roadway
- Obligation (s4, s5, s6):
  - ∀ h, r, e: the same selection (on_way, both occupancies and the `since`) is written again in
    full and implies the following:
  - ∀ users v: if v is not the subject, is in the vehicle aggregate, has `kin_speed` above the
    halt tolerance, occupies some `travel_region` t with `st_on_way t h`, and has the subject
    `rel_bearing … "ahead"`, then:
    - `¬rel_contact subject v`, and
    - ¬(`prim_closest_approach_within` over `p.conflict_horizon` ∧
      `prim_closest_approach_distance` < `p.conflict_centre_clearance`).
- The duty is required for every selection, as the record says ("for every selection … re-bound
  in full"). The obligation's selection does not repeat the subject's own conditions (moving, no
  alley), because they do not select h, r or e and the applicability already requires them.

## Choices the node left open
- None that narrows a span; `narrowings` is empty. The only free choice was how to spell "subject
  ahead of v": I used the bearing atom's `"ahead"` selector, which means exactly what the record
  states.

## Witnesses
- **Setting:** three instants, 1 s apart. The subject heads north at 2 m/s out of driveway entrance
  e. At the third instant it straddles e and roadway r, which lies on highway h. Vehicle v drives
  east at 10 m/s in lane L, which is on h.
- **forbid:** v is 20 m short of the crossing point. The centres come closest after ≈1.98 s at
  ≈0.98 m, which is a conflict.
- **permit:** v is 100 m away, so the closest approach is ≈9.7 s out, past the horizon.
- **idle:** the subject drives along r and never occupies e.
- **blind:** the forbid trace with `st.on_way` masked.
- **branch_1:** the forbid trace without v.
- **branch_2:** the forbid trace, but the subject also occupies an alley region.
- Occupancy is stated explicitly in every scene.

## Why I finished
The gate returned OK on both files.
