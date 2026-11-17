# NRS_484B_307_8e — task result

**Final verdict: OK** (7 witnesses, 11 names, composes nothing)

## Gate runs (3 of 6 used)
1. `UNUSED_CLAIM` — run on the harness skeleton (all `.tt`) as a baseline; every claim unused, as expected.
2. `VACUOUS` — the leaf `dev_governs d i` (head governing the intersection rather than the approach)
   moved no witness, in the applicability and in the obligation's re-binding. Added witness
   `branch_3` (violated): the steady red head governs `i`, not `c`; the subject cuts through the lot.
3. `OK`.

(One stray shell call with `--help` piped to `head` was refused by the permission layer before
any run; it did not reach the gate.)

## How the rule is written
- Selection: `i` (intersection), `c` (travel_region) with `st_lane_enters c i`, `h2` (highway) with
  `st_on_way i h2` and not `st_on_way c h2`.
- s1+s2 `facedRed`: subject occupies `c` while a traffic-signal head governing `c` or `i` shows
  `circular_red` and none of the other state values (one disjunction over the enumeration).
- s6 + (d) `passingAround`: `since (¬occupies i ∧ ¬drv_motion_parked) facedRed`.
- s5 `crossNotRed`: some travel_region `k` on `h2` entering `i` governed by a head not showing
  `circular_red`.
- s4: `asm.within_incorporated_city`.
- Obligation: for every `i, c, h2` meeting the selection and `passingAround` (the record's
  re-binding, which does not list s5), not (occupies `h2` ∧ ¬occupies `i` ∧
  `rises (∃ hw : highway, occupies hw)`).

## Choices the node left open
- "No other state" lists every other `SignalIndication` value, `unknown` included (it is a state value
  other than circular_red; a head with `unknown` beside red is therefore not read as red alone, which
  is the conservative side).
- "Displays a state other than circular_red" is written as "does not show circular_red" (a head
  always displays some state value).
- "At the previous observation it occupied no st.highway region" is written as `rises` of
  "occupies some highway region". This is equivalent because the subject occupies the highway `h2`
  at the judged observation.
- No narrowings declared: none of these is narrower than the record's own wording, and the spans
  involved (s1, s5) are trigger/condition spans.

## Observations for later sessions
- Core's `since` carries the unobserved past as unknown. For a candidate approach the subject never
  faced red on, the applicability stays unknown until the subject enters `i` or parks. So the witnesses
  are built so that every combination is decided by another conjunct: the cross-approach `(b)`
  condition is false, or the subject starts inside `i` (`idle`). The windows begin at the second instant,
  because `rises` has no previous observation at the first one.

## Why I finished
The gate returned OK.
