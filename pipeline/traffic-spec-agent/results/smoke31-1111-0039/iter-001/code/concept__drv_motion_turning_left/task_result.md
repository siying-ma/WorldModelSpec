# drv.motion.turning_left — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms). Gate runs used: 2 of 6.

## Body

`.and (.derived "drv_motion_moving" [x] [speed_floor]) (.cmp (.measure "kin_yaw_rate" [x]) .gt yaw_floor)`

- "it is moving (drv.motion.moving with speed_floor)": a call to the accepted concept with the formal `speed_floor`.
- "its yaw rate … exceeds yaw_floor": `kin_yaw_rate x > yaw_floor`, strict as the word "exceeds" says. Because left is positive, a right-hand yaw (negative) never exceeds the floor.
- No narrowings: the contract fixes the reading. Residues and declared fields are unchanged.

## Witnesses

Instance: speed_floor 0.1 m/s, yaw_floor 0.5 deg/s. One car (track 1) at 5 m/s heading east in a lane, observed at one instant:
- **holds:** yaw rate +15 deg/s → compliant.
- **fails:** yaw rate −15 deg/s → violated.
- **blind:** yaw rate unset, and `kin.yaw_rate` is declared absent → unknown, because only the yaw comparison is undecided.

## Gate runs

1. **WITNESS_FAIL.** The traces had 3 instants 1 s apart with a fixed heading and a ±15 deg/s yaw rate. The adapter rejects this, because the yaw rate should turn the heading 15° over each interval. No exact rational heading vector reaches a 15° rotation, so I cut each trace to a single instant. The body reads only the current observation, so this loses nothing.
2. **OK.**

(Between the two runs I accidentally issued a no-op `cd` command; it was denied and did nothing.)

## Why I finished

The gate returned OK.
