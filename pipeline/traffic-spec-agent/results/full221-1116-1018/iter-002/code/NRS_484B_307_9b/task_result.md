# NRS_484B_307_9b — task result

## Final verdict: BARE_LITERAL (cannot be fixed in the two files)

```
BARE_LITERAL
   formula literals [] ≠ the node's declared literals [('2', 'count')]
```

The node declares the literal "two" (s6, value 2, unit count): "waits for two complete cycles".
The rule writes it in the only operator that can count cycles, `Formula.count edge sinceφ .ge n`,
whose bound `n` is a `Nat` (`twoCycles := 2`). `Formula.literals`
(`Core/Language/Formula.lean`, the function the gate uses to collect formula literals) reads only
`Term.lit`. Its `.count e s _ _` case returns `literals e ++ literals s` and never reports the
bound. No `Term` counts rising edges (`Term.aggregate .count` counts road users), so the text's
"two" cannot be written as a `Term.lit … .count` that means anything. Any `Term.lit 2 .count`
added to pass the check would be a made-up tautology.

**What needs to change (harness/Core, not the node):** either `Formula.literals` (and the gate's
literal collection) should report `count`'s bound as `(n, .count)`, or the gate should accept a
`count`-unit literal that is carried by a `Formula.count` bound. Once that is fixed, the files as
they stand are expected to pass. A diagnostic run (below) showed every other check passing.

## Gate runs (6 budgeted, 5 used)

After run 5 the only change was a comment in the witness file's header, describing the turn arcs.

1. **UNUSED_CLAIM** — an accidental run on the untouched skeleton. I invoked the gate command with
   a `| head` pipe appended, which I should not have done, and it spent a run. No information was
   used from it.
2. **BARE_LITERAL** — first full rule and 15 witnesses. This is when I found the count-bound issue
   above.
3. **WITNESS_FAIL** (diagnostic) — I temporarily added a tautological conjunct
   `.cmp (.lit 2 .count) .ge (.lit 2 .count)` marked `DIAGNOSTIC ONLY`, so the gate would go past
   BARE_LITERAL and check the witnesses. The rule had been restructured to reduce repeated
   sub-formulas (see below) and the witnesses grown to 28. Result: the four turning witnesses were
   rejected because the heading did not rotate with the yaw rate ("keeps the heading … but its
   yaw rate turns it −9/2°").
4. **OK** (diagnostic, still with the tautology) — turning scenes rebuilt as quarter-circle arcs
   whose heading rotates 4.5° per interval. All 28 witnesses passed, with no VACUOUS, PARAM or
   other finding: "28 witnesses, 24 names, composes nothing; narrowings declared by the coder: 2".
5. **BARE_LITERAL** — the diagnostic conjunct removed; this is the final submitted state, which is
   honest. It differs from run 4 only by that conjunct.

The submitted rule does **not** contain the diagnostic conjunct.

## How the rule is written (also in the rule file's header)

- **Class (s2):** the five admitted aggregates by id, plus `ru_motorcycle` for "trimobile", as one
  disjunction.
- **Occasion (event):** judged at the exit, `rises ¬occupies(subject,i)`. The latest entry,
  `rises occupies(subject,i)`, is reached with `since (¬entry) (entry ∧ …)`.
  - s1 + s3 are read at that entry: an occupied travel region c with `st_lane_enters(c,i)`, and a
    head governing c or i that shows circular_red with green_arrow(dir) and no circular_green.
    There is one disjunct per dir (left, right).
  - s4 is read at the exit: not the turn concept for the arrow's direction, and not a U-turn.
- **Obligation:** for every intersection i, at its exit, for every c and head d of the selection
  (read at the latest entry):
  - **(1) Halt.** A halt at a stop line or a crosswalk recorded as marking c: within
    p.stop_point_tolerance, ahead along c (`prim_region_offset_along > 0`), and not occupying the
    mark or i. Where every mark is decided not to mark c, the halt is at i's edge instead. The
    search goes back (`since`) and ends at the approach start or at the previous passage. The
    previous passage is met at its exit, which is equivalent because no halt inside i counts.
  - **(2)+(3) Wait.** At the last observation at rest at the place before the entry, the display
    has risen at least twice since the run at rest began (`count … .ge 2`), and no circular_green
    was shown during that run.
  - **(4) Sign.** Where this passage's exit (reached with `until` from the entry) is a right turn,
    no `no_right_turn` sign governs c or i; likewise `no_left_turn` for a left turn.
  - **(5) Yield.** `¬ since (¬entry) (¬Y)`: at every observation from the entry to the exit, while
    the subject's speed is above p.halt_speed_tolerance, there is no closest approach within
    p.conflict_horizon below p.conflict_centre_clearance, and no contact, with:
    - any pedestrian in a crosswalk that marks a carrier entering i;
    - any traffic-aggregate member occupying i.

## Choices the node left open (declared as `narrowings`, span s6, kind reading)

1. The wait and the no-change are read in the subject's **latest run at rest at the place** before
   the entry. If the search could pick any earlier observation instead, (2) would stay unknown even
   when the recorded wait is too short: the search's only bound is the previous passage, so it
   always reaches the trace start.
2. In the duties, the head is re-bound as one showing steady red with a **green turn arrow, left
   or right**, and a cycle is a rise of that display. The arrow's direction is told apart only in
   the applicability. I chose this so each sub-formula appears once in the obligation, which the
   gate's leaf adequacy (every leaf occurrence must move a decided witness) effectively requires.
   For a head showing a single turn arrow it is the same as the record.

Not narrowings, noted in the header:
- The count's run start is taken from `drv_motion_complete_halt`'s run. A road user at rest does
  not change place, so this is the run at rest at the place.
- The previous-passage end of the search is met at that passage's exit.

## Witnesses

There are 28: the 15 planned, plus 13 branch witnesses so that every leaf occurrence moves a
decided witness. The intersection geometry is in the header of the witness file. Every scene is
sampled at 50 ms, because the turn concepts' step is 50 ms. Occupancy is stated from body
rectangles. Every witness has `window` set from 50 ms, so the first observation (whose rises are
undecided) is not judged.

The added branches:
- **Place forms:** crosswalk marking c (compliant, wait too short, no halt), and intersection edge
  with no mark (compliant, wait too short, no halt).
- **Signs:** a right turn with a `no_right_turn` sign on another lane (compliant), and a right
  arrow with a left turn and a `no_left_turn` sign on i (violated) or on another lane (compliant).
- **Second head** governing only the opposite lane (compliant).
- **Subject with no class** (not applicable).
- **Car** already past the subject and moving away (compliant).
- **Green shown during the wait** (violated).

## Why I finished

I stopped with one run left, because no edit to the two files can change the verdict. The only
remaining verdict, BARE_LITERAL, comes from Core's
`Formula.literals` not reading `Formula.count`'s bound. The two files cannot fix that without
inventing a literal. The node itself is not wrong.
