# NRS_484B_267_1a — task result

## Final verdict: UNEXPRESSED (declared `no_atom` on u4)

The rule and its 8 witnesses pass every other check: the run just before the declaration returned
`OK — 8 witnesses, 15 names, composes nothing`. The only open point is the declaration below.

## Gate runs (4 of 6 used)

1. **UNUSED_CLAIM** (all 13 names): this was the harness skeleton (`.tt` placeholders), run first to see the baseline.
   Then I wrote the rule and seven witnesses.
2. **VACUOUS**: the obligation's copy of `ru_aggregate e DEF-NRS-484A-020::authorized_emergency_vehicle`
   moved no witness. I added `branch_4` (compliant). In it the subject keeps clear of the regulatory
   vehicle, while a bicycle with a lit red flashing lamp is in conflict with it. If that leaf were true,
   the bicycle would be selected and the verdict would become violated.
3. **OK**: 8 witnesses, 15 names.
4. **UNEXPRESSED**: after I added the `no_atom` declaration on u4 (below).

## How the rule is written

- **Subject (u6):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`. "Every other" is
  `not (same e subject)`.
- **Applicability:** `existsUser e (approaching e) ∧ ¬ directedByOfficer`. `approaching e` requires
  all of the following:
  - e is not the subject.
  - e is in u2 or u3: `ru_aggregate e AEV ∨ (ru_official_vehicle e ∧ ru_official_vehicle_kind e regulatory_agency)`.
  - u4: `sig_warning_lamp e red flashing`.
  - u1: `kin_speed e > p.halt_speed_tolerance`, `rel_bearing e subject ahead`, and
    `rel_centre_distance e subject ≤ p.emergency_immediate_approach_reach`.
- **Exception (u7):** `existsDevice human_direction d (role police_officer ∧ existsRegion travel_region r (dev_governs d r ∧ rel_occupies subject r))`.
- **Obligation (u8/u9):** `forallUser e (approaching e → (kin_speed subject > p.halt_speed_tolerance → ¬rel_contact subject e ∧ ¬(prim_closest_approach_within subject e p.conflict_horizon ∧ prim_closest_approach_distance subject e p.conflict_horizon < p.conflict_centre_clearance)))`.
  The obligation repeats the applicability's whole selection of e.

### Choices the record left open

- "Subject ahead in e's frame" is written as the Boolean `rel_bearing e subject "ahead"`, which tests
  that the longitudinal component is positive. The record states exactly that, so this is not a narrowing.
- The exception is about the subject only, so it stays in the applicability and is not repeated in
  the obligation.

## The node's defects (for the plan / repair agent)

1. **u4 / u5: "visible from the front" cannot be stated.** The record requires the lamp to face
   front. The formula language's `sig_warning_lamp` reads only colour, or colour and mode
   (`Semantics.evalAtomE`, `Atoms.lean` `sig_warning_lamp_shows`). No atom on the surface reads a
   lamp's `facing`.
   - The formula therefore says "a lit red flashing warning lamp" in any facing. That is a weaker
     test on a condition span.
   - I declared this as `no_atom` on u4 rather than weakening the condition without saying so.
   - The repair needs one of two things: withdraw "visible from the front" as a gap, or have Core
     add a facing-aware form of `sig.warning_lamp`.
2. **u2: the planned `forbid`, `permit` and `blind` (the ambulance) cannot be reached under this
   run's reading.**
   - `DEF-NRS-484A-020::authorized_emergency_vehicle` includes no class; every vehicle class,
     `ru.emergency_vehicle` among them, is unresolved.
   - So `ru_aggregate e AEV` is never true. For an ambulance it is always unknown
     (`aggregateUnresolved`), which makes the applicability unknown on every scene. An ambulance
     `forbid` returns unknown, not violated, and an ambulance `permit` cannot be compliant.
   - I built `forbid`, `permit` and `blind` on the u3 limb instead: an official vehicle of kind
     `regulatory_agency`, with a red flashing front lamp. Every other part of each narrative is
     kept. The witness file's header says this.
   - To fix it, either the reading must decide some class (e.g. `ru.emergency_vehicle`) as
     included in the aggregate, or the plan must base these scenarios on the u3 limb.
   - The u2 leaf is exercised only by `branch_3` and `branch_4`: a bicycle, which is decidedly
     outside the aggregate.

## Witnesses

| scenario | expected | what it shows |
|---|---|---|
| forbid | violated | Regulatory vehicle closing on the subject in the same lane: closest approach at 2.25 s and 1.25 s, at 0 m |
| permit | compliant | As forbid, but the subject is in the right lane: closest approach 4 m (≥ 3 m), no contact |
| idle | not_applicable | The lamps are observed and none is lit |
| blind | unknown | `sig.warning_lamp` is masked |
| branch_1 | not_applicable | A police officer governs the subject's lane |
| branch_2 | violated | The bodies overlap (contact) with no relative motion |
| branch_3 | not_applicable | A bicycle with a red flashing lamp is in conflict: it is neither u2 nor u3 |
| branch_4 | compliant | As permit, plus a bicycle with a red flashing lamp in conflict with the subject |

## Why I finished

Every other check passes (run 3 was OK). The one remaining point, "visible from the front", cannot
be stated with the surface's atoms. The rules say to declare that as `no_atom` so the repair
session can withdraw it as a gap or re-map it; I declared it, and the gate returned
`UNEXPRESSED`. More runs could not change that. Defect 2 (the reading leaves the
emergency-vehicle aggregate unresolved for every class) is reported above for the plan.
