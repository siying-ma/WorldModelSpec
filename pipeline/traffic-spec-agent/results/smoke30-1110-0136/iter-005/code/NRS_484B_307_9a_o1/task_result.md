# NRS_484B_307_9a_o1 — task result

**Final verdict: OK** (9 witnesses, 11 names; composes NRS_484B_307_9b_o1…o4).

## Gate runs

1. **WITNESS_FAIL**: the harness rejected all 8 traces as ones the adapter can't produce. Each car kept a fixed heading while its yaw rate turned it 4.5° per interval. *Change:* I dropped heading and velocity from the scenes and made positions advance 50 cm per scene.
2. **Accidental run.** I issued `… gate … | head -0`, which ran the gate with its output thrown away. I didn't see the verdict, and the run probably used up one unit of budget. Nothing changed after it.
3. **WITNESS_FAIL**: a track listed as occupancy-observed needs a position, a non-zero heading and an extent, or its footprint is undefined. *Change:* the heading now turns by exact rational unit rotations (cos 399/401, sin 40/401, which is 2·atan(1/20) ≈ 5.7248° per step). There are 16 steps between scenes 4 and 19, about 91.6° in total. The yaw rate is set to that step over 50 ms (≈ 114.496 deg/s). Positions step 50 cm along the heading. The footprint is 20 × 20 cm, so the footprint and the reference point always fall in the same regions. The trace is 40 scenes long.
4. **VACUOUS**: no witness exercised the `dev_governs(s, i)` limb, a signal that governs the intersection itself. *Change:* I added `branch_5`, where the signal governs the intersection rather than the approach lane. It shows circular_red with green_arrow(u_turn), the car goes straight through, and the expected verdict is violated.
5. **OK**.

Afterwards I edited only the header comment of the rule file, to record how each span is written. No formula changed.

6. **OK**: a confirmation run on the final files.

## Choices the node left open

- **Previous observation.** Core has no previous-observation operator, so I wrote one from `rises` alone: `prev φ := (φ ∧ ¬rises φ) ∨ rises ¬φ`. This is φ one observation back wherever φ is decided at the current one. It is used in two places:
  - The carrier occupied "at the observation before the entry".
  - Reading the entry from the exit. `atEntry ψ := prev (since occ(x,i) (rises occ(x,i) ∧ ψ))` evaluates ψ at the latest entry into i, because the `since` holds at the observation before the exit.

  This is a device of the formula language, not a narrowing of the text.
- **Where "vehicular" sits.** The binder class is the traffic aggregate, as in `class_elements`. "Vehicular" (x is not a pedestrian) is a conjunct of the applicability, as the record's applicability text states it.
- **One selection for both formulas.** The applicability's selection of `i` and `s` is written once (`selection`) and repeated in full inside the obligation's `forallRegion` / `forallDevice`.
- **No narrowings declared.**
- **Witness window.** Each witness covers 50–1950 ms. This leaves out only the first scene, where `rises` has no previous scene to compare with.

## Why I finished

The gate returned OK on both files as they stand. The node looked consistent, and I'm not reporting a node or concept defect.
