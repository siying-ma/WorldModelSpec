# NRS_484B_363_4 — task result

## Final verdict

**WITNESS_FAIL** on the files as left: `blind: expected unknown, got violated; the manifest masks rel.bearing`.
Every other check passes. A diagnostic run with a substitute `blind` witness returned `OK` (18 witnesses).
That substitute was not left in the files (see below). **The node is wrong in its `blind` scenario.**

## Gate runs

1. (Accidental) The gate command ran with its output discarded while I was reading Core, on the
   harness skeleton. I did not see its verdict. It may have used one run of the budget.
2. **WITNESS_FAIL**: `blind` expected unknown, got violated. All other witnesses matched. I read
   `Core/Vocab/Atoms.lean` and `Core/Runtime/Manifest.lean` to find the cause (below).
3. **OK**, a diagnostic run. I replaced `blind` with a trace in which b's `kin.position` is unobserved
   and the bearing and longitudinal overlap are supplied as measured. This shows that the rule,
   the 17 other witnesses, the static checks, anchoring and mutation adequacy all pass. That
   `blind` is unknown because b's position is missing, not because of the mask: the pass concept
   reads `kin.position` and is unknown with or without the mask. That breaks "blind needs the
   masked atom to be the one that decides", so I reverted to the planned `blind` (forbid's trace
   with `rel.bearing` masked). The harness re-run will therefore report WITNESS_FAIL on `blind`.

## Why the node is wrong (scenario `blind`, masked `["rel.bearing"]`)

- `rel_bearing` (`Core/Vocab/Atoms.lean:635`) uses a measured bearing if the source supplies one.
  Otherwise it computes the bearing from `kin.position` of both road users and `kin.heading` of the
  subject (`relFrame`).
- Masking `rel.bearing` (`Manifest.lean`, `Mask.relation`) drops only the measured value. Computed
  relations are blanked "only when the source lacks those [kinematics] too".
- A witness may not supply a relation Core can compute. So on any witness whose kinematics are
  observed, the bearing is still computed, the mask changes nothing, and `blind` gets forbid's
  verdict (violated).
- `drv.interaction.overtake_pass` reads `kin.position` and `kin.heading` itself. Any trace that
  removes what `rel_bearing` is computed from also leaves the pass undecided. So no witness can
  make the `rel.bearing` mask the deciding unknown.

**What the plan agent must change:** mask an atom whose absence actually blanks the pass and its
occasion. For example `kin.position`: it blanks the concept, the computed `rel.bearing` and
`rel.longitudinal_overlap`, and the occupancy footprint. Or `kin.heading`. Alternatively, drop
`rel.bearing` as the blind atom: on this Core it is unobservable only where the pass concept is too.
Nothing else in the node needs to change: with a feasible blind scenario the rule and the other
witnesses already pass (run 3).

## How the rule is written (choices the node left open)

- **Under way (U).** U is `since (moving ∧ (¬behind ∨ rises behind)) (ahead ∧ aligned ∧ moving)`,
  built from the under_way element's atoms: `kin.speed` against `p.halt_speed_tolerance`;
  `rel.bearing` ahead/behind; `rel.longitudinal_overlap` < 0; `rel.same_direction` with
  `p.overtake_same_direction_cos`. `someMoment` and `throughout` are exactly the 6b forms with
  W = `p.overtake_window`.
  - U is read at each observation of the window and cannot see the judged observation. So it marks
    every observation from one where b was ahead and aligned with the moving subject, up to and
    including the first observation with b behind.
  - At a recognition, the last such stretch begins at the record's "last observation at which b was
    ahead". Earlier ahead-and-aligned observations of the moving subject (its approach) also count
    as under way.
  - The language has no operator for the stretch "from the last ψ in the window to the judged
    observation" at each of its observations, so this is the closest pointwise form. The repair
    session should know that it slightly widens the occasion.
- **"With no other vehicle in the scene the duty is met."** Written as a disjunct of the
  applicability, `¬∃b (vehicle b ∧ ¬same b subject)`, so `permit` is compliant.
- **Applicability and obligation.** The applicability is `noOther ∨ ∃b occasion(b)`. The obligation
  is `∀b (occasion(b) → ¬overtake_pass(subject, b))`, which repeats the whole selection of b, z and
  r. occasion(b) is:
  - b is another vehicle;
  - b is travelling at some moment under way;
  - a school or school_crossing zone sign z, not an end sign, governs a travel region r that the
    subject occupies at some moment under way;
  - none of exceptions (a)–(d) holds throughout.
- **Exceptions (c) and (d).** Both read "operational beacon governing r" as
  `dev_governs(bc, r) ∧ ¬dev_inoperative(bc)`, quantified over `speed_limit_beacon` devices.
- No narrowings were declared. The record's own observable readings are not restated.
- **Witnesses.**
  - `branch_4` was added (violated): an operational beacon that is not flashing, but the pupils
    are not in class. It exercises the obligation's `asm.pupils_in_class` leaf.
  - Every witness judges t = 12–19 s, so the 10 s windows are covered. Before that both vehicles
    are at rest, so no pass is under way: those observations stand for "before the pass begins" in
    the `occasion_*_outside` witnesses.

## Why I finished

The only remaining failure is the `blind` scenario, which no honest witness can satisfy on this
Core (explained above). That is a defect of the node's plan, not of the rule. I left the honest
planned `blind` witness in place, not a substitute that passes for the wrong reason.
