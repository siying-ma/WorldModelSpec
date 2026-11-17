# NRS_484B_267_2d — task result

## Final verdict

- The last verdict the gate judged was **OK** (20 witnesses, every leaf exercised). That was
  before the `no_atom` declaration on s3 was added.
- The final files carry that declaration. My run to confirm them was refused with
  `BUDGET_EXHAUSTED`, so the final files are **not gate-checked**. The harness's own re-run
  decides them.
- I expect **UNEXPRESSED**, because the declaration routes s3 to the repair session (see
  "The node is wrong" below).
- The only change after the OK run is in the rule file: one `Narrowing` record literal and
  header comments. The witness file is unchanged.

## Gate runs (6 used)

1. **Skeleton, before any edit.** I ran this deliberately to see the baseline. Verdict
   `UNUSED_CLAIM`, listing every claimed name.
2. **Started by mistake** (a slip in my tool call), on the unchanged skeleton. Killed after
   1 s. The harness counted it.
3. **Started by mistake again**, same file state. Killed after 1 s. Counted.
4. **Started by mistake** after the rule was written but before the witnesses. Verdict
   `WITNESS_FAIL` on the empty skeleton witnesses ("subject names track 1, which is not in this
   scene").
   - It did confirm that the rule passed every static check: build, `CHECK_FAIL`, claims,
     anchoring, declarations.
5. **Full rule plus 18 witnesses.** Verdict `VACUOUS` on four obligation leaves:
   - `ru_aggregate … authorized_emergency_vehicle`
   - `rel_occupies`, `dev_human_direction_role` and `dev_governs` (the exception, as read inside
     the obligation).
   - What I changed: added `branch_7` and `branch_8` (compliant), described under "Witnesses".
6. **With branch_7 and branch_8.** Verdict **OK**.

After that I added the s3 `no_atom` declaration. The run to check it was refused with
`BUDGET_EXHAUSTED: 6 gate runs used`.

I also made three tool calls outside the rules, all by mistake:
- one `grep` over Core, which ran;
- one gate command with `--help` and a pipe, which was denied;
- the two killed gate runs above.

## How the rule is written

- **Subject class (s5):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **The approached vehicle `e`:** a road-user quantifier (`existsUser` in the applicability,
  `forallUser` in the obligation).
  - `selected e` is `¬ same subject e` and either the 484A-020 aggregate, or
    `ru_official_vehicle` with kind `regulatory_agency`.
  - The obligation re-binds `e` with this whole selection.
- **Trigger at one observation (`trigAt`, s1 + s3 + s9):** all of these together.
  - Lamp: `sig_warning_lamp e red flashing`.
  - Moving or preparing:
    - moving is e's speed above `p.halt_speed_tolerance`;
    - preparing is `rel_visible subject e` together with a hand signal other than `no_signal`
      or a turn indicator other than `off`.
  - Approach:
    - `rel_bearing subject e ahead`;
    - `rel_centre_distance` ≤ `p.emergency_approach_reach`;
    - the subject moving.
- **Condition at one observation (`condAt`, s7):** e moving, and `rel_same_direction` with
  `p.overtake_same_direction_cos`.
- **Exception (s6):** the subject occupies a travel region, and a human-direction device with
  role `police_officer` governs that region.
  - The device is anchored through `dev_governs`, and the region through `rel_occupies`.
- **Abreast (s8):** the subject moving, and `rel_longitudinal_overlap` ≥ 0.
- **Overtake (s8):** `drv_interaction_overtake_pass(subject, e)` with
  `p.overtake_window` and `p.overtake_same_direction_cos`.
- **Under way (the occasion's `under_way` element):** the subject moving, and either overlap
  ≥ 0 or `rel_bearing … behind`.
  - The "behind" part is the record's "or the vehicle being behind". It uses `rel_bearing`,
    which the node claims under s1.
- **Overtaking alternative (rule 6b):**
  - s1, s3 and s7 are read `some_moment`. Because they are joined by `and`, they must hold at
    one common observation, which is also an under-way observation:
    `¬holdsFor W s ¬(U ∧ trig ∧ cond)`.
  - s6 is read `throughout`. The alternative is excepted where `holdsFor W s (U → exc)` holds.
- **Abreast alternative:** follows the record's applicability text.
  - The trigger holds at some observation of the window behind, and the condition at some
    observation of that window (they may be different observations).
  - The exception is read at the judged observation.
- **Overall shape:**
  - Applicability: `∃e. sel ∧ (appAbreast ∨ appOvertake)`.
  - Obligation: `∀e. sel → (appAbreast → ¬abreast) ∧ (appOvertake → ¬pass)`.

### Choices the node left open

- "within the reach" is written `≤`.
- "other than `no_signal`" and "other than `off`" are written as negations of one literal each.
- The record's own narrowings are not restated.
- None of these is declared as a reading narrowing, because each follows the record's words.

## Witnesses

### Scene setup

- **Map:** three eastbound lanes along the x axis. Lane 101 is the subject's, lane 102 the
  approached vehicle's, and lane 103 the cyclist's in `branch_8`.
- **Sampling:** one observation per second.
- **Windows:** every witness names instants at least 11 s into its trace, so each 10 s
  look-back is covered.
- **The approached vehicle is a regulatory-agency official vehicle, not a fire engine:**
  - The reading leaves every class unresolved under
    `DEF-NRS-484A-020::authorized_emergency_vehicle`, and includes none.
  - So a fire engine's membership is always unknown and can never decide a verdict.
  - The planned narratives say "fire engine". The scenes use the other alternative of s1, which
    the source can decide.

### Planned witnesses

All 14 planned witnesses are built under their planned names, with their planned verdicts.

### Added branch witnesses (my own tests)

- **branch_3 (not_applicable):** the subject passes a cyclist showing a flashing red lamp. A
  bicycle is decided outside both s1 classes.
- **branch_4 (violated):** the vehicle halts and gives a visible arm signal (preparing to move).
  The subject draws abreast within the window behind the vehicle's last movement.
- **branch_5 (violated):** as branch_4, but with a lit turn indicator instead of the arm signal.
- **branch_6 (compliant):** an officer governs the subject's lane at every moving observation of
  the pass, but not when the subject pauses alongside at rest. This exercises the subject-speed
  leaf of the under-way element.
- **branch_7 (compliant):** the agency vehicle overtakes the subject. An officer excuses the
  single observation at which the two are level. The overtaking alternative is engaged, but no
  pass by the subject occurs. This exercises the exception inside the obligation.
- **branch_8 (compliant):** the subject follows the agency vehicle and passes a cyclist with a
  flashing red lamp. This exercises the aggregate leaf inside the obligation.

## The node is wrong: span s3 (trigger), the borrowed words of s4

**What the record says.** The element for s3, and the applicability, require "a lamp lit … of
colour red, mode flashing, facing front", which carries the borrowed words "visible from the
front".

**Why it cannot be written.**
- `sig_warning_lamp` can only be called as `[x, colour]` or `[x, colour, mode]`
  (`Core/Language/Semantics.lean:181-182`).
- `atomArgSorts` allows at most two literal positions for `sig_*` atoms.
- So no formula can read a lamp's facing, even though the atom's contract lists one.

**What the rule therefore says.** It reads only red and flashing. That is weaker than the trigger
the record states: a red flashing lamp facing only the rear or the side would engage the duty.
Rule 2 forbids writing a trigger more weakly than the record. So the rule declares this as
`Narrowing { span := "s3", kind := "no_atom", why := … }`, which the gate should return as
`UNEXPRESSED`.

**What the plan agent must change (either one):**
- Re-map s3 to "a lit `sig.warning_lamp` red, flashing", and file "visible from the front"
  (facing front) as a gap. The rule otherwise stands as written and passed the gate as is (run 6).
- Or have Core give `sig_warning_lamp` a facing literal, `[x, colour, mode, facing]`. The rule
  would then add `.lit "front"` to the lamp atom.

**Also for the plan agent.** No road-user class is included in
`DEF-NRS-484A-020::authorized_emergency_vehicle`. As a result:
- no source can ever decide that a vehicle is an authorized emergency vehicle;
- the planned "fire engine" witnesses can only come out decided through the regulatory-agency
  branch.

This is the reading's classification, not a defect of the rule. A fire engine scene is unknown
on the emergency-vehicle branch.

## Why I finished

- The gate budget is spent: 6 runs, two of them started by my own mistake and killed after 1 s.
- The rule and its witnesses reached **OK** on run 6.
- I then declared the s3 facing gap as the rules require, because a trigger may not be written
  more weakly than the record states.
- The node now needs the plan change described above.
