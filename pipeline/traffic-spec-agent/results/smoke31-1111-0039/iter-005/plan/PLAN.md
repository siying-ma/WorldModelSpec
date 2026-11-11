# Plan — NRS-484B-253 (iteration 5)

## NRS_484B_253_o1 (accepted, re-emitted unchanged)

Accepted in iteration 4, with the gate passing all 7 witnesses. It appears again here exactly as accepted: same segmentation, same obligation span s4 and same atoms. It sets the roles the law's shared spans carry, and o2 now uses the same roles.

## NRS_484B_253_o2 (replanned)

**Why it came back.** There were two reasons:

1. **Segmentation.** o2 gave span s2 "within an intersection" the role `condition`, but o1 gives it `trigger`. A span must have one role across all of the law's nodes. o2 now gives every span it shares with o1 o1's role: s1 `subject`, s2 `trigger`, s3 `trigger`. The spans that only o1 needs (s4–s7) are `sibling`. In o2, s1 names the turning vehicle y, the driver that "such driver" in s8 refers back to. It claims the same vehicle aggregate as for x, so the binder's class does not change. The mapping for s2 copies the mapping index entry ("within an intersection" → entering_region, rel.occupies, st.intersection, st.lane_enters, st.travel_region), now applied to y.
2. **Witness failures (forbid, blind, branch_3, branch_4 came out compliant).** The old record treated "having so yielded" as "y complied with NRS_484B_253_o1 at every observation since its entry, up to now". That reading contradicts the law. When x arrives later and enters the intersection, x is within the intersection while y is still turning, so o1 counts y as not yielding at exactly the observation where o2 should bind x. The condition was therefore false in every violating scene, and the blind scenario was decided before the masked signal could matter.

   The words are in the perfect tense: y yields first, and only then may it make the turn. "Having so yielded" is now judged up to the onset of the turn:
   - There is an observation O inside the intersection where y's left-turn motion rises (`drv.motion.turning_left` within i).
   - o1 {x→y} was complied with at every observation from y's latest entry into i up to and including O.
   - y has stayed in i from O until now. This also carries s11 "may make such left turn" and s15 "the vehicle making the left turn".

   A vehicle that comes close only after O does not undo the yield. A vehicle that was a hazard at O makes the condition false (branch_2, which differs from forbid only in this fact).

**What else changed.** `drv.motion.heading_change_since_entry` and its parameters were dropped. The turn being under way is now read from the observed onset plus y's continued presence in i, so a pause mid-turn still counts as making the turn.

**What is kept.** The signal reading (s9) is the same as before: a left indicator or a left hand signal since y's recorded arrival on c2. The opposite-direction test still compares the carriers' designated directions. The yield is still judged at x's entry into i.

**Composition.** s8 composes NRS_484B_253_o1 as `compliance` with {x→y}. The referent ("such driver": a vehicle within the intersection that intends to turn left) is carried in full on s1–s3 for y. The composition is not used in place of that referent.

**Residue.** s10 "when and as required" stays a residue. No bracketed id says which signalling rule it names.

**Reversal signals:**
- **Onset fails as a boundary:** if the gate shows that a rising edge of `turning_left` within i misses the turn onset on recorded traces (for example, a vehicle that enters the intersection already turning), the onset should become the entry observation when y is already turning there.
- **s10 resolved:** if the operator resolves s10 to NRS_484B_413_2, s10 becomes a `compliance` composition.

## For the operator

- s10 "when and as required" probably refers to NRS 484B.413 (turn signals). The library has `NRS_484B_413_2`, but the text gives no bracketed id, so it is left as a residue. If you add the reference, s10 becomes a composition.
- The failed concept `drv.position.entered_via` lists o1 and o2 among its users, but neither plan record claims it. Both records read the approach carrier directly through `drv.motion.entering_region` and `st.lane_enters`. If the coded o1 calls it, that call came from the coding session, not from this plan.
