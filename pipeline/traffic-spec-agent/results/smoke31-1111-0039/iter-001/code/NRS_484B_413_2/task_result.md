# NRS_484B_413_2: task result

**Final verdict: OK** (8 witnesses, 8 names, composes nothing)

## Gate runs
1. **WITNESS_FAIL**: the adapter refused every departing trace. After the onset, path length grew by 10 m per step while the straight-line step was about 10.11 m. **Fix:** after the onset, path length grows by 11 m per step during the two seconds of sideways movement. Path lengths at and before the onset are unchanged, so no window that is judged moved.
2. **OK**.

(Before run 1, I issued one shell command that the sandbox denied: a gate invocation with a trailing `--help`. It was never executed and did not use a gate run.)

## How the rule is written
- **Class (f9):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (f8):** `rises (∃ travel_region c. rel_occupies(x,c) ∧ (veering_left(x,c) ∨ veering_right(x,c)))`, using p.speed_resolution and p.course_departure_sine. This means a departure holds now and held for no region at the observation before.
- **Obligation (f1):** `(departsLeft ∧ signalled(left)) ∨ (departsRight ∧ signalled(right))`.
  - Each `departsSide` repeats the applicability's whole region selection (a travel region x occupies and veers on), restricted to that side.
  - Joining the two with `or` means a departure to both sides at once owes the signal of either, as the record states.
  - A side's signal is `sig_turn_indicator x side ∨ sig_hand_signal x side`.
- **Window length (f5, f6, f7):** `signalled(φ) = (asm → holdsFor .path 100 ft x φ) ∧ (¬asm → holdsFor .path 300 ft x φ)`.
  - A window length must be a constant term (`Term.isConstant`), so `Term.cond` cannot be the length. I chose two implications on the assumption to select the bound.
  - Where the assumption is unknown, this gives true when both windows hold, and unknown or false otherwise.
- **Literals:** `Units.feet 100` and `Units.feet 300`, with unit tag `.metre`.
- **f10:** the record's residue; no environment atom is read.

## Choices the node left open
- The only choice was how to write the bound selection: two implications, as described above. It follows the record's "a bound selected by the condition" without narrowing it.
- No narrowing was declared.

## Witnesses
**Geometry:**
- Three lanes, all designated east.
- x drives at 10 m/s with one observation per second.
- The departure begins at k = 12, at a path of 120 m, with a lateral velocity of ±1.5 m/s (sine about 0.15, against a tolerance of 0.05).
- Behind the onset, the 100 ft window covers k = 9…12 and the 300 ft window covers k = 3…12.

**Scenarios:**

| Scenario | Expected | District | Departure | Signal |
|---|---|---|---|---|
| forbid | violated | rural | left | indicator left from k=8 (40 m) |
| permit | compliant | rural | left | indicator left from k=1 (110 m) |
| idle | not applicable | — | none, straight in lane | — |
| blind | unknown | rural | left | turn indicator and hand signal masked |
| branch_1 | compliant | business | right | indicator right from k=8 (40 m) |
| branch_2 | violated | rural | right | indicator left throughout |
| branch_3 (added) | violated | business | left | indicator left only over the last 10 m |
| branch_4 (added) | violated | business | right | no signal |

I added branch_3 and branch_4 so that the district-branch leaves are exercised: the assumption and both signal leaves inside each 100 ft window.

## Why I finished
The gate returned OK on the second run.
