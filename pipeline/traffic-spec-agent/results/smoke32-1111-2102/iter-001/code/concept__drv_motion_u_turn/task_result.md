# drv.motion.u_turn — task result

## Final verdict
**OK** (3 witnesses, 1 name, reads 1 atom) — reached on the first gate run of a budget of 6.

## Gate runs
1. `OK`. I changed nothing after this run.

## The body
`|prim_heading_change(a, window)| ≥ min_angle ∧ |prim_heading_change(a, window)| ≤ max_angle` is
evaluated at each observation, using `Term.quantity "prim_heading_change" [a] [window]` under
`Term.abs`.

- **Element:** the one element is the "magnitude of the signed heading change over the window", which maps to `prim.heading_change`. Taking `.abs` of it covers "to either hand".
- **Band:** the band is closed at both ends, as the contract states it. "At or beyond" the lower bound is in, and "beyond" the upper bound is out.
- **Act sentences:** recognition, onset and extent all follow from the pointwise test over the back window.
- **History clause:** "Unknown where the window reaches past the start of the recording or a yaw rate in it is missing" is already the primitive's own behaviour: a truncated window gives `windowTruncated`, and a missing yaw rate gives `absentAtom kin_yaw_rate`.
- **Backing:** backing gives no heading change, so the magnitude is 0 and the body is false.

## Choices the record left open
- **Narrowings:** none. I found no span of the contract that allowed more than one reading.
- **Witness figures:**
  - Parameters: window 10 s, band 160°–200°.
  - `holds`: a forward, reverse, forward three-point turn at 30°/s, with 3 + 2 + 1 scenes, giving a total of 180°. It is judged at t = 15–19 s, where the whole turn lies inside the window.
  - `fails`: the car backs west with its heading east and no yaw. It is judged at t = 10–12 s, where the window is covered.
  - `blind`: the `holds` trace with `kin.yaw_rate` absent.

## Why I finished
The gate returned `OK` on the first run. The record could be written exactly with its one claimed primitive.
