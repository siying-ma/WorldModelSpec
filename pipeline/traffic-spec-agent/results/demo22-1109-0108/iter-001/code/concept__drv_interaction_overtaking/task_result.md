# drv.interaction.overtaking — coding session

**Final verdict: `OK`** (3 witnesses, 4 names, reads 4 atoms, 1 narrowing declared).

## The body

```
and (rel_same_direction a b [same_direction_tolerance])
    (and (kin_speed a − kin_speed b ≥ min_speed_excess)
         (or (rel_longitudinal_overlap a b > 0 m)
             (rel_ahead_behind_in_lane b a)))
```

One leaf per element of the record, in the contract's order and grouping: the heading agreement and
the speed excess conjoined with the disjunction of "drawing level" and "b still ahead in the same
lane". `rel.ahead_behind_in_lane` is read in the order "b is ahead of a" (the atom's first argument
is the one said to be ahead). The only literal is zero metres, the origin of the signed overlap the
atom returns; both formal parameters are used, none invented.

## Gate runs

1. **`VACUOUS`** — `obligation leaf 3: atom rel_ahead_behind_in_lane [b, a]`. The three witnesses as
   first built (the holds narrative's drawing-level pair, the fails narrative's pair in file, blind =
   holds masked) never let the in-lane disjunct decide anything: in `holds` and `blind` the overlap
   disjunct is already true, and in `fails` the speed clause is false whatever the disjunction says.
   *Changed:* the `holds` trace was rebuilt as six instants of one whole pass instead of three
   instants of the drawing-level state, so that each disjunct carries the clause alone at some
   instant (details below). `blind` reuses that trace, as the record says it does.
2. **`WITNESS_FAIL`** — `holds: expected compliant, got violated`, `blind: expected unknown, got
   violated`. The scene was wrong, not the body: `Build.scene` derives occupancy from each user's
   *position* in a polygon, so the overtaking lorry, whose centre lies in the left lane while its
   body lies over the lane line, occupied the left lane only; with no lane shared with the overtaken
   lorry, `rel_ahead_behind_in_lane` was false at the first instant and the disjunction failed there.
   *Changed:* the pass scene now states its occupancy — track 1 covers both lanes, track 2 the right
   lane — which is exactly what `TraceLint.completeOccupancy` derives from the two footprints ("a
   body on the line between two lanes occupies both").
3. **`OK`.**

## The witnesses

Map (the same in every scene): two eastbound 3.5 m lanes, region 1 on the right, region 2 on its
left, each with its direction, neighbour and place from the left. Bodies: two lorries 12 m × 2.5 m ×
4 m, due east, track 1 = `a`, track 2 = `b`. Instance figures: `same_direction_tolerance` = 0.95
(about 18°, cleared with a cosine of 1 by the parallel headings), `min_speed_excess` = 1 m/s.

- `holds` (compliant): six instants, one second apart. Track 1 at 24 m/s, centre y = 4.5 m, its body
  over the lane line and so covering both lanes; track 2 at 20 m/s in the right lane, centre
  y = 1.75 m, a quarter-metre clear of track 1's body. The centres start 13 m apart and close at
  4 m/s: −13, −9, −5, −1, +3, +7 m, so the projections on the eastward axis are 1 m apart at the
  first instant and then share 3, 7, 11, 9 and 5 m. a is passing b at every instant; at the first
  only the in-lane order carries it (b ahead of a in the shared right lane), at the last two only
  the shared projections do (a's centre has gone past b's). Every leaf therefore decides the verdict
  somewhere.
- `fails` (violated): both lorries at 20 m/s in the right lane, 40 m apart and holding it. The
  disjunction holds (b ahead of a in the same lane) and the headings agree; the speed difference is
  zero, below the 1 m/s excess, so the body is false — the narrative's reason.
- `blind` (unknown): the `holds` trace with `kin.speed` masked. The heading agreement and the
  disjunction stay decided and true at every instant, the speed clause is unknown, so the body is
  unknown throughout.

## Choices the record left open

- **Declared as a narrowing** (`{ span := "the two bodies' projections on a's heading overlap", kind
  := "reading" }`): the overlap is read as *strictly* positive. `rel.longitudinal_overlap` is signed
  — zero where the projections abut, negative for the gap between them — and projections that merely
  touch are no overlap, so the bound is `> 0` rather than `≥ 0`.
- Not narrowings, because the contract's words fix them: "by at least the speed excess" is the weak
  bound `≥` on `kin_speed a − kin_speed b`; "projections on a's heading" fixes the atom's argument
  order `(a, b)`, whose axis is the first argument's heading; "b is still ahead of a" fixes the
  in-lane atom's order `(b, a)`.
- Witness figures are the witness's own and are listed above (lane widths, lorry extents, speeds,
  offsets, the tolerance and the speed excess of the instance).
- The `holds` trace covers the whole pass rather than the drawing-level instant alone. The narrative
  states the end state ("draws level … sharing several metres"), which the last four instants show;
  the first two show a still behind b in the shared lane, the earlier part of the same pass, which is
  the only way one of the record's four claimed elements can decide anything in a witness. No
  narrative was contradicted and no fourth scenario was added.

## Why I finished

The gate returns `OK` on the third run: the body says what the record's contract says over its
formals and claimed names only, every claimed name does work in a witness, and the three scenarios
of the record hold, fail and report unknown as their narratives require. The record needed no
repair; the one defect found was in my own first witness set, and the one choice the contract left
open is declared as a narrowing.
