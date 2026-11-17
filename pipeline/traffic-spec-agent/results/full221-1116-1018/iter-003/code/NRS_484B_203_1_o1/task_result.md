# NRS_484B_203_1_o1 — task result

**Final verdict: OK** (5 witnesses, 7 names, composes nothing)

## Gate runs (3 of 6 used)
1. `UNUSED_CLAIM` (drv_motion_complete_halt, rel_bearing, rel_longitudinal_overlap, rel_occupies, …).
   This ran on the untouched harness skeleton (`.tt` placeholders). The command was also piped
   through `head`, which was a mistake on my part; it changed nothing in the files.
   After it: I wrote the rule and all five witnesses.
2. `BUILD_FAIL`: rule line 72. `Term.measure` takes two arguments (atom, args), and I had passed an
   extra params list. After it: I removed the extra `[]`.
3. `OK`.

## How the rule is written
- Class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (h1, "proceeding"): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- Obligation: `forallUser c`, where c is a vehicle (same aggregate), some region of kind `highway`
  is occupied by both subject and c (`rel_occupies` ×2), `rel_oncoming(subject, c; p.oncoming_heading_cos)`,
  and `rel_longitudinal_overlap(subject, c) > 0`. If all of that holds, then `rel_bearing(subject, c, "left")`.

## Choices the node left open
- "Alongside" is a strictly positive overlap. The record says "the projections share length", so
  touching ends (overlap 0) do not count.
- "On the subject's left" is a strictly positive lateral bearing (`rel_bearing … "left"`), as the
  record's obligation says. So a lateral offset of exactly zero is not compliant.
- I added no `same c subject` exclusion. The subject is never oncoming to itself (its headings are
  aligned, cosine +1), so that implication is decided true for the subject.
- No narrowings declared: every span is written as the record maps it.

## Witnesses
All scenes use one highway region (100 m × 10 m) and 5 m × 2 m cars. The other car is 2 m ahead
(3 m of shared projection, still closing) with headings exactly opposed, and its centre is 3.5 m
across from the subject's.
- forbid: the other car is on the subject's right → violated.
- permit: the other car is on the subject's left → compliant.
- idle: the subject's speed is 0 → not applicable.
- blind: the forbid scene with `rel.occupies` and `rel.bearing` masked → unknown.
- branch_1: the subject is alone → compliant.

## Why I finished
The gate returned OK.
