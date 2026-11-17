# LVMC_11_16_040 — task result

**Final verdict: OK** (15 witnesses, 18 names, composes nothing)

## Gate runs (3 of 6 used)

1. `UNUSED_CLAIM` (every claimed name). This run was on the untouched skeleton; I ran it before writing anything, so it was a wasted run.
2. `WITNESS_FAIL` on six branches (7, 8, 9, 10, 14, 15). To separate the d9 (through street) exception from d10, I had made stop and yield signs and flashing-red heads exist only while the subject was approaching. The adapter rejected this: a device that does not move has to appear in every scene. I removed the stop- and yield-sign branches (7, 8, 10, 14). I rebuilt 9 and 15 with one signal head that is in every scene and shows `flashing_red` during the approach, then `dark` from the moment the subject enters j (an outage).
3. `OK`.

## How the rule is written
- **Class (d5):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** there is some intersection j where:
  - `since occ(subject, j) (rises occ ∧ viewRestricted ∧ ¬throughAtEntry)`, and
  - `¬trafficControlled` holds.

  The view and through-street conditions are judged once, at the observation where the subject enters j. They then carry over to every observation for as long as the subject stays in j.
- **d4:** `¬holdsFor .path (100 ft) subject viewClear`. This is the subject's last 100 ft of path, ending at its entry into j.
- **d6:** `st_sight_distance j ≥ st_region_geometry_distance subject j`. j is the only region the element claims whose sight distance can be read.
- **d7 and d8:** for every highway w with `st_on_way j w`, both must hold:
  - `st_sight_along_way subject w ≥ 100 ft`;
  - every traffic member o (other than the subject) that occupies w and is within 100 ft of j is `rel_visible` from the subject.
- **d9:** read at the last observation before entry, using `atLast .path (100 ft) subject (¬occ j)`. Three things must hold:
  - the subject occupies a carrier that enters j;
  - no carrier it occupies that enters j is governed by a stop sign, a yield sign or a flashing-red signal (so the rule never picks the carrier that favours the subject);
  - some carrier entering j is governed by one of those.
- **d10:** at the observation being judged, a signal not showing `dark`, a stop sign or a yield sign governs j or a carrier entering j.
- **d1 (obligation):** `kin_speed subject ≤ 15 mph`.
- **Residue d3:** the node's, unchanged.

## Choices the node left open
- **Subject excluded from its own traffic (d7):** "view of any traffic" is read over road users other than the subject (`¬same o subject`). Otherwise the subject would have to be "visible" to itself, which no source measures.
- **Window for the d9 look-back:** "the last observation before entry" is found with a 100 ft `.path` window, the same approach window as d4. If observations are more than 100 ft apart, the exception is false.
- **When d10 is judged:** at the observation being judged, since the record gives no time.
- **No narrowings declared.**

## Note for the plan (not a blocker)
Read as recorded, d9 implies d10 whenever the devices' state does not change: any stop sign, yield sign or flashing-red head on a carrier entering j already makes j traffic-controlled under d10. Because of this, no witness with static signs can show d9 changing a verdict. Only a signal whose state changes between the approach and the traversal can (branch_9, branch_15). The gate accepted this. The plan may still want to check whether d9 should be kept as a separate exception.

## Witnesses
- **forbid:** violated. Sight along the cross way is 20 m; the subject goes through at 10 m/s.
- **permit:** compliant. Same view, at 5 m/s.
- **idle:** not applicable. A green signal governs the subject's lane.
- **blind:** unknown. `st.sight_along_way` is masked.
- **branch_1:** compliant. A wall limits sight to 15 m; no other road users; 5 m/s.
- **branch_2:** violated. A car on the cross way that the subject cannot see.
- **branch_3:** violated. The intersection's sight distance is 10 m.
- **branch_4:** not applicable. A stop sign governs j.
- **branch_5:** not applicable. A yield sign governs the cross lane.
- **branch_6:** violated. A dark signal on the subject's lane.
- **branch_9:** not applicable. Flashing red on the cross lane during the approach, then dark.
- **branch_11:** not applicable. A green signal governs j.
- **branch_12:** not applicable. A stop sign governs the cross lane.
- **branch_13:** not applicable. A yield sign governs j.
- **branch_15:** violated. Flashing red on both lanes during the approach, then dark.

## Why I finished
The gate returned OK.
