# drv.motion.region_exit — coding session

**Final verdict: `OK`** (3 witnesses, 1 name, reads 1 atom). Gate runs used: 2 of 6.

## The body

```lean
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []
def body : Formula := .rises (.not overlaps)
```

The record claims one element, `rel.occupies`, for the span "it does not overlap the region at the
observation and did overlap it at the observation before". `rises φ` is φ here and not at the
previous observation, so `rises (not (rel_occupies u r))` is that span's two conjuncts and nothing
else: no region geometry, no distance, no heading, no speed, no second region, no carrier — all of
which the contract expressly excludes. It is an edge, not a state, which is the contract's "the
event of that ceasing to overlap, read at the observation at which the overlap has ended, and not
the state of lying outside the region at the later observations". The region is the formal `r` the
caller singles out; the body quantifies over no region. Both formals are read by the atom, so both
are anchored and no variable is bound inside the body.

## The witnesses

One geometry for all three scenarios. Region 100 is an intersection, the square (−10, −10) to
(10, 10) m. Track 1 is a motor vehicle, half-extents (2, 1, 1) m, heading east at 7 m/s, observed
every second from t = 0; its centre stands at x = −7, 0, 7, 14, 21 m, so its footprint spans
[−9, −5], [−2, 2], [5, 9], [12, 16], [19, 23] m along x. Centre-in-polygon (what `Build.scene`
derives) and footprint-overlap (what `TraceLint.completeOccupancy` derives) agree at every
observation — the footprint clears the boundary at x = 10 with 2 m to spare — so the occupancy of
the trace is the occupancy the footprint has. The overlap ends at t = 3000 ms and nowhere else.

| scenario | trace | judged | why the verdict |
|---|---|---|---|
| `holds` | k = 0…3 | `window = (3000, 3000)` | the footprint lay in the square at t = 2000 and lies clear at t = 3000: the edge is true → compliant |
| `fails` | k = 0…4 | whole trace | the edge is false at t = 1000 and 2000 (overlapping at the observation before and overlapping still, only farther in), at t = 0, and at t = 4000 — the observation after the departure, the footprint having lain clear at the observation before → violated |
| `blind` | k = 0…3, `rel.occupies` absent | `window = (3000, 3000)` | neither conjunct is decided → unknown for the masked atom |

The instance fills nothing: no literal formal, no nat, no parameter, and a formula body needs no
bounds. Every figure above is the witness's own.

## Gate runs

1. **`WITNESS_FAIL`** — "blind: unknown for [window_truncated:rises], not for an atom the manifest
   masks". With `rel.occupies` masked the edge is unknown at every observation, but at t = 0 one of
   its reasons is the truncated past before the first observation, and the episode verdict collects
   the reasons of every judged instant. *Change:* gave `blind` the same single-instant window as
   `holds`, `(3000, 3000)`, so the only reason left is the absent atom. The scene was right and the
   body was right; only which instant the witness judged was wrong.
2. **`OK`** — no change after it.

## Choices the record left open

None that needed a narrowing, so `narrowings := []`.

- "the observation before" is the previous observation of the trace: the only predecessor the
  formula language has, and what `rises` compares against. Not a choice among meanings.
- The event-versus-state reading is the contract's own words, not a reading I picked.
- The three-valued behaviour — unknown where the overlap is unobserved at the observation or at the
  one before, and at the first observation of a recording where the footprint does not overlap
  (false there where it does, since false ∧ anything is false) — follows from `rises` and the atom
  in Core, not from anything chosen here.

One judgement belongs to the witnesses rather than the concept: because `rises` is true at one
observation only, and is necessarily false at the observation just before the rise, no trace
containing a departure can be compliant at every instant. So `holds` (and `blind`) name the
departure observation through `window`; that is what `window` is for, and the gate honours it.

## Why I finished

The gate returned `OK` on the second run: the body is the record's one element over the record's two
formals and nothing more, and the three scenarios give compliant, violated and unknown for the
reasons their narratives state. Nothing in the record was wrong, so no `dependency_defect.json` and
no report back to the plan agent. Four gate runs of the budget are unspent.
