# Plan — batch 16 (NRS 484B.287(1)(d)–(e), NRS 484B.283(1)(a), (b), (d)(1)–(4))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the one manoeuvre-like notion (moving across or along a carrier) reuses `drv.motion.moving_across_carrier`, which an earlier batch proposed. No gaps. All ten nodes pass the validator.

## Shared decisions

**Which pedestrian signal a pedestrian obeys.** Subsections 283(1)(d)(1)–(4) apply to "pedestrians facing the signal", the pedestrian proceeding "in the direction of the signal", and "such signals". The ontology has no relation between a pedestrian head and the crosswalk it controls, and no atom for the direction a head's face points. I read "the signal" as a `dev.pedestrian_signal` head that meets two conditions:
- **It governs the roadway or lane being crossed** (`dev.governs`). Its contract covers "the travel regions whose traffic the device controls", and traffic includes pedestrians (DEF-NRS-484A-285). This separates two heads on one corner pole that control perpendicular crossings.
- **The pedestrian faces it.** Its `dev.position` lies ahead of the pedestrian's `kin.position` along `kin.heading`, within a cone (`p.ped_signal_facing_cos`) and a reach (`p.ped_signal_facing_reach`). This excludes heads at the far end of the same roadway segment.

The coder writes "facing" in the node formula with squared comparisons, because a concept cannot take a device formal.
- *Reversal signal:* if the sources do not record `dev.governs` for pedestrian heads, or record it on the intersection only, these nodes report unknown. A gap for a `dev.controls_crossing` relation (pedestrian head → crosswalk) would then be the right fix.

**"Cross the highway" / "entered the highway".** The highway (DEF-NRS-484A-095) includes the sidewalk. However, the law's own words in (d)(3)–(4) name the curb and sidewalk as the places of safety a crossing pedestrian proceeds to. So I read the crossing as being on the roadway or lane, and "entered the highway" as the step from a sidewalk onto it.
- *Reversal:* a reviewer holding the defined word to its whole extent.

**"Except as otherwise provided in …".** Each named rule is an `exception` composition, using the node ids the library lists:
- `NRS_484B_287_1c`, `_1d`, `_1e`, `LVMC_11_30_060_A`, `_B`
- both nodes of `LVMC_11_30_140_B`
- both nodes of `LVMC_11_46_030`

Mapping of each composed rule's subject:
- **Pedestrian rules in the vehicle-subject nodes (1a, 1d1):** mapped to the quantified pedestrian `p`.
- **School-crossing rule (`LVMC_11_46_030`) in the pedestrian-subject nodes:** mapped to a quantified vehicle `v`.
- **All others:** mapped to `subject`.

**Readings moved out of `narrowings`.** The validator does not accept `reading` narrowings on trigger, condition or exception spans. Those readings are now stated in the element justifications and listed below, so they are still disclosed.

## Nodes

**NRS_484B_287_1d** — "shall not cross an intersection diagonally". The pedestrian occupies an intersection, and its velocity is oblique to every lane entering it. This is `moving_across_carrier` at the across-vs-along tolerance (`p.crossing_motion_cos`) and *not* at the right-angle tolerance (`p.right_angle_crossing_cos`).
- **"Unless authorized by official traffic-control devices":** read as a marked crosswalk under the pedestrian (DEF-NRS-484A-065(2) markings), with `official` disclosed as a status reading. A sign that authorizes diagonal crossing without a marking is not read.
- **Judgement point:** each observation, not a corner-to-corner path.
- **Exception:** composes both `LVMC_11_30_140_B` nodes.
- *Reversal:* a labelled diagonal crossing authorized only by a sign, or a non-right-angle junction that this reading misjudges.

**NRS_484B_287_1e** — "cross only in accordance with the devices pertaining to such crossing movements". The start of an authorized diagonal crossing is the moment the pedestrian enters an intersection while in a marked crosswalk and moving diagonally (same reading as 1d).
- **Obligation:** no faced pedestrian head shows a steady don't-walk, or a flashing don't-walk without countdown.
- **Not read:** conduct after the start of the crossing, and devices other than pedestrian heads (disclosed narrowing on the obligation).
- **Why not compose the (d) subparagraphs:** they except 287(1)(e), so composing them as `compliance` would create a cycle.
- *Reversal:* a scramble recording where the label judges mid-crossing conduct.

**NRS_484B_283_1a** — the driver yields to a pedestrian in a crosswalk when devices are not in place or not in operation.
- **"Devices not in operation":** every vehicular head governing the subject's region is dark or `dev.inoperative`, and every pedestrian head governing the pedestrian's region is dark. I read signal heads only, because signs and markings do not allot the crossing in time; this widens applicability rather than narrowing it.
- **"Half of the highway":** read with the section's own definition. The lanes or one-way roadway under the pedestrian have a designated direction that points with the vehicle's `kin.heading`. While turning, the vehicle's half is the one its heading has turned onto.
- **Opposite half:** the pedestrian counts only when "in danger", operationalized as a predicted closest approach within `p.conflict_horizon` below `p.conflict_centre_clearance`.
- **Yield:** no contact, and, while moving above `p.halt_speed_tolerance`, no such predicted conflict (traffic-conflict technique; reuses the index mapping of "shall yield the right-of-way").
- *Reversal:* a yield label that disagrees with the heading-based half on a turning vehicle.

**NRS_484B_283_1b** — "shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle which is so close that it is impossible for the driver to yield". This is now one obligation span, as the validator requires.
- **Event:** the pedestrian's footprint comes onto a roadway from a sidewalk, safety zone or median ("other place of safety" is read only through those three; disclosed).
- **"Suddenly":** read through the vehicle's closeness at that moment (disclosed).
- **"Impossible to yield":** a stopping-distance model. The time to closest approach is below the reaction time plus speed ÷ (2 × deceleration), written as a product. Deceleration is chosen by surface: ice, else wet, else dry.
- *Reversal:* a label that judges the pedestrian's own abruptness rather than the vehicle's closeness.

**NRS_484B_283_1d1** — drivers must give the right-of-way to pedestrians facing a walk head that governs the roadway they are on.
- **"Proceed across the highway in the direction of the signal":** read as the pedestrian on the governed roadway facing the head, whether at rest or moving.
- **Right-of-way:** the danger-of-crash standard (DEF-NRS-484A-210), operationalized as in 1a.
- *Reversal:* see the shared signal decision.

**NRS_484B_283_1d2** — a pedestrian who enters during a flashing don't-walk with countdown must complete the crossing before the countdown reaches zero.
- **When it is judged:** at the head's change from flashing-with-countdown to steady. The timer's displayed number is not an atom; the change ends the interval the timer counts (disclosed).
- **Who it applies to:** pedestrians whose latest entry onto the roadway was made, facing the head, during that same countdown interval.
- **Obligation:** the footprint has left that roadway.
- **Event-relative history:** the past search ends at the entry. A `history_boundary` scenario covers an entry made before the recording began.
- *Reversal:* a source that carries the countdown's value, which would allow reading zero directly.

**NRS_484B_283_1d3_o1 / _o2** — two obligations in one line. The shared clause about a pedestrian who "entered … lawfully pursuant to subparagraph (1)" is an exception in o1 and the subject condition in o2.
- **Reference handling:** the bracketed reference is a `definition` reference. It borrows (1)'s words: walk illuminated, pedestrian facing the signal, proceeding in its direction.
  - Subparagraph (1)'s rule is a driver duty, so whether it was complied with says nothing about the pedestrian's entry. Composing it would weaken the condition.
  - The referring span is `e1`; the defining text is NRS-484B-283-1d1.
- **o1:** while the faced head flashes without a countdown, a pedestrian who is off the governed roadway does not step onto it. A pedestrian continuing a lawful walk-phase crossing (no sidewalk since that entry) is excepted.
- **o2:** a lawful walk-phase entrant still on the roadway during the flashing interval must be off it when the head turns steady. "Place of safety" is read as anywhere off the governed roadway (disclosed).
- *Reversal:* a label that also requires the pedestrian to reach a sidewalk or safety zone specifically.

**NRS_484B_283_1d4_o1 / _o2** — the same structure as 1d3, under the steady indication. The lawful entry is borrowed from both (1) and (2), so there are two `definition` references.
- **o1:** no stepping onto the governed roadway under a steady don't-walk, unless continuing a lawful crossing.
- **o2:** "as soon as possible" is a standard. It is operationalized as a speed floor while still on the roadway (`p.pedestrian_clearing_speed_min`). The convention is MUTCD 4E.06 clearance walking speeds, with the floor set at about half the slow-pedestrian speed. Direction of travel and the pedestrian's own ability are not read (disclosed).
- *Reversal:* a label that flags a brief pause, or a slow wheelchair user; either would argue for a duration window or a lower floor.

## Parameters

**Reused from the iteration's proposed list** (re-proposed with identical values and conventions):
- `p.halt_speed_tolerance`, `p.crossing_motion_cos`, `p.right_angle_crossing_cos`
- `p.conflict_horizon`, `p.conflict_centre_clearance`
- `p.driver_reaction_time`
- `p.following_decel_dry`, `p.following_decel_wet`, `p.following_decel_ice`

**New:**
- `p.ped_signal_facing_cos` (ratio)
- `p.ped_signal_facing_reach` (m)
- `p.pedestrian_clearing_speed_min` (m/s)

## For the operator

- **Pedestrian heads have no "controls this crossing" relation.** The (d) subparagraphs and 287(1)(e) depend on reading `dev.governs` from a pedestrian head to the roadway or lane it controls, together with a facing cone on `dev.position`. Adapter authors need to know that pedestrian heads are expected to carry `dev.governs` onto the crossed roadway or lane. If sources cannot provide it, a gap for `dev.controls_crossing` (pedestrian head → crosswalk) or a device face-orientation atom is the cleaner fix. Either would decide which indication a pedestrian obeys at a pole carrying two heads.
- **`dev.pedestrian_signal` exposes the countdown only as present or absent.** 283(1)(d)(2) ("before the countdown timer gets to zero") is therefore read at the change to steady. A source that shows a countdown reaching zero before the steady indication (a buffer interval) would be judged late by up to that interval.
- **The new parameter values are provisional and need review:** `p.ped_signal_facing_cos` = 0.87, `p.ped_signal_facing_reach` = 40 m, `p.pedestrian_clearing_speed_min` = 0.5 m/s.
