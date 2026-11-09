# NRS_484B_223_1b — coding session result

## Final verdict

**OK** — `15 witnesses, 16 names, composes nothing; narrowings declared by the coder: 1`
(gate run 3 of a budget of 6).

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `VACUOUS` — two leaves did no work: (a) `st_lane_marking` in the applicability (“one of 2 literal variants of this atom; none exercised”), (b) `obligation leaf 68`, the comparison over `prim_closest_approach_distance` | (b) `branch_8` was rebuilt so the closest-approach test alone decides it: the lorry it moves up to stands still 60 m ahead in the lane entered, so the entry clearance is met at both observations of the movement (60 m and 40 m against a bound of 32 m) while the centres close to within a metre inside the horizon at the second. Earlier the clearance failed at the second observation and the conflict test never decided. (a) `branch_10` was added: the middle lane carries no marking on either side, so the movement out of it is not a crossing of a marked side and the duty does not bind (compliant). |
| 2 | `VACUOUS` — only the applicability's own `st_lane_marking` leaf remained: in `branch_10` the rule is still engaged through the marked left-hand lane, so that leaf never decided an episode | `branch_11` added: a carriageway whose map records no marking on any side of any of its three lanes, so no lane the subject occupies is a clearly marked lane, the trigger fails and the rule does not engage (`not_applicable`). |
| 3 | **OK** | nothing; report written. |

The rule built, passed `Rule.check` and carried every witness at the first run: both repairs were
to the witness set, none to the formulas.

## Witnesses

The node's seven (`forbid`, `permit`, `idle`, `blind`, `branch_1…3`) keep their planned verdicts
and narratives. Eight more exercise the leaves the planned scenes do not reach:

| name | verdict | what it exercises |
|---|---|---|
| `branch_4` | compliant | the third limb of the signal requirement: the car crosses the double solid centre line into the westbound carriageway, which is no neighbour of the lane it leaves, so the indication it gave counts |
| `branch_5` | violated | “or lies alongside the subject” in the standard's filter: a van abreast in the right-hand lane, the longitudinal component of the gap zero |
| `branch_6` | compliant | that the clearance is read to the lane entered, not the lane left: a van follows 8 m behind in the middle lane |
| `branch_7` | compliant | `sig.hand_signal` as the indication, with the indicator off |
| `branch_8` | violated | the closest-approach test alone (entry clearance met at every judged observation) |
| `branch_9` | compliant | the right-hand limbs of the signal and of the marked-side test: a movement into the right neighbour with the right indicator |
| `branch_10` | compliant | the marked-side test in the obligation: the lane left is unmarked, so no duty arises |
| `branch_11` | not_applicable | the marking in the trigger: no lane of the carriageway is marked, so the rule does not engage |

Every trace is eight observations one second apart; each witness names the instants it speaks
about (`window` = 3000 … 7000 ms), because the duty looks back over
`p.turn_signal_advance_window`: at those instants the window behind reaches recorded
observations, so no verdict rests on a truncated history and `blind` is unknown only for the atom
its manifest masks.

## What the node left open, and what I chose

1. **“until the driver has given the appropriate turn signal”, where the lane entered is no
   neighbour of the lane left.** The record admits “either indication given for the side the body
   moves towards”. No atom this node claims reads the side the body moves towards, so the third
   limb of `signalGiven` accepts either indication — the indicator showing left or right, or an
   arm signal meaning left or right — within the window behind the movement. An indication is
   still required; only the side it names is left open. **Declared as the session's one narrowing,
   on s3** (the span the record itself carries the look-back reading on), and explained in the
   rule's header.

2. **The marking “on the side the movement crosses” (s1).** Which side the movement crosses is not
   a fact of a single observation: it follows from the regions the subject has moved between, which
   only the obligation reads. So the applicability carries the lane's own marking (a marking of a
   type other than none on a side) and the obligation's antecedent carries the record's whole
   qualified fact: the marking of the side crossed — left where the lane entered is the left
   neighbour, right where it is the right neighbour, either where it is no neighbour
   (`crossedSideMarked`). The duty therefore binds exactly the crossings of a side the map marks,
   and no observation is read more weakly than the record states it; the only difference is that a
   lane marked on the other side alone engages the rule and reports compliance rather than
   not-applicable (`branch_10`). Not declared as a narrowing: a trigger is never narrowed, and the
   qualified fact is carried in full.

3. **The occupancy of the lane “at the observation before the movement” (s3).** The applicability
   selects `L` by present occupancy (`rel_occupies`); the obligation restates the whole selection
   and takes that one part of it from `drv.lane.lane_change` itself, whose contract is that the
   footprint “overlapped the region at the observation before”. This is what lets the duty be
   judged at the observation at which the subject has left `L` altogether (`branch_4`), which the
   record's “at each observation at which the subject moves out of such a lane L” requires.

4. **“one direction” (s1, `st.lane_direction`).** Read where it does work on the regions the duty
   compares: a lane is the neighbour the duty reads only where it is designated for travel in the
   direction of the lane left (`sameDirectionAs`), so the lanes counted and the lane entered are
   lanes of one direction.

5. **“traffic” (s1).** The admitted aggregate `DEF-NRS-484A-285::traffic` is read of the subject
   travelling in the lanes the trigger counts: the lanes are lanes for traffic travelling in one
   direction because the subject occupying and travelling in them is traffic.

6. **“lies alongside the subject” (s5).** Written with the standard's own atoms as the longitudinal
   component of `rel.surface_gap` being zero: the component is never negative, so zero is exactly
   the case of two bodies abreast.

## A defect of the node to report to the plan agent

The node's own obligation says that where the lane entered is no neighbour of the lane left,
“either indication given **for the side the body moves towards** counts”. The side the body moves
towards is a fact the ontology can state (the signed lateral offset of the region entered from the
subject is a primitive of the surface), but the node claims no atom, primitive or concept for it on
s3 or s4. I did not write it with an unclaimed name; I wrote the limb in the broadest reading the
words allow (either indication counts) and declared the narrowing. If the plan agent wants the side
read, s4's element (or s3's) must claim the primitive that reads it.

## Why I finished

The gate returned `OK` on the third of six runs: the rule builds, its static check is clean, every
atom, primitive, concept and parameter the node claims is used and nothing else is, every literal
is the text's two or zero, and all fifteen witnesses reach the verdicts they name with no leaf
left idle. The node's declarations (`laws`, binder, assumptions, intentions, operationalization,
residues, surrogate) are the harness's, untouched; the one narrowing above is the session's and is
on record in the rule.
