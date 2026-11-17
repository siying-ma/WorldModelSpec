# NRS_484B_307_4b — task result

## Final verdict

**WITNESS_FAIL** — `branch_1: expected not_applicable, got violated`. All other witnesses pass:
forbid, permit, idle, blind, branch_2 and branch_3. No build, check, anchoring, claim, literal or
vacuity verdict was returned.

## Gate runs

1. **UNUSED_CLAIM** (skeleton as written: `dev_governs`, `dev_position`, `dev_traffic_signal`,
   `kin_heading` unused). This was a baseline run before any edit. I accidentally chained it with
   `head`/`ls`, but it still counted as one gate run. After it, I wrote the rule and the seven
   witnesses.
2. **WITNESS_FAIL**: the adapter refused every trace because the pedestrian head governed the
   crosswalk, which a device may not govern. The blind trace also had heading `none`, which leaves
   the footprint undefined. After it, the pedestrian head governs roadway 20, and the blind trace
   keeps the heading in the scene and masks `kin.heading` only through the manifest.
3. **WITNESS_FAIL**: `branch_1` gave violated, so NRS_484B_283_1d1 is decidedly not engaged. After
   it, I added four exploratory witnesses, each a variant scene with walk showing:
   - walk turning on at t = 1 s, with the pedestrian moving;
   - the pedestrian head nearer (10, −8), the pedestrian closer to the curb, and the head
     governing roadway and intersection;
   - the pedestrian head governing nothing;
   - the pedestrian head governing the intersection.
4. **WITNESS_FAIL**: all of those variants were also violated. After it, I tried four more
   variants:
   - a marked crosswalk with `entranceOf` observed;
   - the pedestrian head governing the approach lane;
   - a far-side sidewalk, with the head governing roadway, intersection and lane;
   - `dont_walk_flashing` after walk, with the pedestrian heading straight at the head.
5. **WITNESS_FAIL**: all variants were still violated: no 283 exception was engaged in any scene.
   I then removed the exploratory witnesses.
6. **WITNESS_FAIL**: final run on the clean files; only `branch_1` fails.

## How the rule is written (the choices the node left open)

- **s2:** the binder class is `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **s1 ("a green turn arrow alone"):** the head `s` (`existsDevice traffic_signal`) shows one of
  green_arrow(left), green_arrow(right) or green_arrow(u_turn). It also shows none of the other 20
  spellings of the enumeration: the circular indications, flashing red and yellow, dark, unknown,
  green_arrow(straight), and every yellow, red or flashing-yellow arrow.
- **s3 ("facing"):** let d = dev_position(s) − kin_position(subject) and h = kin_heading(subject).
  - The distance bound is |d|² ≤ reach·reach.
  - The angle bound h·d ≥ cos·|d| is written without a square root as
    (h·d)·|h·d| ≥ cos·|cos|·|d|². This is exact for either sign of the bound, because x ↦ x·|x|
    is increasing.
- **s4:**
  - **Control:** the head controls x (`existsRegion intersection`) by `dev_governs(s,x)`, or by
    `dev_governs(s,l) ∧ st_lane_enters(l,x)` for some l (`existsRegion travel_region`).
  - **The highway:** x lies on w (`existsRegion highway`, `st_on_way(x,w)`).
  - **Ψ(w):** some roadway r with `st_on_way(r,w) ∧ rel_occupies(subject,r)`.
  - **"At the previous observation Ψ did not hold":** the language has no previous-observation
    operator, so this is written as `rises Ψ ∨ (¬Ψ ∧ ¬rises ¬Ψ)`. That is equivalent to the
    previous-observation statement (and unknown at the first instant). The witnesses therefore set
    `window := (1000, 3000)`.
  - **Obligation:** for every s, x and w meeting the whole selection again, and every roadway r on
    w, `¬rel_occupies(subject, r)`.
- **s5:** the four compositions are written as `.not (.ruleApplies id [("subject","subject")])` in
  the applicability.
- **Narrowings:** none added. The record's own narrowing on s4 is not restated.

## Why I finished

The gate budget (6 runs) is spent. The one remaining failure is outside what my files can show
without seeing the composed rule.

`branch_1` is the plan's scenario: "the pedestrian head it faces displays walk:
NRS_484B_283_1d1 applies to it". I tested 9 scenes with walk showing (and one with walk followed by
`dont_walk_flashing`). They varied:

- where the pedestrian head stands (19 m or less ahead of the pedestrian, within about 7°);
- what it governs: nothing, the roadway, the intersection, the lane, or combinations;
- the onset of walk;
- a marked crosswalk with its entrance observed, and a far-side sidewalk;
- the pedestrian's speed.

In every one, all four of NRS_484B_283_1d1, 1d2, 1d3_o2 and 1d4_o2 evaluate **decidedly not
engaged**. The verdict is violated, not unknown, so some leaf of their applicability is decidedly
false for this pedestrian.

My rule's handling of the exception is the prescribed `.not (.ruleApplies …)`, and the gate finds
no fault with it. I cannot read the composed rules, so I cannot tell what scene they require.

**For the plan / repair session:** check what NRS_484B_283_1d1's applicability requires of a
pedestrian facing a pedestrian signal that shows `walk`. Its subject class, or how it ties the
pedestrian signal to the pedestrian, may never hold for a pedestrian scene built with the surface
given here. Note that the adapter refuses a device that governs a crosswalk. Then either:

- state in the node or in `branch_1`'s narrative the scene in which that rule is engaged, so the
  coder can build it; or
- if 1d1 cannot be engaged by a pedestrian, repair 1d1, or drop or re-plan `branch_1`.

The rule and the other six witnesses need no change.
