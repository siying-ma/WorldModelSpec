# LVMC_11_22_010 — task result

## Final verdict

**SCOPE_VIOLATION (infrastructure, not the node's files).** The gate never judged the rule or the
witnesses. Each run reported as "changed outside the node's files" only paths under
`.runtime/tmp/claude-154266/…/tasks/*.output` and `.runtime/tmp/claude-154266/cache-break-state-*.json`.
These are the agent runtime's own task-output files, from this session and from concurrent sessions
(LVMC-11-18-020, LVMC-11-30-050, LVMC-11-43-010-B-o1/o2). Running the gate command writes a new one
of these files itself (`…/LVMC-11-22-010/…/tasks/<id>.output`), so no edit to the two node files can
clear the verdict. The scope check needs to ignore `.runtime/tmp/`, or the runtime's temp directory
needs to sit outside the checked worktree.

## Gate runs

1. A stray invocation (`python -m harness gate … | head -0`). I ran this by mistake before the files
   were written, so its output was discarded. It probably used one run of the budget.
2. SCOPE_VIOLATION, listing only `.runtime/tmp/…` files as above.
3. SCOPE_VIOLATION, same list plus the new task-output file that run 2's own invocation created.
   I stopped running the gate here: the failure is structural, and more runs would only use up budget.

After run 3 I made one defensive change: in the witness file I renamed the helper `step` to
`sampleStep`, to avoid a possible clash with a name from the opened `TrafficSpec` namespace. Nothing
else changed. Neither file has been built or judged by the gate.

## How the node is written

- **Binder class (h1/h3, 'vehicle'):** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability (h3, 'operating'):** `kin_speed(subject) > p.halt_speed_tolerance`.
- **Obligation (h2 + h4, the surrogate):** the two conditions below must both hold.
  - For every road user `other` that is not the subject: `¬ rel_contact(subject, other)`.
  - For every road user `lead` that is not the subject and is ahead of it in its lane
    (`rel_ahead_behind_in_lane(lead, subject)`; in Core, the first argument is the one ahead):
    `¬ (prim_closest_approach_within(subject, lead; p.attention_ttc_min) ∧ prim_closest_approach_distance(subject, lead; p.attention_ttc_min) < p.conflict_centre_clearance)`.
    Where the centres do not approach within the horizon, the first operand is false and decides the
    conjunction, so the undefined distance does not make it unknown.

## Choices the node left open

- **Narrowing on h2 (kind `reading`):** the record says "in contact with no road user and no
  structure", but `rel_contact` takes two tracks. The formula therefore checks contact with other
  road users only, not with structure regions. This is declared in `narrowings` and in the file
  header. The plan agent may want to know that "no structure" cannot be carried by `rel.contact` as
  Core types it. If contact with structures is meant to be judged, the node would have to claim
  another atom (for example, `rel.occupies` against an obstruction region).
- **Quantifier variables:** `other` (contact) and `lead` (rear-end conflict) get distinct names.
  Both exclude the subject with `same`.

## Witnesses

Lane 10 runs east, 4 m wide. Cars have half-extent 2.4 × 1.0 × 0.75 m. Each trace has 3 instants,
0.1 s apart.

- **forbid** (violated): the subject drives at 10 m/s towards a halted car 12 m ahead. The centres
  meet after 1.0–1.2 s, which is under 1.5 s, at 0 m, which is under 3 m. The bodies never touch.
- **permit** (compliant): a car 30 m ahead travels at the same 10 m/s, so the centres never approach.
- **idle** (not applicable): the subject stands at 0 m/s before a red signal.
- **blind** (unknown): the forbid scene with the subject's speed set to `none` and `kin.speed`
  masked.
- **branch_1** (compliant): the subject drives alone at 10 m/s.
- **branch_2** (violated, my addition): a side-by-side car in lane 11 overlaps the subject's body by
  0.2 m across, and nothing is ahead in the lane. Only the contact condition decides this one.

## Why I finished

The gate's only verdict was a scope violation caused by runtime temp files that the gate invocation
writes itself. The node's files cannot fix that, and spending the rest of the budget would not change
it. The rule and witnesses are complete as written. The harness's own re-run after this session
will judge them, provided `.runtime/tmp` is excluded from the scope check.
