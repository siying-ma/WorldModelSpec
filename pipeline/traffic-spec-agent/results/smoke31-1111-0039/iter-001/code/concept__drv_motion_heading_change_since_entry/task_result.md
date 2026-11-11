# drv.motion.heading_change_since_entry — task result

**Final verdict: OK** (gate run 1 of 6).

## Gate runs
1. `OK` — 3 witnesses, 3 names, reads 3 atom(s). This was the first run, with the body and witnesses written as described below. Nothing was changed after it.

(Before that run I tried one Bash call that added `--help` to the gate command. It was denied and did not run, so it used none of the gate budget.)

## Body
`Term.headingSince "x" (.param "step") (.atom "rel_occupies" [x, r] [])`: the heading change of x since `rel_occupies x r` last rose. Core integrates it from `kin_yaw_rate` of x, with the formal `step` as the step bound. The unknowns the contract lists all come from this construct:
- the entry was not observed with the overlap known at every observation since
- two observations are further apart than `step`
- a yaw rate is missing

The construct also matches the contract on two other points: leaving r does not end the count, and only the next entry restarts it.

## Choices the record left open
None in the body. The contract is exactly what this construct means when applied to these two atoms, so I declared no narrowings.

In the witnesses, every figure is the witness's own:
- **Instance:** step = 2 s; bounds = [-100, -80] deg.
- **Region and road user:** an intersection that is the square (0,0)–(20,20) m, and a car sampled once per second.
- **holds:** a right turn with yaw-rate samples 0, -30, -30, -30, 0 deg/s, starting from the entry. That gives -90 deg at the exit whether the integration is left-hand, right-hand or trapezoidal.
- **fails:** the car drives straight through with yaw rate 0, so the value is 0 deg.
- **blind:** the holds trace with `kin.yaw_rate` declared absent.

Each scenario is judged only at the exit instant, using a one-instant `window`. Before the entry the value is unknown by contract.

## Why I finished
The gate returned `OK` on the first run.
