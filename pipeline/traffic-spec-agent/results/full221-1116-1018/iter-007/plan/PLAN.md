# Plan — iteration 7

## `NRS_484B_307_9c` (NRS 484B.307(9)(c))

**Decision.** There is one node, and its obligation is s4 “shall not enter the highway,”. The node is re-planned for two reasons:
- In iteration 6 the gate returned it with UNANCHORED_VARIABLE. The vehicular head `h` was tied to the subject only through position arithmetic.
- The iteration-7 repair was returned because the reference span carried elements.

**What is anchored.** The head `h` is now tied by relations, the chain being:
- `dev.governs(h, i)` for the intersection `i`, or `dev.governs(h, g)` with `st.lane_enters(g, i)`;
- `st_region_geometry_distance(subject, i)`, kept within `p.ped_traffic_signal_facing_reach`.

This distance adds no limit that the facing test does not already set. A head that is faced within that reach controls a junction no farther away. The distance only ties the junction to the pedestrian; `dev.governs` and `st.lane_enters` state that the head belongs to the junction.

**Index mapping.** The index maps “facing such a signal” to `dev.position, kin.heading, kin.position` only. I extended it here because the gate requires a structural anchor for a quantified device. The facing test itself is unchanged.

**The exception split.** The old reference span is now two spans:
- **s5, exception.** “unless permitted to proceed by another device” is carried by elements: a pedestrian head that governs the roadway or lane being entered, is faced by the subject, and shows walk or a flashing don't-walk with a countdown. Those are the permissions of 283(1)(d)(1) and (2).
- **s6, reference.** The bracketed reference composes the four 283 nodes as `exception`. The validator rejected a `definition` reading of it, because the words need those rules to apply or not apply.

**Composing 1d1.** `NRS_484B_283_1d1` binds a vehicle as its subject. Mapped to this pedestrian subject, it never engages. It is composed because the reference names that law, and the permission its words give the pedestrian is carried by s5's element. For 1d3_o1 and 1d4_o1, a forbidding pedestrian head means that rule judges the step, not this one (branch_3).

**What “enter” means.** “Enter the highway” is read as a step onto a roadway or lane. It counts only if the previous observation showed the subject on no roadway, lane, median or safety zone. This matches how the accepted 283(1)(d)(3)/(4) nodes read “entered the highway”. It also means a crossing continued from a median is not an entry, which agrees with the continuation permissions of (3)/(4).

**Reversal signal.**
- If the gate still finds `h` unanchored through `st.lane_enters`, tie `g` to the subject directly. Do not drop the governance link.
- If a labelled pedestrian under red-plus-arrow at a junction is judged not_applicable because the junction lies beyond the facing reach, re-examine the tie.

## For the operator

- `NRS_484B_283_1d1` states only the drivers' duty, and its binder is a vehicle. A reference that grants a *pedestrian* permission from 283(1)(d)(1) cannot engage through it. The permission is therefore carried by elements on 9c's exception span. A pedestrian-subject node for 283(1)(d)(1)'s permission, if one is ever planned, would let the composition carry it.
