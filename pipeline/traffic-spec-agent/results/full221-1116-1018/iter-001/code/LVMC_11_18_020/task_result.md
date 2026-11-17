# LVMC_11_18_020 — task result

## Final verdict

**SCOPE_VIOLATION on every run (4 of 6 used).** The gate never judged the two node files. Every run
flagged files under the shared `.runtime/tmp/claude-154266/` tree: the Bash tool's own task-output
files (`tasks/<id>.output`, a new one per command run, so the gate's own invocation creates one),
`cache-break-state-*.json`, and by run 4 the task-output files of **other concurrent sessions**
(LVMC_11_30_050, LVMC_11_43_010_B_o1). This is the environment, not the node files. The agent
runtime's tmp directory sits inside the tree the scope check watches. I cannot remove those files
(nothing outside my two files and this report is writable), so I stopped running the gate. The
harness re-runs it after the session. If that run uses the same scope check, it will report the same
thing until `.runtime/tmp` is excluded from the check or moved out of the worktree.

## Gate runs

1. SCOPE_VIOLATION: a `.runtime/tmp/.../tasks/*.output` file. My first, malformed Bash command
   (which the permission system denied) created it. The skeleton files were unchanged.
2. SCOPE_VIOLATION: a new `tasks/*.output` (this run's own) plus `cache-break-state-*.json`. Nothing
   in the node files had changed. This established that the check catches the tool's own output.
3. SCOPE_VIOLATION: the same pattern, from a gate invocation I made by mistake.
4. SCOPE_VIOLATION: the same, plus other sessions' output files. This invocation was also a mistake
   (I meant to read a Core file). Both node files were written by then.
   Runs 3 and 4 wasted budget. That is my error, though no run could have returned a judgement.

Because the gate never ran on my files, I checked them by hand against Core instead:
`Semantics.lean` (atom dispatch, quantifiers, `rises`), `Temporal.lean` (`risesAll` at the first
observation is false where φ is false), `Atoms.lean` (`rel_bearing` computed from kinematics,
`st_entrance_of`, `dev_governs`, `isKind` for the abstract `travel_region`), `Builders.lean`, and
`Admission.lean`.

## The rule as written

- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Selection, for bound c, j, d, cw:
  - `rel_occupies subject c`, `st_lane_enters c j`, `dev_zone_sign_kind d school_crossing`,
    `dev_governs d c` and `st_entrance_of cw c`;
  - ∃ user o ≠ subject, of class pedestrian, bicycle, electric bicycle or electric scooter, with
    `rel_occupies o cw`;
  - o on the subject's side: ∃ highway w with `st_on_way cw w`, ∃ centre line cl with
    `st_on_way cl w`, and with L = `prim_region_lateral_offset(subject, cl)` and
    y = `rel_bearing(subject, o).y`, (L > 0 ∧ y < L) ∨ (L < 0 ∧ y > L); or ∃ one-way roadway r with
    `rel_occupies subject r`.
- Applicability: ∃ travel_region c, intersection j, zone_sign d, crosswalk cw: selection.
- Obligation: ∀ travel_region c, intersection j, zone_sign d, crosswalk cw:
  selection → ¬ rises(`rel_occupies subject cw`). This re-binds the record's whole selection and
  states the duty for each crosswalk so selected.

## Choices the node left open

- The duty is stated for every selected crosswalk (∀ in the obligation, ∃ in the applicability).
  The record says "for the cw bound in the applicability, re-bound with the same selection"; I read
  that as the duty holding at each crosswalk the selection admits. No narrowing is declared, and
  the record's own observable readings are not restated.
- The School-Xing legend is read through the claimed `dev.zone_sign` **kind** attribute
  (`dev_zone_sign_kind … "school_crossing"`), as the k5 element says. If the gate counts the
  attribute accessor separately from `dev.zone_sign` (UNCLAIMED_ATOM), the node's claim needs to
  cover the kind attribute.

## Witnesses

These are `forbid`, `permit`, `idle`, `blind` and `branch_1` as planned, plus five added branches:

- `branch_2` (violated): a one-way roadway with no centre line exercises the one-way disjunct.
- `branch_3` (violated): the subject comes with the centre line on its right (L < 0), which
  exercises the L < 0 leaves.
- `branch_4`, `branch_5`, `branch_6` (violated): a bicycle, an electric bicycle and an electric
  scooter, one per k8 class leaf.

The geometry is described in the witness file's header.

## Why I finished

Every gate run returns SCOPE_VIOLATION for files the environment itself writes, including other
sessions' files. The remaining runs could not judge the node and would only add more such files.
The rule and witnesses are complete and checked by hand against Core. The node itself does not
appear wrong. The infrastructure defect for the operator to fix: the agent runtime's `.runtime/tmp`
must be outside the gate's scope check.
