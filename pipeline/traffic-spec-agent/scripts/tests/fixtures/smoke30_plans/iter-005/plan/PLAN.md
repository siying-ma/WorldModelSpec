# Plan — iteration 5
## `NRS-484B-307-9a`
### `NRS_484B_307_9a_o1` — "may enter the intersection only to make the movement indicated by the green turn arrow,"
## For the operator

- **Main case returns unknown.** The most common breach of this law is a car going straight, or turning against the arrow, under a red with a left or right arrow. On such a recording this rule reports `unknown`, not `violated`. The cause is the reading: it classifies `ru.motor_vehicle` as unresolved in `DEF-NRS-484A-135::motorcycle`, `DEF-NRS-484A-125::moped`, `DEF-NRS-484B-017::electric_bicycle` and `DEF-NRS-484B-018::electric_scooter`. The composed exception (paragraph (b) applies) therefore cannot be decided for a car.
  - **The fix is in the reading.** If those four aggregates decided `ru.motor_vehicle` (excluded, or covered by `ru.motorcycle` / `ru.moped`), the case would be decided with no change to this record.
  - The witnesses here avoid the case on purpose. They do not show that it works.
- **Alternative reading, not adopted.** The exception could instead read "where (b) permits": a road user of (b)'s classes that also met conditions (1)–(4). A car that did not stop and wait two cycles would then be decided `violated` whatever its class (unknown ∧ false = false).
  - It cannot be written with the composition modes available. `rule` counts a rule that is not engaged as complied with, so a composed rule with unknown applicability and a failed obligation gives unknown, not false.
  - The only other way is to copy (b)'s stop-and-wait history into this node, which duplicates the content of the composed nodes.
  - I kept the `exception` composition. Adding a composition mode for "applies and is complied with" would make this reading writable.
