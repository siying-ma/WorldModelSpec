# NRS_484B_400_2a — coding session result

## Final verdict

**OK** — `8 witnesses, 14 names, composes nothing; narrowings declared by the coder: 3`.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing; the session ended on it (budget 6, one used) |

Before running the gate I read the Core files the surface left open for this node: `Language/RuleEval.lean`
(argument sorts and the static check's arity handling), `Language/Semantics.lean` (the measured-atom
table, `same` over region variables, the Kleene connectives and the region quantifiers),
`Vocab/Atoms.lean` (`isKind`/`regionCandidates`, `rel_occupies`, `st_lane_left_of`, `nearestPoints`,
`inFrame`), `Vocab/Primitives.lean` (`prim_region_lateral_offset`), `Runtime/Manifest.lean` (what
masking `st.lane_adjacency` blanks — the neighbours, the ordinal and the count, and not
`enters_intersection` or the direction), `Runtime/Admission.lean`, `Runtime/Grounding.lean`,
`Runtime/Monitor.lean`, `Evidence/TraceLint.lean`, `Evidence/Builders.lean` and
`Evidence/Adequacy.lean`.

## The rule, span by span

- **s1** — one aggregate atom, `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, as the binder's class;
  never expanded into classes.
- **i1, c1** — an intersection `i` (`st_intersection`) at which the source's current plan for `v` is
  a left turn (`intent int.left_turn v i`, at the judged observation), and the approach `a` the
  subject itself runs to it: a travel region it occupies (`rel_occupies`, `st_travel_region`) whose
  entrance end is that junction (`st_lane_enters a i`).
- **c2** — `twoDirectional`, applied to the way carrying the approach (`st_highway`, `st_on_way a w`)
  and to the other way meeting at the junction (`st_on_way i w2`, `.not (.same w w2)`): no
  `st_median_or_divider` lies on the way, and two distinct carriers it carries have opposed
  designated directions — their normalised dot product at or below the negative of
  `p.same_direction_cosine_tolerance` (`st_lane_direction`, read component by component).
- **ob1** — a universal over the carriers the subject occupies whose entrance end is that junction
  and over their ways; at each, the subject must be in the portion nearest the centre line, read
  either as the leftmost lane of its own direction (`st_lane`, `st_lane_adjacency` through
  `st_lane_adjacency_left`) or, where the carrier is no recorded lane, as a place whose signed
  lateral offset to the centre line of the roadway it occupies (`st_roadway`, `rel_occupies`,
  `st_centre_line`, `st_on_way`, `prim.region_lateral_offset`) is at least
  `p.lateral_offset_resolution` and at most `p.centerline_adjacent_distance`.

All fourteen claimed names and all three parameters are read; nothing else is.

## Choices the node left open, and what I chose

1. **`ordinal 1` without a magnitude of this file's own** (narrowing 1 on `ob1`). The node's
   obligation says "the lane of ordinal 1 for its own direction of travel, counted along that lane's
   designated direction". The node declares no literal, and `1` is not the text's figure, so no
   `Term.lit` for it would be admissible; `st.lane_adjacency`'s contract makes ordinal 1 the leftmost
   lane looking along the lane's direction, and `st_lane_adjacency_left` is decided false for every
   candidate exactly where the lane is first from the left. I wrote the duty as "a recorded lane with
   no neighbouring lane of its own direction on its left". It is the same reading of the same atom and
   masks identically (the `blind` witness turns unknown through it).
2. **The gate between the two readings of the portion** (narrowing 2 on `ob1`). The node gates the
   centre-line reading on "where the carriageway carries no recorded lane". Since the duty is read
   carrier by carrier, I wrote the gate as the carrier the subject occupies not being a recorded lane
   (`.not (.atom "st_lane" [a])`). On a laned carriageway the approach carriers are the lanes, so the
   two coincide there; writing it on the way instead would have left the leaf unexercisable by any
   scene (a carriageway is either laned or not, and the two branches could never both be reachable).
3. **The quantifier over the selected carriers** (narrowing 3 on `ob1`). `st.lane_enters`'s contract
   says a rule never picks the carrier that favours the road user, so the duty is a universal over
   every carrier the subject occupies that enters the junction, not an existential over them.
4. **What the obligation re-selects.** The obligation repeats the whole selection of the carrier and
   its way — occupancy, the kind, `st_lane_enters`, the junction's kind and the declared intention,
   `st_highway` and `st_on_way` — so it denotes the region the applicability selected. It does not
   repeat the two-directionality of the two ways: that is a condition on the ways which the
   applicability already requires, so repeating it could only leave the duty unchanged where the rule
   is engaged, while every leaf of the repetition would be unexercisable by any witness (the
   applicability is false wherever they are). The omission leaves the obligation broader, never
   narrower, and no fact of the trigger is weakened.
5. **Where `st.roadway` is read.** The node claims it on both `c2` and `ob1`. I read it in `ob1`,
   where the node's own words tie it to the centre line ("the centre line of its roadway"), and not
   in `c2`: the definition's words there are "undivided" and "opposite directions", which the divider
   and the designated directions carry, and a roadway region in the laned witnesses would be a coarse
   carrier the subject occupies whose entrance the source does not record, leaving the duty undecided
   on it for no reason the text gives.

## The witnesses

Eight, the node's seven plus one. Geometry (described in the file's header): a four-lane undivided
east–west street meeting an undivided north–south street; the subject a 4.8 m × 1.8 m motor vehicle
east-bound at 10 m/s over three instants, never reaching the junction.

- `forbid` (violated) — kerbside lane, ordinal 2.
- `permit` (compliant) — the lane adjoining the centre of the way, ordinal 1.
- `idle` (not applicable) — the declared plan at that junction is *not* a left turn (declared false,
  not unobserved).
- `blind` (unknown) — `st.lane_adjacency` masked: the neighbours and the ordinals go, the entrance
  relation and the directions stay, so the applicability is decided and only the portion is unknown.
- `branch_1` (compliant) — unlaned street, the centre line 1.9 m from the subject (inside the
  portion: ≥ 0.5 m, ≤ 3.6 m).
- `branch_2` (not applicable) — a raised median on the subject's own way.
- `branch_3` (violated) — unlaned street, the centre line 5.9 m away (outside the 3.6 m portion).
- `branch_4` (not applicable), **added**: the other intersecting highway is divided by a median. The
  node's scenarios reach the divider leaves of the subject's way only; "Both intersecting highways"
  has its own limb, and without this witness the divider leaves of the second way move no decided
  witness (mutation adequacy would have reported them).

Each bound is broken or kept by a clear margin against the run's values (0.866, 0.5 m, 3.6 m):
opposed directions give a dot product of −1; the kept offset is 1.9 m and the broken one 5.9 m.

## Why I finished

The gate returned `OK` on the first run: the files build, the static check and the soundness,
declaration, claim, anchoring, literal, parameter, witness and adequacy checks all pass, and all
eight witnesses reach their planned verdicts. The gate's verdict is the acceptance signal, so there
was nothing left to change; five gate runs of the budget are unused. The node is not wrong: every
span it carries is written with the atoms it maps, and no span needed a `no_atom` or `no_operator`
declaration.
