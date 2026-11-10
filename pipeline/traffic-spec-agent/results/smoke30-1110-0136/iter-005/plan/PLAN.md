# Plan — iteration 5

## `NRS-484B-307-9a`

`NRS_484B_307_9a_o2` is accepted. It is left out of this file and is not re-planned.

### `NRS_484B_307_9a_o1` — "may enter the intersection only to make the movement indicated by the green turn arrow,"

**Decision.** I kept the iteration-4 record word for word: the segmentation, elements, compositions, applicability, obligation, occasion, narrowings and `planned_on` are unchanged. Only the scenarios changed.

**Why the scenarios had to change.** The gate's verdict of `unknown` did not come from a defect in this node's formula. It came from the exception at `a2`: "Except as otherwise provided in paragraph (b)", which composes `NRS_484B_307_9b_o1`–`_o4` as `exception`.

- Paragraph (b)'s nodes apply when two things hold:
  - the road user belongs to one of the classes (b) names;
  - it makes a through movement, or a turn opposite a left or right arrow.
- The run's reading leaves the witness car's class (`ru.motor_vehicle`) *unresolved* in four of those classes: `DEF-NRS-484A-135::motorcycle`, `DEF-NRS-484A-125::moped`, `DEF-NRS-484B-017::electric_bicycle` and `DEF-NRS-484B-018::electric_scooter`.
- The old forbid case had a car going straight under a left arrow. That is exactly the movement (b) covers, so whether (b) applied turned only on the car's class. That class is unresolved, so the exception was unknown and so was the verdict.
- `_o2` passed with the same compositions because its witnesses are left turns under a left arrow, which (b) never covers.

**The new scenarios** test every part of the obligation (left, right and straight against the arrow shown) where (b) cannot apply whatever the class:

- **Violations** use a lone `green_arrow(u_turn)`. It is a green turn arrow under the words, and every node of (b) reads only a left or right arrow. This covers forbid (left turn), branch_2 (straight) and branch_3 (right turn).
- **Compliant cases** are a turn in the arrow's own direction (permit: left under left; branch_4: right under right). That movement is neither through nor opposite, so (b) does not apply.
- **The exception path** is branch_1: a road user that carries only `ru.motorcycle`, which is decided to be in (b)'s class, so (b) applies.
- **blind** now uses the u-turn arrow. Its unknown therefore comes from the masked `kin.yaw_rate` alone, not from an aggregate.
- **Coder instruction:** any further branch witness that expects a decided verdict must also stay outside (b)'s movements, or use a class the reading decides.

**What would reverse this.** I would restructure the exception (see below) if either:
- the operator wants a car going straight under a left or right arrow to be judged `violated` without first changing the reading; or
- a gate rejects witnesses that avoid (b)'s movements.

## For the operator

- **Main case returns unknown.** The most common breach of this law is a car going straight, or turning against the arrow, under a red with a left or right arrow. On such a recording this rule reports `unknown`, not `violated`. The cause is the reading: it classifies `ru.motor_vehicle` as unresolved in `DEF-NRS-484A-135::motorcycle`, `DEF-NRS-484A-125::moped`, `DEF-NRS-484B-017::electric_bicycle` and `DEF-NRS-484B-018::electric_scooter`. The composed exception (paragraph (b) applies) therefore cannot be decided for a car.
  - **The fix is in the reading.** If those four aggregates decided `ru.motor_vehicle` (excluded, or covered by `ru.motorcycle` / `ru.moped`), the case would be decided with no change to this record.
  - The witnesses here avoid the case on purpose. They do not show that it works.
- **Alternative reading, not adopted.** The exception could instead read "where (b) permits": a road user of (b)'s classes that also met conditions (1)–(4). A car that did not stop and wait two cycles would then be decided `violated` whatever its class (unknown ∧ false = false).
  - It cannot be written with the composition modes available. `rule` counts a rule that is not engaged as complied with, so a composed rule with unknown applicability and a failed obligation gives unknown, not false.
  - The only other way is to copy (b)'s stop-and-wait history into this node, which duplicates the content of the composed nodes.
  - I kept the `exception` composition. Adding a composition mode for "applies and is complied with" would make this reading writable.
