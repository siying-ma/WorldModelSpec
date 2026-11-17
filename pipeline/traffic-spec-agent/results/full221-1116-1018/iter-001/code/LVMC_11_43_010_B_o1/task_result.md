# LVMC_11_43_010_B_o1 — task result

## Final verdict
**SCOPE_VIOLATION (infrastructure, not from the node's files).** The gate never judged the rule or the witnesses.

## Gate runs
1. **SCOPE_VIOLATION**: run on the skeletons by mistake, before any edit.
2. **SCOPE_VIOLATION**: a second run I started by mistake; the files were unchanged.
3. **SCOPE_VIOLATION**: run on the finished rule and witnesses.

Each time the gate listed only files under `.runtime/tmp/claude-154266/…`:
- the agent runtime's background-task `*.output` files, including files from other sessions (LVMC-11-18-020 and LVMC-11-30-050);
- `cache-break-state-*.json`.

None of these are files I edited. The runtime writes one for each shell call, so every later gate run will show the violation too. The harness should leave `.runtime/` out of the scope check, or put the runtime temp dir outside the repo. I used 3 of the 6 runs and stopped, because more runs could not get past this check. Two of the three were wasted by my own mistakes.

## What was written
**Rule** (`TrafficSpec/Rules/LVMC_11/LVMC_11_43_010_B_o1.lean`):
- **Subject class:** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability:** `existsRegion roundabout r. rises(rel_occupies(subject, r))`. This covers b3 and b5: the subject occupies `r` now and did not at the observation before.
- **Obligation:** `forallRegion roundabout r. rises(occ(subject,r)) → forallUser v. (ru_aggregate(v, vehicle) ∧ occ(v,r) ∧ ¬rises(occ(v,r))) → (¬rel_contact(subject,v) ∧ ¬(prim_closest_approach_within(subject,v; p.conflict_horizon) ∧ prim_closest_approach_distance(subject,v; p.conflict_horizon) < p.conflict_centre_clearance))`.
  - The obligation repeats the applicability's full selection of `r` and states the duty for every `r` selected that way.

**Witnesses:**
- **The four planned scenes:** forbid (violated), permit (compliant), idle (not applicable) and blind (unknown, with `rel.occupies` masked).
- **branch_1:** the empty roundabout (compliant).
- **Two extra branches I added:**
  - branch_2: a bicycle on the conflicting course, so not a vehicle (compliant).
  - branch_3: a car entering at the same instant from another approach, so not "already in" the roundabout (compliant).
- **Window:** every witness judges t = 1000 and 2000 ms (`window`), so each judged instant has an observation before it for `rises`.
- **Margins:** checked against the reading (horizon 3 s, clearance 3 m).
  - forbid: closest approach at 1.3 s, about 2.1 m apart.
  - permit: closest approach at 2.3 s, about 30 m apart.
  - branch_3: closest approach at 1.76 s, about 0.9 m apart.

## Choices the node left open
- **"At the observation before" (b8)** is written `occ(v,r) ∧ ¬rises(occ(v,r))`. Where `occ(v,r)` holds now, this means exactly that `v` occupied `r` at the previous observation. It is a rewrite with the same meaning, not a narrowing.
- **"Other than the subject"** has no `same` conjunct of its own. The subject never meets b8's selection, because it did not occupy `r` at the observation before its entry. A separate conjunct would be a leaf that does no work.
- **Narrowings:** I declared none.

## Likely issue in the node (for the plan agent)
**b6 claims `kin.speed`, but the node's obligation statement never reads speed.** It states the yield only through `rel.contact` and the closest-approach primitives, which read `kin.position` and `kin.velocity`, not `kin.speed`. My rule follows the obligation exactly and does not use `kin.speed`.

If the gate gets past the scope check, it may return UNUSED_CLAIM on `kin.speed`. That would be the node's defect: either drop `kin.speed` from b6's element, or have the obligation say what the speed does (for example, a stop-or-slow reading of "yield").

## Why I finished
The gate's scope check is tripped by the runtime's own temp files, which neither file change can fix. Using the remaining runs could not produce a verdict on the files. The files are complete as written for the harness's own re-run.
