# LVMC_11_16_040 — task result

## Final verdict

**SCOPE_VIOLATION (infrastructure, not my files).** I never got a gate verdict on the content of
the rule or the witnesses. Both gate runs failed the scope check on files under `.runtime/tmp/`
only: the Bash tool's own `tasks/*.output` files, from this session and from concurrent sessions
of other nodes (LVMC-11-18-020, LVMC-11-30-050, LVMC-11-43-010-B-o1), and a
`cache-break-state-*.json`. None of them is a file I wrote or could avoid. Every call to the gate
command makes a new output file, so the scope check cannot pass from inside this session. This
should be counted as `INFRA`. The harness's own re-run after the session is the first real test
of the two files.

## Gate runs

1. **SCOPE_VIOLATION**: run by mistake on the untouched skeleton (I meant to open a Core file).
   It listed only `.runtime/tmp` files.
2. **SCOPE_VIOLATION**: run after writing the rule and the 15 witnesses. Again only
   `.runtime/tmp` files were listed, including other sessions' output files.
   After this run I renamed one witness helper (`clear` → `clearSight`) to avoid any clash with
   a name. I did not run the gate again because it would make another tmp file and return the
   same verdict. 2 of 6 runs used.

(A third command, a malformed gate call with extra shell syntax, was denied by the permission
layer and did not run.)

## How the rule is written (also in the rule file's header)

- **d5 (class)**: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **d2**: `existsRegion intersection j`, with `rel_occupies(subject, j)` at the judged observation.
- **d4**: `since (occ j) (¬occ j ∧ ¬holdsFor .path (100 ft) subject (¬unclear) ∧ ¬through)`.
  - Core's `since` reads ψ at a past observation and φ strictly after it. So ψ is evaluated at
    the last observation before the subject's occupancy of j rose.
  - The 100-ft `.path` window behind that observation is the "last one hundred feet of his
    approach".
  - It contains an observation with an unclear view.
  - No path length measured from the trace start is read.
- **d6**: `st_sight_distance(j) < st_region_geometry_distance(subject, j)`.
  - Choice: the sight-distance atom belongs to a region. The only region d6 claims is the
    intersection, so I read j's sight distance.
- **d8**: there is some highway w with `st_on_way(j, w)` and
  `st_sight_along_way(subject, w) < 100 ft`.
- **d7**: there is some highway v with `st_on_way(j, v)`, and some road user o such that:
  - o is not the subject;
  - o is a member of `DEF-NRS-484A-285::traffic`;
  - o occupies v;
  - `st_region_geometry_distance(o, j) ≤ 100 ft`;
  - `¬rel_visible(subject, o)`.
- **unclear**: d6 ∨ d7 ∨ d8.
- **d9**: read at the pre-entry observation. Both of these hold:
  - there is a travel region c with `occ(subject, c)` and `st_lane_enters(c, j)`, governed by no
    stop sign, no yield sign and no traffic signal showing `flashing_red`;
  - there is a travel region e with `st_lane_enters(e, j)` governed by one of those.
- **d10**: read at the judged observation. There is a travel region k with `same k j` or
  `st_lane_enters(k, j)`, governed by any of:
  - a traffic signal that does not show `dark`;
  - a stop sign;
  - a yield sign.
- **d1 (obligation)**: `kin_speed(subject) ≤ 15 mph`.
- **d3**: the node's residue.
- No narrowings were declared. Every span is a trigger, condition or exception except d1, and I
  made no reading choice on d1.

## Things the node left open, and points for the plan agent

- **d9 is logically contained in d10, as the node maps them.** d9 needs another approach to j
  governed by a stop sign, a yield sign or a flashing-red signal. Each of those already makes j
  "traffic-controlled" under d10.
  - So `¬d9 ∧ ¬d10` = `¬d10`, and d9 never changes a verdict.
  - If the gate's adequacy check reports VACUOUS on d9's leaves, this is why. It is a property
    of the node's mapping, not a witness gap.
  - The plan agent may want to fold d9 into d10, or note the redundancy.
- **d9's "the carrier it occupied"**: I wrote it as an existential over the carriers the subject
  occupies. Each witness has a single approach carrier.
  - The `st.lane_enters` contract says that where several occupied carriers disagree, the result
    should be unknown.
  - The existential instead favours the exception in that case. It does not arise in these
    witnesses.

## Witnesses

Common setup:
- Two highways (ids 10 and 11) and an intersection (20) on both.
- Approach lanes: lane 30 (northbound, the subject's) and lane 31 (westbound cross approach), both
  entering 20.
- The subject drives north, 5 m of path per observation. It is in lane 30 until k = 12 and in the
  intersection for k = 13…16.
- The 100-ft window behind k = 12 is covered and adequately sampled.
- Fast runs: 10 m/s, one observation per 0.5 s. Slow runs: 5 m/s, one per 1 s.
- Each witness's `window` names the in-intersection instants.

Planned scenarios:
- **forbid** (violated): sight along way 11 is 20 m; fast.
- **permit** (compliant): as forbid; slow.
- **idle** (not applicable): a circular_green signal governs lane 30.
- **blind** (unknown): sight along the ways is not supplied, and `st.sight_along_way` is masked.
- **branch_1** (compliant): sight along way 11 is 25 m; no other users; slow.

Branches I added:
- **branch_2** (violated): a car 22.5 m from j on way 11, not visible.
- **branch_3** (not applicable): the same car, visible.
- **branch_4** (not applicable): the car is 87.5 m away, not visible.
- **branch_5** (violated): the intersection's sight distance is 10 m.
- **branch_6** (not applicable): a stop sign on lane 31.
- **branch_7** (not applicable): a yield sign on lane 30.
- **branch_8** (not applicable): a green signal governing j itself.
- **branch_9** (violated): a dark signal on lane 30.
- **branch_10** (not applicable): a flashing-red signal on lane 31.
- **branch_11** (not applicable): the view is clear.

## Why I finished

The gate fails at the scope check on harness runtime temp files outside my two files. They
include other concurrent sessions' output files. Every further run creates more, so the remaining
budget cannot produce a judgement on the content. Both files are complete, with no `TODO` and no
`.tt` placeholders. The harness's re-run after the session will judge them.
