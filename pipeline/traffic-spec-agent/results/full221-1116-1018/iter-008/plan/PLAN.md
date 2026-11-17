# Plan — iteration 8

## `NRS_484B_307_4b` (NRS-484B-307-4b), replanned after gate WITNESS_FAIL

**Returned reason.** The `branch_1` witness expected `not_applicable` and got `violated`. In that witness the pedestrian head shows walk. The old record handled the walk permission only by composing `NRS_484B_283_1d1` as an exception, with subject mapped to subject. But that node's subject binder is a **vehicle**: it states the drivers' duty to give way. So `ruleApplies(NRS_484B_283_1d1, {subject ↦ pedestrian})` is never true for a pedestrian subject, and the exception never fired. No accepted node of NRS 484B.283 states the pedestrian's permission ("may proceed") as a rule whose subject is the pedestrian:
- 1d1 judges drivers.
- 1d2 judges only the end of the countdown.
- 1d3_o2 and 1d4_o2 judge a pedestrian already on the roadway.

**Decision.**
- **New span s5.** "until permitted to proceed by another device" is now its own exception span. An element carries it, reading the pedestrian signal directly:
  - It permits when a `dev.pedestrian_signal` shows `walk`, or `dont_walk_flashing` with its countdown.
  - The subject must face that head, using the facing test of the accepted 1d1 node (`p.ped_signal_facing_cos`, `p.ped_signal_facing_reach`).
  - The head must govern the roadway entered, or a lane of the same highway that the subject occupies. This is 1d1's own anchor.
  - The permission is part of the obligation, so a permitted entry is `compliant`. The walk witness `branch_1` now expects `compliant`.
- **Reference span s6.** "as provided in NRS 484B.283 [...]" keeps its execution compositions: exceptions for 1d1, 1d2, 1d3_o2 and 1d4_o2.
  - The validator refuses a `definition` reading of this span. It says "as provided in" requires the rules.
  - The 1d3_o2 and 1d4_o2 exceptions keep a real effect: a pedestrian lawfully continuing a crossing it began under NRS 484B.283.
- **Kept from iteration 7.** The s1–s4 mappings, the highway anchoring chain (head → intersection → highway → roadway), and the s4 narrowing are unchanged. They passed the gate apart from this witness.
- **New scenarios.**
  - `branch_4` / `branch_5` differ only in the countdown: flashing with countdown is permitted, without countdown is violated.
  - `branch_6` has no pedestrian head in the scene, so the duty binds the subject alone.
  - `branch_7` has a walk head that the subject does not face.

**What would reverse this.**
- An accepted node of NRS 484B.283 whose subject is the pedestrian and whose applicability is the permission to proceed. The s5 element would then become a composition.
- A gate refusing a device quantifier anchored only through `dev.governs` and `rel.occupies` on the roadway entered.

## For the operator

- The composition `NRS_484B_283_1d1` as `exception` (required: the validator demands an execution composition for every law that s6 names) is **inert** for this node. Its subject binder's class is vehicle, and this node's subject is a pedestrian. The permission that 1d1's words grant pedestrians is read directly from the device in s5. The same holds for NRS_484B_307_9c and NRS_484B_307_2b, which compose 1d1 the same way. Two possible fixes, either of which would let the composition carry the permission itself:
  - a pedestrian-side node of NRS-484B-283-1d1 (the permission to proceed), or
  - a composition form that maps a composed rule's quantified party (its pedestrian `p`) to this node's subject.
- The `NRS_484B_283_1d2` exception is engaged only at the observation where its countdown ends. It cannot excuse an entry made during the countdown, so that permission is also read in s5.
