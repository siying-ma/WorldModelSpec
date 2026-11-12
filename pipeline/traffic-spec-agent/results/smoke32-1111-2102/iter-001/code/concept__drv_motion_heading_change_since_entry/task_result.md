# drv.motion.heading_change_since_entry — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms)

## Body

`Term.headingSince "a" (.param "step") (.atom "rel_occupies" [a, r] [])`. This is a's signed heading change, integrated from `kin_yaw_rate`. It counts from zero at the last definite rise of a's occupancy of r, and keeps counting after a leaves r. The step bound is the formal parameter `step`, passed directly. The operator's unknown cases are the ones the contract lists: an entry that is not observed or is hidden by an unknown occupancy, an interval longer than the step bound since the observation before the entry, and a missing yaw rate since the entry.

## Gate runs

1. **WITNESS_FAIL**: the trace lint rejected the holds and blind traces. At t=3 s and t=5 s the heading stayed the same as the scene before, even though a 30 deg/s yaw rate was supplied, and a rate is held over the interval before its scene.
   - Fix: the headings now turn with the yaw rate: east, then (4/5, 3/5), then (3/5, 4/5), then north. The body did not change.
2. **OK**.

## Choices the record left open

- **Narrowings:** none. The contract's words are exactly what `Term.headingSince` does with this onset and step bound.
- **Witness figures, all chosen by me:**
  - **Region and road user:** r is an intersection 20 m square. a is a motor vehicle at 5 m/s, observed 7 times at 1 s spacing.
  - **Instance:** the step bound is 2 s, and the value is bounded to [60°, 120°].
  - **Window:** every scenario is judged only at the exit, t ∈ [5 s, 6 s]. Before the entry the value is unknown by design, so the window has to leave those instants out.
- **Scenario values at the exit:**
  - holds: 90°.
  - fails: 0°.
  - blind: unknown, because `kin.yaw_rate` is masked.

## Why I finished

The gate returned OK on the second run, and the record needed no correction.
