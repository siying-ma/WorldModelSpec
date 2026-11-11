# NRS_484D_100_1 — task result

## Final verdict: UNEXPRESSED (s9, `no_atom`)

## Gate runs
1. **UNUSED_CLAIM** — I ran it on the untouched skeleton (all formulas `.tt`). This spent one run without changing anything.
2. **UNEXPRESSED** — I ran it after writing the rule and the seven witnesses, with a `no_atom` declaration on s9.

I also tried two other commands by mistake: the gate command with `--help` added, which was denied, and a directory listing of the Core vocabulary folder, which ran. Neither changed any file.

## What is written
- **s1**: the class is `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- **s2**: `existsRegion highway h (rel_occupies x h)`. This is the whole highway, not narrowed to the roadway.
- **s4**: the vehicle is not parked, written as `not (drv_motion_halted(x; p.speed_resolution) ∧ ¬kin_engine_running(x))`.
- **s7 ∨ s8** (either trigger is enough):
  - s7 is `env_darkness`.
  - s8 is `env_visibility < Units.feet 1000`.
- **s5**: `sig_headlamp(x, low_beam) ∨ sig_headlamp(x, high_beam)`.
- **s9**: not written. It is declared `no_atom`; see below.

### Choices the node left open
- **s7's literal "one-half hour" is not a term.** `env_darkness` takes no arguments; its contract says the sunset/sunrise boundary is a reading parameter. So the one-half hour is carried by the run's darkness reading, not by a literal in the rule. The header comment records this. The gate did not object to the unused literal, but it may not have reached that check before stopping at s9.
- **No narrowing of type `reading` was added.** The only narrowing I declared is the `no_atom` on s9.

## Why s9 is `no_atom` (for the plan/repair session)
The record maps s9 ("When directed by an official traffic control device") to these atoms, with an atom gap:
- `dev.regulatory_sign`
- `dev.governs`
- `rel.occupies`
- `st.travel_region`

None of `dev.regulatory_sign`'s catalogue codes directs road users to display lamps, and no `dev.zone_sign` kind marks a lamps-on section either. A formula built from these atoms would therefore let any regulatory sign governing the vehicle's travel region trigger the headlamp duty by day, including no_parking, one_way and keep_right signs. The words do not say that.

What is needed is the plan's own gap proposal: `dev.lamps_on_sign`, or a catalogue code `lamps_on` for `dev.regulatory_sign`. Until then, s9 should be withdrawn as a gap. Once s9 is withdrawn, the claims on `dev.regulatory_sign`, `dev.governs` and `st.travel_region` must also be dropped from the node. Otherwise they will be `UNUSED_CLAIM`, because the rest of the rule does not use them.

## Witnesses (built; not yet judged by the gate)
The scene is a 200 m highway (y from −10 to 10) containing a roadway (y from −5 to 5). The car is track 1, a motor vehicle.

| Scenario | Scene | Expected |
|---|---|---|
| forbid | night, moving at 10 m/s, engine on, headlamps off | violated |
| permit | night, moving, low beam on | compliant |
| idle | clear day, visibility 2 km, headlamps off | not applicable |
| blind | as forbid, with `sig.headlamp` masked | unknown |
| branch_1 | foggy day, visibility 50 m, headlamps off | violated |
| branch_2 | night, parked on the shoulder strip at y = −7, speed 0, engine off, headlamps off | not applicable |
| branch_3 | foggy day, low beam on | compliant |

The gate stopped at UNEXPRESSED, so these witnesses have not been run.

## Why I finished
The record carries a gap on s9, and the atoms it maps s9 to cannot express a lamps-on direction. The rules say to declare `no_atom` in that case, which files the plan's gap; the gate returned UNEXPRESSED as designed. Writing s9 with those atoms would have been an over-broad trigger, and leaving it out without a declaration would have dropped a trigger silently. The rest of the rule and the witnesses are ready for when s9 is resolved.
