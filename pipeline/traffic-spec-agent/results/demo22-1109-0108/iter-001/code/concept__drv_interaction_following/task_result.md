# drv.interaction.following — coding session result

**Final verdict: `OK`** (3 witnesses, 2 names, reads 2 atoms).

## The body

```lean
def aheadInLane : Formula := .atom "rel_ahead_behind_in_lane" [aB, aA] []
def headingsAligned : Formula := .atom "rel_same_direction" [aA, aB] [pSameDirectionTolerance]
def body : Formula := .and aheadInLane headingsAligned
```

- `b is ahead of a in the same lane along that lane's direction of travel` →
  `rel_ahead_behind_in_lane [b, a]`. The atom's contract reads "a is ahead of / behind b in the
  same lane, along the lane direction" — its *first* argument is the one ahead (Core: `rel_ahead_in_lane s a b = rel_ahead_behind_in_lane s a b`,
  `rel_behind_in_lane s a b = rel_ahead_behind_in_lane s b a`), so the contract's words are the
  atom with the formals in the order `(b, a)`.
- `the two bodies' headings are aligned within the same-direction tolerance` →
  `rel_same_direction [a, b]` with the formal parameter `same_direction_tolerance` forwarded
  unchanged as the atom's only parameter. No magnitude lives in the concept file.
- The two elements are conjoined; both are read at the observation, so no temporal operator and no
  gap, speed, duration or intention enters. `residues := []`, `narrowings := []`.

## Gate runs (budget 6, used 2)

1. `WITNESS_FAIL` — `blind: expected unknown, got compliant`. The `blind` trace was the `holds`
   trace with the manifest declaring `rel.ahead_behind_in_lane` absent, but masking that atom
   blanks only a *supplied* `aAheadOfB` (`Mask.relation`); Core still computed the order from the
   occupancy, positions and headings of a fully observed lane scene, so the witness stayed
   compliant. Changed: the `blind` scene now carries the carriageway as a region labelled
   `roadway` with `unobservedKinds := [.lane]`, on which Core's computation of
   `rel_ahead_behind_in_lane` is unknown (`Structure.isOfKind .lane` is `none`, and the atom
   returns `none` where a shared region's lane-kind is unknown), and that source supplies the
   order measured on the ordered pair (van, car). Masking the atom blanks the measurement, so the
   order cannot be read and the conjunction is unknown while the heading alignment still holds.
   `holds` and `fails` supply no relation, since Core computes both atoms there.
2. `OK`.

## Choices the record left open

- **Witness figures** (all the witness's own): 20 m/s for both bodies; the car 4 m × 2 m, the van
  6 m × 2 m; 30 m between centres along the lane in `holds`/`blind`; an 8 m carriageway from
  x = −20 m to x = 160 m, one lane in `holds`, two adjacent lanes (y ∈ [0,4] and y ∈ [−4,0]) in
  `fails`; the car's heading 1/40 left of due east (≈1.4°, cosine ≈0.9997) with the matching 0.5 m/s
  lateral drift so position, heading and velocity agree; `same_direction_tolerance := 0.97`, the
  cosine of about 14°.
- **How `blind` is made unknown**: see gate run 1. The record's narrative ("the source declaring
  the in-lane order of road users absent") is satisfied by a source whose scene does not determine
  the order geometrically and which therefore reports it measured — the only construction under
  which masking `rel.ahead_behind_in_lane` is what decides, given that Core computes the atom from
  kinematics whenever the lane geometry is observed. Documented in the witness header.
- **No narrowings declared**: each element has exactly one atom that states its words, and each
  argument order is fixed by that atom's own contract (the same-direction atom being symmetric in
  its two bodies). Nothing in the contract was left to interpretation, so the body needed no
  reading of mine.

## Why I finished

The gate returned `OK` on the second run: the body uses exactly the two claimed atoms over the two
track formals and the one formal parameter, and the three witnesses hold, fail and go unknown as
the record's scenarios declare. The record needed no change.
