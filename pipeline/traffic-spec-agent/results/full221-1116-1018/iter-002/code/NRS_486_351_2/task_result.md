# NRS_486_351_2 — task result

## Final verdict

`WITNESS_FAIL` on `blind` only (expected unknown, got violated). Every other witness (forbid,
permit, idle, branch_1 … branch_5) evaluates to its planned verdict. **The node is wrong:** its
`blind` scenario cannot be built (see below).

## Gate runs

1. `WITNESS_FAIL`: forbid and blind returned unknown for `aggregate_unresolved:DEF-NRS-486-041::motorcycle`
   and `…DEF-NRS-486-038::moped`. The car partner (`motor_vehicle`) is unresolved under the motorcycle
   and moped aggregates, so the s4 limb ("the other is a motorcycle or moped") can never be decided
   false for a car. Change: in forbid/blind the car is westbound in L (oncoming), so s5
   (`rel.same_direction`) decides the pair unexcused. It is abreast of the motorcycle at instant 1 only,
   with a 2 m overlap.
2. `WITNESS_FAIL`: blind expected unknown, got violated, even though the manifest masks
   `rel.longitudinal_overlap`. Core's mask (`Runtime/Manifest.lean`, `Mask.scene`) drops only a
   *measured* overlap; `rel_longitudinal_overlap` is then recomputed from the footprints. Change:
   the car's `extent := none` in blind.
3. `WITNESS_FAIL`: admission rejects the trace: "track 2 is in occupancy_observed but lacks a position,
   a non-zero heading or an extent, so its footprint is undefined".
4. The same files were re-run by mistake (identical result). One extra non-gate command
   (`… --help`) was also attempted and denied. It was not run.

After run 4 I put blind back to an admissible trace (the forbid scene, with the overlap masked). On
these files the gate gives run 2's state: blind violated, everything else passes.

## Why the node is wrong (blind, span s3/s6, `masked: ["rel.longitudinal_overlap"]`)

`rel_longitudinal_overlap` (Atoms.lean) is computed from the two footprints (position, heading,
extent) whenever no measured value is supplied. Masking the atom removes only a measured value.
The admission requires a full footprint for every track whose occupancy is observed, and
`rel.occupies` reads that occupancy. In this rule the overlap is only ever read for a pair whose
`rel.occupies` of L is also read. So:

- if both tracks' occupancy is observed, the overlap is computed and known: the blind can't be unknown;
- if a footprint is withheld, that track's occupancy must be unobserved. The verdict is then unknown
  for `rel.occupies` too, which the manifest does not mask, and the gate rejects the reason.

No scene meets "both occupy L; rel.longitudinal_overlap is not observed". **What the plan must
change:** pick a blind whose masked atom can be the sole deciding unknown. `rel.same_direction` has
the same problem: it is recomputed from the headings, which every occupancy-observed track must have.
The atom to mask is `ru.aggregate`, which the mask blanks through `classes := none`. For example:
"a motorcycle abreast of a second vehicle in L, headings aligned, two abreast; the classes are not
observed" makes the s4 limb unknown and nothing else. Alternatively, the plan can declare that the
rule has no realisable overlap-blind.

## A second plan issue (forbid narrative)

The forbid narrative ("a motorcycle beside a car in L") with the car travelling the same way is
**unknown, not violated** under the run's reading. `motor_vehicle` is unresolved in
DEF-NRS-486-041::motorcycle and DEF-NRS-486-038::moped. No class is included in DEF-NRS-484A-320::vehicle
and also decidedly outside both aggregates. So s4 can only be decided false through s5 (headings
not aligned) or s6 (three abreast). My forbid uses an oncoming car. The plan or reading may want to
revisit whether `motor_vehicle` should stay unresolved under these definitions. Without that, the
core violation (a same-direction car beside a motorcycle in its lane) can never be decided.

Similarly, the idle narrative's "passenger car" subject is unknown, not false, for the motorcycle
and trimobile aggregates. The idle witness uses a bicycle subject, which is outside all three
aggregates.

## Choices the node left open

- Applicability restates the record's applicability (the three-aggregate disjunction on the subject),
  the same formula as the binder class.
- s6 "no more than two abreast" is written with the text's literal 2 (count): the count of road
  users w that are the subject (`same`), or are of the vehicle aggregate, occupy the same L and have
  `rel.longitudinal_overlap(subject, w) ≥ 0`, is at most 2. This is equivalent to the record's "no
  third road user w other than the subject and v", because v meets the counted condition by the
  antecedent. The literal is written `.lit (Units.ratio 2 1) .count`: Units has no count constructor.
  Neither the BARE_LITERAL nor the CHECK_FAIL check has run on this yet, because the gate stopped at
  the witnesses.
- No narrowings were added.
- Added witnesses: branch_4 (two mopeds abreast, aligned → compliant; exercises the moped limbs of s4)
  and branch_5 (two motorcycles abreast head-on → violated; s5).

## Why I finished

Every planned witness except blind reaches its verdict. Blind cannot be realised under Core's
masking and admission rules, so the node's blind plan is a defect only the plan agent can fix. I
stopped with 2 gate runs unused, since further edits to my files cannot change this.
