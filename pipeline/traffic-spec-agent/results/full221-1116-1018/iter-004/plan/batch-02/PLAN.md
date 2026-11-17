# Plan — iteration 4, batch 02

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts. All ten nodes validate `accept`.

## NRS-484B-283 (1)(a), (1)(b), (1)(d)(1)–(4): eight nodes, re-emitted unchanged

`NRS_484B_283_1a`, `NRS_484B_283_1b`, `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o1` and `NRS_484B_283_1d4_o2` came back for one reason only: a pin mismatch on `LVMC_11_30_060_A`. A repair session revised that node this iteration, it passed the gate (OK, 10 witnesses) and it is accepted under the same id. That makes it the successor the return asks for. Re-planning the composition on span `r` ("Except as otherwise provided in NRS 484B.287 [... LVMC-11-30-060-A ...]") pins it to the current record. No word or mapping was wrong, so every record is kept exactly as it passed the validator in iterations 1–3: same segmentation, elements, compositions, operationalizations and scenarios (rule 11).

The revised `LVMC_11_30_060_A` still has the same meaning here: a pedestrian crossing a roadway outside any crosswalk owes the yield. As an exception it therefore never overlaps 1a's crosswalk pedestrian, and it only removes the out-of-crosswalk crossings from the pedestrian duties in 1b and 1d.

The nodes also compose `NRS_484B_287_1c` and `NRS_484B_287_1e`. Neither is accepted yet: they failed the gate and went to node repair. Those compositions stand, because the reference names those laws, and the nodes wait for them.

**Reversal signal:** a further pin mismatch, or a revision of `LVMC_11_30_060_A` that changes its applicability to cover pedestrians inside a crosswalk.

## NRS-484B-307 (8)(d): `NRS_484B_307_8d`, now blocked by an operator gap on s7

This record is the iteration-3 repair, kept whole: its wording of s4 fixed the earlier witness failure. The gate then returned it as BARE_LITERAL.

The law states the figure "two" ("waits for two complete cycles"), so rule 8 requires it as a declared literal `(2, count)`. But the only operator that counts rising edges, `Formula.count`, takes its bound as a bare Nat that `Formula.literals` does not report. No faithful formula can carry the figure. The two ways round it are both forbidden:
- adding a made-up `Term.lit 2 count` conjunct, or
- dropping the figure from the literals.

This is the same defect the repair of `NRS_484B_307_9b` filed as G87. Span s7 is now mapped to its nearest atoms, with an `operator` gap proposing a count whose bound is a count-typed Term, or literal reporting for `Formula.count`. The law stays blocked until the operator decides.

**Reversal signal:** G87 resolved, or Core reporting `count`'s bound as a literal. Once that happens, the record codes as written.

## NRS-484B-307 (8)(a): `NRS_484B_307_8a_o2`, re-planned

`o1` and `o3` are accepted and are left out of this file; they are not re-planned. `o2` was returned because its roles for the paragraph (c) words (s7–s15) were `exception`, while the accepted `o3` segments them as `condition` (s7, s9, s10, s11, s13, s14, s15) and `subject` (s8, s12). The role of words is fixed once a node of the law is accepted.

`o2` now uses `o3`'s roles exactly. s16–s18, the yield duty only `o3` needs, are `sibling`. The elements are `o3`'s mappings, word for word.

The permission of paragraph (c) is still read as a release from the duty to remain stopped, so the applicability states that the duty does not apply where those conditions hold. The conditions themselves are the full referent of the s3 requirement: the halt itself at the stop line, else the crosswalk, else the intersection's edge, with `o1`'s zone and history bound. A weaker fact is not substituted.

`o3` was not composed instead, for two reasons:
- The reference on s5 names only NRS-484B-307-8d.
- `o3`'s applicability needs the footprint already inside the intersection. A lawful right turn on red passes through the near crosswalk first, and that entry would then be read as a violation.

So the permission here no longer requires the subject to be in the intersection, and `branch_1` now tests the entry into the crosswalk. Paragraph (d) stays a composition of `NRS_484B_307_8d` on s5, as an exception. The intentions on s10 and s14 reuse the catalogue ids `int.right_turn` and `int.left_turn`.

**Reversal signal:** the validator rejecting a negatively read `condition` span. If that happens, compose `o3` on s5 and narrow the crosswalk case explicitly.

## For the operator

- **G87 needs a decision.** It now blocks both NRS-484B-307-9b and NRS-484B-307-8d (the operator gap on s7 here). Either fix closes both: let `Formula.count` take a Term bound in unit count, or have the literal collection report its Nat bound as `(n, count)`.
- **The (8)(d) exception in `o2` is narrower than the law.** `NRS_484B_307_8d`'s applicability, like the accepted `o3`'s, starts at the rider's entry into the intersection. So `o2`'s exception for paragraph (d) does not cover a rider who has waited two cycles and is crossing the near crosswalk on the way in; until the rider reaches the intersection, `o2` may report that crossing as a violation. Widening both yield nodes to an event of "entered the crosswalk marking the approach, or the intersection" would close this. That needs `o3` to be re-opened, and `o3` is accepted, so it was not done here.
