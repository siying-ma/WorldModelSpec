# NRS_484B_257_1_o1 — task result

**Final verdict: OK** (gate run 4 of 6: "18 witnesses, 23 names, composes nothing").

## Gate runs

1. **UNUSED_CLAIM** on the untouched skeletons. I ran this by mistake before writing anything.
2. **UNUSED_CLAIM** again on the same skeletons. This was my error: I chained a directory listing
   onto the gate command and the whole command ran. Both runs were wasted.
3. **VACUOUS**: 14 obligation leaves did no work in any witness. The files built and every
   witness gave its expected verdict. Fixes:
   - The obligation repeated the s1 exception (traffic membership, police role, signal not
     inoperative, the devices governing c or i) in its re-selection of (i, c). The obligation is
     read only where the applicability holds, so the exception is already decided false there.
     For example, the traffic-membership leaf can never change a verdict in the obligation. The
     exception now stays in the applicability only; the obligation re-selects (i, c) by the entry
     and the signs.
   - Sign leaves in the obligation (stop sign governing i, yield sign governing c, yield sign
     governing i) needed violated scenes. Added `branch_10` (yield sign on i), `branch_12` (yield
     sign on c, crosswalk) and `branch_13` (stop sign on i, no marks).
   - The crosswalk's stopping-zone leaves needed a violated scene (`branch_12`). The halt at the
     crosswalk was not decisive in the old `branch_4`, because its yield sign let the slowing also
     comply. It now has its own stop-sign scene (`branch_11`), and `branch_4` shows a yield-sign
     slowing before the crosswalk.
   - The intersection-place zone leaf (offset to i > 0) needed a violated scene (`branch_13`).
4. **OK**.

## How the node is written (also in the rule header)

- **Class (s3):** `ru_aggregate x DEF-NRS-484A-320::vehicle`.
- **Entry (s2):**
  - There is an intersection i and a travel region c.
  - x occupies c at the entry and at the observation before it: `rel_occupies` and not
    `rises (rel_occupies x c)`. This follows the record's missing-evidence words: "whether this is
    an entry through c is unknown where the observation before it does not show x on a mapped
    carrier".
  - `st_lane_enters c i` holds, and so does `drv_motion_entering_region x i`.
  - A stop sign or a yield sign governs c or i (`dev_governs`).
- **Exception (s1):** x is a member of `DEF-NRS-484A-285::traffic`, and a `police_officer`
  directing traffic, or a `traffic_signal` that is not `dev_inoperative`, governs c or i. The
  applicability excludes this case.
- **Obligation (s4, s8):** for every selected (i, c), the place is fixed by c's marks in the
  words' order:
  1. a stop line that `st_entrance_of` records as marking c;
  2. otherwise a crosswalk it records as marking c;
  3. otherwise the intersection, with the through-highway view of s8 (`st_on_way i h`, not
     `st_on_way c h`, `st_sight_along_way ≥ p.intersection_sight_distance`).

  The act is a halt at the place. Where no stop sign governs, a slowing before passing the place
  also counts.
- **History bound:** the act is searched for with `since`, from the entry back to whichever comes
  first:
  - the approach start: x on c, not on the place, ahead of it along c (offset > 0) and farther
    than p.stop_point_tolerance;
  - x's observed exit from a previous stay in i.

  An act at the bounding observation itself counts. Reaching the recording's start leaves the
  verdict unknown.
- **Several carriers:** `definedWhen (every ∨ ¬some) every`. The verdict is compliant if the duty
  holds through every selected carrier, violated if it holds through none, and unknown if the
  carriers differ.

## Choices the node left open

- **Previous stay in i:** written as the observed exit, `rises (¬ rel_occupies x i)`. A stay
  that started before the recording leaves the search unknown.
- **"Before passing the place" for a slowing:** the stop line or crosswalk is not behind x
  (offset ≥ 0); for place (3), x is not yet in i. This is the record's wording.
- **No narrowing declared:** none of these goes beyond the record's own reading.

## Deviation worth the plan's attention

The obligation's re-selection of (i, c) omits the s1 exception. Every leaf the obligation
carries has to be able to move a witness, and the exception's leaves cannot. As a result, a
carrier controlled by a signal or an officer is still judged in the obligation in the rare
multi-carrier case where i itself is not controlled. If the plan wants the exception per carrier,
the gate's adequacy rule and rule 3c pull in different directions here.

## Housekeeping

I accidentally created a stray file, `scratch_tail.txt` (one placeholder line), in this working
directory. My shell is limited to the gate command, so I could not delete it. It is not part of
the result.

## Why I finished

The gate returned OK on run 4, with two runs left unused.
