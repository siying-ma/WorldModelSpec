# NRS_484B_220_1 — coding session result

## Final verdict

`OK` — `python -m harness gate --run_id demo22-1109-0108 --node_id NRS_484B_220_1`:
`6 witnesses, 13 names, composes nothing, narrowings declared by the coder: 1`.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing — the session finished on it (1 of 6 runs used) |

Before the single run I read four Core files to settle questions the surface left open, rather
than spend gate runs on them:

- `Language/RuleEval.lean` — the static check: `same` compares any two bound variables (so a
  region may be compared), an atom's argument sorts are checked positionally, a quantifier kind
  must be a spelling.
- `Language/Semantics.lean` — the kind atoms (`st_roadway`, `st_one_way_roadway`, `st_highway`,
  `dev_regulatory_sign`) are **not** in the surface's `boolAtomNames` list, but they do evaluate as
  formula atoms through the generated codecs (`evalAtomE`'s fallback, `isKind`/`devKind`), and
  `st_lane_direction` is a measure that takes a component literal (`"x"` / `"y"`) and is read
  normalised (`Geom.unit`), a zero vector reading unknown.
- `Language/Rule.lean` + `Language/Formula.lean` — `Formula.atoms` counts the kind of every
  quantifier with a literal kind (`kindAtom "st_"`, `kindAtom "dev_"`). So the node's claims
  `st.travel_region`, `st.highway` and `dev.regulatory_sign` are read by the quantifiers that range
  over those kinds; no redundant kind atom was needed for them. `Formula.leaves`/`replaceLeaf` show
  the adequacy check is leaf-mutation based.
- `Vocab/Primitives.lean` (the `prim_conditions_hold` body) and `Vocab/Atoms.lean`
  (`Structure.isOfKind`) — empty conditions (`conditions := some {}`) are unconditionally true and
  need no civil time, a posted window with a civil time outside it is decided **false**, and a
  region labelled `one_way_roadway` is decidedly a `roadway` and a `travel_region` by refinement
  while a lane is decidedly **not** a roadway.

## How the node is written

- **s2 / binder `v`** — `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the aggregate claimed whole.
- **s1 / `applicability`** — one existential over the travelled region
  (`existsRegion "travel_region" "r"`, the claim `st.travel_region`) whose body
  (`designatedOneWayRegion`) conjoins: `rel_occupies v r`; `st_roadway r` and `st_one_way_roadway r`
  (the one-way designation as the ontology's vocabulary carries it, the refinement stated with the
  kind it refines); `existsRegion "highway" "h" (st_on_way r h)`; `carriesDirection` (the components
  of `st_lane_direction r`, so a region carrying no designated direction leaves the trigger unknown,
  never false); `existsDevice "regulatory_sign" "d"` with `dev_regulatory_sign_code d one_way`,
  `dev_governs d r` and `prim_conditions_hold d v`; and
  `ru_aggregate v "DEF-NRS-484A-285::traffic"` — the travel the designation governs is the
  subject's. Every quantified variable is anchored: `r` by `rel_occupies` to `v`, `h` by `st_on_way`
  to `r`, `d` by `dev_governs` to `r` and by `prim_conditions_hold` to `v`.
- **s3 / `obligation`** — `forallRegion "travel_region" "r" (implies designatedOneWayRegion …)`: the
  trigger's whole selection is repeated under the quantifier, so the region judged is the one s1
  singled out and not merely a region of the same kind. The consequent is
  `drv_position_direction_component v r > −p.wrong_way_speed_tolerance`, i.e. a component at or
  below the negative of the tolerance violates, and travel with the designation, a standstill or a
  movement across the region within the tolerance complies.

## Choices the node left open, and what I chose

1. **Several selected regions (declared as a narrowing on s3, `kind := "reading"`).** The record's
   obligation says that where the vehicle occupies several selected regions and the verdict differs
   between them the duty is unknown. The language has no three-valued consensus over a quantifier;
   I wrote the duty as holding at *each* selected region (`forallRegion` + `implies`), as the
   record's own "where it is the same through each, it is decided" and hard rule 3c direct, so
   disagreeing regions are decided against the vehicle rather than left unknown. This is the only
   narrowing on the rule; the record's own narrowings (its two observable readings and its tolerance
   reading) are not restated.
2. **"carries a designated direction of travel" in the trigger.** The record's applicability names
   it, and the only way to state the presence of a vector-valued atom is a comparison on its
   components: `¬(x = 0 ∧ y = 0)`, which is true for any direction read, unknown where none is
   read (the atom's absence, a zero vector, or the masked source of the `blind` scene). Zero is
   written with the `.ratio` unit tag, the designated direction being read normalised.
3. **Where `st.one_way_roadway` and `st.roadway` sit.** The record's applicability prose names only
   the travel region, the highway, the designated direction and the sign, while s1's element claims
   both roadway kinds for the words "designated … for one-way traffic". I carried them as the
   element maps them — conjuncts on the region the vehicle occupies, i.e. that region *is* the
   one-way roadway, which is what every planned scenario describes ("a one-way roadway of a city
   street"). No narrowing is declared for this: s1 is a trigger span, which is carried as the node
   maps it and never narrowed.
4. **Witness geometry (mine, nowhere in the rule).** A 200 m east–west city street: highway region
   (16 m wide) with a one-way roadway on it (8 m wide) whose designated direction runs east, and a
   `one_way` sign governing that roadway. The car drives at 8 m/s, so the component is ±8 m/s —
   sixteen times the 0.5 m/s tolerance of the reading in either direction, and the standstill scene
   sits exactly at zero, half a tolerance inside the bound.
5. **One added branch witness.** `branch_2` (not applicable): the forbid scene with the sign's
   legend restricting it to 07:00–09:00 on weekdays and the observation on a Wednesday at 14:00, so
   `prim_conditions_hold` is decided false and the subsection does not engage — a decided witness
   for the conditions leaf, which the planned five scenes only ever leave true.

## Why I finished

The gate returned `OK` on the first run: the two files build, the rule's static check is clean,
every claimed name is read and no unclaimed one is, every quantified variable is anchored, and all
six witnesses (the node's five plus `branch_2`) reach their expected verdicts with every leaf
exercised. Nothing in the node is wrong as far as this session could tell, so there is no defect to
report and no further edit to make; five gate runs of the budget are unspent.
