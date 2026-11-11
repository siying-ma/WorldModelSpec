# NRS_484B_769 — task result

## Final verdict

**WITNESS_FAIL** (on the files as left). The rule's formulas are complete and checked. Three planned
witnesses (`forbid`, `blind`, `branch_1`) cannot reach their planned verdicts. Each one's narrative needs
an electric-scooter rider, and under the run's reading no electric-scooter rider is ever a decided
member of the claimed aggregate `DEF-NRS-484B-018::electric_scooter`. This is a defect of the node
together with the run's reading, not of the Lean code (see below).

## Gate runs

1. **Run 1 — wasted, my error.** I ran the gate on the unedited harness skeletons and discarded
   its output, so I don't know its verdict. Nothing was learned from it.
2. **Run 2 — WITNESS_FAIL.** This was the full rule plus 10 witnesses (the 7 planned plus
   `branch_4..6`):
   - `forbid`: expected violated, got unknown `[aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]`
   - `blind`: unknown for the same aggregate reason, not for the masked `sig.hand_signal`
   - `branch_1`: expected compliant, got unknown for the same reason
3. **Run 3 — OK (diagnostic only, reverted).** I temporarily rebuilt the scooter riders as
   electric-bicycle riders, and the gate returned `OK  10 witnesses, 5 names, composes nothing`.
   So the formulas, the claims, the anchoring and every leaf are sound. The only blocker is the
   scooter class. I reverted the swap: the scenes would have contradicted the planned narratives
   ("An electric scooter rider …"), and an OK on them would hide the fact that the rule never
   engages for a scooter rider.

The files are left as written for run 2: the planned narratives, built faithfully.

## The rule as written

- **s1:** `x`'s class is the disjunction of the three claimed `ru_aggregate` atoms, each with its
  aggregate id as the literal argument.
- **s2:** `existsRegion "roadway" r (rel_occupies x r)`.
- **s3/s4:**
  - **Applicability:** the rider is on a roadway and shows a signal: the indicator is `left` or
    `right`, or the arm signal is not `no_signal`.
  - **Obligation:** the arm signal is not `no_signal`. If the indicator is `left`, the arm signal
    is `left` or `re_enter`. If the indicator is `right`, the arm signal is `right`.
- **s5:** the right-arm form is the same `sig_hand_signal x right` leaf. It adds nothing.

No reading beyond the record's own was chosen, so `narrowings` is empty. I added three witnesses
so that the left-indicator leaves are exercised:
- `branch_4`: left indicator with no arm signal, expects violated.
- `branch_5`: left indicator with arm signal `right`, expects violated.
- `branch_6`: left indicator with arm signal `re_enter`, expects compliant.

## The node is wrong — span s1 (and the scenarios built on it)

The run's reading classifies `DEF-NRS-484B-018::electric_scooter` as follows:
- **included:** none
- **unresolved:** `ru.electric_scooter`, plus the motor-vehicle classes

So `ru_aggregate x "DEF-NRS-484B-018::electric_scooter"` is never true. For a rider whose only class
is `electric_scooter`, it is unknown (`aggregate_unresolved`). The two other aggregates are false for
that rider, so `x`'s class is unknown. Every scene where a scooter rider is on the roadway and
signalling then comes out unknown. As a result:

- the electric-scooter limb of s1 can never engage the rule, so the duty is never judged for a
  scooter rider;
- the planned `forbid` (violated) and `branch_1` (compliant) are unreachable, and `blind` can't be
  unknown for the masked atom, because the class makes it unknown first.

**What the plan agent must change**, one of:
1. Map the electric-scooter limb of s1 so that a scooter rider can be a decided member. This could
   be done by revising the reading's classification of `DEF-NRS-484B-018::electric_scooter` so that
   `ru.electric_scooter` is included, if the definition's 100 lb / 20 mph limits are what left it
   unresolved. If those limits are deliberately unobservable, record them as an assumption or
   narrowing of s1.
2. If the unresolved classification is intended, re-plan `forbid`, `blind` and `branch_1` with a
   bicycle or electric-bicycle rider. In that case, record that the scooter limb is undecidable
   under this reading, as a gap on s1.

## Why I finished

The only remaining failure comes from the node's s1 mapping together with the run's aggregate
classification. I can't repair either in Lean without building witnesses that contradict the
planned narratives. Run 3 shows that the rule is otherwise accepted.
