# NRS_484B_785_1a — task result

## Final verdict
`WITNESS_FAIL` (1 gate run of 6). I stopped because the node is wrong: its subject class cannot hold in any scene.

## Gate runs
1. `WITNESS_FAIL`:
   - forbid, permit, branch_1, branch_2: each expected a decided verdict and got `unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]`.
   - blind: also unknown, but for the aggregate rather than for the masked `kin.speed`.
   - idle passed. Its applicability is decidedly false, so it is not applicable whatever the class.

   Nothing changed after this run. The failure comes from the node's reading, not from the formulas or the scenes.

## What was written
- **Class (s2):** `.atom "ru_aggregate" [subject, .lit "DEF-NRS-484B-018::electric_scooter"] []`.
- **Applicability (s4):** `(∃ roadway r. rel_occupies subject r) ∨ (∃ bicycle_lane_or_path b. rel_occupies subject b)`. The claimed `st.roadway` and `st.bicycle_lane_or_path` are the quantifier kinds, and `rel.occupies` anchors each variable to the subject.
- **Obligation (s5):** `kin_speed subject ≤ Units.mph 15` (m/s).
- **s1 and s3:** the node's residues (scope none), so not written.
- **Narrowings:** none of my own.
- **Witnesses:**
  - forbid: roadway, 8 m/s.
  - permit: bicycle lane, 5 m/s.
  - idle: sidewalk, 8 m/s, with a roadway beside it but not overlapped.
  - blind: roadway, speed `none`, `kin.speed` masked.
  - branch_1: bicycle lane, 8 m/s, expects violated.
  - branch_2: roadway, 5 m/s, expects compliant.

## Why I finished — the node is wrong (span s2)
The run's reading classifies `DEF-NRS-484B-018::electric_scooter` as:
- **included:** none
- **unresolved:** ru.electric_scooter, ru.motor_vehicle, ru.motorcycle, ru.bus, and every other listed class.

By the `ru.aggregate` contract, the atom is true only when the user carries an included class. With no included class it is never true: it is unknown for an electric scooter (and for every other unresolved class) and false otherwise. So the binder class is never decidedly satisfied, and the rule can only return `unknown` or `not_applicable`. No forbid, permit or blind witness can pass, whatever the formulas say.

**What the plan or reading must change:** classify `ru.electric_scooter` as **included** under `DEF-NRS-484B-018::electric_scooter`. The definition (NRS 484B.018, "electric scooter") names exactly the devices that class represents, so this is the natural fix. Classes the definition does not cover should be excluded rather than unresolved. Alternatively, if the representation decisions allow it, map s2 to the class atom `ru.electric_scooter` directly. Once the aggregate has an included class, the rule and witnesses as written should be expected to pass without change.

## Note
By mistake I ran one shell command other than the gate: a no-op `echo skip`. It changed nothing.
