# LVMC_11_60_090 — task result

**Final verdict: OK** (5 witnesses, 11 names, composes nothing)

## Gate runs
1. **UNUSED_CLAIM** — I ran it by mistake on the harness skeleton before editing anything, so every claimed name was reported as unused. Nothing changed after this run; it is why this session used more runs than the edits needed.
2. A second invocation was sent by mistake through a piped/no-op command. Its output was discarded, so I can't tell whether the gate counted it.
3. **WITNESS_FAIL** — permit and branch_1 failed the check that a trace is one the adapter can produce. Their headings stayed fixed while the yaw rate said they were turning. Change: the turn is now 18 scenes at −100°/s. The heading vector follows the yaw at 5° per scene, using a 7-decimal cos/sin table. The position is integrated 50 cm per scene along each scene's heading, which gives −90° in total.
4. **VACUOUS** — the "no other intersection" leaf in the obligation (`rel_occupies(subject, q)`) never changed a verdict. forbid had only one intersection, so the `forall q` was trivially true. Change: the second intersection R2 (unvisited) is now in the forbid, permit and blind scenes.
5. **OK**.

## Rule as written
- s1: binder class `ru_taxicab subject`.
- s2 ∧ s4 (read at the departure observation d):
  - Some `curb_zone k` with `st_curb_zone_kind k taxicab_stand` and `rises(¬rel_occupies(subject,k))`.
  - Some `regulatory_sign d` of code `right_turn_only`, with `prim_conditions_hold(d, subject)`, that `dev_governs` a `travel_region v` the subject occupies.
- s5 (`selection r`):
  - `rises(¬rel_occupies(subject,r))`, the exit from r and the occasion's recognition.
  - `[∀ intersection q: same q r ∨ ¬rel_occupies(subject,q)] since [s2 ∧ s4]`.
- Applicability: `∃ intersection r. selection r`.
- Obligation: `∀ intersection r. selection r → drv_motion_right_turn_through_region(subject, r)` with the parameters `p.heading_since_step_carla_scene_graph`, `p.turn_heading_min` and `p.u_turn_heading_min`.
  - The applicability's whole selection is repeated here (rule 3c).
  - The duty applies at every intersection so selected. In practice that is the single exited one.

## Choices the node left open
- **Quantifier in the obligation:** universal with an implication (the duty at each selected intersection), not existential. Only one intersection can be both exited at an observation and be the first since the departure, so the two readings agree.
- **No narrowings declared.** Every span is written as the record maps it.

## Witness notes
- `since` treats the past before the trace as unknown. That raised two problems:
  - **idle:** to be decided not applicable, the cab starts inside another intersection Q before pulling into the stand. That makes the "first intersection" condition definitely false from the trace start onward.
  - **First scene:** in every witness it is left out of the window, because `rises`/`since` cannot see the observation before it there.
- **branch_1's window** starts after the exit from the first intersection. The narrative's verdict (not applicable) concerns the exit from the second intersection. Including the compliant right turn through the first would make the episode compliant.
- **idle's sign** is right_turn_only but governs lane S, which the cab never enters. This makes the `dev_governs` leaf decide.

## Why I finished
The gate returned OK.
