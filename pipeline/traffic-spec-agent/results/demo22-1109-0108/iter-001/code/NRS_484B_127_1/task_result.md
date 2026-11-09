# NRS_484B_127_1 — coding session result

**Final verdict: `OK`** (`14 witnesses, 11 names, composes nothing; narrowings declared by the coder: 2`).

Files written: `library/TrafficSpec/Rules/NRS_484B/NRS_484B_127_1.lean`,
`library/TrafficSpecWitness/NRS_484B/NRS_484B_127_1.lean`. Nothing else was touched.

## Gate runs (budget 6, used 2)

| run | verdict | what changed after it |
|---|---|---|
| 1 | `WITNESS_FAIL` — `blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest masks` | The `blind` trace was rebuilt (see below). Everything else — the build, the static checks, the claims, the other 13 witnesses and the adequacy sweep — passed on the first run and was not changed afterwards. |
| 2 | `OK` | — |

### What run 1 taught, and why the blind scene has no map

`Formula.elimCond` rewrites a comparison over a `Term.cond` into
`(φ ∧ A) ∨ (¬φ ∧ B) ∨ (A ∧ B)`, so every guard of the bound becomes an operand of the obligation's
formula. An unknown guard therefore contributes its own reason to an unknown verdict, beside the
reason the masked atom gives.

That matters here because of a tie Core enforces: `rel.surface_gap` is unobservable for a pair only
where a footprint is (`Vocab/Atoms.lean`: it is computed from both footprints unless the source
supplies it, and a supplied value is what the mask drops), while `TraceLint.occupancy` requires every
track whose occupancy is observed to have a footprint. So a scene in which the gap cannot be read is
a scene in which some track's `rel.occupies` is unknown — and the bound's dense-traffic count reads
`rel.occupies` of **every** road user of the scene, so that guard went unknown and its reason leaked.

The fix keeps the node's masked set exactly (`rel.surface_gap`, nothing else) and removes the leak at
its source: the blind scene is recorded by a source that maps no road structure. With no highway
region in the trace, `existsRegion highway` is decidedly false, so both region-dependent guards (the
adverse geometry and the traffic count, which is then zero) are decided; the van carries no extent,
so no gap is computed from the bodies; the source supplies the gap (which the manifest drops) and
supplies that the van is ahead of the car in the lane, which Core cannot compute there because the
van's occupancy is unobserved — the only two relations the scene supplies, both of them ones Core
cannot compute. The duty is then unknown for the gap alone.

## Choices the node left open

Both are declared as `narrowings` on `s3` in the rule and explained in the file header; the record's
own narrowings (the agency reading of "the driver", the conditions-of-the-way list, the density
reading of "the traffic", the surrogate mark) are the plan's and are not restated.

1. **Where the condition of the highway and the traffic upon it are read.** The operationalization
   names `st.grade`, `st.curvature`, `st.highway` and `rel.occupies` but not which region carries
   them. Written as `existsRegion highway "h"` with `st_highway h ∧ rel_occupies v h` — the only tie
   the claimed names give between a way and the subject, and the anchor for both `h` and the counted
   `u`. Consequence: where the subject occupies more than one highway region, the adverse-geometry
   selection and the traffic count are read at *some* such region, not at all of them.
2. **Whether the subject is one of "the traffic upon the highway".** The count includes it: the
   posted definition covers every road user using the way for travel and names no exception for the
   one whose duty is judged. (With the reading's `p.following_dense_traffic_count = 5` this matters
   only at the margin; `branch_6` has six road users on the way.)

Other writing decisions, none of which narrow a span:

- `applicability := .tt`. The node states no trigger beyond the binder's class ("The duty has no
  further trigger"), so engagement is the class alone.
- The followed vehicle is quantified inside the obligation (`existsUser "w"`, with `.not (.same v w)`
  for "another"), so a subject alone in the scene is judged compliant rather than left unjudged, as
  the node's `obligation` requires.
- "reaches `p.following_dense_traffic_count`" is written `.ge`; "the excess … where that excess is
  positive" is written `.cond (speed v > speed w) …` with the zero branch in metres; the magnitude of
  the grade is `.abs` of `st_grade` (the curvature atom is already a magnitude).
- The bound's selections are written with `Term.cond` in the order the convention states
  (ice, then wet or precipitation, then adverse geometry, then dry), so a bound both branches agree
  on stays decided where a condition is not observed.

## Witnesses

The four planned scenes and the node's two branches, plus eight branch witnesses of my own, each
written to turn on one selection of the bound or one limb of the prohibition (all figures are the
witnesses', none appears in the rule):

| witness | expects | what it exercises |
|---|---|---|
| `forbid` | violated | wet headway: 20 m gap against a bound of 75 m |
| `permit` | compliant | dry headway: 90 m gap against 50 m |
| `idle` | not applicable | a pedal cycle is no vehicle of the definition, so nothing is bound |
| `blind` | unknown | the gap alone unreadable |
| `branch_1` | compliant | no other road user in the scene — the duty is decided for the subject alone |
| `branch_2` | violated | the closing-speed term (55 m gap, 50 m dry term, 72.5 m with the closing term) |
| `branch_3` | violated | the ice selection (90 m gap against 112.5 m) |
| `branch_4` | violated | the grade limb of the adverse-geometry selection (−6 per hundred; 60 m against 75 m) |
| `branch_5` | violated | the curvature limb (a 50 m radius; 60 m against 75 m) |
| `branch_6` | violated | the dense-traffic increment (six road users; 52 m against 55 m) |
| `branch_7` | violated | the precipitation limb of the wet selection (60 m against 75 m) |
| `branch_8` | compliant | the followed road user is not a member of the aggregate |
| `branch_9` | compliant | headings not aligned within the tolerance (a van standing at 45° in the lane) |
| `branch_10` | compliant | abreast in the next lane: no shared lane, so no following |

Core counts a comparison as one adequacy leaf (`Formula.leaves` does not descend into terms), so the
obligation has three leaves and the planned scenes already move all of them; `branch_3`–`branch_10`
are tests of the bound's branches rather than leaf coverage, and they are what would catch a
mis-selected headway or a dropped term in a later repair.

## Why I finished

The gate returned `OK` on run 2 of a budget of 6: the rule builds, its declarations match the node,
every claimed name is used and no unclaimed one appears, no literal but zero is written, all 14
witnesses reach their declared verdicts, and the adequacy sweep finds no unexercised leaf. The node
is sound as written — nothing in it needed to be reported to the plan agent, and
`dependency_defect.json` was not written: `drv.interaction.following` behaved as its contract states
in every scene it was called on (including the two scenes built to make it fail, `branch_9` and
`branch_10`).
