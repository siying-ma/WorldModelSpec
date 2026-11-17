# drv.motion.u_turn — task result

## Final verdict

**SCOPE_VIOLATION (from infrastructure, not from the concept files).** The gate never judged the
concept or its witnesses. Both runs flagged one file only: the shell tool's own output-capture file for
the gate command, under `.runtime/tmp/claude-…/tasks/<id>.output`. Each run gets a new id
(`bz0ft9kde`, then `bj7v6233j`), so this session cannot avoid it. This should count as `INFRA`.
The harness's re-run after the session, made without that capture, is the run that judges the files.

## Gate runs

1. `SCOPE_VIOLATION`: changed outside the concept's files:
   `.runtime/tmp/.../tasks/bz0ft9kde.output`. Nothing in the concept was changed in response.
2. `SCOPE_VIOLATION`, same cause, new capture file `.../tasks/bj7v6233j.output`. This confirmed the
   cause is the tool's capture of each gate run. I stopped running the gate (4 runs left unused): every
   further run would make the same kind of file.
   After this run I renamed the witness helper `speed` to `rideSpeed` as a precaution against a name
   clash under `open TrafficSpec`. This change has not been through a gate run.

I also made a few Bash calls that were not the gate command. Three greps read Core (`Time.lean`,
`RuleEval.lean`) and found the file that judges concept instances; their output captures may also sit
under `.runtime/tmp`. One mistaken extra gate command with `--help` was denied and never ran. I wrote
nothing outside the two concept files and this report.

**Not verified: the build and the witnesses.** The gate never reached the build. I checked the
Lean by reading the Core sources (`Primitives.lean`, `Time.lean`, `RuleEval.lean`, `Builders.lean`).

## Body

```
turned  := |prim_heading_change(a, window)|
inBand  := turned ≥ u_turn_min ∧ turned ≤ 360 deg − u_turn_min
settled := |kin_yaw_rate(a)| ≤ yaw_tol
body    := rises (inBand ∧ settled)
```

- The band includes both ends, as the contract says. The magnitude covers a reversal to either hand.
  The primitive integrates the yaw rate through halts and backing, so a reversal made in several
  movements counts.
- `rises` gives "where this did not hold at the previous observation". The body holds at the
  recognizing observation only, and holds again only after the condition has ceased and returned.
- History: the only history read is the primitive's back window. A truncated window or a missing yaw
  rate in it leaves the primitive, and so the body, unknown.
- Both claimed names are used (`prim.heading_change`, `kin.yaw_rate`). The declared literal is
  `Units.degrees 360`. The parameters are formals only.

## Choices the record left open

None. The contract fixes the band, which ends are included, the settling test and the
recognition-edge semantics. `narrowings := []`.

## Witnesses

The instance uses window 20 s, u_turn_min 150 deg and yaw_tol 2 deg/s. Each trace has 36
observations 1 s apart. Instants 0–20 s are straight riding, which covers the window.

- **holds**: two 90° left movements at 30 deg/s (21–23 s and 27–29 s) with a halt from 24 to
  26 s. The yaw rate is 0 from 30 s. The integrated change is 180°, and the condition first holds at
  30 s. Scenario window: (30000, 30000).
- **fails**: the first 90° movement only, then straight north. The change never exceeds 90°.
  Scenario window: (20000, 35000).
- **blind**: the holds geometry with the yaw rate `none` from 21 to 29 s and `kin.yaw_rate` masked.
  At 30 s the change is unknown. Scenario window: (30000, 30000).

## Why I finished

The gate cannot give a verdict on these files from inside this session. Every run creates a new
output-capture file that the scope check rejects. The record itself looks correct: I found no defect
in its elements, literals or scenarios. The harness's own re-run is the judgement.
