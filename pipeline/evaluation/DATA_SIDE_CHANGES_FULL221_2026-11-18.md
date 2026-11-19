# Changes requested of the data producer for the next export (2026-11-18)

Readers: the data producer (scene-graph generator and adapter developers), and the operator who
reviews this list before it is sent.

The pipeline's contracts govern: the ontology (`ontology/ATOMS.md`), Core's scene types and decoder,
and the trace format in `pipeline/evaluation/evaluation_scenario/adapter/README.md` (the adapter
guide). Where this list and the guide differ, the guide of the next pipeline release governs, and we
correct this list. Missing data only makes a verdict unknown; it never blocks the pipeline or changes
a rule. Each delivery becomes its own dataset and is never mixed with another.

The list has five parts:
1. new atoms;
2. extensions and changes of existing atoms;
3. declarations: the premises a scene states (provisional until our next full run);
4. other changes;
5. judgment-call recordings.

The status column says how final each item is:
- **In contract**: written into the ontology and adapter guide of the next pipeline release, which
  passed its full test suite (release candidate `60e1e371`). The guide on `main` gains it when that
  release lands.
- **Approved, guide text pending**: decided by the operator; the guide gains the wording before the
  release lands.
- **Approved, format open**: the request is approved; its trace format is fixed with a later Core
  change.
- **Provisional**: the direction is known, but the ids are fixed only after our next full run (part 3).

## 1. New atoms

| Atom / trace field | What the producer writes | Status |
|---|---|---|
| `ru.unladen_mass` → `unladen_mass` (kg) | The vehicle's mass as built and equipped, without load, occupants or a drawn vehicle, from a registration or manufacturer's figure the source records; a combination tracked as one body writes the sum of its units. Never estimated from the bounding box. | In contract |
| `ru.disabled` → `disabled` (bool) | The vehicle cannot move under its own power (broken down, wrecked, out of fuel or charge), as the source records it, for example a scenario that disables an actor. Write `false` only where the source knows the vehicle can move; never derive either value from a halt, hazard lamps or the engine state. Not a class. | In contract |
| `ru.tow_car` (class) | A vehicle built or equipped for towing or roadside assistance, read from its equipment. A tow vehicle in official or contracted service is also `official_vehicle` with `official_kind` `tow`. | In contract |
| `ru.tour_or_shuttle_bus`, `ru.limousine` (classes) | Replace `ru.tour_bus_or_limousine`, which no longer exists. | In contract |
| `ru.trailer`, `ru.vehicle_combination` (classes) | Replace `ru.trailer_or_combination`, which no longer exists. `trailer`: a drawn unit tracked on its own. `vehicle_combination`: a drawing vehicle and what it draws, tracked as one body, listed beside the drawing vehicle's own classes. | In contract |
| `ru.trimobile` (class) | A motor vehicle with handlebars and a saddle seat, designed to travel on three wheels, at least one of them powered, as the source classifies it. A trimobile also lists `motorcycle`. A motorcycle with a sidecar is not a trimobile. | In contract |
| `st.railway_track` (region), `railway_kind` ∈ {`railroad`, `streetcar`} | The outline of a track's outermost rails along its length, on, beside or across the highway, written whether or not a rail vehicle is on it. A level crossing stays its own `railway_crossing` region. | In contract |
| `st.impassable_section` (region) | A stretch of sidewalk, or of the ground beside a roadway where a pedestrian would walk, that a pedestrian cannot traverse (missing, broken, closed or too narrow), with its boundary where recorded. It is not an `obstruction`: no object need be there. A place with no sidewalk mapped is not one. | In contract |
| `dev.governs_sidewalk` → `governs_sidewalk` (region ids) | Only on a `regulatory_sign` whose code is `bicycles_prohibited` or `bicycle_ebike_escooter_prohibited`: the `sidewalk` regions the sign governs, as the source records them (`[]` where it records none). Omit the key where not recorded. | In contract |
| `dev.governs_parking_space` → `governs_parking_space` (region ids) | Only on a `regulatory_sign` whose code is `angle_parking`: the `parking_space` regions the sign governs, written as `governs_sidewalk` is. | In contract |
| Declared facts `fact.*` (`facts` in each scene; `facts` list in the manifest) | Facts the scene's source confirms and no sensor sees: a road user's duty or role at the time, a permit, an assignment, membership of a procession, a consent between two road users, an emergency its conduct answers to, or what the map records state of a region (`map_record`). Each record names its subjects (one or two road users, a road user and a region, or a region alone) and a value. Write true or false only on a record that states or excludes the fact; omit it otherwise. A road user's own displays (lamps, siren, hand signals) never decide a fact. The ids come with the catalogue (part 3). | Format in contract; ids provisional |
| Crosswalk × walking direction → the vehicle signal heads a pedestrian faces | For every crosswalk and walking direction, the vehicle signal heads a pedestrian crossing that way faces, for example from the signal timing plan. A complete list must be distinguishable from an unobserved one: in a complete list an empty list means none. | Approved, format open |

## 2. Extensions and changes of existing atoms

| Atom | Change | Status |
|---|---|---|
| `st.grade`, `st.curvature` | **Moved from structures to road users.** Each road user carries `road_grade` (the longitudinal slope of the roadway at its position, along its heading: positive uphill, ratio) and `road_curvature` (the horizontal curvature at its position, 1/m, either sign). Structures no longer carry `grade` or `curvature`. Write them only where the road user's position and the one road it lies on are determined; otherwise omit them, never pick one, and never copy a whole road's value onto its users. A grade is read as unknown where the road user's heading is unknown. Earlier deliveries are migrated with both atoms unknown. | In contract |
| `st.driveway_or_alley_entrance` | New `entrance_kind` ∈ {`driveway`, `private_road`, `alley`, `property`}, and `private` (bool): the way or property the entrance leads into is private or public, as the map records it. Never derive `private` from `entrance_kind`. | In contract |
| `st.sight_along_way` | Also given along a `railway_track`: the distance in each direction from the level crossing nearest the road user. Write it only where measured. | In contract |
| `dev.regulatory_sign` | New codes `lamps_on` (a sign directing vehicles' lamps to be lit) and `parking_permitted` (a sign permitting parking; write its hours, duration or class in `conditions`); both need `governs`. | In contract |
| `dev.regulatory_sign` | New code `bicycle_ebike_escooter_prohibited`. The existing `bicycles_prohibited` keeps its meaning (bicycles only). | In contract |
| `dev.regulatory_sign` | New `legend_angle` on an `angle_parking` sign: the parking angle in degrees that the legend states, or `"none"` where the source confirms that the legend states no angle. Omit it where the legend is not read. | In contract |
| `st.parking_space` | New `angle_marking` (bool): `true` where the source confirms that the space's markings are an official marking indicating the parking angle, `false` where it confirms they are not, omitted otherwise. New `axis` ([x, y]): the undirected direction of the space's long axis, from the stall lines the source records, never from a parked vehicle or a template. | In contract |
| `st.obstruction` | New kind `sidewalk_elevator_or_chute`. New attribute `protected` for a hose: `true` where a cover or bridge is laid over it, `false` where it lies bare, omitted where not recorded. | In contract |
| `dev.human_direction` | New role `fire_official` (the fire department official in command at a fire). | In contract |
| `ru.official_vehicle` | New kind `postal` (a vehicle in postal service, by its livery). | In contract |
| `ru.emergency_vehicle` | **Changed meaning.** The class states that the vehicle is an authorized emergency vehicle and that the producer has confirmed it carries the warning lamps and siren the jurisdiction requires. It never states that a lamp is in use, that the vehicle is responding to an emergency or that it is on official duty. In data exported before 2026-11-18, the class counts only once you confirm the equipment; until then it is listed in `unobserved_classes`. | In contract |
| `ru.electric_bicycle` | **Changed meaning.** Declared only where the source has classified the road user under the jurisdiction and definition its delivery names (for this corpus, Nevada, NRS 484B.017). The pipeline needs no measurement of power, speed or pedals. | In contract |
| `ru.bus`, `ru.school_bus` | A school bus is labelled `school_bus`. It is labelled `bus` as well only where your vehicle-model mapping, with its source and version, confirms that it also meets the legal definition of a bus; otherwise `bus` is unknown for it. | Approved, guide text pending |
| `ru.occupant_count` → `occupants` | The number of persons in or on the vehicle. A source that sees a person arrive at or leave a vehicle but not the total omits it and declares the atom `absent`. | In contract |
| `ru.rider_posture` → `posture` | The posture fields are independent: write each one the source observes. A source that renders a rider as part of the machine, so that no field can vary, omits `posture` and declares the atom `absent`. | In contract |
| `warning_lamps[].facing` | Format unchanged, but rules now read it. Write each lit lamp's real facing (`front`, `rear`, `side`), never a default. A lamp whose facing the source cannot tell is not observed. | In contract |
| `conditions.duration_limit` (seconds) | Format unchanged, but rules now read it. Write it where the sign shows a time limit; never write 0 for a limit not read. | In contract |
| Boundaries of `st.obstruction` and `st.fire_hydrant` | Rules judge a vehicle's contact with these objects from its footprint and the object's boundary, so the boundary must be reliable. Where it is not, mark the kind not observed. | In contract |

## 3. Declarations: premises a scene states (provisional)

A declaration is a premise no sensor sees, which the scene's source states from its map records or
scenario. The **format** below is in contract. The **ids are provisional**: our next full run
starts with an empty catalogue, its plans propose the ids the laws need, and we review them once
after that run. We then send you the final catalogue. Do not export any `asm.*` or `fact.*` id
before it arrives; prepare the records the kinds below will need.

**Format.**
- An assumption (`asm.*`) holds for the whole scene: it has no road-user or region argument, and
  every road user a rule judges in the scene reads the same value.
- The area a scene covers is the union of the regions in that scene's `structures`. Write an area
  premise `true` or `false` only where your map records or scenario establish it for that whole
  area. Omit it where it is unknown, and omit it at a scene where any part of the area is
  classified differently.
- School premises concern the school served by the zones the scene's school zone signs
  (`dev.zone_sign` of kind `school`) designate. Omit them at a scene whose signs designate zones of
  different schools.
- Never write an unknown premise as false.
- A declared intention (`int.*`) is per road user and target region: write it for every planned
  manoeuvre the catalogue names.
- A declared fact (`fact.*`) follows part 1.

**Expected range.** The last full run's plans proposed, and the operator reviewed, the
premises below. They show the kinds of records to prepare. The next run may name them differently,
split or merge them, or add others.

| Kind of premise | Ids reviewed after the last run | Records you would need |
|---|---|---|
| District of the area | `asm.in_business_district`, `asm.in_residence_district`, `asm.in_business_or_residence_district` (the area is one of the two, without saying which; if either district is true, so is this one) | the map's land-use or zoning classification of the area, under the jurisdiction's general definitions |
| Municipal limits | `asm.in_city_of_las_vegas`, `asm.in_city` (an incorporated city), `asm.in_city_or_town` (an incorporated city or a town) | the municipal boundaries of the area |
| Kind of premises | `asm.public_access_premises` (premises to which the public has access) | the map's record of the premises' access |
| School schedule | `asm.school_in_session_day`, `asm.school_outside_operation_margin` (from a half hour after the school ceased operation to a half hour before it next begins), `asm.pupils_in_class` | the calendar and timetable of the school the zones serve, with the scene's date and time |
| Planned turns | `int.left_turn`, `int.right_turn` (the source's current plan for the road user includes a turn to that side at the target region, its preparation included) | the scenario's or controller's route plan per road user |
| Map records about a region | a named street segment, such as "a sidewalk on Fremont Street between Main Street and Seventh Street" (a `fact.*` of kind `map_record`) | the map's street-segment records, with provenance |
| Facts about road users | duty, permit, assignment, procession membership, consent, emergency (`fact.*`) | the scenario's or dispatch records |

Ids used in earlier deliveries are not carried over. They described the judged vehicle's own
location, while an assumption now describes the whole area a scene covers: each value is decided
again under the final catalogue, and never copied across. `asm.public_highway`, `asm.synthetic_*`
and `asm.public_authority_posting` are not used.

## 4. Other changes

1. **Export under the new ontology.** Use the class names of part 1 and list every atom id of the
   current ontology (140) in the manifest. Our compatibility overlays for earlier deliveries only
   rename classes and read the grade and curvature as unknown; they add no observation capability.
2. **Class completeness.** A class the blueprint decides a road user does not belong to is known
   false (declared `exact`), never listed in `unobserved_classes`. List a class in
   `unobserved_classes` only where the source cannot tell. The pipeline trusts the producer's class
   list and does not check its basis; the risk of a misclassification lies with the data side.
3. **Jurisdiction in the manifest.** The manifest names the jurisdiction and definitions the
   classification follows (needed for `ru.electric_bicycle`).
4. **Split version.** Write `demo-overlap-v5` in `scope.json` (the training split of 224 laws). We
   confirm the version again before each export.
5. **Acceptance evidence with the delivery.**
   - A device with its governed lanes listed, each lane carrying `enters_intersection`, and one
     whose governance is unknown; the resulting three-valued `dev.governs` queries.
   - A track crossing each estimated line strip and a nearby track that does not; every positive
     `occupies` pair and the complete structure inventory before `occupancy_observed` is asserted.
   - A verdict-bearing judgment-call recording, a separate scenario-sweep member and a truly
     unresolved recording, run through the dataset builder with their derived reports compared.

## 5. Judgment-call recordings (added 2026-11-19)

**How we label a judgment call.** A recording labelled `judgment call` keeps that label and its
`legal_judgment.references` as delivered today. We give it a provisional label from your measured
values alone: each value, widened by its error, is compared with a threshold from our frozen
parameter set, under the model our generated rule declares for the law. We do not read the trace to
label it, and we do not recompute your values. A recording is labelled violated or compliant only
when the comparison holds across the whole error range; otherwise it stays undetermined. Our
thresholds and models change between our runs, and our tooling re-labels for each run.

**What we do not need.** Do not decide judgment calls, choose thresholds or compute verdicts. Do not
shape a scene to one of our rules or parameter values.

**What we need for every judgment-call recording.** In its metadata, a list
`judgment_measurements`. It holds one entry for every quantity the unresolved phrase turns on,
measured on that recording. Each entry has:

| Field | Content |
|---|---|
| `quantity` | the atom id of our ontology that the quantity is; a descriptive name only where no atom fits |
| `value`, `unit` | the measured number and its unit |
| `error` | `kind`: a hard bound, an interval at a stated `confidence`, or a standard deviation; and its `value` in the same unit. Unknown is stated as unknown, never as 0 |
| `statistic`, `window` | the worst case over the interval in which the law applies: the minimum or the maximum, whichever is least favourable to compliance, and the start and end of that interval. A mean or another summary is not usable |
| `phrase` | the `legal_judgment` phrase the quantity bears on |
| `source` | `trace` when the value is computed from the delivered trace only; otherwise `other`, naming the source |

Rules for the list:
1. **Cover every quantity of the phrase.** Include every quantity a reasonable reading of the
   phrase depends on: the road user's own conduct and every condition of the scene that bears on
   it. For each law we send, per run, the list of quantities our current rules read (atom ids and
   units, never values); include at least those. A quantity that is missing, or that has no error,
   leaves the recording undetermined.
2. **One recording, one set of values.** The values describe the delivered recording, not the
   requested set point. A sweep's requested setting is not a measurement.
3. **Shared errors.** State in the entry when its error is shared with another entry (a common
   localization or map error). We do not assume independent errors, and we do not assume they
   cancel.
4. **Geometry is not error.** A physical size is a quantity of its own, never the error of a
   position.
5. **Sweep design.** Vary one variable per sweep, over a range wide enough that any reasonable
   threshold lies inside it. We do not send our parameter values.
6. **Coverage.** We label a judgment-call recording only for a law our generated rules cover. Keep
   delivering the others: they stay unlabelled until a run covers the law.
7. **Plain labels are still needed.** Provisional labels are counted apart and never replace plain
   labels; the request in part 4, item 5, stands.
