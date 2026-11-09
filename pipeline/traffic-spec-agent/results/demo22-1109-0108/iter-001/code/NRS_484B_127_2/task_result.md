# NRS_484B_127_2 — coding session result

## Final verdict

`UNUSED_CLAIM — dev_temporary_traffic_control`

The node is wrong on one point, and that point alone blocks the gate: the s3 operationalization
claims `dev.temporary_traffic_control` but claims no atom that ties a device to the subject or to a
region, so the claim cannot be written in a formula at all. Everything the gate checks before the
claim audit passes on the delivered files — the two files build, `Rule.check` is empty, the
soundness and scope checks pass, every quantified variable is anchored, the declarations match the
node, no span is unexpressed, and no unclaimed atom is read. The rule and the fifteen witnesses are
complete and delivered; the one leaf the node makes unwritable is the only thing missing.

## Gate runs (4 of 6 used)

| # | verdict | what I changed after it |
|---|---|---|
| 1 | `UNANCHORED_VARIABLE` — `ttc` | The s3 standard's "no works zone lies in that space" was written as `.existsDevice "temporary_traffic_control" "ttc" (dev_temporary_traffic_control ttc)`. The node claims no atom relating a device to the subject or a region, so the quantifier ranges over every device of the scene. I removed that leaf (keeping the obstruction leaf, which `rel.occupies` + `st.on_way` do anchor) so the gate could check the rest of the rule and the witnesses, and dropped the one witness (cones) that only that leaf moved. |
| 2 | `UNUSED_CLAIM` — `dev_temporary_traffic_control` | The gate's own message names `dev_governs` as the device anchor, and its parenthetical ("the record's claims are already checked") left open whether the claim audit reads atom families. One run to find out: I wrote the leaf as "no temporary traffic control governs a lane the subject occupies" (`dev_governs ttc ln4`, `ln4` anchored by `rel_occupies v ln4`) and re-added the cones witness. |
| 3 | `UNCLAIMED_ATOM` — `dev_governs` | Settled it: the claim audit is per atom id, so the leaf is unwritable either way (unanchored with the claimed atom, unclaimed with the anchoring atom). Reverted to the run-2 state, which is the correct deliverable: every name in the formulas is claimed (hard rule 3), and the node's defect is reported rather than worked around. |
| 4 | `UNUSED_CLAIM` — `dev_temporary_traffic_control` | Nothing; this is the delivered state and the verdict the harness will reproduce. |

The gate's verdicts are ordered, so runs 1–3 never reached the witness, adequacy or vacuity
stages, and no run of a satisfiable claim set exists to reach them: the witnesses below are
reasoned against Core's semantics (which I read: `Semantics.lean`, `Atoms.lean`, `RuleEval.lean`,
`Rule.lean`, `Manifest.lean`, `Builders.lean`, `Units.lean`), not confirmed by the gate.

## What the plan agent must change

**Span s3 (the operationalization "whenever conditions permit").** Its convention requires that
"no `dev.temporary_traffic_control` … lies in that space". `dev.temporary_traffic_control` is a
device-kind atom: the only way a formula reads a device is a device quantifier, and a device
quantifier is anchored to the subject only through `dev.governs` (device ↦ region) or `dev.position`
(device ↦ a comparison with a place). The node claims neither, and no other claimed atom takes a
device argument. One of two repairs:

- add `dev.governs` (and, for the obstruction, `st.region_geometry`) to the s3 operationalization's
  `concepts`, so the works-zone leaf can be placed — with `dev.governs` the leaf reads "no
  temporary traffic control governs a lane the subject occupies", which the gate accepted as
  anchored in run 3; or
- drop `dev.temporary_traffic_control` from s3 and leave the standard to speed and the intervening
  users, with the obstruction leaf as written here.

This is a defect of the node's mapping and not a `no_atom` gap: the surface does carry atoms for
the words (`dev.governs`, `dev.position`), the node simply does not claim them, so by hard rule 2 I
neither declared `no_atom` on s3 nor wrote the words with an unclaimed atom.

**Two further defects of the node that do not block the gate but make leaves that no witness can
move** (reported, not worked around; I did not delete either atom):

1. `ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles` **can never be true.** The run's reading
   admits that aggregate with *no* included class and sixteen unresolved ones, so
   `aggregateMembership` returns `unknown` for any road user carrying one of those sixteen classes
   and `false` only for a road user carrying none of them. The atom therefore decides nothing
   positive anywhere in s1, s2, s6 or s7: in the `idle` witness the combination limb is unknown and
   the duty is kept off only by the width comparison (`and unknown false = false`). Either the
   reading must resolve the classes that make up a combination of vehicles (at least
   `ru.trailer_or_combination`), or s1/s2/s6/s7 should not claim the aggregate.
2. `ru.aggregate=DEF-NRS-484A-285::traffic` **adds nothing on s7.** The only place the words put
   traffic is "lanes available for traffic moving in the same direction", and the movement counted
   is the subject's own; every class that can satisfy the binder (truck, trailer-or-combination) is
   an included class of the traffic aggregate, so the leaf is true in every scene in which the rule
   engages, and no witness can make it false while the rest of s7 holds.

## What the node left open, and what I chose

- **s7, "two or more lanes available for traffic moving in the same direction."** The node claims
  `st.lane_adjacency`, `st.lane_direction`, `st.on_way`, `st.highway`, `st.lane` and `rel.occupies`
  for this one fact, and its `applicability` states only the recorded count. I wrote the fact as the
  disjunction of the two observations those atoms carry of it: the recorded count of lanes in the
  direction of the lane the subject occupies is at least the text's two
  (`st_lane_adjacency`, field `count`), **or** another lane on the same highway carries the same
  direction of travel (`st_lane_direction`, both components, compared against the subject's lane).
  Neither disjunct adds a requirement to the words or drops one; each is sufficient evidence of the
  same legal fact, and the direction counted is the subject's because it is the direction of the
  lane it occupies. I did **not** declare this as a narrowing: s7 is an exception, which rule 2
  forbids narrowing, and this reading neither narrows nor broadens the words. `branch_1` decides on
  the count, `branch_4` on the second lane's direction.
- **s3, the place of the obstruction** — declared as the session's one narrowing
  (`{ span := "s3", kind := "reading" }`). The claimed atoms place no structure region inside the
  space between two bodies (`rel.occupies` is road-user-to-region, `rel.surface_gap`
  road-user-to-road-user, and `st.region_geometry` is unclaimed), so the leaf reads an
  `st.obstruction` region lying on the highway the subject's lane lies on. That relieves the duty
  in some scenes in which the words would still require the space, which is why it is declared.
- **s3, the intervening road users** — the convention's "number of road users that occupy the
  subject's roadway between the subject and the vehicle it follows" is a `Term.aggregate .count`
  over the road users that are neither the subject nor the followed user, share a roadway region
  with the subject (`st.roadway`, `rel.occupies`), lie ahead of it in its lane
  (`rel.ahead_behind_in_lane`) and lie at a smaller longitudinal `rel.surface_gap` than the followed
  user. `count` reads no value of its term, so the term is the declared zero.
- **s4, re-selecting the followed road user.** The applicability's `.existsUser "u"` does not reach
  the obligation, so the obligation re-states the whole of s2's selection under
  `.forallUser "u"` (not the subject, a truck or wide combination, followed by the subject, and
  ahead of it in the lane) and owes the 500 feet to each such user — the duty is owed to whichever
  road user the subject is following, so the quantifier is universal with the selection as its
  antecedent.
- **s1, the width qualifier** is attached to the combination limb only, as the node's
  `applicability` reads it ("a truck of DEF-NRS-484A-305::truck, or a road user of
  DEF-NRS-484A-050::combination_of_vehicles whose read width is at least the literal 80 inches").
- **s6 in `branch_2`** is shown through the overtaking contract's second limb (the overtaken road
  user still ahead of the passer in the lane) rather than the narrative's body overlap: making the
  two 18 m lorries' projections overlap in one lane puts their footprints in contact, and a witness
  of a collision would be a worse scene than the one the contract equally admits. The scene is the
  node's otherwise: same direction, a 4 m/s speed excess.
- **The `blind` witness.** Core's mask of `rel.surface_gap` drops only a *supplied* gap ("the
  computed relations are blanked through the kinematics they would be computed from only when the
  source lacks those too"), and hard rule 8 forbids supplying a relation Core computes. So the
  blind trace is the forbid scene in which the source records no body extent for the leader, which
  is exactly a source that cannot read the space between the bodies; `rel_surface_gap` is then
  `none` and the unknown carries `absentAtom rel_surface_gap`, the atom the manifest masks. The
  classes, the following relation and the one-lane carriageway stay recorded, as the node asks.

## The witnesses

Planned: `forbid` (violated, 42 m clearance), `permit` (compliant, 242 m), `idle`
(not applicable, a 70-inch car as subject), `blind` (unknown, the space unreadable), `branch_1`
(not applicable, three lanes recorded in the direction), `branch_2` (not applicable, overtaking),
`branch_3` (compliant, a queue at 2 m/s with a van in the space).

Added, so that every leaf of the duty and its standards moves a decided witness: `branch_4`
(not applicable — no lane count recorded, but a second lane of the same direction on the way),
`branch_5` (compliant — free-flow speed but a van has moved into the space), `branch_6` (compliant
— nothing in the space but the subject creeps at 2 m/s), `branch_7` (compliant — a barrier on the
way), `branch_8` (not applicable — the subject leads and follows nothing), `branch_9` (not
applicable — the road user followed is a passenger car, outside both aggregates), `branch_10`
(compliant — the subject stands still on the three-lane carriageway, so the s7 exception fails by
its own words and the duty engages, but a standing subject is below the free-flow bound).

Leaves no witness moves, all for the two reading defects reported above: the combination aggregate
(never true under the run's reading) and the traffic aggregate on s7 (true whenever the rule
engages).

## Why I finished

The node is wrong in a way no formula can repair: s3's `dev.temporary_traffic_control` claim has no
anchoring companion, so the gate's claim audit cannot be satisfied — run 1 showed the leaf written
is unanchored, run 3 that the atom which anchors it is unclaimed, and run 4 that the honest state
(every formula name claimed, the claim reported as unused) is stable. The verdict order means no
further run of mine could reach the witness or vacuity stages, so two runs of the budget are left
unspent. The files are delivered complete apart from that leaf, with the defect, the two reading
defects and every choice I made recorded here and in the rule's header and `narrowings`.
