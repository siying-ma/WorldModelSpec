# Plan — iteration 6

## NRS-484B-270-2b (returned: `NRS_484B_217_2` pin_mismatch)

The law came back because all three nodes compose `NRS_484B_217_2`, and their pin was to a version that has since been superseded. In iteration 5 a repair session revised `NRS_484B_217_2` and it was coded again. The library now lists it as composable (build). This record is still the node the words name: "Except as otherwise provided in … 484B.217 [NRS-484B-217-2]". Its duty is the same no-passing-zone prohibition, and its subject binder is the same. So the fix is to plan the law again against the current record. No other node stands in for it. Nothing else in the returned reason touches these records, and no failing case or label mismatch was reported. Each node therefore keeps its segmentation, its mappings, its operationalization and its scenarios as they were in iteration 4, where the validator accepted them. The parameter proposals have been dropped, because every parameter named is now in the catalogue.

**`NRS_484B_270_2b_o1`: "shall exercise due care".** This is a surrogate. Due care is read only through the outcome of the pass for the rider: no `rel.contact`, and no evasive braking by the rider (`kin.accel_longitudinal` below −`p.rider_evasive_decel`) while the two are side by side. The trigger is the rise of `drv.interaction.overtake_pass` against a bicycle, electric bicycle or electric scooter that is moving and aligned with the subject. Reference span b11 composes the five rules as `unless`, scoped to the authorization b12. b12 is a residue of scope `none`: it relaxes 484B.213 and 484B.217, and leaves this duty as it is. Reversal signal: an operator ruling that the authorization should be modelled as an exception to the other rules rather than a residue here.

**`NRS_484B_270_2b_o2`: "pass to the left … at a safe distance".** This applies only where the rider's lane has a single lane in its direction (`st.lane_adjacency` count = literal one). While the two are side by side, the rider must be on the subject's right (`rel.bearing` lateral component < 0). The `rel.surface_gap` must be at least the larger of the literal 3 ft and `p.bicycle_pass_safe_gap`. Reversal signal: a label that reads "safe distance" as growing with speed.

**`NRS_484B_270_2b_o3`: "shall not move again to the right side … until safely clear".** Until the rider is behind the subject at a time-headway gap (the following headway for the surface, times the rider's speed), the subject must not turn its heading to the right of the rider's lane (`drv.lane.heading_right_of_carrier` against `p.course_departure_sin_tol`). Reversal signal: a label that judges a slow drift back within the course tolerance as a move to the right.

## For the operator

Nothing new. The `pin_mismatch` was a consequence of the iteration-5 repair of `NRS_484B_217_2`. Re-planning against the current record resolves it.
