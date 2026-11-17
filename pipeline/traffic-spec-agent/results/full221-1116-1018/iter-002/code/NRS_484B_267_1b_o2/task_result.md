# NRS_484B_267_1b_o2 — task result

## Final verdict: UNEXPRESSED (u4, no_atom)

Without the u4 declaration the rule and its 7 witnesses pass the gate (`OK`, 7 witnesses, 19 names,
composes nothing). The one thing it cannot state is the qualifier "facing front" on the warning lamp.

## Gate runs (3 of 6 used)

1. **UNUSED_CLAIM**: I ran this by mistake on the skeleton the harness wrote, before editing anything. It lists every claimed name as unused, as expected.
2. **OK**: rule fully written; witnesses forbid / permit / idle / blind / branch_1 plus the added branch_2 and branch_3.
3. **UNEXPRESSED**: added the `no_atom` narrowing on u4 (below). No other change.

(A stray composite shell command was also denied before run 1; it did not reach the gate.)

## The gap: span u4, "visible from the front"

The record maps u4 (with the words u5 borrows from DEF-NRS-484A-480-3, "at least one flashing red
warning lamp visible from the front") to `sig.warning_lamp` read as colour red, mode flashing,
facing front. The applicability states "facing front" too. The formula surface reads this atom
only as `sig_warning_lamp [x, colour]` or `[x, colour, mode]`. `Semantics.evalAtomE` has no form with a facing
argument, and `Atoms.lean` has no accessor that reads `WarningLamp.facing`. u4 is a condition span,
so it may not be written with a weaker fact. The only formula possible is "a red flashing warning lamp lit", which is
weaker, so I declared `no_atom` on u4.

**What the plan or repair session needs to do:** withdraw "visible from the front" / "facing front" from u4
as a gap (the rule then fires for a red flashing lamp in any facing), or have Core add a facing
selector to `sig_warning_lamp`. If the gap is withdrawn, remove the `narrowings` entry and the
rule is otherwise ready: run 2 shows it passes.

## Choices the node left open

- **Where u1 goes:** the record's applicability text contains the immediate approach (speed > p.halt_speed_tolerance,
  `rel_bearing(e, subject).x > 0`, `rel_centre_distance ≤ p.emergency_immediate_approach_reach`). I wrote it there,
  inside the `existsUser e` that selects the emergency or regulatory vehicle.
- **Where b7 goes:** the skeleton's docstring lists b7 under applicability, but the record's obligation and the planned
  `branch_1` (compliant when no sign is present) put the shoulder_use_permitted sign in the obligation's
  selection of the shoulder. I followed the record.
- **u3:** written as `ru_official_vehicle(e) ∧ ru_official_vehicle_kind(e, regulatory_agency)`.
- **"Comes to rest":** `.rises (drv_motion_complete_halt subject [p.halt_speed_tolerance])`, as the record states.
  All witnesses set `window` to t ∈ [1 s, 3 s] because `rises` looks back.
- **Witnesses added:** `branch_2` (not_applicable) has a bicycle with a red flashing lamp; it is neither an authorized emergency vehicle nor
  an official vehicle. It exercises the AEV-aggregate leaf. In this run's reading that aggregate has no
  included classes, so it can only ever be false or unknown. `branch_3` (not_applicable) has a police officer
  directing traffic in the lane and shoulder the subject occupies, which exercises the u7 exception.
- **Forbid's approaching vehicle:** a regulatory-agency official vehicle, not the ambulance in the narrative. An
  ambulance's classes are all "unresolved" for DEF-NRS-484A-020::authorized_emergency_vehicle in this
  reading (no class is included), so `ru_aggregate` would be unknown and forbid could not be violated.

## Why I finished

The rule is fully written and passes the gate apart from u4. u4's "facing front" cannot be stated with any
atom of the surface, and the protocol requires a `no_atom` declaration for that, which sends the node to
the repair session as UNEXPRESSED.
