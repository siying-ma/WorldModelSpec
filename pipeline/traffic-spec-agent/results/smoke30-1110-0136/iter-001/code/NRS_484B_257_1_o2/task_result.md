# NRS_484B_257_1_o2 — task result

**Final verdict: OK** (13 witnesses, 21 names, composes nothing). Three of six gate runs used.

## Gate runs

1. **WITNESS_FAIL**: `blind` was unknown because of `absent_atom:st_lane_enters`, not because of the masked `st.on_way`. Cause: with y inside i, the intersection itself is a candidate `cy`, since the quantifier is over `travel_region` as the record names it and an intersection refines that kind. Core leaves `st_lane_enters` unknown for any region that records no entrance, and for `cy = i` nothing else in limb (a) is false. Fix: `blind` is now judged at x's entry, while y is still outside i on lane 12 (limb (b), conflict about 0.3 m in 2.3 s). The only unknown left is `st.on_way`.
2. **VACUOUS**: Two groups of leaves never changed a witness verdict:
   - Two applicability leaves had no witness: police governs c, and signal governs i.
   - The obligation's copies of the s1/s2 exception leaves were vacuous. The traffic-aggregate leaf can never move there, because every vehicle is also a member of `DEF-NRS-484A-285::traffic`.
   - The obligation's gap comparison for limb (b) was vacuous.

   Fixes:
   - The obligation now re-states the selection without the exceptions (see choices below).
   - `branch_8` (police directs c) and `branch_9` (an operating signal governs i) were added, both expecting not_applicable.
   - `branch_2` was shortened to end at x's entry, so its violation comes through limb (b) alone.
3. **OK**.

## Choices the node left open

- **Entry of the current occupancy.** This is the observation at which `rel_occupies x i` last rose. It is written as `since (occ x i) (rises (occ x i) ∧ occ x c ∧ …)`. The approach carrier c is a travel region with `st_lane_enters c i` that x occupied at that entry.
- **"Since it last came onto c, before the entry."** At the entry: `since (occ x c) (occ x c ∧ ¬occ x i ∧ (stopped ∨ (onlyYield ∧ speed ≤ p.yield_sign_check_speed)))`.
- **"Only a yield sign governs"** (a yield sign governs c or i, and no stop sign does). This is read at the observation of the slowing. Signs are static, so this decides the same as reading it at the judged observation.
- **Stop or yield sign governing (s3).** Read at the judged observation, as the applicability states.
- **Signal "not dark".** Written as `¬ dev_traffic_signal_shows d dark`, the state attribute of the claimed `dev.traffic_signal`.
- **Through highway (s14).** `existsRegion highway h` with `st_on_way cy h ∧ st_on_way i h ∧ ¬ st_on_way c h`.
- **Immediate hazard (s16).** `st_region_geometry_distance y i ≤ kin_speed y × p.immediate_hazard_time_gap`, a bound on a ratio written as a bound on a product.
- **Obligation.** It quantifies every i and c (`forallRegion`) under the re-stated selection, and every y under y's whole selection. The s1/s2 exceptions are not repeated in the obligation's re-selection, for three reasons:
  - they fix no region and no road user, only whether the rule is engaged;
  - the applicability already requires them absent at the entry;
  - repeated, their leaves are vacuous by construction.

  The only consequence: if x had entered i through two candidate carriers at once and only one of them were controlled, the obligation would also judge the vehicles owed through the controlled one. This is noted in the rule header.
- **No narrowings declared.** Every span that decides when the rule applies is carried as the node maps it.

## Observation for the plan and repair sessions (not a node defect)

Core gives `st_lane_enters` an unknown value for any travel region that records no intersection entrance. This covers the intersection itself and lanes that enter nothing. Because the record quantifies y's carrier `cy` over `travel_region`, the candidate `cy = i` makes limb (a), "y has entered i", unknown rather than false whenever y occupies i and no real through-highway carrier decides it.

In a scene where y occupies i but came from a non-through carrier, the applicability is therefore unknown, not false. I kept the kind the record names (rule 3b) and did not add an exclusion it does not state.

## Why I finished

The gate returned OK on the third run.
