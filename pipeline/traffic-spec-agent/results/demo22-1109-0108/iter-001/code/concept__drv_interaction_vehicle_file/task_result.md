# drv.interaction.vehicle_file — coding session

## Final verdict

**OK** — `3 witnesses, 3 names, reads 3 atom(s)`, 3 narrowings declared. One gate run of the six
in budget.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` (3 witnesses, 3 names, 3 atoms read) | nothing: the session ended on it |

Before running the gate I read `Core/Language/Semantics.lean` (`aggregateAt`, `evalMeasure`,
`same`), `Core/Vocab/Atoms.lean` (`rel_surface_gap`, `rel_ahead_behind_in_lane`,
`rel_same_direction`, `footprint`), `Core/Language/RuleEval.lean` (`checkTerm`/`checkFormula`),
`Core/Runtime/Manifest.lean` (`Mask.relation`, `Mask.scene`) and `Core/Evidence/TraceLint.lean`
(valid geometry, geometric occupancy, `completeOccupancy`), so the body and the three scenes were
written once and passed as written.

## The body

```
count over the road users v of the observation of
    v = u
  ∨ ( rel_same_direction v u [same_direction_tolerance]
      ∧ ( rel_ahead_behind_in_lane v u ∨ rel_ahead_behind_in_lane u v )
      ∧ rel_surface_gap u v ≤ file_reach )
  ≥ min_member_count
```

Three claimed atoms, all three used, nothing else; `u` is the only formal, `v` is the aggregate's
variable and is anchored to `u` by every relation in the member test.

## What the record left open, and what I chose (the three declared narrowings)

1. **"are within the file reach of u, a distance … measured between the nearest points of the
   bodies"** — `rel_surface_gap` is read *without* a component, which Core defines as the distance
   between the nearest points of the two footprints (the component reads, `longitudinal` /
   `lateral`, would be a projection and not the distance the contract names). The bound is
   **inclusive** (`≤`): a road user whose body is exactly `file_reach` from u's is a member. The
   contract says "within" without fixing the boundary.
2. **"counting u itself"** — u is a member **by identity** (`same v u`), not by the three relations
   holding of u with itself: `rel_ahead_behind_in_lane u u` is false (u is neither ahead of nor
   behind itself), so a conjunction-only reading would never count u and no file could reach its
   member count. Every road user other than u is counted only through the relations.
3. **"lie ahead of or behind u in the same lane"** — the one claimed atom read in **both
   directions**: `rel_ahead_behind_in_lane v u` (v ahead of u) or `rel_ahead_behind_in_lane u v`
   (u ahead of v, i.e. v behind u). The atom states one road user ahead of another along the
   direction of the lane they share; both sides of u are members by the contract's words.

Not narrowings, because the contract dictates them: `≥` for "at least"; the tolerance passed as
`rel.same_direction`'s own cosine parameter; the lane condition carried by
`rel.ahead_behind_in_lane` itself (it is the atom's "same lane"); nothing about speed, purpose,
class or towing in the body.

## The witnesses

One instance: `min_member_count` 3, `file_reach` 50 m, `same_direction_tolerance` 0.95. One
east-bound lane (region 1), x ∈ [−50, 500] m, y ∈ [−2, 2] m; every car 5 m × 2 m on the centre
line, heading east at 20 m/s; three observations one second apart, each car advancing 20 m, so the
spacings are constant. u ↦ track 1.

- `holds` → **compliant**: five cars at x = 0, 25, 50, 75, 100 — body gaps from u of 20, 45, 70,
  95 m, so u itself plus tracks 2 and 3 are within the 50 m reach: exactly the minimum count of 3.
- `fails` → **violated**: u alone with one car at x = 400 (a 395 m body gap, far outside the
  reach) — that car is decided *not* a member (aligned and ahead in the lane, but too far), so the
  count is 1.
- `blind` → **unknown** with `rel.surface_gap` absent: the same five cars, but the source measures
  the gap between the bodies instead of the extents. It supplies the surface gap and the in-lane
  ahead/behind relation as measured relations and supplies no extent, so no footprint exists and
  occupancy is not observed. Unmasked the count is 3 (compliant); masked, `Mask.relation` drops
  the measured gap, nothing in the geometry can replace it, and the member count cannot be read.
  Supplying those two relations is admissible exactly here: without extents or observed occupancy
  Core cannot compute either, and `rel.same_direction`, which Core *can* compute from the
  headings, is left to it.

## Why I finished

The gate returned `OK` on the first run: the body is the record's contract over its three claimed
atoms and its three formal parameters only, every claim is used, the aggregate variable is
anchored, no magnitude of the concept's own appears in the body, and the three witnesses reach
`compliant`, `violated` and `unknown`-on-the-masked-atom. Nothing in the record is wrong, so there
is nothing to report back to the plan agent and no dependency defect to file (the concept calls no
other concept).
