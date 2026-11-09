# NRS_484B_307_6a — coding session result

**Final verdict: OK** (`8 witnesses, 9 names, composes nothing`), on the first gate run.
Budget used: 1 of 6 gate runs.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing — the session ended here |

Before running the gate I read the Core files the writing depended on and that the surface did not
settle: `Language/Semantics.lean` (the three-valued evaluator, `aggregateMembership`, the quantifier
treatment of a region whose kind is unknown), `Foundations/Temporal.lean` (`sinceAll`, `risesAll`:
strong since is `ψ ∨ (φ ∧ since')` with the unobserved past as the head, so it is decided false at
the first observation when both operands are false there, and unknown when `φ` holds and `ψ` does
not), `Language/Rule.lean` (`verdictAt`: a false applicability is not applicable whatever the
obligation), `Runtime/Grounding.lean` (`episode`, admission), `Runtime/Admission.lean` (no structure
may carry an abstract kind — hence `travel_region` is a formula's word only, never a label),
`Runtime/Manifest.lean` (masking `dev.traffic_signal` marks the kind unobserved and leaves the
indications alone, so the `blind` witness is unknown through the device-kind read), `Vocab/Atoms.lean`
and `Ontology/Device.lean` / `Ontology/Structure.lean` (the indication spellings, including the
`<state>(<dir>)` arrow form, and `lane`/`intersection` both refining `travel_region`).

## What the node left open, and what I chose

1. **"alone" against the indication enumeration.** The record fixes the reading ("that state being
   displayed and no other state of the head being displayed at the observation") but not the list.
   I negated every other spelling of `SignalIndication`, the enumeration's `unknown` among them:
   a head one of whose faces the source cannot read does not show the steady yellow *alone*, so the
   trigger is not established there. The alternative — leaving `unknown` out of the list — would
   assert the trigger on a head with an unreadable face, which is the worse reading of the words.
   This is the enumeration's own content, not a narrowing of the span.
2. **Which quantifier over the selected carrier, junction and head.** The applicability selects a
   carrier existentially (the record: "occupying a carrier whose entrance end is an intersection and
   which a traffic-signal head governs"); the obligation, which must re-state that whole selection
   because the applicability's bindings do not reach it, reads the duty at **every** selected
   carrier, junction and head (`forallRegion`/`forallDevice` with the selection as the antecedent).
   The `st.lane_enters` contract directs this: "a rule never picks the carrier that favours the road
   user". With one approach in a scene the two coincide; with several they do not, and the universal
   reading is the contract's.
3. **The carrier quantifier ranges over `travel_region` as the record names it**, so it also ranges
   over the junction region itself (`intersection` refines `travel_region`), which the subject
   occupies at the instant of entry. No exclusion was added: that candidate is decided out by the
   conjunction the record already states, since the head that governs the subject's carrier does not
   govern the junction region (`dev_governs` is false there), and a false conjunct settles the
   conjunct whatever `st_lane_enters` says about a region that records no entrance.
4. **Trigger look-back.** The record's applicability reads the yellow alone "at the judged
   observation or at an earlier observation while the subject was on that carrier"; that is exactly
   `.since (rel_occupies v c) (yellowAlone d)`, whose past operand is the occupancy of the same
   carrier.
5. **Narrowings declared: none.** Everything above is either the record's own reading (its ob1
   narrowing splitting the yellow observation from the red one, its applicability and obligation
   statements) or the content of a contract and an enumeration. Nothing in the duty or a standard is
   stated more narrowly than its words, so `narrowings` stays empty, as the instructions require for
   the plan's own narrowings.

## Witnesses

The four planned ones plus the two planned branches, and two of my own:

- `forbid` (violated), `permit` (compliant), `idle` (not applicable), `blind` (unknown, masking
  `dev.traffic_signal` and nothing else), `branch_1` (compliant: entry made while the yellow still
  showed), `branch_2` (not applicable: a pedestrian, outside the vehicle aggregate).
- `branch_3` (not applicable, mine): the head shows the steady yellow **with a green left arrow**
  throughout, so no observation shows it alone — the only scene that exercises the "no other state"
  conjunction.
- `branch_4` (compliant, mine): two heads; the car faces head A's yellow alone on its own lane and
  enters while A still shows yellow, while head B — governing the southern approach, not the car's
  lane — shows red throughout. Drop `dev_governs` from the obligation and this scene is violated,
  so it is what holds the obligation's head selection in place.

`idle` and `branch_3` start with the subject upstream of the recorded lane region: with the trigger
false and the subject off the carrier at the first observation, the look-back is settled false rather
than truncated, so these witnesses are not applicable rather than unknown. No witness needs padding
or a `window`, and none declares a history boundary.

## Why I finished

The gate returned `OK` on the files as written, on the first run: the rule checks, every claimed name
is used and no unclaimed one appears, the formulas are not vacuous under the eight witnesses, and
every witness reaches its planned verdict. There is nothing further to fix and no reason to spend
another run. The node is sound as mapped — I found no span whose words its atoms cannot carry, so no
`no_atom`/`no_operator` declaration and no defect report for the plan agent, and
`drv.motion.region_entry` behaved exactly as its contract states (the event of the overlap
beginning, false where the subject's footprint does not overlap the junction at the observation), so
no `dependency_defect.json`.
