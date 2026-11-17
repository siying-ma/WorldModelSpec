# NRS_484B_560_3_o2 — task result

## Final verdict

**WITNESS_FAIL** (run 2): `blind: expected unknown, got violated; the manifest masks rel.longitudinal_overlap`.
This is a fault in the node's plan, not in the rule or in the other witnesses. Details are under "The node is wrong" below.
I put the blind witness back to the planned scene, so the harness's re-run will report the same WITNESS_FAIL.

## Gate runs

1. **BARE_LITERAL**: `formula literals [] ≠ the node's declared literals [('4','count')]`. I had written s8 as four nested
   pairwise-distinct lane quantifiers, so the figure four was never written as a literal. I changed the exception
   to: some highway h the subject occupies, and lanes l1…l4 with
   `cond(all four lie on h ∧ pairwise distinct, 4 count, 0 count) ≥ 4 count`. The language counts only road users
   (`Term.aggregate`), not regions, so the count of distinct lanes is written over the four bound lanes. The literal
   is `.lit (Units.ratio 4 1) .count`, because `Units` has no count constructor.
2. **WITNESS_FAIL**: `blind` came out violated instead of unknown. The other witnesses raised no error:
   forbid, permit, idle, branch_1, branch_2, and branch_3–6, which I added for the stop-sign, red-signal,
   police-stop and gate-down leaves.
3. **WITNESS_FAIL**: I tried leaving the other car's extent unobserved in `blind`. The adapter admission rejected
   it: "track 2 is in occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is
   undefined". I reverted that change.

## Choices the node left open

- **s1:** the device kinds are read through the device quantifiers' kinds (`existsDevice (.lit "stop_sign")`, etc.).
  The travel region is a `travel_region` quantifier, which covers lanes.
- **s2 / s7:** in the obligation, "the same crossing c" re-selects c as the applicability does: a railway crossing
  within p.railroad_crossing_approach_reach of the subject. The other road user must also be within that reach of c.
- **s8:** written as described under run 1. No narrowing is declared.

## The node is wrong: the `blind` scenario (masked `rel.longitudinal_overlap`) cannot be unknown

- `Mask.relation "rel.longitudinal_overlap"` drops only a *supplied* `longitudinalOverlap`
  (`Core/Runtime/Manifest.lean`: "The computed relations are blanked through the kinematics they would be computed
  from only when the source lacks those too").
- `rel_longitudinal_overlap` (`Core/Vocab/Atoms.lean`) computes the overlap from both footprints: position, heading
  and extent.
- The adapter admission requires that same footprint for every track whose occupancy is observed.
- s7 requires `rel_occupies(v, lane)` for the other road user, and s1 requires it for the subject. Both tracks
  must therefore be occupancy-observed, so both carry footprints, so the overlap is always computed.
- The other option is to leave a track's occupancy unobserved. That makes `rel.occupies` unknown, which is an
  unmasked reason, and the witness fails for that instead.

So no admitted trace leaves this rule unknown because of `rel.longitudinal_overlap` alone.

**What the plan should change:** point the `blind` scenario at an atom whose absence the masking really produces.
Two candidates:
- `st.on_way`: the lane-count exception becomes undecidable on a two-lane highway, so the applicability, and with
  it the verdict, is unknown.
- `ru.aggregate`: the other road user's membership of traffic becomes unknown.

Either one gives a blind witness that is unknown only for the masked atom. The rest of the rule and the other
witnesses can stay as they are.

## Why I finished

The only remaining failure comes from the node's planned blind scenario, and no change within my two files can
fix it. Any change that would make it unknown (an unobserved extent, unobserved occupancy, or masking another atom)
is either refused by admission or produces unmasked unknown reasons. I stopped after 3 of the 6 gate runs.
