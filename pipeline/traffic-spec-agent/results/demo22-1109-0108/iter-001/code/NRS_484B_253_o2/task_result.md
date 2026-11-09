# NRS_484B_253_o2 — coding session result

## Final verdict

`OK` — "12 witnesses, 15 names, composes NRS_484B_253_o1, narrowings declared by the coder: 2"
(gate run 4 of a budget of 6).

Files written:
- `library/TrafficSpec/Rules/NRS_484B/NRS_484B_253_o2.lean`
- `library/TrafficSpecWitness/NRS_484B/NRS_484B_253_o2.lean`

The node is not wrong: every span it carries is written with the names it claims, and no
`no_atom` / `no_operator` declaration was needed.

## Gate runs

1. **WITNESS_FAIL** — every witness: "its trace is not one the adapter can produce: track 2 keeps
   the heading it had at t=…, but its yaw rate turns it 3/2° over the interval (the rate at a
   scene is held over the interval before it)". The first traces carried a yaw rate with a
   piecewise-constant heading, and crude speed/position pairs.
   *Changed:* the witness geometry was rebuilt so each body's figures agree step by step — an
   exact rational rotation of 1.5° per scene for the turning van (`stepCos`/`stepSin`, trimmed to
   a tenth of a micrometre so sixty steps stay small rationals), every body either standing or
   running straight at a constant speed with its position advancing by the speed of the scene over
   the interval before it, and no `accelLongitudinal` claimed where the speed steps.
2. **WITNESS_FAIL** — only `blind`: "unknown for [absent_atom:st_lane_enters,
   absent_atom:st_lane_direction], not for an atom the manifest masks". With occupancy masked, the
   carrier quantifiers reached two candidates whose lane record is absent: the junction region
   itself (an intersection records no approach of its own) and an unused westbound carrier with no
   entrance.
   *Changed:* the carriers are held apart from the junction they enter
   (`.not (.same cv j)`, `.not (.same ct j)` — see below), and the unused westbound carrier was
   dropped from the scenes. `blind` is now unknown for `rel.occupies` and nothing else.
3. **VACUOUS** — "obligation leaf 6: atom sig_hand_signal". The arm-signal leaf moved no decided
   witness inside the obligation: the only arm-signalled witness (`branch_3`) is compliant through
   the standing-subject limb, so the antecedent's value never changed its verdict.
   *Changed:* added `branch_8` — the van signals the turn by arm alone and the subject runs on at
   8 m/s with a predicted closest approach under the clearance (violated).
4. **OK**.

## What the node left open, and what I chose

- **c2, "when and as required" (a condition span, so declared in the rule's header and not as a
  narrowing).** The record reads the signal as a left indication at some observation in the window
  `p.turn_signal_advance_window` behind *the recognition of the turn*. I write the recognition as
  `.rises` of the turn concept and read the span at it, through
  `atLast .time p.turn_signal_advance_window` over `.not (.holdsFor … (.not leftIndication))`.
  Consequence worth the reviewer's eye: `atLast` finds the recognition only while it lies within
  that same window behind the judged observation, so the duty is read over the stretch after the
  turn is recognized rather than for the whole remaining trace. The alternative that bounds
  nothing (`.since`) is unknown wherever the recorded past holds no recognition, which would make
  a signal-less turn (`branch_1`) undecided instead of unengaged — the language offers no
  unbounded past that stays decided.
- **The carriers and the junction (s1, also a subject span, so explained in the header only).**
  The two carrier quantifiers range over `st.travel_region` as the record names it, with the
  junction region excluded from the carriers by `.not (.same cv j)` / `.not (.same ct j)`. By
  `st.lane_enters` a carrier is an approach to an intersection and enters one intersection at
  most, so the region entered is not among the regions entering it; this is the ontology's own
  distinction, and without it a source that leaves occupancy unobserved reports the junction's
  missing lane record instead of the missing occupancy.
- **ob1, the duty (two narrowings declared on the rule, `kind := "reading"`).**
  1. Granting precedence is read as a duty on the subject's own proceeding: contact is forbidden
     outright, while the clearance bounds are read on a subject that is itself moving (a standing
     subject grants precedence by standing). This is how `kin.speed`, claimed by ob1 as "the
     subject's own speed", does work.
  2. The clearance is bounded in both of the ways ob1's atoms measure it, each at
     `p.yield_min_clearance`: the gap between the nearest points of the two bodies at the
     observation (`rel.surface_gap`), and the centre distance at the closest approach where the
     centres approach within `p.yield_conflict_horizon` (`prim.closest_approach_within` /
     `prim.closest_approach_distance`, the latter undefined — and so bounding nothing — where they
     do not approach).
- **ob1's quantification.** The applicability says such a vehicle exists; the obligation owes the
  duty to each one, so it re-states the record's whole selection (junction, turn, signal, composed
  compliance, opposed carriers) under `.forallUser` as the separate-formulas rule requires.
- **Witness choices that are mine, not the record's.** The van stands in the junction mouth and
  swings its nose to the left at 30 deg/s rather than driving through its turn: a standing body's
  position is consistent with its velocity under any convention the trace checker might use, which
  the first gate run showed to matter. Each scene also declares the van's plan at the junction
  (`int.turn_left` and two spellings beside it, false in the witnesses where the turn is already
  made, true in `branch_2`), so that a composed rule reading a declared intention is not left
  unknown on these traces; nothing in this rule reads an intention.
- **Extra witnesses (mine, as tests of the rule).** `branch_3` standing subject (compliant),
  `branch_4` predicted closest approach below the clearance with the bodies far apart (violated),
  `branch_5` nearest-point gap below the clearance with no approach within the horizon
  (violated), `branch_6` approach within the horizon well above the clearance (compliant),
  `branch_7` bicycle subject, outside the aggregate (not applicable), `branch_8` arm signal alone
  (violated).

## One thing a reviewer should know about the c1 composition

`c1` is read, as the record directs, as `.rule "NRS_484B_253_o1" [("v", "t")]` in the
applicability, so the turning vehicle's own compliance is read **at the same observation as this
duty**. Where the subject's conflict with the turning vehicle is also the conflict that
`NRS_484B_253_o1` measures, the two rules can only fail together, and this rule then reports not
applicable rather than violated at that observation. The violating witnesses are therefore built
so that the turning vehicle is itself blameless at the judged instants (it stands, having
yielded, and the predicted closest approach it is party to stays above the clearance); `branch_2`
is the converse scene, where the van is in contact with a car it turned across and the duty on the
other drivers is unraised. All of them hold, so the composition behaves as the record intends on
these traces; a plan session that wants the duty to outlast the turning vehicle's own momentary
verdict would have to say over what stretch "having so yielded" is read.

## Why I finished

The gate returned `OK` on run 4 of 6: the rule builds and checks, every claimed name is used and
no unclaimed one appears, the two files are the only ones touched, and twelve witnesses — the
six the node plans and six branch witnesses of my own — reach their declared verdicts, with
`blind` unknown for the masked atom alone and every leaf of both formulas moving some decided
witness. Nothing in the node required repair, so there is no `dependency_defect.json` and no
blueprint change to request beyond the note above.
