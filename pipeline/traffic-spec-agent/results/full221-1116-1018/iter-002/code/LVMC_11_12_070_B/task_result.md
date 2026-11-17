# LVMC_11_12_070_B — task result

## Final verdict
**OK** — 20 witnesses, 16 names, composes nothing (gate run 4 of 6).

## Gate runs
1. **UNUSED_CLAIM** (dev_governs, dev_stop_sign, dev_traffic_signal, dev_yield_sign, …). I ran this
   one by mistake on the untouched skeleton, piped through `head`, before writing anything. It used
   one run of the budget and judged nothing of mine.
2. **WITNESS_FAIL**: `blind` was unknown for `absent_atom:st_lane_enters` as well as for the
   masked `dev.governs`. The cause: the carrier quantifier over `travel_region` also ranges over
   the intersection j itself. `st_lane_enters(j, j)` is unknown because an intersection carries no
   lane record. In every other witness `dev_governs(·, j) = false` settled that branch false; with
   governance masked, both unknowns survived together.
   Change: the entering vehicle's carrier is written distinct from j (`.not (.same c2 j)`), first
   in its selection. An approach carrier into j is never j. This is entry topology, not a
   narrowing.
3. **VACUOUS**: leaves no decided witness moved:
   - o's conflict check for a vehicle v on a carrier governed by a yield sign or a flashing-red
     signal (applicability and obligation copies);
   - the obligation's re-bound copy of the whole conflict check (vehicle class, occupancy, entry,
     devices, speed, closest approach, contact);
   - the obligation's copy of the halt-device test.

   Change: added witnesses branch_9 to branch_16, all expecting `violated`:
   - branch_9, 10, 11: a follower queued behind o on c2 under a stop sign, a yield sign, or a
     flashing-red signal;
   - branch_12: a bicycle on the through lane in conflict with o;
   - branch_13: o creeps while the subject's closest approach is first above the clearance, then
     beyond the horizon;
   - branch_14: o at rest at the edge of j, about to enter, with the subject passing within the
     clearance;
   - branch_15: a car at rest on an exit lane that enters a second intersection;
   - branch_16: c2 under a yield sign and a flashing-yellow signal, with the stop sign and the
     flashing-red signal on another approach.
4. **OK**.

After run 4 I only edited the witness file's header comment (the geometry description). No code
changed.

## How the node is written
- Subject class: `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- s6/s7: the subject occupies a carrier c (kind travel_region) with `st_lane_enters(c, j)`, j an
  intersection. c is governed by no stop sign, no yield sign and no traffic signal showing
  flashing_red.
- s1/s10: o is a vehicle and not the subject. It comes from c2 ≠ j with `st_lane_enters(c2, j)`,
  where c2 is governed by one of those devices. Either o occupies j, or o occupies c2 and occupies
  j within `p.conflict_horizon` ahead (`.within .time`).
- s2 "having so yielded" has two parts:
  - (ii) `since onApproach (rises(occupies o c2) ∧ onApproach)`. At every observation from the
    last rise of o's occupancy of c2, o occupies c2 or j. Wherever it is not yet in j, there is no
    v that both:
    - is a vehicle other than o, in j or on a carrier entering j with no entrance device; and
    - is in danger of a crash with o (o's speed above `p.halt_speed_tolerance`, closest approach
      within `p.conflict_horizon` below `p.conflict_centre_clearance`) or in `rel_contact` with o.

    A rise before the recording leaves the search unknown, as the record states.
  - (i) where c2 is governed by a stop sign or a flashing-red signal:
    `since (¬ rises(occupies o c2)) (complete_halt(o) ∧ occupies o c2 ∧ ¬ occupies o j)`.
- s8/s9 obligation: for every o re-bound with the whole selection (same j, c and c2 selection):
  - no case where the subject's speed is above the tolerance while its closest approach to o
    falls below the clearance within the horizon; and
  - no `rel_contact(subject, o)`.
- s3: residue, kept as recorded.

## Choices the node left open
- `within` is measured in time; its track argument (o) is not read by a time window.
- The speed comparison and contact sit inside one existential over v. This is equivalent to the
  record's "speed above tolerance while some v is in danger, and contact with no such v", because
  o's speed does not depend on v.
- The guard c2 ≠ j (see run 2). It is not a narrowing: the record's selection already implies it.
- No narrowings are declared.

## Why I finished
The gate returned OK on the rule and all 20 witnesses. The node needed no repair and no concept
defect was found.
