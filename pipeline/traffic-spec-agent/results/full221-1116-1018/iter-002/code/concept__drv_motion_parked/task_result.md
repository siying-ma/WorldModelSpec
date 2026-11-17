# drv.motion.parked — task result

**Final verdict: OK** (3 witnesses, 2 names, reads 2 atoms)

## Gate runs
1. OK — first run; no changes after it.

## Body
`holdsFor .time (param min_duration) "a" (.derived "drv_motion_complete_halt" [a] [param speed_tol])`:
a at rest (speed at or below speed_tol, through drv.motion.complete_halt) at every observation of the
time window of length min_duration behind. Truncation at the trace start and an unobserved speed
leave it unknown, as the contract states.

## Choices the record left open
- None needing a narrowing: the window is a time window because the contract gives min_duration
  in seconds; the subject of the window is a.

## Witnesses
Instance: speed_tol = 0.1 m/s, min_duration = 2 s; six scenes at 1 s; each scenario is judged over
t = 3000–5000 ms, so every window falls inside the trace.
- holds: bicycle at speed 0 throughout → compliant.
- fails: bicycle rides at 2 m/s, halts at t = 2000 and 3000, then rides off → violated.
- blind: same as holds with kin.speed masked → unknown.

## Why I finished
The gate returned OK on the first run.
