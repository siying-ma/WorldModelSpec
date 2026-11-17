# NRS_484B_363_4 — task result

## Final verdict

**WITNESS_FAIL**, on the planned `blind` witness only. Every other witness (20 of 21) passed. The
cause is the node's plan for `blind`, not the rule (see "The node is wrong"). The files are left
with the node's own mask (`["kin.position"]`).

## Gate runs

1. **WITNESS_FAIL**: `blind: unknown for [absent_atom:rel_longitudinal_overlap, window_truncated:since,
   absent_atom:rel_bearing, window_truncated:until], not for an atom the manifest masks; the manifest
   masks kin.position`. No other witness was reported.
2. **(accidental run, output discarded)**: I ran the gate command with `| head -0` appended
   while trying to run a no-op. That used one gate run on the same files and broke the
   one-command rule. I'm sorry for this; nothing else was run.
3. **WITNESS_FAIL (diagnostic)**: I temporarily set the `blind` mask to `["kin.position", "kin.speed"]`
   to see whether a decisive atom that the rule reads by name would be accepted. The gate rejected
   the mask as different from the node's, and reported the same four reasons. So it evaluates
   `blind` under the node's mask. **Reverted** to `["kin.position"]`.

## The node is wrong: the `blind` scenario (masked `kin.position`)

The node plans `blind` as "unknown for `kin.position`". In Core, no reading this node makes ever
reports a missing position under that atom's name:
- `rel_bearing` and `rel_longitudinal_overlap` are computed from the positions. With the positions
  blanked they report `absent_atom:rel_bearing` and `absent_atom:rel_longitudinal_overlap`, not
  `absent_atom:kin_position` (`Vocab/Atoms.lean`, `relFrame`, `rel_longitudinal_overlap`).
- `drv.interaction.overtake_pass` reports `absent_atom:rel_longitudinal_overlap` and
  `window_truncated:since` (its look-back has nothing decided to stop on).
- The under-way stretch looks forward to the recognition (`until`). With nothing decided it runs
  to the end of the trace and reports `window_truncated:until`.
- Occupancy is not blanked by a `kin.position` mask (`Runtime/Manifest.lean`: `Mask.user` clears
  only the position). So `rel_occupies` stays decided and is not the reason either.

The masked atom does decide the verdict, but it never appears among the reasons, so the gate's
attribution check cannot pass. No way of writing the claimed atoms changes this:
- the node's under-way atoms are `rel.bearing`, `rel.longitudinal_overlap`, `rel.same_direction`
  and `kin.speed`, none of which reports a missing position as `kin_position`;
- the concept's `since` truncation is outside this rule.

**What the planner must change:** pick a `blind` mask whose atom this rule reads by name and which
alone decides the scene. Two candidates:
- **`rel.occupies` (recommended):** the subject's footprint occupancy is unobserved, so whether
  the pass was made in the zone is undecided. With positions observed, the pass and its under-way
  stretch stay decided, and the only reason is `absent_atom:rel_occupies`.
- **`kin.speed`:** whether the other vehicle was travelling, and whether the subject was moving,
  are undecided. The reason is `absent_atom:kin_speed`.

Either is a one-line change to the `blind` witness's manifest. Alternatively, the gate's
attribution could count a relation computed from a masked kinematic atom (and the truncation that
blanked operands cause) as "for" that atom.

## How each span is written (also in the rule header)

- **s1:** binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s2:**
  - Each other road user b is a vehicle (`ru_aggregate b …`, `not (same b subject)`).
  - The pass is the concept call `drv_interaction_overtake_pass subject b [p.overtake_window, p.overtake_same_direction_cos]`.
  - "Traveling" is b's `kin_speed > p.halt_speed_tolerance` at some observation while the pass is under way.
- **Occasion** (boundary `window`, W = `p.overtake_window`):
  - The ahead-aligned test is `rel_bearing subject b "ahead"`, `rel_longitudinal_overlap < 0`, `rel_same_direction` and `kin_speed subject > p.halt_speed_tolerance`.
  - `U = until (not ahead-aligned) pass`.
  - `some_moment φ = not (holdsFor .time W subject (not (U ∧ φ)))`.
  - `throughout φ = holdsFor .time W subject (U → φ)`.
- **s3** (some_moment): there exist a zone sign z and a travel region r such that `dev_governs z r`, the sign's kind is school or school_crossing, it is not an end sign, and `rel_occupies subject r`. z and r are bound outside the time operators, so each exception is read "for that z and r".
- **s5 / s6:** throughout `not asm.school_in_session_day` / throughout `asm.school_outside_operation_margin`.
- **s7, s8, s9** (c), throughout:
  - some beacon bc governs r and is not `dev_inoperative`;
  - `asm.pupils_in_class` holds;
  - every operational beacon that governs r is not `dev_speed_limit_beacon_flashing`.
- **s10, s11** (d), throughout: no operational beacon governs r, and `prim_conditions_hold z subject` is false.
- **Applicability:** `∃b qualifying(b) ∨ ¬∃b otherVehicle(b)`. The second disjunct is the record's "with no other vehicle in the scene the duty is met".
- **Obligation:** `∀b (qualifying(b) → ¬pass(b))`. It restates the whole qualification, including the zone and region selection.

## Choices the node left open

- **The start of the under-way stretch.** The record says the stretch runs "from the last
  observation of the window behind at which b was ahead … up to the recognition". The language has
  no next-observation operator, so U(o), seen from the observation o itself, cannot single out the
  last ahead-aligned observation L from the earlier observations of the same run. My `until`
  formulation gives exactly the observations after L up to the recognition. L itself, where b is
  still ahead with a gap, is left out, and every observation before L is excluded as required. I
  chose this half-open stretch over the alternative ("the whole last ahead-aligned run"), which
  would count the whole time spent following b as part of the pass. It is not a span, so it is
  recorded in the header and here rather than as a narrowing. The planner may want to confirm it,
  or declare `no_operator` on the occasion's words if the closed stretch is required.
- **Extra witnesses** for the leaves the planned scenes leave unexercised:
  - `branch_4`: (a) holds throughout the pass, not before it → not applicable.
  - `branch_5`: the same for (b) → not applicable.
  - `branch_6`: an operational beacon that is not flashing, with pupils not in class → violated. This exercises the `asm.pupils_in_class` leaf of the obligation.
  - `branch_7`: compliant. A travelling vehicle the subject is drawing alongside keeps the duty in force, while the vehicle passed at the judged instant had stopped before being drawn alongside. This exercises the under-way leaves of the obligation.
- **Judged instant.** Every witness judges t = 16 s, the recognition (`window := (16000, 16000)`). The
  10 s window behind is covered by each trace.

## Why I finished

The only failing check is the node's own `blind` plan: masking `kin.position` cannot make this
rule unknown "for `kin.position`" under the gate's attribution, however the claimed atoms are
written. This is a node defect for the planner to fix (change the `blind` mask, see above).
Adequacy (VACUOUS) was not reached because `blind` fails first.
