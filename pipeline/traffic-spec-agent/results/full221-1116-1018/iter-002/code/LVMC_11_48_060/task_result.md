# LVMC_11_48_060 — task result

**Final verdict: OK** (6 witnesses, 9 names, composes nothing). 4 of 6 gate runs used.

## Gate runs
1. `UNUSED_CLAIM` on the untouched skeleton (`.tt` formulas). I ran it by mistake before editing.
   Changed after it: wrote the class, the applicability, the obligation and the five planned witnesses.
2. `VACUOUS`: five leaves of the exception were never exercised:
   - the `dev_regulatory_sign_code` atoms in the stretch cells (every sign in the scenes was a truck_route sign);
   - the `rises(onTR-any)` disjunct inside the exception's inner stretch.

   Changed after it:
   - added a keep_right regulatory sign governing street S to every scene, so that the sign code decides the cells;
   - added `branch_2`: the truck crosses a truck-route junction X (lying on W1 and W2) in one sample during the stretch, then halts beyond the delivery dwell and enters B.
3. `WITNESS_FAIL`: `branch_2` was expected not_applicable but came out compliant. The rule engages at the rise onto X, and the obligation holds there because X shares W1 with A. Under the aggregation, compliant outranks not applicable. The witness was wrong, not the formula, so I changed its expectation to compliant.
4. `OK`.

## How the record is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-305::truck")`.
- onTR(g): `rel_occupies(subject, g)` for a `travel_region` g that some `regulatory_sign` d governs (`dev_governs(d, g)`), where d has `dev_regulatory_sign_code(d, truck_route)`.
- Trigger (s4): `rises(∃g onTR(g))`.
- Stretch (s1/s2/s3): the since-step is φ = (no onTR, and occupies some `highway`) or `rises(onTR-any)`, as the record writes it.
- Start of the stretch (s4): ψ(g2) = ∃g1 onTR(g1) ∧ ∀ highway w (`st_on_way(g1,w)` → ¬`st_on_way(g2,w)`).
- Obligation (s3): ∀ travel region g2 (onTR(g2) → ¬since(φ, ψ(g2))).
- Exception (s5): ∃g2 onTR(g2) ∧ since(φ, parked ∧ cell ∧ since(φ, ψ(g2))). This is the same stretch, re-bound with its full selection, with `drv_motion_parked(subject; p.halt_speed_tolerance, p.delivery_halt_min_duration)` at some cell of it.

## Choices the node left open
- The parked observation is required to be a cell of the stretch (on a street, off every truck route) and to lie after the truck-route observation that starts it. This is my reading of the record's "within the stretch"; I did not declare it as a narrowing.
- Every quantified variable has its own name, tagged by where it is used, so no quantifier shadows another.
- `narrowings` is empty: the readings applied are the record's own.

## Witnesses
- All witnesses share one map: W1 with lanes A and A2, street WS with roadway S, and W2 with lane B.
- Samples are 5 s apart, with the truck at 10 m/s or halted.
- `window` starts at 5 s, because the rise onto A at the first instant would read the unobserved previous observation.
- forbid → violated, permit → compliant, idle → not_applicable, blind (dev.governs masked) → unknown.
- branch_1 (95 s halt on S) → not_applicable.
- branch_2 (brief crossing of truck-route junction X, then the halt) → compliant.

## Why I finished
The gate returned OK.
