# drv.motion.moving — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom). Gate runs used: 3 of 6.

## Gate runs
1. `UNUSED_CLAIM kin_speed`: I ran the gate on the harness skeletons before editing anything, so the body was still `.tt`. That spent one run without testing any work. I then wrote the body.
2. `WITNESS_FAIL`: the body passed the static checks. The witness traces were still the skeleton's empty scenes, where the subject's track 1 doesn't exist. I then built the three scenes.
3. `OK`.

## Body
`.cmp (.measure "kin_speed" [x]) .gt (.param "speed_floor")`. This is "its speed exceeds speed_floor", and it uses only the claimed atom `kin.speed`. The comparison is strict because the contract says a speed at or below the floor counts as no motion. Where the speed isn't observed, the body is unknown.

## Choices the record left open
- None in the body. "Exceeds" plus "at or below it counts as no motion" fixes the comparison as strict, so no narrowing was declared.
- Witness figures (all my own):
  - Speed floor: 0.1 m/s.
  - Lane: region 10, eastbound, x 0…200 m, y −2…2 m.
  - Car: track 1, motor vehicle.
  - **holds**: the car travels at 50 km/h.
  - **fails**: the car stands still just behind a stop line (region 11, x 60…60.3 m) with speed 0.
  - **blind**: the holds trace, with `kin.speed` masked through `Build.masked` and the manifest.

## Why I finished
The gate returned `OK`. The record is consistent: one element, one atom, and the body says exactly what the contract says.
