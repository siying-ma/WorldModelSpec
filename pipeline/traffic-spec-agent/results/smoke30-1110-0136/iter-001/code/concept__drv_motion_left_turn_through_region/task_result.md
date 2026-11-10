# drv.motion.left_turn_through_region — task result

## Final verdict: OK

## Body

```lean
def occ : Formula := .atom "rel_occupies" [aX, aI] []
def leaves : Formula := .rises (.not occ)                 -- overlapped before, not here: the exit
def turned : Term := .headingSince "x" pStep occ           -- heading change since the last rise of the overlap: the entry
def body : Formula :=
  .and leaves (.and (.cmp turned .ge pMinAngle) (.cmp turned .lt pMaxAngle))
```

## Gate runs

1. **WITNESS_FAIL** — `holds`: the adapter holds a scene's yaw rate over the interval *before*
   it, and my trace gave the car 22.5 °/s at the entry scene (t=2000) while it kept its heading
   from t=1000. Changed: yaw rate 0 at the entry scene and 22.5 °/s at the four scenes after it,
   so the heading reaches north at the exit. The heading at t=4000 is now (119/169, 120/169)
   (≈44.8°) instead of a ≈46.4° vector. The header comments were updated to match.
2. **OK** — 3 witnesses, 3 names, reads 3 atoms.

## Choices the record left open

None needed a narrowing:
- The exit ("overlaps at the observation before and not at this one") is `rises (¬ rel_occupies x i)`.
- The entry ("the observation at which the overlap last became true") is the onset of
  `headingSince "x" step (rel_occupies x i)`. By its definition, the heading change is unknown
  when the entry is not in the recording, which is what the contract asks for.
- "at least `min_angle`" is `.ge`; "below `max_angle`" is `.lt`.

Witness figures (all chosen in the witness file): the intersection is the 20 m square (0,0)–(20,20),
the car moves at 5 m/s, scenes are 1 s apart, `step` = 1 s, `min_angle` = 45°, `max_angle` = 150°.
All three scenarios use the window [6000, 6000], the exit observation, because the concept holds
only there.

## Why I finished

The gate returned OK on run 2 of 6.
