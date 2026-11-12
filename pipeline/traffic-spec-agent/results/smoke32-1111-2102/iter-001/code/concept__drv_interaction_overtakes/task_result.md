# drv.interaction.overtakes — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 3 atoms)

## Gate runs
1. `OK` — first run, on the body and witnesses below. Nothing changed after it.

## Body
`rises(drv_position_behind(b, a)) ∧ since(rel_same_direction(a, b; alignment), drv_position_behind(a, b; alignment))`

- `rises` of b-behind-a is the observation at which a becomes wholly ahead of b. It is true there only, so the concept holds only at the recognition observation.
- `since` checks that a was behind b at some observation and that the headings were aligned at every observation after it, up to the recognition. Such an observation exists exactly when the last one before the recognition (the observed beginning) has the headings aligned from it onward, so this matches the contract's condition. At the recognition a is ahead of b, not behind it, so the matching observation is an earlier one.
- History: if no observation of a behind b exists and the headings are aligned all the way back to the start of the recording, `since` is unknown (truncated), never false. `rises` at the first observation is unknown too.

## Choices the record left open
None that needed a narrowing; `narrowings` is empty. The witness figures are this file's own:
- alignment = 9/10
- both cars are 4 m × 2 m
- a moves at 10 m/s and b at 5 m/s, in adjacent east-bound lanes
- 7 observations, 1 s apart

## Witnesses
- **holds:** a starts wholly behind b (k ≤ 3), is alongside at k = 4 and wholly ahead from k = 5. The window is the recognition at 5000 ms.
- **fails:** a comes alongside at k = 4 and then keeps pace with b to the end. It is never ahead, so the concept is false everywhere.
- **blind:** the holds geometry. From k = 4 on, b's extent is missing and `rel.longitudinal_overlap` is masked. This leaves the recognition at 5000 ms unknown because of the masked atom only: a is still decidedly behind b at k ≤ 3, so there is no truncation reason.

## Why I finished
The gate returned `OK` on the first run.
