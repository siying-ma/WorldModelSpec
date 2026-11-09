# drv.motion.reverse_travel — coding session

## Final verdict

**OK** — `3 witnesses, 2 names, reads 2 atom(s)` (one gate run of the six budgeted).

## Gate runs

| # | verdict | what changed after it |
|---|---------|-----------------------|
| 1 | `OK` | nothing: the files were complete when it ran, and `OK` ended the session. |

Before that run the two skeletons were filled in one pass:

- concept: `alongHeading` and `body` replaced the `.tt` TODO; the header's reading section was
  written out for the single element.
- witness: the instance's parameter value, the bay, the car builder, the three traces.

## The body

```lean
def alongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aU, .lit "x"]) (.measure "kin_heading" [aU, .lit "x"]))
       (.mul (.measure "kin_velocity" [aU, .lit "y"]) (.measure "kin_heading" [aU, .lit "y"]))

def body : Formula := .cmp alongHeading .le (.neg pReverseSpeedTolerance)
```

The component of a vector along another is their inner product with the second taken as a unit
vector, and `kin.heading` is read normalised by Core (its contract: the unit vector times a factor
of at least 1 and below 1 + 2·10⁻⁶, exactly the unit vector for an axis-aligned direction), so the
sum of the two products is the signed speed in the direction the body points, in m/s
(`kin_velocity` ⟨1, −1, 0⟩ × `kin_heading` ⟨0, 0, 0⟩). "At most the negative of the reverse speed
tolerance" is `.le (.neg (.param "reverse_speed_tolerance"))`. Both claimed atoms are read and
nothing else is: no region, device, signal or control-state atom, and not `kin.speed` (unsigned)
or `kin.gear` (which the ontology expressly denies as a stand-in for the direction of motion).
Either atom unobserved leaves the comparison unknown, never false.

## Choices the record left open

None that needed a narrowing, so `narrowings := []`. The contract fixes the quantity (the
component of the velocity along the heading), the sense and strictness of the bound (at most the
negative of the tolerance) and the instant it is read at (the observation), and it names no window,
place or duration. The one thing the contract does not state is how the component is computed from
the two vector atoms, and the formula language offers exactly one way — the inner product over the
`"x"` and `"y"` selectors — so that is a consequence of the surface rather than a reading chosen
among meanings. The normalisation factor on the heading (≤ 1 + 2·10⁻⁶) is Core's, not a choice of
this file, and it is exact for the axis-aligned heading the witnesses use.

Figures that are the witness's own, not the contract's:

- `reverse_speed_tolerance` = 0.30 m/s in the instance (a source resolution below the 1.5 m/s of
  the narratives);
- track 1, a motor vehicle 4.8 m × 1.8 m, heading north (0, 1) throughout;
- the bay (region 10, parking space, (−1.50, 0.00)–(1.50, 5.00)), which no formula of the concept
  reads and which stands in the scenes only because the narratives speak of a parking bay;
- three observations at 1 s per trace, with the positions walking 1.5 m per second.

## Witnesses

- `holds` (compliant): heading north, velocity (0, −1.5) m/s at every observation, so the
  component is −1.5 m/s ≤ −0.30 m/s. No window: the concept speaks about the observation only, so
  the body is true at every instant of the trace.
- `fails` (violated): the same car driving forward, velocity (0, +1.5) m/s, component +1.5 m/s.
- `blind` (unknown): the reversing trace with `kin.velocity` masked; the heading is still read, so
  the masked atom is the one that decides.

## Why I finished

The gate returned `OK` on the first run: the body writes the contract's single element over the
formals and the two claimed atoms only, and the three witnesses show it holding, failing and
reporting unknown when the velocity is unobserved. There is nothing left to repair and no reason
to spend further runs.
