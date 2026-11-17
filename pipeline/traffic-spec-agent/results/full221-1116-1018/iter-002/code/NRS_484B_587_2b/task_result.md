# NRS_484B_587_2b — task result

## Final verdict: VACUOUS (node/reading defect; not repairable in Lean)

```
VACUOUS
   applicability leaf 8: atom ru_aggregate [subject, "DEF-NRS-484A-020::authorized_emergency_vehicle"] (one of 3 literal variants of this atom; none exercised)
   applicability leaf 14: atom ru_transit_bus [subject]
```

Everything else passes: the rule builds and checks, every claim is used, there are no unanchored variables, and all 8 witnesses
(forbid, permit, idle, blind, branch_1..branch_4) give the expected verdicts. Every other leaf is exercised.

## Gate runs (4 of 6)

1. **UNUSED_CLAIM** — I ran the untouched skeleton by mistake, so every claim was still unused. Nothing changed after this run.
2. **VACUOUS** — the `sig_warning_lamp` family, the aggregate family (AEV/tow_car/bus) and `ru_transit_bus` were unexercised.
   I changed `branch_1` so the emergency vehicle shows only a red lamp. With red and blue both lit, removing either colour left the other one lit, so no single leaf moved the verdict.
3. **VACUOUS** — only the aggregate family and `ru_transit_bus` were left unexercised. No witness can fix these (see below).

(Two non-gate shell reads of Core also ran before I stopped using the shell for anything but the gate. A third was denied.)

## How the rule is written

- Binder class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Applicability is the conjunction of four parts:
  - **moving:** `¬drv_motion_complete_halt(subject; p.halt_speed_tolerance)`
  - **on a controlled-access region:** `∃ca:controlled_access. rel_occupies(subject, ca)`
  - **no emergency conduct:** `¬(sig_hazard ∨ (ru_emergency_vehicle ∧ warning lamp of any colour lit))`
  - **not a listed vehicle on a permitted shoulder:** `¬(listed ∧ onPermittedShoulder)`
- **listed** means any one of:
  - AEV aggregate (e12/e13)
  - `ru_official_vehicle ∧ kind ∈ {incident_management, coroner}` (e14/e16)
  - tow_car aggregate (e15)
  - `bus aggregate ∧ ru_transit_bus` (e17)
- **onPermittedShoulder** (e2/e10/e18) means there is a shoulder `sh` such that:
  - the subject occupies it and it is paved
  - it lies on (`st_on_way`) a highway the subject occupies
  - a `regulatory_sign` of code `shoulder_use_permitted` governs it, with `prim_conditions_hold` for the subject
- **Obligation (e6):** there are no lanes r1, r2 and side s ∈ {left, right} such that all of these hold:
  - the subject occupies both r1 and r2
  - `drv_lane_entering_adjacent_lane(subject, r1, r2, s)` holds
  - the marking on side s of r1 is (solid | double_solid, white)
  - exactly one of r1, r2 is governed by a regulatory sign of code entrance or exit
- Choices the record left open:
  - The controlled-access occupancy that e10 names is the trigger's (e5) at the same observation, so it is not restated inside the exception.
  - Explicit occupancy of r1 and r2 restates what the concept's contract already requires and anchors the two lane quantifiers.
  - Neither choice narrows anything, so no narrowing is declared.

## Why I finished — the node is wrong (spans e12, e13, e15, e17)

Under this run's reading, the three aggregates the node claims for the listed vehicles have **no included class**:

- `DEF-NRS-484A-020::authorized_emergency_vehicle`
- `DEF-NRS-484A-280::tow_car`
- `DEF-NRS-484A-030::bus`

Every class that `DEF-NRS-484A-320::vehicle` includes is **unresolved** in the AEV aggregate. So for any subject that satisfies the binder class:

- `ru_aggregate subject AEV` is always unknown, never true or false.
- `listed` is therefore either true (through the official-vehicle limb) or unknown.
- The tow_car and bus limbs can never decide it.
- Because of the AEV limb, `ru_transit_bus` can never change `listed` either.

Wherever these leaves could matter (subject on a permitted shoulder, not an official IM/coroner vehicle), the instant is unknown. An episode with an unknown instant is either unknown or violated somewhere else, and a mutation of the leaf cannot change either outcome. So **no witness with a decided verdict can ever exercise these leaves**. This follows from the reading, not from the witnesses.

It also means the shoulder exception, as mapped, is unknown for every vehicle other than an incident-management or coroner official vehicle.

### What the plan agent must change

Either (a) remap the listed vehicles to class atoms that an observation can decide, or (b) resolve the aggregates in the reading. Option (a) is what the `ru.aggregate` contract asks for ("Not a stand-in for a named road-user class for which … its own class atom"):

- **e17** "public transit motor bus": `ru.transit_bus` alone ("bus in public transit service"), not `DEF-NRS-484A-030::bus ∧ ru.transit_bus`.
- **e15** "tow car": `ru.official_vehicle` of kind `tow` ("a vehicle in official or contracted road service … kind tow"), or a reading under which `DEF-NRS-484A-280::tow_car` includes a decidable class.
- **e12/e13** "authorized emergency vehicle": a reading under which `DEF-NRS-484A-020::authorized_emergency_vehicle` includes a decidable class (e.g. `ru.emergency_vehicle`, `ru.fire_apparatus`), or a remap to `ru.emergency_vehicle`.

Once any member of the aggregate family and `ru_transit_bus` can be decided true or false, a `branch_*` witness (a transit bus, tow car or AEV on the signed shoulder, plus a non-listed car on the same shoulder) will exercise them. The rest of the rule and its witnesses can stay as they are.
