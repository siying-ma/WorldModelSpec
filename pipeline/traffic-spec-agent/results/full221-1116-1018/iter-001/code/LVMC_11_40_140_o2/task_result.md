# LVMC_11_40_140_o2 — task result

## Final verdict

**SCOPE_VIOLATION, an infrastructure fault rather than a defect in the node's files.** The gate never judged the rule or the witnesses. The two
files are written in full; the harness's own re-run after this session is the first judgement.

## Gate runs (3 of 6 used)

| # | files | verdict | cause |
|---|---|---|---|
| 1 | skeletons, untouched | SCOPE_VIOLATION | "changed outside the node's files": only paths under `.runtime/tmp/claude-154266/…/tasks/*.output` and `.runtime/tmp/claude-154266/cache-break-state-….json` |
| 2 | skeletons, untouched (I started this run by mistake, as `gate … \| head -0`; its output was discarded) | (not seen) | — |
| 3 | rule + 7 witnesses written | SCOPE_VIOLATION | same list, plus the `.output` file of this gate call itself |

The listed paths are the tool runtime's scratch files. The agent runtime writes them for every
shell call, the gate call included. Several are from other nodes' concurrent sessions
(LVMC_11_18_020, LVMC_11_30_050, LVMC_11_43_010_B_o1). That runtime directory sits inside the
worktree the gate diffs, so every run reports SCOPE_VIOLATION whatever the node's files contain.
Running the gate again would only burn budget. **Operator action:** exclude `.runtime/` from the
gate's scope check, or move the agent runtime's tmp directory out of the worktree.

Because the gate never got past the scope check, the files are **not verified by build or
evaluation**. What follows is my own reading of the code against Core
(`Foundations/Temporal.lean`, `Vocab/Atoms.lean`, `Vocab/Primitives.lean`, `Language/RuleEval.lean`,
`Evidence/Builders.lean`). It is not an acceptance signal.

## The rule

- **Class (e1):** the three admitted aggregates, joined by `or` (`ru_aggregate` with each id).
- **Applicability:** `∃ sidewalk s. onS ∧ since onS (rises onS ∧ asm) ∧ since onS (trigger)`.
  - `onS` is `rel_occupies(subject, s)` and `st_region_geometry_distance(subject, s) = 0`. This is
    occupancy read together with the sidewalk outline that the record claims for e5.
  - `since onS ψ` reaches back exactly to the latest entry: `rises onS` at the entry, or `¬onS` at
    the observation just before it. So "at the entry" is read as the record states it.
  - The trigger covers e3's alternatives, all in one `since` so they speak of the same entry:
    1. alley or driveway/alley-entrance occupancy at the entry or the observation before;
    2. no highway region occupied at the observation before (emerging from a building);
    3. from the entry, on s `until` no highway region is occupied (entering a building).
- **Obligation (e6/e7):** `∀ p. (pedestrian(p) ∧ ¬same(p, subject)) → (¬rel_contact ∧ ¬(speed > p.halt_speed_tolerance ∧ prim_closest_approach_within(h) ∧ prim_closest_approach_distance(h) < p.conflict_centre_clearance))`.
  This is the record's obligation and its own e6 narrowing. A scene with no pedestrian is
  compliant.
- **Narrowings:** none added. The one choice the record left open is how e5's
  `st.region_geometry` combines with `rel.occupies`. I chose a conjunction, following the
  element's justification ("reads the sidewalk's outline for the occupancy the source derives").
  It is explained in the rule header. A conjunction states a stronger fact, never a weaker one.

## Witnesses

| name | expected | scene |
|---|---|---|
| `forbid` | violated | driveway (driveway is the only trigger alternative that decides) |
| `permit` | compliant | halts, the pedestrian passes 0.45 m clear, then moves away |
| `idle` | not applicable | on the roadway only |
| `blind` | unknown | the `forbid` trace with `rel.occupies` masked |
| `branch_1` | compliant | alley, no pedestrian |
| `branch_2` | violated | emerging from a building (added) |
| `branch_3` | violated | entering a building (added) |

The highway includes a 2 m border beyond the sidewalk, and the driveway and alley regions reach
into it. On the observation before the entry the rider is therefore on both the highway and the
driveway or alley, so the alley/driveway alternative is the only one that decides `forbid` and
`branch_1`. `branch_2` and `branch_3` each decide through one of the building alternatives.

In `blind`, the geometry distance is decidedly non-zero off the sidewalk, which keeps `since`,
`rises` and `until` decided at the ends of the trace. The only unknown reason left should be
`absent_atom:rel_occupies`.

## Defect to report (reading, not node)

The reading admits no class into `DEF-LVMC-11-02-083::electric_scooter`: its included list is
empty and `ru.electric_scooter` is only unresolved. A road user observed only as
`.electricScooter` leaves the subject's class unknown, so no witness can decide this aggregate,
and the gate's VACUOUS rule may flag its leaf.

The planned `branch_1` narrates an electric scooter and expects compliant. I built its subject as
`[.electricScooter, .electricBicycle]`, so the class is decided through the electric-bicycle
aggregate. A scooter observed as nothing else would make `branch_1` unknown.

The reading's classification of `ru.electric_scooter` under DEF-LVMC-11-02-083 should be
**included** (the definition's term is that class). If VACUOUS is reported on the
electric_scooter leaf, that is the cause; the rule should not drop the leaf.

## Why I finished

Every gate run returns SCOPE_VIOLATION for files the agent runtime writes inside the worktree. No
edit to the two node files can change that, so further runs would only spend budget. The rule and
witnesses are complete for the harness's own re-run.
