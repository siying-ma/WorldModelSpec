# PLAN — iteration 8

## NRS-484B-307-9a

`NRS_484B_307_9a_o2` is accepted. It is left out of this blueprint and not re-planned.

### `NRS_484B_307_9a_o1`: re-planned. Returned for gate WITNESS_FAIL, aggregate_unresolved on paragraph (b)'s classes

**Why it failed.** Every violation of this duty is a straight-through passage or a turn opposite the arrow. Those are exactly the movements paragraph (b) covers (`NRS_484B_307_9b_o1`'s applicability). So in every violating witness, the earlier exception "not engaged where `NRS_484B_307_9b_o1` applies" was decided by x's class alone. The run's reading leaves `ru.bus` unresolved under the motorcycle, moped, electric-bicycle and electric-scooter aggregates. That made the exception unknown, so the verdict was unknown and not violated (forbid, branch_3, branch_5). It also made blind unknown for the aggregate, not for the masked signal.

**Decision.** The exception now carries what paragraph (b) actually provides. Its words are "may proceed straight through or turn in the direction opposite … **if**: (1) … (4)". That is a permission that holds only when its conditions are met. It is not an exemption for every member of the named classes. The exception is a conjunction of three parts:
- **E1:** `NRS_484B_307_9b_o1` applies. This is `ruleApplies`, covering class, signal and movement.
- **E2:** condition (1), the halt before entry, is met as a fact. It is written in this node's formula with the approach convention that `NRS_484B_307_9b_o1`'s obligation states. It is not read through that rule's verdict, because a composed rule counts as complied with where its engagement is unknown.
- **E3:** `NRS_484B_307_9b_o2`, `_o3` and `_o4` are complied with. These are conditions (2) to (4), composed `as: compliance`.

The result: a vehicle that went straight on red without halting is violated whatever its class under (b), which is the law's verdict. A road user of (b)'s classes that met all four conditions is excused (branch_6). If (b)'s class is unresolved and condition (1) was met or is undecided, the verdict stays unknown (history_boundary). Branch_1, a motorcycle with no halt, now expects violated. Before, the composition wrongly made it not_applicable.

**Spans and how they are carried.**
- The reference span b2 ("Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],") must be carried by compositions only, so the validator returned the first cut that split the exception words off.
- Condition (1)'s atoms are claimed on b5 ("may enter the intersection"). Its words name the entry that the halt must come before. The atoms are the mapping index's set for 9b's "(1) the person stops before entering …".
- Element b5 differs from the index entry for the same words in `NRS_484B_307_9a_o2` (entering_region, rel.occupies, st.intersection). It keeps all of those atoms and adds the halt-before-entry atoms that the exception needs on that entry.
- All other mappings (b1, b3, b4, b6, residue b11) and the obligation are kept unchanged. The reason for return does not concern them.

**Reversal signal.** Reverse to the plain `exception` composition if the operator's reading changes so that ordinary motor-vehicle classes (`ru.bus`, `ru.motor_vehicle`) are excluded under the paragraph (b) aggregates. Then the class alone decides E1. Also reverse if the reviewer rules that "except as otherwise provided" exempts the classes regardless of (b)'s conditions.

**Disclosed weakness.** Conditions (2) to (4) are carried through compliance with the composed rules. Where E1 is unknown (class unresolved) and condition (1) was met, a failure of (2), (3) or (4) gives unknown rather than violated. Writing those conditions inline (the two-cycle wait, the device prohibition, the yield) would decide that case. That is deferred because it would restate three accepted nodes' bodies.

## For the operator

- **Reading of the paragraph (b) aggregates.** `ru.bus` is unresolved under DEF-NRS-484A-135::motorcycle, DEF-NRS-484A-125::moped, DEF-NRS-484B-017::electric_bicycle and DEF-NRS-484B-018::electric_scooter. The definitions classify by wheels, motors and weight, which a class label does not show. The consequence: any car-class road user is "possibly a motorcycle" for every rule that reads these ids. Excluding the ordinary motor-vehicle classes where the class contract settles it (a bus or truck is not "designed to travel on not more than three wheels", and a bus does not weigh under 100 pounds) would decide many verdicts that are now unknown.
- **The accepted sibling `NRS_484B_307_9a_o2` still uses the bare exception** "not engaged where `NRS_484B_307_9b_o1` applies". It therefore excuses a paragraph (b) road user from the yield duty even when it did not meet (b)'s conditions, and it is unknown for unresolved classes going straight. This plan cannot re-plan it because it is accepted. A future repair should align it with the E1 ∧ E2 ∧ E3 exception above.
