# NRS_484B_127_2 — coding session result

**Final verdict: `OK`** (14 witnesses, 19 names, composes nothing), reached on the first and only
gate run.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` — `14 witnesses, 19 names, composes nothing` | nothing; the session ended |

Before running the gate I read the Core files that the injected surface does not settle:
`Language/Formula.lean` and `Language/RuleEval.lean` (leaf/family structure, the static checks,
argument sorts and arities of measures with a selector), `Language/Semantics.lean` (what
`st_lane_adjacency [r, "count"]`, `kin_extent [x, "width"]` and `rel_surface_gap [a, b,
"longitudinal"]` evaluate to), `Vocab/Atoms.lean` (how `rel_surface_gap`,
`rel_ahead_behind_in_lane`, `rel_occupies` and `st_region_geometry_distance` are computed from a
built scene), `Foundations/Unknown.lean` (`R.any []` is false, so an empty quantifier decides),
`Evidence/Builders.lean` and `Evidence/TraceLint.lean` (what a hand-written trace must satisfy),
`Runtime/Manifest.lean` (what masking an atom actually blanks) and `Evidence/Adequacy.lean` (the
mutation rule: binder classes are not mutated, and leaves of one atom differing only in a literal
argument form one family).

## How the spans are written

Fully documented, span by span, in the rule file's header. In short: s1/s2 share one formula over
the two admitted aggregates with `kin_extent`'s width read against the literal 80 inches (the
figure on the combination limb, as the record's applicability states); s2's following is the
catalogue concept with `p.same_direction_cosine_tolerance`, its road user quantified in the
applicability and re-selected whole in the obligation; s3 is the operationalization's four leaves
(speed, intervening count as a `Term.aggregate .count`, obstruction nearer than the gap, works-zone
device over a lane or roadway), standing as the duty's precondition inside the obligation; s4 is
the longitudinal `rel_surface_gap` at or above 500 feet with `rel_ahead_behind_in_lane` fixing its
direction; s6 and s7 are `.not` of their own content in the applicability; s5 is the node's
residue and no leaf reads it.

## Choices the node left open, and what I chose

1. **`st.lane_direction` on s7.** The record maps the atom to the exception to fix "that the
   direction counted is the one the subject travels in", and the span claims no heading atom, so no
   comparison of the subject's heading with the lane's is available. I read the atom on the lane the
   subject occupies, as the squared length of the direction it returns above zero: the lane carries
   a designated direction of travel, which is what makes `st.lane_adjacency`'s count a count of
   lanes available for traffic moving in the subject's own direction, and which reads unknown where
   the lane carries none. The leaf is decided in every witness and moves `branch_1`. s7 is an
   exception, so this is carried as the node maps it and **no narrowing is declared**: the atom is
   doing its own contract's work on its own span.
2. **Where the standard sits.** `conditionsPermit` is the antecedent of the duty inside the
   obligation, not a conjunct of the applicability, so a scene in which the conditions do not permit
   is *compliant* and not unengaged — the record's own wording ("at each observation at which the
   applicability holds and the conditions of s3 permit"). `branch_3`, `branch_4`, `branch_6`,
   `branch_7`, `branch_8` and `branch_9` are the compliant witnesses this produces.
3. **The intervening count excludes the followed road user** (`same w u`) as well as the subject:
   the convention's "between the subject and the road user it follows".
4. **The s6/s7 subject-class limbs are written out** (`truck ∨ combination`, `vehicle ∨
   combination`) even though the binder's class already entails the first of them, because the
   spans' own words name them. They survive adequacy because every `ru_aggregate` leaf on one
   variable is one family, and the truck/vehicle member of each family moves a decided witness.
5. **Extra witnesses (`branch_6` … `branch_10`)** were added for leaves the planned nine never
   reach: the speed leaf alone (`branch_6`), the intervening-users leaf at free-flow speed
   (`branch_7`, which also exercises the obligation's width comparison through a van that is not of
   the bound classes), the roadway limb of the works-zone leaf (`branch_8`), the obstruction leaf
   (`branch_9`) and the applicability's width comparison (`branch_10`).

## One thing the plan should know about the `blind` scenario

The node's `blind` masks `rel.surface_gap`, but Core's mask only drops a *supplied* gap: the atom
otherwise computes the gap from the two bodies' footprints, which every scene with observed
occupancy must supply. A `blind` scene that is the `forbid` scene with the atom masked is therefore
still decided, and would have failed. I built the only scene in which the mask decides: a source
that maps **no outline for the lorry ahead** (no extent, so its occupancy is not observed either),
which therefore reports the clearance and that lorry's place in the lane as measured relations —
both relations Core cannot compute in that scene, so supplying them is permitted. Masking
`rel.surface_gap` then drops the one reading of the space there is, and the duty is unknown for
`absent_atom:rel_surface_gap` and nothing else. The plan agent may want to record that a masked
`rel.*` atom only bites on a source that lacks the kinematics behind it; nothing in the node's
reading needed changing.

## Why I finished

The gate returned `OK` on the first run: the rule builds, checks, claims and uses exactly the
node's names, every quantified region, device and road user is anchored to the binder through a
claimed anchoring atom, every witness reaches its planned verdict and every leaf of the
applicability and the obligation moves a decided witness. There is nothing left to repair and no
defect of the node or of a concept to report.
