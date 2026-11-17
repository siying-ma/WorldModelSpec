# LVMC_11_40_180_A — task result

## Final verdict

`WITNESS_FAIL` (gate run 1 of 6): `forbid: expected violated, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter]`.
No other witness was reported failing.

I stopped here on purpose. The planned `forbid` witness cannot be built under the run's reading,
and I did not want to cover that up by changing the witness.

## Gate runs

1. `WITNESS_FAIL`. Only `forbid` failed: the electric scooter's class formula comes out unknown, so the
   episode is unknown and not violated. I changed nothing after this run (see below).

## What was written

- **Binder class (a2):** `ru_aggregate(subject, "DEF-NRS-484A-025::bicycle") ∨ ru_aggregate(subject, "DEF-LVMC-11-02-082::electric_bicycle") ∨ ru_aggregate(subject, "DEF-LVMC-11-02-083::electric_scooter")`.
- **Applicability (a3, a4):** `∃ sw : sidewalk. rel_occupies(subject, sw)` ∧ `asm.fremont_street_main_to_seventh`.
  `st.sidewalk` is carried as the region quantifier's kind (`existsRegion (.lit "sidewalk")`), anchored by `rel_occupies`.
- **Obligation (a1):** `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- **a5:** the node's residue. Nothing is written for it.
- **Narrowings:** none. The record leaves no reading open beyond its own observable reading on a1, which I did not restate.
- **Witnesses:** a sidewalk at y ∈ [0, 4] m and a roadway at y ∈ [−10, 0] m. Moving devices go 3 m/s east. The `permit` bicycle has speed 0. `blind` masks `kin.speed`. `branch_1` declares the assumption false.

## Why I finished — the defect is in the run's reading, not in the rule

The run's reading for the admitted aggregate `DEF-LVMC-11-02-083::electric_scooter` reads:
**included (none)**, and `ru.electric_scooter` is among the **unresolved** classes. Under the
`ru.aggregate` contract, a road user that carries only unresolved classes is a member of
**unknown** status. So no road user can ever be decided a member of this aggregate.

As a result:
- The `forbid` scenario as planned ("An electric scooter moves along a sidewalk …") can never be `violated`. It is always `unknown`.
- More importantly, the rule as a whole can never judge an electric scooter riding on the Fremont
  Street sidewalk a violation, even though the law names electric scooters outright (span a2).

**What must change (planning/reading):** the classification of `DEF-LVMC-11-02-083::electric_scooter`
should list `ru.electric_scooter` as **included**. The definition describes "a device with handlebars and
an electric motor", which is what that class denotes. The other option is for the plan to map
"electric scooter" in a2 to the class atom `ru.electric_scooter`, if the representation decisions allow
it. Once the reading includes the class, the rule and witnesses in these files should pass unchanged:
the rule needs no edit.

I did not swap the `forbid` scooter for an electric bicycle or a bicycle. That would get an `OK`
from the gate, but the witness would depart from the planned narrative and the defect would stay hidden.
