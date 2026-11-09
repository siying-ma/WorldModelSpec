# NRS_484B_250_4_o1 — coding session result

**Final verdict: `OK`** (one gate run, the first; budget 6).

```
OK
   10 witnesses, 19 names, composes nothing
   narrowings declared by the coder: 4
```

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing — the files stand as written |

Before the run I read, from Core only: `Language/Semantics.lean` (atom arity and argument
sorts, the three-valued evaluator, quantifier ranges), `Foundations/Temporal.lean` (`sinceAll`,
`risesAll`, truncation tags), `Language/RuleEval.lean` (`check`, `verdictAt`),
`Language/Rule.lean`, `Language/Formula.lean` (`atoms`, `leaves`, `replaceLeaf`),
`Evidence/Builders.lean` (`pastOps`, `Scenario.run`), `Evidence/Adequacy.lean`,
`Evidence/TraceLint.lean`, `Vocab/Atoms.lean`, `Runtime/Admission.lean`, `Runtime/Grounding.lean`
and the head of `Vocab/Primitives.lean`.

## What the rule says

- **Binder `v`** — the admitted aggregate `DEF-NRS-484A-320::vehicle`, one atom.
- **Applicability (t1)** — a junction of kind `st.intersection` the subject occupies
  (`rel.occupies`, which also anchors the region quantifier) and comes to overlap at this
  observation (`drv.motion.region_entry`), with a head of kind `dev.traffic_signal` governing it
  (`dev.governs`), uncovered (`dev.traffic_signal`'s uncovered attribute) and inoperative
  (`dev.inoperative`). Nothing in the trigger is weakened.
- **Obligation (ob1)** — the same junction, selected again by the record's whole selection, and
  then, for **every** approach carrier the subject occupies whose entrance end is that junction
  (`st.travel_region` as the kind, `rel.occupies` as the anchor, `st.lane_enters` as the entrance
  end), the halt must be found searching back. The place is read in the words' order: the stop line
  marking that carrier (`st.stop_line` + `st.entrance_of`); else, where the carrier's stop lines are
  observed and none marks it, the crosswalk marking it (`st.crosswalk` + `st.entrance_of`); else the
  view point (`st.sight_along_way` along a `st.highway` the junction lies on and the carrier does
  not, `st.on_way`). A halt counts at a mark where the subject is at rest
  (`drv.motion.standstill`, `p.standstill_speed_tolerance`), on that carrier, its footprint not yet
  over the junction, its body at most `p.stop_point_tolerance` from the mark
  (`st.region_geometry`) and the mark not yet passed (the sign of `prim.region_offset_along` along
  the carrier's designated direction). The search ends at the start of that approach (off the mark,
  short of it, farther than the tolerance) or at the subject's own earlier presence in that
  junction; neither end reached ⇒ unknown.

## Choices the node left open (all declared as narrowings on ob1, and in the file header)

1. **"the point nearest the intersection where the driver has a view"** — written as: at rest on the
   carrier, short of the junction, with the sight along the crossing way at least
   `p.intersecting_way_view_distance`. No region marks that point and a trace carries sampled
   positions, so the place is not stated as a minimum over the points of the carrier; any point of
   the carrier short of the junction from which the way is visible that far counts.
2. **"the through highway"** — a highway region the junction lies on (`st.on_way`) that the
   subject's carrier does not lie on. With several such ways, the view along any one satisfies the
   place; an unrecorded way yields no view (so the place is not reached, rather than reached
   trivially).
3. **The start of the approach for the view-point place** — the view point is no region, so the
   stretch upstream of it is the part of the carrier, short of the junction, where the sight does
   not yet reach the view distance: the same relation to the place that a mark's upstream zone has
   to a mark.
4. **"the previous entry of the same subject into the same intersection"** — written as the
   subject's own occupancy of that junction, read at an observation before the judged entry, and the
   duty itself is judged at the observation before the entry (`atPreviousObservation`). A formula
   read at the judged entry cannot tell that entry from an earlier one: `since` reads its own
   instant, where the entry event and the junction occupancy are both true, which would make every
   entry violated. The two bounds decide this duty alike, because no halt at the place can be found
   while the footprint overlaps the junction, so nothing a halt could occupy lies between them.

Two further choices are the atoms' own contracts, not narrowings, and are explained in the header:
`.not (.same l x)` keeps the junction out of the carrier range (`st.lane_enters` admits as carriers
only lanes and the kinds refining them, roadways, shoulders and bicycle lanes or paths, never an
intersection; the junction's own entrance relation is unobserved and would otherwise leave the
quantifier undecided), and the carrier quantifier is **universal** — the record says a rule never
picks the carrier that favours the road user.

## Witnesses

Ten, on one shared layout (a four-way junction, an eastbound approach lane whose entrance end is
that junction, a stop line, a crosswalk, the two highways, one signal head). Occupancy is written as
the footprint's overlap with each boundary as closed sets, computed in the witness file
(`occupancyOf`), so it is exactly what Core derives from the geometry rather than the reference
point's polygon.

| witness | verdict | what it shows |
|---|---|---|
| `forbid` | violated | the stop line governs; no halt between the line's upstream zone and the entry |
| `permit` | compliant | halted 0.5 m short of the line (tolerance 1 m), then enters |
| `idle` | not applicable | the head shows circular red and is not inoperative |
| `blind` | unknown | `dev.inoperative` masked and unreported at the entry |
| `branch_1` | compliant | stop line and crosswalk observed to mark another carrier: halted at the view point (120 m ≥ 100 m) |
| `branch_2` | violated | crosswalk governs; a crawl at 1 m/s (tolerance 0.1 m/s), no halt |
| `branch_3` | violated | no marks at all: the view point governs and is passed at speed |
| `branch_4` | compliant | crosswalk governs; halted 0.7 m short of it |
| `branch_5` | violated | enters, reverses out without halting and without reaching the line's upstream zone, enters again: the search ends at the earlier presence in the junction |
| `history_boundary` | unknown | the recording begins inside the line's stopping zone; the search reaches the trace start (`windowTruncated "since"`) |

`branch_3`, `branch_4` and `branch_5` are mine: they exercise the view-point branch of the search
end, the compliant crosswalk branch, and the junction-occupancy end of the search, none of which
the planned scenes reach with a decided verdict.

## Observations for the plan agent (not defects; the gate accepted the node)

- ob1 claims `st.lane_direction` and `ru.aggregate=DEF-NRS-484A-285::traffic`. The duty as the record
  states it operationally reads the direction only *through* `prim.region_offset_along` (whose
  contract names `st.lane_direction` as its input, and whose other inputs the record deliberately
  does not claim), and never reads the traffic aggregate at all: the view is the sight along the way,
  "whether or not anyone is on it", so no formula over that aggregate can carry the words without
  making the place turn on a road user being present — which the plan's own `permit` and `branch_1`
  narratives forbid ("the scene contains no other road user, and the verdict is still decided").
  Neither name appears in my formulas; the gate reported 19 names and no unused claim, so I left
  them as the node has them. If a later session wants them carried, the mapping, not the Lean, is
  what has to change.
- The duty's history bound needs the judged instant excluded from the search, which the language
  has no operator for (`since`, `count`, `atLast` all read the instant they judge, and `atLast`
  would need a window length this node has no parameter for). `atPreviousObservation`, written from
  `rises`, is the only way to state it; it is declared as narrowing 4 rather than as
  `no_operator`, because the duty the record states is expressible this way and decides correctly
  at every entry observation.

## Why I finished

The gate returned `OK` on the first run: the rule builds, passes `Rule.check`, names only claimed
atoms, carries no bare literal, and all ten witnesses reach their planned verdicts with every leaf
of the applicability and the obligation exercised by a decided witness. There is nothing left to fix
and no further run would add information.
