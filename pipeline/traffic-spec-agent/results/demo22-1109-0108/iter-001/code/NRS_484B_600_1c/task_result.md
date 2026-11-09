# NRS_484B_600_1c — coding session result

## Final verdict

`OK` — `8 witnesses, 11 names, composes nothing` (one gate run of a budget of six).

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session finished |

Before running the gate I read the Core files that decide the questions the surface left open, so
that the first run would be the only one: `Language/Semantics.lean` (atom arity and the sorts of
each position; that `Formula.atoms` counts a quantifier's literal kind as a read of the kind atom,
so `st.travel_region`, `st.highway` and `dev.speed_limit_sign` are used by the quantifiers
themselves and need no redundant conjunct), `Language/RuleEval.lean` (the static check and the
anchoring the evaluator needs), `Evidence/Builders.lean` and `Scenario.run` (how a witness is
judged, and that an `unknown` witness must be unknown for a masked atom only), `Runtime/Manifest.lean`
(masking `dev.speed_limit_sign` puts `speedLimitSign` into the device's `unobservedKinds` and
leaves its value and kind fields alone), `Vocab/Atoms.lean` (`deviceCandidates` still ranges over a
device whose kind the source cannot tell, which is what makes the `blind` scene unknown rather than
not applicable) and `Vocab/Ontology/Structure.lean` (`lane` and `roadway` refine the abstract
`travel_region`; `highway` does not).

## The rule

- Binder class: `ru_aggregate v "DEF-NRS-484A-320::vehicle"` — the aggregate id, not its classes.
- Applicability: `¬ drv.motion.standstill(v, p.standstill_speed_tolerance)` ∧ some
  `dev.speed_limit_sign` of kind `maximum`, `structure_maximum` or `zone` that `dev.governs` a
  `st.travel_region` which `rel.occupies` ties to `v`, that region lying `st.on_way` on a region of
  kind `st.highway`.
- Obligation: for **every** such sign, `kin.speed(v) ≤ dev.speed_limit_sign.value(d)` — so the
  lowest posted maximum binds, as the record reads it. The region selection is written out again in
  the obligation, because the region bound in the applicability is not in its scope.
- Parameters: `p.standstill_speed_tolerance` only, as `.param`; no magnitude in the file.

## Choices the node left open

- **Sign kinds.** `postsMaximum` is the disjunction of the three kinds the record names
  (`maximum`, `structure_maximum`, `zone`); `minimum` is excluded, as the record's narrowing on s2
  directs. The three spellings are one atom's enumeration in separate disjuncts, so one scene
  exercises that leaf (`branch_1` uses `zone`, the rest `maximum`, `branch_2` shows `minimum`
  decided false).
- **"of highway".** The record names `st.on_way` and `st.highway` without fixing the shape; I wrote
  it as an existential over regions of kind `highway` that the governed travel region lies on,
  nested inside the region the subject occupies. This is the record's own reading of "the
  particular portion of highway being traversed", not a further narrowing, so `narrowings` stays
  empty: the agency reading of "drive or operate", the presence of the sign as evidence of its
  official posting, and the lowest-posted-maximum rule are all the blueprint's narrowings already
  on its record, and the instructions forbid restating them.
- **Quantifier order.** `forallDevice … (implies selection bound)` in the obligation and
  `existsDevice` in the applicability: the record requires the duty at every sign that governs a
  region the vehicle occupies, and the duty to arise where at least one does.
- **No anchoring defect.** Every quantified variable is tied to the binder: the region by
  `rel_occupies`, the device by `dev_governs` to that region, the way by `st_on_way` from it.

## Witnesses

The four planned scenes plus `branch_1`/`branch_2` from the node, and two of my own:

- `forbid` (violated): 40 mph in a lane a 25 mph maximum sign governs.
- `permit` (compliant): 15 mph under the same sign.
- `idle` (not applicable): the only sign governs the other lane; `dev.governs` is decided false for
  every region the subject occupies.
- `blind` (unknown): the same scene as `forbid` with `dev.speed_limit_sign` masked — the device's
  kind becomes unknown, so the selection is unknown and no other atom is.
- `branch_1` (violated): a 45 mph maximum sign on the roadway and a 25 mph zone sign on the lane,
  the subject between them at 35 mph — the lower posting binds through the `forall`.
- `branch_2` (not applicable): a minimum-kind sign, the subject faster than its value.
- `branch_3` (not applicable, mine): the subject halted at 0 m/s under the governing maximum sign —
  the standstill leaf decided true, so the words do not reach it.
- `branch_4` (not applicable, mine): the governed lane lies on no public way (`ways := []`), so
  `st.on_way` is decided false and the portion traversed is no portion of a highway.

Figures are the witnesses' own; the only reading value they are built against,
`p.standstill_speed_tolerance = 0.1 m/s`, is cleared by two orders of magnitude by every moving
subject and met exactly by the halted one.

## Why I finished

The gate returned `OK` on the files as they stand, with every claimed name used, every planned
scenario present with its planned verdict and two extra branches that exercise the standstill and
`st.on_way` leaves in their decided-false polarity. The node needed no repair: its elements,
narrowings and scenarios were consistent with the atoms the surface offers, so there is nothing for
a plan agent to change.
