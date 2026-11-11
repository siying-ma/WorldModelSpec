# Plan — iteration 3 (returned laws NRS-484B-250-1, NRS-484B-307-9a)
## NRS_484B_250_1
## NRS_484B_307_9a_o1
## NRS_484B_307_9a_o2
## For the operator

- Composed records that are repaired after a dependant is planned trigger `pin_mismatch` returns.
  These cost a planning iteration even though the dependant's words are unaffected. A re-pin
  that skips re-planning, when the composed node keeps its id and its binders, would avoid that.
