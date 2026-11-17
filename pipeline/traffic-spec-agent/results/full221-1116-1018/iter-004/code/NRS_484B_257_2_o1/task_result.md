# NRS_484B_257_2_o1 — task result

**Final verdict: OK** (14 witnesses, 19 names, composes NRS_484B_257_1_o1)

## Gate runs (3 of 6 used)

1. **UNUSED_CLAIM**: this run was on the untouched skeleton, which still had `.tt` placeholders. I ran it to see the baseline.
2. **VACUOUS**: these obligation leaves were never exercised:
   - `st_lane_enters` in the obligation's re-selection of the entry;
   - `dev_governs` of the stop sign and of the yield sign;
   - the approach-start pieces: `st_entrance_of`, `rel_occupies`, the offset and the distance for the stop line, the crosswalk and X;
   - the `noLine`/`noWalk` leaves.

   **Diagnosis:** in every violated witness, the composed `NRS_484B_257_1_o1` is also violated, so this rule's own act and history-bound leaves can only change a compliant witness. **Changes:**
   - Gave all stop-line quantifiers the variable `L` and all crosswalk quantifiers the variable `W`, so identical relations are written identically (no change in meaning).
   - Removed the "off the mark" conjunct (`¬rel_occupies`) from the upstream test. A body farther than the tolerance from a mark cannot overlap it, so the conjunct was redundant.
   - For X, the upstream test is now just "on c and farther than the tolerance from X". Because c's entrance end is X, that already means outside X and short of it along c's direction, so I dropped the separate offset test.
   - The yield branch became `¬stopGoverns → found(slowed)`. Under the applicability, "only a yield sign governs" is the same as "no stop sign governs".
   - Added `branch_9`. It covers the obligation's `st_lane_enters` and the stop sign's `dev_governs` leaves.
3. **OK.**

## Choices the node left open

- **Previous observation.** Core has no "previous" operator. The entry is written `rises(occ X) ∧ since(occ X, occ c ∧ ¬occ X)` together with `st_lane_enters(c, X)`. At the entry, the `since` steps back one observation, to the one before the subject was in X.
- **History bound.** It is written as `since(occ X, ¬occ X ∧ since(¬approachStart ∧ ¬occ X, inZone ∧ act))`, evaluated at the entry:
  - The search runs back from the observation before the entry.
  - It stops at the approach start, or at an observation in X (the previous visit, which begins at the previous entry).
  - If it reaches the recording's start first, the result is unknown.
  - No bound comes from the trace start or from a path length.
- **Place order (subsection 1).** In order:
  1. A stop line marking c: offset ≥ 0 and distance ≤ tolerance.
  2. Where every stop line's entrance list excludes c: a crosswalk marking c, not overlapped, offset > 0, distance ≤ tolerance.
  3. Where neither marks c: outside X and within the tolerance of X.

  The "approach start" uses the same order: every mark of that kind that marks c lies ahead (offset > 0) and farther than the tolerance.
- **Region re-selection (3c).** The obligation quantifies over every intersection X and travel region c for which the entry holds. Sign governance is read at the entry: a stop sign means a halt is required, otherwise a slowing. The exceptions and `signed` are only in the applicability.
- **Not handled specially:** a subject that occupies several carriers entering the same intersection, where the verdict differs between them. The contract says that case is unknown; the `forall` over c makes it violated instead. No witness reaches this case.
- **Narrowings:** none declared. The two removed conjuncts follow from the remaining ones, so they do not narrow the reading.

## Witnesses

- **Geometry:**
  - Lane c is eastbound, x ∈ [-80, 0] m.
  - X is at x ∈ [0, 20] m.
  - The stop line is at x ∈ [-3, -2.5] m. The crosswalk (branch_6 only) is at x ∈ [-4, -1] m.
  - The subject is 4 m × 2 m. Its occupancy is stated from its footprint.
- **Planned witnesses:** forbid, permit, idle, blind, history_boundary, branch_1 and branch_2.
- **Added witnesses:**
  - branch_3: an officer governs c → not applicable.
  - branch_4: the stop sign governs X and the signal is inoperative → violated.
  - branch_5: yield only, entering fast → violated.
  - branch_6: crosswalk place → compliant.
  - branch_7: an operating signal governs X → not applicable.
  - branch_8: an officer governs X → not applicable.
  - branch_9: a yield sign governs c, and a stop sign governs an overlapping carrier c' that enters another intersection Y → compliant.

## Observations for the plan

The composed `NRS_484B_257_1_o1` evidently states the same act on the same scenes: it is violated in every violated witness of this node. So this node's own act is redundant with the composition whenever the act is missing. It only changes the verdict where 257_1 is compliant or does not apply. Nothing is wrong in the node itself, but the plan agent may want to check whether repeating the act on top of the composition is intended.

## Why I finished

The gate returned OK.
