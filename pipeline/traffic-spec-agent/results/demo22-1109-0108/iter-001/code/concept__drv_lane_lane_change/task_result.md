# drv.lane.lane_change — coding session

## Final verdict

**OK** (first and only gate run): `3 witnesses, 3 names, reads 3 atom(s); narrowings declared by the coder: 2`.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | `OK` | nothing — the session finished; budget of 6 runs, 1 used |

Before running the gate I read the Core surface for the three things the body and the witnesses turn
on: `Semantics.evalAtomE` for `st_lane_adjacency [r, side, r']` (it is `st_lane_left_of/right_of s r r'`,
i.e. "`r'` is `r`'s neighbour on that side"), `Temporal.risesAll` (at the first instant of a trace
`rises φ` carries `windowTruncated "rises"`), and `Scenario.run` / `Grounding.episode` (the episode
verdict is taken over the instants in `window`, a violation dominates, an unknown beats a compliant,
and an `unknown` witness may be unknown only for atoms the manifest masks).

## The body

```
body = rises (¬ occupies r)
     ∨ ( occupies r ∧ ¬ rises (occupies r)
         ∧ ∃ n : lane. (st_lane_adjacency r left n ∨ st_lane_adjacency r right n) ∧ rises (occupies u n) )
```

`occupies x` is `rel_occupies u x`; the neighbour `n` is bound by a region quantifier over
`st.lane` and anchored to both formals (`st_lane_adjacency` reads `r`, `rel_occupies` reads `u`).
Claimed names used, and only those: `rel.occupies`, `st.lane_adjacency`, `st.lane` (the quantifier's
kind). No parameter, no literal, no concept call.

The two branches are the contract's own disjunction. Its reading
`overlapped-before ∧ (¬ overlaps-now ∨ neighbour)` is exactly the disjunction above: the case
`overlapped-before ∧ ¬ overlaps-now ∧ neighbour` is the first branch already, so nothing is lost or
added.

## Choices the record left open, and what I chose (both declared as narrowings)

1. **"its footprint overlapped the region at the observation before"** — the formula language names
   no past instant of its own; the only operator that reaches the preceding observation is
   `rises φ` (φ here and not at the observation before). So the overlap at the observation before is
   written through it, per branch: `rises (¬ occupies r)` where the region is no longer overlapped,
   and `occupies r ∧ ¬ rises (occupies r)` — overlapping here and not newly so — where it still is.
   (`holdsFor`/`atLast` would need a window length, and the concept declares no time formal.)
2. **"overlaps a lane neighbouring it in the same direction of travel"** — `st.lane_adjacency` takes
   a side; the contract reads none, since it excludes "the direction or side the crossing is made
   towards". The body therefore reads the neighbour on either side, disjunctively. The two sides are
   one leaf family for the adequacy check (they differ only in a literal argument), and the `holds`
   witness exercises the family through the left side.

Not choices, stated for the reader: the event is read with `rises`, not with `eventually`/`since`,
so the body is true at the observation at which the crossing has happened and not afterwards; `r` is
read as given (the body never quantifies over it); nothing reads a heading, a signal, a declared
intention or a lateral offset.

## The witnesses

One instance (`drv.lane.lane_change@w`, no literals, nats, params or bounds), `u ↦ 1`, `r ↦ 100`.
A three-lane carriageway running east, each lane 4 m wide: 101 (y 8…12, ordinal 1), 100 (y 4…8,
ordinal 2, the formal `r`), 102 (y 0…4, ordinal 3), with the neighbour links written both ways.
Track 1 is a motor vehicle 5 m × 2 m heading east at 20 m/s; three observations a second apart.
Occupancy is written out and agrees with the footprint's overlap of the lane boundaries, so the
scenes read the same whether `occupies` is taken as written or re-derived from the geometry.

- `holds` → compliant: centres (10, 6), (20, 6) — the middle lane alone — then (30, 8.5), whose
  footprint (y 7.5…9.5) overlaps the middle lane and the left-hand lane: the second branch holds.
- `fails` → violated: centres (10, 6), (20, 6.8), (30, 6) — a drift within the middle lane; the
  middle lane alone at every observation, so both branches are false.
- `blind` → unknown with `rel.occupies` masked: the same movement; the only unknown reason is the
  masked atom.

Every scenario's `window` is the last observation alone (t = 2000 ms). That is the observation the
record's narratives speak about and the observation at which the crossing has happened; it also
keeps the witnesses clear of the `rises` truncation at a trace's first instant, which would
otherwise be a stray unknown reason in the `blind` witness.

## Why I finished

The gate returned `OK` on the first run: the concept builds, checks, reads exactly the record's three
claimed atoms, every leaf does work in a witness, and the three witnesses reach compliant, violated
and unknown as the record's scenarios expect. The record needed no change: each element paired with
an accessor of the surface, and the two readings the contract leaves open are declared as narrowings
rather than resolved silently. Nothing was left out; 5 of 6 gate runs are unused.
