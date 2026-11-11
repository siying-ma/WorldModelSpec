# Plan — iteration 4 (replanning of five returned laws)

All five laws came back for one reason. Every node used the proposed concept
`drv.position.entered_via`, and that concept failed its gate three times: its `blind` witness came
out unknown because of window truncation (`rises`, `since`), not because of the atom the manifest
masks. None of the node records was itself at fault. The concept is now closed as failed. Rule 0b
says not to propose it again under its id. Its notion ("x is inside r on its current entry and came
in through c") is a condition on regions the node binds already, so each node now writes it in its
own formula using catalogued pieces only:

> x (or y) occupies i, and, read through a past operator, has occupied i at every observation since
> its latest entry into i (`drv.motion.entering_region`), at which entry observation it occupied
> carrier c (`rel.occupies`, `st.travel_region`, `st.lane_enters c i`).

Where the node judges the subject at its own entry, the carrier is the one the subject occupies at
that entry observation. This is how the accepted `NRS_484B_250_4_o1` and `NRS_484B_257_1_o1` read
it, so no history is needed there. Every other mapping, operationalization, composition and
scenario of the iteration-1 records is kept. The only change to scenarios is that their narratives
now say the recording covers the relevant entries. As a result, a `blind` verdict comes from the
masked atom and not from truncated history. Parameters are all in the catalogue now, so no node
proposes any. `NRS_484B_257_1_o1` is accepted, so it is left out, not re-emitted. No new concepts
and no law-local aggregates (`aggregates.jsonl` is empty).

## NRS_484B_250_1

**Decision.** The yield is judged at x's entry into i, through the approach carrier c it occupies
there. Span s4, "which has entered the intersection from a different highway", is the qualified
fact in full:
- y has occupied i ever since its latest entry;
- at that entry y was on a carrier c2 entering i;
- c2 lies on a highway h2 that c does not lie on.

The pair exception (s7–s9) reads the opposed directions of c and c2 the same way. The `unless`
composition with `NRS_484B_250_4_o1` on s6 is kept.

**Reason.** Same meaning as before, now without the failed concept.

**Reversal signal.** The gate reports that the inline `since` reading cannot be typed. That would
need an `operator` gap, not a re-proposed concept.

## NRS_484B_253_o1

**Decision.** "Within an intersection" (s2) is x in i since its latest entry, at which it occupied
approach c. Clause (a) of s5/s6 is y in i since its latest entry through an opposed c2. Clause (b)
(s7, immediate hazard) is unchanged.

**Reversal signal.** As for 250_1.

## NRS_484B_253_o2

**Decision.** The turning vehicle y is in i since its latest entry through c2, opposed to x's c.
"Having given a signal" (s9) is a left indicator or a left arm signal at some observation since y
last came onto c2 (`drv.motion.entering_region y c2`), with y on c2 or in i at every observation
since. "Having so yielded" (s8) stays a compliance composition with `NRS_484B_253_o1` (x → y): the
words require compliance with that duty.

**Reversal signal.** A label showing that an unsignalled turning vehicle is still owed precedence.
That would remove s9 as a condition.

## NRS_484B_257_1_o2

**Decision.**
- Through-highway vehicles that "have entered the intersection" (s11) are read as above, with c2
  lying on h2.
- s9 stays a compliance composition with the accepted `NRS_484B_257_1_o1`. The applicability
  duplicates o1's, so o1 is engaged at exactly this entry, and its compliance is the stop, or
  slowing at a yield sign, that the words refer to.

**Reversal signal.** A label treating a driver who ran the sign as still bound by this yield. That
would turn s9 into a statement of order only.

## NRS_484B_307_9b_o1 … o4

**Decision.** "Facing the signal" (c5) is a signal governing c or i. Here c is the carrier x
occupied at the entry observation of the passage that ends at the leaving being judged; that entry
is read through a past operator, and x stayed in i from the entry up to the leaving. The signal
condition (red together with a green arrow) is read at that same entry observation, where the words
fix it. Otherwise:
- o1 keeps its approach-convention search with a `history_boundary` scenario.
- o2 keeps the cycle count with the literal "two".
- o3 keeps the turn-prohibition reading.
- o4 keeps the closest-approach yield.

**Reversal signal.** The gate rejecting a past operator anchored at the leaving.

## NRS_484B_307_9a_o1, NRS_484B_307_9a_o2

**Decision.** Same inline entry reading for the carrier faced (b4). The exception composition with
`NRS_484B_307_9b_o1` is kept.

**Note.** For o2, which is judged during the passage, that exception never takes effect, because
9b_o1 is engaged only at the leaving. A cyclist going straight is therefore also held to 9a's yield
during the passage. That duty has the same content as 9b's condition (4), which `NRS_484B_307_9b_o4`
reads, so no verdict differs. The record is kept as it was.

**Reversal signal.** A label on a cyclist passage where the two disagree.

## For the operator

- `drv.position.entered_via` failed its gate because its `blind` witness was unknown from window
  truncation, not from the masked atom. The concept witness builder may need to give `since` and
  `rises` bodies a recorded history before the masked observation. The nodes no longer depend on
  the concept.
- The inline reading leaves a road user's "entered through c" unknown when its entry into i comes
  before the recording. This is intended (the `entering_region` contract makes the first
  observation unknown). Node witnesses therefore have to record the entries they rely on, and the
  scenario narratives say so.
