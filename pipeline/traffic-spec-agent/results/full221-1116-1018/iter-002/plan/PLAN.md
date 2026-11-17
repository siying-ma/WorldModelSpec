# Plan — iteration 2 (returned law `NRS-484B-267-2f`)

The law came back because `NRS_484B_267_2f_o2` composed `NRS_484B_607_1a` … `NRS_484B_607_1d`. Those
nodes are not accepted and are not in this iteration's plan. NRS 484B.607 is also missing from the
texts the harness supplies for the bracketed ids, so its lines are not part of the corpus this run
formalizes. The validator confirms this: it accepts `s11r` as a residue. It would return a residue
on a reference to a law that is in the corpus.

No `aggregates.jsonl` records are needed (no law-local aggregate).

## `NRS_484B_267_2f_o1` — branch "(1) Approaches the driver's vehicle"

- **What changed:** nothing. This is the iteration-1 record, re-emitted word for word. The return
  reason did not concern it, and in iteration 1 the validator accepted it.
- **Trigger:** an authorized emergency vehicle or a regulatory-agency official vehicle that is
  moving or preparing to move, shows a flashing red lamp facing front, and lies ahead of the
  subject within the approach reach.
  - The lamp words are borrowed from `DEF-NRS-484A-480-3` through a `definition` reference on `s4`.
  - "Preparing to move" (`s12`) is read through visible indications: a movement, a hand signal or
    a turn indicator. This is disclosed as an `observable_reading`.
- **Condition (`s8`):** that vehicle approaches the subject. It is moving, with the subject ahead
  of it.
- **Duty:** compliance with the subsection 1 nodes `NRS_484B_267_1a`, `NRS_484B_267_1b_o1`,
  `NRS_484B_267_1b_o2` and `NRS_484B_267_1c` (all planned).
- **What would reverse it:** a change to those composed records' binder names, or a label showing
  that the "approaches" condition needs more than a vehicle closing with the subject ahead of it.

## `NRS_484B_267_2f_o2` — branch "(2) Stops"

- **What stays the same:** the trigger, the exception (`s6`, a police officer directing traffic)
  and the condition are as in iteration 1. "Stops" (`s10`) is `drv.motion.complete_halt` of the
  approached vehicle. It has held since an observation where the trigger held, linked by the past
  mirror of until.
- **Why the concept record is repeated:** the validator would not accept a call to
  `drv.motion.complete_halt` while the concept was neither accepted nor proposed in this plan. Its
  iteration-1 coding was rolled back for a scope violation. The record here repeats the proposed
  contract word for word: same formal `a`, same parameter `speed_tol`, same definition
  `DEF-NRS-484A-255`. So it is the same record, not a competing one.
- **Why the duty is not expressible:**
  - The obligation `s11` "proceed" gets its whole content from `s11r` "as required pursuant to NRS
    484B.607".
  - That law is outside the corpus. It cannot be composed, and the rules forbid writing its
    content inline.
  - So `s11r` is a residue, and only a residue can carry the manner of proceeding.
  - The record's `obligation` says this and is **not weakened**. "Proceed" is not reduced to "keeps
    moving", and the duty is not rebuilt from what the move-over law is assumed to say.
  - This is not an atom or operator gap: no atom or operator is missing. What is missing is the
    composed law's text.
  - The forbid and permit scenarios describe what the law requires. A coder cannot write a formula
    that decides them. It should declare `s11` unstatable instead of writing a vacuous obligation.
- **What would reverse it:** the lines `NRS-484B-607-1a` … `1d` entering the run's corpus. The
  record would then go back to the iteration-1 version, composing those four nodes `as:
  compliance` with `subject` mapped to `subject`.

## For the operator

- `NRS-484B-267-2f` cites `NRS-484B-607-1a` … `1d` by bracketed id, but this run's corpus does not
  include those lines (probably a train/test split or a corpus-selection issue). Branch (2) of the
  law can be formalized only once those lines are in the run, or the law should be closed as
  partly inexpressible. Branch (1) (`_o1`) is complete as it stands.
- The `drv.motion.complete_halt` concept was rolled back after a coding-session scope violation
  (stray `.runtime/tmp` files). It still blocks many held nodes. The record here does not change
  it.
