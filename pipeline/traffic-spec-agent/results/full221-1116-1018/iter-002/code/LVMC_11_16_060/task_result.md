# LVMC_11_16_060 — task result

**Final verdict: OK** (6 witnesses, 8 names, composes nothing)

## Gate runs
1. `OK` — first run, on the files as first written. Nothing changed afterwards.

## How the rule is written
- Subject class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- f2 (condition): `existsRegion "highway" w (rel_occupies subject w)`.
- f3 (exception): `not (existsDevice "speed_limit_sign" d (kind ∈ {maximum, structure_maximum, zone} ∧ existsRegion "travel_region" r (rel_occupies subject r ∧ dev_governs d r)))`. The kind is checked with `dev_speed_limit_sign_kind`, the attribute of the claimed `dev.speed_limit_sign`.
- f1 (obligation): `kin_speed subject ≤ Units.mph 25`, a `.metrePerSecond` literal.

## Choices the node left open
None. The record states the kind set for f3 (minimum excluded), the anchoring through the occupied travel region, and both narrowings (prima facie read as a maximum; posting read through the sign's presence). Those narrowings belong to the record, so they are not repeated in `narrowings`, which stays empty.

## Witnesses
- forbid: subject in a street lane, no signs, 35 mph → violated.
- permit: same at 20 mph → compliant.
- idle: a 45 mph maximum sign governs the lane → not applicable.
- blind: a speed limit sign whose governed regions are not observed (`governsObserved := false`), with `dev.governs` masked, at 35 mph → unknown.
- branch_1: only a 15 mph minimum sign governs the lane, at 35 mph → violated. This tests that a minimum is not a different limit.
- branch_2: subject off the highway → not applicable. This tests the f2 condition.

## Why I finished
The gate returned OK on the first run.
