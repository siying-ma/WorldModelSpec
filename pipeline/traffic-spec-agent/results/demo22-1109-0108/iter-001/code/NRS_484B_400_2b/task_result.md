# NRS_484B_400_2b — coding session

## Final verdict

`OK` — `7 witnesses, 15 names, composes nothing, narrowings declared by the coder: 2`
(gate run 2 of a budget of 6).

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `WITNESS_FAIL` — every witness: "its trace is not one the adapter can produce: scene t=150: track 1 keeps the heading it had at t=100, but its yaw rate turns it 5° over the interval (the rate at a scene is held over the interval before it)" | The traces were rebuilt. The first drafts sampled the turn along a schematic polyline with a few coarse headings while reporting a yaw rate of 100 deg/s; the admission holds the heading to the reported rate. Every turn is now an exact circular arc of radius v/ω sampled at 5° of heading per 50 ms observation, with unit headings written to the ten-millionth and positions to the micrometre, so position, heading, velocity and yaw rate are one motion. `branch_3`'s weave is two 5° steps of a left arc followed by two of a right arc. |
| 2 | `OK` | — |

## The rule

- `clsV` = `ru_aggregate(v, "DEF-NRS-484A-320::vehicle")`.
- Applicability, under one `intersection` quantifier `i`: the subject is (or has been) on a
  `travel_region` carrier it occupies whose entrance end is `i` (`rel_occupies`, `st_lane_enters`);
  the declaration `int.turn` for the subject at `i` is current; every carrier entering `i` lies
  only on two-directional ways (`st_on_way` to a `highway`, each way undivided — no
  `median_or_divider` region on it — and carrying two `roadway` carriers whose `st_lane_direction`
  point against each other); the subject has entered `i` (`drv.motion.region_entry`, now or
  earlier); and it has turned left (`drv.motion.left_turn` with the profile's step bound, the onset
  yaw rate and the turn angle).
- Obligation: for every intersection `i` the same selection picks out, at the observation at which
  the subject's footprint leaves `i` (`drv.motion.region_exit`), every `highway` region it then
  occupies has a `centre_line` region on it (`st_on_way`) whose signed lateral offset from the
  subject (`prim.region_lateral_offset`, left positive) is at least `p.lateral_offset_resolution`;
  where no centre line is observed on that way the duty is undefined there rather than broken
  (`definedWhen`), as the record states.

## What the node left open, and what I chose

1. **When the approach is read (s3, restated in s7).** The record's applicability is present-tense
   ("v occupies a carrier whose entrance end is an intersection i"), but the duty it governs is
   judged at the observation at which the subject's footprint *leaves* that junction, and a
   carrier whose entrance end is the junction is an approach to it: once the subject is clear of
   the junction it is no longer on such a carrier. Read strictly at the judged observation, the
   duty could never be judged on a compliant departure — the plan's own `permit` scene leaves the
   junction on the far side from its approach. I therefore read the approach selection as holding
   at the judged observation **or at an earlier one** (`since .tt …`), exactly as the record
   already reads the entry ("at the judged observation or at an earlier one"). Nothing else about
   the selection is relaxed, and the declared intention is still read at the judged observation.
   Declared as a narrowing on s7 (the duty span); on s3 itself the gate admits no narrowing, so
   the choice is recorded in the rule file's header for the planning session.
2. **"proceed in opposite directions" (s4).** Written as a negative dot product of the two
   carriers' designated directions — two carriers of the way whose directions point against each
   other. This admits every obtuse pair rather than antiparallel pairs alone. An exact
   antiparallel test is not writable: a direction is read normalised only up to a factor below
   1 + 2·10⁻⁶, and the node's reading carries no cosine tolerance, so a stricter test would need a
   magnitude this file has no right to. Recorded in the header (s4 is a condition span, which the
   gate does not let a narrowing touch).
3. **"the highway being entered" (s7).** The record narrows it to the highway region the subject
   occupies at the departure; the quantifier was left open. I read it universally: the centre line
   of *every* highway region occupied at that observation must lie to the subject's left, so no
   way is picked in the subject's favour. Declared as a narrowing on s7.

## Witnesses

Planned: `forbid` (violated — the corner cut, out west on the wrong side of the entered way's
centre line, 2.8 m to its right against a 0.5 m resolution), `permit` (compliant — the wide turn,
the centre line 2.8 m to its left), `idle` (not applicable — straight through, the declaration
false and no yaw), `blind` (unknown — the `permit` world with `kin.yaw_rate` masked, so the turn
cannot be told; the only unknown reason is the masked atom), `branch_1` (not applicable — a median
on the way entered).

Added for the leaves the planned scenes do not reach: `branch_2` (not applicable — both carriers
of the way entered point east, so no opposed pair exists and that way is not two-directional, the
other limb of the two-directional reading) and `branch_3` (not applicable — the declaration is
made and the junction entered, but the heading change accumulated since the onset of a 10 deg
weave never leaves ±5 deg, so the turn angle decides the rule false rather than unknown).

The declaration of `int.turn` is false before the turn's onset and true from it on. That is the
witnesses' own choice and is forced by the concept's contract: before an onset is observed
`drv.motion.left_turn` is unknown and never false, so an observation before the manoeuvre must be
decided by another conjunct if `permit` is to be compliant rather than unknown.

## Why I finished

The gate returned `OK` on run 2 of 6: the rule builds and checks, every claimed name is used and
no unclaimed name appears, every witness reaches its planned verdict (with the two added branch
witnesses), and no leaf is vacuous. Nothing in the node looked wrong: the blueprint's reading is
writable as it stands with the three choices above, so there is nothing for a repair session.
