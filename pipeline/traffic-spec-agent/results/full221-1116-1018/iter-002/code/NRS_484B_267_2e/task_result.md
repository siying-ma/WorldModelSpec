# NRS_484B_267_2e — task result

**Final verdict: OK** (20 witnesses, 28 names, composes nothing). 3 of 6 gate runs used.

## Gate runs
1. **UNUSED_CLAIM** on the untouched skeleton: every claimed name was listed, as expected for `.tt` placeholders. I spent this run by mistake before writing anything.
2. **VACUOUS** after writing the rule and 18 witnesses. Four obligation leaves did no work:
   - leaf 0, `ru_aggregate e authorized_emergency_vehicle` inside the windowed selection;
   - leaves 28–30, the head-on adjacency limb (opposed directions, shared roadway) inside the *candidate-lane* exclusion.

   Fix: I added two witnesses.
   - `branch_15` (compliant): a bicycle with a red flashing lamp in the lane next to the subject, and the regulatory vehicle in a lane that is not adjacent.
   - `branch_16` (compliant): like `branch_4`, but a truck inside the headway gap blocks the subject's right lane. Only the head-on exclusion keeps the subject's own lane from being a clear candidate.
3. **OK**.

## How the rule is written
- **Subject (s5):** `ru_aggregate subject DEF-NRS-484A-320::vehicle`, moving (speed > `p.halt_speed_tolerance`).
- **Selection of e (s1, s3/s4, s10):**
  - e is not the subject.
  - e is either an authorized emergency vehicle (the aggregate) or an `ru_official_vehicle` with kind `regulatory_agency`.
  - e shows `sig_warning_lamp e red flashing`.
  - e is moving, or preparing to move: `rel_visible` from the subject and (hand signal ≠ `no_signal` or turn indicator ≠ `off`).
  - e is ahead (`rel_bearing … ahead`) at a centre distance ≤ `p.emergency_approach_reach`.
- **Exception (s6):** a `human_direction` device with role `police_officer` governs a `travel_region` that the subject occupies.
- **Obligation (s7/s8/s9):** applies to every e whose selection has held throughout `holdsFor .time p.emergency_lane_change_window`, every lane e occupies and every lane the subject occupies. The subject's lane must not be adjacent to e's lane, or the move is excused.
  - **Adjacent:** a left or right neighbour, or both lanes have ordinal one, their directions have a negative dot product, and some roadway is occupied by both vehicles.
  - **Excused:** ice or snow; or visibility below the subject's speed × the window; or no candidate lane is open and clear.
  - **Candidate lane:** on the same highway, positive direction dot product, not adjacent to e's lane.
  - **Open and clear:** no temporary traffic control governs the lane, and every other road user in it has a surface gap ≥ the subject's speed × headway. The headway is ice, else wet/precipitation, else dry, written with `Term.cond`.

## Choices the node left open
- **"Within the approach reach"** is inclusive (≤). **"Below"** for both the gap and the visibility is strict, so "clear" means ≥.
- **"Ordinal one"** is written `ordinal × ordinal = ordinal`. Ordinals count from 1 (st.lane_adjacency contract), so this holds exactly at 1. The node declares no literal, and I wanted to avoid an undeclared count literal `1`. The plan should declare `1` (count) as a literal so it can be written directly.
- **The windowed selection** covers e's selection (`eSel`). It does not include the subject's own movement, which stays in the applicability.
- **No narrowings were declared.**

## Defects to report (the plan or Core must act; I did not work around them)
1. **s3/s4 "visible from the front": Core cannot read the lamp's facing.** `Semantics.evalAtomE` reads `sig_warning_lamp` only as `[x, colour]` or `[x, colour, mode]`, and `atomArgSorts` allows at most two literals. No formula can state *facing front*. So the trigger is written as `sig_warning_lamp e red flashing`, which is weaker than the record's "red, flashing, facing front".
   - This is a trigger span, so I could not narrow it.
   - The words *are* in the atom's contract, so `no_atom` would be false. This is a gap in the Core evaluator, not in the node's mapping.
   - Needed: a `[x, colour, mode, facing]` reading of `sig_warning_lamp` in Core. Alternatively, the plan records that facing is unobservable and the rule reads colour and mode only.
2. **The run's reading of `DEF-NRS-484A-020::authorized_emergency_vehicle` includes no class.** `ru.emergency_vehicle`, `ru.fire_apparatus` and the others are all unresolved. As a result, no witness or trace can ever decide that a police car is a member: the limb is always unknown or false.
   - For that reason the witnesses use a regulatory-agency official vehicle wherever the narratives say "police car" (forbid, permit, blind, branch_1–3).
   - The verdicts and situations are otherwise the planned ones.
   - On real data, any scene with a police car and no regulatory-agency vehicle will come out unknown, not violated or compliant. The reading, or the node's choice of aggregate over `ru.emergency_vehicle`, should be revisited.

## Witnesses beyond the plan
| Witness | Expected | Scene |
|---|---|---|
| `branch_5` | not applicable | Police officer directing traffic in the subject's lane |
| `branch_6` | violated | Halted vehicle with a visible arm signal |
| `branch_7` | violated | Halted vehicle with its turn indicator lit |
| `branch_8` | compliant | Lanes 3 and 4 closed by temporary traffic control |
| `branch_9` | violated | e in the lane to the subject's right |
| `branch_10` | compliant | Wet road; traffic at about 50 m (inside the wet gap) |
| `branch_11` | compliant | Precipitation; same traffic as `branch_10` |
| `branch_12` | violated | Dry road; traffic at about 70 m (beyond the dry gap) |
| `branch_13` | compliant | Fog, visibility 80 m |
| `branch_14` | not applicable | A bicycle with a red flashing lamp is the only lit vehicle |
| `branch_15` | compliant | Described under gate run 2 |
| `branch_16` | compliant | Described under gate run 2 |

All witnesses are judged over 7–9 s, where the 6 s look-back is covered.

## Why I finished
The gate returned **OK**. The two defects above are reported for the plan and Core to act on.
