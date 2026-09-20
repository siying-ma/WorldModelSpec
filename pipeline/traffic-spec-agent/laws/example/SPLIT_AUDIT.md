# Split audit of the unsplit Core files (2026-09-20)

`SPLIT.md` lists the atoms, enumeration values and derived concept whose only textual support is
a test line. The training-only artifacts (`ontology/ATOMS_train.md`, `library/splits/train/…/
Atoms.lean`, `…/Ontology/*.lean`) omit them. Every other Core file is left as it is; this audit
says what in those files exists only because of a test line, so the reader can decide.

Method: (1) a scratch copy of the library with the three training files swapped in was built with
`lake build`; (2) every identifier the training ontology lacks (removed `def`s, removed
constructors, the World fields only a removed atom reads, the removed derived concept) was searched
for across `Core/*.lean`, `Tests/*.lean`, `Main.lean` and the witness root.

## Build result

The swapped library fails at `World.lean` (the first module after the ontology): `DoorSide` is
unknown, because the `sig.door_open` value set is test-only and the training `Signal.lean` no
longer defines the type. Every module downstream is blocked by that one error, so the remaining
findings come from the search.

## Findings, by file

| file | what only a test line brings | would have to go for a strictly training-only Core |
|---|---|---|
| `Core/World.lean` | `Kin.steerAngle` (`kin.steer_angle`, NRS 484B.533); `Signals.reverseLamp` (484D.205(4)); `Signals.signalArm` (ice-cream truck, LVMC 11.22.150); `Signals.doorsOpen : Option (List DoorSide)` (484B.153); `Signals.compressionBrake` (484D.285); `Device.onTrack`, `.redFlashing`, `.amberFlashing`, `.stopArm` (school bus signal, 484B.353) | the eight fields and the `DoorSide` use; the structures keep every other field |
| `Core/Decode.lean` | the JSON keys of the same eight fields: `steer_angle`, `reverse_lamp`, `signal_arm`, `doors_open`, `compression_brake`, `on_track`, `red_flashing`, `amber_flashing`, `stop_arm` | the nine decoder lines |
| `Core/Manifest.lean` (`Mask.user`) | the mask arms for `kin.steer_angle`, `sig.reverse_lamp`, `sig.signal_arm`, `sig.door_open`, `sig.compression_brake`; the kind-atom arms (`ru.*`, `st.*`, `dev.*`) are generic and need no change | the five arms |
| `Core/Semantics.lean` | dispatch arms and table entries for `kin_steer_angle`, `sig_reverse_lamp`, `sig_signal_arm`, `sig_door_open` (both arities, `DoorSide.ofString`), `sig_compression_brake`, `dev_school_bus_signal_{on_track,red_flashing,amber_flashing,stop_arm}`; class atoms (`ru_school_bus`, `ru_low_speed_vehicle`, `st_roundabout`, `st_turnout`, `dev_school_bus_signal`, …) dispatch through the generated codecs and need no change | the arms and the entries in `boolAtomNames` / `measureNames` |
| `Core/Derived.lean` | `drv_queue_behind` (definition, `derivedNames` entry, `reads` entry, `evalB` arm): its only provenance is NRS 484B.630(1), the turnout line | the four places; `drv_forced_halt`, `drv_following` and `drv_standing_or_parked` also look at vehicles ahead but are supported by training lines |
| `Core/Ontology/Ids.lean` (full) | `derivedIds` lists `drv.queue_behind`; the training `Ids.lean` already omits it, so the Lean test `derivedIds ↔ Derived.derivedNames` would fail against the unsplit `Derived.lean` | nothing in Ids; the mismatch is the previous row |
| `Core/Atoms.lean`, `Core/Ontology/*` | split (see `SPLIT.md`) | — |
| `Core/{Tri,Units,Time,Unknown,Formula,Assumptions,Params,Rule,Grounding,Monitor,Builders}.lean` | nothing: no reference to a test-only atom, value, field or concept | — |
| `Tests/*.lean`, `Main.lean`, `TrafficSpecWitness.lean` | nothing | — |

## What is NOT flagged, and why

- `ru.child`, `dev.zone_sign` kinds `school` / `school_crossing`, the school-zone hours machinery
  (`CivilTime`, `TimeWindow`, `Conditions`, `drv.condition_in_effect`): the school-zone lines
  NRS 484B.363 stay in training (they are referenced by training lines), so these are training
  knowledge even though the school bus moved.
- `sig.hazard`, `sig.brake_lamp`: no test line and no training line names them; they are
  equipment every source can observe and stay in the training ontology as design, not as evidence.
- `dev.regulatory_sign` code `keep_right`: the rotary-island line (test) says "to the right of
  such island", but the divided-highway lines (training) carry the same sign; kept.
- `env.darkness`, `env.civil_time`: fixed clock windows in LVMC 11.48.050 and 11.52.300 (training)
  support them; the sunset/sunrise lines in `lamps_and_warnings` are training too.

## If the training Core is to be strictly training-only

Removing the flagged fields changes `World.lean`, which every other file imports, so it is a
Core change that drags `Decode`, `Manifest`, `Semantics` and the tests along (CLAUDE.md working
agreement, step 3). The alternative that keeps one Core for both splits: leave the fields in
`World` as "observable but unnamed by any training atom" — the training `Atoms.lean` has no
accessor for them, so no training rule can read them, and the manifest marks them absent.
Which of the two the evaluation wants is the operator's decision; nothing was changed.
