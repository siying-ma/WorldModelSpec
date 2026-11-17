# NRS_484B_250_4_o2 — task result

**Final verdict: OK** (9 witnesses, 14 names, composes NRS_484B_250_4_o1)

## Gate runs
1. `UNUSED_CLAIM` — on the untouched skeleton. I ran it together with an `ls` in one shell call by mistake, which broke the one-command rule.
2. `UNUSED_CLAIM` — the untouched skeleton again; I ran the gate by accident, so this run was wasted.
3. `OK` — on the rule and witnesses described below. Nothing changed after it.

(One more shell call, `gate --help`, was denied and did not run.)

## How the rule is written
- **Class (v, dr):** `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability (t1, t2, t3, p1):** the formula is `∃ intersection X, ∃ travel_region c: st_lane_enters c X ∧ since (occupies subject X) (entry ∧ signal ∧ o1)`.
  - `entry` is `rises(occupies X) ∧ since (occupies X) (occupies c ∧ ¬occupies X)`. At a rise of `occupies X`, this is exactly "occupied c, not X, at the previous observation".
  - `signal` is a `traffic_signal` device d with `(dev_governs d c ∨ dev_governs d X) ∧ dev_traffic_signal_uncovered d ∧ dev_inoperative d`, read at the entry.
  - `o1` is `.rule "NRS_484B_250_4_o1" {subject↦subject}`, read at the entry.
- **Obligation:** for every X and c chosen by the same full selection, and every user v with `¬same v subject ∧ vehicle v ∧ (occupies v X ∨ ∃ travel_region c2: st_lane_enters c2 X ∧ occupies v c2 ∧ stoppedEarlier)`, the duty is `¬rel_contact ∧ ¬(kin_speed > p.halt_speed_tolerance ∧ prim_closest_approach_within(h) ∧ prim_closest_approach_distance(h) < p.conflict_centre_clearance)`.
- **stoppedEarlier (p4):** the formula is `since A (rises Hs ∧ A ∧ since Hs (¬Hs ∧ since A (rises Hv)))  ∨  (count Hs (occupies subject c) = 0 ∧ since A (rises Hv))`, where:
  - Hs is `halt subject ∧ on c ∧ ¬in X`.
  - Hv is `halt v ∧ on c2 ∧ ¬in X`.
  - A is `v on c2 ∨ in X`.

## Choices the node left open
- **"Earlier than the onset of the subject's last halt"** is read as "some subject halt onset comes strictly after v's onset", which is equivalent. At a rise of Hs, `since Hs (¬Hs ∧ φ)` gives φ at the observation before, so the comparison is strict without a separate leaf for simultaneous onsets.
- **"Or the subject made none"** is read as "no halt onset during the subject's latest stay on c" (`count … = 0`). This can be decided on a finite trace; "never halted, back to the start of the recording" could not be decided.
- **"Installed and uncovered"** (t2) is written with the `uncovered` attribute of dev.traffic_signal, as well as `dev_inoperative`.

None of these narrow a span, so `narrowings` is empty.

## Witnesses
- **Planned:** forbid, permit, idle, blind (kin.speed masked), branch_1, branch_2, branch_3.
- **Added:**
  - `branch_4` (violated): v halted on c2 before the subject's halt — the positive case of p4.
  - `branch_5` (violated): the inoperative signal governs X rather than c — the "or X" case of t2.
- **Untested assumption:** the witnesses assume NRS_484B_250_4_o1 counts a halt whose footprint overlaps the stop line as compliance. I could not read that file. The gate's OK shows o1 behaves this way on these scenes (complied in forbid, violated in branch_3).

## Why I finished
The gate returned OK.
