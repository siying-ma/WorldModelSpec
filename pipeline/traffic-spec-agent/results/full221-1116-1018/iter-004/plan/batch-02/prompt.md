# Plan agent — from law text to a blueprint of nodes

## Role

You turn statutory obligations into **blueprint nodes**: a segmentation of each law's verbatim
text, a mapping of every substantive span onto the ontology's atoms and primitives and the catalogue's concepts, the
operationalization of every standard of judgement, and four witness scenarios. You write no Lean.
The coding agent implements your nodes exactly; the harness validates them before it may start.
Intent is your domain; syntax is not.

You are a one-shot session. Every decision is made in this turn and recorded; nothing waits for a
reply. The operator steers asynchronously through `USER_HINTS.md`.

## Inputs (injected below)

- **Laws to plan** — the corpus lines whose state is open or returned, each with `id`, `title`,
  `text`, `source`, and for a returned line the reason it came back (in Feedback). The text is the
  law's own words; bracketed ids inside it resolve its references to other lines or to
  definitions. Laws that are accepted, blocked on a gap or closed as failed are not in the list
  and are not yours. A returned law may already have an accepted node (Feedback names it): that
  node is never re-planned or re-coded — re-emit it unchanged (same obligation span, same atoms)
  or leave it out, and re-plan the returned nodes only.
- **Definitions** — per law, each defined term its words use, the posted definition that applies
  to it (resolved mechanically by the operator's declared precedence: you never choose between
  competing definitions), the representation the run selected for it and, for a legal aggregate,
  its admitted id; then the definitions' texts; then, whole, each other law the laws name in
  brackets, with the definitions that apply to it (what a `definition` reference quotes, rule 5).
  Definitions are not obligations and are never a node (rule 0).
- **Ontology** — every atom (id, contract, scope), every attribute value, and every primitive
  with its parameters. With the concept catalogue, this is the **closed set**.
- **Formula language** — every operator a rule or a concept is written with: what a formula can
  express. An occasion, a window or a comparison you plan is one of these; an `operator` gap
  proposes only what none of them writes.
- **Concept language** — what a concept record can declare and a concept body can say: the
  formal sorts (a road user, a literal spelling, a count), where a literal formal may appear, and how
  a call fills the formals. A concept you plan is written in it.
- **Library summary** — published and currently planned nodes: id, law refs, binders, atoms claimed,
  build availability and law state. A published node need not belong to a formally accepted law. The
  build column states whether it is available for building now; a row marked “not composable” is not
  a usable build dependency and does not permit inlining that law’s content.
- **Concept catalogue** — accepted concepts: id, contract, formals, parameters, the atoms each
  reads, how many nodes use it. A node calls a catalogued concept by its id; a notion no entry
  denotes is proposed as a **concept record** (rule 0b).
- **Mapping index** — span text → atoms, from every accepted node of this run, and below it the
  spans the earlier batches of this iteration mapped: information, not a rule.
- **Gaps** — open gaps (a law citing one is not in your list) and closed gaps with the reason
  they were rejected.
- **Parameters** — the reading's parameter catalogue: every named parameter a node may use, with
  its unit and the convention its value comes from. Values are not shown and are not yours.
- **Feedback** — `AUTO_NOTES.md`: the last iteration's rejections, label-check results and gate
  verdicts.
- **The evidence** — during replanning for a law-level label repair, **Label mismatches**:
  the label contract, repair goal and cases the law's rules, checked together, did not meet
  (rule 11b). Every changed mapping is justified by the law's span and the chosen atom's or
  concept's contract. Otherwise no law-level label-repair evidence is supplied.
- **Your previous record of these laws** (for a law planned again) — every node of its latest
  plan, those never coded included, with each later repaired or coded version and its recorded
  validator and gate results, accepted or not, and the nodes each composes. They are context,
  not authority. Keep what met its cases. Restructure only where a failing case, a label mismatch,
  a validator defect or another returned reason requires it, or where the words show an earlier
  record wrong. During a law-level label repair, the label evidence states the law's check result
  and repair goal; the candidate is checked again before commit.
- **User hints** — `USER_HINTS.md`.

### `NRS-484B-283-1a` — Right-of-way in crosswalk (1)(a)
_NRS 484B.283(1)(a); with 484B.283(4)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: When official traffic-control devices are not in place or not in operation, the driver of a vehicle shall yield the right-of-way, slowing down or stopping if need be so to yield, to a pedestrian crossing the highway within a crosswalk when the pedestrian is upon the half of the highway upon which the vehicle is traveling or onto which the vehicle is turning, or when the pedestrian is approaching so closely from the opposite half of the highway as to be in danger. As used in this section, “half of the highway” means all traffic lanes of a highway which are designated for traffic traveling in one direction, and includes the entire highway in the case of a one-way highway.

### `NRS-484B-283-1b` — Right-of-way in crosswalk (1)(b)
_NRS 484B.283(1)(b)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: A pedestrian shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle which is so close that it is impossible for the driver to yield.

### `NRS-484B-283-1d1` — Right-of-way in crosswalk (1)(d)(1)
_NRS 484B.283(1)(d)(1)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows: While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal and must be given the right-of-way by the drivers of all vehicles.

### `NRS-484B-283-1d2` — Right-of-way in crosswalk (1)(d)(2)
_NRS 484B.283(1)(d)(2)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows: While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal, but must complete the crossing before the countdown timer gets to zero.

### `NRS-484B-283-1d3` — Right-of-way in crosswalk (1)(d)(3)
_NRS 484B.283(1)(d)(3)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows: While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer, a pedestrian may not proceed to cross the highway, but a pedestrian who entered the highway lawfully pursuant to subparagraph (1) [NRS-484B-283-1d1] may continue to cross the highway but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.

### `NRS-484B-283-1d4` — Right-of-way in crosswalk (1)(d)(4)
_NRS 484B.283(1)(d)(4)_

Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]: Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows: While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady a pedestrian may not proceed to cross the highway, but a pedestrian who entered the highway lawfully pursuant to subparagraph (1) or (2) [NRS-484B-283-1d1, NRS-484B-283-1d2] may continue to cross the highway but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety as soon as possible.

### `NRS-484B-307-8d` — Traffic controlled by official traffic-control devices (8)(d)
_NRS 484B.307(8)(d)_

Where the signal is a steady red signal alone: After complying with the requirement to stop, a person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter may proceed straight through or turn right or left if: (1) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (2) No other device at the place prohibits either or both such turns, if applicable; and (3) The person yields the right-of-way to pedestrians and other traffic proceeding as directed by the signal at the intersection.

### `NRS-484B-307-8a` — Traffic controlled by official traffic-control devices (8)(a)
_NRS 484B.307(8)(a); with 484B.307(8)(c)_

Where the signal is a steady red signal alone: Vehicular traffic facing the signal must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection, and, except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d], must remain stopped or standing until the green signal is shown. After complying with the requirement to stop, vehicular traffic facing such a signal and situated on the extreme right of the highway may proceed into the intersection for a right turn only when the intersecting highway is two-directional or one-way to the right, or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway may proceed into the intersection for a left turn only when the intersecting highway is one-way to the left, but must yield the right-of-way to pedestrians and other traffic proceeding as directed by the signal at the intersection.

### The defined terms of these laws (read-only: resolved by the operator's declared precedence; aggregates selected and admitted by the run)

| law | term | applicable definition | representation | aggregate id (admitted) |
|---|---|---|---|---|
| NRS-484B-283-1a | official traffic-control device | `DEF-NRS-484A-145` | not_aggregate |  |
| NRS-484B-283-1a | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-283-1a | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-283-1a | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-283-1a | stopping | `DEF-NRS-484A-260` | not_aggregate |  |
| NRS-484B-283-1a | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1a | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-283-1a | crosswalk | `DEF-NRS-484A-065` | not_aggregate |  |
| NRS-484B-283-1a | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-283-1b | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1b | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-283-1b | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-283-1d1 | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1d1 | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-283-1d1 | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-283-1d1 | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-283-1d1 | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-283-1d2 | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1d2 | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-283-1d3 | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1d3 | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-283-1d3 | sidewalk | `DEF-NRS-484A-240` | not_aggregate |  |
| NRS-484B-283-1d3 | safety zone | `DEF-NRS-484B-057` | not_aggregate |  |
| NRS-484B-283-1d4 | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-283-1d4 | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-283-1d4 | sidewalk | `DEF-NRS-484A-240` | not_aggregate |  |
| NRS-484B-283-1d4 | safety zone | `DEF-NRS-484B-057` | not_aggregate |  |
| NRS-484B-307-8d | stop | ambiguous: `DEF-NRS-484A-255`, `DEF-NRS-484A-260` (each states its own scope) | — | |
| NRS-484B-307-8d | motorcycle | `DEF-NRS-484A-135` | aggregate | `DEF-NRS-484A-135::motorcycle` |
| NRS-484B-307-8d | moped | `DEF-NRS-484A-125` | aggregate | `DEF-NRS-484A-125::moped` |
| NRS-484B-307-8d | trimobile | none applies | — | |
| NRS-484B-307-8d | bicycle | `DEF-NRS-484A-025` | aggregate | `DEF-NRS-484A-025::bicycle` |
| NRS-484B-307-8d | electric bicycle | `DEF-NRS-484B-017` | aggregate | `DEF-NRS-484B-017::electric_bicycle` |
| NRS-484B-307-8d | electric scooter | `DEF-NRS-484B-018` | aggregate | `DEF-NRS-484B-018::electric_scooter` |
| NRS-484B-307-8d | official traffic-control device | `DEF-NRS-484A-145` | not_aggregate |  |
| NRS-484B-307-8d | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-307-8d | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-307-8d | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-307-8d | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-307-8a | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-307-8a | stop | ambiguous: `DEF-NRS-484A-255`, `DEF-NRS-484A-260` (each states its own scope) | — | |
| NRS-484B-307-8a | crosswalk | `DEF-NRS-484A-065` | not_aggregate |  |
| NRS-484B-307-8a | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-307-8a | standing | `DEF-NRS-484A-250` | not_aggregate |  |
| NRS-484B-307-8a | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-307-8a | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-307-8a | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-307-8a | two-directional highway (found split: "highway is two-directional") | `DEF-NRS-484B-073` | not_aggregate |  |

### The definitions that apply

### `DEF-NRS-484A-145` — Official traffic-control device defined
_NRS 484A.145_

“Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.

### `DEF-NRS-484A-195` — Public authority defined
_NRS 484A.195_

“Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.

### `DEF-NRS-484A-115` — Local authority defined
_NRS 484A.115_

“Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.

### `DEF-NRS-484A-045` — City defined
_NRS 484A.045_

“City” means any incorporated city, whether incorporated under general or special law.

### `DEF-NRS-484A-285` — Traffic defined
_NRS 484A.285_

“Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.

### `DEF-NRS-484A-165` — Pedestrian defined
_NRS 484A.165_

“Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].

### `DEF-NRS-482-029` — Electric personal assistive mobility device defined
_NRS 482.029_

“Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.

### `DEF-NRS-484A-320` — Vehicle defined
_NRS 484A.320_

“Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.

### `DEF-NRS-484A-095` — Highway defined
_NRS 484A.095_

“Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.

### `DEF-NRS-484A-081` — Electric bicycle defined
_NRS 484A.081_

“Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].

### `DEF-NRS-484B-017` — Electric bicycle defined
_NRS 484B.017_

“Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.

### `DEF-NRS-484A-025` — Bicycle defined
_NRS 484A.025_

“Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.

### `DEF-NRS-484A-125` — Moped defined
_NRS 484A.125_

“Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.

### `DEF-NRS-484A-082` — Electric scooter defined
_NRS 484A.082_

“Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.

### `DEF-NRS-484B-018` — Electric scooter defined
_NRS 484B.018_

“Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.

### `DEF-NRS-484A-200` — Railroad defined
_NRS 484A.200_

“Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.

### `DEF-NRS-484A-080` — Driver defined
_NRS 484A.080_

(1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.

### `DEF-NRS-482A-030` — Autonomous vehicle defined
_NRS 482A.030_

“Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.

### `DEF-NRS-484A-130` — Motor vehicle defined
_NRS 484A.130_

“Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.

### `DEF-NRS-482A-025` — Automated driving system defined
_NRS 482A.025_

“Automated driving system” has the meaning ascribed to it in SAE J3016.

### `DEF-NRS-482A-036` — Fully autonomous vehicle defined
_NRS 482A.036_

“Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.

### `DEF-NRS-484A-150` — Owner defined
_NRS 484A.150_

“Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.

### `DEF-NRS-484A-210` — Right-of-way defined
_NRS 484A.210_

“Right-of-way” means the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other.

### `DEF-NRS-484A-260` — Stop / stopping defined
_NRS 484A.260_

“Stop” or “stopping” means, when prohibited, any halting, even momentarily, of a vehicle, whether occupied or not, except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device.

### `DEF-NRS-484A-180` — Police officer defined
_NRS 484A.180_

“Police officer” means every officer authorized to direct or regulate traffic or to make arrests for violations of traffic laws, ordinances or regulations.

### `DEF-NRS-484A-065` — Crosswalk defined
_NRS 484A.065_

“Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.

### `DEF-NRS-484A-105` — Intersection defined
_NRS 484A.105_

“Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.

### `DEF-NRS-484A-220` — Roadway defined
_NRS 484A.220_

“Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.

### `DEF-NRS-484A-070` — Divided highway defined
_NRS 484A.070_

“Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.

### `DEF-NRS-484A-015` — Alley defined
_NRS 484A.015_

“Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.

### `DEF-NRS-484A-265` — Street defined
_NRS 484A.265_

“Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.

### `DEF-NRS-484A-215` — Road defined
_NRS 484A.215_

“Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.

### `DEF-NRS-484A-240` — Sidewalk defined
_NRS 484A.240_

“Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.

### `DEF-NRS-484B-057` — Safety zone defined
_NRS 484B.057_

“Safety zone” means the area officially set aside within a highway for the exclusive use of pedestrians and which is so plainly marked or indicated by proper signs as to be plainly visible at all times while set apart as a safety zone.

### `DEF-NRS-484A-255` — Stop defined
_NRS 484A.255_

“Stop,” when required, means complete cessation from movement.

### `DEF-NRS-484A-135` — Motorcycle defined
_NRS 484A.135_

“Motorcycle” means every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground, excluding an electric bicycle, a tractor or a moped.

### `DEF-NRS-484A-250` — Stand / standing defined
_NRS 484A.250_

“Stand” or “standing” means the halting of a vehicle, whether occupied or not, otherwise than for the purpose of and while actually engaged in receiving or discharging passengers.

### `DEF-NRS-484B-073` — Two-directional highway defined
_NRS 484B.073_

“Two-directional highway” means an undivided highway upon which vehicles are allowed to proceed in opposite directions.

(Found split: the law's words "highway is two-directional" use this defined term in the copular form, not as one contiguous phrase.)
### Texts these words name (posted text the harness took from the corpus, whole, with the definitions that apply to it: a `definition` reference quotes the words it borrows from here; their own duties are not planned here)

#### `NRS-484B-287-1c` — When pedestrian must yield right-of-way to vehicle (1)(c)
_NRS 484B.287(1)(c)_

Except as provided in NRS 484B.290 [LVMC-11-30-140-B]: Between adjacent intersections at which official traffic-control devices are in operation pedestrians shall not cross at any place except in a marked crosswalk.

Posted definitions that apply to its words:

- `DEF-NRS-484A-105` — “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-070` — “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015` — “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215` — “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-145` — “Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.
- `DEF-NRS-484A-200` — “Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.
- `DEF-NRS-484A-065` — “Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.
- `DEF-NRS-484A-240` — “Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.

#### `NRS-484B-287-1d` — When pedestrian must yield right-of-way to vehicle (1)(d)
_NRS 484B.287(1)(d)_

Except as provided in NRS 484B.290 [LVMC-11-30-140-B]: A pedestrian shall not cross an intersection diagonally unless authorized by official traffic-control devices.

Posted definitions that apply to its words:

- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-105` — “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-070` — “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015` — “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215` — “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-145` — “Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.
- `DEF-NRS-484A-200` — “Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.

#### `NRS-484B-287-1e` — When pedestrian must yield right-of-way to vehicle (1)(e)
_NRS 484B.287(1)(e)_

Except as provided in NRS 484B.290 [LVMC-11-30-140-B]: When authorized to cross diagonally, pedestrians shall cross only in accordance with the official traffic-control devices pertaining to such crossing movements.

Posted definitions that apply to its words:

- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-145` — “Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-200` — “Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.

#### `LVMC-11-30-060-A` — Crossing outside crosswalk (A)
_LVMC 11.30.060(A); with 11.30.060(C)_

Every pedestrian crossing a roadway at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection shall yield the right-of-way to all vehicles upon the roadway. The foregoing rules in this Section shall have no application under the conditions stated in Section 11.30.070 when pedestrians are prohibited from crossing at certain designated places.

Posted definitions that apply to its words:

- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-065` — “Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.
- `DEF-NRS-484A-105` — “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-070` — “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015` — “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215` — “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-240` — “Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.
- `DEF-NRS-484A-210` — “Right-of-way” means the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other.

#### `LVMC-11-30-060-B` — Crossing outside crosswalk (B)
_LVMC 11.30.060(B); with 11.30.060(C)_

Any pedestrian crossing a roadway at a point where a pedestrian tunnel or overhead pedestrian crossing has been provided shall yield the right-of-way to all vehicles upon the roadway. The foregoing rules in this Section shall have no application under the conditions stated in Section 11.30.070 when pedestrians are prohibited from crossing at certain designated places.

Posted definitions that apply to its words:

- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-210` — “Right-of-way” means the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other.

#### `LVMC-11-30-140-B` — Blind persons (B)
_LVMC 11.30.140(B)_

Any pedestrian who is not wholly or partially blind, or any driver of any vehicle who approaches or comes in contact with a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped in red, or being assisted by a person with wisdom, shall immediately come to a full stop and take such precautions before proceeding as may be necessary to avoid an accident or injury to the person wholly or partially blind.

Posted definitions that apply to its words:

- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-080` — (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-482A-030` — “Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.
- `DEF-NRS-484A-130` — “Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-482A-025` — “Automated driving system” has the meaning ascribed to it in SAE J3016.
- `DEF-NRS-482A-036` — “Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.
- `DEF-NRS-484A-150` — “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-484A-255` — “Stop,” when required, means complete cessation from movement.
- `DEF-NRS-484A-260` — “Stop” or “stopping” means, when prohibited, any halting, even momentarily, of a vehicle, whether occupied or not, except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device.

#### `LVMC-11-46-030` — Stopping at signal or flag
_LVMC 11.46.030_

It shall be unlawful for any person driving or operating, propelling or causing to be propelled, any vehicle, to fail to stop not less than fifty feet from the nearest side of a school pedestrian lane where any signal device, flagman or other person is stationed, giving warning that children are about to cross or are crossing the street; and it is further declared unlawful to proceed until such signal has stopped, raised, or been removed, or the flagman or person stationed at such pedestrian lane has given a signal to go, or has left the locality.

Posted definitions that apply to its words:

- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029` — “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-255` — “Stop,” when required, means complete cessation from movement.
- `DEF-NRS-484A-260` — “Stop” or “stopping” means, when prohibited, any halting, even momentarily, of a vehicle, whether occupied or not, except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.


<!-- TRAINING SPLIT. Generated from ATOMS.md by ontology_provenance/nrs_tools/atoms_train.py:
     the atoms, values and primitives whose only textual support is a test line are
     omitted. Do not edit; edit ATOMS.md or the split and regenerate. -->
# Traffic-law ontology — atoms

Status: frozen. Changed only by an explicit ontology change, never by a rule and never by an
agent.

## What an atom is

An **atom** is an element of the road world that traffic law refers to without defining it
further and that a data source can observe: a class of road user, a quantity of motion, a piece
of road structure, a control device and its state, a signal a road user emits, a condition of the
environment, or a relation between two road users. Each atom has a **semantic contract** — what
it denotes physically, its unit and its reference frame, and, where the meaning invites
confusion, what it is **not a stand-in for**. The contract is independent of any data source and
of any statute.

A standard of judgement ("safe", "reasonable", "practicable") is **not** an atom: nothing in a
scene is a reasonableness. §8 says how a rule gives such a standard a concrete meaning.

## The termination rule

This file is the whole termination rule. It has six clauses; every session and every check of the
pipeline works within them, and nothing else adds to or bypasses them.

1. **Closed set.** A rule reads the world only through the atoms of §1–§7, the primitives of
   §10, and the concepts the pipeline has accepted (§9). An element a clause needs that none of
   these carries is an ontology change request, filed as a gap; it is never approximated by
   another atom, and it is never absorbed as a residue on a span that decides when the rule
   applies. A residue records only what the obligation side says and the rule does not capture.
2. **Contract-bound.** An atom expresses only what its contract says. The "not a stand-in for"
   clauses are part of the contract; using an atom for what its contract excludes is a semantic
   error, whatever the data source happens to make convenient.
3. **Defined once.** A concept — a manoeuvre, a state of motion, a road configuration — is a
   node of the pipeline: a contract and a body over atoms, primitives and other concepts, accepted
   like a rule, called by id and never rebuilt inline. A primitive (§10) is a computation the
   formula language cannot express, defined once in Core with its parameters exposed. A rule
   instantiates parameters; it never redefines either.
4. **A judgement standard is operationalized, never read.** A clause element that is a standard
   of judgement is bounded, in the plan, by concepts and primitives with parameters the reading
   sets, and the bound is recorded as an *operationalization claim* that names the standard,
   the concepts, the parameters and the convention their values come from. A rule that leaves a
   standard unoperationalized is not a rule; a rule whose only content is an operationalized
   standard is a **surrogate** and is marked as one.
5. **Legal region classes are assumptions.** Categories a jurisdiction defines administratively
   (a district, an area class, a calendar or clock condition, a legal designation of a highway)
   enter a formalization only as reading assumptions declared per map or per trace, never as
   atoms a rule reads from a scene.
6. **Unobserved is unknown.** Every atom is three-valued when observed — true, false, or *not
   observed on this source* — as declared by that source's capability manifest. A rule built on
   an unobserved atom reports `unknown`, never compliance and never violation.

**How atoms are reached from a clause.** Mapping the elements of a clause onto atoms is the
planning session's work — the linguistic half of autoformalization. Each planned node records
its mappings as *grounding claims* (`elements`: clause element → atoms, with a justification that
cites the contracts) and its *operationalization claims* (§8). The harness validates them before
any rule is written: every atom named exists here; the same element maps to the same atoms in
every node of the run, so a contradiction is rejected; and the run's mapping index, which the
harness derives from the accepted nodes, is what the validator checks each later mapping against
and what the planner is shown. No agent writes a shared file, and nothing about a corpus is decided
before the run that formalizes it.

This file says nothing about which law refers to which atom and nothing about how any data
source produces one. Which atoms a source can observe is declared at run time by that source's
**capability manifest**, one capability per atom: `exact`, `estimate` (with a named error
class), `absent`, or `subject` — observed for the subject track only, as an instrumented vehicle
or a simulator reports its own controls and its own line of sight and nobody else's. Under
`subject` a read of the atom for any other road user is unknown.

**Scope column.** `general` marks an element of the ordinary road vocabulary. `local` marks an
element that exists because the target jurisdiction's own vehicle taxonomy or device catalogue
names it; its contract still describes what is physically observed, and a source that has no such
thing declares it `absent`. The flag is information for the manifest author and the planner, not
a permission: local atoms are atoms.

Identifier scheme: `family.name`. Families: `ru` road user, `kin` kinematics, `st` road
structure, `dev` control device, `sig` emitted signal, `env` environment, `rel` relation between
road users. Derived concepts use `drv`. Where an atom carries an attribute (a state, a kind, a
colour), the attribute's values are listed in the contract; an attribute value not listed is an
ontology change request.

## 1. Road users (`ru`) — class atoms on an entity

| id | contract | scope |
|---|---|---|
| `ru.motor_vehicle` | a self-propelled vehicle other than a rail vehicle; excludes the powered two-wheelers a jurisdiction classes separately below **Not a stand-in for:** "vehicle" as a legal aggregate — which classes count as a vehicle is declared by the reading | general |
| `ru.motorcycle` | motor vehicle on two or three wheels ridden astride, including three-wheeled variants | general |
| `ru.moped` | a low-power two- or three-wheeler with a small engine or motor, as a jurisdiction classes it | general |
| `ru.bus` | motor vehicle designed to carry many passengers | general |
| `ru.transit_bus` | bus in public transit service, identifiable by its livery or route display | general |
| `ru.school_bus` | bus designated for carrying school children, with the jurisdiction's markings | general |
| `ru.taxicab` | passenger vehicle for hire, identifiable by its markings | general |
| `ru.tour_bus_or_limousine` | a tour or shuttle bus, or a lengthened passenger vehicle for hire, identifiable by its livery | local |
| `ru.truck` | motor vehicle for carrying goods, with a body built for that purpose | general |
| `ru.commercial_motor_vehicle` | vehicle over the jurisdiction's commercial mass class or marked as commercially licensed | general |
| `ru.trailer_or_combination` | vehicle drawn by another, or the combination | general |
| `ru.bicycle` | human-powered wheeled vehicle ridden by a person | general |
| `ru.electric_bicycle` | a bicycle with an assisting electric motor; **class** attribute as the jurisdiction's taxonomy labels it | local |
| `ru.electric_scooter` | a standing or seated electric scooter with handlebars | local |
| `ru.pedestrian` | a person on foot, in a wheelchair, or on a device the jurisdiction treats as on foot **Not a stand-in for:** a person on a bicycle or scooter | general |
| `ru.pedestrian_with_white_cane_or_guide_animal` | pedestrian carrying a white or white-and-red cane, accompanied by a guide animal, or led by another person | general |
| `ru.child` | pedestrian who is visibly a child | general |
| `ru.emergency_vehicle` | vehicle of a class the jurisdiction designates as emergency; **kind** ∈ {police, fire, ambulance, other} **Not a stand-in for:** a responding emergency vehicle — the class alone is not responding; its responding is conduct, carried by a concept, and an unobserved lamp or siren makes the rule unknown, not satisfied | general |
| `ru.fire_apparatus` | a fire-fighting vehicle (a sub-kind of `ru.emergency_vehicle` that law names on its own) | general |
| `ru.official_vehicle` | a vehicle in official or contracted road service, identifiable by livery or equipment; **kind** ∈ {tow, utility, highway_maintenance, incident_management, regulatory_agency, coroner, armored_car, municipal, other} **Not a stand-in for:** an emergency vehicle | general (kinds `incident_management`, `regulatory_agency`, `armored_car`: local) |
| `ru.rail_vehicle` | a train, tram, streetcar or other on-track equipment | general |
| `ru.occupant_count` | the number of persons in or on a vehicle (an integer attribute of a road user). A source that observes a change in it — a person arriving at or leaving a vehicle — but not a total, declares the count absent: what it observes then is the arrival or the departure, which is not this atom | general |
| `ru.rider_posture` | how a rider sits and holds the machine: **on_seat**, **hands_on_controls** (count), **standing_on_deck**, **holding_another_vehicle**, **stunt** (a wheel off the ground, a person on the handlebars). The fields are independent: a source declares each on its own, and one that renders a rider as part of the machine, so that no field can vary, declares all of them absent. **hands_on_controls** is a count and is the field a source is least likely to carry **Not a stand-in for:** a manoeuvre, or an arm signal, which is `sig.hand_signal` | general |
| `ru.subject` | the road user whose conduct a rule judges (the ego) | general |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept | general |

Legal aggregate words ("vehicle", "traffic") are carried by `ru.aggregate` with the definition-scoped
id as its argument, never the word: which classes the posted definition counts under that id is
derived from its words and recorded in the reading, never expanded into a class list by a rule.
"Driver" is no aggregate: it names who controls a vehicle, a relational role read as the section on
what is not an atom states. A responding emergency vehicle is a role the words describe by conduct, carried by a concept, not by the class.

## 2. Kinematics and control state (`kin`) — measurements on any road user, and the inputs to a vehicle's controls

| id | contract | unit / frame | scope |
|---|---|---|---|
| `kin.time` | instant of observation of a scene | ms, monotone within a trace | general |
| `kin.position` | position of the body's reference point | m, world frame (map or local) | general |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown | unit vector, world frame | general |
| `kin.velocity` | velocity vector | m/s, world frame | general |
| `kin.speed` | magnitude of velocity | m/s | general |
| `kin.accel_longitudinal` | acceleration along heading, signed **Not a stand-in for:** speed | m/s² | general |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres | deg/s | general |
| `kin.extent` | the body's size along its axes about the reference point: a trace writes the half-length, half-width and half-height; a formula reads the full length, width and height, twice each | m | general |
| `kin.steer_angle` | front-wheel steering angle. A source often carries it for the road user whose conduct is judged and not for the others; the capability is declared for the atom, not per road user, so a source that supplies it for the subject alone declares `subject` and one that cannot supply it at all declares it absent **Not a stand-in for:** road geometry, a turn, a lane change or any other manoeuvre — a steering input is not a path and not a road | deg | general |
| `kin.path_length` | distance travelled along the body's path since the start of the trace, monotone | m | general |
| `kin.engine_running` | the vehicle's engine or motor is running, so that propulsion is available **Not a stand-in for:** motion or a halt — a vehicle stands with its engine running and rolls with it stopped | — | general |
| `kin.parking_brake` | the parking brake (hand brake) is set **Not a stand-in for:** the service brake (`kin.service_brake`) or the brake lamp (`sig.brake_lamp`) — a set parking brake lights no lamp and a pressed pedal sets no parking brake | — | general |
| `kin.gear` | the gear selected: negative for reverse, zero for neutral, positive for a forward gear **Not a stand-in for:** the direction of motion — a vehicle in a forward gear rolls backwards on a grade; backing is read from kinematics | gear number, signed | general |
| `kin.throttle` | the accelerator input, as the fraction of its full travel that is applied **Not a stand-in for:** acceleration (`kin.accel_longitudinal`) — the input is what the driver does, the acceleration is what the body does | ratio | general |
| `kin.service_brake` | the service brake (foot brake) input, as the fraction of its full travel that is applied **Not a stand-in for:** deceleration or the brake lamp — the lamp is what other road users see, the input is what the driver does | ratio | general |

The control-state atoms are observed on an instrumented vehicle — a simulator's own vehicle, a
vehicle with a data recorder. A source that observes them on the subject's vehicle alone declares
them `subject`; a source that observes none declares them absent, and a rule that reads one then
reports unknown.

## 3. Road structure (`st`) — map-level atoms and occupancy

A kind whose contract ends in **Refines:** names the kind it refines: every region of the refining kind is also a region of the kind it refines, and of every kind that one refines. A parent never implies a refining kind, and two kinds refining one parent never imply each other. Refinement is not lying on a way (`st.on_way`): a region that lies on another is not thereby of its kind. Where a source cannot tell a refining kind, only the regions it labels with a kind that refining kind refines are unknown members of it; a region of any other kind is known not to be one. A kind whose contract begins with **Abstract.** is the union of the kinds that refine it, and only a quantifier or a formula reads it: no region is labelled with it, no source declares it a kind it cannot tell, it refines no kind, and a region is of it exactly when it is of a kind that refines it (unknown where that is unknown for one of them and true for none). An abstract parent is no parent for what a source cannot tell: a kind whose parent is abstract is treated, where a source cannot tell it, as a kind that refines none.

| id | contract | scope |
|---|---|---|
| `st.highway` | the entire public way between its boundary lines, including sidewalks and shoulders **Not a stand-in for:** the roadway | general |
| `st.travel_region` | **Abstract.** the union of the kinds a device can govern (`dev.governs`): a lane and the kinds that refine it, a bicycle lane or path, a roadway and the kinds that refine it, a shoulder, or an intersection; a region is a travel region exactly when it is of one of them **Not a stand-in for:** the extent of a highway (`st.highway`, `st.on_way`) — a sidewalk, a crosswalk, a stop line or the way as a whole is no travel region; travel along or across a way, which the road user's motion and the region's direction state, never the kind of the region occupied; or which entry into an intersection a region is (`st.lane_enters`, `st.entrance_of`) | general |
| `st.roadway` | the part of a highway improved for vehicular traffic, excluding shoulder; separate roadways of a divided highway are separate **Not a stand-in for:** the sidewalk — 'not on the roadway' includes shoulder, verge and parking bays **Refines:** `st.travel_region` | general |
| `st.lane` | a longitudinal strip of roadway for one line of vehicles **Not a stand-in for:** a half of the roadway or a lateral position within a lane — lane membership is not an offset from the edge, and lane ordinal equals roadway half only on a two-lane road **Refines:** `st.travel_region` | general |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown | general |
| `st.lane_adjacency` | left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes | general |
| `st.lane_connectivity` | which lane a lane leads into | general |
| `st.lane_enters` | relation: the intersection region a directed approach carrier runs into at its entrance end — the carrier is an approach to that intersection. A carrier is a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path that the source records as a directed approach segment: the stretch one direction of travel uses to reach one junction, its entrance end at that junction. A bicycle lane or path stays its own kind, not a lane, and a mark or a device's governance on it does not pass to an adjacent lane, nor theirs to it. A two-way road between two junctions is written, where the source can separate its directions, as one segment per direction, each entering the junction its direction reaches; each keeps its kind, and none is relabelled one-way for having a direction, nor is a lane written where the road has none. Writing the relation on a roadway, one-way roadway, shoulder or bicycle lane or path asserts that it is such a segment: a whole two-way roadway or bicycle path, with an end at each junction, carries none, and which junction it is an approach to stays unknown. A carrier enters one intersection at most. The relation is entry topology: it is decided where the source records it, whether or not the carrier's direction (`st.lane_direction`) is observed. It is the source's record, never inferred from distance, overlap or a road user's velocity, and a carrier never takes the entrance of a carrier it overlaps. **Which carrier a road user approaches through:** a road user's approach to an intersection is a carrier it occupies (`rel.occupies`) whose entrance end is that intersection, and the mark that governs that approach is one the source records as marking that carrier (`st.entrance_of`). The intersection is fixed by the event the rule reads (the intersection entered, or the one the words name), never by the road user's velocity or heading, by distance or by overlap. A road user occupying one such carrier approaches through it whatever its motion: forward, at rest, backing, or with its velocity or heading unobserved. Overlapping carriers that enter different intersections are told apart by the intersection, not by motion. Where it occupies several carriers entering the same intersection and the verdict differs between them (different marks, or one mark's association unobserved), which governs is unknown; where the verdict is the same through each, it is decided; a rule never picks the carrier that favours the road user. Travel against a carrier's direction does not change which intersection the carrier enters, and reaching a carrier's far (exit) end is no entry through it **Not a stand-in for:** the lane a lane leads into (`st.lane_connectivity`), the subject's presence in the intersection (`rel.occupies`), or the region a device governs (`dev.governs`) — a device governs a lane and the lane enters an intersection; which intersection a device controls is read through both, or directly where the device governs the intersection | general |
| `st.on_way` | relation: the public way (a `highway` region) a structure region lies on — a lane, roadway, shoulder, crosswalk, stop line, median or any other part of it; an intersection lies on every way that meets there **Not a stand-in for:** nearness to a way (`st.region_geometry`), or the lane a lane leads into (`st.lane_connectivity`) | general |
| `st.entrance_of` | relation: the carrier whose entrance into an intersection a stop line or a crosswalk marks — exactly that carrier's entrance, the line or crossing a vehicle approaching through that carrier halts at or before, and not a line near the carrier or on its way. The carriers are those `st.lane_enters` admits: a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path recorded as a directed approach segment; the intersection is the one that carrier enters, so a rule reads both relations on the same carrier. One line may mark several carriers (several lanes, or lanes and a segment or a bicycle lane beside them), and a carrier may have a stop line and a crosswalk. Where the source observes a line's entrances its list is complete, and the line marks no carrier it does not list; where it does not, which carriers the line marks is unknown, never "no line for this carrier". The association is the source's record, never inferred from distance, overlap or a road user's velocity; a carrier never takes the line, nor the governance of a device (`dev.governs`), of a carrier it overlaps. No region other than a stop line or a crosswalk marks an entrance **Not a stand-in for:** distance to the line (`st.region_geometry`), or the way the line lies on (`st.on_way`) | general |
| `st.lane_marking` | per side of a lane: **type** ∈ {none, broken, solid, double_solid, solid_broken, dotted, curb}, **colour** ∈ {white, yellow, other} | general |
| `st.centre_line` | the marking, or the geometric centre, dividing the two directions of a two-way roadway | general |
| `st.road_edge` | curb or edge of the roadway; **paved** attribute for the surface beyond it | general |
| `st.shoulder` | the part of the highway beside the roadway not intended for vehicular traffic; **paved** attribute **Refines:** `st.travel_region` | general |
| `st.sidewalk` | area for pedestrians between roadway and property line **Not a stand-in for:** a crosswalk | general |
| `st.median_or_divider` | physical barrier or dividing section between roadways; **opening** attribute where a crossover exists | general |
| `st.one_way_roadway` | roadway on which traffic is restricted to one direction **Refines:** `st.roadway` | general |
| `st.intersection` | the region where two roadways meet, bounded by the prolongation of their edges; a junction where an alley meets another way (a street, road, highway or alley) is no intersection but a `st.driveway_or_alley_entrance` **Not a stand-in for:** a crosswalk or a stop line — a stop before the crossing is earlier than a stop before the intersection **Refines:** `st.travel_region` | general |
| `st.crosswalk` | marked crossing, or the unmarked prolongation of sidewalks at an intersection (`st.intersection`); **marked** attribute | general |
| `st.stop_line` | the transverse line marking where vehicles halt for a device | general |
| `st.driveway_or_alley_entrance` | private road, alley or driveway meeting the highway **Not a stand-in for:** which of them meets the highway there — the kind does not tell an alley's entrance from a private road's or driveway's | general |
| `st.alley` | a narrow way within a block serving the rear of properties | general |
| `st.curvature` | horizontal curvature of the roadway at a point, as a magnitude (1/m, never negative): a bend to either hand has the same value | general |
| `st.grade` | longitudinal slope of the roadway at a point **Not a stand-in for:** the place of a crest (`st.crest`) — the slope where a road user is says nothing of a crest ahead of it | general |
| `st.crest` | the place on a roadway's longitudinal profile where the slope changes from rising to falling in the direction of travel, carried as a region with a reference point and a boundary, so the ground distance from a road user to it is read through `st.region_geometry` **Not a stand-in for:** the slope at a point (`st.grade`), the view a crest restricts (`st.sight_distance`), or a horizontal bend (`st.curvature`) | general |
| `st.sight_distance` | the distance along the road within which a vehicle at a point and another vehicle on the road could see each other, from the eye of either driver to the body of the other vehicle at the height convention the source declares: both the view of approaching traffic from that point and its being seen by drivers approaching it, whether or not any road user is there **Not a stand-in for:** whether an actual road user saw, or could see, another at an observation (`rel.visible`), or the clarity of the air (`env.visibility`) | general |
| `st.sight_along_way` | the distance along a way, in each direction from the point of that way nearest a road user, within which another vehicle on that way could be seen from the road user's eye at the observation, at the height convention the source declares; the smaller of the two directions; m **Not a stand-in for:** the sight distance of the place the road user is at (`st.sight_distance`), or whether an actual road user is seen (`rel.visible`) | general |
| `st.railway_crossing` | level crossing of a railway with the roadway, and its nearest rail | general |
| `st.controlled_access` | a highway with access only at designated points, and its entrance and exit lanes | general |
| `st.elevated_structure` | bridge, viaduct or tunnel carrying the roadway | general |
| `st.bicycle_lane_or_path` | lane or separate path reserved for bicycles and the devices a jurisdiction groups with them **Refines:** `st.travel_region` | general |
| `st.reserved_lane` | lane reserved for a class of vehicles; **class** ∈ {high_occupancy, bus, heavy_vehicle, other} **Refines:** `st.lane` | general (class `high_occupancy` with occupancy and hours conditions: local) |
| `st.centre_turn_lane` | a single centre lane used only for turning by traffic in both directions **Refines:** `st.lane` | local |
| `st.turn_lane` | a lane designated only for turning; **side** ∈ {left, right} **Refines:** `st.lane` | general |
| `st.parking_space` | marked bay for standing or parking; **angle** attribute; **designation** ∈ {general, disabled, disabled_side_lift, access_aisle, municipal, charging} | general |
| `st.curb_zone` | a signed or marked length of curb; **kind** ∈ {passenger_loading, freight_loading, tour_bus_loading, restricted_parking, bus_stop, taxicab_stand, fire_lane, no_stopping, no_parking}; **colour** ∈ {red, yellow, white, blue, gray, none} where the curb itself is painted | general (curb colour code and kind `tour_bus_loading`: local) |
| `st.transit_stop` | a bus stop, bench, shelter or platform for public transport passengers | general |
| `st.safety_zone` | an area within the highway marked off for pedestrians only | general |
| `st.pedestrian_grade_separation` | a pedestrian tunnel or overpass at a point on the highway | general |
| `st.fire_hydrant` | a fire hydrant beside the roadway | general |
| `st.fire_station_entrance` | the driveway entrance of a fire station | general |
| `st.roundabout` | a rotary intersection: its central island, its circulatory roadway and its entry and exit approaches | general |
| `st.lane_width` | width of a lane at a point | general |
| `st.region_geometry` | the reference point and the boundary polygon of a structure region in the world frame, and the ground distance from a road user's body outline to it (zero when they overlap); a source that maps regions without their outline declares it absent, and every such distance is then unknown **Not a stand-in for:** occupancy — a footprint inside a boundary is `rel.occupies`, which a source may observe without geometry | general |
| `st.obstruction` | a physical object on or beside the roadway that is not a road user; **kind** ∈ {debris, excavation, hose, barrier, stalled_vehicle_wreckage, sidewalk_fixture, mail_drop_box, other} | general |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) | general |

## 4. Control devices (`dev`) — class, state, position, governance

| id | contract | scope |
|---|---|---|
| `dev.traffic_signal` | a signal head; **state** ∈ {circular_green, circular_yellow, circular_red, green_arrow(dir), yellow_arrow(dir), red_arrow(dir), flashing_yellow_arrow(dir), flashing_red, flashing_yellow, dark, unknown} with dir ∈ {left, right, straight, u_turn}; several states may be displayed at once; **uncovered** attribute for an installed head whose faces are not covered | general (state `flashing_yellow_arrow`: local) |
| `dev.pedestrian_signal` | a pedestrian head; **state** ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; **countdown** attribute when a timer is displayed | general (countdown semantics: local) |
| `dev.lane_control_signal` | an overhead per-lane signal; **state** ∈ {green_down_arrow, red_x, yellow_x, yellow_arrow(dir), dark} | local |
| `dev.speed_limit_beacon` | a pair or more of yellow lamps mounted with a speed sign, flashing alternately when the sign's limit is in effect; **flashing** attribute | local |
| `dev.crossing_warning_signal` | a signal device at a pedestrian or school crossing that warns of persons crossing; **active** attribute | general |
| `dev.stop_sign` | regulatory sign requiring a full halt | general |
| `dev.yield_sign` | regulatory sign requiring yielding without a mandatory halt | general |
| `dev.speed_limit_sign` | sign stating a maximum or minimum speed, with value and unit; **kind** ∈ {maximum, minimum, structure_maximum, zone} | general |
| `dev.regulatory_sign` | a point regulation by catalogue **code**, with the same structured **conditions** attribute as `dev.zone_sign`, read as that row says (unconditional when empty, unknown when absent), where the sign states hours, days, a duration or a class: no_left_turn, no_right_turn, no_u_turn, no_straight, one_way, keep_right, do_not_enter, wrong_way, no_stopping, no_standing, no_parking, angle_parking, right_turn_only, entrance, exit, closed_to_traffic, exempt_crossing, abandoned_crossing, shoulder_use_permitted, bicycles_prohibited, pedestrians_prohibited, nonmotorized_prohibited, motor_vehicles_prohibited, truck_route, no_trucks **Not a stand-in for:** a manoeuvre or a road feature — a prohibition sign is a condition, a warning sign is not the hazard it warns of, and a sign is not a signal | general (`shoulder_use_permitted`, `exempt_crossing`, `truck_route`: local) |
| `dev.zone_sign` | a sign that begins or ends a signed zone along the road; **kind** ∈ {school, school_crossing, pedestrian_safety, temporary_traffic_control, no_passing, high_occupancy_lane, heavy_vehicle_lane, speed_zone, narrow_highway, hazardous_place, parking_restricted, trail}; **end** attribute; **conditions** attribute: a structured reading of the sign's legend — a list of time windows (a set of weekdays or a calendar class such as school days, a start and an end time of day), a minimum occupancy, a duration limit, a vehicle class, or a "when children present" flag; a legend read with no restriction is the empty set (unconditional), a legend not read is absent (every condition unknown) **Not a stand-in for:** whether the condition holds now — that is `prim.conditions_hold` | general (kinds `school_crossing`, `pedestrian_safety`, `high_occupancy_lane`: local) |
| `dev.railway_signal_or_gate` | the devices at a level crossing; **lights** ∈ {flashing, dark}; **gate** ∈ {up, lowering, down, raising, none}; **bell** attribute | general |
| `dev.temporary_traffic_control` | cones, barricades, temporary signs and flashers marking works, a closure or an obstruction | general |
| `dev.human_direction` | a person directing traffic and the direction given; **role** ∈ {police_officer, flagger, school_crossing_guard, railroad_flagger}; **indication** ∈ {stop, proceed, slow, turn(dir)} | general |
| `dev.governs` | relation: the travel regions whose traffic the device controls — a lane, reserved lane, turn lane, centre turn lane, bicycle lane or path, roadway, one-way roadway or shoulder — or an intersection, read as control of the junction itself and of nothing else (no closure to the lanes that enter it); never a highway, a controlled-access region or a region no vehicle travels in. Unknown where the source does not observe what a device governs **Not a stand-in for:** a position — the region a device governs is not where a halt is required | general |
| `dev.position` | location of the device head / sign face **Not a stand-in for:** a stop line or a crossing — the distance to a signal head is a different quantity from the distance to the line or region | general |
| `dev.inoperative` | a signal head installed and uncovered but showing no valid indication | general |

## 5. Signals emitted by road users (`sig`)

| id | contract | scope |
|---|---|---|
| `sig.turn_indicator` | the turn indicator **state** ∈ {off, left, right}: neither indicator lit, or the left or the right one **Not a stand-in for:** the turn or lane change itself — the indicator is the signal that precedes a manoeuvre, judged separately from it | general |
| `sig.brake_lamp` | brake lamps lit **Not a stand-in for:** a halt or a deceleration — a lamp is an actuation; the motion state is `kin.velocity` / `kin.accel_longitudinal` | general |
| `sig.hazard` | both indicators flashing together | general |
| `sig.headlamp` | headlamp **state** ∈ {off, low_beam, high_beam} | general |
| `sig.position_lamp` | position, parking, cowl or tail lamps lit (the lamps a vehicle shows without its headlamps) | general |
| `sig.compression_brake` | an engine compression brake sounding (audible; a source without audio declares it absent) | general |
| `sig.warning_lamp` | a warning lamp lit; **colour** ∈ {red, blue, amber, white}, **mode** ∈ {flashing, rotating, steady}, **facing** ∈ {front, rear, side} **Not a stand-in for:** an audible warning | general (steady blue rear lamps and amber-lamp roles: local) |
| `sig.siren` | a siren, whistle or bell sounding (audible; a source without audio declares it absent, and does not read a warning lamp as the sound — the two are separable and a road user may show one without the other) | general |
| `sig.horn` | an ordinary horn or a rail vehicle's horn or bell sounding (audible; a source without audio declares it absent, and no visible state stands in for it) **Not a stand-in for:** a siren | general |
| `sig.hand_signal` | a driver's or rider's arm signal; **meaning** ∈ {no_signal, left, right, stop_or_slow, re_enter}: no arm signal given, or the meaning of the one given | general |
| `sig.door_open` | a door open; **side** ∈ {traffic, curb} | general |

## 6. Environment (`env`)

| id | contract | scope |
|---|---|---|
| `env.darkness` | insufficient natural light; the boundary relative to sunset and sunrise is a reading parameter | general |
| `env.precipitation` | rain or snow falling | general |
| `env.wet_road` | road surface wet, standing water | general |
| `env.ice_or_snow` | road surface icy or snow-covered | general |
| `env.visibility` | visibility distance (fog, dust, smoke) | general |
| `env.civil_time` | the local calendar time of the observation: date, weekday, time of day (from the recording's metadata, not from the scene) **Not a stand-in for:** `kin.time`, which orders observations within a trace and carries no date | general |

Weather and surface conditions are what a speed or care standard is judged against; every one of
them is observable and is kept whether or not a single clause names it. Civil time is what a
posted hours-of-effect condition is judged against; a source that records no calendar time
declares it absent, and every specification that reads it then reports unknown.

## 7. Relations between road users (`rel`)

| id | contract | scope |
|---|---|---|
| `rel.centre_distance` | Euclidean ground-plane distance between reference points **Not a stand-in for:** a clearance between bodies or an order of arrival — centre-to-centre overstates a clearance by about the two half-extents, and proximity says nothing about who reached a boundary first | general |
| `rel.surface_gap` | distance between the nearest points of two bodies, each body's footprint read with its own heading and extent: zero when they touch or overlap, never negative; its longitudinal and lateral components are the lengths of the vector between those nearest points along and across the subject's heading, and a read without a component is the distance; a supplied gap with a negative component reads unknown, never as its magnitude, as zero or as contact | general |
| `rel.ahead_behind_in_lane` | a is ahead of / behind b in the same lane, along the lane direction | general |
| `rel.longitudinal_overlap` | the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies | general |
| `rel.oncoming` | headings opposed and closing: the cosine of the angle between the headings is below the negative of its tolerance, which is the cosine of the largest angle off exactly opposed allowed, a ratio between -1 and 1 **Not a stand-in for:** the direction a road user approaches from — that is read through the carrier it approaches through, any carrier `st.lane_enters` admits (a lane or a kind refining it, or a roadway, one-way roadway, shoulder or bicycle lane or path recorded as a directed approach segment), whose entrance end is the intersection, and through that carrier's direction (`st.lane_direction`) at the same instant; where that evidence is unobserved, the direction is unknown, never a reason a duty does not arise. A turn can make the current headings cease to satisfy this relation while the vehicle's approach direction remains unchanged. | general |
| `rel.same_direction` | headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1 | general |
| `rel.bearing` | direction of b from a in a's frame (for "on the right of", "immediately to the rear") | general |
| `rel.contact` | the bodies of two road users, or a road user and a structure, touch or overlap (a collision) **Not a stand-in for:** a near miss; bodies that do not touch or overlap are not in contact. | general |
| `rel.visible` | b is visible from a: an unobstructed line of sight from a's reference point to b's body, as the source tests it (a ray cast, an occlusion test, an annotator's judgement) **Not a stand-in for:** a distance, the sight distance of a place (`st.sight_distance`) — what could be seen from or at a place, whether or not any road user is there, is that atom, the clarity of the air (`env.visibility`), or a lamp being lit — a visible vehicle may show no lamp and a lit lamp may be hidden | general |

Computed from kinematics; listed because traffic language names them directly and a source may
supply them measured rather than derived. `rel.visible` is the exception: it depends on what
stands between two bodies, which no kinematics carry, so only a source supplies it and it is
never computed.

## 8. Judgement standards — not atoms; how a rule gives them a concrete meaning

Traffic law states many duties as standards: a manoeuvre made "with safety", a speed that is
"reasonable", a distance that is "practicable", a vehicle "so close as to be a hazard", a stop
"when necessary". No scene contains a reasonableness. A specification that bottoms out in such a
word detects nothing, so a standard is never an atom and never a leaf of a rule.

**Operationalization.** The plan bounds every standard in a clause by concepts and primitives
with parameters the reading sets, and records an *operationalization claim*: the standard's
words, the concepts, the parameters, and the engineering convention their values come from (a
headway convention, a gap-acceptance convention, a stopping-distance model, a sight-distance
model). The
harness rejects a node that maps a standard to nothing. The claim bounds the standard; it never
replaces an observable the clause states outright. The claim records the specification's
operationalization; it does not determine a recording's label. Labels involving judgement calls are
confirmed independently under operator-reviewed, frozen parameters before they drive repair.

**Two kinds of rule follow.** Where the standard qualifies an otherwise concrete duty (a yield
that is owed when the other vehicle is "so close as to be a hazard"), the operationalization is a
bound on one element and the rule is the law's own rule. Where the standard *is* the duty ("due
care", "careless", "reasonable speed"), any operationalization is a policy choice, not a reading
of the text: such a rule is marked **surrogate**, its verdicts are evidence and not a legal
conclusion, and it is evaluated separately.

**One kind of standard has only a surrogate.** A standard about the driver's state of mind —
care, attention, intent, knowledge — is not observable (§9): any operationalization of it is a
surrogate, whatever concepts bound it. A declared intention (§9) is not of this kind: it is a fact
the trace supplies, not an operationalization of a standard.

## 9. Not atoms

**Legal region classes** — categories a jurisdiction defines administratively and that are not
visible on the road: a district defined by its buildings, an urban or rural area, a city or town
limit, a mountain or canyon highway, premises to which the public has access, the designation of a
highway as a priority road, whether school is in session and its hours, the hours a signed
restriction is in effect when the sign only refers to them. These enter a formalization only as
**reading assumptions** declared per map or per trace, never as atoms a rule reads from a scene.
Where the same category is *also* marked on the road by a sign (`dev.zone_sign`), the sign is the
atom and the category is not.

**Declared intentions** — where the words state that a road user intends, or is preparing, to
turn, the span is carried by a declared intention of that road user at the region the words name:
a fact the trace supplies, under an `int.*` id the plan declares with its meaning, never an act in
a window ahead nor a signal (a signal "of intention" is the signal, `sig.turn_indicator`). The act
the words also name ("is making …") is read by its manoeuvre concept, and the two are joined as the
words join them. What an id covers (an intention to turn, a preparation for a turn) is its
meaning; when it begins and ends is the source's declaration. A declared intention states, at each
scene, the source's declaration current at that scene for one road user at one target region:
- it is **true** where the source's current plan for that road user includes, at that target, what
  the id means;
- it is **false** where the source's current plan decides that what the id means does not hold at
  that target: another manoeuvre, passing through, a manoeuvre cancelled, or one the plan has
  completed;
- an **id is left out** of the record's values wherever the source's plan does not decide its
  meaning, even when other ids of the same pair are listed: what a plan does not mention is
  unknown, never false;
- the **pair is absent** where the source has no current plan for that road user at that target,
  or does not know it.

The value follows the source's plan, never the road user's motion: a manoeuvre that is blocked,
delayed or under way stays true while the plan still holds it. A source never writes false for a
road user whose plan it does not know. A change of declaration takes effect from the scene that
carries it, and a rule reads a declaration only at the observation it judges or before it, so a
later change never alters an earlier verdict or erases an obligation already triggered.

**Purpose, perception and imminent movement** — why a vehicle is stopped (loading, waiting for a
pedestrian, receiving passengers), what a driver perceived, knew or ascertained, a movement it is
about to make. These are not observable, and a rule is a check of conduct on a trace, so a span
that turns on one is read through the conduct or the outcome it governs: an imminent movement
("about to …") by the movement it leads to, a duty to perceive, ascertain or make sure by the outcome the check is there to secure
(the movement made with the clearances the reading sets), a purpose by the conduct it explains.
Who or what controls a vehicle — a person at the controls, an automated driving system, no one —
is not observable either: "drives", "operates" and "the driver" are read through the vehicle's
controlled motion, a vehicle moving on the road is taken to be driven, and the duty binds that
vehicle's conduct whoever or whatever controls it. Where the words offer observable evidence themselves, the rule reads that evidence (what was in an
actual road user's line of sight is `rel.visible`; what could be seen from or at a place is
`st.sight_distance`). Each such reading is disclosed on its span as a narrowing of kind
`observable_reading` with its category (`intention`, `perception`, `status`, `purpose`, `agency`): it is a
reading of the words, not an approximation by a neighbouring atom, and never an assumption or a
gap. A state of mind that shows in no conduct is outside what a trace can check, and a rule never
assumes one. The control state of
a vehicle — engine running, parking brake set, gear, throttle, service brake — is not of this
kind: it is observed on an instrumented vehicle and carried by the control-state atoms of §2,
under the `subject` capability where only the subject's vehicle is instrumented.

**Legal status of a feature on the road** — that a sign, a signal, a marking, an opening or a
crossing is official, posted or designated by an authority. The feature's presence on the road is
the observable evidence of that status: a rule reads the feature and presumes the status (an
`observable_reading` of category `status`). A category that no feature on the road displays is a
legal region class (above).

**A clearly marked stop line** — the words "clearly marked" said of a stop line the scene
represents. The line's presence is the evidence: a rule reads the represented stop line as the
clearly marked one (an `observable_reading` of category `status`), and the paint's clarity or wear
is not modelled. This reading never relaxes which stopping point governs, the action and its
timing, or the road users to yield to.

**Lawfulness of another road user's conduct** ("pedestrians lawfully within the crosswalk", "a
person lawfully riding") — a reference to another rule's verdict, expressed by rule composition in
Core, not by an atom.

**An act due at a place before an event: the approach** — where words require an act (a halt, a
yield) at a named place (a stop line, a crosswalk, the edge of an intersection) before an event the
words name (an entry into an intersection, the passing of a mark), and state no occurrence, timing
or exception of their own, the act is owed on the approach that leads to that event. The approach is
identified by the map and the event's target, never by the road user's motion: a road user's
approach to an intersection is a carrier it occupies whose entrance end is that intersection
(`st.lane_enters`), and a mark governs that approach where it is recorded as marking that carrier
(`st.entrance_of`); below, the mark is the named place, and where the place is the edge of the
intersection it is that carrier's entrance end. The approach starts at the last observation before
the event at which the road user, on a carrier the mark is recorded as marking, is outside the
mark's stopping zone upstream: off the mark, short of it, and farther from it than the stop-point
tolerance; where several marks of the place's kind mark that carrier, outside the zone of each and
short of each. The side of the mark is read along that carrier's designated
direction (`st.lane_direction`, by the sign of `prim.region_offset_along`), never along the road
user's heading; every distance to the mark, the tolerance and the zone's bound included, is the
distance between the road user's body and the mark (`st.region_geometry`). The stop-point tolerance is
one parameter the reading sets: the bound within which the act counts at the place is the bound
beyond which the road user is outside the zone, and a halt that lies within measurement noise of
that bound may be read on either side of it, the expected limit of this approximation. Where the
words place the act before the road user enters a region, a halt at which its footprint already
overlaps that region (`rel.occupies`) is not at the place, and the stop-point tolerance applies
outside that region only. A search for
the act runs back from the event and ends only at that approach start or at the previous occurrence
of the same event for the same road user and the same place; nothing else ends it: not another
intersection or mark, not the start of the recording, not a first observation, not a distance
travelled. Each occurrence of the event owes its own act: an act done before the previous
occurrence of the same event for the same road user and place discharged that occurrence, not the
new one; an entry and the passing of a mark are different events, each with its own occurrences. Only an observed exit from the stopping zone upstream begins a new approach, so a road
user that leaves the zone upstream and comes back owes the act again; crossing the mark, moving on
toward the event, a change of carrier or a lateral move within the same entry, a reverse that stays
within the zone, and speed noise begin no new approach, and none of them loses an act already done for the event still
to come.
Where the search finds the act, the duty is met; where it reaches either end without the act, the
duty is violated; only where it reaches neither end without finding the act is the duty unknown.
Whether the event occurred at an observation is read from that observation and the one before it: it
is unknown, never absent, where the one before does not show the road user's place relative to the
mark through its carrier, because there is no earlier observation of the road user (its recording
begins at that observation), it is on no mapped carrier, or it is on a carrier whose association
with the mark is not observed; where the one before shows it on a carrier the mark is observed not
to mark, or already within the region the event enters, it is not that mark's event. Which mark
governs is read through the same carrier: where a mark's association with that carrier is not
observed, whether the mark governs is unknown; where the mark's entrances are observed, so that its
list is complete, and exclude that carrier, the mark does not govern that approach, the duty's place
is read from the other places the words list, in their order, and the duty is not unknown on that
ground. Missing evidence makes the duty unknown only where the verdict depends on it: a recorded act at a place known
to govern, a duty that does not arise, and an association the source excludes are decided
whatever the missing fact would be; where the verdict does turn on a missing direction, association
or observation, the duty is unknown, never decided from a distance alone or from the absence of a
record. Words that state their own occurrence, timing or exception govern instead, written with
their own window. This reading fixes the time of a duty, a distinction of the driving task: it is a
modelling convention the operator adopts for the whole corpus, not an abstraction of an incidental
word, and it relaxes no check of which place governs, the act, or the road users it concerns.

**Concepts** (`drv`) — manoeuvres, states of motion, road configurations and relations between
road users over time (a stop, a turn, a pass, a following gap, a laned roadway) are not atoms.
They are concept nodes the pipeline defines over atoms, primitives and other concepts, each with a
contract of its own, accepted like a rule and called by id (`drv.<family>.<name>`); a rule never
rebuilds one inline.

**Dataset fields** — any edge label, trigger region, render distance, band label or node name of
a particular scene-graph format. These are how a source grounds an atom; they belong in the
adapter and its manifest, never in a rule.

## 10. Primitives (`prim`) — computations the formula language cannot express

A primitive is a geometric computation over atoms with no legal word in it, defined once in Core
with its parameters exposed. A concept or a rule calls it by id; the set is closed, and a need
for another is a gap for the operator, never a definition written during a run.

`heading_since` (`Term.headingSince`) is a construct of the formula language, not an atom an
adapter supplies and not a primitive: the signed heading change of a road user since a formula
last became true, integrated from `kin.yaw_rate` with a step bound. It recognises no manoeuvre;
the formula that marks the onset does. `prim.heading_change`, over a fixed window behind each
observation, is not a stand-in for it.

| id | contract | parameters | result unit | parameter units |
|---|---|---|---|---|
| `prim.heading_change` | the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing | the window length (time) | deg | s |
| `prim.closest_approach_within` | under constant velocities, the centres of two road users approach each other at some time between the observation and the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them | the horizon (time) | boolean | s |
| `prim.closest_approach_time` | the time from the observation at which the two centres are closest, under constant velocities; undefined when they do not approach within the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them | the horizon (time) | s | s |
| `prim.closest_approach_distance` | the centre distance at that closest approach; undefined when they do not approach within the horizon **Not a stand-in for:** contact between bodies, the clearance between bodies, or the danger of a crash — it is computed from the centres under constant velocities, and alone establishes none of them | the horizon (time) | m | s |
| `prim.conditions_hold` | the structured conditions of a device (`dev.zone_sign`, `dev.regulatory_sign`) hold at the observation for a road user: `env.civil_time` falls in one of its time windows on one of its days (a calendar class is an assumption), and any occupancy or class condition is met | — | boolean | — |
| `prim.region_lateral_offset` | the signed lateral offset (m, left positive) of a structure region from a road user: the component, perpendicular to the road user's heading, of the vector from its reference point to the point of the region's boundary nearest that reference point; zero where the reference point lies inside the region; where several boundary points are equally nearest, their common component, and undefined where their components differ; unknown where the position, the heading or the boundary is absent | — | m | — |
| `prim.region_offset_along` | the signed distance (m) from a road user's reference point (`kin.position`) to a structure region (`st.region_geometry`), measured along a carrier's designated direction (`st.lane_direction`) on the straight line through the reference point parallel to that direction. The region is a closed set: a vertex the line only touches and an edge it runs along are points of it the line meets. Zero where the reference point lies in the region or on its boundary; where every point of the region on that line lies ahead, the distance to the nearest of them (positive); where every one lies behind, minus the distance to the nearest (negative); where the line does not meet the region, the value comes from the region's projection on the direction, the interval [lo, hi] of the signed distances of its points along it: lo where lo > 0 (all of the region ahead), hi where hi < 0 (all behind) — a projection gap, not a distance along the line, so the value may jump where the line starts or stops meeting the region, while its sign gives the side in both cases; undefined where the line meets the region both ahead and behind (the reference point lies in an opening of the region), where it misses the region and [lo, hi] spans or touches zero, and where the boundary is not a simple polygon (empty, fewer than three vertices, zero area, or crossing or touching itself); unknown where the position, the direction (a zero vector included) or the boundary is absent; independent of the boundary's start vertex and orientation. The direction is read normalised as `st.lane_direction` is, with Core's micrometre-rounded square root, and the distance is counted in lengths of that normalised vector (between 1 and 1 + 2·10⁻⁶ m), so it carries that rounding. It is a geometric quantity only: it does not establish that the road user is on the carrier, that the region marks the carrier's entrance, that the whole body has crossed the region, or that a crossing happened between observations; a caller states those with its own relations, footprint occupancy and temporal formulas; a distance to the region is read from `st.region_geometry`, never from this value | — | m | — |

## 11. Units of the measured atoms

The unit of the value a formula reads from a measured atom, by the name a formula uses
(`Term.measure`); a vector atom's components share its unit. `1` marks a count, a ratio, a
direction or an ordinal, which carry no unit; `1/m` is a reciprocal length. A primitive's units are
the last two columns of §10. These units type a comparison: two sides of a comparison, of a sum
or of the branches of a selection have the same unit.

| id | measure | unit |
|---|---|---|
| `kin.time` | `kin_time` | s |
| `kin.position` | `kin_position` | m |
| `kin.heading` | `kin_heading` | 1 |
| `kin.velocity` | `kin_velocity` | m/s |
| `kin.speed` | `kin_speed` | m/s |
| `kin.accel_longitudinal` | `kin_accel_longitudinal` | m/s² |
| `kin.yaw_rate` | `kin_yaw_rate` | deg/s |
| `kin.extent` | `kin_extent` | m |
| `kin.steer_angle` | `kin_steer_angle` | deg |
| `kin.path_length` | `kin_path_length` | m |
| `kin.gear` | `kin_gear` | 1 |
| `kin.throttle` | `kin_throttle` | 1 |
| `kin.service_brake` | `kin_service_brake` | 1 |
| `ru.occupant_count` | `ru_occupant_count` | 1 |
| `ru.rider_posture` | `ru_rider_posture_hands_on_controls` | 1 |
| `ru.electric_bicycle` | `ru_electric_bicycle_class` | 1 |
| `st.lane_direction` | `st_lane_direction` | 1 |
| `st.lane_adjacency` | `st_lane_adjacency` | 1 |
| `st.lane_adjacency` | `st_lane_adjacency_ordinal` | 1 |
| `st.lane_adjacency` | `st_lane_adjacency_count` | 1 |
| `st.lane_width` | `st_lane_width` | m |
| `st.curvature` | `st_curvature` | 1/m |
| `st.grade` | `st_grade` | 1 |
| `st.sight_distance` | `st_sight_distance` | m |
| `st.sight_along_way` | `st_sight_along_way` | m |
| `st.parking_space` | `st_parking_space_angle` | deg |
| `st.region_geometry` | `st_region_geometry` | m |
| `st.region_geometry` | `st_region_geometry_distance` | m |
| `dev.position` | `dev_position` | m |
| `dev.speed_limit_sign` | `dev_speed_limit_sign_value` | m/s |
| `env.visibility` | `env_visibility` | m |
| `env.civil_time` | `env_civil_time` | 1 |
| `rel.centre_distance` | `rel_centre_distance` | m |
| `rel.surface_gap` | `rel_surface_gap` | m |
| `rel.longitudinal_overlap` | `rel_longitudinal_overlap` | m |
| `rel.bearing` | `rel_bearing` | m |

### Formula language (`library/TrafficSpec/Core/Language/Formula.lean`; `Measure` from `Foundations/Time.lean`)
```lean
inductive Arg
  | var (name : String)      -- a bound variable
  | lit (value : String)     -- an enumeration value, spelled as in the ontology
  | nat (n : Nat)

inductive CmpOp
  | lt | le | eq | ge | gt

inductive Measure
  | time | path

mutual
  /-- A quantity. -/
  inductive Term
    | lit (q : Q) (unit : PUnit')                            -- written through a Units constructor
    | param (name : ParamName)                               -- a reading parameter
    | measure (atom : String) (args : List Arg)              -- a measured atom (Option Q or Option Nat)
    | quantity (concept : String) (args : List Arg) (params : List Term)   -- a Q-valued derived concept
    | distanceWhile (subject : String) (φ : Formula)         -- path length over which φ has held continuously
    | sinceRise (φ : Formula)                                -- time elapsed since φ last became true
    | headingSince (subject : String) (maxStep : Term) (ψ : Formula)   -- the heading change of subject since ψ last became true
    | aggregate (op : AggOp) (var : String) (φ : Formula) (t : Term)   -- op of t over the road users var of the scene satisfying φ
    | add (a b : Term)
    | sub (a b : Term)
    | mul (a b : Term)
    | div (a b : Term)
    | neg (a : Term)
    | abs (a : Term)
    | cond (φ : Formula) (a b : Term)                        -- a where φ holds, b where it does not
  /-- A three-valued statement about the trace at an instant. -/
  inductive Formula
    | tt
    | ff
    | atom (name : String) (args : List Arg) (params : List Term)   -- a Boolean atom; params for tolerances
    | cmp (lhs : Term) (op : CmpOp) (rhs : Term)
    | asm (id : AsmId)
    | intent (id : IntId) (who target : Arg)                 -- the declaration current here: road user `who` intends `id` at region `target`
    | same (a b : Arg)                                        -- the two variables denote the same entity
    | not (φ : Formula)
    | and (φ ψ : Formula)
    | or (φ ψ : Formula)
    | implies (φ ψ : Formula)
    | always (φ : Formula)                                    -- from now to the end of the trace
    | eventually (φ : Formula)                                -- φ here or at some later observation, to the end of the trace
    | until (φ ψ : Formula)                                   -- strong until, future
    | since (φ ψ : Formula)                                   -- past mirror of until
    | holdsFor (m : Measure) (d : Term) (subject : String) (φ : Formula)   -- φ at every observation in the window behind
    | within (m : Measure) (d : Term) (subject : String) (φ : Formula)     -- φ at some observation in the window ahead
    | untilWithin (m : Measure) (d : Term) (subject : String) (φ ψ : Formula)   -- ψ at some observation in the window ahead, φ at every one before it
    | atLast (m : Measure) (d : Term) (subject : String) (ψ φ : Formula)   -- φ at the last observation in the window behind at which ψ held
    | count (edge : Formula) (sinceφ : Formula) (op : CmpOp) (n : Nat)   -- rising edges of `edge` since `sinceφ` became true (start of its latest run)
    | rises (φ : Formula)                                     -- φ here and not at the previous observation
    | definedWhen (pre φ : Formula)                           -- φ where `pre` holds; unknown (undefined) where it does not
    | derived (concept : String) (args : List Arg) (params : List Term)   -- a Boolean derived concept
    | rule (id : String) (map : List (String × String))       -- another rule complied with (not engaged counts as complied)
    | ruleApplies (id : String) (map : List (String × String)) -- another rule engaged (its binders' classes and applicability hold)
    | existsUser (var : String) (φ : Formula)                 -- some road user present in the scene
    | forallUser (var : String) (φ : Formula)
    | existsRegion (kind : Arg) (var : String) (φ : Formula)
    | forallRegion (kind : Arg) (var : String) (φ : Formula)
    | existsDevice (kind : Arg) (var : String) (φ : Formula)
    | forallDevice (kind : Arg) (var : String) (φ : Formula)
end
```
Notes. `Arg.var` names a binder or a quantifier variable; `Arg.lit` an enumeration spelling or an
attribute selector (`"x"`, `"y"`, `"width"`, `"length"`, `"lateral"`, `"longitudinal"`, a side);
`Arg.nat` a count. Quantifiers `existsRegion k v φ`/`forallRegion` range over the scene's structures of
kind `k` (an `Arg.lit` spelling, or a concept's literal formal) or of a kind that refines `k`, and the
structures that may be of it where the source cannot tell; `existsDevice`/`forallDevice` over its
devices of a kind, `existsUser`/`forallUser` over its road users, the bound ones included (`same a b`
excludes the subject); the variable is an `Arg.var` inside `φ`. `rises φ` is φ here and not at the
previous observation; `definedWhen pre φ` is undefined (unknown) where `pre` fails; `Term.sinceRise φ`
the seconds since φ last became true; `Term.headingSince x step ψ` the heading change of `x` since ψ last
became true (zero at the onset, unaffected by ψ turning false; `step` is a time parameter bounding the
integration interval, not a window and not a look-back length); `Term.aggregate op v φ t` the min/max/median/count of `t` over the
road users `v` satisfying φ. `Term.cond φ a b` is `a` where φ holds and `b` where it does not; a
comparison over it is decided wherever both selections decide it alike, so a condition that selects
among bounds is written with it. `holdsFor m d s φ`: φ held at every observation in
the window of length `d` (a `Term`, usually `.param`) behind, measured in time or path of subject `s`:
`m = .time` is the last `d` seconds, `m = .path` the last `d` of distance the subject travelled, so a
window the words state as a distance travelled is a `.path` window;
`within` looks ahead; `atLast m d s ψ φ`: φ at the last observation in the window behind at which ψ held
(false where ψ held nowhere in a covered window). A window that reaches past the start of the trace is unknown (`windowTruncated`),
so a witness of a rule that looks back names `window`. `rule id map` / `ruleApplies id map`: `map` pairs
the composed rule's binder names with this rule's variables.

### What a formula may not say (`Language/RuleEval.lean`, `Language/Formula.lean`, `Language/Concept.lean`)
The static checks a rule and a concept are held to before any trace, and what Core states a formula may not do with the constructors it restricts:
- `Rule.check`: Every defect a rule has before any trace; empty for a rule the evaluator will never report `malformed` or `unboundVariable` on: an empty id; no binder, or one unnamed or named twice; an assumption or intention read but not declared, or an intention id ill-formed; an operationalization bounded by nothing, or by a name that is no atom, primitive or concept; a name no table knows; an atom, measure, primitive or concept given the wrong number of arguments; an unbound variable, or one of the wrong sort where a track, region or device is read (such a position takes a variable, never a spelling or a number; a literal position takes no variable); a spelling no enumeration decodes; a quantifier kind that is not a spelling; a parameter of an atom or a call, or a window's length, that is not a constant term (a literal, a reading parameter, or arithmetic over them); a heading change's step bound that is not a literal or a reading parameter, or a literal one not strictly positive; a declared intention read ahead of the judged observation; the distance travelled since the trace began read inside a search into the past; a composed rule not in the set, or a map that names a variable not bound to a track, misses one of its binders or names one it does not have. `regions` names variables the caller binds to regions: the region formals of a concept's instance, which alone may then have no binder.
- `Concept.check`: Every defect a concept has before any trace: an empty id; a formal or a parameter named twice; a parameter named as a reading's, or a body parameter that is no formal parameter; a literal formal that admits no value; a composed rule or a declared intention in the body (a concept reads neither); a referenced concept unknown, or a reference cycle; and, on every admissible instantiation of its literal formals with its calls expanded, every defect `Rule.check` finds in a formula and a call whose arguments do not fit the callee's formals.
- `Term.headingSince`: The signed heading change (degrees, left positive) of `subject`, integrated from its yaw rate, since ψ last became true: from the latest observation at which ψ rose definitely (false at the observation before, true there), counted from zero at that observation. ψ turning false does not end it, nor does a stop; only the next definite rise of ψ starts it again. Unknown where no such rise is observed with ψ known at every observation since (an onset before the recording, or one an unknown value of ψ could hide), where an interval between consecutive observations from the one before the rise onwards is longer than `maxStep`, or where a yaw rate since the rise is missing. `maxStep` is a literal or a reading parameter, a time, strictly positive: the sampling standard of the integration, not a window and not a bound on how far back the onset may lie.
- `Term.div`: `a / b`, unknown wherever `b` is zero. Its divisor reads no measured atom: a measurement can be zero (a straight way's curvature, a halted road user's speed), so a bound on a ratio is written as a bound on a product (a ratio below a bound is the dividend below the bound times the divisor).
- `ArgSort.literal`: A literal formal is read only where a spelling is expected: the kind of a quantifier, or a literal argument of an atom or a primitive. No operator compares it with a spelling (`same` compares two bound variables), so a body decides alike for every value except through such a reading; notions that differ only by the value are separate concepts.

### Concepts (`Language/Concept.lean`): the `Concept` a concept file declares, the `Instance` its witnesses build
```lean
inductive ArgSort
  | track
  | region
  | literal (values : List String)
  | nat

structure ConceptParam where
  name : ParamName
  unit : PUnit'

inductive ConceptBody
  | formula (φ : Formula)
  | quantity (t : Term)

structure Concept where
  id : String                          -- drv.<family>.<name>
  contract : String
  definition : Option String := none   -- the corpus definition the contract quotes, when it has one
  args : List (String × ArgSort)
  params : List ConceptParam
  body : ConceptBody
  residues : List String := []
  narrowings : List Narrowing := []
  supersedes : Option String := none

structure Instance where
  name : String
  concept : String                          -- the concept id
  literals : List (String × String) := []   -- literal formal ↦ spelling
  nats : List (String × Nat) := []
  params : List (String × Term) := []       -- formal parameter ↦ a constant term
  bounds : Option (Term × Term) := none     -- a quantity: the value lies in [lo, hi]
```
A rule calls a concept by its Lean name (the id with `.` → `_`): `.derived "drv_<family>_<name>" args params`
for a formula concept, `Term.quantity "drv_<family>_<name>" args params` for a quantity; `args` fill the
formals in order (a track formal takes a variable bound to a road user, a region formal a variable bound
to a region — the one the caller singles out, bound by its own region quantifier — a literal formal a
spelling among its values, a nat a count; each variable's innermost binding decides its sort, and the
gate checks every call against these sorts), `params` fill the formal parameters in order with constant
terms (`.param "p.…"` of the reading,
or a declared literal). Inside a concept's body every `.var` is a formal or bound in the body and every
`.param` is a formal parameter: a body never names a reading parameter. The call is expanded before
evaluation, so its atoms count as the caller's.

A caller states a condition on what a concept denotes only through what the concept exposes: the
road users and regions it passes as formals, and the parameters it fills. It cannot restrict a road
user, a region or a device that the body binds itself. Where the contract leaves a condition on such
a bound object to the caller (the class of the road users counted, the kind of a region the body
finds, the motion of the others), the concept exposes the object as a formal, or the quantifier or
count moves to the caller and the concept states the relation for one bound object. A concept whose
contract itself states the full range of its quantifier (every road user of the scene, whatever its
class; every region of a kind the body names) keeps its quantifier and any class condition the
contract states. A quantifier moved to the caller keeps its scope and its order relative to the
other quantifiers, the logical operators and the time operators the contract states: the concept
states the relation at one observation; what the contract puts around the quantifier ("at every
observation of the window, some road user") stays around the caller's quantifier, and what it puts
inside ("one road user, at every observation of the window") stays inside; the caller's bound
variable takes a name no other binder of the formula uses. A literal formal admits only the
spellings of Core's enumerations, never an aggregate id. When a member's class is left to the
calling law, that law states the class of an exposed track with its own admitted aggregate.

| node | law | binders | atoms claimed | build | law state |
|---|---|---|---|---|---|
| `LVMC_11_38_030` | LVMC-11-38-030 | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.moped, st.sidewalk | composable (build) | planned |
| `LVMC_11_30_090` | LVMC-11-30-090 | subject | drv.motion.complete_halt, drv.motion.moving_across_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.highway, st.lane, st.on_way, st.roadway, st.sidewalk | composable (build) | planned |
| `LVMC_11_20_060_o1` | LVMC-11-20-060 | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.driveway_or_alley_entrance, st.region_geometry, st.sidewalk | composable (build) | planned |
| `LVMC_11_30_140_B_o1` | LVMC-11-30-140-B | subject | drv.motion.complete_halt, rel.centre_distance, rel.contact, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.pedestrian_with_white_cane_or_guide_animal | composable (build) | planned |
| `LVMC_11_40_120` | LVMC-11-40-120 | subject | dev.governs, dev.regulatory_sign, dev.temporary_traffic_control, drv.motion.complete_halt, drv.motion.moving_across_carrier, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, st.bicycle_lane_or_path, st.highway, st.lane, st.lane_width, st.on_way, st.roadway | composable (build) | planned |
| `LVMC_11_52_040_A` | LVMC-11-52-040-A | subject | dev.governs, dev.regulatory_sign, drv.motion.parked, kin.heading, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.roadway, st.travel_region | composable (build) | planned |
| `LVMC_11_52_136` | LVMC-11-52-136 | subject | drv.motion.parked, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.parking_space | composable (build) | planned |
| `LVMC_11_46_030_o2` | LVMC-11-46-030 | subject | dev.crossing_warning_signal, dev.governs, dev.human_direction, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.highway, st.on_way, st.region_geometry, st.travel_region | composable (build) | planned |
| `LVMC_11_52_060` | LVMC-11-52-060 | subject | drv.motion.parked, kin.extent, kin.heading, rel.occupies, ru.aggregate=DEF-LVMC-11-02-170::trailer, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane_direction, st.on_way, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `LVMC_11_40_180_C_o2` | LVMC-11-40-180-C | subject | drv.interaction.overtake_pass, drv.motion.complete_halt, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-165::pedestrian, sig.horn, sig.siren, st.sidewalk | not composable: replanning | returned |
| `LVMC_11_52_070` | LVMC-11-52-070 | subject | dev.governs, dev.regulatory_sign, drv.motion.parked, kin.heading, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.parking_space, st.travel_region | composable (build) | planned |
| `LVMC_11_52_340` | LVMC-11-52-340 | subject | drv.motion.parked, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.official_vehicle, st.parking_space | composable (build) | planned |
| `LVMC_11_43_010_C2` | LVMC-11-43-010-C2 | subject | drv.motion.right_turn_through_region, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency, st.roundabout | composable (build) | planned |
| `NRS_484B_110` | NRS-484B-110 | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.safety_zone | composable (build) | planned |
| `LVMC_11_46_030_o1` | LVMC-11-46-030 | subject | dev.crossing_warning_signal, dev.governs, dev.human_direction, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.highway, st.on_way, st.region_geometry, st.travel_region | composable (build) | planned |
| `LVMC_11_40_140_o1` | LVMC-11-40-140 | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, st.alley, st.driveway_or_alley_entrance, st.highway, st.region_geometry, st.sidewalk | composable (build) | planned |
| `LVMC_11_48_060` | LVMC-11-48-060 | subject | dev.governs, dev.regulatory_sign, drv.motion.parked, rel.occupies, ru.aggregate=DEF-NRS-484A-305::truck, st.highway, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_220_2` | NRS-484B-220-2 | subject | drv.motion.circulating_clockwise_about, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | composable (build) | planned |
| `NRS_484B_153_2` | NRS-484B-153-2 | subject | drv.motion.complete_halt, rel.contact, rel.longitudinal_overlap, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.door_open | composable (build) | planned |
| `LVMC_11_30_030` | LVMC-11-30-030 | subject | drv.interaction.overtake_pass, drv.motion.complete_halt, kin.speed, prim.region_offset_along, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_113_3` | NRS-484B-113-3 | subject | drv.motion.complete_halt, drv.motion.moving_backward, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | composable (build) | planned |
| `LVMC_11_30_140_B_o2` | LVMC-11-30-140-B | subject | drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, rel.centre_distance, rel.contact, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.pedestrian_with_white_cane_or_guide_animal | composable (build) | planned |
| `NRS_484B_203_1_o2` | NRS-484B-203-1 | subject | drv.motion.complete_halt, kin.extent, prim.closest_approach_within, prim.region_lateral_offset, rel.longitudinal_overlap, rel.occupies, rel.oncoming, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.highway, st.lane, st.lane_adjacency, st.on_way, st.region_geometry, st.road_edge | composable (build) | planned |
| `NRS_484B_223_1b` | NRS-484B-223-1b | subject | drv.lane.entering_adjacent_lane, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator, st.lane, st.lane_adjacency | composable (build) | planned |
| `LVMC_11_60_090` | LVMC-11-60-090 | subject | dev.governs, dev.regulatory_sign, drv.motion.right_turn_through_region, kin.yaw_rate, prim.conditions_hold, rel.occupies, ru.taxicab, st.curb_zone, st.intersection, st.travel_region | composable (build) | planned |
| `NRS_484B_223_3a` | NRS-484B-223-3a | subject | drv.motion.left_turn, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_turn_lane, st.driveway_or_alley_entrance, st.highway, st.intersection, st.on_way | composable (build) | planned |
| `NRS_484B_127_2` | NRS-484B-127-2 | subject | drv.interaction.overtake_pass, drv.motion.complete_halt, kin.extent, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, ru.aggregate=DEF-NRS-484A-305::truck, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency | composable (build) | planned |
| `NRS_484B_223_3b` | NRS-484B-223-3b | subject | drv.motion.left_turn, kin.path_length, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_turn_lane | composable (build) | planned |
| `NRS_484B_223_3c` | NRS-484B-223-3c | subject | drv.motion.left_turn, kin.path_length, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_turn_lane, st.highway, st.on_way | composable (build) | planned |
| `NRS_484A_450_2` | NRS-484A-450-2 | subject | dev.governs, dev.stop_sign, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484B_223_4b` | NRS-484B-223-4b | subject | drv.motion.right_turn_through_region, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.turn_lane | composable (build) | planned |
| `NRS_484B_213_2a` | NRS-484B-213-2a | subject | kin.position, kin.speed, kin.velocity, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.crest, st.curvature, st.highway, st.on_way, st.one_way_roadway, st.region_geometry, st.sight_distance | composable (build) | planned |
| `NRS_484A_450_3` | NRS-484A-450-3 | subject | dev.governs, dev.yield_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484B_600_1a` | NRS-484B-600-1a | subject | env.darkness, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.extent, kin.speed, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curvature, st.lane, st.lane_width, st.sight_distance | composable (build) | planned |
| `NRS_484B_270_2a_o1` | NRS-484B-270-2a | subject | drv.interaction.overtake_pass, kin.accel_longitudinal, kin.speed, rel.contact, rel.longitudinal_overlap, rel.same_direction, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | composable (build) | planned |
| `NRS_484B_227_1_o3` | NRS-484B-227-1 | subject | drv.motion.left_turn, drv.motion.u_turn, kin.yaw_rate, prim.heading_change, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.median_or_divider, st.on_way | composable (build) | planned |
| `NRS_484B_213_2c` | NRS-484B-213-2c | subject | kin.position, kin.speed, kin.velocity, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.elevated_structure, st.highway, st.on_way, st.one_way_roadway, st.region_geometry, st.sight_distance | composable (build) | planned |
| `NRS_484B_213_2b` | NRS-484B-213-2b | subject | kin.position, kin.velocity, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.highway, st.intersection, st.on_way, st.one_way_roadway, st.railway_crossing, st.region_geometry | composable (build) | planned |
| `NRS_484B_270_2a_o2` | NRS-484B-270-2a | subject | dev.governs, dev.temporary_traffic_control, drv.interaction.overtake_pass, env.ice_or_snow, env.precipitation, env.wet_road, kin.speed, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, st.lane, st.lane_adjacency | composable (build) | planned |
| `NRS_484B_293` | NRS-484B-293 | subject | drv.motion.complete_halt, kin.position, kin.speed, kin.velocity, prim.region_lateral_offset, rel.bearing, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.crosswalk, st.obstruction, st.region_geometry | composable (build) | planned |
| `NRS_484B_250_4_o1` | NRS-484B-250-4 | subject | dev.governs, dev.inoperative, dev.traffic_signal, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `LVMC_11_30_060_B` | LVMC-11-30-060-B | subject | dev.governs, dev.regulatory_sign, drv.motion.moving_across_carrier, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.pedestrian_grade_separation, st.region_geometry, st.roadway | composable (build) | planned |
| `NRS_484B_307_12b` | NRS-484B-307-12b | subject | dev.governs, dev.lane_control_signal, dev.position, drv.motion.complete_halt, kin.heading, kin.position, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.on_way | composable (build) | planned |
| `NRS_484B_307_12a` | NRS-484B-307-12a | subject | dev.governs, dev.lane_control_signal, dev.position, drv.motion.complete_halt, kin.heading, kin.position, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.on_way | composable (build) | planned |
| `NRS_484B_257_1_o1` | NRS-484B-257-1 | subject | dev.governs, dev.human_direction, dev.inoperative, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.speed, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484B_307_5a_o1` | NRS-484B-307-5a | subject | dev.governs, dev.traffic_signal, drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_280_1c` | NRS-484B-280-1c | subject | dev.governs, dev.zone_sign, drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, rel.surface_gap, rel.visible, ru.aggregate=DEF-NRS-484A-030::bus, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.transit_bus, sig.door_open, st.crosswalk, st.highway, st.region_geometry, st.transit_stop, st.travel_region | composable (build) | planned |
| `NRS_484B_213_1` | NRS-484B-213-1 | subject | drv.interaction.overtake_pass, kin.speed, kin.velocity, prim.closest_approach_distance, prim.closest_approach_within, prim.region_lateral_offset, rel.bearing, rel.centre_distance, rel.contact, rel.longitudinal_overlap, rel.occupies, rel.oncoming, rel.same_direction, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.highway, st.lane, st.lane_adjacency, st.on_way, st.sight_distance | composable (build) | planned |
| `LVMC_11_12_070_B` | LVMC-11-12-070-B | subject | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_307_4a_o1` | NRS-484B-307-4a | subject | dev.governs, dev.traffic_signal, drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_307_8e` | NRS-484B-307-8e | subject | dev.governs, dev.traffic_signal, drv.motion.parked, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_enters, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_307_8a_o1` | NRS-484B-307-8a | subject | dev.governs, dev.traffic_signal, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | not composable: replanning | returned |
| `NRS_484B_410_o1` | NRS-484B-410 | subject | dev.governs, dev.regulatory_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.highway, st.travel_region | composable (build) | planned |
| `NRS_484B_410_o2` | NRS-484B-410 | subject | dev.governs, dev.regulatory_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.highway, st.travel_region | composable (build) | planned |
| `NRS_484B_310_1` | NRS-484B-310-1 | subject | dev.governs, dev.traffic_signal, drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484B_413_3` | NRS-484B-413-3 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.accel_longitudinal, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.brake_lamp, sig.hand_signal, st.travel_region | composable (build) | planned |
| `NRS_484B_307_7a_o1` | NRS-484B-307-7a | subject | dev.governs, dev.traffic_signal, drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, kin.speed, kin.yaw_rate, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1g` | NRS-484B-450-1g | subject | dev.governs, dev.human_direction, dev.position, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.extent, kin.heading, kin.position, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_direction, st.lane_enters, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1h` | NRS-484B-450-1h | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.extent, prim.region_lateral_offset, prim.region_offset_along, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.region_geometry, st.road_edge, st.safety_zone, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1m` | NRS-484B-450-1m | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.elevated_structure, st.travel_region | composable (build) | planned |
| `NRS_484B_250_4_o2` | NRS-484B-250-4 | subject | dev.governs, dev.inoperative, dev.traffic_signal, drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1j` | NRS-484B-450-1j | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.fire_station_entrance, st.highway, st.on_way, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1k` | NRS-484B-450-1k | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.obstruction, st.on_way, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_477_1a` | NRS-484B-477-1a | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, drv.motion.parked, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.travel_region | composable (build) | planned |
| `NRS_484B_400_2b` | NRS-484B-400-2b | subject | drv.motion.left_turn_through_region, drv.motion.moving_against_carrier, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane, st.lane_direction, st.median_or_divider, st.on_way, st.roadway | composable (build) | planned |
| `NRS_484B_490` | NRS-484B-490 | subject | dev.governs, dev.zone_sign, drv.motion.parked, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.travel_region | composable (build) | planned |
| `NRS_484B_450_1o` | NRS-484B-450-1o | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.regulatory_sign, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, drv.motion.parked, prim.conditions_hold, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.travel_region | composable (build) | planned |
| `NRS_484B_457_1` | NRS-484B-457-1 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.regulatory_sign, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.heading, prim.conditions_hold, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.lane_direction, st.lane_marking, st.on_way, st.one_way_roadway, st.parking_space, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_497` | NRS-484B-497 | subject | dev.governs, dev.regulatory_sign, dev.zone_sign, drv.motion.parked, kin.heading, prim.conditions_hold, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.lane_direction, st.on_way, st.one_way_roadway, st.parking_space, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_493` | NRS-484B-493 | subject | dev.governs, dev.regulatory_sign, drv.motion.parked, kin.heading, prim.conditions_hold, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.highway, st.lane_direction, st.on_way, st.one_way_roadway, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_500` | NRS-484B-500 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.regulatory_sign, dev.stop_sign, dev.traffic_signal, dev.yield_sign, dev.zone_sign, drv.motion.complete_halt, prim.conditions_hold, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.travel_region | composable (build) | planned |
| `NRS_484B_477_1b` | NRS-484B-477-1b | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.obstruction, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_560_7a` | NRS-484B-560-7a | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.railway_crossing, st.region_geometry | composable (build) | planned |
| `NRS_484B_533` | NRS-484B-533 | subject | drv.motion.complete_halt, kin.engine_running, kin.parking_brake, kin.steer_angle, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.occupant_count, st.grade, st.highway, st.on_way, st.road_edge | composable (build) | planned |
| `NRS_484B_257_1_o2` | NRS-484B-257-1 | subject | dev.governs, dev.human_direction, dev.inoperative, dev.stop_sign, dev.traffic_signal, dev.yield_sign, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_enters, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_557_o1` | NRS-484B-557 | subject | dev.governs, dev.stop_sign, drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.on_way, st.railway_crossing, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_503` | NRS-484B-503 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, dev.zone_sign, drv.motion.complete_halt, drv.motion.parked, prim.conditions_hold, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.door_open, st.curb_zone, st.travel_region | composable (build) | planned |
| `NRS_484B_307_8c` | NRS-484B-307-8c | subject | dev.governs, dev.traffic_signal, drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, prim.region_offset_along, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.median_or_divider, st.on_way, st.one_way_roadway, st.region_geometry, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484D_165_3` | NRS-484D-165-3 | subject | drv.motion.complete_halt, env.darkness, env.visibility, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.position_lamp, st.highway, st.on_way, st.roadway, st.shoulder | composable (build) | planned |
| `NRS_484B_510` | NRS-484B-510 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, dev.zone_sign, drv.motion.complete_halt, drv.motion.parked, prim.conditions_hold, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.trailer_or_combination, ru.truck, sig.door_open, st.curb_zone, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484D_165_4` | NRS-484D-165-4 | subject | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.headlamp | composable (build) | planned |
| `LVMC_11_16_060` | LVMC-11-16-060 | subject | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.travel_region | composable (build) | planned |
| `NRS_484B_560_7b` | NRS-484B-560-7b | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.rail_vehicle, st.railway_crossing, st.region_geometry, st.travel_region | composable (build) | planned |
| `LVMC_11_40_130` | LVMC-11-40-130 | subject | env.darkness, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.speed, ru.aggregate=DEF-NRS-484A-025::bicycle | composable (build) | planned |
| `NRS_484B_627_2` | NRS-484B-627-2 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.accel_longitudinal, prim.closest_approach_distance, prim.closest_approach_within, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roadway, st.travel_region | composable (build) | planned |
| `NRS_484B_507_1` | NRS-484B-507-1 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, dev.zone_sign, drv.motion.complete_halt, drv.motion.parked, prim.conditions_hold, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.commercial_motor_vehicle, ru.truck, sig.door_open, st.curb_zone, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_557_o2` | NRS-484B-557 | subject | dev.governs, dev.stop_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.rail_vehicle, st.highway, st.on_way, st.railway_crossing, st.region_geometry, st.travel_region | composable (build) | planned |
| `LVMC_11_30_050` | LVMC-11-30-050 | subject | drv.motion.moving_across_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.crosswalk, st.lane, st.roadway | composable (build) | planned |
| `LVMC_11_30_070_B` | LVMC-11-30-070-B | subject | drv.motion.moving_across_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.crosswalk, st.lane, st.roadway | composable (build) | planned |
| `LVMC_11_22_010` | LVMC-11-22-010 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.ahead_behind_in_lane, rel.contact, ru.aggregate=DEF-NRS-484A-320::vehicle | composable (build) | planned |
| `LVMC_11_43_010_B_o2` | LVMC-11-43-010-B | subject | prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | composable (build) | planned |
| `LVMC_11_22_020` | LVMC-11-22-020 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | composable (build) | planned |
| `NRS_484B_307_8a_o3` | NRS-484B-307-8a | subject | dev.governs, dev.traffic_signal, drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, prim.region_offset_along, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.median_or_divider, st.on_way, st.one_way_roadway, st.region_geometry, st.stop_line, st.travel_region | not composable: replanning | returned |
| `NRS_484B_777_3` | NRS-484B-777-3 | subject | drv.motion.complete_halt, rel.longitudinal_overlap, rel.occupies, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, st.bicycle_lane_or_path, st.roadway | composable (build) | planned |
| `LVMC_11_20_060_o2` | LVMC-11-20-060 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.driveway_or_alley_entrance, st.sidewalk | composable (build) | planned |
| `NRS_484B_220_1` | NRS-484B-220-1 | subject | drv.motion.moving_against_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.one_way_roadway | composable (build) | planned |
| `NRS_484B_153_3` | NRS-484B-153-3 | subject | ru.aggregate=DEF-NRS-484A-320::vehicle, sig.door_open | composable (build) | planned |
| `LVMC_11_20_060_o3` | LVMC-11-20-060 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.driveway_or_alley_entrance, st.roadway | composable (build) | planned |
| `NRS_484B_777_1_o2` | NRS-484B-777-1 | subject | drv.interaction.overtake_pass, drv.motion.complete_halt, kin.speed, rel.contact, rel.longitudinal_overlap, rel.occupies, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, st.roadway | not composable: replanning | returned |
| `NRS_484B_127_1` | NRS-484B-127-1 | subject | env.ice_or_snow, env.precipitation, env.wet_road, kin.speed, rel.ahead_behind_in_lane, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle | composable (build) | planned |
| `NRS_484B_227_1_o1` | NRS-484B-227-1 | subject | drv.motion.moving_against_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.median_or_divider, st.on_way, st.roadway | composable (build) | planned |
| `NRS_484B_113_2` | NRS-484B-113-2 | subject | drv.motion.moving_backward, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.intersection | composable (build) | planned |
| `LVMC_11_18_020` | LVMC-11-18-020 | subject | dev.governs, dev.zone_sign, prim.region_lateral_offset, rel.bearing, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.bicycle, ru.electric_bicycle, ru.electric_scooter, ru.pedestrian, st.centre_line, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane_enters, st.on_way, st.one_way_roadway, st.travel_region | composable (build) | planned |
| `NRS_484B_227_1_o2` | NRS-484B-227-1 | subject | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.median_or_divider, st.on_way | composable (build) | planned |
| `NRS_484B_270_7a` | NRS-484B-270-7a | subject | kin.accel_longitudinal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.bearing, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | composable (build) | planned |
| `LVMC_11_16_040` | LVMC-11-16-040 | subject | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, kin.path_length, kin.speed, rel.occupies, rel.visible, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_enters, st.on_way, st.region_geometry, st.sight_along_way, st.sight_distance, st.travel_region | composable (build) | planned |
| `NRS_484B_253_o1` | NRS-484B-253 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_direction, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_270_5a` | NRS-484B-270-5a | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | composable (build) | planned |
| `LVMC_11_40_140_o2` | LVMC-11-40-140 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.alley, st.driveway_or_alley_entrance, st.highway, st.region_geometry, st.sidewalk | composable (build) | planned |
| `NRS_484B_267_2b` | NRS-484B-267-2b | subject | dev.governs, dev.human_direction, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.bearing, rel.centre_distance, rel.contact, rel.longitudinal_overlap, rel.occupies, rel.surface_gap, rel.visible, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.official_vehicle, sig.hand_signal, sig.turn_indicator, sig.warning_lamp, st.travel_region | composable (build) | planned |
| `NRS_484B_257_2_o2` | NRS-484B-257-2 | subject | dev.governs, dev.human_direction, dev.inoperative, dev.stop_sign, dev.traffic_signal, dev.yield_sign, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | not composable: replanning | returned |
| `NRS_484B_280_1a` | NRS-484B-280-1a | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-165::pedestrian | composable (build) | planned |
| `NRS_484B_307_2a` | NRS-484B-307-2a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_363_1` | NRS-484B-363-1 | subject | dev.governs, dev.inoperative, dev.speed_limit_beacon, dev.zone_sign, kin.speed, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, st.travel_region | composable (build) | planned |
| `NRS_484B_363_2` | NRS-484B-363-2 | subject | dev.governs, dev.inoperative, dev.speed_limit_beacon, dev.zone_sign, kin.speed, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, st.travel_region | composable (build) | planned |
| `NRS_484B_267_1b_o1` | NRS-484B-267-1b | subject | dev.governs, dev.human_direction, dev.regulatory_sign, kin.heading, kin.speed, kin.time, prim.region_lateral_offset, rel.bearing, rel.centre_distance, rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.official_vehicle, sig.warning_lamp, st.highway, st.intersection, st.lane_direction, st.on_way, st.region_geometry, st.road_edge, st.shoulder, st.travel_region | not composable: operator | blocked |
| `NRS_484B_307_7a_o3` | NRS-484B-307-7a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_307_3a` | NRS-484B-307-3a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_330_1` | NRS-484B-330-1 | subject | dev.governs, dev.human_direction, dev.position, dev.temporary_traffic_control, dev.zone_sign, kin.accel_longitudinal, kin.heading, kin.position, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_307_7a_o2` | NRS-484B-307-7a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_307_4a_o2` | NRS-484B-307-4a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_267_2e` | NRS-484B-267-2e | subject | dev.governs, dev.human_direction, dev.temporary_traffic_control, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.speed, rel.bearing, rel.centre_distance, rel.occupies, rel.surface_gap, rel.visible, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.official_vehicle, sig.hand_signal, sig.turn_indicator, sig.warning_lamp, st.highway, st.lane, st.lane_adjacency, st.lane_direction, st.on_way, st.roadway, st.travel_region | composable (build) | planned |
| `NRS_484B_560_3_o1` | NRS-484B-560-3 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.on_way, st.railway_crossing, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_307_6a` | NRS-484B-307-6a | subject | dev.governs, dev.traffic_signal, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_307_5a_o2` | NRS-484B-307-5a | subject | dev.governs, dev.traffic_signal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_600_1e` | NRS-484B-600-1e | subject | kin.speed, ru.aggregate=DEF-NRS-484A-320::vehicle | composable (build) | planned |
| `NRS_484B_253_o2` | NRS-484B-253 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator, st.intersection, st.lane_direction, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_400_1_o2` | NRS-484B-400-1 | subject | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.roadway, st.turn_lane | composable (build) | planned |
| `NRS_484B_600_1c` | NRS-484B-600-1c | subject | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.travel_region | composable (build) | planned |
| `NRS_484B_587_1` | NRS-484B-587-1 | subject | dev.governs, dev.regulatory_sign, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access, st.travel_region | composable (build) | planned |
| `NRS_484B_400_1_o1` | NRS-484B-400-1 | subject | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane, st.lane_direction, st.lane_enters, st.turn_lane | composable (build) | planned |
| `NRS_484B_403_2` | NRS-484B-403-2 | subject | dev.governs, dev.regulatory_sign, drv.motion.u_turn, kin.yaw_rate, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_633_2` | NRS-484B-633-2 | subject | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.elevated_structure, st.highway, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_620_2` | NRS-484B-620-2 | subject | dev.governs, dev.speed_limit_sign, dev.zone_sign, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, st.highway, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_403_3` | NRS-484B-403-3 | subject | drv.motion.u_turn, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.median_or_divider, st.on_way | composable (build) | planned |
| `NRS_484B_653_1a` | NRS-484B-653-1a | subject | kin.accel_longitudinal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | composable (build) | planned |
| `NRS_484B_407` | NRS-484B-407 | subject | drv.motion.u_turn, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crest, st.curvature, st.region_geometry, st.roadway, st.sight_distance | composable (build) | planned |
| `NRS_484B_363_3` | NRS-484B-363-3 | subject | dev.governs, dev.inoperative, dev.speed_limit_beacon, dev.zone_sign, drv.motion.u_turn, kin.yaw_rate, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.child, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_400_2a` | NRS-484B-400-2a | subject | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.median_or_divider, st.on_way, st.roadway | composable (build) | planned |
| `NRS_484B_627_1b` | NRS-484B-627-1b | subject | dev.governs, dev.speed_limit_sign, kin.speed, rel.ahead_behind_in_lane, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.lane_adjacency, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_486_351_1` | NRS-486-351-1 | subject | rel.bearing, rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle, ru.emergency_vehicle, sig.warning_lamp, st.lane, st.lane_adjacency | composable (build) | planned |
| `NRS_484B_627_1a` | NRS-484B-627-1a | subject | dev.governs, dev.speed_limit_sign, kin.extent, kin.speed, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-285::traffic, st.centre_line, st.highway, st.lane, st.lane_adjacency, st.lane_direction, st.on_way, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_603_1_o2` | NRS-484B-603-1 | subject | env.ice_or_snow, env.precipitation, env.wet_road, kin.accel_longitudinal, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | composable (build) | planned |
| `NRS_484B_603_1_o1` | NRS-484B-603-1 | subject | dev.governs, dev.temporary_traffic_control, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.path_length, kin.position, kin.speed, kin.velocity, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crest, st.curvature, st.highway, st.intersection, st.lane, st.lane_enters, st.lane_width, st.obstruction, st.on_way, st.region_geometry, st.roadway, st.sight_distance, st.travel_region | composable (build) | planned |
| `NRS_484B_785_1a` | NRS-484B-785-1a | subject | kin.speed, rel.occupies, ru.electric_scooter, st.bicycle_lane_or_path, st.roadway | composable (build) | planned |
| `LVMC_11_40_180_A` | LVMC-11-40-180-A | subject | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, st.sidewalk | composable (build) | planned |
| `LVMC_11_43_010_A` | LVMC-11-43-010-A | subject | drv.motion.circulating_clockwise_about, drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | composable (build) | planned |
| `NRS_484B_287_1d` | NRS-484B-287-1d | subject | drv.motion.moving_across_carrier, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.crosswalk, st.intersection, st.lane, st.lane_enters | composable (build) | planned |
| `NRS_484B_203_1_o1` | NRS-484B-203-1 | subject | drv.motion.complete_halt, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.oncoming, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | composable (build) | planned |
| `NRS_484B_413_2` | NRS-484B-413-2 | subject | drv.lane.heading_left_of_carrier, drv.lane.heading_right_of_carrier, kin.path_length, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator, st.lane | composable (build) | planned |
| `LVMC_11_43_010_C1` | LVMC-11-43-010-C1 | subject | drv.motion.left_turn_through_region, drv.motion.u_turn_through_region, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency, st.roundabout | composable (build) | planned |
| `LVMC_11_43_010_B_o1` | LVMC-11-43-010-B | subject | prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | composable (build) | planned |
| `NRS_486_341` | NRS-486-341 | subject | rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle, st.highway, st.lane | composable (build) | planned |
| `NRS_484B_210_3` | NRS-484B-210-3 | subject | drv.interaction.overtake_pass_on_right, kin.velocity, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-320::vehicle, st.road_edge, st.shoulder | composable (build) | planned |
| `NRS_484B_263_o1` | NRS-484B-263 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.bearing, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | composable (build) | planned |
| `NRS_484B_260` | NRS-484B-260 | subject | kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.bearing, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.alley, st.driveway_or_alley_entrance, st.highway, st.on_way, st.roadway, st.travel_region | composable (build) | planned |
| `NRS_484B_270_7b` | NRS-484B-270-7b | subject | drv.interaction.overtake_pass, kin.heading, kin.position, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.longitudinal_overlap, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | composable (build) | planned |
| `LVMC_11_30_060_A` | LVMC-11-30-060-A | subject | dev.governs, dev.regulatory_sign, drv.motion.moving_across_carrier, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.lane, st.roadway | composable (build) | planned |
| `NRS_486_351_2` | NRS-486-351-2 | subject | rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle, ru.aggregate=DEF-NRS-486-057::trimobile, st.lane | composable (build) | planned |
| `NRS_484B_450_1l` | NRS-484B-450-1l | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.on_way, st.region_geometry, st.road_edge, st.travel_region | composable (build) | planned |
| `NRS_484B_223_4a` | NRS-484B-223-4a | subject | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.driveway_or_alley_entrance, st.highway, st.intersection, st.lane_enters, st.on_way, st.turn_lane | composable (build) | planned |
| `NRS_484B_263_o2` | NRS-484B-263 | subject | kin.speed, kin.time, prim.closest_approach_distance, prim.closest_approach_within, rel.bearing, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | composable (build) | planned |
| `NRS_484B_560_3_o2` | NRS-484B-560-3 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane, st.on_way, st.railway_crossing, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_250_1` | NRS-484B-250-1 | subject | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, kin.speed, kin.yaw_rate, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_direction, st.lane_enters, st.on_way, st.travel_region | composable (build) | planned |
| `NRS_484B_587_2b` | NRS-484B-587-2b | subject | dev.governs, dev.regulatory_sign, drv.lane.entering_adjacent_lane, drv.motion.complete_halt, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.emergency_vehicle, ru.motor_vehicle, ru.official_vehicle, ru.transit_bus, sig.hazard, sig.warning_lamp, st.controlled_access, st.highway, st.lane, st.lane_marking, st.on_way, st.shoulder | composable (build) | planned |
| `NRS_484B_517` | NRS-484B-517 | subject | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, drv.motion.parked, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-030::bus, ru.aggregate=DEF-NRS-484A-270::taxicab, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.trailer_or_combination, ru.truck, sig.door_open, st.curb_zone, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_208_1` | NRS-484B-208-1 | subject | dev.governs, dev.human_direction, dev.lane_control_signal, dev.regulatory_sign, dev.speed_limit_sign, dev.temporary_traffic_control, dev.zone_sign, drv.interaction.overtake_pass, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.speed, prim.conditions_hold, prim.region_lateral_offset, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.aggregate=DEF-NRS-484A-460-2::high_occupancy_vehicle, ru.official_vehicle, sig.siren, sig.warning_lamp, st.controlled_access, st.intersection, st.lane, st.lane_adjacency, st.lane_enters, st.obstruction, st.region_geometry, st.reserved_lane, st.travel_region | composable (build) | planned |
| `LVMC_11_40_180_C_o1` | LVMC-11-40-180-C | subject | drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.sidewalk | not composable: planned this iteration, not yet published | planned |
| `LVMC_11_52_030_A` | LVMC-11-52-030-A | subject | dev.governs, dev.human_direction, dev.stop_sign, dev.traffic_signal, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-LVMC-11-02-090::limo, ru.aggregate=DEF-LVMC-11-02-120::rtc_bus, ru.aggregate=DEF-LVMC-11-02-150::shuttle_bus, ru.aggregate=DEF-LVMC-11-02-150::tour_bus, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.emergency_vehicle, ru.official_vehicle, st.curb_zone, st.obstruction, st.region_geometry, st.travel_region | not composable: planned this iteration, not yet published | planned |
| `LVMC_11_52_030_B` | LVMC-11-52-030-B | subject | dev.governs, dev.zone_sign, drv.motion.complete_halt, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-LVMC-11-02-070::commercial_vehicle, ru.aggregate=DEF-LVMC-11-02-140::taxicab, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.travel_region | not composable: planned this iteration, not yet published | planned |
| `LVMC_11_52_300` | LVMC-11-52-300 | subject | drv.motion.parked, env.civil_time, kin.time, rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_217_2` | NRS-484B-217-2 | subject | dev.governs, dev.zone_sign, kin.extent, prim.closest_approach_distance, prim.closest_approach_within, prim.region_lateral_offset, rel.bearing, rel.contact, rel.occupies, rel.oncoming, rel.same_direction, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator, st.centre_line, st.driveway_or_alley_entrance, st.highway, st.intersection, st.lane, st.lane_marking, st.on_way, st.travel_region | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_257_2_o1` | NRS-484B-257-2 | subject | dev.governs, dev.human_direction, dev.inoperative, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, kin.speed, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_267_2a` | NRS-484B-267-2a | subject | dev.governs, dev.human_direction, kin.accel_longitudinal, kin.speed, rel.bearing, rel.centre_distance, rel.longitudinal_overlap, rel.occupies, rel.visible, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.official_vehicle, sig.hand_signal, sig.turn_indicator, sig.warning_lamp, st.travel_region | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_270_2b_o1` | NRS-484B-270-2b | subject | drv.interaction.overtake_pass, kin.accel_longitudinal, kin.speed, rel.contact, rel.longitudinal_overlap, rel.same_direction, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_270_2b_o2` | NRS-484B-270-2b | subject | drv.interaction.overtake_pass, kin.speed, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, st.lane, st.lane_adjacency | not composable: planned this iteration, not yet published | planned |
| `NRS_484B_270_2b_o3` | NRS-484B-270-2b | subject | drv.interaction.overtake_pass, drv.lane.heading_right_of_carrier, env.ice_or_snow, env.precipitation, env.wet_road, kin.speed, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, st.lane, st.lane_adjacency | not composable: planned this iteration, not yet published | planned |

### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)
`callers in a current plan` counts the accepted nodes, this run's and its base run's, that call the concept directly and are current: not fenced, and listed in their law's current plan (a node of a law this run does not plan is its base run's current record). A fenced node, an accepted node its law's current plan no longer lists, and a node of a law being planned again or waiting for the operator are not counted.

| id | kind | contract | definition | args | params | reads | calls | callers in a current plan |
|---|---|---|---|---|---|---|---|---|
| `drv.interaction.overtake_pass` | formula | Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame, the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position), is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window. Where the positions of a and b are unobserved, it is unknown. **Review notes (not confirmed differences):** Tested a pass recognized one second after the recording begins, within a two-second window. The observed aligned-ahead and first-behind observations suffice: the body holds, agreeing with the contract despite the truncated history. |  | a:track, b:track | window (s), same_dir_cos (ratio) | kin.heading, kin.position, kin.time, rel.longitudinal_overlap, rel.same_direction | no concept | 7 |
| `drv.interaction.overtake_pass_on_right` | formula | Road user a overtakes and passes road user b on b's right: a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance, and makes the passage with b on its left. b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive; the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero). b is ahead of a where the longitudinal component, along a's heading (kin.heading), of the vector from a's position to b's position (kin.position) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); their headings are aligned where the cosine of the angle between them is above same_dir_cos (rel.same_direction). The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos. The act is recognized at the observation at which drv.interaction.overtake_pass holds for a and b, where b is on a's left there and at every observation since the act began at which the two are side by side. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users and the side on which a passes only: it says nothing of the lanes or the pavement a uses, of whether b moves, or of why a passes. Not denoted: a pass with b on a's right at the recognition or at some observation at which the two are side by side, which is a pass on b's left; a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned. Where b's bearing, the positions or headings of a and b, or the overlap of the two bodies is unobserved at an observation the passage reads, it is unknown. **Review notes (not confirmed differences):** Tested a one-second right-side pass with window = 2 s and a recording beginning at its aligned-ahead onset. The body holds at recognition despite the shorter recording, agreeing with the contract; this is not a divergence. |  | a:track, b:track | window (s), same_dir_cos (ratio) | kin.heading, kin.position, kin.time, rel.bearing, rel.longitudinal_overlap, rel.same_direction | `drv.interaction.overtake_pass` | 1 |
| `drv.lane.entering_adjacent_lane` | formula | Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The event is recognized at the first observation at which a's footprint overlaps r2, and conduct before the previous observation is not read. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, where there is no previous observation, or where the adjacency of the two lanes is not observed, it is unknown. |  | a:track, r1:region, r2:region, s:literal['left', 'right'] |  | rel.occupies, st.lane_adjacency | no concept | 2 |
| `drv.lane.heading_left_of_carrier` | formula | Road user a, moving, points to the left of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the left. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is above sin_tol, so that h lies to the left of d, counter-clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its right; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown. |  | a:track, r:region | sin_tol (ratio), speed_tol (m/s) | kin.heading, kin.speed, st.lane_direction | no concept | 1 |
| `drv.lane.heading_right_of_carrier` | formula | Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown. |  | a:track, r:region | sin_tol (ratio), speed_tol (m/s) | kin.heading, kin.speed, st.lane_direction | no concept | 1 |
| `drv.motion.circulating_clockwise_about` | formula | Road user a travels clockwise about the reference point of region r, as seen from above: the point lies to the right of a's direction of travel and a's velocity turns about it clockwise. It is observed with a's position (kin.position), a's velocity (kin.velocity), a's speed (kin.speed) and r's reference point (st.region_geometry), in the world frame, in which a turn to the left is counter-clockwise (the frame of kin.yaw_rate): with d the vector from r's reference point to a's position, the cross product of d with a's velocity is negative, and its square exceeds sin_tol squared times the squared length of d times the square of a's speed, so that the share of a's motion that turns about the point is above sin_tol; and a's speed is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of the path a followed before, or of why a moves so. Not denoted: a road user at rest or moving at or below speed_tol; one travelling counter-clockwise about the point; one moving towards or away from the point within the angle sin_tol allows; one at the point itself. Where r's reference point, a's position or a's velocity is unobserved, it is unknown. |  | a:track, r:region | speed_tol (m/s), sin_tol (ratio) | kin.position, kin.speed, kin.velocity, st.region_geometry | no concept | 2 |
| `drv.motion.complete_halt` | formula | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. | DEF-NRS-484A-255 | a:track | speed_tol (m/s) | kin.speed | no concept | 57 |
| `drv.motion.left_turn` | formula | Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown. **Review notes (not confirmed differences):** dismissed: divergence 1 (holds_wrongly) at t=6000 ms: A continuous leftward turn is already under way at t=0 and is still under way at t=4000 ms; the first stopped observation is t=6000 ms. The act began before the … — contract: fails, body: holds; contract: "The act begins within the window behind the observation at which it is recognized." — The contract says conduct before the window is not read, and states the recognition condition in terms of the window alone. In the executed facts that condition holds at t=6000 ms and did not hold at t=4000 ms: yaw rate 30 deg/s at 2000 and 4000 ms gives an in-band heading change, then yaw rate 0 at 6000 ms. A reasonable reading therefore treats the recognized act as the turning within the window, so it begins there, and gives the body's verdict. — "Conduct before the window behind is not read" |  | a:track | window (s), turn_min (deg), u_turn_min (deg), yaw_tol (deg/s) | kin.yaw_rate | no concept | 4 |
| `drv.motion.left_turn_through_region` | formula | Road user a has made a turn to the left through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from turn_min inclusive to u_turn_min exclusive, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is below turn_min, such as one straight through or a turn to the right; a heading change of u_turn_min or more, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. **Review notes (not confirmed differences):** The body agreed with the contract on both tested passages: a fully observed 90-degree left turn and the same entry-to-exit change preceded by a right turn before entry. Neither test established a defect. |  | a:track, r:region | step (s), turn_min (deg), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept | 5 |
| `drv.motion.moving_across_carrier` | formula | Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown. **Review notes (not confirmed differences):** dismissed: divergence 1 (fails_wrongly) at t=0 ms: The road user's velocity [-2.4, 14.3] has magnitude 14.5 m/s and absolute cosine exactly 0.6 with carrier direction [20, 21], meeting the inclusive threshold. … — contract: holds, body: fails; contract: "a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction …" — The contract states its test as a dot product with "the normalised direction", and the atom contract for st.lane_direction defines that reading: the vector is the unit vector times a factor of at least 1, exactly the unit vector only where the scaled length is a whole number of micrometres. For [20, 21] that length is 29/21, which is not a whole number of micrometres, so the read vector is slightly longer than the unit vector. Under that disclosed reading, the dot product at this exact boundary (8.7 against 0.6 × 14.5) slightly exceeds cos_max times the speed, which gives the body's verdict. — "the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed" |  | a:track, r:region | speed_tol (m/s), cos_max (ratio) | kin.speed, kin.velocity, st.lane_direction | no concept | 7 |
| `drv.motion.moving_against_carrier` | formula | Road user a moves against the designated direction of travel of carrier region r: part of its motion runs opposite to r's designated direction. It is observed as the component of a's velocity (kin.velocity) along r's designated direction (st.lane_direction), the dot product of the velocity with the direction as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against r's direction exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of whether a occupies r, of where a's body points, of the gear selected, of how long a has moved so, or of why. Not denoted: a road user at rest; one whose velocity component against r's direction is at or below speed_tol, such as one moving along r's direction or straight across it. Where r carries no designated direction, or a's velocity is unobserved, it is unknown. |  | a:track, r:region | speed_tol (m/s) | kin.velocity, st.lane_direction | no concept | 3 |
| `drv.motion.moving_backward` | formula | Road user a is moving backward: it moves against the direction its body points. It is observed as the component of a's velocity (kin.velocity) along a's heading (kin.heading), the dot product of the velocity with the heading as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against its heading exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of the gear selected, of the path a has followed or will follow, of where a is, or of why it moves so. Not denoted: a road user at rest, or one whose velocity component against its heading is at or below speed_tol; a road user moving forward. Where a's velocity or heading is unobserved, it is unknown. |  | a:track | speed_tol (m/s) | kin.heading, kin.velocity | no concept | 2 |
| `drv.motion.parked` | formula | Road user a is parked: "the standing of a vehicle, whether occupied or not", observed as a at rest at every observation of the window behind the observation, of length min_duration: at each of them a's speed (kin.speed, read through drv.motion.complete_halt) is at or below speed_tol. A halt shorter than min_duration, which may be the temporary halt the definition leaves out, is not denoted. It denotes a state at one observation: it says nothing of whether a rider is on a, of where a stands, or of why it stands. Not denoted: a road user whose speed was above speed_tol at some observation of that window. Where the window reaches before the start of the recording or a speed in it is unobserved, it is unknown. **Review notes (not confirmed differences):** The harness requires consecutive observations in a look-back window to be at most half the window's length apart. The contract states no sampling-gap limit, but the harness rejected the sparse-window example as incomplete, so no divergence was confirmed.; The boundary test agreed with the contract: a speed above tolerance exactly min_duration before the current observation makes the body fail. | DEF-NRS-484A-155 | a:track | speed_tol (m/s), min_duration (s) | kin.speed, kin.time | `drv.motion.complete_halt` | 17 |
| `drv.motion.right_turn_through_region` | formula | Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |  | a:track, r:region | step (s), turn_min (deg), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept | 6 |
| `drv.motion.u_turn` | formula | Road user a has turned "so as to proceed in the opposite direction": its heading has reversed, "whether accomplished by one continuous movement or not". The magnitude of its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them, is denoted where its integrated heading change lies in the band. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the magnitude of the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a reversal that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the way on which a turns, of its class, of its speed, or of why it turns. Not denoted: a heading change smaller than u_turn_min, such as a turn to the left or the right; a full loop, whose heading change exceeds 360 degrees minus u_turn_min; a reversal still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown. | DEF-NRS-484B-077 | a:track | window (s), u_turn_min (deg), yaw_tol (deg/s) | kin.yaw_rate | no concept | 5 |
| `drv.motion.u_turn_through_region` | formula | Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. **Review notes (not confirmed differences):** A tested 180-degree passage lasting longer than step, with every sampling interval equal to step, holds in both the contract and the body; step does not limit the total passage duration.; A tested 180-degree turn completed at entry, followed by zero heading change through exit, fails in both the contract and the body; the pre-entry turn is not counted. | DEF-NRS-484B-077 | a:track, r:region | step (s), u_turn_min (deg) | kin.time, kin.yaw_rate, rel.occupies | no concept | 4 |

Concept families (the fixed grammar `drv.<family>.<name>`): motion, position, lane, interaction, road, control, user, env.

| words | atoms | node |
|---|---|---|
| (1) on or near a highway, street or road; | rel.occupies, st.highway, st.region_geometry | NRS_484B_280_1c |
| (1) overtaking another vehicle proceeding in the same direction; | drv.interaction.overtake_pass, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_208_1 |
| (2) at or near a bus stop or bench, shelter or transit stop for passengers of public mass transporta | rel.occupies, st.region_geometry, st.transit_stop | NRS_484B_280_1c |
| (3) traveling in a lane designated for the use of high-occupancy vehicles pursuant to nrs 484a.460, | rel.occupies, st.reserved_lane | NRS_484B_208_1 |
| (a) an authorized emergency vehicle described in nrs 484a.480; | ru.emergency_vehicle | NRS_484B_587_2b |
| (a) when there are no children present; | dev.governs, dev.zone_sign, ru.child, st.region_geometry, st.travel_region | NRS_484B_363_3 |
| (b) a vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant  | ru.emergency_vehicle | NRS_484B_587_2b |
| (b) when traffic conditions, inclement weather, obstructions or hazards | env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.lane, st.lane_adjacency, st.obstruction, st.region_geometry | NRS_484B_208_1 |
| (c) a traffic incident management vehicle; | ru.official_vehicle | NRS_484B_587_2b |
| (c) if the zone is designated by an operational speed limit beacon, | dev.governs, dev.inoperative, dev.speed_limit_beacon, st.travel_region | NRS_484B_363_2 |
| (c) when compliance with an official traffic control device or the directions given by a peace offic | dev.governs, dev.human_direction, dev.lane_control_signal, dev.regulatory_sign, dev.temporary_traffic_control, rel.occupies, st.lane, st.lane_adjacency | NRS_484B_208_1 |
| (d) a tow car; | ru.motor_vehicle, ru.official_vehicle | NRS_484B_587_2b |
| (d) if the zone is designated by an operational speed limit beacon, | dev.governs, dev.inoperative, dev.speed_limit_beacon, st.travel_region | NRS_484B_363_3 |
| (d) to the driver of an authorized emergency vehicle in the course of his or her official duties. | ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, sig.siren, sig.warning_lamp | NRS_484B_208_1 |
| (e) a coroner vehicle; | ru.official_vehicle | NRS_484B_587_2b |
| (e) to a driver operating a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_208_1 |
| a bicycle | ru.aggregate=DEF-NRS-484A-025::bicycle | LVMC_11_40_130 |
| a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_2a_o2 |
| a bicycle, an electric bicycle or an electric scooter. | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_5a |
| a bicycle, electric bicycle, or electric scooter | ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle | LVMC_11_40_180_A |
| a bus or other public transportation vehicle; | ru.aggregate=DEF-NRS-484A-030::bus, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.transit_bus | NRS_484B_280_1c |
| a downward-pointing green arrow means that | dev.governs, dev.lane_control_signal, st.lane | NRS_484B_307_12a |
| a driver | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_603_1_o1 |
| a driver facing the signal | dev.position, kin.heading, kin.position | NRS_484B_307_12a |
| a driver may not continue to operate a motor vehicle in the extreme left lane | rel.occupies, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, st.lane, st.lane_adjacency | NRS_484B_208_1 |
| a driver of a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_280_1a |
| a pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_287_1d |
| a pedestrian: | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_280_1c |
| a person | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_450_1l |
| a person driving a vehicle described in | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_587_2b |
| a person shall not drive a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_363_2 |
| a person shall not drive a motorcycle, moped or trimobile | ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle, ru.aggregate=DEF-NRS-486-057::trimobile | NRS_486_351_2 |
| a person shall not drive a vehicle | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_587_2b |
| a person shall not stand or park a vehicle | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_497 |
| a person shall not stop, stand or park a vehicle | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.travel_region | NRS_484B_517 |
| a person wholly or partially blind, carrying a cane or walking stick white in color, or white tipped | ru.pedestrian_with_white_cane_or_guide_animal | LVMC_11_30_140_B_o2 |
| a person, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_410_o2 |
| a rate of speed greater than | kin.speed | NRS_484B_600_1c |
| a rate of speed greater than 80 miles per hour. | kin.speed | NRS_484B_600_1e |
| a red “x” symbol means | dev.lane_control_signal | NRS_484B_307_12b |
| a school pedestrian lane | prim.region_offset_along, st.crosswalk, st.highway, st.on_way | LVMC_11_46_030_o1 |
| a signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall | ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator | NRS_484B_413_2 |
| a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_407 |
| a vehicle must: | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_223_4a |
| a vehicle of any kind or character | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_600_1c |
| about to enter or cross a highway | kin.speed, rel.occupies, st.highway, st.on_way, st.roadway | NRS_484B_260 |
| about to enter or exit a controlled-access highway | kin.speed, rel.occupies, st.controlled_access | NRS_484B_263_o2 |
| abreast of or overtake or pass another vehicle within the same traffic lane. | rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane | NRS_486_351_2 |
| across any solid white line that separates an entrance or exit lane from a marked traffic lane. | dev.governs, dev.regulatory_sign, drv.lane.entering_adjacent_lane, st.lane, st.lane_marking | NRS_484B_587_2b |
| adjacent to a roadway | st.highway, st.on_way, st.roadway | LVMC_11_40_120 |
| after complying with | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484B_307_8c |
| after complying with the requirement to stop, | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484B_307_8a_o3 |
| after entering the intersection, the left turn must be made so as to leave the intersection to the r | drv.motion.left_turn_through_region, drv.motion.moving_against_carrier, rel.occupies, st.intersection, st.lane | NRS_484B_400_2b |
| after making a left-hand turn onto the highway | drv.motion.left_turn, rel.occupies, st.highway, st.on_way | NRS_484B_223_3c |
| after the establishment of a speed zone and the installation of appropriate signs to control speed, | dev.governs, dev.speed_limit_sign, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_620_2 |
| all vehicular travel | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_43_010_A |
| alley | rel.occupies, st.alley | NRS_484B_477_1b |
| alongside or opposite any highway excavation or obstruction | prim.region_lateral_offset, rel.occupies, st.highway, st.obstruction, st.on_way, st.region_geometry | NRS_484B_450_1k |
| an authorized emergency vehicle | ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle | NRS_484B_267_1b_o1 |
| an electric scooter | ru.electric_scooter | NRS_484B_785_1a |
| and a person shall not drive another motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_486_341 |
| and afterward may proceed only | rel.occupies, st.railway_crossing | NRS_484B_557_o2 |
| and clear of any intersection. | rel.occupies, st.intersection | NRS_484B_267_1b_o1 |
| and erect official traffic-control devices at such crossings directing a stop. | dev.stop_sign | NRS_484B_557_o2 |
| and for the purpose of and while actually engaged in | drv.motion.complete_halt | NRS_484B_517 |
| and having given a signal when and as required, | sig.hand_signal, sig.turn_indicator | NRS_484B_253_o2 |
| and in the speed zone | dev.governs, dev.zone_sign, rel.occupies, st.highway, st.on_way, st.travel_region | NRS_484B_620_2 |
| and is being overtaken in that lane from the rear by a motor vehicle traveling at a higher rate of s | kin.speed, rel.ahead_behind_in_lane, ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_208_1 |
| and is free of oncoming traffic | rel.centre_distance, rel.oncoming, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_213_1 |
| and it is further declared unlawful to proceed | drv.motion.complete_halt | LVMC_11_46_030_o2 |
| and making use of flashing lights meeting the requirements of | sig.warning_lamp | NRS_484B_267_2e |
| and must not be driven over, across or within any dividing space, barrier or section | rel.occupies, st.median_or_divider | NRS_484B_227_1_o2 |
| and not less than the last 300 feet traveled | kin.path_length | NRS_484B_413_2 |
| and of any traffic upon all of the streets or highways entering such intersection | rel.occupies, rel.visible, ru.aggregate=DEF-NRS-484A-285::traffic, st.highway, st.on_way, st.region_geometry | LVMC_11_16_040 |
| and shall cause or permit suitable signs stating such maximum speed to be erected and maintained | dev.governs, dev.speed_limit_sign | NRS_484B_633_2 |
| and shall continue to yield the right-of-way to that traffic | kin.speed, kin.time, rel.contact, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_263_o2 |
| and shall give audible signal | sig.horn, sig.siren | LVMC_11_40_180_C_o2 |
| and shall provide signage or other markings to indicate where such parking is permitted. | dev.governs, dev.regulatory_sign, rel.occupies, st.parking_space, st.travel_region | LVMC_11_52_070 |
| and speed must be decreased | kin.accel_longitudinal, kin.speed | NRS_484B_603_1_o2 |
| and take such precautions before proceeding | drv.motion.complete_halt | LVMC_11_30_140_B_o2 |
| and the drivers of all other vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_253_o2 |
| and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that  | dev.speed_limit_beacon | NRS_484B_363_3 |
| and there is insufficient light to reveal any person or object within a distance of 1,000 feet upon  | env.darkness, env.visibility | NRS_484D_165_3 |
| and to other traffic | ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_307_4a_o2 |
| and to pedestrians | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_307_5a_o2 |
| and wait | rel.occupies, st.roundabout | LVMC_11_43_010_B_o2 |
| and which are within the intersection | rel.occupies, st.intersection | NRS_484B_257_2_o2 |
| and yield | kin.speed, rel.contact | NRS_484B_307_7a_o3 |
| and, on the side of a highway opposite the entrance to any fire station, | prim.region_lateral_offset, rel.occupies, st.fire_station_entrance, st.highway, st.on_way, st.road_edge | NRS_484B_450_1j |
| any bus or taxicab | ru.aggregate=DEF-NRS-484A-030::bus, ru.aggregate=DEF-NRS-484A-270::taxicab | NRS_484B_517 |
| any cab, | ru.taxicab | LVMC_11_60_090 |
| any lighted headlamps | sig.headlamp | NRS_484D_165_4 |
| any motor vehicle used for the transportation of materials | ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.truck | NRS_484B_507_1 |
| any pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_30_060_B |
| any pedestrian who is not wholly or partially blind | ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.pedestrian_with_white_cane_or_guide_animal | LVMC_11_30_140_B_o2 |
| any person | ru.bicycle, ru.electric_bicycle, ru.electric_scooter, ru.pedestrian | LVMC_11_18_020 |
| any vehicle which is waiting to enter or about to enter the zone | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curb_zone, st.region_geometry | NRS_484B_510 |
| approaching a stop intersection indicated by a stop sign | dev.governs, dev.stop_sign, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484A_450_2 |
| approaching a yield sign | dev.governs, dev.yield_sign, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484A_450_3 |
| approaching an intersection | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_250_1 |
| approaching from the rear shall not overtake and pass such stopped vehicle | drv.interaction.overtake_pass | LVMC_11_30_030 |
| approaching the intersection | rel.occupies, st.intersection, st.lane_enters, st.travel_region | LVMC_11_12_070_B |
| approaching the intersection from the opposite direction | rel.occupies, st.intersection, st.lane_direction, st.lane_enters, st.travel_region | NRS_484B_253_o2 |
| as used in this section, “completely cross” means to travel across a railroad track or tracks in suc | st.railway_crossing, st.region_geometry | NRS_484B_560_7a |
| as used in this section, “preparing to move” means any indication that is visible to an approaching  | kin.speed, rel.visible, sig.hand_signal, sig.turn_indicator | NRS_484B_267_2e |
| as used in this section, “speed limit beacon” means a device which is used in conjunction with a sig | dev.speed_limit_beacon | NRS_484B_363_3 |
| at a place marked as a freight curb loading zone | rel.occupies, st.curb_zone | NRS_484B_507_1 |
| at a point where a pedestrian tunnel or overhead pedestrian crossing has been provided | st.pedestrian_grade_separation, st.region_geometry | LVMC_11_30_060_B |
| at a railroad crossing | st.railway_crossing, st.region_geometry | NRS_484B_560_3_o2 |
| at a railroad crossing. | rel.occupies, st.railway_crossing | NRS_484B_560_7b |
| at a speed greater than | kin.speed | LVMC_11_40_130 |
| at a speed in excess of 15 miles per hour | kin.speed | NRS_484B_363_1 |
| at a speed in excess of 25 miles per hour | kin.speed | NRS_484B_363_2 |
| at a speed of not more than 15 miles per hour. | kin.speed | NRS_484B_785_1a |
| at a speed which is greater than the maximum speed which can be maintained with safety to the bridge | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, st.travel_region | NRS_484B_633_2 |
| at an intersection and: | rel.occupies, st.intersection, st.lane, st.lane_enters, st.roadway | NRS_484B_400_2a |
| at an intersection; | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_208_1 |
| at any place other than by a route at right angles to the curb or by the shortest route to the oppos | drv.motion.moving_across_carrier | LVMC_11_30_050 |
| at any place where official traffic-control devices prohibit stopping, standing or parking. | dev.governs, dev.regulatory_sign, drv.motion.complete_halt, drv.motion.parked, prim.conditions_hold, rel.occupies, st.curb_zone, st.travel_region | NRS_484B_450_1o |
| at any point other than within a marked crosswalk or within an unmarked crosswalk at an intersection | rel.occupies, st.crosswalk | LVMC_11_30_060_A |
| at the edge of or curb of a highway. | st.highway, st.on_way, st.region_geometry, st.road_edge | NRS_484B_450_1l |
| at the first street intersection after it leaves such stand. | rel.occupies, st.curb_zone, st.intersection | LVMC_11_60_090 |
| at the time the signal is exhibited. | dev.traffic_signal | NRS_484B_307_3a |
| attempting to cross the street | rel.occupies, st.crosswalk | LVMC_11_18_020 |
| be driven in the right turn lane | rel.occupies, st.driveway_or_alley_entrance, st.highway, st.intersection, st.lane_enters, st.on_way, st.turn_lane | NRS_484B_223_4a |
| be operated no more than two abreast in a single traffic lane. | rel.longitudinal_overlap, rel.occupies, st.lane | NRS_486_351_2 |
| before entering | rel.occupies, st.roundabout | LVMC_11_43_010_B_o2 |
| before entering the intersection. | rel.occupies, st.intersection | NRS_484A_450_2 |
| before making a left-hand turn from the highway. | drv.motion.left_turn, rel.occupies, st.centre_turn_lane | NRS_484B_223_3b |
| before merging with traffic. | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.centre_turn_lane | NRS_484B_223_3c |
| before overtaking and passing | drv.interaction.overtake_pass, rel.bearing, rel.longitudinal_overlap, rel.same_direction | LVMC_11_40_180_C_o2 |
| between a safety zone and the adjacent curb | prim.region_lateral_offset, rel.occupies, st.region_geometry, st.road_edge, st.safety_zone | NRS_484B_450_1h |
| between moving or stationary vehicles occupying adjacent traffic lanes. | rel.bearing, rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency | NRS_486_351_1 |
| both intersecting highways are two-directional: | st.highway, st.intersection, st.lane, st.lane_direction, st.median_or_divider, st.on_way, st.roadway | NRS_484B_400_2a |
| both the approach for the right turn and the right turn must be made from the right turn lane | rel.occupies, st.intersection, st.lane_enters, st.turn_lane | NRS_484B_400_1_o1 |
| but is inoperative at the time the vehicle enters the intersection, | dev.inoperative | NRS_484B_250_4_o2 |
| but must yield | kin.speed, rel.contact | NRS_484B_307_8a_o3 |
| but the traffic | ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_307_4a_o2 |
| but this shall not prevent a truck or combination of vehicles from overtaking and passing any vehicl | drv.interaction.overtake_pass, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_127_2 |
| come to a full stop | drv.motion.complete_halt | LVMC_11_30_140_B_o1 |
| controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, | dev.governs, dev.traffic_signal | NRS_484B_250_4_o2 |
| crossing a roadway | drv.motion.moving_across_carrier, rel.occupies, st.lane, st.roadway | LVMC_11_30_060_A |
| does not have a clear and unobstructed view of such intersection | st.intersection, st.region_geometry, st.sight_distance | LVMC_11_16_040 |
| does not relieve | kin.speed | NRS_484B_603_1_o1 |
| drive a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_653_1a |
| drive in a lane that is not adjacent to the lane in which the authorized emergency vehicle or offici | rel.occupies, st.lane, st.lane_adjacency, st.lane_direction, st.roadway | NRS_484B_267_2e |
| drive in the extreme right-hand lane | rel.occupies, st.lane, st.lane_adjacency | NRS_484B_627_1b |
| drive to a position parallel to, and | kin.heading, rel.occupies, st.lane_direction, st.travel_region | NRS_484B_267_1b_o1 |
| drive to the extreme right side of the highway | kin.extent, prim.region_lateral_offset, rel.occupies, st.highway, st.on_way, st.region_geometry, st.road_edge | NRS_484B_627_1a |
| driven upon a divided highway | rel.occupies, st.highway, st.median_or_divider, st.on_way | NRS_484B_227_1_o2 |
| drivers of vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_310_1 |
| drivers of vehicles proceeding in opposite directions | drv.motion.complete_halt, rel.oncoming, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_203_1_o1 |
| drivers of vehicles, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_307_12a |
| drives or operates a motor vehicle | kin.speed, ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_627_1a |
| driving onto a sidewalk or onto the sidewalk area extending across any alleyway or driveway | rel.occupies, st.sidewalk | LVMC_11_20_060_o2 |
| driving onto a sidewalk or onto the sidewalk area extending across any alleyway, driveway or buildin | rel.occupies, st.region_geometry, st.sidewalk | LVMC_11_40_140_o2 |
| due to insufficient: (1) space for the vehicle on the opposite side of the railroad crossing; or (2) | drv.motion.complete_halt | NRS_484B_560_7a |
| during hours when the provisions applicable to such zones are in effect. | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | NRS_484B_507_1 |
| during hours when the regulations applicable to such passenger curb loading zone are effective. | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | NRS_484B_503 |
| during not less than the last 100 feet traveled | kin.path_length | NRS_484B_413_2 |
| during the time such driver is moving across or within the intersection. | kin.speed, rel.occupies, st.intersection | NRS_484B_257_2_o2 |
| during the times mentioned | env.darkness, env.visibility | NRS_484D_165_3 |
| during the times when the sign designating the school zone indicates that the speed limit is not in  | dev.zone_sign, prim.conditions_hold | NRS_484B_363_2 |
| during the times when the sign designating the school zone or school crossing zone indicates that th | dev.zone_sign, prim.conditions_hold | NRS_484B_363_3 |
| each driver shall give to the other at least one-half of the paved portion of the highway | kin.extent, prim.closest_approach_within, prim.region_lateral_offset, rel.longitudinal_overlap, st.centre_line, st.on_way | NRS_484B_203_1_o2 |
| emerging or entering an alley, driveway or building | rel.occupies, st.alley, st.driveway_or_alley_entrance | LVMC_11_20_060_o3 |
| enter the intersection only to make the movement indicated by the arrow signal, | dev.traffic_signal, drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, rel.occupies, st.intersection | NRS_484B_307_7a_o1 |
| entering a roundabout | rel.occupies, st.roundabout | LVMC_11_43_010_B_o1 |
| entering into or emerging from an alley, driveway or building | rel.occupies, st.alley, st.driveway_or_alley_entrance, st.highway | LVMC_11_40_140_o2 |
| enters an intersection | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_250_4_o2 |
| every driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484A_450_2 |
| every motorcycle or moped | ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle | NRS_486_341 |
| every pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_30_060_A |
| every person operating a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_777_1_o2 |
| every vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_227_1_o2 |
| except a police officer in the performance of his or her duty, | ru.emergency_vehicle, sig.warning_lamp | NRS_486_351_1 |
| except as otherwise provided in this chapter: | dev.governs, dev.regulatory_sign, rel.occupies, st.travel_region | LVMC_11_52_040_A |
| except as otherwise provided in this paragraph, | dev.governs, dev.regulatory_sign, rel.occupies, st.shoulder | NRS_484B_267_1b_o1 |
| except at an intersection | rel.occupies, st.intersection | NRS_484B_403_3 |
| except at those entrances and exits which are indicated by such devices. | dev.governs, dev.regulatory_sign, rel.occupies, st.travel_region | NRS_484B_587_1 |
| except if required by an emergency | ru.emergency_vehicle, sig.hazard, sig.warning_lamp | NRS_484B_587_2b |
| except in a crosswalk | rel.occupies, st.crosswalk | LVMC_11_30_050 |
| except on a through street or highway | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, rel.occupies, st.lane_enters, st.travel_region | LVMC_11_16_040 |
| except on paths or parts of roadways set aside for the exclusive use of bicycles, electric bicycles  | rel.occupies, st.bicycle_lane_or_path | NRS_484B_777_3 |
| except that a driver of a passenger vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle, ru.trailer_or_combination, ru.truck | NRS_484B_510 |
| except that the driver of a passenger vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle, ru.trailer_or_combination, ru.truck | NRS_484B_517 |
| except through an opening in the barrier or dividing section or space | rel.occupies, st.median_or_divider | NRS_484B_227_1_o2 |
| except when otherwise directed by a law enforcement officer: | dev.governs, dev.human_direction, rel.occupies, st.travel_region | NRS_484B_267_2e |
| except when stopping, standing or parking where no parking is permitted, | dev.governs, dev.regulatory_sign, drv.motion.complete_halt, prim.conditions_hold, rel.occupies, st.curb_zone, st.travel_region | NRS_484B_410_o2 |
| except when traffic is being controlled by a police officer | dev.governs, dev.human_direction, ru.aggregate=DEF-NRS-484A-285::traffic, st.travel_region | NRS_484B_257_2_o2 |
| for a distance of one hundred feet along all such streets or highways | st.highway, st.on_way, st.sight_along_way | LVMC_11_16_040 |
| for safe operation | prim.closest_approach_distance, prim.closest_approach_within, rel.ahead_behind_in_lane, rel.surface_gap | NRS_484B_627_2 |
| for the particular portion of highway being traversed. | dev.governs, rel.occupies, st.travel_region | NRS_484B_600_1c |
| for the purpose of and while actually engaged in loading or unloading of passengers | drv.motion.complete_halt, sig.door_open | NRS_484B_510 |
| for the purpose of and while actually engaged in loading or unloading passengers, | drv.motion.complete_halt, sig.door_open | NRS_484B_507_1 |
| for the purpose of parking in accordance with the purpose to which parking is restricted. | dev.governs, dev.zone_sign, prim.conditions_hold, st.travel_region | NRS_484B_510 |
| from a different highway. | rel.occupies, st.highway, st.lane_enters, st.on_way, st.travel_region | NRS_484B_250_1 |
| from a private way | rel.occupies, st.alley, st.driveway_or_alley_entrance | NRS_484B_260 |
| from one truck route to another | dev.governs, dev.regulatory_sign, rel.occupies, ru.aggregate=DEF-NRS-484A-305::truck, st.highway, st.on_way, st.travel_region | LVMC_11_48_060 |
| having so yielded | drv.motion.complete_halt, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.contact, rel.occupies, st.intersection | LVMC_11_12_070_B |
| if a highway has been designed to provide a single center lane to be used only for turning by traffi | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.centre_turn_lane | NRS_484B_223_3c |
| if a highway has been designed to provide a single right lane to be used only for turning, | rel.occupies, st.turn_lane | NRS_484B_223_4a |
| if a highway has two or more clearly marked lanes for traffic traveling in one direction, | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.lane, st.lane_adjacency | NRS_484B_223_1b |
| if a laned roadway is restricted to one direction, | st.highway, st.lane, st.on_way, st.one_way_roadway | NRS_484B_497 |
| if a stop sign or a yield sign is erected at one or more entrances thereto | dev.governs, dev.stop_sign, dev.yield_sign, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_2_o2 |
| if an official traffic-control device indicates that a u-turn is prohibited, | dev.governs, dev.regulatory_sign, prim.conditions_hold, rel.occupies, st.intersection, st.lane, st.lane_enters, st.travel_region | NRS_484B_403_2 |
| if any driver or operator of a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_627_1a |
| if during the last one hundred feet of his approach to such intersection | kin.path_length, rel.occupies, st.intersection | LVMC_11_16_040 |
| if the driver complies with the requirements to travel in such a lane | dev.governs, dev.zone_sign, prim.conditions_hold, ru.aggregate=DEF-NRS-484A-460-2::high_occupancy_vehicle | NRS_484B_208_1 |
| if the driver knows, or reasonably should know, that he or she is traveling at a rate of speed which | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, st.travel_region | NRS_484B_208_1 |
| if the driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_400_2a |
| if the highway has a right turn lane | st.lane, st.lane_direction, st.lane_enters, st.turn_lane | NRS_484B_400_1_o1 |
| if the highway has one lane for traveling in each direction | rel.occupies, st.highway, st.lane, st.lane_adjacency, st.lane_direction, st.on_way | NRS_484B_627_1a |
| if the highway has two or more clearly marked lanes for traffic traveling in the direction in which  | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.highway, st.lane, st.lane_adjacency, st.on_way | NRS_484B_627_1b |
| if there is more than one lane for traffic proceeding in the same direction, | rel.occupies, st.lane, st.lane_adjacency | NRS_484B_270_2a_o2 |
| in a bus stop, | rel.occupies, st.curb_zone | NRS_484B_517 |
| in a clearly marked area of highway construction or maintenance | dev.governs, dev.temporary_traffic_control, rel.occupies, st.highway, st.on_way, st.travel_region | NRS_484B_330_1 |
| in a manner which would deprive any such motorcycle or moped of such use. | rel.longitudinal_overlap, rel.occupies, st.lane | NRS_486_341 |
| in a roadway | rel.occupies, st.roadway | LVMC_11_52_040_A |
| in a taxicab stand, | rel.occupies, st.curb_zone | NRS_484B_517 |
| in an access aisle. | rel.occupies, st.parking_space | LVMC_11_52_136 |
| in an area designated as a school crossing zone | dev.governs, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_363_2 |
| in an area designated as a school zone | dev.governs, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_363_1 |
| in an area designated as a school zone or school crossing zone | dev.governs, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_363_3 |
| in any place marked as a freight curb loading zone | rel.occupies, st.curb_zone | NRS_484B_507_1 |
| in any place marked as a passenger curb loading zone | rel.occupies, st.curb_zone | NRS_484B_503 |
| in any restricted parking zone | rel.occupies, st.curb_zone | NRS_484B_510 |
| in any such designated place. | dev.governs, rel.occupies, st.travel_region | NRS_484B_500 |
| in any such space that has been duly posted or marked. | rel.occupies, st.parking_space | LVMC_11_52_340 |
| in excess of the speed therein authorized. | dev.governs, dev.speed_limit_sign, kin.speed, rel.occupies, st.travel_region | NRS_484B_620_2 |
| in no case shall any part of any vehicle | kin.extent, ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_52_060 |
| in such a manner, or under such conditions as to leave available less than 10 feet of the width of t | drv.motion.complete_halt, prim.region_lateral_offset, rel.bearing, rel.longitudinal_overlap, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.obstruction, st.region_geometry, st.road_edge | NRS_484B_477_1b |
| in such zone | rel.occupies, st.curb_zone | NRS_484B_510 |
| in traffic | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.roundabout | LVMC_11_43_010_B_o2 |
| interfere with the movement | kin.accel_longitudinal, kin.speed, rel.bearing | NRS_484B_270_7a |
| is entitled to full use of the traffic lane it is occupying, | rel.occupies, st.lane | NRS_486_341 |
| it is unlawful for a driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_330_1 |
| it is unlawful for a person to: | kin.accel_longitudinal, kin.speed | NRS_484B_653_1a |
| it is unlawful for any person to drive a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_620_2 |
| it is unlawful for any person to drive a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_633_2 |
| it is unlawful for any person to drive or operate | kin.speed | NRS_484B_600_1c |
| it is unlawful for the driver of any vehicle: | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_560_7b |
| it is unlawful to park | drv.motion.parked | LVMC_11_52_340 |
| it shall be unlawful for any pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_30_090 |
| it shall be unlawful for any person driving or operating, propelling or causing to be propelled, any | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_46_030_o1 |
| it shall be unlawful for any person to operate | kin.speed | LVMC_11_40_130 |
| it shall be unlawful for any person to ride | drv.motion.complete_halt | LVMC_11_40_180_A |
| it shall be unlawful for the operator of any vehicle to drive into a crosswalk | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk | LVMC_11_18_020 |
| it shall require obedience by vehicular traffic as follows: | ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_310_1 |
| lawfully using the intersection | rel.occupies, st.intersection | NRS_484B_307_3a |
| lawfully using the intersection. | rel.occupies, st.intersection | NRS_484B_307_4a_o2 |
| lawfully within an adjacent crosswalk | rel.occupies, st.crosswalk, st.entrance_of, st.lane_enters, st.travel_region | NRS_484B_307_3a |
| lawfully within the adjacent crosswalk | rel.occupies, st.crosswalk, st.entrance_of, st.lane_enters, st.travel_region | NRS_484B_307_4a_o2 |
| lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited. | dev.traffic_signal, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_5a_o2 |
| leave a space of 500 feet so that an overtaking vehicle may enter and occupy such space without dang | rel.surface_gap | NRS_484B_127_2 |
| loading or unloading of passengers | sig.door_open | NRS_484B_517 |
| local authorities may by ordinance permit angle parking on any highway, except that angle parking mu | dev.governs, dev.regulatory_sign, prim.conditions_hold, rel.occupies, st.highway, st.parking_space, st.travel_region | NRS_484B_457_1 |
| located at the side of a highway. | dev.position, kin.heading, kin.position, prim.region_lateral_offset, st.road_edge | NRS_484B_450_1g |
| making use of flashing lights meeting the requirements of | sig.warning_lamp | NRS_484B_267_1b_o1 |
| marked in accordance with nrs 484b.363 | dev.zone_sign | NRS_484B_280_1c |
| may be driven in the center turn lane | rel.occupies, st.centre_turn_lane | NRS_484B_223_3a |
| may drive in any lane over which the green signal is shown. | dev.governs, dev.lane_control_signal, drv.motion.complete_halt, rel.occupies, st.lane | NRS_484B_307_12a |
| may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed sign | dev.governs, dev.regulatory_sign, prim.conditions_hold, rel.occupies, st.controlled_access, st.shoulder | NRS_484B_587_2b |
| may make such left turn | kin.speed, rel.occupies, st.intersection | NRS_484B_253_o2 |
| may not proceed on or through any private or public property to enter the intersecting | rel.occupies, st.highway, st.intersection, st.on_way | NRS_484B_307_8e |
| may proceed | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_3a |
| may proceed into the intersection | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_8a_o3 |
| may proceed only in the direction indicated by the arrow signal so long as the arrow is illuminated, | dev.traffic_signal, drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, rel.occupies, st.intersection | NRS_484B_307_4a_o1 |
| may proceed straight through or turn right or left | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_2a |
| may proceed straight through, but must not turn right or left. | drv.motion.left_turn_through_region, drv.motion.right_turn_through_region, drv.motion.u_turn_through_region, rel.occupies, st.intersection | NRS_484B_307_5a_o1 |
| motorcycles and mopeds may, | ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle | NRS_486_351_2 |
| move the vehicle to the lane to the immediate left, | rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency | NRS_484B_270_2a_o2 |
| moving vehicular traffic. | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_153_2 |
| must be driven only upon the right-hand roadway | drv.motion.moving_against_carrier, rel.occupies, st.on_way, st.roadway | NRS_484B_227_1_o1 |
| must be stopped or parked with the right-hand wheels of the vehicle parallel to and within 18 inches | kin.heading, prim.region_lateral_offset, rel.occupies, st.lane_direction, st.on_way, st.region_geometry, st.road_edge, st.travel_region | NRS_484B_457_1 |
| must not be driven to the left side of the center of a two-lane, two-directional highway and overtak | drv.interaction.overtake_pass, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.highway, st.lane, st.lane_adjacency, st.on_way | NRS_484B_213_1 |
| must not be driven to the left side of the highway at any time: | prim.region_lateral_offset, rel.occupies, st.centre_line, st.highway, st.on_way | NRS_484B_213_2b |
| must not enter or drive in any lane over which the red signal is shown. | dev.governs, drv.motion.complete_halt, rel.occupies, st.lane | NRS_484B_307_12b |
| must not enter the intersection | rel.occupies, st.intersection | NRS_484B_307_6a |
| must not travel more than 200 feet in a center turn lane | kin.path_length, rel.occupies, st.centre_turn_lane | NRS_484B_223_3b |
| must not travel more than 50 feet in a center turn lane | kin.path_length, rel.occupies, st.centre_turn_lane | NRS_484B_223_3c |
| must stop before entering the crosswalk on the nearest side of the intersection where the sign or pa | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484B_307_8a_o1 |
| must yield | kin.speed, rel.contact | NRS_484B_307_5a_o2 |
| no motorcycle | ru.aggregate=DEF-NRS-484A-135::motorcycle | LVMC_11_38_030 |
| no pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_30_070_B |
| no person shall park | drv.motion.parked | LVMC_11_52_136 |
| no person shall stand or park a vehicle | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_52_040_A |
| no person shall stand or park a vehicle unless the front of the vehicle is pointed toward the direct | drv.motion.parked, kin.heading, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.travel_region | LVMC_11_52_070 |
| no vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_110 |
| nor enter upon a highway | rel.occupies, st.highway | NRS_484B_410_o2 |
| not be moved from that lane until the driver has given the appropriate turn signal | drv.lane.entering_adjacent_lane, rel.occupies, sig.hand_signal, sig.turn_indicator, st.lane | NRS_484B_223_1b |
| not travel through an intersection. | drv.motion.right_turn_through_region, rel.occupies, st.intersection | NRS_484B_223_4b |
| of a motor vehicle. | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_270_7a |
| of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_413_3 |
| of a vehicle. | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_413_2 |
| of an authorized flagger serving in a traffic control capacity | dev.governs, dev.human_direction, rel.occupies, st.travel_region | NRS_484B_330_1 |
| of vehicles with the left-hand wheels adjacent to and within 18 inches of the left-hand curb of a on | kin.heading, prim.region_lateral_offset, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.on_way, st.one_way_roadway, st.region_geometry, st.road_edge | NRS_484B_457_1 |
| on a controlled-access highway | rel.occupies, st.controlled_access | NRS_484B_208_1 |
| on a controlled-access highway: | rel.occupies, st.controlled_access | NRS_484B_587_2b |
| on a highway | rel.occupies, st.highway | NRS_484B_653_1a |
| on a roadway, bicycle lane, path or route | rel.occupies, st.bicycle_lane_or_path, st.roadway | NRS_484B_785_1a |
| on all streets and highways | rel.occupies, st.highway | LVMC_11_16_060 |
| on any highway | rel.occupies, st.highway | LVMC_11_22_020 |
| on or entering a highway | rel.occupies, st.highway | NRS_484B_603_1_o2 |
| on the highway side of any vehicle | prim.region_lateral_offset, rel.bearing, rel.longitudinal_overlap, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_450_1l |
| on the through highway | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, rel.occupies, st.lane_enters, st.travel_region | LVMC_11_12_070_B |
| only when the intersecting highway is one-way to the left, | st.highway, st.intersection, st.lane, st.lane_direction, st.on_way | NRS_484B_307_8a_o3 |
| only when the intersecting highway is two-directional or one-way to the right, | st.highway, st.intersection, st.lane, st.lane_direction, st.median_or_divider, st.on_way | NRS_484B_307_8a_o3 |
| onto or from any controlled-access highway | rel.occupies, st.controlled_access | NRS_484B_587_1 |
| onto or from the highway. | drv.motion.left_turn, rel.occupies, st.driveway_or_alley_entrance, st.highway, st.intersection, st.on_way | NRS_484B_223_3a |
| or (3) in or near a school zone or a school crossing zone | dev.governs, dev.zone_sign, rel.occupies, st.region_geometry, st.travel_region | NRS_484B_280_1c |
| or (4) engaged in the construction, maintenance or repair of the highway, including, without limitat | ru.official_vehicle, sig.warning_lamp | NRS_484B_208_1 |
| or (d) if the zone is not designated by an operational speed limit beacon, | dev.governs, dev.inoperative, dev.speed_limit_beacon, st.travel_region | NRS_484B_363_2 |
| or (e) if the zone is not designated by an operational speed limit beacon, | dev.governs, dev.inoperative, dev.speed_limit_beacon, st.travel_region | NRS_484B_363_3 |
| or (f) a public transit motor bus, | ru.transit_bus | NRS_484B_587_2b |
| or a marked or unmarked crosswalk. | rel.occupies, st.crosswalk, st.region_geometry | NRS_484B_280_1c |
| or a taxicab | ru.aggregate=DEF-NRS-484A-270::taxicab | NRS_484B_517 |
| or a traffic-control signal: | dev.governs, dev.inoperative, dev.traffic_signal | NRS_484B_257_2_o2 |
| or an official vehicle of a regulatory agency | ru.official_vehicle | NRS_484B_267_2b |
| or an official vehicle of a regulatory agency, | ru.official_vehicle | NRS_484B_267_1b_o1 |
| or any driver of any vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_30_140_B_o2 |
| or any other area which has been designated as a temporary traffic control zone. | dev.governs, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_330_1 |
| or are within the intersection. | rel.occupies, st.intersection | NRS_484B_250_4_o2 |
| or as otherwise authorized by subsection 3 | dev.regulatory_sign | NRS_484B_587_2b |
| or at a crossover or intersection established by a public authority. | rel.occupies, st.intersection, st.median_or_divider | NRS_484B_227_1_o2 |
| or at a traffic-controlled intersection | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, st.intersection, st.lane_enters, st.travel_region | LVMC_11_16_040 |
| or by reason of weather | env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, st.sight_distance | NRS_484B_603_1_o1 |
| or in compliance with law | dev.governs, dev.stop_sign, dev.traffic_signal, rel.occupies, st.travel_region | NRS_484B_450_1l |
| or in compliance with law. | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, rel.occupies, st.travel_region | NRS_484B_627_2 |
| or in the act of boarding | drv.motion.complete_halt, rel.surface_gap, sig.door_open | NRS_484B_280_1c |
| or is making a left turn. | kin.yaw_rate, rel.occupies, st.intersection | NRS_484B_250_1 |
| or make any left turn, semicircular turn or u-turn, | drv.motion.left_turn, drv.motion.u_turn | NRS_484B_227_1_o3 |
| or motor scooter | ru.moped | LVMC_11_38_030 |
| or must be made from the extreme right lane. | rel.occupies, st.lane, st.lane_adjacency, st.lane_enters, st.roadway | NRS_484B_400_1_o2 |
| or official traffic-control device, | dev.governs, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, rel.occupies, st.travel_region | NRS_484B_450_1l |
| or on a divided highway | rel.occupies, st.highway, st.median_or_divider, st.on_way | NRS_484B_403_3 |
| or other such movement as is permitted by other signal indications displayed at the same time. | dev.traffic_signal | NRS_484B_307_7a_o1 |
| or the directions of a police officer | dev.governs, dev.human_direction, rel.occupies, st.travel_region | NRS_484B_450_1l |
| or to vehicles approaching each other from opposite directions, | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.lane_enters, st.travel_region | NRS_484B_250_1 |
| or trailer | ru.aggregate=DEF-LVMC-11-02-170::trailer | LVMC_11_52_060 |
| or upon a curve in the highway | rel.occupies, st.curvature, st.highway | NRS_484B_213_2a |
| or upon the approach to or near the crest of a grade, | st.crest, st.region_geometry | NRS_484B_407 |
| or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway | dev.governs, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency, st.lane_enters, st.one_way_roadway | NRS_484B_307_8a_o3 |
| or within 30 feet of points on the curb immediately opposite the ends of a safety zone. | kin.extent, prim.region_lateral_offset, prim.region_offset_along, rel.occupies, st.lane_direction, st.region_geometry, st.road_edge, st.safety_zone, st.travel_region | NRS_484B_450_1h |
| or within a highway tunnel. | rel.occupies, st.elevated_structure | NRS_484B_450_1m |
| other than a bus | ru.aggregate=DEF-NRS-484A-030::bus | NRS_484B_517 |
| other than a city vehicle | ru.official_vehicle | LVMC_11_52_340 |
| other than for the purpose to which parking in such zone is restricted, | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | NRS_484B_510 |
| other than in a marked crosswalk or within an unmarked crosswalk | rel.occupies, st.crosswalk | LVMC_11_30_070_B |
| other than parallel with the edge of the roadway headed in the direction of lawful traffic movement. | kin.heading, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.lane_direction, st.travel_region | LVMC_11_52_040_A |
| other than truck routes | dev.governs, dev.regulatory_sign, rel.occupies, st.travel_region | LVMC_11_48_060 |
| over any bridge or other elevated structure constituting a part of a highway | rel.occupies, st.elevated_structure, st.highway, st.on_way | NRS_484B_633_2 |
| part of the load of such vehicle | kin.extent | LVMC_11_52_060 |
| passing around a rotary traffic island | rel.occupies, st.roundabout | NRS_484B_220_2 |
| path for bicycles, electric bicycles, or electric scooters has been provided | st.bicycle_lane_or_path, st.highway, st.on_way | LVMC_11_40_120 |
| pedestrians | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_293 |
| persons riding bicycles, electric bicycles or electric scooters | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_777_3 |
| prior to changing the course | drv.lane.heading_left_of_carrier, drv.lane.heading_right_of_carrier, rel.occupies, st.lane | NRS_484B_413_2 |
| proceed | kin.speed | NRS_484B_267_2b |
| proceeding in the same direction, | kin.speed, rel.same_direction | NRS_484B_270_2a_o2 |
| project into the street more than fifteen feet measured on a line at right angles to the curb. | drv.motion.parked, kin.extent, kin.heading, rel.occupies, st.highway, st.lane_direction, st.on_way, st.region_geometry, st.road_edge, st.travel_region | LVMC_11_52_060 |
| riders of bicycles, electric bicycles, and electric scooters | ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle | LVMC_11_40_120 |
| said driver | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | LVMC_11_12_070_B |
| shall | rel.contact | LVMC_11_22_010 |
| shall at any time be driven | drv.motion.complete_halt | NRS_484B_110 |
| shall be depressed or dimmed. | sig.headlamp | NRS_484D_165_4 |
| shall be driven only in the direction designated. | drv.motion.moving_against_carrier | NRS_484B_220_1 |
| shall be driven only to the right of such island. | drv.motion.circulating_clockwise_about | NRS_484B_220_2 |
| shall be in a counterclockwise direction | drv.motion.circulating_clockwise_about | LVMC_11_43_010_A |
| shall be ridden | drv.motion.complete_halt | LVMC_11_38_030 |
| shall cross a roadway | drv.motion.moving_across_carrier, rel.occupies, st.lane, st.roadway | LVMC_11_30_070_B |
| shall execute a right-hand turn, | drv.motion.right_turn_through_region, kin.yaw_rate, rel.occupies | LVMC_11_60_090 |
| shall in every case yield | drv.motion.moving_backward, rel.contact | NRS_484B_113_3 |
| shall keep as far to the right of the highway | prim.region_lateral_offset, rel.occupies, st.highway, st.on_way, st.road_edge | NRS_484B_560_3_o1 |
| shall move | drv.motion.complete_halt | NRS_484B_293 |
| shall not back into an intersection, on or over a crosswalk, or around a street corner. | drv.motion.moving_backward, kin.yaw_rate, rel.occupies, st.crosswalk, st.intersection | NRS_484B_113_2 |
| shall not be permitted to stand | drv.motion.complete_halt | NRS_484B_533 |
| shall not be turned so as to proceed in the opposite direction | drv.motion.u_turn | NRS_484B_407 |
| shall not be used as through routes | rel.occupies, st.highway | LVMC_11_48_060 |
| shall not bring a vehicle to a complete stop | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_627_2 |
| shall not cross an intersection diagonally | drv.motion.moving_across_carrier, rel.occupies, st.intersection, st.lane, st.lane_enters | NRS_484B_287_1d |
| shall not drive a motorcycle or moped | ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-041::motorcycle | NRS_486_351_1 |
| shall not follow another vehicle | rel.ahead_behind_in_lane, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_127_1 |
| shall not form two lanes of traffic | rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-285::traffic, st.lane | NRS_484B_560_3_o2 |
| shall not leave open a door on the side of a vehicle which is closest to passing traffic | ru.aggregate=DEF-NRS-484A-320::vehicle, sig.door_open | NRS_484B_153_3 |
| shall not make a u-turn | drv.motion.u_turn | NRS_484B_363_3 |
| shall not open the door of or board or alight from | sig.door_open | NRS_484B_153_2 |
| shall not overtake and pass another vehicle upon the right | drv.interaction.overtake_pass_on_right, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_210_3 |
| shall not park a vehicle | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_490 |
| shall not ride more than two abreast | drv.motion.complete_halt, rel.longitudinal_overlap, rel.same_direction, rel.surface_gap | NRS_484B_777_3 |
| shall not stand or park a vehicle | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_493 |
| shall not start a vehicle which is stopped, standing or parked on a highway | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway | NRS_484B_410_o1 |
| shall not stop | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, st.travel_region | NRS_484B_413_3 |
| shall not stop, stand or park a vehicle, | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_450_1l |
| shall not: overtake and pass a motor vehicle | drv.interaction.overtake_pass, kin.heading, kin.position, rel.longitudinal_overlap, rel.same_direction, ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_270_7b |
| shall not: stop, stand or park a vehicle | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.travel_region | NRS_484B_477_1b |
| shall obey the directions of the device. | drv.motion.u_turn | NRS_484B_403_2 |
| shall pass each other keeping to the right, | rel.bearing, rel.longitudinal_overlap, rel.occupies, st.highway | NRS_484B_203_1_o1 |
| shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line | NRS_484B_250_4_o1 |
| shall stop before entering the crosswalk on the near side of the intersection or, if there is no cro | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484A_450_2 |
| shall stop before entering the crosswalk on the nearest side of the intersection or, if there is no  | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484A_450_3 |
| shall stop before entering the nearest crosswalk in an intersection or at a limit line when marked,  | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.lane_enters, st.region_geometry, st.stop_line | NRS_484B_310_1 |
| shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswal | drv.motion.complete_halt, kin.speed, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.crosswalk, st.entrance_of, st.intersection, st.lane_direction, st.region_geometry, st.stop_line | NRS_484B_257_1_o1 |
| shall stop such vehicle immediately prior to | drv.motion.complete_halt | LVMC_11_40_140_o1 |
| shall stop within 50 feet but not less than 15 feet from the nearest track of such a grade crossing | drv.motion.complete_halt, rel.occupies, st.railway_crossing, st.region_geometry | NRS_484B_557_o2 |
| shall use such path and shall not use the roadway | drv.motion.complete_halt, drv.motion.moving_across_carrier, rel.occupies, st.bicycle_lane_or_path, st.lane, st.roadway | LVMC_11_40_120 |
| shall use the left lane to turn left or complete a u-turn | drv.motion.left_turn_through_region, drv.motion.u_turn_through_region, rel.occupies, st.lane, st.lane_adjacency | LVMC_11_43_010_C1 |
| shall use the right lane to turn right | drv.motion.right_turn_through_region, rel.occupies, st.lane, st.lane_adjacency | LVMC_11_43_010_C2 |
| shall yield | kin.speed, rel.contact | NRS_484B_250_1 |
| shall yield the right-of-way | kin.speed, rel.contact | NRS_484B_263_o1 |
| shall: exercise | kin.speed, rel.contact | NRS_484B_280_1c |
| stopped or parked | drv.motion.complete_halt | NRS_484B_450_1l |
| streets | rel.occupies, st.highway | LVMC_11_48_060 |
| subsection 2 does not apply upon a one-way highway. | rel.occupies, st.one_way_roadway | NRS_484B_213_2b |
| such pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_40_180_C_o2 |
| such vehicle shall display lighted lamps | sig.position_lamp | NRS_484D_165_3 |
| such vehicular traffic | ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_307_5a_o2 |
| such vehicular traffic, including vehicles turning right or left, | ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_307_2a |
| that is being driven on the paved shoulder of a highway where lawfully placed signage allows that ve | dev.governs, dev.regulatory_sign, prim.conditions_hold, rel.occupies, st.highway, st.on_way, st.shoulder | NRS_484B_587_2b |
| that posted by a public authority | dev.speed_limit_sign | NRS_484B_600_1c |
| the approach for a left turn must be made in that portion of the right half of the highway nearest t | rel.occupies, st.highway, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.on_way, st.roadway | NRS_484B_400_2a |
| the city council may designate parking spaces upon city streets or in city parking facilities for th | st.parking_space | LVMC_11_52_340 |
| the city traffic engineer shall determine upon what streets angle parking shall be permitted, | dev.governs, dev.regulatory_sign, rel.occupies, st.parking_space, st.travel_region | LVMC_11_52_070 |
| the department of transportation, and local authorities with the approval of the department of trans | st.highway, st.on_way, st.railway_crossing | NRS_484B_557_o2 |
| the driver | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_560_3_o2 |
| the driver of a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_270_5a |
| the driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_250_1 |
| the driver of a vehicle: | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_113_2 |
| the driver of any other vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_30_030 |
| the driver of any other vehicle shall, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_267_2e |
| the driver of any truck or combination of vehicles 80 inches or more in overall width, | kin.extent, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, ru.aggregate=DEF-NRS-484A-305::truck | NRS_484B_127_2 |
| the driver of any vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_557_o2 |
| the driver of every other vehicle shall, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_267_1b_o1 |
| the driver of the vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_250_4_o2 |
| the driver or operator shall: | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_627_1a |
| the driver shall yield | kin.speed, rel.contact | NRS_484B_257_1_o2 |
| the drivers of all other vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_12_070_B |
| the operation of vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_43_010_B_o1 |
| the operation of vehicles within a roundabout | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | LVMC_11_43_010_C1 |
| the operator of a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_7b |
| the operator of a bicycle, electric bicycle, or electric scooter | ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle | LVMC_11_40_140_o2 |
| the operator of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_43_010_B_o1 |
| the prima facie speed limit is twenty-five miles per hour | kin.speed | LVMC_11_16_060 |
| the prima facie speed limit shall be fifteen miles per hour | kin.speed | LVMC_11_16_040 |
| the requirements of subsection 1 do not apply: (a) to a driver operating a motor vehicle that is: | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_208_1 |
| the side of a vehicle which is closest to passing traffic | ru.aggregate=DEF-NRS-484A-320::vehicle, sig.door_open | NRS_484B_153_2 |
| this section does not apply at intersections controlled by official traffic-control devices | dev.governs, dev.stop_sign, dev.traffic_signal, dev.yield_sign, st.intersection, st.lane_enters, st.travel_region | NRS_484B_250_1 |
| this subsection does not apply to any vehicle or combination of vehicles while moving on a highway o | rel.occupies, st.lane, st.lane_adjacency | NRS_484B_127_2 |
| through or within a safety zone. | rel.occupies, st.safety_zone | NRS_484B_110 |
| to a vehicle which has entered the intersection | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection | NRS_484B_250_1 |
| to all vehicles approaching on said roadway | prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roadway | LVMC_11_20_060_o3 |
| to all vehicles approaching on such highway. | kin.speed, rel.bearing, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.on_way, st.travel_region | NRS_484B_260 |
| to all vehicles approaching on the highway | kin.speed, rel.bearing, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | NRS_484B_263_o2 |
| to all vehicles upon the roadway | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roadway | LVMC_11_30_060_A |
| to any pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_20_060_o2 |
| to any vehicle approaching from the opposite direction | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_direction, st.lane_enters, st.travel_region | NRS_484B_253_o1 |
| to avoid a collision | rel.contact | NRS_484B_280_1a |
| to avoid the red signal. | drv.motion.parked, rel.occupies, st.intersection | NRS_484B_307_8e |
| to fail or refuse to comply with any signal | dev.human_direction, dev.position, kin.accel_longitudinal, kin.heading, kin.position, kin.yaw_rate | NRS_484B_330_1 |
| to fail to completely cross the track or tracks without stopping | drv.motion.complete_halt | NRS_484B_560_7a |
| to fail to obey an official traffic-control device or the directions of a police officer | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.complete_halt, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.rail_vehicle, st.region_geometry, st.travel_region | NRS_484B_560_7b |
| to fail to stop not less than fifty feet from the nearest side of | drv.motion.complete_halt, st.region_geometry | LVMC_11_46_030_o1 |
| to moving traffic and pedestrians. | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, st.highway | NRS_484B_113_3 |
| to other traffic lawfully within the intersection. | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.intersection | NRS_484B_307_7a_o3 |
| to other vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_307_5a_o2 |
| to other vehicles which have entered the intersection from such through highway | dev.governs, dev.stop_sign, dev.yield_sign, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_enters, st.on_way, st.travel_region | NRS_484B_257_1_o2 |
| to pass other slowly moving vehicles. | kin.speed, rel.bearing, rel.longitudinal_overlap, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_627_1b |
| to pedestrians | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_307_4a_o2 |
| to pedestrians and other traffic proceeding as directed by the signal at the intersection. | dev.governs, dev.traffic_signal, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_8a_o3 |
| to pedestrians lawfully within the intersection or an adjacent crosswalk | rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_7a_o2 |
| to the driver of any vehicle immediately to the rear. | rel.ahead_behind_in_lane, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_413_3 |
| to the vehicle about to enter or cross the through highway | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | LVMC_11_12_070_B |
| to the vehicle making the left turn. | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection | NRS_484B_253_o2 |
| to vehicles already in the roundabout | rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.roundabout | LVMC_11_43_010_B_o1 |
| to vehicles not so obligated to stop or yield | dev.governs, dev.stop_sign, dev.yield_sign, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane_enters, st.travel_region | NRS_484B_257_2_o2 |
| to vehicles which have previously completed a stop | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | NRS_484B_250_4_o2 |
| to walk along and upon an adjacent roadway | drv.motion.complete_halt, drv.motion.moving_across_carrier, rel.occupies, st.highway, st.lane, st.on_way, st.roadway | LVMC_11_30_090 |
| traffic | rel.ahead_behind_in_lane, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_627_2 |
| traffic proceeding immediately behind the driver or operator, | rel.ahead_behind_in_lane, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_627_1a |
| unattended | ru.occupant_count | NRS_484B_533 |
| unless a different speed limit is posted as set forth in this title | dev.governs, dev.speed_limit_sign, rel.occupies, st.travel_region | LVMC_11_16_060 |
| unless authorized by official traffic-control devices. | rel.occupies, st.crosswalk | NRS_484B_287_1d |
| unless official traffic-control devices are erected permitting such standing or parking. | dev.governs, dev.regulatory_sign, dev.zone_sign, prim.conditions_hold, rel.occupies, st.parking_space, st.travel_region | NRS_484B_497 |
| unless pick-up, delivery or essential use is required enroute | drv.motion.parked | LVMC_11_48_060 |
| unless such left side is clearly visible | st.sight_distance | NRS_484B_213_1 |
| unless the highway is marked for four or more lanes of traffic. | rel.occupies, st.highway, st.lane, st.on_way | NRS_484B_560_3_o2 |
| unloading and delivery or pickup and loading of materials | drv.motion.complete_halt, ru.commercial_motor_vehicle, ru.truck, sig.door_open | NRS_484B_507_1 |
| until such signal has stopped, raised, or been removed, or the flagman or person stationed at such p | dev.crossing_warning_signal, dev.governs, dev.human_direction | LVMC_11_46_030_o2 |
| upon a highway | rel.occupies, st.highway | NRS_484B_457_1 |
| upon a highway designated and signposted for one-way traffic | rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, st.one_way_roadway | NRS_484B_220_1 |
| upon a parked vehicle | drv.motion.parked, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484D_165_4 |
| upon a roadway | rel.occupies, st.roadway | NRS_484B_777_3 |
| upon a roadway shall, except: | rel.occupies, st.roadway | NRS_484B_777_1_o2 |
| upon any bridge or other elevated structure | rel.occupies, st.elevated_structure | NRS_484B_450_1m |
| upon any curve, | rel.occupies, st.curvature, st.roadway | NRS_484B_407 |
| upon any perceptible grade | rel.occupies, st.grade, st.highway | NRS_484B_533 |
| upon any sidewalk | rel.occupies, st.sidewalk | LVMC_11_38_030 |
| upon any such highway. | rel.occupies, st.travel_region | NRS_484B_490 |
| upon approaching | kin.speed, rel.bearing, rel.centre_distance | NRS_484B_267_2b |
| upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which | kin.speed, rel.bearing, rel.centre_distance, rel.visible, ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle, ru.official_vehicle, sig.hand_signal, sig.turn_indicator | NRS_484B_267_2e |
| upon approaching within 100 feet of any bridge, viaduct or tunnel. | kin.position, kin.velocity, st.elevated_structure, st.region_geometry | NRS_484B_213_2c |
| upon entering the roadway | rel.occupies, st.roadway | LVMC_11_20_060_o3 |
| upon highways having width for not more than one line of traffic in each direction, | rel.occupies, st.highway, st.lane, st.lane_adjacency | NRS_484B_203_1_o2 |
| upon leaving any stand designated in accordance with the provisions of this section, | rel.occupies, st.curb_zone | LVMC_11_60_090 |
| upon observing | rel.visible | NRS_484B_280_1c |
| upon the left-hand side of a one-way | kin.heading, prim.region_lateral_offset, rel.occupies, st.highway, st.lane_direction, st.on_way, st.one_way_roadway, st.region_geometry, st.road_edge | NRS_484B_493 |
| upon the left-hand side of such one-way roadway | kin.heading, prim.region_lateral_offset, rel.occupies, st.highway, st.lane_direction, st.on_way, st.one_way_roadway, st.road_edge | NRS_484B_497 |
| upon the right half of crosswalks. | kin.position, kin.speed, kin.velocity, rel.occupies, st.crosswalk, st.region_geometry | NRS_484B_293 |
| upon the side of the roadway on which said vehicle is coming | prim.region_lateral_offset, rel.bearing, st.centre_line, st.highway, st.on_way, st.one_way_roadway | LVMC_11_18_020 |
| upon the sidewalks | rel.occupies, st.sidewalk | LVMC_11_40_180_A |
| upon the traveled portion of a highway or shoulder adjacent thereto, | rel.occupies, st.highway, st.on_way, st.roadway, st.shoulder | NRS_484D_165_3 |
| vehicles must: | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_223_1b |
| vehicular traffic facing such a signal and situated on the extreme right of the highway | dev.governs, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.lane, st.lane_adjacency, st.lane_enters | NRS_484B_307_8a_o3 |
| vehicular traffic facing the signal | dev.governs, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | NRS_484B_307_5a_o2 |
| waiting to enter or about to enter such zone. | drv.motion.complete_halt, rel.occupies, st.curb_zone, st.region_geometry | NRS_484B_517 |
| when a red lens is illuminated with rapid intermittent flashes, | dev.governs, dev.traffic_signal, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_310_1 |
| when a sign is posted giving notice of this requirement, | dev.governs, dev.regulatory_sign, prim.conditions_hold, rel.occupies, st.travel_region | LVMC_11_60_090 |
| when a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_250_4_o2 |
| when approaching a hill crest, | kin.position, kin.velocity, st.crest, st.region_geometry | NRS_484B_603_1_o1 |
| when approaching and crossing an intersection, | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_603_1_o1 |
| when approaching and going around a curve, | kin.path_length, rel.occupies, st.curvature, st.roadway | NRS_484B_603_1_o1 |
| when approaching the crest of a grade | kin.position, kin.velocity, st.crest, st.region_geometry | NRS_484B_213_2a |
| when approaching within 100 feet or traversing any intersection or railroad grade crossing. | kin.position, kin.velocity, rel.occupies, st.intersection, st.railway_crossing, st.region_geometry | NRS_484B_213_2b |
| when being driven on the highway | rel.occupies, st.highway | NRS_486_341 |
| when crossing at grade any track or tracks of a railroad, | rel.occupies, st.railway_crossing | NRS_484B_560_7a |
| when official traffic-control devices are erected at hazardous or congested places, | dev.regulatory_sign, dev.zone_sign, prim.conditions_hold | NRS_484B_500 |
| when official traffic-control devices are erected giving notice thereof, | dev.regulatory_sign | NRS_484B_587_1 |
| when official traffic-control devices are erected prohibiting parking upon a narrow highway, | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | NRS_484B_490 |
| when operating a vehicle | kin.speed, ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_22_010 |
| when overtaking or passing | drv.interaction.overtake_pass, rel.longitudinal_overlap | NRS_484B_270_2a_o2 |
| when passing a standing vehicle or one proceeding in the same direction. | drv.interaction.overtake_pass, drv.motion.complete_halt, kin.speed, rel.same_direction, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_777_1_o2 |
| when pedestrians are prohibited from crossing at certain designated places | dev.governs, dev.regulatory_sign | LVMC_11_30_060_A |
| when proper signs have been erected, | dev.governs, dev.stop_sign, dev.yield_sign, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_1_o2 |
| when stopping is required | dev.governs, dev.human_direction, dev.railway_signal_or_gate, dev.stop_sign, dev.traffic_signal, rel.occupies, st.travel_region | NRS_484B_560_3_o2 |
| when such movement requires driving off the paved portion of the highway. | rel.occupies, st.road_edge, st.shoulder | NRS_484B_210_3 |
| when such stop or stand has been officially designated and appropriately signed, | rel.occupies, st.curb_zone | NRS_484B_517 |
| when such stop signs are erected | dev.governs, rel.occupies, st.travel_region | NRS_484B_557_o2 |
| when such structure is signposted as provided in this section | dev.governs, dev.speed_limit_sign, rel.occupies, st.travel_region | NRS_484B_633_2 |
| when the red signal is exhibited. | dev.governs, dev.traffic_signal | NRS_484B_307_6a |
| when the signal is circular green alone: | dev.traffic_signal | NRS_484B_307_2a |
| when there is in the crosswalk | rel.occupies, st.crosswalk | LVMC_11_18_020 |
| when traveling upon any narrow or winding highway, | rel.occupies, st.curvature, st.highway, st.lane, st.lane_width, st.on_way | NRS_484B_603_1_o1 |
| when traversing any intersection | rel.occupies, st.intersection | LVMC_11_16_040 |
| whenever a vehicle is parked or stopped | drv.motion.complete_halt, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484D_165_3 |
| whenever an illuminated flashing red or yellow signal is used in conjunction with an official traffi | dev.traffic_signal | NRS_484B_310_1 |
| whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, st.sidewalk | LVMC_11_40_180_C_o2 |
| whenever any vehicle is stopped at a marked crosswalk or at any unmarked crosswalk at an intersectio | drv.motion.complete_halt, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.region_geometry, st.travel_region | LVMC_11_30_030 |
| whenever signals are placed over the individual lanes of a highway, | dev.governs, dev.lane_control_signal, st.highway, st.lane, st.on_way | NRS_484B_307_12a |
| where an appropriate opening or crossing place exists. | rel.occupies, st.median_or_divider | NRS_484B_403_3 |
| where angle parking is permitted, | dev.governs, dev.regulatory_sign, rel.occupies, st.parking_space, st.travel_region | LVMC_11_52_070 |
| where any signal device, flagman or other person is stationed, giving warning that children are abou | dev.crossing_warning_signal, dev.governs, dev.human_direction, rel.occupies, st.travel_region | LVMC_11_46_030_o1 |
| where sidewalks are provided | st.highway, st.on_way, st.sidewalk | LVMC_11_30_090 |
| where such vehicle cannot be seen by the driver of any other vehicle approaching from either directi | st.sight_distance | NRS_484B_407 |
| where the driver’s view is obstructed | st.sight_distance | NRS_484B_213_2a |
| where the signal is a flashing yellow turn arrow, displayed alone or in combination with another sig | dev.traffic_signal | NRS_484B_307_7a_o2 |
| where the signal is a green straight-through arrow alone: | dev.traffic_signal | NRS_484B_307_5a_o2 |
| where the signal is a green turn arrow alone: | dev.traffic_signal | NRS_484B_307_4a_o2 |
| where the signal is a steady red signal alone: | dev.traffic_signal | NRS_484B_307_8a_o3 |
| where the signal is a steady yellow signal alone: | dev.traffic_signal | NRS_484B_307_6a |
| where the signal is circular green with a green turn arrow: | dev.traffic_signal | NRS_484B_307_3a |
| where there are adjacent curbs | st.highway, st.lane, st.lane_marking, st.on_way | NRS_484B_457_1 |
| where there is displayed a sign with the words "school-xing," | dev.governs, dev.zone_sign, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.travel_region | LVMC_11_18_020 |
| where traffic is not facing a red signal | dev.governs, dev.traffic_signal, st.lane_enters, st.on_way, st.travel_region | NRS_484B_307_8e |
| which has two or more clearly marked lanes for traveling in the same direction, | rel.occupies, st.lane, st.lane_adjacency | NRS_484B_208_1 |
| which is following a truck, or combination of vehicles 80 inches or more in overall width, | kin.extent, rel.ahead_behind_in_lane, ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles, ru.aggregate=DEF-NRS-484A-305::truck | NRS_484B_127_2 |
| which is moving or preparing to move in any direction, | kin.speed, rel.visible, sig.hand_signal, sig.turn_indicator | NRS_484B_267_2b |
| which is waiting to enter or about to enter such zone. | drv.motion.complete_halt, rel.occupies, st.curb_zone, st.region_geometry | NRS_484B_507_1 |
| which is within the intersection | rel.occupies, st.intersection | NRS_484B_253_o1 |
| while being driven in the right turn lane, | rel.occupies, st.intersection, st.lane_enters, st.turn_lane | NRS_484B_223_4b |
| who approaches or comes in contact with | drv.motion.complete_halt, rel.centre_distance, rel.contact | LVMC_11_30_140_B_o2 |
| who intends to exit a roundabout | drv.motion.left_turn_through_region, drv.motion.u_turn_through_region, rel.occupies, st.roundabout | LVMC_11_43_010_C1 |
| with a pedestrian. | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_280_1a |
| with a person riding | kin.speed | NRS_484B_270_5a |
| with any person, vehicle or other conveyance | rel.contact, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_603_1_o2 |
| with other traffic | rel.ahead_behind_in_lane, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_450_1l |
| with respect to pedestrians or other traffic, | prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, ru.aggregate=DEF-NRS-484A-285::traffic, st.roadway | NRS_484B_603_1_o1 |
| with the consent of the drivers, | rel.same_direction | NRS_486_351_2 |
| within 20 feet of a driveway entrance to any fire station | st.fire_station_entrance, st.region_geometry | NRS_484B_450_1j |
| within 30 feet upon the approach to any official traffic-control signal | dev.governs, dev.position, dev.traffic_signal, kin.extent, kin.position, rel.occupies, st.intersection, st.lane_direction, st.lane_enters, st.travel_region | NRS_484B_450_1g |
| within 75 feet of that entrance. | st.fire_station_entrance, st.region_geometry | NRS_484B_450_1j |
| within a roundabout | rel.occupies, st.roundabout | LVMC_11_43_010_B_o1 |
| within an alley | rel.occupies, st.alley | NRS_484B_477_1a |
| within an intersection | rel.occupies, st.intersection | NRS_484B_253_o2 |
| without first giving an appropriate signal | sig.brake_lamp, sig.hand_signal | NRS_484B_413_3 |
| without stopping the engine and effectively setting the brake thereon and turning the front wheels t | kin.engine_running, kin.parking_brake, kin.steer_angle, prim.region_lateral_offset, st.highway, st.on_way, st.road_edge | NRS_484B_533 |
| yielding | kin.speed, rel.contact | NRS_484B_257_2_o2 |
| yielding the right-of-way to any pedestrian | kin.speed, rel.contact, ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_40_140_o2 |

### Spans mapped this iteration by an earlier batch (not yet accepted; the same words map to the same atoms, or `PLAN.md` records a dispute)
| words | atoms | node |
|---|---|---|
| (1) Commercial vehicles to stop, stand or park for the purpose of loading or unloading freight | drv.motion.complete_halt, ru.aggregate=DEF-LVMC-11-02-070::commercial_vehicle | LVMC_11_52_030_B |
| (2) Taxicabs to stop, stand, park for the purpose of loading, unloading or waiting for passengers | drv.motion.complete_halt, ru.aggregate=DEF-LVMC-11-02-140::taxicab | LVMC_11_52_030_B |
| (2) When the location is accompanied by signage which indicates that parking is limited to tour buse | rel.occupies, ru.aggregate=DEF-LVMC-11-02-090::limo, ru.aggregate=DEF-LVMC-11-02-150::shuttle_bus, ru.aggregate=DEF-LVMC-11-02-150::tour_bus, st.curb_zone | LVMC_11_52_030_A |
| (5) At locations where a drop box for U.S. mail is adjacent to a curb or road surface painted red, | st.obstruction, st.region_geometry | LVMC_11_52_030_A |
| A driver may drive across a pavement striping marking such zone | kin.extent, prim.region_lateral_offset, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line | NRS_484B_217_2 |
| Armored cars and emergency vehicles may park at such locations | drv.motion.complete_halt, ru.emergency_vehicle, ru.official_vehicle | LVMC_11_52_030_A |
| As used in this section, “preparing to move” means any indication that is visible to an approaching  | kin.speed, rel.visible, sig.hand_signal, sig.turn_indicator | NRS_484B_267_2a |
| Decrease the speed of his or her vehicle | kin.accel_longitudinal, rel.longitudinal_overlap | NRS_484B_267_2a |
| Except for a motor vehicle, | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | LVMC_11_52_300 |
| Except when traffic is being controlled by a police officer | dev.governs, dev.human_direction, ru.aggregate=DEF-NRS-484A-285::traffic, st.travel_region | NRS_484B_257_2_o1 |
| If there is only one lane for traffic proceeding in the same direction, | rel.occupies, st.lane, st.lane_adjacency | NRS_484B_270_2b_o2 |
| Red indicates no stopping, standing or parking, | dev.governs, dev.human_direction, dev.stop_sign, dev.traffic_signal, drv.motion.complete_halt, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, st.curb_zone, st.travel_region | LVMC_11_52_030_A |
| The driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_257_2_o1 |
| The location of such zones shall be established by posting appropriate signage or other durable mark | rel.occupies, st.curb_zone | LVMC_11_52_030_A |
| The parking of vehicles is prohibited or restricted in certain zones as set forth in this Section. | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_52_030_A |
| Upon approaching | kin.speed, rel.bearing, rel.centre_distance | NRS_484B_267_2a |
| When overtaking or passing | drv.interaction.overtake_pass, rel.longitudinal_overlap | NRS_484B_270_2b_o1 |
| When the location is accompanied by signage which indicates that parking is limited to RTC buses, | rel.occupies, ru.aggregate=DEF-LVMC-11-02-120::rtc_bus, st.curb_zone | LVMC_11_52_030_A |
| Whenever any person is riding a bicycle, electric bicycle, or electric scooter upon a sidewalk | drv.motion.complete_halt, rel.occupies, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter, ru.aggregate=DEF-NRS-484A-025::bicycle, st.sidewalk | LVMC_11_40_180_C_o1 |
| Yellow indicates a zone for: | drv.motion.complete_halt, rel.occupies, st.curb_zone | LVMC_11_52_030_B |
| a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_2b_o1 |
| a curb or road surface edge which is painted red indicates no parking, | rel.occupies, st.curb_zone | LVMC_11_52_030_A |
| a driver | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_217_2 |
| a driver may drive across a pavement striping marking such a zone | kin.extent, prim.region_lateral_offset, ru.aggregate=DEF-NRS-484A-320::vehicle, st.centre_line, st.driveway_or_alley_entrance, st.intersection | NRS_484B_217_2 |
| a person may stop | drv.motion.complete_halt | LVMC_11_52_030_A |
| an authorized emergency vehicle | ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle | NRS_484B_267_2a |
| and making use of flashing lights meeting the requirements of | sig.warning_lamp | NRS_484B_267_2a |
| and shall not move again to the right side of the highway | drv.lane.heading_right_of_carrier, rel.bearing, rel.occupies, st.lane | NRS_484B_270_2b_o3 |
| any vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_52_300 |
| between the hours of one a.m. and six a.m. of any day. | env.civil_time | LVMC_11_52_300 |
| except when otherwise directed by a law enforcement officer: | dev.governs, dev.human_direction, rel.occupies, st.travel_region | NRS_484B_267_2a |
| for a period of time longer than thirty minutes | drv.motion.parked, kin.time | LVMC_11_52_300 |
| for the period necessary to conduct their business, | drv.motion.complete_halt | LVMC_11_52_030_A |
| if a stop sign or a yield sign is erected at one or more entrances thereto | dev.governs, dev.stop_sign, dev.yield_sign, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_2_o1 |
| if the driver has first given the appropriate turn signal | sig.hand_signal, sig.turn_indicator | NRS_484B_217_2 |
| in accordance with the conditions and times posted on an accompanying sign. | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | LVMC_11_52_030_B |
| in accordance with the conditions and times posted on an accompanying sign; and | dev.governs, dev.zone_sign, prim.conditions_hold, rel.occupies, st.travel_region | LVMC_11_52_030_B |
| no person shall park | drv.motion.parked | LVMC_11_52_300 |
| on any street | rel.occupies, st.highway | LVMC_11_52_300 |
| oncoming or following traffic. | rel.bearing, rel.oncoming, rel.same_direction, ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_217_2 |
| or a traffic-control signal: | dev.governs, dev.inoperative, dev.traffic_signal | NRS_484B_257_2_o1 |
| or an official vehicle of a regulatory agency | ru.official_vehicle | NRS_484B_267_2a |
| pass to the left of the bicycle, electric bicycle or electric scooter | rel.bearing, rel.longitudinal_overlap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_2b_o2 |
| prior to entering an intersection | rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_2_o1 |
| proceeding in the same direction, | kin.speed, rel.same_direction | NRS_484B_270_2b_o1 |
| shall not drive on the left side of the highway within such zone or drive across or on the left side | dev.governs, dev.zone_sign, kin.extent, prim.region_lateral_offset, rel.occupies, st.centre_line, st.highway, st.lane, st.lane_marking, st.on_way, st.travel_region | NRS_484B_217_2 |
| shall stop in obedience to a stop sign or yield in compliance with a yield sign, | dev.governs, dev.stop_sign, dev.yield_sign, drv.motion.complete_halt, kin.speed, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.lane_direction, st.region_geometry, st.stop_line | NRS_484B_257_2_o1 |
| such person shall yield | kin.speed, rel.contact | LVMC_11_40_180_C_o1 |
| the driver of a motor vehicle | ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_270_2b_o1 |
| the driver of any other vehicle shall, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_267_2a |
| those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers | drv.motion.complete_halt, rel.occupies | LVMC_11_52_030_A |
| those vehicles may park for a period up to thirty minutes for the loading or unloading of passengers | drv.motion.complete_halt, rel.occupies | LVMC_11_52_030_A |
| to an adjoining highway if the driver has first given the appropriate turn signal | rel.occupies, sig.hand_signal, sig.turn_indicator, st.highway | NRS_484B_217_2 |
| to any pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | LVMC_11_40_180_C_o1 |
| which is moving or preparing to move in any direction, | kin.speed, rel.visible, sig.hand_signal, sig.turn_indicator | NRS_484B_267_2a |

| parameter | unit | convention |
|---|---|---|
| `p.abreast_gap_max` | m | the gap between the bodies of two riders side by side within which they ride abreast in one row: the handlebar-to-handlebar spacing of a group riding side by side plus the source's position error |
| `p.approach_lane_same_direction_cos` | ratio | cosine of the largest angle (about twenty-five degrees) between the designated directions of two mapped lanes entering one intersection at which they count as lanes of the same approach carrying traffic the same way: the direction noise of map lane segments along a gently curving way, far below the angle between the legs of a junction |
| `p.attention_ttc_min` | s | time-to-collision threshold of a critical rear-end conflict |
| `p.bicycle_decel_dry` | m/s^2 | braking deceleration of a bicycle on a dry paved surface in the stopping-sight-distance model (coefficient of friction about 0.32) |
| `p.bicycle_decel_ice` | m/s^2 | braking deceleration on an icy or snow-covered surface (coefficient of friction about 0.05) |
| `p.bicycle_decel_wet` | m/s^2 | braking deceleration of a bicycle on a wet surface in the stopping-sight-distance model (coefficient of friction about 0.16) |
| `p.bicycle_keep_right_gap` | m | the gap between a bicycle or scooter rider's body and the right-hand curb or roadway edge within which the rider counts as riding as near to the right side as practicable: the shy distance a bicyclist keeps from a curb or edge plus the sway of its operating space and the source's position error |
| `p.bicycle_lamp_reach` | m | the distance ahead a bicycle headlamp lights the path in darkness, within which the rider can see an obstacle |
| `p.bicycle_pass_safe_gap` | m | the lateral clearance between the body of a passing motor vehicle and a bicyclist's: the bicyclist's operating-space sway beyond its body width, about one metre of free space beside it |
| `p.bicycle_reaction_time` | s | perception-reaction time of a bicyclist in the stopping-sight-distance model |
| `p.blind_person_approach_reach` | m | the centre distance within which a moving road user has approached a pedestrian carrying a white cane or led by another person: the stopping distance from an urban approach speed of about 13 m/s with a 1 s perception-reaction time and a 4.5 m/s^2 deceleration |
| `p.commensurate_speed_margin` | m/s | the amount by which the speed of nearby traffic travelling the same way may exceed a rider's speed with the rider still counted as keeping pace with it: about five miles per hour, the speed differential within which road users travel as one stream |
| `p.commercial_loading_max_halt` | s | the longest halt of a commercial vehicle counted as expeditious loading or unloading of goods or passengers: the thirty-minute limit common to commercial loading zones |
| `p.conflict_centre_clearance` | m | centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width |
| `p.conflict_horizon` | s | time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash |
| `p.contest_accel_min` | m/s^2 | a sustained acceleration well above ordinary launches (about 0.25 g) held by both vehicles |
| `p.contest_same_direction_cos` | ratio | cosine of the largest heading difference (about 18 degrees) for travel in the same direction |
| `p.contest_window` | s | duration a side-by-side hard acceleration must last to be a contest rather than a merge |
| `p.course_departure_sin_tol` | ratio | sine of the largest angle (about two degrees) between a moving vehicle's heading and its lane's designated direction at which it counts as keeping its course: lane-keeping heading wander plus the source's heading noise, below the few degrees of heading a lane change takes |
| `p.crest_near_reach` | m | the ground distance from a road user's body to a crest within which the road user is on the approach to or near the crest: the length of a crest vertical curve over which forward sight is restricted, about the stopping sight distance at 90 km/h |
| `p.cross_direction_sin_min` | ratio | sine of the smallest angle (thirty degrees) by which a way's designated direction lies to one side of an approach's designated direction for that way's traffic to count as flowing to that side: the legs of a junction meet at larger angles, and map direction noise is far smaller |
| `p.crossing_motion_cos` | ratio | largest absolute cosine between a pedestrian's velocity and a carrier's designated direction at which the pedestrian counts as moving across the carrier rather than along it: motion more than about 20 degrees away from the direction of travel |
| `p.curb_parallel_cos` | ratio | cosine of the largest angle (about fourteen degrees) between a stopped bus's heading and its carrier's designated direction, in either sense, at which the bus counts as approximately parallel to the curb |
| `p.curvature_resolution` | 1/m | the horizontal curvature at or below which a mapped roadway reads as straight: the curvature resolution of map centrelines (a radius of about two kilometres) |
| `p.curve_approach_reach` | m | the distance a road user travels ahead within which a bend it reaches counts as one it is approaching: about the stopping sight distance at 90 km/h, the distance over which a driver must already be slowing for the bend |
| `p.curve_lateral_accel_max` | m/s^2 | the lateral acceleration a passenger vehicle sustains on a curve within comfortable side friction on a dry or wet paved surface (about 0.3 g) |
| `p.delivery_halt_min_duration` | s | the shortest halt counted as a pick-up or delivery stop en route rather than a halt in traffic: the short end of a goods vehicle's curbside dwell |
| `p.door_swing_reach` | m | lateral reach of an open passenger-car side door beyond the vehicle body (a front door opens about 0.9 to 1.1 m) |
| `p.driver_reaction_time` | s | perception-reaction time of an alert driver to an expected hazard in the stopping-distance model |
| `p.edge_standing_gap` | m | the gap between a standing vehicle's body and the curb or roadway edge within which the vehicle counts as standing at that edge: the curb clearance of a parallel-parked vehicle plus the source's position error |
| `p.emergency_approach_reach` | m | centre distance within which a driver approaching an emergency or enforcement vehicle that shows flashing warning lamps counts as approaching it: about the distance at which the lamps are conspicuous by day and a driver at an urban speed of 15 m/s has ten seconds to slow |
| `p.emergency_immediate_approach_reach` | m | centre distance within which an emergency or enforcement vehicle closing on a road user with its warning lamps flashing is in immediate approach: about five seconds of travel at an urban response speed of 20 m/s, the time a driver needs to perceive the lamps and begin to clear the way |
| `p.emergency_lane_change_window` | s | the time from the onset of an approach to an emergency or enforcement vehicle until a driver has moved one lane over: a perception-reaction time of about 1.5 s plus one lane change of about 4 s |
| `p.emergency_pass_clearance` | m | the gap between bodies a driver keeps while passing alongside an emergency or enforcement vehicle: a lateral passing clearance of about half a lane's free width, leaving room for its crew and doors |
| `p.emergency_pullover_window` | s | the longest time from the onset of an emergency vehicle's immediate approach until a driver has moved to the right-hand edge: a perception-reaction time of about 1.5 s plus one or two lane changes of about 4 s each |
| `p.exhibition_accel_min` | m/s^2 | harsh-acceleration threshold: a longitudinal acceleration of about 0.4 g, beyond ordinary driving |
| `p.exhibition_speed_min` | m/s | a speed of about 100 mph, beyond any posted limit in the jurisdiction |
| `p.following_decel_dry` | m/s^2 | braking deceleration of a passenger vehicle on a dry paved surface (coefficient of friction about 0.6) |
| `p.following_decel_ice` | m/s^2 | braking deceleration of a passenger vehicle on an icy or snow-covered surface (coefficient of friction about 0.1) |
| `p.following_decel_wet` | m/s^2 | braking deceleration of a passenger vehicle on a wet paved surface (coefficient of friction about 0.4) |
| `p.following_headway_dry` | s | time headway a following driver keeps on a dry surface: the two-second rule of driver manuals |
| `p.following_headway_ice` | s | time headway a following driver keeps on an icy or snow-covered surface: the tripled following time driver manuals advise |
| `p.following_headway_wet` | s | time headway a following driver keeps on a wet surface or in rain: the two-second rule lengthened by a second |
| `p.free_passage_width` | m | the free lateral width one passing vehicle needs beside a standing vehicle: the width of a design passenger or single-unit vehicle with its lateral clearance, about a narrow traffic lane |
| `p.grade_resolution` | ratio | the longitudinal slope at or below which a roadway reads as level: the grade resolution of map elevation profiles |
| `p.grade_separation_reach` | m | ground distance from a pedestrian's body to a pedestrian tunnel or overpass within which a roadway crossing is made at the point that facility serves: the facility's width plus the stair or ramp landings at either end |
| `p.halt_speed_tolerance` | m/s | the speed at or below which a sampled speed counts as no movement: the source's speed resolution |
| `p.heading_since_step_carla_scene_graph` | ms | The sampling period of the carla_scene_graph acquisition standard, 20 Hz (one scene every 50 ms): the step bound of headingSince, the largest gap between two consecutive scenes it integrates across; not a look-back window and not an action window. |
| `p.immediate_stop_window` | s | the longest time from the moment a stop is due until the road user is at rest for the stop to be immediate: a 1 s perception-reaction time plus the braking time from an urban approach speed of about 13 m/s at 4.5 m/s^2 |
| `p.impeding_speed_margin` | m/s | the amount by which a vehicle's speed below the posted maximum of its way holds back the traffic immediately behind it: about ten miles per hour, the differential at which slow-vehicle turnout and keep-right practice treats a vehicle as slow-moving |
| `p.lane_departure_time_min` | s | the shortest time to line crossing a driver tolerates before correcting its lateral drift: the warning threshold of lane-departure warning systems |
| `p.lane_keeping_heading_error` | ratio | the sine of the heading error (about 1.7 degrees) that a driver's lane keeping leaves uncorrected, so that the vehicle drifts laterally at that fraction of its speed |
| `p.lane_opposed_direction_cos` | ratio | cosine of the largest angle (about twenty-five degrees) off exactly opposed at which the designated directions of two mapped lanes of one way count as opposite directions of travel: the direction noise of map lane segments along a gently curving way |
| `p.lateral_position_tolerance` | m | the lateral margin within which a vehicle body counts as at a line or an edge: lane-keeping variability of a driven vehicle plus the source's position error |
| `p.left_lane_move_over_time` | s | the time a driver needs, once a faster vehicle closes from behind, to check the mirrors, signal and move one lane to the right: a perception-reaction time, a few seconds of signal and the lane change |
| `p.low_beam_sight_reach` | m | the distance ahead a passenger-car low beam lights the road in darkness enough to see an obstacle |
| `p.mail_deposit_max_halt` | s | the longest halt counted as expeditious deposit of mail into a drop box: pull up, post, pull away |
| `p.mail_drop_box_reach` | m | the ground distance from a halted vehicle's body to a mail drop box within which a driver can post mail from the vehicle or a step away |
| `p.meeting_horizon` | s | the time ahead within which two vehicles closing head-on on a narrow two-way road count as meeting, so that each keeps to its half: the decision-and-steering time of a driver adjusting lateral position |
| `p.merge_window` | s | the time an entering or exiting vehicle takes, after coming onto or leaving the controlled-access highway, to complete its merge into or diverge from the highway's traffic: an acceleration or deceleration lane of about 250 m run at about 25 m/s |
| `p.narrow_lane_width` | m | the lane width at or below which a highway's lane counts as narrow: below the 3.3 to 3.6 m design lane width at which a passenger car and a truck meet with comfortable lateral clearance |
| `p.nearby_traffic_reach` | m | the gap between bodies within which another road user counts as nearby traffic: two seconds of headway at an urban speed of about 15 m/s |
| `p.oncoming_heading_cos` | ratio | cosine of the largest angle off exactly opposed headings (about 25 degrees) at which two vehicles count as proceeding in opposite directions |
| `p.overtake_same_direction_cos` | ratio | cosine of the largest heading difference (about 25 degrees) at which two vehicles count as travelling in the same direction while one moves out to pass the other |
| `p.overtake_window` | s | the longest duration of an overtaking manoeuvre on an urban street, from having the overtaken vehicle ahead to having it behind |
| `p.parked_heading_cos` | ratio | cosine of the largest angle (about fourteen degrees) between a standing vehicle's heading and its carrier's designated direction at which it counts as parallel with the edge and headed with traffic |
| `p.parking_min_duration` | s | the longest halt counted as temporary, as for loading or unloading: a common time limit of a passenger loading zone |
| `p.parking_space_angle_resolution` | deg | the bay angle at or below which a mapped parking bay counts as parallel to the curb rather than angled: the source's angle resolution for mapped bays |
| `p.passing_sight_time` | s | the MUTCD minimum passing sight distance (Table 3B-1, the warrant for a no-passing zone) divided by the prevailing speed it is tabulated for: about eleven seconds of travel across 25 to 70 mph; the sight distance or the clear distance a pass needs is the subject's speed times this time |
| `p.ped_signal_facing_cos` | ratio | cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander |
| `p.ped_signal_facing_reach` | m | the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb |
| `p.ped_traffic_signal_facing_cos` | ratio | cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a vehicular signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander |
| `p.ped_traffic_signal_facing_reach` | m | the largest distance from a pedestrian to a vehicular signal head at which the head counts as one the pedestrian faces across the intersection: a wide urban intersection (about 40 m) plus the set-back of a far-side head beyond the far crosswalk |
| `p.pedestrian_clearing_speed_min` | m/s | the speed below which a pedestrian still on the roadway counts as lingering rather than proceeding to a place of safety: about half the 3.0 ft/s (0.9 m/s) walking speed to which pedestrian clearance intervals are timed for slower pedestrians |
| `p.pedestrian_lateral_tolerance` | m | the lateral margin within which a pedestrian's reference point counts as on a line that divides a region or a way: half a pedestrian's shoulder breadth plus the source's position error for a pedestrian |
| `p.pedestrian_near_reach` | m | the ground distance from a pedestrian's body to a place, a region or a vehicle within which the pedestrian is near it: about two walking strides plus a curb step |
| `p.pullover_edge_gap` | m | the gap between a vehicle body and the right-hand curb or roadway edge within which a vehicle pulled over to clear the way counts as as close to the edge as it can be placed: the curb clearance of a parallel-parked car (about 0.3 m) plus lane-keeping variability and an edge margin |
| `p.queue_halt_gap` | m | the gap between bodies to a road user ahead in the same lane within which a halt is a halt behind other traffic: the spacing of halted vehicles in a queue |
| `p.railroad_crossing_approach_reach` | m | the ground distance from a vehicle's body to a railroad grade crossing within which the vehicle is at the crossing, on the stretch where a halt for the crossing is made: the 50-ft outer bound of the zone in which grade-crossing practice places the halt before the nearest rail |
| `p.rear_signal_reach` | m | the gap between bodies within which a following vehicle in the same lane is immediately to the rear of a vehicle: two seconds of headway at an urban speed of about 15 m/s |
| `p.rider_crossing_motion_cos` | ratio | largest absolute cosine between a rider's velocity and a carrier's designated direction at which the rider counts as moving across the carrier rather than along it: motion more than about 20 degrees away from the direction of travel |
| `p.rider_evasive_decel` | m/s^2 | the longitudinal deceleration of a bicycle or scooter rider beyond which its braking counts as an evasive reaction to another road user rather than ordinary speed control: about 0.2 g, above comfortable bicycle braking |
| `p.right_angle_crossing_cos` | ratio | largest absolute cosine between a pedestrian's velocity and a carrier's designated direction at which the motion counts as at right angles to the curb: within about 15 degrees of perpendicular |
| `p.right_side_impede_reach` | m | the gap between a rider's body and an object or road user on its right within which that object impedes the rider's access to the right side of the roadway: about three seconds of travel at a bicyclist's cruising speed of 5 m/s, the distance within which a rider must steer around it |
| `p.roundabout_clockwise_sin_tol` | ratio | the share of a vehicle's speed across the line to the roundabout's centre at or below which its motion counts as towards or away from the centre rather than around it: within about 15 degrees of the radial direction |
| `p.roundabout_critical_gap` | s | critical headway of an entering driver at a single-lane roundabout: the shortest time to the next conflicting road user an entering driver accepts |
| `p.same_time_arrival_window` | s | the largest difference between the times two vehicles reach an intersection's edge at which they count as arriving at approximately the same time: a two-second headway, within which neither can clear the conflict area before the other arrives |
| `p.shared_lane_min_width` | m | the lane width below which a bicycle and a motor vehicle cannot travel safely side by side within the lane: 14 ft, the wide outside lane width of bicycle facility guidance |
| `p.side_by_side_same_direction_cos` | ratio | cosine of the largest heading difference (about 25 degrees) at which two road users standing or moving side by side count as travelling the same way: the heading spread of vehicles queued in adjacent lanes |
| `p.speed_decrease_decel_min` | m/s^2 | the longitudinal deceleration at or beyond which a sampled acceleration counts as a decrease of speed rather than noise or rolling resistance: the acceleration resolution of the source |
| `p.standing_min_duration` | s | the longest halt counted as receiving or discharging passengers or loading rather than standing: a passenger pick-up dwell at the curb |
| `p.steer_angle_resolution` | deg | the front-wheel steering angle at or below which a parked vehicle's wheels read as straight: the steering-angle sensor resolution plus the play of a parked vehicle's wheels |
| `p.stop_point_tolerance` | m | the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin |
| `p.stop_signal_lead_window` | s | the time behind the onset of a halt or a sudden deceleration within which a stop or slow signal shown counts as given first for it: two perception-reaction times of an alert following driver |
| `p.sudden_decel_min` | m/s^2 | the longitudinal deceleration beyond which a decrease of speed counts as sudden: the comfortable deceleration most drivers use when braking for an expected stop |
| `p.traffic_side_door_max_open` | s | the longest time a traffic-side door stays open for immediate loading or unloading: a passenger pick-up or drop-off dwell at the curb |
| `p.truck_space_open_time` | s | the time a following heavy vehicle needs to open a space behind a leader that has come ahead of it, easing off by a few miles per hour: about 150 m at a closing speed near 5 m/s |
| `p.turn_heading_min` | deg | the smallest heading change over the turn window at which a change of course counts as a turn rather than a lane change or a drift |
| `p.turn_window` | s | the longest duration of a turn at a junction by a bicycle or a scooter, from the start of its heading change to its end |
| `p.turn_yaw_rate_tol` | deg/s | the yaw-rate magnitude at or below which a road user's heading counts as no longer turning: the yaw-rate noise floor of the source |
| `p.u_turn_heading_min` | deg | the smallest heading change magnitude over the turn window at which a turn counts as a reversal of direction |
| `p.usable_path_width_min` | m | the narrowest width of a bicycle path at which one bicycle or scooter rider can operate on it: the essential operating space of a bicyclist |
| `p.vehicle_evasive_decel` | m/s^2 | the longitudinal deceleration of a motor vehicle at or beyond which its braking counts as an evasive reaction to another road user rather than ordinary speed control: about 0.4 g, above the comfortable deceleration of about 3.4 m/s^2 |
| `p.vehicle_turn_window` | s | the longest duration of a turn by a motor vehicle at a junction or into or out of a driveway, from the start of its heading change to its end, including the crossing of opposing lanes |
| `p.yield_line_speed_max` | m/s | the speed at or below which a vehicle at the place of a yield sign counts as having slowed: the speed from which a passenger car can still halt within the stop-point tolerance at a comfortable deceleration of about 4.5 m/s^2 |
| `p.zone_entry_wait_reach` | m | the ground distance from a halted vehicle's body to a curb zone within which the vehicle counts as waiting to enter the zone: about one design passenger-car length plus the spacing of halted vehicles in a queue |

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

### Parameters proposed this iteration by an earlier batch (not entered in the reading until their nodes are coded: every node that uses one the catalogue above lacks proposes it again in its own `param_proposals`, with the same name, value, unit and convention)
| parameter | value | unit | convention | node |
|---|---|---|---|---|
| `p.bicycle_pass_safe_gap` | 1.0 | m | the lateral clearance between the body of a passing motor vehicle and a bicyclist's: the bicyclist's operating-space sway beyond its body width, about one metre of free space beside it | NRS_484B_270_2b_o2 |
| `p.conflict_centre_clearance` | 3.0 | m | centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width | LVMC_11_40_180_C_o1 |
| `p.conflict_horizon` | 3.0 | s | time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash | LVMC_11_40_180_C_o1 |
| `p.contest_same_direction_cos` | 0.95 | ratio | cosine of the largest heading difference (about 18 degrees) for travel in the same direction | NRS_484B_217_2 |
| `p.course_departure_sin_tol` | 0.035 | ratio | sine of the largest angle (about two degrees) between a moving vehicle's heading and its lane's designated direction at which it counts as keeping its course: lane-keeping heading wander plus the source's heading noise, below the few degrees of heading a lane change takes | NRS_484B_270_2b_o3 |
| `p.emergency_approach_reach` | 150.0 | m | centre distance within which a driver approaching an emergency or enforcement vehicle that shows flashing warning lamps counts as approaching it: about the distance at which the lamps are conspicuous by day and a driver at an urban speed of 15 m/s has ten seconds to slow | NRS_484B_267_2a |
| `p.following_headway_dry` | 2.0 | s | time headway a following driver keeps on a dry surface: the two-second rule of driver manuals | NRS_484B_270_2b_o3 |
| `p.following_headway_ice` | 6.0 | s | time headway a following driver keeps on an icy or snow-covered surface: the tripled following time driver manuals advise | NRS_484B_270_2b_o3 |
| `p.following_headway_wet` | 3.0 | s | time headway a following driver keeps on a wet surface or in rain: the two-second rule lengthened by a second | NRS_484B_270_2b_o3 |
| `p.halt_speed_tolerance` | 0.1 | m/s | the speed at or below which a sampled speed counts as no movement: the source's speed resolution | LVMC_11_40_180_C_o1 |
| `p.lateral_position_tolerance` | 0.3 | m | the lateral margin within which a vehicle body counts as at a line or an edge: lane-keeping variability of a driven vehicle plus the source's position error | NRS_484B_217_2 |
| `p.mail_deposit_max_halt` | 60.0 | s | the longest halt counted as expeditious deposit of mail into a drop box: pull up, post, pull away | LVMC_11_52_030_A |
| `p.mail_drop_box_reach` | 3.0 | m | the ground distance from a halted vehicle's body to a mail drop box within which a driver can post mail from the vehicle or a step away | LVMC_11_52_030_A |
| `p.oncoming_heading_cos` | 0.9 | ratio | cosine of the largest angle off exactly opposed headings (about 25 degrees) at which two vehicles count as proceeding in opposite directions | NRS_484B_217_2 |
| `p.overtake_same_direction_cos` | 0.9 | ratio | cosine of the largest heading difference (about 25 degrees) at which two vehicles count as travelling in the same direction while one moves out to pass the other | NRS_484B_270_2b_o1 |
| `p.overtake_window` | 10.0 | s | the longest duration of an overtaking manoeuvre on an urban street, from having the overtaken vehicle ahead to having it behind | NRS_484B_270_2b_o1 |
| `p.parking_min_duration` | 180.0 | s | the longest halt counted as temporary, as for loading or unloading: a common time limit of a passenger loading zone | LVMC_11_52_300 |
| `p.queue_halt_gap` | 5.0 | m | the gap between bodies to a road user ahead in the same lane within which a halt is a halt behind other traffic: the spacing of halted vehicles in a queue | LVMC_11_52_030_A |
| `p.rider_evasive_decel` | 2.0 | m/s^2 | the longitudinal deceleration of a bicycle or scooter rider beyond which its braking counts as an evasive reaction to another road user rather than ordinary speed control: about 0.2 g, above comfortable bicycle braking | NRS_484B_270_2b_o1 |
| `p.speed_decrease_decel_min` | 0.3 | m/s^2 | the longitudinal deceleration at or beyond which a sampled acceleration counts as a decrease of speed rather than noise or rolling resistance: the acceleration resolution of the source | NRS_484B_267_2a |
| `p.stop_point_tolerance` | 2.0 | m | the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin | NRS_484B_257_2_o1 |
| `p.vehicle_turn_window` | 10.0 | s | the longest duration of a turn by a motor vehicle at a junction or into or out of a driveway, from the start of its heading change to its end, including the crossing of opposing lanes | NRS_484B_217_2 |
| `p.yield_line_speed_max` | 4.2 | m/s | the speed at or below which a vehicle at the place of a yield sign counts as having slowed: the speed from which a passenger car can still halt within the stop-point tolerance at a comfortable deceleration of about 4.5 m/s^2 | NRS_484B_257_2_o1 |

### Declared-fact ids (assumptions `asm.*`, declared intentions `int.*`): reuse an id whose meaning is the words' meaning
| id | meaning | status |
|---|---|---|
| `asm.business_district` | the place of the road user at the observation lies in a business district, as the map's reading classifies the area | proposed |
| `asm.business_or_residence_district` | the place of the road user at the observation lies in a business district or a residence district, as the map's reading classifies the area | proposed |
| `asm.fremont_street_main_to_seventh` | the place of the road user at the observation lies on Fremont Street between Main Street and Seventh Street, as the map's reading records the named way and its limits | proposed |
| `asm.left_curb_parking_permitted` | the one-way way at the place of the road user at the observation is one on which the local authority having jurisdiction permits vehicles to park with their left-hand wheels at the left-hand curb, as the map's reading records | proposed |
| `asm.local_alley_ordinance` | the alley at the place of the road user at the observation is one on which an ordinance of the local authority having jurisdiction regulates stopping, standing or parking by provisions of its own, as the map's reading records | proposed |
| `asm.public_access_premises` | the place of the road user at the observation lies on premises to which the public has access, as the map's reading classifies the area | proposed |
| `asm.pupils_in_class` | the pupils of the school served by the signed zone at the road user's place are in class at the time of the observation, as the reading declares from that school's schedule | proposed |
| `asm.school_in_session_day` | the date of the observation is a day on which the school served by the signed zone at the road user's place is in session, as the reading declares from that school's calendar | proposed |
| `asm.school_outside_operation_margin` | the time of the observation lies in the period from a half hour after the school served by the signed zone at the road user's place ceased operation to a half hour before that school next begins operation, as the reading declares from that school's schedule | proposed |
| `asm.within_city_limits` | the place of the road user at the observation lies within the territorial limits of the incorporated city whose ordinances the reading applies, as the map's reading classifies the area | proposed |
| `asm.within_city_or_town_limits` | the place of the road user at the observation lies within the geographical limits of an incorporated city or of a town, as the map's reading classifies the area | proposed |
| `asm.within_incorporated_city` | the place of the road user at the observation lies within the territorial limits of an incorporated city, as the map's reading classifies the area | proposed |
| `int.left_turn` | the source's current plan for the road user includes a turn to the left at the target region, the plan's preparation for that turn included | proposed |
| `int.right_turn` | the source's current plan for the road user includes a turn to the right at the target region, the plan's preparation for that turn included | proposed |

| id | state | kind | span | proposal | decision |
|---|---|---|---|---|---|
| G17 | proposed | atom | does not have a clear and unobstructed view of such crossing and of any traffic  | `st.sight_along_railway` | the distance along a railway, in each direction from its crossing with the roadway, within wh |  |
| G18 | proposed | atom | no person shall aid or abet in | `rel.contest_assistance` | relation: road user a assists road user b's speed contest or exhibition on the road — startin |  |
| G19 | proposed | atom | over or across any pavement newly laid or repaired | `st.fresh_pavement` | a stretch of pavement newly laid or repaired and not yet open to travel (uncured asphalt or concre |  |
| G20 | proposed | atom | The provisions of this Section shall not apply to the employees actually engaged | `ru.road_work_activity` | the road user is engaged, at the observation, in work on the way at its place: paving, surfaci |  |
| G21 | proposed | atom | by motor-driven cycles, bicycles, horse-drawn vehicles or other nonmotorized tra | `ru.animal_drawn_vehicle` | a vehicle drawn by a horse or another animal (a carriage, cart or wagon), together with the  |  |
| G22 | proposed | atom | (2) Any vehicle that is being used in connection with maintenance of the right-o | `ru.road_work_activity` | the road user is engaged, at the observation, in work on the way at its place: paving, surfaci |  |
| G23 | proposed | atom | shall carry at least one lighted headlamp capable of showing a white light visib | `ru.lamp_equipment` | the lamps a vehicle is equipped with, lit or not: per lamp, **position** ∈ {front, rear, side}, ** |  |
| G24 | proposed | operator | shall obey the instructions of official traffic-control signals, signs and other | `ruleAsClass` (id, map, aggregate): another rule complied with by the mapped road users, its subject binder's class cond |  |
| G25 | proposed | operator | in which event such person shall then obey the regulations applicable to pedestr | `compliesWithClassRules` (aggregate, who): at an observation, every rule of the set whose subject binder's class is the  |  |
| G26 | proposed | atom | in a rack to support the bicycle, electric bicycle, or electric scooter | `st.bicycle_rack` | a fixed stand on a sidewalk or beside the roadway built to hold parked bicycles and the devices a ju |  |
| G27 | proposed | atom | or against a building | `st.building` | a building beside the highway, carried as a region with its outline (the face of its wall toward the way |  |
| G28 | proposed | atom | on any other sidewalk | `dev.governs_walkway` | relation: the sidewalk regions whose use a sign erected for them controls — a sign prohibiting r |  |
| G29 | proposed | atom | in excess of eight thousand pounds unladen weight | `ru.unladen_weight` | the mass of a vehicle without its load, as registered for it or as the source measures it (an attr |  |
| G30 | proposed | atom | provided, however, that the Department of Public Works may, at its discretion, u | `ru.special_permit` | a vehicle moving under a written special permit an authority has issued for it, with the permit's  |  |
| G31 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G32 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G33 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G34 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G35 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G36 | proposed | atom | In front of any sidewalk elevator or chute | `st.sidewalk_elevator_or_chute` | a freight elevator, lift or chute set in a sidewalk, its doors or opening at the sidew |  |
| G37 | proposed | operator | in compliance with law | `Formula.requiredByRuleSet (who : Arg)`: true at an observation where some rule of the set, engaged there for road user  |  |
| G38 | proposed | atom | In front of or within five feet of a public or private driveway; | `st.driveway_entrance` | the place where a driveway, a way used for vehicular travel to a property (in private ownership |  |
| G39 | proposed | atom | by a person who owns or is in control of that driveway, or who is a family membe | `rel.premises_privilege` | relation: the road user's vehicle is controlled by the person who owns or is in control of a  |  |
| G40 | proposed | atom | The provisions of Paragraphs (1) and (7) of Subsection (A) of this Section do no | `ru.postal_vehicle` | a vehicle of the national postal service, identifiable by its livery **Not a stand-in for:** an of |  |
| G41 | proposed | operator | shall not park for a greater period than thirty minutes within any one-hour peri | durationWithin (m : Measure) (d : Term) (subject : String) (φ : Formula) : Term -- the total time, within the window of  |  |
| G42 | proposed | atom | or as permitted by posted sign, | `dev.parking_permission_sign` | a posted sign permitting the standing, parking or storage of a vehicle class at the plac |  |
| G43 | proposed | atom | or an unladen weight in excess of eight thousand pounds. | `ru.unladen_mass` | the mass of a vehicle without load, as registered or measured (kg); for a combination, the sum of it |  |
| G44 | proposed | atom | or (2) Being used in conjunction with the performance of service, repair, constr | `ru.work_service_use` | the vehicle is in use for service, repair, construction or similar work at a site near where it  |  |
| G45 | proposed | atom | for the route to which such vehicle is assigned | `rel.route_terminus_of` | relation: a signed bus place is the origin or destination point of the transit route a bus is  |  |
| G46 | proposed | atom | for the route to which such vehicle is assigned | `rel.route_terminus_of` | relation: a signed bus place is the origin or destination point of the transit route a bus is  |  |
| G47 | proposed | atom | except in case of an emergency. | `env.emergency` | a sudden peril at the observation that a road user's conduct answers to (a fire, a medical emergency o |  |
| G48 | proposed | atom | for a period of time longer than has been designated for such bus stop or origin | `dev.posted_duration_limit` | the longest duration of standing or parking that a posted sign states for the stop, stand  |  |
| G49 | proposed | atom | The provisions of subsection 1 do not apply to a vehicle that is powered solely  | `ru.electric_three_wheeler` | a vehicle propelled solely by an electric motor and built to travel on three wheels in con |  |
| G50 | proposed | atom | (b) By an officer or other authorized employee of a law enforcement agency, | `ru.operator_role` | the role in which the person at a vehicle's controls operates it, as the source records it: **role* |  |
| G51 | proposed | atom | in the course of his or her official duties; or | `ru.operator_role` | the role in which the person at a vehicle's controls operates it, as the source records it: **role* |  |
| G52 | proposed | atom | (c) By a security guard, | `ru.operator_role` | the role in which the person at a vehicle's controls operates it, as the source records it: **role* |  |
| G53 | proposed | atom | in the course of his or her official duties. | `ru.operator_role` | the role in which the person at a vehicle's controls operates it, as the source records it: **role* |  |
| G54 | proposed | atom | in a caravan or motorcade | `ru.procession_member` | a road user travelling as a member of an organized group of vehicles proceeding together in a c | filed for the gap carried over from run smoke31-1111-0039 (its G17, commit fafc6b19d1e7) on NRS-484B-127-3@0780f8aca9bc464c:76-101 |
| G55 | proposed | atom | or past any private way that is used to enter or exit the highway. | `st.private_way_entrance` | the place where a way in private ownership — a private road or driveway — meets the highway, |  |
| G56 | proposed | operator | a person lawfully riding | lawful (who : Arg) — a Formula that holds at an observation where the road user `who` complies there with every rule of  |  |
| G57 | proposed | atom | (d) In the performance of official duties; | ru.on_official_duty | the road user is being used, at the observation, in the performance of the duties of a public offi |  |
| G58 | proposed | atom | (b) When operating or parking a disabled vehicle; | ru.disabled | a vehicle that cannot move under its own power or cannot be driven on (a breakdown, crash damage, a flat t | filed for the gap carried over from run smoke31-1111-0039 (its G19, commit fafc6b19d1e7) on NRS-484B-270-3@bcef26b221a13592:455-504 |
| G59 | proposed | atom | (f) In an emergency. | env.emergency | a sudden peril at the observation that a road user's conduct answers to (a fire, a medical emergency, a  | filed for the gap carried over from run smoke31-1111-0039 (its G20, commit fafc6b19d1e7) on NRS-484B-270-3@bcef26b221a13592:652-672 |
| G60 | proposed | atom | including, without limitation, a short section of the sidewalk that is missing o | st.impassable_section | a stretch of a sidewalk, or of the ground between a sidewalk and a roadway or bicycle lane, that | filed for the gap carried over from run smoke31-1111-0039 (its G18, commit fafc6b19d1e7) on NRS-484B-297-6@5a178d4df6df22d1:128-221 |
| G61 | proposed | atom | (c) May walk or otherwise travel in a lane provided for bicycles, electric bicyc | st.impassable_section | a stretch of a sidewalk, or of the ground between a sidewalk and a roadway or bicycle lane, that |  |
| G62 | proposed | operator | to disobey the instructions of any official traffic-control device | `compliesWithDeviceRules (subject)`: true at an observation where every rule of the set that states the instruction an o |  |
| G63 | proposed | atom | when transporting pupils to and from school. | `ru.pupil_transport_service` | a school bus is on a trip carrying pupils to or from a school or a school activity, as th |  |
| G64 | proposed | atom | This section shall not apply to the driver of any vehicle which is disabled whil | `ru.disabled` | the vehicle cannot move under its own power (a breakdown, damage, a flat tyre), as the source records it |  |
| G65 | proposed | operator | or in compliance with law | `compliesWithEngaged` (Formula.compliesWithEngaged (binder map)): an operator that decides whether, at an observation, t |  |
| G66 | proposed | operator | or in compliance with law | `compliesWithEngaged` (Formula.compliesWithEngaged (binder map)): an operator that decides whether, at an observation, t | filed for the gap carried over from run smoke31-1111-0039 (its G22, commit fafc6b19d1e7) on NRS-484B-450-1c@246833c41d20e47e:109-134 |
| G67 | proposed | operator | or in compliance with law | `compliesWithEngaged` (Formula.compliesWithEngaged (binder map)): an operator that decides whether, at an observation, t |  |
| G68 | proposed | atom | Within 50 feet of the nearest rail of a railroad. | | `st.railway_track` | the rails of a railway wherever they run on or beside a highway, crossing the roadway or not, eac |  |
| G69 | proposed | operator | shall not stop, stand or park a vehicle other than at the angle to the curb or e | Term.cosDeg (a : Term) : the cosine of an angle a given in degrees, a ratio; unknown where a is unknown. It decides wher |  |
| G70 | proposed | operator | lawfully | Formula.compliesWithEngaged (who : Arg) (conduct : String) : at the observation, every rule of the set that governs cond |  |
| G71 | proposed | atom | in such position as to block the driveway or entrance to any abutting property. | `st.property_entrance` | a driveway, private road or other entrance by which abutting property is entered from a highway |  |
| G72 | proposed | atom | use alternate routes whenever possible. | `st.alternate_route` | relation: for a road user on a controlled-access highway, a way of the road network other than a  |  |
| G73 | proposed | atom | shall give all signals by hand and arm in the manner required | `sig.hand_signal_posture` | the posture of a driver's or rider's arm signal: **arm** in {left, right}, the arm extended; |  |
| G74 | proposed | atom | except that the operator may give a signal for a right turn by extending his or  | `sig.hand_signal_posture` | the posture of a driver's or rider's arm signal: **arm** in {left, right}, the arm extended; |  |
| G75 | proposed | atom | any unprotected hose | `st.protected_hose` | a hose lying on or across a way that a hose bridge or ramp covers, so that a vehicle crossing it d |  |
| G76 | proposed | atom | without the consent of the fire department official in command. | `dev.fire_official_direction` | the fire department official in command at a fire scene directing road users, and the di |  |
| G77 | proposed | atom | (c) When directed by an official traffic control device. | `dev.lamps_on_sign` | a regulatory sign directing road users to display lighted lamps (headlamps on) where it governs, w |  |
| G78 | proposed | atom | during the times specified in | | `dev.lamps_on_sign` | an official sign or device directing road users to display lighted lamps (headlamps on) where it |  |
| G79 | proposed | atom | making use of flashing lights meeting the requirements of | a formula-surface reading of the facing attribute of sig.warning_lamp (e.g. sig_warning_lamp [x, colour, mode, facing],  |  |
| G80 | proposed | atom | making use of flashing lights meeting the requirements of | a formula form of sig.warning_lamp that reads the lamp's facing: sig_warning_lamp [track, colour, mode, facing] (facing  |  |
| G81 | proposed | atom | and making use of flashing lights meeting the requirements of | A formula-readable facing of a lit warning lamp: sig.warning_lamp read with colour, mode and facing ([x, colour, mode, f |  |
| G82 | proposed | atom | The operator of a taxicab | An observable road-user class for the admitted aggregate DEF-LVMC-11-02-140::taxicab ('a motor vehicle which is properly |  |
| G83 | proposed | atom | The operator of a bus, | An observable class or attribute that carries what DEF-NRS-484A-030 makes a bus: a vehicle 'owned by the State, a politi |  |
| G84 | proposed | atom | and making use of flashing lights meeting the requirements of | an atom form of sig.warning_lamp that reads the lamp's facing (road user, colour, mode, facing ∈ {front, rear, side}), s |  |
| G85 | proposed | atom | making use of flashing lights meeting the requirements of | A Boolean surface form of sig.warning_lamp that reads the lamp's facing attribute together with its colour and mode, e.g |  |
| G86 | proposed | atom | An authorized emergency vehicle | A road-user class that decides membership of 'an authorized emergency vehicle' (DEF-NRS-484A-020::authorized_emergency_v |  |
| G87 | proposed | operator | (1) The person stops before entering the crosswalk on the nearest side of the in | A way to write the text's figure 'two' in '(2) The person waits for two complete cycles of the lights or lighted arrows  |  |
| smoke31-1111-0039:G21 | proposed | atom | and (c) When directed by an official traffic control device. | `dev.lamps_on_sign` | a regulatory sign directing road users to display lighted lamps (headlamps on) where it governs, a | carried over pending from run smoke31-1111-0039 (its G21, commit fafc6b19d1e7) on NRS-484D-100-1@230cefc3f0568ebc:558-618 |

# Feedback from iteration 3

concept `drv.motion.right_turn`: not repaired, no node uses it
`NRS_484B_267_1b_o2`: the repair session withdrew it — the vocabulary lacks atom `a formula-surface reading of the facing attribute of sig.warning_lamp (e.g. sig_warning_lamp [x, colour, mode, facing], or a selector sig_warning_lamp_facing [x, facing]). Span u4, together with the words that the definition reference u5 borrows from DEF-NRS-484A-480-3 ('at least one flashing red warning lamp visible from the front'), is a condition on when the duty arises. It decides which road users the duty concerns and when it arises: the approaching authorized emergency vehicle or regulatory-agency vehicle triggers the duty only while it shows a flashing red lamp that is visible from the front. The ontology's contract gives sig.warning_lamp a facing attribute in {front, rear, side}, but Core's evaluator only reads the atom by colour and mode, so the rule can only state 'a red flashing warning lamp lit, in any facing'. That fact is weaker than the condition, because a vehicle that shows a flashing red lamp only to the rear or side would also trigger the duty. Rule 3 says a condition is never narrowed or weakened, and no other atom carries the lamp's facing, so the span is withdrawn until Core exposes the facing selector. Once it does, the record as planned (colour red, mode flashing, facing front) codes as is: the coder's run 2 passed the gate with every other element written.` for span u4; gap G79 filed, law blocked
`NRS_484B_267_1c`: the repair session withdrew it — the vocabulary lacks atom `a formula form of sig.warning_lamp that reads the lamp's facing: sig_warning_lamp [track, colour, mode, facing] (facing ∈ {front, rear, side}, as the atom's contract already lists). The condition u4, with the words it borrows from u5 (DEF-NRS-484A-480-3: 'at least one flashing red warning lamp visible from the front'), holds only when the approaching vehicle is making use of a flashing red warning lamp facing front. Core's evaluator reads sig_warning_lamp only as [track, colour] or [track, colour, mode], so 'visible from the front' cannot be written. Writing a lit red flashing lamp of any facing is a weaker fact on a condition span. It would trigger the duty for a vehicle showing only rear- or side-facing red flashers as it closes from behind, a vehicle the law does not cover. So the missing form decides whether the duty to stop arises at all, and toward which approaching road users it is owed. Red and flashing are carried; only the facing lacks a form.` for span u4; gap G80 filed, law blocked
`NRS_484B_267_2d`: the repair session withdrew it — the vocabulary lacks atom `A formula-readable facing of a lit warning lamp: sig.warning_lamp read with colour, mode and facing ([x, colour, mode, facing], facing in {front, rear, side}), so that a rule can state that the approached vehicle shows a lit red warning lamp, mode flashing, facing front. This is the trigger s3 carries with the words s4 borrows from DEF-NRS-484A-480-3, 'at least one flashing red warning lamp visible from the front'. The atom's contract lists the facing attribute, but its formula surface takes only [x, colour] or [x, colour, mode]: atomArgSorts admits at most two literal positions for sig_*. So no formula can read the facing. Without it, the trigger can only be written as 'a red flashing lamp', which is weaker than the words. A vehicle whose only red flashing lamp faces the rear or the side would then engage the duty. That would widen when the duty arises, and rule 3 forbids narrowing or weakening a trigger. The distinction this decides is which road users the duty concerns: whether the approached vehicle is making use of lights that meet NRS 484A.480(3), so that drivers must not drive abreast of it or overtake it. 'Visible from the front' describes the lamp's orientation on the approached vehicle. It is not the subject's line of sight: the subject usually approaches from behind, where a front-facing lamp is not in its view. So the words cannot be re-mapped to an existing readable atom.` for span s3; gap G81 filed, law blocked
`NRS_484B_203_1_o1`: revised by a repair session; coded again this iteration
`LVMC_11_43_010_A`: revised by a repair session; coded again this iteration
`LVMC_11_60_040`: the repair session withdrew it — the vocabulary lacks atom `An observable road-user class for the admitted aggregate DEF-LVMC-11-02-140::taxicab ('a motor vehicle which is properly licensed under State and local law to provide taxicab service for a charge or fee') that the run's reading can classify as included. Right now the reading lists no included class under that id and marks ru.taxicab as unresolved. So ru.aggregate=DEF-LVMC-11-02-140::taxicab can never be true: it is unknown for every taxicab and false for everything else. The s1 binder class, and the same aggregate on s5, therefore never let the duty be judged. The span decides which road users the duty concerns: the taxicab whose standing outside a taxicab stand is forbidden. One of two things is needed. Either a class atom whose contract carries the licence to provide taxicab service, or an operator decision that this licensing status is read through the taxicab's markings (an observable_reading of category status, under which ru.taxicab is classified as included in DEF-LVMC-11-02-140::taxicab). In both cases the rule, mappings and witnesses written for this node need no further change.` for span s1; gap G82 filed, law blocked
`LVMC_11_43_010_C1`: revised by a repair session; coded again this iteration
`NRS_484B_270_7b`: revised by a repair session; coded again this iteration
`LVMC_11_60_030_A4`: the repair session withdrew it — the vocabulary lacks atom `An observable class or attribute that carries what DEF-NRS-484A-030 makes a bus: a vehicle 'owned by the State, a political subdivision or a private school or nursery, designed for carrying more than 10 passengers and used for the transportation of persons', or a vehicle 'other than a taxicab, designed and used for the transportation of persons for compensation'. Without it the run's reading cannot include any road-user class under DEF-NRS-484A-030::bus. It now records 'included (none)', with ru.bus, ru.transit_bus, ru.school_bus and ru.tour_bus_or_limousine all unresolved. So the subject's binder class (c1) is never decided true, and the duty is reported only as not_applicable or unknown, never compliant or violated. The exception span c2 (DEF-LVMC-11-02-150::tour_bus) has the same defect. That definition covers a motor vehicle 'other than a limousine ... designed, maintained and used to transport more than six persons ... to or from hotels, motels, casinos, cultural or athletic events or other tourist attractions'. No class atom carries that service apart from limousines, so the reading leaves every class unresolved and no bus is decidedly not a tour bus. The gap decides which road users the duty concerns. Mapping c1 and c2 to ru.bus or ru.transit_bus instead would expand an admitted aggregate into a class list, which rule 4 and the ru.aggregate contract forbid. The operator may instead review the run's reading: whether ru.transit_bus and ru.school_bus are included under DEF-NRS-484A-030::bus ('owned by ... a political subdivision', 'used for the transportation of persons for compensation'), and whether ru.transit_bus is excluded or covered under DEF-LVMC-11-02-150::tour_bus. The record is otherwise faithful. The coder's rule and witnesses (forbid, permit, idle, blind, branch_1, branch_2) are expected to pass once these classes are decided.` for span c1; gap G83 filed, law blocked
`LVMC_11_40_180_C_o1`: revised by a repair session; coded again this iteration
`LVMC_11_40_180_A`: revised by a repair session; coded again this iteration
`LVMC_11_52_030_B`: revised by a repair session; coded again this iteration
`LVMC_11_43_010_B_o1`: revised by a repair session; coded again this iteration
`NRS_484B_785_1a`: revised by a repair session; coded again this iteration
`LVMC_11_30_060_A`: revised by a repair session; coded again this iteration
`LVMC_11_52_030_A`: revised by a repair session; coded again this iteration
`NRS_484B_450_1l`: revised by a repair session; coded again this iteration
`NRS_484B_363_4`: revised by a repair session; coded again this iteration
`NRS_484B_267_2c`: the repair session withdrew it — the vocabulary lacks atom `an atom form of sig.warning_lamp that reads the lamp's facing (road user, colour, mode, facing ∈ {front, rear, side}), so that a trigger can state the words s3 borrows through s4 from DEF-NRS-484A-480-3, 'at least one flashing red warning lamp visible from the front': a lit red lamp, mode flashing, facing front. The surface reads sig_warning_lamp only as [x, colour] or [x, colour, mode], and no accessor reads WarningLamp.facing, so the trigger can only require a red flashing lamp of any facing. That would apply the duty to a vehicle that shows only rear-facing or side-facing red flashing lamps, which the borrowed words exclude. The words decide which lit vehicles trigger the duty, that is, the road users it concerns. Dropping the facing would weaken a trigger span, and re-quoting the source's permissive 'may display ... to the front, sides or rear' clause would replace the requirements the words name with a permission. Neither is a faithful re-mapping.` for span s3; gap G84 filed, law blocked
`NRS_484B_260`: revised by a repair session; coded again this iteration
`NRS_484B_263_o1`: revised by a repair session; coded again this iteration
`NRS_484B_267_1a`: the repair session withdrew it — the vocabulary lacks atom `A Boolean surface form of sig.warning_lamp that reads the lamp's facing attribute together with its colour and mode, e.g. sig_warning_lamp [x, colour, mode, facing], true where road user x shows a lit warning lamp of that colour, mode and facing. The ontology's contract for sig.warning_lamp lists facing ∈ {front, rear, side}, but the formula language only reads colour, or colour and mode (Atoms.lean sig_warning_lamp_shows). Span u4 ('making use of flashing lights meeting the requirements of') borrows from u5 (DEF-NRS-484A-480-3) the words 'at least one flashing red warning lamp visible from the front'. So the condition needs a lit warning lamp that is red, flashing and facing front. Without facing, the rule would treat a vehicle showing only side or rear red flashing lamps as making use of the required lights. That widens a condition span and changes which approaching vehicles the duty concerns, i.e. the road users it concerns and when it arises. A condition is never narrowed or widened, so the span cannot be carried and is not dropped.` for span u4; gap G85 filed, law blocked
`NRS_484D_400_5`: the repair session withdrew it — the vocabulary lacks atom `A road-user class that decides membership of 'an authorized emergency vehicle' (DEF-NRS-484A-020::authorized_emergency_vehicle: 'a vehicle permitted to depart from certain traffic laws when equipped and operated in the manner provided by law'). The run's reading admits this aggregate but classifies every road-user class under it as unresolved, ru.emergency_vehicle, ru.fire_apparatus and ru.motor_vehicle included, and none as included. Under ru.aggregate membership is then never true, and it is unknown for every vehicle. The siren duty (s3) and its exception (s4, s5) are therefore never decided for any road user. No faithful record can reach a violated or compliant verdict, and a private car is never decidedly outside the subject class. The span needs either an observable class that carries the authorization (a vehicle bearing the designation and equipment of an authorized emergency vehicle) or the reading's classification of the definition's members, for example ru.emergency_vehicle and ru.fire_apparatus as included and ru.motor_vehicle as covered or excluded. This decides the road users the duty concerns: which vehicles may not use a siren except in response or pursuit.` for span s1; gap G86 filed, law blocked
`NRS_484B_267_2f_o2`: the repair session withdrew it; the law is returned to the planner
`NRS_484B_307_9b`: the repair session withdrew it — the vocabulary lacks operator `A way to write the text's figure 'two' in '(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device' as a typed count literal that the formula language carries and the gate's literal check reads. Each complete cycle is a rise of the governing head's display, and the count runs from the start of the subject's run at rest at the place. The only operator that counts rising edges is Formula.count, and its bound is a bare Nat. Formula.literals never reports it, so a faithful rule, `count (circular_red ∧ green_arrow) (complete_halt) ge 2`, shows no literal, and the gate refuses it as BARE_LITERAL against the declared literal (s6, 2, count). Two fixes would close the gap: Formula.count could take its bound as a Term (a Term.lit in unit count), or Formula.literals and the gate's literal collection could report count's bound as (n, count). The distinction this decides for the driving task: the minimum wait at the red with the green turn arrow before the subject may proceed against it. That wait is how long the act requires, and it separates a lawful proceed after a detector failure (two cycles) from running the red after one. The record itself is faithful. A diagnostic gate run passed all 28 witnesses (OK) once the literal check was satisfied. The only way to pass now would be to add a made-up tautological Term.lit 2 count conjunct, or to drop the figure the law states from the record's literals, and the rules forbid both.` for span s6; gap G87 filed, law blocked
`NRS_486_341`: revised by a repair session; coded again this iteration
`NRS_484B_560_3_o2`: revised by a repair session; coded again this iteration
`NRS_486_351_2`: revised by a repair session; coded again this iteration
`NRS_484B_517`: revised by a repair session; coded again this iteration
`LVMC_11_52_300`: revised by a repair session; coded again this iteration
`NRS_484B_263_o2`: revised by a repair session; coded again this iteration
`NRS_484B_307_8d`: revised by a repair session; coded again this iteration
`NRS_484B_223_4a`: revised by a repair session; coded again this iteration
`NRS_484B_208_1`: revised by a repair session; coded again this iteration
`NRS_484B_587_2b`: revised by a repair session; coded again this iteration
`NRS_484B_587_2a`: revised by a repair session; coded again this iteration
concept `drv.interaction.overtake_pass_on_right`: re-proposed by a repair session
`NRS-484B-307-8a`: a held node no longer validates beside the current plan; returned to the planner, no attempt counted
concept `drv.lane.heading_left_of_carrier`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.interaction.overtake_pass_on_right`: gate OK — 3 witnesses, 6 names, reads 6 atom(s)
concept `drv.interaction.overtake_pass_on_right`: accepted; the review's notes are recorded on it — Tested a one-second right-side pass with window = 2 s and a recording beginning at its aligned-ahead onset. The body holds at recognition despite the shorter recording, agreeing with the contract …
`NRS_484B_217_2`: not coded — `NRS_484B_217_2` composes or calls `NRS_484B_413_2` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_257_2_o1`: not coded — `NRS_484B_257_2_o1` composes or calls `NRS_484B_257_1_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_267_2a`: not coded — `NRS_484B_267_2a` composes or calls `NRS_484B_600_1a` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_270_2b_o1`: not coded — `NRS_484B_270_2b_o1` composes or calls `NRS_484B_213_2c` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_270_2b_o2`: not coded — `NRS_484B_270_2b_o2` composes or calls `NRS_484B_213_2c` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_270_2b_o3`: not coded — `NRS_484B_270_2b_o3` composes or calls `NRS_484B_213_2c` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1a`: not coded — `NRS_484B_283_1a` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1b`: not coded — `NRS_484B_283_1b` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d1`: not coded — `NRS_484B_283_1d1` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d2`: not coded — `NRS_484B_283_1d2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d3_o1`: not coded — `NRS_484B_283_1d3_o1` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d3_o2`: not coded — `NRS_484B_283_1d3_o2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d4_o1`: not coded — `NRS_484B_283_1d4_o1` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_283_1d4_o2`: not coded — `NRS_484B_283_1d4_o2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_777_1_o1`: not coded — `NRS_484B_777_1_o1` composes or calls `NRS_484B_785_1a` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_250_2` proposed `p.same_time_arrival_window` = 2.0 s: the largest difference between the times two vehicles reach an intersection's edge at which they count as arriving at ap
`NRS_484B_287_1e` proposed `p.ped_signal_facing_cos` = 0.87 ratio: cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pe
`NRS_484B_287_1e` proposed `p.ped_signal_facing_reach` = 40.0 m: the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossi
`NRS_484B_785_1a`: gate OK — 4 witnesses, 5 names, composes nothing
`LVMC_11_40_180_A`: gate OK — 6 witnesses, 4 names, composes nothing
`LVMC_11_43_010_A`: gate OK — 4 witnesses, 5 names, composes nothing
`NRS_484B_287_1d`: gate OK — 5 witnesses, 8 names, composes LVMC_11_30_140_B_o1,LVMC_11_30_140_B_o2
`NRS_484B_203_1_o1`: gate OK — 5 witnesses, 7 names, composes nothing
`LVMC_11_40_180_C_o1`: gate WITNESS_FAIL — branch_3: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-082::electric_bicycle, aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter]
`NRS_484B_413_2`: gate OK — 8 witnesses, 8 names, composes nothing
`NRS_484B_287_1e`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `d` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_287_1e`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`LVMC_11_43_010_C1`: gate OK — 6 witnesses, 7 names, composes nothing
`LVMC_11_43_010_B_o1`: gate OK — 8 witnesses, 6 names, composes nothing
`NRS_486_341`: gate OK — 6 witnesses, 5 names, composes nothing
`NRS_484B_210_3`: gate OK — 9 witnesses, 12 names, composes nothing
`LVMC_11_52_030_B`: gate VACUOUS — applicability leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-LVMC-11-02-070::commercial_vehicle"] (one of 2 literal variants of this atom; none exercised)
`NRS_484B_210_2`: gate WITNESS_FAIL — blind: expected unknown, got compliant; the manifest masks rel.bearing
`NRS_484B_210_2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_263_o1`: gate OK — 6 witnesses, 8 names, composes nothing
`NRS_484B_260`: gate OK — 6 witnesses, 13 names, composes nothing
`NRS_484B_287_1c`: gate WITNESS_FAIL — branch_2: expected not_applicable, got unknown for [window_truncated:since]
`NRS_484B_287_1c`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_270_7b`: gate OK — 8 witnesses, 10 names, composes nothing
`LVMC_11_30_060_A`: gate OK — 10 witnesses, 13 names, composes nothing
`NRS_486_351_2`: gate OK — 8 witnesses, 5 names, composes nothing
`NRS_484B_450_1l`: gate OK — 19 witnesses, 24 names, composes nothing
`LVMC_11_52_300`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle], not for an atom the manifest masks; the manifest masks env.civil_time; branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]
`NRS_484B_223_4a`: gate OK — 7 witnesses, 9 names, composes nothing
`NRS_484B_263_o2`: gate OK — 5 witnesses, 9 names, composes nothing
`NRS_484B_560_3_o2`: gate OK — 10 witnesses, 20 names, composes nothing
`NRS_484B_250_1`: gate OK — 9 witnesses, 18 names, composes NRS_484B_250_4_o1,NRS_484B_250_4_o2
`LVMC_11_52_030_A`: gate VACUOUS — applicability leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-LVMC-11-02-150::tour_bus"] (one of 4 literal variants of this atom; none exercised)
`NRS_484B_250_2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_250_2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_587_2a`: gate VACUOUS — obligation leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] (one of 2 literal variants of this atom; none exercised)
`NRS_484B_587_2b`: gate OK — 15 witnesses, 22 names, composes nothing
`NRS_484B_517`: gate OK — 15 witnesses, 24 names, composes nothing; narrowings declared by the coder: 2
`NRS_484B_363_4`: gate WITNESS_FAIL — blind: unknown for [absent_atom:rel_longitudinal_overlap, window_truncated:since, absent_atom:rel_bearing, window_truncated:until], not for an atom the manifest masks; the manifest masks kin.position
`NRS_484B_307_8d`: gate BARE_LITERAL — formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
`NRS_484B_208_1`: gate OK — 23 witnesses, 42 names, composes nothing
dependency context changed and rechecked: `drv.lane.heading_left_of_carrier`
dependency context changed and rechecked: `drv.interaction.overtake_pass_on_right`
`NRS-484B-287-1d` span s1 composes accepted `LVMC_11_30_140_B_o1` (as: exception)
`NRS-484B-287-1d` span s1 composes accepted `LVMC_11_30_140_B_o2` (as: exception)
`NRS-484B-250-1` span g composes accepted `NRS_484B_250_4_o1` (as: exception)
`NRS-484B-250-1` span g composes accepted `NRS_484B_250_4_o2` (as: exception)
`NRS-484B-587-2b` span e8 borrows from `NRS-484B-210-1` the words “(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;”
`NRS-484B-208-1` span k13b borrows from `DEF-NRS-484A-460-2` the words “(a) A vehicle that is transporting more than one person; (b) A motorcycle, regardless of the number of passengers; (c) A bus, regardless of the number of passengers; and (d) Any other vehicle designated by regulation.”

## Laws by state

- blocked: 54
- failed: 1
- planned: 146
- returned: 20

## Returned laws and why

- `NRS-484B-217-2` (attempt 0): `NRS_484B_217_2` composes or calls `NRS_484B_413_2` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-257-2` (attempt 0): `NRS_484B_257_2_o1` composes or calls `NRS_484B_257_1_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted — accepted already and not to be re-planned: NRS_484B_257_2_o2
- `NRS-484B-267-2a` (attempt 0): `NRS_484B_267_2a` composes or calls `NRS_484B_600_1a` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-270-2b` (attempt 0): `NRS_484B_270_2b_o3` composes or calls `NRS_484B_213_2c` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1a` (attempt 0): `NRS_484B_283_1a` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1b` (attempt 0): `NRS_484B_283_1b` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1d1` (attempt 0): `NRS_484B_283_1d1` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1d2` (attempt 0): `NRS_484B_283_1d2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1d3` (attempt 0): `NRS_484B_283_1d3_o2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-283-1d4` (attempt 0): `NRS_484B_283_1d4_o2` composes or calls `LVMC_11_30_060_A` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-307-8a` (attempt 0): NRS_484B_307_8a_o2: span s7 `After complying with the requirement to stop,` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as condition, and the role of words is fixed with the segmentation once a node of the law is accepted; NRS_484B_307_8a_o2: span s8 `vehicular traffic facing such a signal and situated on the e` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as subject, and the role of words is fixed with the segmentation once a node of the law is accepted; NRS_484B_307_8a_o2: span s9 `may proceed into the intersection` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as condition, and the role of words is fixed with the segmentation once a node of the law is accepted; NRS_484B_307_8a_o2: span s11 `only when the intersecting highway is two-directional or one` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as condition, and the role of words is fixed with the segmentation once a node of the law is accepted; NRS_484B_307_8a_o2: span s12 `or vehicular traffic facing such a signal and situated on th` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as subject, and the role of words is fixed with the segmentation once a node of the law is accepted; NRS_484B_307_8a_o2: span s13 `may proceed into the intersection` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as condition, and the role of words is fixed with the segmentation once a node of the law is accepted — accepted already and not to be re-planned: NRS_484B_307_8a_o1, NRS_484B_307_8a_o3
- `NRS-484B-307-8d` (attempt 1): gate BARE_LITERAL; formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
- `NRS-484B-307-9a` (attempt 1): NRS_484B_307_9a_o1: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; NRS_484B_307_9a_o2: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; composes ['NRS_484B_307_9b'], whose law waits for the operator: that composition stands, and the law waits for it once the defects above are fixed
- `NRS-484B-363-4` (attempt 1): gate WITNESS_FAIL; blind: unknown for [absent_atom:rel_longitudinal_overlap, window_truncated:since, absent_atom:rel_bearing, window_truncated:until], not for an atom the manifest masks; the manifest masks kin.position
- `NRS-484B-587-2a` (attempt 1): gate VACUOUS; obligation leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] (one of 2 literal variants of this atom; none exercised)
- `NRS-484B-777-1` (attempt 0): `NRS_484B_777_1_o1` composes or calls `NRS_484B_785_1a` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted — accepted already and not to be re-planned: NRS_484B_777_1_o2
- `LVMC-11-40-180-C` (attempt 1): gate WITNESS_FAIL; branch_3: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-082::electric_bicycle, aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter] — accepted already and not to be re-planned: LVMC_11_40_180_C_o2
- `LVMC-11-52-030-A` (attempt 1): gate VACUOUS; applicability leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-LVMC-11-02-150::tour_bus"] (one of 4 literal variants of this atom; none exercised)
- `LVMC-11-52-030-B` (attempt 1): gate VACUOUS; applicability leaf 2: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-LVMC-11-02-070::commercial_vehicle"] (one of 2 literal variants of this atom; none exercised)
- `LVMC-11-52-300` (attempt 1): gate WITNESS_FAIL; forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle], not for an atom the manifest masks; the manifest masks env.civil_time; branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-130::motor_vehicle]

## Laws closed as failed this iteration (reopen with `python -m harness reopen`)

- `NRS-484B-267-2f`: attempt budget (2) spent; gate WITNESS_FAIL; forbid: expected violated, got compliant; node repair of `NRS_484B_267_2f_o2`: the session withdrew the record as a plan defect (the text needs another cut) — The node's whole duty (s11 'proceed' + s11r 'as required pursuant to NRS 484B.607 [NRS-484B-607-1a..1d]') is a compliance reference to rules this run does not plan: no NRS_484B_607 node exists, accepted or planned, and the harness supplies no text for it. So the record has no obligation formula. Its own prose says the obligation is 'Not expressible', yet its forbid/permit scenarios assume content from NRS 484B.607 (slowing, moving to a lane not adjacent). Those scenarios cannot be met without making up that law's duty, and 'keeps moving' would be a weaker duty the words do not state. Writing s11r as a residue leaves nothing to code. What the planner must do: bring NRS 484B.607 (lines 1a to 1d) into the run's plan so that s11r becomes a 'compliance' composition of those nodes, with subject mapped to subject, the way sibling NRS_484B_267_2f_o1 composes subsection 1. Until then this node is not planned. Noted for the same re-plan: the s3/s4 borrowed words 'flashing red warning lamp visible from the front' need the lamp's facing. The formula atom sig_warning_lamp reads only colour and mode (the same UNEXPRESSED that NRS_484B_267_1a, 1b_o2 and 1c returned). The planner should file that as an operator gap on the trigger span, not narrow it.

## Concepts by state

- accepted: 16
- returned: 1

## Returned concepts and why

- `drv.motion.right_turn` (returned, attempt 1; used by LVMC_11_40_080_o1, LVMC_11_40_080_o2): gate WITNESS_FAIL; holds (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); fails (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); blind (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it)

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_307_2b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o1`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_4b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_8b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_9c` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d4_o1`

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `NRS_484B_517` s1: 'a traffic signal displaying a red or yellow indication': read as the steady red and yellow indications, circular and arrow (circular_red, circular_yellow, red_arrow(dir), yellow_arrow(dir)), with the record's flashing_red; flashing_yellow and flashing_yellow_arrow, which let traffic proceed with caution, are not taken as an indication a halt complies with
- `NRS_484B_517` s1: 'a railway signal or gate with ... gate not up': read as a gate in the state lowering, down or raising; the state none (the device has no gate) is not a gate that is not up

## Gaps filed this iteration

- G79 (atom) on `making use of flashing lights meeting the requirements of` — NRS-484B-267-1b
- G80 (atom) on `making use of flashing lights meeting the requirements of` — NRS-484B-267-1c
- G81 (atom) on `and making use of flashing lights meeting the requirements of` — NRS-484B-267-2d
- G82 (atom) on `The operator of a taxicab` — LVMC-11-60-040
- G83 (atom) on `The operator of a bus,` — LVMC-11-60-030-A4
- G84 (atom) on `and making use of flashing lights meeting the requirements of` — NRS-484B-267-2c
- G85 (atom) on `making use of flashing lights meeting the requirements of` — NRS-484B-267-1a
- G86 (atom) on `An authorized emergency vehicle` — NRS-484D-400-5
- G87 (operator) on `(1) The person stops before entering the crosswalk on the nearest side of the in` — NRS-484B-307-9b

## Repair evidence

No law-level label-repair evidence is supplied for this session.

## Your previous record of these laws

### `NRS-484B-283-1a`: the plan of iteration 1 and what followed

`NRS_484B_283_1a` — its duty: “shall yield the right-of-way,” (characters 293–322)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1a",
 "law_refs": [
  "NRS-484B-283-1a"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c1",
   "text": "When official traffic-control devices are not in place or not in operation,",
   "role": "condition"
  },
  {
   "id": "s",
   "text": "the driver of a vehicle",
   "role": "subject"
  },
  {
   "id": "ob",
   "text": "shall yield the right-of-way,",
   "role": "obligation"
  },
  {
   "id": "st",
   "text": "slowing down or stopping if need be so to yield,",
   "role": "standard"
  },
  {
   "id": "c2",
   "text": "to a pedestrian crossing the highway within a crosswalk",
   "role": "condition"
  },
  {
   "id": "c3",
   "text": "when the pedestrian is upon the half of the highway upon which the vehicle is traveling or onto which the vehicle is turning,",
   "role": "condition"
  },
  {
   "id": "st2",
   "text": "or when the pedestrian is approaching so closely from the opposite half of the highway as to be in danger.",
   "role": "standard"
  },
  {
   "id": "d",
   "text": "As used in this section, “half of the highway” means all traffic lanes of a highway which are designated for traffic traveling in one direction, and includes the entire highway in the case of a one-way highway.",
   "role": "definitional"
  }
 ],
 "elements": [
  {
   "span": "c1",
   "atoms": [
    "dev.traffic_signal",
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.inoperative",
    "rel.occupies",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "The official traffic-control devices (DEF-NRS-484A-145: every 'sign, signal, marking and device ... for the purpose of regulating, warning or guiding traffic') that regulate a crosswalk crossing are the vehicular signal heads (dev.traffic_signal, state including 'dark') and pedestrian heads (dev.pedestrian_signal, state including 'dark') that control the travel regions the vehicle and the pedestrian are in: dev.governs ('the travel regions whose traffic the device controls'), with rel.occupies anchoring each road user in a governed region (kind st.travel_region). 'not in operation' is a head showing 'dark' or dev.inoperative ('a signal head installed and uncovered but showing no valid indication'); 'not in place' is no such head governing those regions. dev.governs is used for control, not for a position, as its exclusion requires."
  },
  {
   "span": "s",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'the driver of a vehicle' maps, as in the run's index, to the admitted aggregate DEF-NRS-484A-320::vehicle ('every device in, upon or by which any person or property is or may be transported or drawn upon a highway', with its exceptions decided by the reading); 'driver' (DEF-NRS-484A-080) is a role, read through the vehicle's controlled motion."
  },
  {
   "span": "ob",
   "atoms": [
    "kin.speed",
    "rel.contact"
   ],
   "derived": [],
   "justification": "Yielding the right-of-way (DEF-NRS-484A-210: 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another') is observed as the vehicle not reaching the pedestrian: no rel.contact ('the bodies of two road users ... touch or overlap') and the vehicle's speed (kin.speed) bounded as the standard below sets; as mapped in the run's index for 'shall yield the right-of-way'."
  },
  {
   "span": "c2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "rel.occupies",
    "st.crosswalk"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian. 'crossing the highway within a crosswalk': the crosswalk (DEF-NRS-484A-065: 'That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks ... or (2) Any portion of a highway ... distinctly indicated for pedestrian crossing') is st.crosswalk ('marked crossing, or the unmarked prolongation of sidewalks at an intersection'), marked or unmarked, so the definition's whole extent is kept; rel.occupies places the pedestrian's footprint in it."
  },
  {
   "span": "c3",
   "atoms": [
    "rel.occupies",
    "st.lane",
    "st.one_way_roadway",
    "st.lane_direction",
    "kin.heading"
   ],
   "derived": [],
   "justification": "By the section's own definition, a half of the highway is 'all traffic lanes ... designated for traffic traveling in one direction': the pedestrian's footprint overlaps (rel.occupies) a lane (st.lane) or a one-way roadway (st.one_way_roadway, 'the entire highway in the case of a one-way highway') whose designated direction (st.lane_direction, 'direction of travel designated for a structure a vehicle travels in') points with the vehicle's heading (kin.heading, 'direction the body points'): the half on which the vehicle travels, or, while it turns, the half its heading has turned onto. kin.heading is read as the direction of travel of a vehicle driven forward; st.lane 'Not a stand-in for' a half of the roadway does not apply because the half is assembled from the lanes' designated directions, as the definition itself builds it."
  },
  {
   "span": "d",
   "atoms": [
    "st.lane",
    "st.lane_direction",
    "st.one_way_roadway"
   ],
   "derived": [],
   "justification": "The section's definition of 'half of the highway' ('all traffic lanes of a highway which are designated for traffic traveling in one direction', 'the entire highway in the case of a one-way highway') is carried by the lanes (st.lane) grouped by their designated direction (st.lane_direction) and by a one-way roadway (st.one_way_roadway, 'roadway on which traffic is restricted to one direction'), the atoms c3 and st2 read."
  }
 ],
 "operationalizations": [
  {
   "span": "st",
   "standard": "slowing down or stopping if need be so to yield (the right-of-way's 'danger of a crash unless one grants precedence')",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "kin.speed"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance",
    "p.halt_speed_tolerance"
   ],
   "convention": "traffic-conflict technique: while the vehicle moves (speed above the halt tolerance), a predicted closest approach of the two centres within the conflict horizon at a centre distance below the conflict clearance is a danger of a crash the driver has not yielded to; a vehicle at rest has slowed or stopped as need be",
   "surrogate": false
  },
  {
   "span": "st2",
   "standard": "approaching so closely from the opposite half as to be in danger",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "rel.occupies",
    "st.lane",
    "st.lane_direction",
    "kin.heading"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance"
   ],
   "convention": "traffic-conflict technique: a pedestrian in the crosswalk on a lane whose designated direction points against the vehicle's heading is in danger where the predicted closest approach of the two centres falls within the conflict horizon at a centre distance below the conflict clearance",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject is a vehicle (ru.aggregate DEF-NRS-484A-320::vehicle), not engaged by LVMC_11_30_140_B_o1, LVMC_11_30_140_B_o2, LVMC_11_46_030_o1 or LVMC_11_46_030_o2. Devices are not in place or not in operation: every traffic signal head (dev.traffic_signal) that governs (dev.governs) a travel region the subject occupies shows dark or is inoperative (dev.inoperative). There is a pedestrian p (ru.aggregate DEF-NRS-484A-165::pedestrian) whose footprint overlaps a crosswalk (st.crosswalk), such that every pedestrian signal head governing a travel region p occupies shows dark, p is not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A or LVMC_11_30_060_B, and either (a) p's footprint overlaps a lane or one-way roadway whose designated direction (st.lane_direction) has a positive dot product with the subject's heading (kin.heading) — the subject's half — or (b) otherwise (p on the opposite half) the predicted closest approach of the subject and p falls within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance).",
 "obligation": "For every such pedestrian p: the subject is not in contact with p (rel.contact), and where the subject's speed (kin.speed) is above p.halt_speed_tolerance, it is not the case that the closest approach of the subject and p falls within p.conflict_horizon at a centre distance below p.conflict_centre_clearance.",
 "params": [
  "p.conflict_horizon",
  "p.conflict_centre_clearance",
  "p.halt_speed_tolerance"
 ],
 "narrowings": [
  {
   "span": "s",
   "why": "'the driver' is read through the vehicle's controlled motion: the duty binds the vehicle's conduct whoever or whatever controls it.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c1",
   "why": "'official' is read through the presence of the signal heads in the scene.",
   "kind": "observable_reading",
   "category": "status"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "No signal head governs the subject's lane; a pedestrian stands in an unmarked crosswalk on a lane whose direction matches the subject's heading, 15 m ahead; the subject moves at 10 m/s with a predicted closest approach of 0.5 m in 1.5 s."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same scene, but the subject is at rest (speed 0.0 m/s) before the crosswalk while the pedestrian crosses its half."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "A traffic signal head governing the subject's lane shows circular_green: the devices are in operation."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "No signal head governs the subject's lane; a pedestrian near the crosswalk is on the predicted collision course, but whether its footprint overlaps the crosswalk is not observed.",
   "masked": [
    "rel.occupies"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "No signal heads and no pedestrian anywhere in the scene: the duty is decided for the subject alone as not engaged."
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "A pedestrian in the crosswalk on the opposite half, on a lane whose direction points against the subject's heading, with no predicted closest approach within the horizon."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "traffic-conflict technique literature (Hayward 1972; Swedish traffic conflict technique)"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "AASHTO Green Book passenger-car design vehicle dimensions"
  },
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "speed resolution of the acquisition standard's kinematic channel"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-283-1b`: the plan of iteration 1 and what followed

`NRS_484B_283_1b` — its duty: “shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle” (characters 206–305)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1b",
 "law_refs": [
  "NRS-484B-283-1b"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "s",
   "text": "A pedestrian",
   "role": "subject"
  },
  {
   "id": "ob",
   "text": "shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle",
   "role": "obligation"
  },
  {
   "id": "st",
   "text": "which is so close that it is impossible for the driver to yield.",
   "role": "standard"
  }
 ],
 "elements": [
  {
   "span": "s",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'A pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian ('a person afoot, a person in a manual or motorized wheelchair ...')."
  },
  {
   "span": "ob",
   "atoms": [
    "rel.occupies",
    "st.sidewalk",
    "st.safety_zone",
    "st.median_or_divider",
    "st.roadway",
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "Leaving 'a curb or other place of safety' is the pedestrian's footprint (rel.occupies) coming onto the roadway (st.roadway, 'the part of a highway improved for vehicular traffic') from a place pedestrians are safe from vehicles: the sidewalk the curb bounds (st.sidewalk, 'area for pedestrians between roadway and property line'), a safety zone (st.safety_zone, 'an area within the highway marked off for pedestrians only') or a median or dividing section (st.median_or_divider). st.sidewalk is not used for a crosswalk, as its exclusion requires; st.roadway is not used for the sidewalk. 'into the path of a vehicle': the vehicle is the admitted aggregate DEF-NRS-484A-320::vehicle; the pedestrian is in its path where, under constant velocities, the two centres approach within the conflict horizon (prim.closest_approach_within) to a centre distance below the conflict clearance (prim.closest_approach_distance). These primitives are 'Not a stand-in for' contact or danger alone; here they bound the path the vehicle will sweep, the clearance and horizon set by the reading, and the impossibility is decided by the standard."
  }
 ],
 "operationalizations": [
  {
   "span": "st",
   "standard": "so close that it is impossible for the driver to yield",
   "concepts": [
    "prim.closest_approach_time",
    "kin.speed",
    "env.wet_road",
    "env.ice_or_snow"
   ],
   "params": [
    "p.driver_reaction_time",
    "p.following_decel_dry",
    "p.following_decel_wet",
    "p.following_decel_ice"
   ],
   "convention": "stopping-distance model: the vehicle cannot yield where the time to the predicted closest approach (prim.closest_approach_time) is less than the driver's perception-reaction time plus the vehicle's speed (kin.speed) divided by twice the braking deceleration, written as a product (2·a·t_ca < 2·a·t_r + v); the deceleration is selected by the surface: icy or snow-covered (env.ice_or_snow), else wet (env.wet_road), else dry",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian) that leaves a place of safety at this observation: its footprint overlaps a roadway (st.roadway) here, and at the previous observation it overlapped no roadway and overlapped a sidewalk, a safety zone or a median or divider. The duty does not apply where NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2 is engaged for the subject, nor where LVMC_11_46_030_o1 or LVMC_11_46_030_o2 is engaged for a vehicle v of the scene.",
 "obligation": "There is no vehicle v (ru.aggregate DEF-NRS-484A-320::vehicle) such that the closest approach of the subject and v falls within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance) and 2·a·t < 2·a·p.driver_reaction_time + speed(v), where t is prim.closest_approach_time with horizon p.conflict_horizon, speed(v) is v's kin.speed, and a is p.following_decel_ice where env.ice_or_snow holds, else p.following_decel_wet where env.wet_road holds, else p.following_decel_dry. With no vehicle in the scene, compliant.",
 "params": [
  "p.conflict_horizon",
  "p.conflict_centre_clearance",
  "p.driver_reaction_time",
  "p.following_decel_dry",
  "p.following_decel_wet",
  "p.following_decel_ice"
 ],
 "narrowings": [
  {
   "span": "ob",
   "why": "'suddenly' is read through the vehicle's closeness at the moment the pedestrian leaves the place of safety: a departure is sudden in the law's sense where the vehicle is already too close to yield; the pedestrian's own abruptness is not measured.",
   "kind": "reading"
  },
  {
   "span": "ob",
   "why": "'other place of safety' is read only through the sidewalk the curb bounds, a safety zone and a median or dividing section.",
   "kind": "reading"
  },
  {
   "span": "st",
   "why": "'the driver' is read through the vehicle's motion: whether the vehicle can stop, whoever or whatever controls it.",
   "kind": "observable_reading",
   "category": "agency"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "Dry road. The pedestrian steps from the sidewalk onto the roadway while a car 12 m away moves toward it at 12 m/s; predicted closest approach 0.5 m in 1.0 s, below 1.5 s + 12/(2·6) s."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The pedestrian steps off while the car is 70 m away at 12 m/s: no closest approach within the horizon."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The pedestrian stays on the sidewalk throughout."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "A car is 12 m away at 12 m/s on a collision course, but whether the pedestrian's footprint overlaps the roadway or the sidewalk is not observed.",
   "masked": [
    "rel.occupies"
   ]
  },
  {
   "name": "branch_1",
   "expected": "compliant",
   "narrative": "The pedestrian steps off the sidewalk with no vehicle in the scene: the duty binds the pedestrian alone and is met."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "traffic-conflict technique literature (Hayward 1972; Swedish traffic conflict technique)"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "AASHTO Green Book passenger-car design vehicle dimensions"
  },
  {
   "name": "p.driver_reaction_time",
   "unit": "s",
   "value": 1.5,
   "convention": "perception-reaction time of an alert driver to an expected hazard in the stopping-distance model",
   "source": "AASHTO Green Book stopping sight distance; perception-reaction studies"
  },
  {
   "name": "p.following_decel_dry",
   "unit": "m/s^2",
   "value": 6.0,
   "convention": "braking deceleration of a passenger vehicle on a dry paved surface (coefficient of friction about 0.6)",
   "source": "tire-pavement friction tables of accident reconstruction handbooks"
  },
  {
   "name": "p.following_decel_wet",
   "unit": "m/s^2",
   "value": 4.0,
   "convention": "braking deceleration of a passenger vehicle on a wet paved surface (coefficient of friction about 0.4)",
   "source": "tire-pavement friction tables of accident reconstruction handbooks"
  },
  {
   "name": "p.following_decel_ice",
   "unit": "m/s^2",
   "value": 1.0,
   "convention": "braking deceleration of a passenger vehicle on an icy or snow-covered surface (coefficient of friction about 0.1)",
   "source": "tire-pavement friction tables of accident reconstruction handbooks"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-283-1d1`: the plan of iteration 1 and what followed

`NRS_484B_283_1d1` — its duty: “and must be given” (characters 488–505)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d1",
 "law_refs": [
  "NRS-484B-283-1d1"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Walk” indication or walking person symbol is illuminated,",
   "role": "trigger"
  },
  {
   "id": "c1",
   "text": "pedestrians facing the signal",
   "role": "condition"
  },
  {
   "id": "c2",
   "text": "may proceed across the highway in the direction of the signal",
   "role": "condition"
  },
  {
   "id": "ob",
   "text": "and must be given",
   "role": "obligation"
  },
  {
   "id": "st",
   "text": "the right-of-way",
   "role": "standard"
  },
  {
   "id": "s",
   "text": "by the drivers of all vehicles.",
   "role": "subject"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}'); 'in place' is a head present in the scene. 'such signals' regulate the crossing of the roadway they control: dev.governs ('the travel regions whose traffic the device controls — a lane, ... roadway'), traffic including pedestrians (DEF-NRS-484A-285: 'pedestrians, ridden or herded animals, vehicles'), ties the head to the roadway or lane its crossing traverses (kinds st.roadway, st.lane). dev.governs is not used as a position."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'the “Walk” indication or walking person symbol is illuminated' is the head's state walk (dev.pedestrian_signal state 'walk')."
  },
  {
   "span": "c1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "kin.heading",
    "kin.position",
    "dev.position"
   ],
   "derived": [],
   "justification": "'pedestrians' is the admitted aggregate DEF-NRS-484A-165::pedestrian. 'facing the signal': the head's location (dev.position, 'location of the device head / sign face') lies ahead of the pedestrian's position (kin.position) along the direction its body points (kin.heading, 'direction the body points'), within a cone and a reach. dev.position is used as the head's location, not as the place of a stop line or crossing, which its exclusion names."
  },
  {
   "span": "c2",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "'may proceed across the highway in the direction of the signal' identifies the pedestrians the right-of-way is owed to: those on the roadway the head governs (rel.occupies of a st.roadway or st.lane region that head governs), facing the head, so moving toward it across the way. The highway (DEF-NRS-484A-095: 'the entire width between the boundary lines') is crossed by traversing its roadway; the sidewalk the words of the sibling subparagraphs call a place of safety is no part of the crossing."
  },
  {
   "span": "ob",
   "atoms": [
    "kin.speed",
    "rel.contact"
   ],
   "derived": [],
   "justification": "Giving the right-of-way (DEF-NRS-484A-210: 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another') is observed as the vehicle not reaching the pedestrian (no rel.contact) with its speed (kin.speed) bounded as the standard sets, as the index maps 'Yield'."
  },
  {
   "span": "s",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'the drivers of all vehicles' is the admitted aggregate DEF-NRS-484A-320::vehicle, the driver read through the vehicle's controlled motion."
  }
 ],
 "operationalizations": [
  {
   "span": "st",
   "standard": "the right-of-way: precedence where the two approach 'under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence' (DEF-NRS-484A-210)",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "kin.speed"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance",
    "p.halt_speed_tolerance"
   ],
   "convention": "traffic-conflict technique: while the vehicle moves (speed above the halt tolerance), a predicted closest approach of the two centres within the conflict horizon at a centre distance below the conflict clearance is a danger of a crash in which the vehicle has not granted precedence",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "p"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject is a vehicle (ru.aggregate DEF-NRS-484A-320::vehicle), not engaged by LVMC_11_30_140_B_o1, LVMC_11_30_140_B_o2, LVMC_11_46_030_o1 or LVMC_11_46_030_o2. There are a pedestrian p (ru.aggregate DEF-NRS-484A-165::pedestrian), a pedestrian signal head d showing walk, and a roadway or lane r governed by d (dev.governs), with p's footprint overlapping r (rel.occupies), p facing d, and p not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A or LVMC_11_30_060_B. p faces d where, with Δ the vector from p's kin.position to d's dev.position and h p's kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach².",
 "obligation": "For every such pedestrian p: the subject is not in contact with p (rel.contact), and where the subject's speed (kin.speed) is above p.halt_speed_tolerance, it is not the case that the closest approach of the subject and p falls within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance).",
 "params": [
  "p.conflict_horizon",
  "p.conflict_centre_clearance",
  "p.halt_speed_tolerance",
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "s",
   "why": "'the drivers' is read through the vehicles' controlled motion: the duty binds each vehicle's conduct whoever or whatever controls it.",
   "kind": "observable_reading",
   "category": "agency"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A pedestrian on the roadway faces a pedestrian head 12 m ahead that governs that roadway and shows walk; the subject turns toward the crossing at 8 m/s with a predicted closest approach of 0.8 m in 1.2 s."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same scene with the subject at rest before the crossing."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The faced head shows dont_walk_steady."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "Same as forbid, but the head's state is not observed.",
   "masked": [
    "dev.pedestrian_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "The head shows walk but no pedestrian is in the scene: decided for the subject alone as not engaged."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "traffic-conflict technique literature (Hayward 1972; Swedish traffic conflict technique)"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "AASHTO Green Book passenger-car design vehicle dimensions"
  },
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "speed resolution of the acquisition standard's kinematic channel"
  },
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-283-1d2`: the plan of iteration 1 and what followed

`NRS_484B_283_1d2` — its duty: “but must complete the crossing before the countdown timer gets to zero.” (characters 543–614)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d2",
 "law_refs": [
  "NRS-484B-283-1d2"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer,",
   "role": "trigger"
  },
  {
   "id": "s",
   "text": "a pedestrian",
   "role": "subject"
  },
  {
   "id": "c",
   "text": "may proceed across the highway in the direction of the signal,",
   "role": "condition"
  },
  {
   "id": "ob",
   "text": "but must complete the crossing before the countdown timer gets to zero.",
   "role": "obligation"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; countdown attribute when a timer is displayed'); 'such signals' regulate the crossing of the roadway they control, read through dev.governs ('the travel regions whose traffic the device controls — a lane, ... roadway'; traffic includes pedestrians, DEF-NRS-484A-285) on a roadway or lane (kinds st.roadway, st.lane)."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'“Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer' is the head's state dont_walk_flashing with its countdown attribute displayed."
  },
  {
   "span": "s",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "c",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "kin.heading",
    "kin.position",
    "dev.position"
   ],
   "derived": [],
   "justification": "The pedestrian who proceeds across the highway under this indication is one whose footprint came onto the governed roadway or lane (rel.occupies of st.roadway / st.lane) while the head showed it, facing the head: the head's location (dev.position, 'location of the device head') ahead of the pedestrian's position (kin.position) along its heading (kin.heading, 'direction the body points') within a cone and a reach — the direction of the signal. dev.position is not used as a crossing or a stop line."
  },
  {
   "span": "ob",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "Completing the crossing is having left the roadway or lane crossed: the pedestrian's footprint no longer overlaps it (rel.occupies). The countdown timer gets to zero at the end of the flashing interval it times, where the head stops showing the flashing indication with a countdown and shows dont_walk_steady (dev.pedestrian_signal states dont_walk_flashing with countdown, then dont_walk_steady)."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian), not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2, with no vehicle v of the scene engaged by LVMC_11_46_030_o1 or LVMC_11_46_030_o2. The judged observation is the countdown's end for a pedestrian head d governing (dev.governs) a roadway or lane r: d shows dont_walk_steady here and showed dont_walk_flashing with its countdown at the previous observation. The subject's latest entry onto r (the latest earlier observation at which its footprint came to overlap r, not overlapping it at the observation before; history bound: that entry, searched back without other limit) was made while d showed dont_walk_flashing with its countdown and the subject faced d, and d showed dont_walk_flashing with countdown at every observation from that entry to the previous one. The subject faces d where, with Δ the vector from its kin.position to d's dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Where the entry lies before the recording, applicability is unknown.",
 "obligation": "At the countdown's end the subject's footprint does not overlap r (rel.occupies): it has completed the crossing.",
 "params": [
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "ob",
   "why": "the countdown's reaching zero is read as the head's change from the flashing indication with countdown to the steady indication, which ends the interval the timer counts; the timer's displayed number is not read.",
   "kind": "reading"
  },
  {
   "span": "ob",
   "why": "'complete the crossing' is read as the pedestrian's footprint having left the roadway or lane governed by the head; a pedestrian on a median or safety zone between roadways has left it.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "The head governing roadway r shows dont_walk_flashing with countdown; the pedestrian steps onto r facing it, walks slowly, and is still on r when the head turns dont_walk_steady."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The pedestrian steps onto r during the flashing countdown and is on the far sidewalk, off r, when the head turns dont_walk_steady."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The pedestrian entered r while the head showed walk; at the countdown's end it is still on r (the steady-indication duty governs it, not this one)."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The pedestrian steps onto r and is on it later, but the head's state is not observed, so neither the countdown interval nor its end can be told.",
   "masked": [
    "dev.pedestrian_signal"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "The recording begins with the pedestrian already on r while the head shows dont_walk_flashing with countdown; the head turns dont_walk_steady while it is still on r; its entry onto r is not recorded.",
   "boundary": "the pedestrian's entry onto r, which lies before the recording"
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-283-1d3`: the plan of iteration 1 and what followed

`NRS_484B_283_1d3_o1` — its duty: “may not proceed to cross the highway,” (characters 484–521)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below
- span `ref2` “[NRS-484B-283-1d1]” borrows from `NRS-484B-283-1d1` the words “While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal” (as definition: no rule is composed)

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d3_o1",
 "law_refs": [
  "NRS-484B-283-1d3"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer,",
   "role": "trigger"
  },
  {
   "id": "s1",
   "text": "a pedestrian",
   "role": "subject"
  },
  {
   "id": "ob1",
   "text": "may not proceed to cross the highway,",
   "role": "obligation"
  },
  {
   "id": "s2",
   "text": "but a pedestrian",
   "role": "exception"
  },
  {
   "id": "e1",
   "text": "who entered the highway lawfully pursuant to subparagraph (1)",
   "role": "exception"
  },
  {
   "id": "ref2",
   "text": "[NRS-484B-283-1d1]",
   "role": "reference"
  },
  {
   "id": "e2",
   "text": "may continue to cross the highway",
   "role": "exception"
  },
  {
   "id": "ob2",
   "text": "but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; countdown attribute'). The signal that indicates to a pedestrian ('such signals') is the head that governs the roadway or lane its crossing traverses (dev.governs, 'the travel regions whose traffic the device controls', traffic including pedestrians by DEF-NRS-484A-285; kinds st.roadway, st.lane) and that the pedestrian faces: the head's location (dev.position, 'location of the device head') ahead of the pedestrian's position (kin.position) along its heading (kin.heading, 'direction the body points') within a cone and a reach. dev.position is not used as a stop line or crossing."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'illuminated and flashing but is not accompanied by a countdown timer' is the head's state dont_walk_flashing with no countdown attribute displayed."
  },
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "ob1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Proceeding to cross the highway is coming onto the roadway or lane the head governs: the pedestrian's footprint comes to overlap it (rel.occupies of st.roadway / st.lane). The highway (DEF-NRS-484A-095) includes the sidewalk, but the sibling words 'must proceed to a curb, sidewalk, safety zone' place the sidewalk outside the crossing, so the crossing begins on the roadway."
  },
  {
   "span": "s2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' (the one excepted) is the same admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "e1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "st.sidewalk",
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading"
   ],
   "derived": [],
   "source_spans": [
    "ref2"
   ],
   "justification": "Entering the highway lawfully pursuant to subparagraph (1) borrows (1)'s words: 'While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal'. It is the pedestrian's latest step from a sidewalk (st.sidewalk) onto a roadway or lane (rel.occupies of st.roadway / st.lane) made while a pedestrian head (dev.pedestrian_signal) governing that roadway or lane (dev.governs) showed walk and the pedestrian faced it (dev.position ahead of kin.position along kin.heading within the cone and reach)."
  },
  {
   "span": "e2",
   "atoms": [
    "rel.occupies",
    "st.sidewalk"
   ],
   "derived": [],
   "justification": "Continuing to cross is not having returned to a sidewalk (rel.occupies of st.sidewalk) since that entry: the pedestrian is still in the crossing it began."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d1",
   "why": "It borrows the circumstances of subparagraph (1)'s permission — the walk indication illuminated, the pedestrian facing the signal, proceeding across the highway in its direction — to qualify how the pedestrian entered. Subparagraph (1)'s rule is a duty on drivers to give the right-of-way; whether that duty applied to some vehicle, held, or was complied with says nothing of how this pedestrian entered, so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian), not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2, with no vehicle v of the scene engaged by LVMC_11_46_030_o1 or LVMC_11_46_030_o2. There are a pedestrian head d (dev.pedestrian_signal) showing dont_walk_flashing without its countdown attribute and a roadway or lane r governed by d (dev.governs), the subject faces d, and the subject's footprint did not overlap r at the previous observation. The subject faces d where, with Δ the vector from its kin.position to d's dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Excepted: the subject is continuing a crossing it began lawfully under subparagraph (1) — its latest step from a sidewalk onto a roadway or lane was made while a pedestrian head governing that roadway or lane showed walk and the subject faced that head, and its footprint has overlapped no sidewalk since.",
 "obligation": "The subject's footprint does not overlap r at this observation: it has not proceeded onto the roadway.",
 "params": [
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "ob1",
   "why": "'proceed to cross the highway' is read as the pedestrian's footprint coming onto the roadway or lane the faced head governs; walking on the sidewalk is not crossing.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "At the curb, the pedestrian faces a head 15 m away across roadway r that governs r and shows dont_walk_flashing without countdown; at the next observation its footprint overlaps r."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same head and state; the pedestrian waits on the sidewalk and its footprint never overlaps r."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The faced head shows walk."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The pedestrian steps onto r facing the head, but the head's state is not observed.",
   "masked": [
    "dev.pedestrian_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "The pedestrian stepped onto the first roadway from the sidewalk while the head governing it showed walk, reached the median, and now steps onto the second roadway r while its faced head shows dont_walk_flashing without countdown: it is continuing a lawful crossing."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

`NRS_484B_283_1d3_o2` — its duty: “but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.” (characters 654–846)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below
- span `ref2` “[NRS-484B-283-1d1]” borrows from `NRS-484B-283-1d1` the words “While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal” (as definition: no rule is composed)

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d3_o2",
 "law_refs": [
  "NRS-484B-283-1d3"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and flashing but is not accompanied by a countdown timer,",
   "role": "trigger"
  },
  {
   "id": "s1",
   "text": "a pedestrian",
   "role": "sibling"
  },
  {
   "id": "ob1",
   "text": "may not proceed to cross the highway,",
   "role": "sibling"
  },
  {
   "id": "s2",
   "text": "but a pedestrian",
   "role": "subject"
  },
  {
   "id": "e1",
   "text": "who entered the highway lawfully pursuant to subparagraph (1)",
   "role": "condition"
  },
  {
   "id": "ref2",
   "text": "[NRS-484B-283-1d1]",
   "role": "reference"
  },
  {
   "id": "e2",
   "text": "may continue to cross the highway",
   "role": "condition"
  },
  {
   "id": "ob2",
   "text": "but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety before the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady.",
   "role": "obligation"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; countdown attribute'). The signal that indicates to a pedestrian is the head that governs the roadway or lane its crossing traverses (dev.governs, 'the travel regions whose traffic the device controls', traffic including pedestrians by DEF-NRS-484A-285; kinds st.roadway, st.lane) and that the pedestrian faces: dev.position ('location of the device head') ahead of kin.position along kin.heading ('direction the body points') within a cone and a reach. dev.position is not used as a stop line or crossing."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'illuminated and flashing but is not accompanied by a countdown timer' is the head's state dont_walk_flashing with no countdown attribute displayed."
  },
  {
   "span": "s2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "e1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "st.sidewalk",
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading"
   ],
   "derived": [],
   "source_spans": [
    "ref2"
   ],
   "justification": "Entering the highway lawfully pursuant to subparagraph (1) borrows (1)'s words: 'While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal'. It is the pedestrian's latest step from a sidewalk (st.sidewalk) onto the roadway or lane r (rel.occupies of st.roadway / st.lane) made while the head d (dev.pedestrian_signal) governing r (dev.governs) showed walk and the pedestrian faced d (dev.position ahead of kin.position along kin.heading within the cone and reach)."
  },
  {
   "span": "e2",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Continuing to cross under this indication is the pedestrian's footprint still overlapping r (rel.occupies) at some observation while d shows the flashing indication without countdown."
  },
  {
   "span": "ob2",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "Proceeding to a curb, sidewalk, safety zone or other place of safety is having left the roadway or lane crossed: the pedestrian's footprint no longer overlaps r (rel.occupies). Each place the words list (the curb's sidewalk, a safety zone, a median) lies off r. 'before the ... indication ... is illuminated and steady' fixes the moment: the observation at which d shows dont_walk_steady, having shown dont_walk_flashing without countdown at the previous one."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d1",
   "why": "It borrows the circumstances of subparagraph (1)'s permission — the walk indication illuminated, the pedestrian facing the signal, proceeding across the highway in its direction — to qualify how the pedestrian entered. Subparagraph (1)'s rule is a duty on drivers to give the right-of-way; whether that duty applied to some vehicle, held, or was complied with says nothing of how this pedestrian entered, so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian), not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2, with no vehicle v of the scene engaged by LVMC_11_46_030_o1 or LVMC_11_46_030_o2. The judged observation is the onset of the steady indication of a pedestrian head d governing (dev.governs) a roadway or lane r: d shows dont_walk_steady here and showed dont_walk_flashing without countdown at the previous observation. The subject's latest step from a sidewalk onto r (history bound: that step, searched back without other limit) was made while d showed walk and the subject faced d; and the subject's footprint overlapped r at some observation since d last began showing dont_walk_flashing without countdown. The subject faces d where, with Δ the vector from its kin.position to d's dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Where that step lies before the recording, applicability is unknown.",
 "obligation": "At the onset of the steady indication the subject's footprint does not overlap r (rel.occupies): it has reached a place of safety off the roadway.",
 "params": [
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "ob2",
   "why": "'a curb, sidewalk, safety zone ... or other place of safety' is read as any place off the roadway or lane the head governs; the kind of place reached is not checked.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "The pedestrian steps from the sidewalk onto r facing d while d shows walk; d turns dont_walk_flashing without countdown while it is mid-crossing, then dont_walk_steady while it is still on r."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same, but the pedestrian reaches the far sidewalk, off r, before d turns steady."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The pedestrian stepped onto r while d already showed dont_walk_flashing without countdown (no lawful entry under subparagraph (1))."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "Same as forbid but d's state is not observed.",
   "masked": [
    "dev.pedestrian_signal"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "The recording begins with the pedestrian already on r while d shows dont_walk_flashing without countdown; d turns steady while it is still on r; its step onto r is not recorded.",
   "boundary": "the pedestrian's step from the sidewalk onto r, which lies before the recording"
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-283-1d4`: the plan of iteration 1 and what followed

`NRS_484B_283_1d4_o1` — its duty: “may not proceed to cross the highway,” (characters 437–474)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below
- span `ref2` “[NRS-484B-283-1d1, NRS-484B-283-1d2]” borrows from `NRS-484B-283-1d1` the words “While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal” (as definition: no rule is composed)
- span `ref2` “[NRS-484B-283-1d1, NRS-484B-283-1d2]” borrows from `NRS-484B-283-1d2` the words “While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal” (as definition: no rule is composed)

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d4_o1",
 "law_refs": [
  "NRS-484B-283-1d4"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady",
   "role": "trigger"
  },
  {
   "id": "s1",
   "text": "a pedestrian",
   "role": "subject"
  },
  {
   "id": "ob1",
   "text": "may not proceed to cross the highway,",
   "role": "obligation"
  },
  {
   "id": "s2",
   "text": "but a pedestrian",
   "role": "exception"
  },
  {
   "id": "e1",
   "text": "who entered the highway lawfully pursuant to subparagraph (1) or (2)",
   "role": "exception"
  },
  {
   "id": "ref2",
   "text": "[NRS-484B-283-1d1, NRS-484B-283-1d2]",
   "role": "reference"
  },
  {
   "id": "e2",
   "text": "may continue to cross the highway",
   "role": "exception"
  },
  {
   "id": "ob2",
   "text": "but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety",
   "role": "sibling"
  },
  {
   "id": "st",
   "text": "as soon as possible.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; countdown attribute'). The signal that indicates to a pedestrian is the head that governs the roadway or lane its crossing traverses (dev.governs, 'the travel regions whose traffic the device controls', traffic including pedestrians by DEF-NRS-484A-285; kinds st.roadway, st.lane) and that the pedestrian faces: dev.position ('location of the device head') ahead of kin.position along kin.heading ('direction the body points') within a cone and a reach. dev.position is not used as a stop line or crossing."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'illuminated and steady' is the head's state dont_walk_steady."
  },
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "ob1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Proceeding to cross the highway is coming onto the roadway or lane the head governs: the pedestrian's footprint comes to overlap it (rel.occupies of st.roadway / st.lane). The highway (DEF-NRS-484A-095) includes the sidewalk, but the sibling words 'must proceed to a curb, sidewalk, safety zone' place the sidewalk outside the crossing, so the crossing begins on the roadway."
  },
  {
   "span": "s2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' (the one excepted) is the same admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "e1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "st.sidewalk",
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading"
   ],
   "derived": [],
   "source_spans": [
    "ref2"
   ],
   "justification": "Entering the highway lawfully pursuant to subparagraph (1) or (2) borrows their words: (1) 'While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal'; (2) 'While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal'. It is the pedestrian's latest step from a sidewalk (st.sidewalk) onto a roadway or lane (rel.occupies of st.roadway / st.lane) made while a pedestrian head (dev.pedestrian_signal) governing it (dev.governs) showed walk, or dont_walk_flashing with its countdown, and the pedestrian faced that head (dev.position ahead of kin.position along kin.heading within the cone and reach)."
  },
  {
   "span": "e2",
   "atoms": [
    "rel.occupies",
    "st.sidewalk"
   ],
   "derived": [],
   "justification": "Continuing to cross is not having returned to a sidewalk (rel.occupies of st.sidewalk) since that entry."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d1",
   "why": "It borrows the circumstances of subparagraph (1)'s permission — the walk indication illuminated, the pedestrian facing the signal, proceeding across the highway in its direction — to qualify how the pedestrian entered. Subparagraph (1)'s rule is a duty on drivers to give the right-of-way; whether that duty applied to some vehicle, held, or was complied with says nothing of how this pedestrian entered, so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d2",
   "why": "It borrows the circumstances of subparagraph (2)'s permission — the flashing don't-walk indication accompanied by a countdown timer, the pedestrian proceeding across the highway in the direction of the signal — to qualify how the pedestrian entered. Subparagraph (2)'s rule is the duty to complete the crossing before the countdown ends; lawful entry under (2) does not depend on that later duty being complied with (the entry precedes it), so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian), not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2, with no vehicle v of the scene engaged by LVMC_11_46_030_o1 or LVMC_11_46_030_o2. There are a pedestrian head d (dev.pedestrian_signal) showing dont_walk_steady and a roadway or lane r governed by d (dev.governs), the subject faces d, and the subject's footprint did not overlap r at the previous observation. The subject faces d where, with Δ the vector from its kin.position to d's dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Excepted: the subject is continuing a crossing it began lawfully under subparagraph (1) or (2) — its latest step from a sidewalk onto a roadway or lane was made while a pedestrian head governing that roadway or lane showed walk, or dont_walk_flashing with its countdown, and the subject faced that head, and its footprint has overlapped no sidewalk since.",
 "obligation": "The subject's footprint does not overlap r at this observation: it has not proceeded onto the roadway.",
 "params": [
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "ob1",
   "why": "'proceed to cross the highway' is read as the pedestrian's footprint coming onto the roadway or lane the faced head governs; walking on the sidewalk is not crossing.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "At the curb, the pedestrian faces a head 15 m away across roadway r that governs r and shows dont_walk_steady; at the next observation its footprint overlaps r."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same head and state; the pedestrian waits on the sidewalk."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The faced head shows walk."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The pedestrian steps onto r facing the head, but the head's state is not observed.",
   "masked": [
    "dev.pedestrian_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "The pedestrian stepped onto the first roadway while its head showed dont_walk_flashing with countdown, reached the median, and now steps onto the second roadway r while its faced head shows dont_walk_steady: it is continuing a lawful crossing."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

`NRS_484B_283_1d4_o2` — its duty: “but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety” (characters 632–725)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1c` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1d` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `NRS_484B_287_1e` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_A` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_060_B` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o1` as exception: a node of another law, below
- span `r` “Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:” composes `LVMC_11_46_030_o2` as exception: a node of another law, below
- span `ref2` “[NRS-484B-283-1d1, NRS-484B-283-1d2]” borrows from `NRS-484B-283-1d1` the words “While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal” (as definition: no rule is composed)
- span `ref2` “[NRS-484B-283-1d1, NRS-484B-283-1d2]” borrows from `NRS-484B-283-1d2` the words “While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal” (as definition: no rule is composed)

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_283_1d4_o2",
 "law_refs": [
  "NRS-484B-283-1d4"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-165::pedestrian"
  ]
 },
 "segmentation": [
  {
   "id": "r",
   "text": "Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:",
   "role": "reference"
  },
  {
   "id": "c0",
   "text": "Whenever signals exhibiting the words “Walk,” “Don’t Walk,” “Wait” or similar symbols are in place, such signals indicate as follows:",
   "role": "condition"
  },
  {
   "id": "t",
   "text": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated and steady",
   "role": "trigger"
  },
  {
   "id": "s1",
   "text": "a pedestrian",
   "role": "sibling"
  },
  {
   "id": "ob1",
   "text": "may not proceed to cross the highway,",
   "role": "sibling"
  },
  {
   "id": "s2",
   "text": "but a pedestrian",
   "role": "subject"
  },
  {
   "id": "e1",
   "text": "who entered the highway lawfully pursuant to subparagraph (1) or (2)",
   "role": "condition"
  },
  {
   "id": "ref2",
   "text": "[NRS-484B-283-1d1, NRS-484B-283-1d2]",
   "role": "reference"
  },
  {
   "id": "e2",
   "text": "may continue to cross the highway",
   "role": "condition"
  },
  {
   "id": "ob2",
   "text": "but must proceed to a curb, sidewalk, safety zone if one is provided or other place of safety",
   "role": "obligation"
  },
  {
   "id": "st",
   "text": "as soon as possible.",
   "role": "standard"
  }
 ],
 "elements": [
  {
   "span": "c0",
   "atoms": [
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Signals exhibiting 'Walk', 'Don't Walk', 'Wait' or similar symbols are pedestrian heads (dev.pedestrian_signal: 'a pedestrian head; state ∈ {walk, dont_walk_flashing, dont_walk_steady, dark}; countdown attribute'). The signal that indicates to a pedestrian is the head that governs the roadway or lane its crossing traverses (dev.governs, 'the travel regions whose traffic the device controls', traffic including pedestrians by DEF-NRS-484A-285; kinds st.roadway, st.lane) and that the pedestrian faced when it stepped onto it: dev.position ('location of the device head') ahead of kin.position along kin.heading ('direction the body points') within a cone and a reach. dev.position is not used as a stop line or crossing."
  },
  {
   "span": "t",
   "atoms": [
    "dev.pedestrian_signal"
   ],
   "derived": [],
   "justification": "'illuminated and steady' is the head's state dont_walk_steady."
  },
  {
   "span": "s2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'a pedestrian' is the admitted aggregate DEF-NRS-484A-165::pedestrian."
  },
  {
   "span": "e1",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "st.sidewalk",
    "dev.pedestrian_signal",
    "dev.governs",
    "dev.position",
    "kin.position",
    "kin.heading"
   ],
   "derived": [],
   "source_spans": [
    "ref2"
   ],
   "justification": "Entering the highway lawfully pursuant to subparagraph (1) or (2) borrows their words: (1) 'While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal'; (2) 'While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal'. It is the pedestrian's latest step from a sidewalk (st.sidewalk) onto the roadway or lane r (rel.occupies of st.roadway / st.lane) made while the head d (dev.pedestrian_signal) governing r (dev.governs) showed walk, or dont_walk_flashing with its countdown, and the pedestrian faced d (dev.position ahead of kin.position along kin.heading within the cone and reach)."
  },
  {
   "span": "e2",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane"
   ],
   "derived": [],
   "justification": "Continuing to cross is the pedestrian's footprint still overlapping r (rel.occupies) while d shows the steady indication."
  },
  {
   "span": "ob2",
   "atoms": [
    "rel.occupies",
    "st.roadway",
    "st.lane",
    "kin.speed"
   ],
   "derived": [],
   "justification": "Proceeding to a curb, sidewalk, safety zone or other place of safety is moving off the roadway or lane crossed: while the footprint overlaps r (rel.occupies), the pedestrian moves (kin.speed, 'magnitude of velocity'), at the pace the standard bounds. kin.speed is used as the magnitude of motion, not as acceleration."
  }
 ],
 "operationalizations": [
  {
   "span": "st",
   "standard": "as soon as possible",
   "concepts": [
    "kin.speed"
   ],
   "params": [
    "p.pedestrian_clearing_speed_min"
   ],
   "convention": "pedestrian clearance walking speed: a pedestrian still on the roadway after the steady indication proceeds as soon as possible where its speed is at least a floor well below the slow walking speed the clearance interval is timed for; lingering or halting on the roadway is below it",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "r",
   "rule": "NRS_484B_287_1c",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "NRS_484B_287_1e",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_A",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_060_B",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o1",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_30_140_B_o2",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o1",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "r",
   "rule": "LVMC_11_46_030_o2",
   "map": {
    "subject": "v"
   },
   "as": "exception"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d1",
   "why": "It borrows the circumstances of subparagraph (1)'s permission — the walk indication illuminated, the pedestrian facing the signal, proceeding across the highway in its direction — to qualify how the pedestrian entered. Subparagraph (1)'s rule is a duty on drivers to give the right-of-way; whether that duty applied to some vehicle, held, or was complied with says nothing of how this pedestrian entered, so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Walk” indication or walking person symbol is illuminated, pedestrians facing the signal may proceed across the highway in the direction of the signal"
  },
  {
   "span": "ref2",
   "as": "definition",
   "source": "NRS-484B-283-1d2",
   "why": "It borrows the circumstances of subparagraph (2)'s permission — the flashing don't-walk indication accompanied by a countdown timer, the pedestrian proceeding across the highway in the direction of the signal — to qualify how the pedestrian entered. Subparagraph (2)'s rule is the duty to complete the crossing before the countdown ends; lawful entry under (2) does not depend on that later duty being complied with (the entry precedes it), so no rule of it is composed and the qualified fact is carried by this node's own atoms.",
   "quote": "While the “Don’t Walk” or “Wait” indication or an upraised hand symbol is illuminated, is flashing and is accompanied by a countdown timer, a pedestrian may proceed across the highway in the direction of the signal"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ]
  }
 ],
 "applicability": "The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian), not engaged by NRS_484B_287_1c, NRS_484B_287_1d, NRS_484B_287_1e, LVMC_11_30_060_A, LVMC_11_30_060_B, LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2, with no vehicle v of the scene engaged by LVMC_11_46_030_o1 or LVMC_11_46_030_o2. There are a pedestrian head d (dev.pedestrian_signal) showing dont_walk_steady and a roadway or lane r governed by d (dev.governs) such that the subject's footprint overlaps r here and the subject's latest step from a sidewalk onto r (history bound: that step, searched back without other limit) was made while d showed walk, or dont_walk_flashing with its countdown, and the subject faced d. The subject faces d where, with Δ the vector from its kin.position to d's dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Where that step lies before the recording, applicability is unknown.",
 "obligation": "The subject's speed (kin.speed) is at least p.pedestrian_clearing_speed_min: it keeps moving off the roadway rather than lingering on it.",
 "params": [
  "p.pedestrian_clearing_speed_min",
  "p.ped_signal_facing_cos",
  "p.ped_signal_facing_reach"
 ],
 "narrowings": [
  {
   "span": "ob2",
   "why": "'proceed to a curb, sidewalk, safety zone ... or other place of safety' is read through the pedestrian's motion while still on the roadway; the direction it moves in (forward or back to the curb it left) is not read, and the kind of place reached is not checked.",
   "kind": "reading"
  },
  {
   "span": "st",
   "why": "'as soon as possible' is read as a speed floor at every observation on the roadway after the steady indication; the pedestrian's own ability (a slower walker) is not measured.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "The pedestrian stepped onto r from the sidewalk facing d while d showed walk; d now shows dont_walk_steady and the pedestrian stands still (0.0 m/s) in the middle of r."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same, but the pedestrian walks on across r at 1.3 m/s."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "d shows dont_walk_steady and the pedestrian waits on the sidewalk, off r."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "Same as forbid but the pedestrian's speed is not observed.",
   "masked": [
    "kin.speed"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "The recording begins with the pedestrian standing on r while d shows dont_walk_steady; its step onto r is not recorded, so whether it entered lawfully cannot be told.",
   "boundary": "the pedestrian's step from the sidewalk onto r, which lies before the recording"
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.pedestrian_clearing_speed_min",
   "unit": "m/s",
   "value": 0.5,
   "convention": "the speed below which a pedestrian still on the roadway counts as lingering rather than proceeding to a place of safety: about half the 3.0 ft/s (0.9 m/s) walking speed to which pedestrian clearance intervals are timed for slower pedestrians",
   "source": "MUTCD section 4E.06 pedestrian clearance walking speeds (3.5 ft/s, 3.0 ft/s for slower pedestrians)"
  },
  {
   "name": "p.ped_signal_facing_cos",
   "unit": "ratio",
   "value": 0.87,
   "convention": "cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a pedestrian signal head at which the pedestrian counts as facing that head: the lateral offset of a far-side head from the crossing's line plus a pedestrian's heading wander",
   "source": "MUTCD section 4E.08 (pedestrian signal heads placed at the far end of the crossing, in the pedestrian's line of sight)"
  },
  {
   "name": "p.ped_signal_facing_reach",
   "unit": "m",
   "value": 40.0,
   "convention": "the largest distance from a pedestrian to a pedestrian signal head at which the head counts as the one across the crossing the pedestrian faces: a wide urban crossing (six lanes and a median, about 30 m) plus the head's set-back behind the far curb",
   "source": "MUTCD section 4E.08; AASHTO Green Book urban cross-section widths"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

### `NRS-484B-307-8d`: the plan of iteration 1 and what followed

`NRS_484B_307_8d` — its duty: “(3) The person yields” (characters 670–691)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; coded: gate WITNESS_FAIL (branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-)
- iteration 3: repaired; the validator accepted the revision; validator accept; coded: gate BARE_LITERAL (formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading)
- state: not accepted
- span `s3` “the requirement to stop,” borrows from `NRS-484B-307-8a` the words “must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection” (as definition: no rule is composed)

The record, as coded in iteration 3:

```json
{
 "node_id": "NRS_484B_307_8d",
 "law_refs": [
  "NRS-484B-307-8d"
 ],
 "segmentation": [
  {
   "id": "s1",
   "text": "Where the signal is a steady red signal alone:",
   "role": "trigger"
  },
  {
   "id": "s2",
   "text": "After complying with",
   "role": "condition"
  },
  {
   "id": "s3",
   "text": "the requirement to stop,",
   "role": "reference"
  },
  {
   "id": "s4",
   "text": "a person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "s5",
   "text": "may proceed straight through or turn right or left",
   "role": "condition"
  },
  {
   "id": "s6",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "s7",
   "text": "(1) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device",
   "role": "condition"
  },
  {
   "id": "s8",
   "text": "and the signal does not change",
   "role": "condition"
  },
  {
   "id": "s9",
   "text": "because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;",
   "role": "condition"
  },
  {
   "id": "s10",
   "text": "(2) No other device at the place prohibits",
   "role": "condition"
  },
  {
   "id": "s11",
   "text": "either or both such turns, if applicable;",
   "role": "condition"
  },
  {
   "id": "s12",
   "text": "and",
   "role": "boilerplate"
  },
  {
   "id": "s13",
   "text": "(3) The person yields",
   "role": "obligation"
  },
  {
   "id": "s14",
   "text": "the right-of-way",
   "role": "standard"
  },
  {
   "id": "s15",
   "text": "to pedestrians and other traffic proceeding as directed by the signal at the intersection.",
   "role": "condition"
  }
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.motorcycle",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal, 'a signal head; state ∈ {circular_green, circular_yellow, circular_red, ...}; several states may be displayed at once': a steady red signal alone is circular_red and no other state (not flashing_red, and no arrow beside it). The head s is the one governing the rider's approach carrier (s7). Same atom as the index for the signal words of NRS_484B_307_2a."
  },
  {
   "span": "s2",
   "atoms": [
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection",
    "st.lane_direction",
    "st.region_geometry",
    "st.stop_line"
   ],
   "derived": [
    "drv.motion.complete_halt"
   ],
   "justification": "'After complying with the requirement to stop' requires the halt itself (rule 5), with every qualification of the requirement it names, borrowed from NRS-484B-307-8a (reference s3): 'must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection'. A stop required is DEF-NRS-484A-255, 'complete cessation from movement': drv.motion.complete_halt. The place: the stop line (st.stop_line, 'the transverse line marking where vehicles halt for a device') recorded as marking the entrance of the rider's carrier c (st.entrance_of), else the crosswalk (st.crosswalk) marking it, else c's entrance end at the intersection (st.intersection); the footprint not overlapping the region (rel.occupies), on its upstream side along c's designated direction (st.lane_direction, sign of prim.region_offset_along) and within p.stop_point_tolerance of it (st.region_geometry distance), on the approach that ends in this entry, as NRS_484B_307_8a_o1 states the place, zone and history bound. Not compliance with that node, which a composed rule grants where it is not engaged; st.region_geometry is not occupancy.",
   "source_spans": [
    "s3"
   ]
  },
  {
   "span": "s4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.motorcycle",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "The admitted aggregates for the defined words: DEF-NRS-484A-135::motorcycle ('every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels'), DEF-NRS-484A-125::moped ('a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine'), DEF-NRS-484A-025::bicycle ('a device propelled by human power upon which a person may ride'), DEF-NRS-484B-017::electric_bicycle and DEF-NRS-484B-018::electric_scooter, claimed as ru.aggregate and never expanded. 'trimobile' has no applicable definition and is not an aggregate: it is carried by ru.motorcycle, 'motor vehicle on two or three wheels ridden astride, including three-wheeled variants', the class atom that denotes a three-wheeled motor vehicle; the atom has no stand-in exclusion that applies. 'driving' and 'riding' are read through the road user's controlled motion (narrowing). Membership is decided by the run's reading of these definitions: where it leaves a class unresolved under one of them (as it does ru.motor_vehicle), a road user of that class is of unknown membership, and the rule reports unknown for it rather than not_applicable."
  },
  {
   "span": "s5",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'may proceed straight through or turn right or left': the rider's entry into intersection i (st.intersection), its footprint coming to overlap i (rel.occupies) having occupied at the observation before a travel region c (st.travel_region) whose entrance end is i (st.lane_enters); every movement through i is admitted. Same words, same atoms as the index (NRS_484B_307_2a)."
  },
  {
   "span": "s7",
   "atoms": [
    "dev.governs",
    "dev.traffic_signal",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'the applicable official traffic-control device': the signal installation of the intersection the rider is at, observed through its heads: the traffic signal heads (dev.traffic_signal) that govern (dev.governs, 'the travel regions whose traffic the device controls') a travel region (st.travel_region) entering i (st.lane_enters; st.intersection); the head s governing c is the rider's own. 'official' (DEF-NRS-484A-145, 'placed or erected by a public authority') is presumed from the head's presence (narrowing). 'waits for two complete cycles of the lights or lighted arrows': from the latest onset of its halt at the place until its entry into i the rider does not overlap i, and in that interval some head of the installation begins a green indication (circular_green or a green_arrow, the lights or lighted arrows that come on once in each cycle of the installation) at least two times: a count of that head's rising green indications since the halt's onset, against the literal two."
  },
  {
   "span": "s8",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "'the signal does not change': the rider's head s (dev.traffic_signal) displays the steady red alone (circular_red, no other state) at every observation from the latest onset of the halt to the entry."
  },
  {
   "span": "s10",
   "atoms": [
    "dev.governs",
    "dev.regulatory_sign",
    "st.intersection",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'No other device at the place prohibits': a regulatory sign (dev.regulatory_sign, 'a point regulation by catalogue code', codes no_left_turn and no_right_turn) governing (dev.governs) the rider's carrier c (st.travel_region) or the intersection i (st.intersection). Not a stand-in: 'a prohibition sign is a condition', and it is read as one, not as a manoeuvre. 'official' status is presumed from presence."
  },
  {
   "span": "s11",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.right_turn_through_region",
    "drv.motion.left_turn_through_region"
   ],
   "justification": "'either or both such turns, if applicable': the turn the rider makes on this passage through intersection i (st.intersection), from its entry (rel.occupies rising) to its exit, recognized at the exit as a right turn (drv.motion.right_turn_through_region, 'a turn to the right through region r, recognized as it leaves r') or a left turn (drv.motion.left_turn_through_region); 'if applicable': only a turn made brings a prohibition into play, and a straight passage is never prohibited by a turn sign. Read from each observation of the passage at the recognition the passage reaches, so that the condition is decided at the entry where the exit is recorded."
  },
  {
   "span": "s13",
   "atoms": [
    "kin.speed",
    "rel.contact"
   ],
   "derived": [],
   "justification": "'yields': kin.speed ('magnitude of velocity') tells a rider that moves on toward the other road user from one that holds back, and rel.contact ('the bodies of two road users ... touch or overlap (a collision)') is the crash precedence exists to avoid; not a stand-in for a near miss, which the operationalization of s14 reads. As the index maps 'must yield' (NRS_484B_307_2a)."
  },
  {
   "span": "s15",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "kin.speed",
    "rel.occupies",
    "st.intersection",
    "st.crosswalk",
    "st.entrance_of",
    "st.lane_enters",
    "st.travel_region",
    "dev.governs",
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "'pedestrians and other traffic': road users of the admitted aggregates DEF-NRS-484A-165::pedestrian and DEF-NRS-484A-285::traffic other than the rider. 'proceeding': moving, kin.speed above p.halt_speed_tolerance. 'as directed by the signal at the intersection': it overlaps (rel.occupies) intersection i (st.intersection) or a crosswalk (st.crosswalk) recorded as marking the entrance (st.entrance_of) of a travel region that enters i (st.lane_enters, st.travel_region), or it occupies a travel region c' entering i that is governed (dev.governs) by a head displaying a green indication (dev.traffic_signal: circular_green or green_arrow). Not a stand-in: st.entrance_of is the recorded association, never a distance."
  }
 ],
 "operationalizations": [
  {
   "span": "s14",
   "standard": "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "kin.speed"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance",
    "p.halt_speed_tolerance"
   ],
   "convention": "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the rider grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "s3",
   "as": "definition",
   "source": "NRS-484B-307-8a",
   "quote": "must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection",
   "why": "The words borrow the requirement's place and its order (the crosswalk on the nearest side, or the place a sign or pavement marking indicates, else the intersection's edge) and the meaning of stopping before it. The condition requires that the halt itself occurred there; a composition with NRS_484B_307_8a_o1 would not establish it, since a composed rule counts as complied with where it is not engaged, and this paragraph governs riders whether or not that duty engages them (a bicycle or electric scooter is no vehicle). So the borrowed words are carried by the halt, the place and the approach on s2, and no rule of NRS-484B-307-8a need apply, hold or be complied with."
  }
 ],
 "residues": [
  {
   "span": "s9",
   "why": "The words give the cause of the unchanged red. A head that keeps its steady red alone through two complete cycles of the installation's other indications while the rider waits at its stop place has not served the rider's approach, which is a malfunction or a failure to detect the rider; the duty is the same whichever of the two causes holds, and neither shows in the scene beyond the unchanged red (s8) and the cycles (s7), which the rule reads.",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.motorcycle",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "The subject is of one of the classes motorcycle, moped, bicycle, electric bicycle or electric scooter (admitted aggregates) or a ru.motorcycle (the trimobile). It approached intersection i through a travel region c whose entrance end is i (st.lane_enters) and which a traffic signal head s governs (dev.governs), and halted (drv.motion.complete_halt, p.halt_speed_tolerance) at the place of the stop on that approach: the stop line recorded as marking c's entrance, else the crosswalk recorded as marking it, else c's entrance end at i, with the zone (p.stop_point_tolerance) and the history bound NRS_484B_307_8a_o1 states. From the latest onset of that halt until its entry into i, s displayed a steady red alone (circular_red, no other state) at every observation and the subject's footprint did not overlap i; in that interval some traffic signal head governing a travel region that enters i began a green indication (circular_green or a green_arrow rising) at least two times (literal 2). The subject then entered i (its footprint came to overlap i, having occupied c at the observation before) while s still displayed the steady red alone, and its footprint has overlapped i at every observation since that entry, the judged one included. It is not the case that the passage through i begun at that entry is recognized at its exit (at the judged observation or a later one: the observation at which the subject's footprint ceases to overlap i) as a right turn (drv.motion.right_turn_through_region; step = p.heading_since_step_carla_scene_graph, turn_min = p.turn_heading_min, u_turn_min = p.u_turn_heading_min) while a regulatory sign coded no_right_turn governs c or i, nor as a left turn (drv.motion.left_turn_through_region) while one coded no_left_turn governs c or i; where no such sign governs, this condition holds whatever the movement, and where one governs and the exit is not recorded, it is unknown.",
 "obligation": "For every road user p other than the subject that is of the class pedestrian or of the class traffic and is proceeding as directed by the signal at i — its speed above p.halt_speed_tolerance, and either its footprint overlaps i or a crosswalk recorded as marking the entrance of a travel region that enters i, or it occupies a travel region c' entering i governed by a head that displays circular_green or a green_arrow: it is not the case that the subject's speed is above p.halt_speed_tolerance while the closest approach of the two centres lies within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance); and the subject's body does not touch p's (rel.contact).",
 "params": [
  "p.halt_speed_tolerance",
  "p.stop_point_tolerance",
  "p.conflict_horizon",
  "p.conflict_centre_clearance",
  "p.heading_since_step_carla_scene_graph",
  "p.turn_heading_min",
  "p.u_turn_heading_min"
 ],
 "narrowings": [
  {
   "span": "s4",
   "why": "'driving' and 'riding' are read through the road user's controlled motion, whoever or whatever is at its controls.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s7",
   "why": "'official' traffic-control device: the presence of the signal heads at the intersection is the evidence of their official status.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s13",
   "why": "'proceeding as directed by the signal at the intersection' is read through the signal state governing the other road user's approach (a green indication) where it approaches, and through its presence within the intersection or an adjacent crosswalk where it is there; a road user that entered against its own red and is now within the intersection is yielded to as well.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A moped halts 1 m short of the stop line marking lane c's entrance while head s displays circular_red alone; while it waits, the head governing the cross street's lane begins circular_green twice and s stays circular_red alone; no turn-prohibiting sign governs c or i. The moped enters i straight through at 5 m/s while a pedestrian walks at 1.3 m/s in the crosswalk marking the entrance of the far approach, the closest approach of their centres 1.0 s ahead at 0.6 m."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same wait and entry with no other road user in the scene: the duty binds the rider alone and is met."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The moped halts at the line and enters i after the cross street's head has begun circular_green only once since its halt: the wait of two cycles is not met."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but the source does not observe which travel regions the heads govern: which head is the rider's and whether the cross head belongs to this intersection are unknown.",
   "masked": [
    "dev.governs"
   ]
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "As forbid, but the moped halted 15 m short of the line behind a queue and, when the queue cleared, rolled to the line and into i without halting at the place: the halt the requirement to stop names did not occur, and the paragraph does not apply."
  },
  {
   "name": "branch_3",
   "expected": "not_applicable",
   "narrative": "As forbid, but a regulatory sign coded no_right_turn governs lane c and the moped's passage through i is recognized at its exit as a right turn (heading change -85 degrees): a device at the place prohibits the turn it made, and the permission with its yield does not arise."
  }
 ],
 "literals": [
  {
   "span": "s7",
   "text": "two",
   "value": 2,
   "unit": "count"
  }
 ],
 "param_proposals": [
  {
   "name": "p.turn_heading_min",
   "unit": "deg",
   "value": 45.0,
   "convention": "the smallest heading change over the turn window at which a change of course counts as a turn rather than a lane change or a drift",
   "source": "proposed this iteration by LVMC_11_40_080_o1; repeated unchanged"
  },
  {
   "name": "p.u_turn_heading_min",
   "unit": "deg",
   "value": 135.0,
   "convention": "the smallest heading change magnitude over the turn window at which a turn counts as a reversal of direction",
   "source": "proposed this iteration by LVMC_11_40_080_o1; repeated unchanged"
  },
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin",
   "source": "proposed this iteration by LVMC_11_20_060_o1; repeated unchanged"
  },
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {}
}
```

It differs from the record planned in iteration 1 in: `elements` (s4), `planned_on`, `scenarios` (branch_1).

### `NRS-484B-307-8a`: the plan of iteration 1 and what followed

`NRS_484B_307_8a_o1` — its duty: “must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,” (characters 83–333)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; coded: gate OK (10 witnesses, 14 names, composes nothing)
- state: accepted
- composes no rule

The record, as accepted:

```json
{
 "node_id": "NRS_484B_307_8a_o1",
 "law_refs": [
  "NRS-484B-307-8a"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-285::traffic",
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Where the signal is a steady red signal alone:",
   "role": "trigger"
  },
  {
   "id": "s2",
   "text": "Vehicular traffic facing the signal",
   "role": "subject"
  },
  {
   "id": "s3",
   "text": "must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,",
   "role": "obligation"
  },
  {
   "id": "s4",
   "text": "and,",
   "role": "boilerplate"
  },
  {
   "id": "s5",
   "text": "except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],",
   "role": "sibling"
  },
  {
   "id": "s6",
   "text": "must remain stopped or standing until the green signal is shown.",
   "role": "sibling"
  },
  {
   "id": "s7",
   "text": "After complying with the requirement to stop,",
   "role": "sibling"
  },
  {
   "id": "s8",
   "text": "vehicular traffic facing such a signal and situated on the extreme right of the highway",
   "role": "sibling"
  },
  {
   "id": "s9",
   "text": "may proceed into the intersection",
   "role": "sibling"
  },
  {
   "id": "s10",
   "text": "for a right turn",
   "role": "sibling"
  },
  {
   "id": "s11",
   "text": "only when the intersecting highway is two-directional or one-way to the right,",
   "role": "sibling"
  },
  {
   "id": "s12",
   "text": "or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway",
   "role": "sibling"
  },
  {
   "id": "s13",
   "text": "may proceed into the intersection",
   "role": "sibling"
  },
  {
   "id": "s14",
   "text": "for a left turn",
   "role": "sibling"
  },
  {
   "id": "s15",
   "text": "only when the intersecting highway is one-way to the left,",
   "role": "sibling"
  },
  {
   "id": "s16",
   "text": "but must yield",
   "role": "sibling"
  },
  {
   "id": "s17",
   "text": "the right-of-way",
   "role": "sibling"
  },
  {
   "id": "s18",
   "text": "to pedestrians and other traffic proceeding as directed by the signal at the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal, 'a signal head; state ∈ {circular_green, circular_yellow, circular_red, ...}; several states may be displayed at once': a steady red signal alone is circular_red and no other state (not flashing_red, and no arrow beside it). Same atom as the index for the signal words of NRS_484B_307_2a."
  },
  {
   "span": "s2",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'Vehicular traffic': the admitted aggregates DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle ('every device in, upon or by which any person or property is or may be transported or drawn upon a highway'), claimed as ru.aggregate, never expanded. 'facing the signal': the subject occupies (rel.occupies) a travel region c (st.travel_region) whose entrance end is intersection i (st.lane_enters; st.intersection) and which the head governs (dev.governs, 'the travel regions whose traffic the device controls'). Not a stand-in: dev.governs is not the place of the halt, st.lane_enters not presence in i. Same words, same atoms as the index (NRS_484B_307_2a)."
  },
  {
   "span": "s3",
   "atoms": [
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection",
    "st.lane_direction",
    "st.region_geometry",
    "st.stop_line"
   ],
   "derived": [
    "drv.motion.complete_halt"
   ],
   "justification": "'must stop': a stop required, DEF-NRS-484A-255, '\"Stop,\" when required, means complete cessation from movement': drv.motion.complete_halt. 'before entering the crosswalk on the nearest side of the intersection': the crosswalk (st.crosswalk, 'marked crossing, or the unmarked prolongation of sidewalks at an intersection') recorded as marking the entrance of the subject's carrier c (st.entrance_of, 'the line or crossing a vehicle approaching through that carrier halts at or before'); 'where the sign or pavement marking indicates where the stop must be made': the stop line (st.stop_line, 'the transverse line marking where vehicles halt for a device') recorded as marking c's entrance; 'or in the absence of any such crosswalk, sign or marking, then before entering the intersection': c's entrance end at intersection i (st.intersection). 'before entering': the footprint does not yet overlap the region (rel.occupies); the side is read by the sign of prim.region_offset_along along c's designated direction (st.lane_direction), the distance to the place by st.region_geometry ('the ground distance from a road user's body outline to it'). Not a stand-in: st.region_geometry is not occupancy, and prim.region_offset_along is read for the side only, never as the distance. Same mapping as the index for the stop words of NRS_484A_450_2 and NRS_484A_450_3."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject, of the classes traffic and vehicle, enters intersection i at the judged observation: its footprint overlaps i (rel.occupies) there and did not at the previous observation, at which it occupied a travel region c whose entrance end is i (st.lane_enters) and which a traffic signal head s governs (dev.governs); and s displays at the judged observation a steady red alone (circular_red and no other state).",
 "obligation": "Rule 4c duty: an act at a place before an event. Event: the entry into i just described; each such entry is its own occurrence. Place: the stop line recorded as marking c's entrance (st.entrance_of) where one is; else the crosswalk recorded as marking c's entrance; else c's entrance end at the edge of i. Where a mark's association with c is not observed, whether it governs is unknown; where its list of entrances is observed and excludes c, it does not govern and the next place in that order is read. Act: a complete halt (drv.motion.complete_halt, speed_tol = p.halt_speed_tolerance) at an observation at which the subject occupies c, its footprint overlaps neither i nor the crosswalk marking c's entrance and it is not past the stop line where one is the place, it lies on the upstream side of the place along c's designated direction (st.lane_direction; the sign of prim.region_offset_along shows the place ahead, or zero on the line), and its body is within p.stop_point_tolerance of the place (st.region_geometry distance). History bound: the search runs back from the entry and ends at the approach start, the last observation before the entry at which the subject, on c, is outside the place's stopping zone upstream (off the place, short of it, and farther from it than p.stop_point_tolerance), or at the subject's previous entry into i from c, whichever is later; nothing else ends it: not the start of the recording, not the subject's first observation, not another intersection or mark, not a distance travelled. Only an observed exit from the zone upstream begins a new approach; a creep, a lateral move or a change of lane within the zone keeps a halt already made. A halt found: complied. Either end reached without a halt: violated. Neither end reached and no halt found (the recording begins with the subject inside the zone): unknown. Whether the entry occurred is unknown where the observation before does not show the subject on a mapped carrier whose association with the place is observed, or where there is no observation before.",
 "params": [
  "p.halt_speed_tolerance",
  "p.stop_point_tolerance"
 ],
 "narrowings": [
  {
   "span": "s3",
   "why": "The place 'where the sign or pavement marking indicates where the stop must be made' is read as the stop line the source records as marking the approach's entrance: a sign standing without a line indicates a place the ontology does not record (no regulatory sign code marks a stopping point), so where only such a sign indicates the place the duty is read at the crosswalk or the intersection's edge. The places are read in the order stop line, crosswalk, edge of the intersection, a halt before the first that marks the approach meeting the words for all of them.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A car occupies lane c, recorded as entering i and governed by head s displaying circular_red alone; a stop line marks c's entrance. The car passes the line at 12 m/s, its speed never at or below the halt tolerance, and its footprint comes to overlap i while s still displays circular_red alone; the search from the entry reaches the approach start (the car 40 m short of the line) without a halt."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "Same approach; the car halts with its body 1 m short of the stop line, footprint off the line and the crosswalk, waits, and then enters i for a right turn while s still displays circular_red alone: the halt lies within the approach."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The car enters i while s displays circular_green alone."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but the source supplies no speed for the car at any observation of the approach: whether it halted is unknown.",
   "masked": [
    "kin.speed"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "The recording begins with the car already on c with its body 1.5 m short of the stop line, moving at 1 m/s; it enters i under circular_red alone without halting in the recording. The approach start and any earlier entry lie before the recording, so neither end of the search is reached.",
   "boundary": "the car's approach on c before it came within the stop-point tolerance of the stop line"
  },
  {
   "name": "branch_1",
   "expected": "compliant",
   "narrative": "No stop line or crosswalk marks c's entrance (every line's and crosswalk's list of entrances is observed and excludes c); the car halts with its body 1 m short of the edge of i and then enters i under circular_red alone: the place is the intersection's edge."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin",
   "source": "proposed this iteration by LVMC_11_20_060_o1; repeated unchanged"
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {},
 "context": "cf595f5a91e4390b345146b0"
}
```

It differs from the record planned in iteration 1 in: `context`, `planned_on`.

`NRS_484B_307_8a_o2` — its duty: “must remain stopped or standing until the green signal is shown.” (characters 436–500)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator return: NRS_484B_307_8a_o2: span s7 `After complying with the requirement to stop,` has role exception; accepted node NRS_484B_307_8a_o3 of the same law segments these words as condition, and the role of words is fixed with the segmentation once a ; not coded
- state: not accepted, never coded
- span `s5` “except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],” composes `NRS_484B_307_8d` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_8a_o2",
 "law_refs": [
  "NRS-484B-307-8a"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-285::traffic",
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Where the signal is a steady red signal alone:",
   "role": "trigger"
  },
  {
   "id": "s2",
   "text": "Vehicular traffic facing the signal",
   "role": "subject"
  },
  {
   "id": "s3",
   "text": "must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,",
   "role": "sibling"
  },
  {
   "id": "s4",
   "text": "and,",
   "role": "boilerplate"
  },
  {
   "id": "s5",
   "text": "except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],",
   "role": "reference"
  },
  {
   "id": "s6",
   "text": "must remain stopped or standing until the green signal is shown.",
   "role": "obligation"
  },
  {
   "id": "s7",
   "text": "After complying with the requirement to stop,",
   "role": "exception"
  },
  {
   "id": "s8",
   "text": "vehicular traffic facing such a signal and situated on the extreme right of the highway",
   "role": "exception"
  },
  {
   "id": "s9",
   "text": "may proceed into the intersection",
   "role": "exception"
  },
  {
   "id": "s10",
   "text": "for a right turn",
   "role": "exception"
  },
  {
   "id": "s11",
   "text": "only when the intersecting highway is two-directional or one-way to the right,",
   "role": "exception"
  },
  {
   "id": "s12",
   "text": "or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway",
   "role": "exception"
  },
  {
   "id": "s13",
   "text": "may proceed into the intersection",
   "role": "exception"
  },
  {
   "id": "s14",
   "text": "for a left turn",
   "role": "exception"
  },
  {
   "id": "s15",
   "text": "only when the intersecting highway is one-way to the left,",
   "role": "exception"
  },
  {
   "id": "s16",
   "text": "but must yield",
   "role": "sibling"
  },
  {
   "id": "s17",
   "text": "the right-of-way",
   "role": "sibling"
  },
  {
   "id": "s18",
   "text": "to pedestrians and other traffic proceeding as directed by the signal at the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal, 'a signal head; state ∈ {circular_green, circular_yellow, circular_red, ...}; several states may be displayed at once': a steady red signal alone is circular_red and no other state (not flashing_red, and no arrow beside it). Same atom as the index for the signal words of NRS_484B_307_2a."
  },
  {
   "span": "s2",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'Vehicular traffic': the admitted aggregates DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle, claimed as ru.aggregate, never expanded. 'facing the signal': the subject occupies (rel.occupies) a travel region c (st.travel_region) whose entrance end is intersection i (st.lane_enters; st.intersection) and which the head governs (dev.governs, 'the travel regions whose traffic the device controls'). Not a stand-in: dev.governs is not a position, st.lane_enters not presence in i. Same words, same atoms as the index (NRS_484B_307_2a)."
  },
  {
   "span": "s6",
   "atoms": [
    "dev.traffic_signal",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection"
   ],
   "derived": [],
   "justification": "'remain stopped or standing' (DEF-NRS-484A-255, 'complete cessation from movement'; DEF-NRS-484A-250, 'the halting of a vehicle ... otherwise than for the purpose of and while actually engaged in receiving or discharging passengers') at the place of the stop: the subject's footprint does not come to overlap (rel.occupies) the crosswalk recorded as marking c's entrance (st.crosswalk, st.entrance_of) nor intersection i (st.intersection). 'until the green signal is shown': the duty holds while the head (dev.traffic_signal) displays the steady red alone and ends once it displays another state. Not a stand-in: st.entrance_of is the recorded association, never a distance."
  },
  {
   "span": "s7",
   "atoms": [
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection",
    "st.lane_direction",
    "st.region_geometry",
    "st.stop_line"
   ],
   "derived": [
    "drv.motion.complete_halt"
   ],
   "justification": "'After complying with the requirement to stop' refers to s3 of this line and requires the halt itself with every qualification s3 states: 'must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection'. A complete halt (drv.motion.complete_halt; DEF-NRS-484A-255, 'complete cessation from movement') at that place — the stop line (st.stop_line) recorded as marking c's entrance (st.entrance_of), else the crosswalk (st.crosswalk) marking it, else c's entrance end at i (st.intersection) — with the footprint not overlapping the region (rel.occupies), on its upstream side along c's direction (st.lane_direction, sign of prim.region_offset_along) and within p.stop_point_tolerance of it (st.region_geometry), on the approach that ends in this entry: the place, zone and history bound of NRS_484B_307_8a_o1. The halt itself, not compliance with that node, which a composed rule grants where it is not engaged."
  },
  {
   "span": "s8",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.lane",
    "st.lane_adjacency",
    "st.lane_enters"
   ],
   "derived": [],
   "justification": "'vehicular traffic': the admitted aggregates DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle. 'facing such a signal': the steady red head governs (dev.governs) the carrier c the subject occupies (rel.occupies), whose entrance end is i (st.lane_enters). 'situated on the extreme right of the highway': c is a lane (st.lane, 'a longitudinal strip of roadway for one line of vehicles') whose ordinal equals the count of lanes in its direction (st.lane_adjacency, 'lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane'): the rightmost lane. Not a stand-in: lane membership is read from the ordinal, never from a lateral offset ('lane membership is not an offset from the edge')."
  },
  {
   "span": "s9",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'may proceed into the intersection': the subject's entry into intersection i (st.intersection), its footprint coming to overlap i (rel.occupies) having occupied at the observation before the travel region c (st.travel_region) whose entrance end is i (st.lane_enters); the place at which the intention of s10 is declared. As the index maps 'may proceed straight through or turn right or left' (NRS_484B_307_2a)."
  },
  {
   "span": "s11",
   "atoms": [
    "st.highway",
    "st.on_way",
    "st.intersection",
    "st.lane",
    "st.lane_direction",
    "st.median_or_divider"
   ],
   "derived": [],
   "justification": "'the intersecting highway': each highway region (st.highway, 'the entire public way between its boundary lines') that i lies on (st.on_way, 'an intersection lies on every way that meets there') other than a highway c lies on. 'two-directional' (DEF-NRS-484B-073, 'an undivided highway upon which vehicles are allowed to proceed in opposite directions'): no median or dividing section (st.median_or_divider, 'physical barrier or dividing section between roadways') lies on it, and two lanes (st.lane) lying on it carry designated directions (st.lane_direction) whose cosine is below minus p.lane_opposed_direction_cos. 'one-way to the right': at least one lane lies on it and every lane lying on it carries a designated direction to the right of c's designated direction, the cross product of c's direction with the lane's (d_x times l_y minus d_y times l_x) being below minus p.cross_direction_sin_min. Not a stand-in: st.on_way is the way a region lies on, not nearness; st.lane_direction is local to its carrier."
  },
  {
   "span": "s12",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.lane",
    "st.lane_adjacency",
    "st.lane_enters",
    "st.one_way_roadway"
   ],
   "derived": [],
   "justification": "'vehicular traffic facing such a signal': as s8. 'situated on the extreme left': c is a lane (st.lane) of ordinal 1 (st.lane_adjacency, 'ordinal 1 is the leftmost lane'); 'of a one-way highway': the subject's footprint overlaps (rel.occupies) a one-way roadway (st.one_way_roadway, 'roadway on which traffic is restricted to one direction'), as the index maps 'Upon a highway designated and signposted for one-way traffic' (NRS_484B_220_1). Not a stand-in: lane membership is read from the ordinal, never from an offset."
  },
  {
   "span": "s13",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "As s9: the subject's entry into i from c (rel.occupies rising; st.lane_enters; st.travel_region; st.intersection), the place at which the intention of s14 is declared."
  },
  {
   "span": "s15",
   "atoms": [
    "st.highway",
    "st.on_way",
    "st.intersection",
    "st.lane",
    "st.lane_direction"
   ],
   "derived": [],
   "justification": "'the intersecting highway': each highway region (st.highway) that i lies on (st.on_way) other than a highway c lies on. 'one-way to the left': at least one lane (st.lane) lies on it and every lane lying on it carries a designated direction (st.lane_direction) to the left of c's designated direction, the cross product of c's direction with the lane's being above p.cross_direction_sin_min. Not a stand-in: st.on_way is not nearness."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [
  {
   "span": "s10",
   "id": "int.right_turn"
  },
  {
   "span": "s14",
   "id": "int.left_turn"
  }
 ],
 "compositions": [
  {
   "span": "s5",
   "rule": "NRS_484B_307_8d",
   "map": {
    "subject": "subject"
   },
   "as": "exception"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject, of the classes traffic and vehicle, occupies at the judged observation, or occupied at the previous one, a travel region c whose entrance end is intersection i (st.lane_enters) and which a traffic signal head s governs (dev.governs); s displays a steady red alone (circular_red, no other state) at the judged observation; and at the previous observation the subject's footprint overlapped neither i nor a crosswalk recorded as marking c's entrance (st.entrance_of). Exception (paragraph (c), appended in this line, s7 to s15): at the judged observation the subject's footprint overlaps i, it has halted at the place of the stop on this approach (the place, zone and history bound of NRS_484B_307_8a_o1), and either (right) c is a lane whose ordinal equals the count of lanes in its direction, int.right_turn is declared true for the subject at i, and every highway i lies on other than one c lies on is two-directional (no median or divider lies on it; two lanes on it with directions opposed within p.lane_opposed_direction_cos) or one-way to the right (every lane on it points to the right of c's direction by more than p.cross_direction_sin_min); or (left) c is a lane of ordinal 1, the subject's footprint overlaps a one-way roadway, int.left_turn is declared true for the subject at i, and every such highway is one-way to the left. Exception (paragraph (d), s5): NRS_484B_307_8d applies to the subject.",
 "obligation": "At the judged observation the subject's footprint overlaps neither i nor a crosswalk recorded as marking c's entrance (rel.occupies): having stopped, or still short of the place, it remains short of them while the steady red alone is displayed; once s displays another state (the green shown) the duty no longer applies.",
 "params": [
  "p.halt_speed_tolerance",
  "p.stop_point_tolerance",
  "p.lane_opposed_direction_cos",
  "p.cross_direction_sin_min"
 ],
 "narrowings": [
  {
   "span": "s6",
   "why": "'remain stopped or standing' is read at the place the stop was due: the subject leaves the stop when its footprint comes to overlap the crosswalk marking its carrier's entrance or the intersection while the steady red alone is displayed. A movement short of them, such as closing up behind a vehicle ahead before reaching the place or a creep within the stop-point zone, is not read as leaving the stop: the stop the words require is the one at the place.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A car halts at the stop line of lane c (ordinal 2 of 3), which enters i and is governed by head s displaying circular_red alone; int.right_turn is not declared; 5 s later it moves off and its footprint comes to overlap the crosswalk marking c's entrance while s still displays circular_red alone."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The car halts at the line under circular_red alone and stays short of the crosswalk until s displays circular_green; it then enters i."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "s displays circular_green alone throughout the car's approach and entry."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but the source does not observe which travel regions s governs: whether the car faces s is unknown.",
   "masked": [
    "dev.governs"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "The car halts with its body 1 m short of the stop line in the rightmost lane (ordinal 3 of 3), int.right_turn is declared for it at i, and the cross street is undivided with lanes in both directions; it enters i under circular_red alone: paragraph (c)'s exception holds."
  },
  {
   "name": "branch_2",
   "expected": "violated",
   "narrative": "As branch_1, but the cross street is one-way and every lane on it points to the car's left: the exception does not hold, and the entry under the red violates."
  },
  {
   "name": "branch_3",
   "expected": "violated",
   "narrative": "As branch_1, but the car halted 15 m short of the line behind a queue and, when the queue cleared, rolled to the line and into i without halting at the place: the halt the exception refers to did not occur."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin",
   "source": "proposed this iteration by LVMC_11_20_060_o1; repeated unchanged"
  },
  {
   "name": "p.lane_opposed_direction_cos",
   "unit": "ratio",
   "value": 0.9,
   "convention": "cosine of the largest angle (about twenty-five degrees) off exactly opposed at which the designated directions of two mapped lanes of one way count as opposite directions of travel: the direction noise of map lane segments along a gently curving way",
   "source": "map lane-direction tolerance, matching the catalogue's tolerance for opposed vehicle headings (p.oncoming_heading_cos)"
  },
  {
   "name": "p.cross_direction_sin_min",
   "unit": "ratio",
   "value": 0.5,
   "convention": "sine of the smallest angle (thirty degrees) by which a way's designated direction lies to one side of an approach's designated direction for that way's traffic to count as flowing to that side: the legs of a junction meet at larger angles, and map direction noise is far smaller",
   "source": "intersection design guidance limiting the skew of junction legs"
  }
 ],
 "gaps": [],
 "gap_resolutions": []
}
```

`NRS_484B_307_8a_o3` — its duty: “but must yield” (characters 970–984)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; coded: gate OK (9 witnesses, 27 names, composes nothing)
- state: accepted
- composes no rule

The record, as accepted:

```json
{
 "node_id": "NRS_484B_307_8a_o3",
 "law_refs": [
  "NRS-484B-307-8a"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-285::traffic",
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Where the signal is a steady red signal alone:",
   "role": "trigger"
  },
  {
   "id": "s2",
   "text": "Vehicular traffic facing the signal",
   "role": "subject"
  },
  {
   "id": "s3",
   "text": "must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,",
   "role": "sibling"
  },
  {
   "id": "s4",
   "text": "and,",
   "role": "boilerplate"
  },
  {
   "id": "s5",
   "text": "except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],",
   "role": "sibling"
  },
  {
   "id": "s6",
   "text": "must remain stopped or standing until the green signal is shown.",
   "role": "sibling"
  },
  {
   "id": "s7",
   "text": "After complying with the requirement to stop,",
   "role": "condition"
  },
  {
   "id": "s8",
   "text": "vehicular traffic facing such a signal and situated on the extreme right of the highway",
   "role": "subject"
  },
  {
   "id": "s9",
   "text": "may proceed into the intersection",
   "role": "condition"
  },
  {
   "id": "s10",
   "text": "for a right turn",
   "role": "condition"
  },
  {
   "id": "s11",
   "text": "only when the intersecting highway is two-directional or one-way to the right,",
   "role": "condition"
  },
  {
   "id": "s12",
   "text": "or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway",
   "role": "subject"
  },
  {
   "id": "s13",
   "text": "may proceed into the intersection",
   "role": "condition"
  },
  {
   "id": "s14",
   "text": "for a left turn",
   "role": "condition"
  },
  {
   "id": "s15",
   "text": "only when the intersecting highway is one-way to the left,",
   "role": "condition"
  },
  {
   "id": "s16",
   "text": "but must yield",
   "role": "obligation"
  },
  {
   "id": "s17",
   "text": "the right-of-way",
   "role": "standard"
  },
  {
   "id": "s18",
   "text": "to pedestrians and other traffic proceeding as directed by the signal at the intersection.",
   "role": "condition"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal, 'a signal head; state ∈ {circular_green, circular_yellow, circular_red, ...}; several states may be displayed at once': a steady red signal alone is circular_red and no other state (not flashing_red, and no arrow beside it). Same atom as the index for the signal words of NRS_484B_307_2a."
  },
  {
   "span": "s2",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'Vehicular traffic': the admitted aggregates DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle, claimed as ru.aggregate, never expanded. 'facing the signal': the subject occupies (rel.occupies) a travel region c (st.travel_region) whose entrance end is intersection i (st.lane_enters; st.intersection) and which the head governs (dev.governs, 'the travel regions whose traffic the device controls'). Not a stand-in: dev.governs is not a position, st.lane_enters not presence in i. Same words, same atoms as the index (NRS_484B_307_2a)."
  },
  {
   "span": "s7",
   "atoms": [
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.intersection",
    "st.lane_direction",
    "st.region_geometry",
    "st.stop_line"
   ],
   "derived": [
    "drv.motion.complete_halt"
   ],
   "justification": "'After complying with the requirement to stop' refers to s3 of this line and requires the halt itself with every qualification s3 states: 'must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection'. A complete halt (drv.motion.complete_halt; DEF-NRS-484A-255, 'complete cessation from movement') at that place — the stop line (st.stop_line) recorded as marking c's entrance (st.entrance_of), else the crosswalk (st.crosswalk) marking it, else c's entrance end at i (st.intersection) — with the footprint not overlapping the region (rel.occupies), on its upstream side along c's direction (st.lane_direction, sign of prim.region_offset_along) and within p.stop_point_tolerance of it (st.region_geometry), on the approach that ends in this entry: the place, zone and history bound of NRS_484B_307_8a_o1. The halt itself, not compliance with that node, which a composed rule grants where it is not engaged."
  },
  {
   "span": "s8",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.lane",
    "st.lane_adjacency",
    "st.lane_enters"
   ],
   "derived": [],
   "justification": "'vehicular traffic': the admitted aggregates DEF-NRS-484A-285::traffic and DEF-NRS-484A-320::vehicle. 'facing such a signal': the steady red head governs (dev.governs) the carrier c the subject occupies (rel.occupies), whose entrance end is i (st.lane_enters). 'situated on the extreme right of the highway': c is a lane (st.lane, 'a longitudinal strip of roadway for one line of vehicles') whose ordinal equals the count of lanes in its direction (st.lane_adjacency, 'lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane'): the rightmost lane. Not a stand-in: lane membership is read from the ordinal, never from a lateral offset."
  },
  {
   "span": "s9",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'may proceed into the intersection': the subject's entry into intersection i (st.intersection), its footprint coming to overlap i (rel.occupies) having occupied at the observation before the travel region c (st.travel_region) whose entrance end is i (st.lane_enters); the place at which the intention of s10 is declared. As the index maps 'may proceed straight through or turn right or left' (NRS_484B_307_2a)."
  },
  {
   "span": "s11",
   "atoms": [
    "st.highway",
    "st.on_way",
    "st.intersection",
    "st.lane",
    "st.lane_direction",
    "st.median_or_divider"
   ],
   "derived": [],
   "justification": "'the intersecting highway': each highway region (st.highway, 'the entire public way between its boundary lines') that i lies on (st.on_way, 'an intersection lies on every way that meets there') other than a highway c lies on. 'two-directional' (DEF-NRS-484B-073, 'an undivided highway upon which vehicles are allowed to proceed in opposite directions'): no median or dividing section (st.median_or_divider, 'physical barrier or dividing section between roadways') lies on it, and two lanes (st.lane) lying on it carry designated directions (st.lane_direction) whose cosine is below minus p.lane_opposed_direction_cos. 'one-way to the right': at least one lane lies on it and every lane lying on it carries a designated direction to the right of c's designated direction, the cross product of c's direction with the lane's (d_x times l_y minus d_y times l_x) being below minus p.cross_direction_sin_min. Not a stand-in: st.on_way is the way a region lies on, not nearness; st.lane_direction is local to its carrier."
  },
  {
   "span": "s12",
   "atoms": [
    "dev.governs",
    "rel.occupies",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "st.lane",
    "st.lane_adjacency",
    "st.lane_enters",
    "st.one_way_roadway"
   ],
   "derived": [],
   "justification": "'vehicular traffic facing such a signal': as s8. 'situated on the extreme left': c is a lane (st.lane) of ordinal 1 (st.lane_adjacency, 'ordinal 1 is the leftmost lane'); 'of a one-way highway': the subject's footprint overlaps (rel.occupies) a one-way roadway (st.one_way_roadway, 'roadway on which traffic is restricted to one direction'), as the index maps 'Upon a highway designated and signposted for one-way traffic' (NRS_484B_220_1). Not a stand-in: lane membership is read from the ordinal, never from an offset."
  },
  {
   "span": "s13",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "As s9: the subject's entry into i from c (rel.occupies rising; st.lane_enters; st.travel_region; st.intersection), the place at which the intention of s14 is declared."
  },
  {
   "span": "s15",
   "atoms": [
    "st.highway",
    "st.on_way",
    "st.intersection",
    "st.lane",
    "st.lane_direction"
   ],
   "derived": [],
   "justification": "'the intersecting highway': each highway region (st.highway) that i lies on (st.on_way) other than a highway c lies on. 'one-way to the left': at least one lane (st.lane) lies on it and every lane lying on it carries a designated direction (st.lane_direction) to the left of c's designated direction, the cross product of c's direction with the lane's being above p.cross_direction_sin_min. Not a stand-in: st.on_way is not nearness."
  },
  {
   "span": "s16",
   "atoms": [
    "kin.speed",
    "rel.contact"
   ],
   "derived": [],
   "justification": "'must yield': kin.speed ('magnitude of velocity') tells a subject that moves on toward the other road user from one that holds back, and rel.contact ('the bodies of two road users ... touch or overlap (a collision)') is the crash precedence exists to avoid; not a stand-in for a near miss, which the operationalization of s17 reads. Same words, same atoms as the index (NRS_484B_307_2a)."
  },
  {
   "span": "s18",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "kin.speed",
    "rel.occupies",
    "st.intersection",
    "st.crosswalk",
    "st.entrance_of",
    "st.lane_enters",
    "st.travel_region",
    "dev.governs",
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "'pedestrians and other traffic': road users of the admitted aggregates DEF-NRS-484A-165::pedestrian and DEF-NRS-484A-285::traffic other than the subject. 'proceeding': moving, kin.speed above p.halt_speed_tolerance. 'as directed by the signal at the intersection': it overlaps (rel.occupies) intersection i (st.intersection) or a crosswalk (st.crosswalk) recorded as marking the entrance (st.entrance_of) of a travel region that enters i (st.lane_enters, st.travel_region), or it occupies a travel region c' entering i that is governed (dev.governs) by a head displaying a green indication (dev.traffic_signal: circular_green or green_arrow). Not a stand-in: st.entrance_of is the recorded association, never a distance."
  }
 ],
 "operationalizations": [
  {
   "span": "s17",
   "standard": "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'",
   "concepts": [
    "prim.closest_approach_within",
    "prim.closest_approach_distance",
    "kin.speed"
   ],
   "params": [
    "p.conflict_horizon",
    "p.conflict_centre_clearance",
    "p.halt_speed_tolerance"
   ],
   "convention": "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the subject grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [
  {
   "span": "s10",
   "id": "int.right_turn",
   "meaning": "the source's current plan for the road user includes a turn to the right at the target region, the plan's preparation for that turn included"
  },
  {
   "span": "s14",
   "id": "int.left_turn",
   "meaning": "the source's current plan for the road user includes a turn to the left at the target region, the plan's preparation for that turn included"
  }
 ],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject, of the classes traffic and vehicle, approached intersection i through a travel region c whose entrance end is i (st.lane_enters) and which a traffic signal head s governs (dev.governs), and entered i (its footprint came to overlap i, having occupied c and not i at the observation before) at an observation at which s displayed a steady red alone (circular_red, no other state), after halting at the place of the stop on that approach (s7: the place, zone and history bound of NRS_484B_307_8a_o1); at that entry either (right) c is a lane whose ordinal equals the count of lanes in its direction, int.right_turn is declared true for the subject at i, and every highway i lies on other than one c lies on is two-directional (no median or divider lies on it; two lanes on it with directions opposed within p.lane_opposed_direction_cos) or one-way to the right (every lane on it points to the right of c's direction by more than p.cross_direction_sin_min); or (left) c is a lane of ordinal 1, the subject's footprint overlaps a one-way roadway, int.left_turn is declared true for the subject at i, and every such highway is one-way to the left. Its footprint has overlapped i at every observation since that entry, the judged one included.",
 "obligation": "For every road user p other than the subject that is of the class pedestrian or of the class traffic and is proceeding as directed by the signal at i — its speed above p.halt_speed_tolerance, and either its footprint overlaps i or a crosswalk recorded as marking the entrance of a travel region that enters i, or it occupies a travel region c' entering i governed by a head that displays circular_green or a green_arrow: it is not the case that the subject's speed is above p.halt_speed_tolerance while the closest approach of the two centres lies within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance); and the subject's body does not touch p's (rel.contact).",
 "params": [
  "p.halt_speed_tolerance",
  "p.stop_point_tolerance",
  "p.lane_opposed_direction_cos",
  "p.cross_direction_sin_min",
  "p.conflict_horizon",
  "p.conflict_centre_clearance"
 ],
 "narrowings": [
  {
   "span": "s16",
   "why": "'proceeding as directed by the signal at the intersection' is read through the signal state governing the other road user's approach (a green indication) where it approaches, and through its presence within the intersection or an adjacent crosswalk where it is there; a road user that entered against its own red and is now within the intersection is yielded to as well.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "A car halts with its body 1 m short of the stop line of the rightmost lane c (ordinal 2 of 2), int.right_turn declared at i, the cross street undivided with lanes in both directions; it enters i under circular_red alone at 4 m/s while a car on the cross street, on a lane entering i governed by a head displaying circular_green, approaches from the left at 12 m/s, the closest approach of their centres 1.5 s ahead at 1 m."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The same right turn on red with no other road user in the scene: the duty binds the subject alone and is met."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The car halts in lane c and enters i only after s displays circular_green alone."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but lane ordinals and counts are not observed: whether the car is on the extreme right is unknown (c is on no one-way roadway, so the left branch is decided false).",
   "masked": [
    "st.lane_adjacency"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "As forbid, but the car halted 15 m short of the stop line behind a queue and rolled into i without halting at the place: the halt the words require did not occur and the duty of this paragraph does not arise."
  },
  {
   "name": "branch_2",
   "expected": "violated",
   "narrative": "A car halts at the stop line of the leftmost lane (ordinal 1) of a one-way roadway, int.left_turn declared at i, every lane of the cross street pointing to its left; it enters i under circular_red alone at 5 m/s while a pedestrian walking at 1.3 m/s in the crosswalk marking the entrance of a cross-street lane into i is closing on its path, the closest approach of their centres 1.2 s ahead at 0.7 m."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placement margin",
   "source": "proposed this iteration by LVMC_11_20_060_o1; repeated unchanged"
  },
  {
   "name": "p.lane_opposed_direction_cos",
   "unit": "ratio",
   "value": 0.9,
   "convention": "cosine of the largest angle (about twenty-five degrees) off exactly opposed at which the designated directions of two mapped lanes of one way count as opposite directions of travel: the direction noise of map lane segments along a gently curving way",
   "source": "map lane-direction tolerance, matching the catalogue's tolerance for opposed vehicle headings (p.oncoming_heading_cos)"
  },
  {
   "name": "p.cross_direction_sin_min",
   "unit": "ratio",
   "value": 0.5,
   "convention": "sine of the smallest angle (thirty degrees) by which a way's designated direction lies to one side of an approach's designated direction for that way's traffic to count as flowing to that side: the legs of a junction meet at larger angles, and map direction noise is far smaller",
   "source": "intersection design guidance limiting the skew of junction legs"
  },
  {
   "name": "p.conflict_horizon",
   "unit": "s",
   "value": 3.0,
   "convention": "time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present danger of a crash",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  },
  {
   "name": "p.conflict_centre_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are taken to collide or nearly collide: about a car's half-length plus half a body width",
   "source": "proposed this iteration by LVMC_11_12_070_B; repeated unchanged"
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {},
 "context": "e5998f0d1ff0428afc69b775"
}
```

It differs from the record planned in iteration 1 in: `context`, `intentions` (s10, s14), `planned_on`.

### Nodes of other laws these records compose

`NRS_484B_287_1c` (NRS-484B-287-1c) — its duty: “shall not cross at any place” (characters 157–185)

- state: not accepted; coded: gate WITNESS_FAIL (branch_2: expected not_applicable, got unknown for [window_truncated:since]); the record as coded in iteration 3
- applicability: The subject is a member of DEF-NRS-484A-165::pedestrian; neither LVMC_11_30_140_B_o1 nor LVMC_11_30_140_B_o2 applies to it (ruleApplies, subject mapped to subject); and at the observation it is between adjacent controlled intersections: its footprint overlaps a travel region c (rel.occupies) recorded as entering an intersection i1 (st.lane_enters), and an intersection i2 other than i1 is found either because its footprint also overlaps a travel region recorded as entering i2, or because c is a lane and a lane that enters i2 leads into c (st.lane_connectivity) directly or through one lane between; each of i1 and i2 has a device in operation — a dev.traffic_signal that is uncovered, whose state is not dark and that is not dev.inoperative — that governs it (dev.governs) or governs a travel region recorded as entering it; and its footprint overlaps neither i1 nor i2 nor a crosswalk recorded as marking the entrance of a carrier it occupies (st.entrance_of); and it is moving across c (drv.motion.moving_across_carrier(subject, c) with p.halt_speed_tolerance and p.crossing_motion_cos).
- obligation: At that observation the subject's footprint overlaps a crosswalk (st.crosswalk) whose marked attribute is true (rel.occupies). Otherwise violated; where the crosswalk's occupancy or its marking is unobserved, unknown.
- span `v1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `v1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below

`NRS_484B_287_1d` (NRS-484B-287-1d) — its duty: “shall not cross an intersection diagonally” (characters 68–110)

- state: accepted; the record as accepted
- applicability: The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian) whose footprint overlaps an intersection x (rel.occupies, st.intersection) into which at least one lane runs (st.lane_enters); the duty does not apply where LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2 is engaged for the subject.
- obligation: At each such observation: if the subject moves diagonally across x, that is, for every lane l with st.lane_enters(l, x), drv_motion_moving_across_carrier(subject, l) holds with parameters (p.halt_speed_tolerance, p.crossing_motion_cos) and does not hold with parameters (p.halt_speed_tolerance, p.right_angle_crossing_cos), then the subject's footprint overlaps a marked crosswalk (st.crosswalk with its marked attribute true). Otherwise compliant.
- span `s1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `s1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below

`NRS_484B_287_1e` (NRS-484B-287-1e) — its duty: “shall cross only in accordance with the official traffic-control devices pertaining to such crossing movements.” (characters 104–215)

- state: not accepted; coded: gate UNANCHORED_VARIABLE (in the formula, the quantified variable `d` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_re); the record as coded in iteration 3
- applicability: The subject is a pedestrian (ru.aggregate DEF-NRS-484A-165::pedestrian) beginning an authorized diagonal crossing: at this observation its footprint comes to overlap an intersection x (rel.occupies, st.intersection) that it did not overlap at the previous observation, its footprint overlaps a marked crosswalk (st.crosswalk, marked), and it moves diagonally across x: for every lane l with st.lane_enters(l, x) (at least one exists), drv_motion_moving_across_carrier(subject, l) holds with (p.halt_speed_tolerance, p.crossing_motion_cos) and does not hold with (p.halt_speed_tolerance, p.right_angle_crossing_cos). The duty does not apply where LVMC_11_30_140_B_o1 or LVMC_11_30_140_B_o2 is engaged for the subject.
- obligation: For every pedestrian signal head d (dev.pedestrian_signal) that the subject faces at this observation, d shows neither dont_walk_steady nor dont_walk_flashing without its countdown attribute. The subject faces d where, with Δ the vector from the subject's kin.position to d's dev.position and h the subject's kin.heading: h·Δ > 0, (h·Δ)² ≥ p.ped_signal_facing_cos² · (Δx² + Δy²), and Δx² + Δy² ≤ p.ped_signal_facing_reach². Where no head is faced, compliant.
- span `s1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o1` as exception: a node of another law, below
- span `s1` “Except as provided in NRS 484B.290 [LVMC-11-30-140-B]:” composes `LVMC_11_30_140_B_o2` as exception: a node of another law, below

`LVMC_11_30_060_A` (LVMC-11-30-060-A) — its duty: “shall yield” (characters 137–148)

- state: accepted; the record as accepted
- applicability: The subject is a member of DEF-NRS-484A-165::pedestrian; there is a roadway r such that: the subject occupies r, and (subject occupies r) since (the subject moves across a carrier it occupies: some lane k it occupies with drv.motion.moving_across_carrier(subject, k), or r itself with drv.motion.moving_across_carrier(subject, r); speed_tol p.halt_speed_tolerance, cos_max p.crossing_motion_cos) — the strong past since, holding at the judged observation where the subject moves across there, and where it moved across at an earlier observation and has occupied r at every observation since; and no dev.regulatory_sign of code pedestrians_prohibited governs (dev.governs) r. Further, at the judged observation the subject occupies no crosswalk (st.crosswalk).
- obligation: For every roadway r selected again with the applicability's whole selection (the subject occupies r, has occupied r since it moved across a carrier as stated there, and no pedestrians_prohibited regulatory sign governs r), and for every vehicle v (DEF-NRS-484A-320::vehicle) that occupies r: the subject is not in contact with v (rel.contact), and it is not the case that the subject is moving (kin.speed above p.halt_speed_tolerance) while the subject's and v's centres, under constant velocities, approach within p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance).
- composes no rule

`LVMC_11_30_060_B` (LVMC-11-30-060-B) — its duty: “shall yield” (characters 121–132)

- state: accepted; the record as accepted
- applicability: The subject is a member of DEF-NRS-484A-165::pedestrian; it occupies a roadway r and moves across a carrier k it occupies (drv.motion.moving_across_carrier with speed_tol p.halt_speed_tolerance and cos_max p.crossing_motion_cos); some pedestrian tunnel or overpass g (st.pedestrian_grade_separation) lies within p.grade_separation_reach of its body (st.region_geometry); and no dev.regulatory_sign of code pedestrians_prohibited governs (dev.governs) that roadway r.
- obligation: For every vehicle v (DEF-NRS-484A-320::vehicle) that occupies the roadway the subject occupies and crosses (re-bound with the same selection): the subject is not in contact with v (rel.contact), and it is not the case that the subject is moving (kin.speed above p.halt_speed_tolerance) while the subject's and v's centres, under constant velocities, approach within p.conflict_horizon (prim.closest_approach_within) to a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance).
- composes no rule

`LVMC_11_30_140_B_o1` (LVMC-11-30-140-B) — its duty: “come to a full stop” (characters 292–311)

- state: accepted; the record as accepted
- applicability: The subject is either a pedestrian (ru.aggregate=DEF-NRS-484A-165::pedestrian) that is not of the class ru.pedestrian_with_white_cane_or_guide_animal, or a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) read through its controlled motion; and at the judged observation, for some other road user b of the scene (not the same as the subject) of the class ru.pedestrian_with_white_cane_or_guide_animal, an approach or contact event occurs: rel.contact between the subject and b holds here and did not at the previous observation, or rel.centre_distance between them is at most p.blind_person_approach_reach here and was not at the previous observation while the subject is not at rest (not drv.motion.complete_halt with speed_tol p.halt_speed_tolerance).
- obligation: At each observation at which such an event occurs, the subject is at rest (drv.motion.complete_halt with speed_tol p.halt_speed_tolerance) at some observation of the window ahead of length p.immediate_stop_window, measured in time on the subject. No halt in that window is violated; a window that reaches past the end of the trace without a halt is unknown.
- composes no rule

`LVMC_11_30_140_B_o2` (LVMC-11-30-140-B) — its duty: “and take such precautions before proceeding” (characters 312–355)

- state: accepted; the record as accepted
- applicability: The subject is either a pedestrian (ru.aggregate=DEF-NRS-484A-165::pedestrian) that is not of the class ru.pedestrian_with_white_cane_or_guide_animal, or a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) read through its controlled motion; for some other road user b (not the same as the subject) of the class ru.pedestrian_with_white_cane_or_guide_animal, an approach or contact event (rel.contact beginning, or rel.centre_distance first falling to at most p.blind_person_approach_reach while the subject is not at rest) occurred at or before the judged observation; the subject has been at rest (drv.motion.complete_halt with speed_tol p.halt_speed_tolerance) at some observation since the latest such event; and at the judged observation the subject is not at rest (proceeding).
- obligation: At every such observation, for that b: the subject is not in contact with b (rel.contact), and it is not the case that the centres of the subject and b approach each other within p.conflict_horizon (prim.closest_approach_within) with a closest-approach distance (prim.closest_approach_distance, same horizon) below p.conflict_centre_clearance. Either contact or such a conflict course is violated. Surrogate: the verdict is evidence for the standard, not a legal conclusion.
- composes no rule

`LVMC_11_46_030_o1` (LVMC-11-46-030) — its duty: “to fail to stop not less than fifty feet from the nearest side of” (characters 110–175)

- state: accepted; the record as accepted
- applicability: The subject is a vehicle (ru.aggregate DEF-NRS-484A-320::vehicle). The duty arises at an event: at the judged observation t the subject comes within fifty feet of a crosswalk at which a warning is given. Bind a travel region g (kind st.travel_region) with rel.occupies(subject, g); a device d with dev.governs(d, g) that gives warning at t: a dev.crossing_warning_signal whose active attribute holds, or a dev.human_direction of any role whose indication is stop; a highway w (st.highway) with st.on_way(g, w); a crosswalk c (st.crosswalk) with st.on_way(c, w), ahead of the subject along g (prim.region_offset_along(subject, c, g) > 0), and the nearest such crosswalk ahead (no other crosswalk on w has a smaller positive offset along g). The event: st_region_geometry_distance(subject, c) is below the literal fifty feet at t and was at or above it at the observation before (rises of the distance being below fifty feet).
- obligation: Duty of rule 4c. Act: a halt of the subject (drv_motion_complete_halt(subject) with speed_tol p.halt_speed_tolerance) at an observation at which the body distance st_region_geometry_distance(subject, c) is at or above the literal fifty feet, c is ahead of the subject along a travel region it occupies that d governs, and d gives warning. Search: back from t through observations at which d gives warning continuously and c stays ahead of the subject along a travel region it occupies that d governs. The search ends at the onset of d's warning (the observation at which d's warning rose: a halt before the warning began is no halt for it), at the previous occurrence of the same event for the same subject and crosswalk (an earlier rise of 'within fifty feet of c'), or at an observation at which c is not ahead. Written: since(warning(d) and ahead(c) and not earlier-event, halt(subject) and distance(subject, c) >= fifty feet and warning(d) and ahead(c)). Where the search finds the halt, compliant; where it reaches the warning's onset, the previous event or an observation with c not ahead without the halt, violated; where it reaches the start of the recording with d warning and c ahead at every observation and no halt found, unknown. A missing distance, governance or direction makes the duty unknown only where the verdict turns on it.
- composes no rule

`LVMC_11_46_030_o2` (LVMC-11-46-030) — its duty: “and it is further declared unlawful to proceed” (characters 340–386)

- state: accepted; the record as accepted
- applicability: The subject is a vehicle (ru.aggregate DEF-NRS-484A-320::vehicle). At the judged observation bind, as in LVMC_11_46_030_o1, a travel region g with rel.occupies(subject, g), a device d with dev.governs(d, g) giving warning (dev.crossing_warning_signal active, or dev.human_direction of any role with indication stop), a highway w with st.on_way(g, w), and the nearest crosswalk c on w ahead of the subject along g (prim.region_offset_along(subject, c, g) > 0). The subject stopped for that warning and the warning has lasted since: since(warning(d) and ahead(c), drv_motion_complete_halt(subject) and st_region_geometry_distance(subject, c) >= the literal fifty feet and warning(d) and ahead(c)), with speed_tol p.halt_speed_tolerance. The duty ends ('until') at the first observation at which d gives no warning: the signal's active attribute is false or the signal is gone or no longer governs g ('stopped, raised, or been removed'); the person's indication is proceed ('a signal to go'), or the person is gone or no longer governs g ('has left the locality'); from then the since fails and the duty does not apply.
- obligation: The subject does not proceed: drv_motion_complete_halt(subject) holds at the judged observation, with speed_tol p.halt_speed_tolerance.
- composes no rule

`NRS_484B_307_8d` (NRS-484B-307-8d) — its duty: “(3) The person yields” (characters 670–691)

- state: not accepted; coded: gate BARE_LITERAL (formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading); the record as coded in iteration 3
- applicability: The subject is of one of the classes motorcycle, moped, bicycle, electric bicycle or electric scooter (admitted aggregates) or a ru.motorcycle (the trimobile). It approached intersection i through a travel region c whose entrance end is i (st.lane_enters) and which a traffic signal head s governs (dev.governs), and halted (drv.motion.complete_halt, p.halt_speed_tolerance) at the place of the stop on that approach: the stop line recorded as marking c's entrance, else the crosswalk recorded as marking it, else c's entrance end at i, with the zone (p.stop_point_tolerance) and the history bound NRS_484B_307_8a_o1 states. From the latest onset of that halt until its entry into i, s displayed a steady red alone (circular_red, no other state) at every observation and the subject's footprint did not overlap i; in that interval some traffic signal head governing a travel region that enters i began a green indication (circular_green or a green_arrow rising) at least two times (literal 2). The subject then entered i (its footprint came to overlap i, having occupied c at the observation before) while s still displayed the steady red alone, and its footprint has overlapped i at every observation since that entry, the judged one included. It is not the case that the passage through i begun at that entry is recognized at its exit (at the judged observation or a later one: the observation at which the subject's footprint ceases to overlap i) as a right turn (drv.motion.right_turn_through_region; step = p.heading_since_step_carla_scene_graph, turn_min = p.turn_heading_min, u_turn_min = p.u_turn_heading_min) while a regulatory sign coded no_right_turn governs c or i, nor as a left turn (drv.motion.left_turn_through_region) while one coded no_left_turn governs c or i; where no such sign governs, this condition holds whatever the movement, and where one governs and the exit is not recorded, it is unknown.
- obligation: For every road user p other than the subject that is of the class pedestrian or of the class traffic and is proceeding as directed by the signal at i — its speed above p.halt_speed_tolerance, and either its footprint overlaps i or a crosswalk recorded as marking the entrance of a travel region that enters i, or it occupies a travel region c' entering i governed by a head that displays circular_green or a green_arrow: it is not the case that the subject's speed is above p.halt_speed_tolerance while the closest approach of the two centres lies within p.conflict_horizon (prim.closest_approach_within) at a centre distance below p.conflict_centre_clearance (prim.closest_approach_distance); and the subject's body does not touch p's (rel.contact).
- span `s3` “the requirement to stop,” borrows from `NRS-484B-307-8a` the words “must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection” (as definition: no rule is composed)


(none)


## Hard rules

0. **Aggregates are admitted before you plan: claim them, never derive them.** The definitions
   table lists, per law, each defined term its words use, the definition that applies, the
   representation the run selected and, for a legal aggregate, its admitted id. A span whose words
   are such a term claims `ru.aggregate=<admitted id>`; a term marked `not_aggregate` or `gap`,
   or one no definition applies to, is mapped like any other words: existing atoms or concepts, or
   a gap. Where you find that a term the table does not mark as an aggregate names road users the
   duty turns on, claim `ru.aggregate=<definition id>::<term, words joined by underscores>`
   anyway and say why in `PLAN.md`: the harness asks the selection role once to reconsider and,
   if it keeps its decision, returns your plan without an attempt. A law-local aggregate exists
   only where the clause itself defines, adds or excludes members (for the purposes of this
   section a term means …; the road users this section covers are …; a clause that adds or excludes
   a class): write it in `aggregates.jsonl` (schema below), classifying every class of road users of
   the ontology with the law's own words, verbatim; an independent gate verifies it before any node
   may claim it. A use of an already defined word is never a law-local aggregate. A condition of
   the scene a definition or a clause states (where or when a road user is) is not membership: the
   rule carries it beside the aggregate.
0b. **Concepts are catalogued or proposed, never assumed.** A span that names a manoeuvre, a
   state of motion or a relation between road users over time maps to a concept: an entry of the
   catalogue when one denotes it, else a **concept record** you write in `blueprint.jsonl` beside
   the nodes. A configuration of the scene maps to a catalogued concept where one fits it, and
   otherwise may be written with atoms in the node's formula (the rule on singled-out regions below).
   A record has an id in the fixed grammar `drv.<family>.<name>` (the families are listed with
   the catalogue; a snake_case name for the observable notion, never a statute's word, a place or
   a figure), a `contract` in neutral words stating unit, frame and what is *not* denoted, typed
   `args` (`track`, `region`, `literal` with its admissible `values`, or `nat`), `params` (formal names with
   units and meanings — every magnitude the contract leaves open, never a value), `elements`
   mapping the contract's words to atoms and catalogued or co-proposed concepts with a quoted
   justification (a primitive's inputs are the primitive's: an element that maps to a primitive
   does not also claim the atoms the primitive reads, which the ontology lists with it, and the
   gate returns a claim no leaf of the body names), `residues`, three `scenarios` (`holds` → `compliant`, `fails` → `violated`,
   `blind` → `unknown` with `masked`), and `used_by`, the node ids of this plan that claim it.
   Two sources decide the contract:
   - a corpus **definition** that defines a manoeuvre, a state or a configuration (rather than a
     class of road users, which is an aggregate; an administrative region, which is an
     assumption; or a relation between parties' rights, which is a composition) gives a record
     with `definition: "DEF-…"` and a `contract` you write: it states the notion as a condition
     the atoms can observe, quotes the definition's deciding words verbatim in double quotation
     marks (at least three consecutive words), and names as a parameter every tolerance and
     window an absolute of the definition leaves to the observer — an absolute is observed over
     sampled measurements only within a bound the caller sets, and that bound is the contract's
     own magnitude, never a figure. Words of the
     definition the contract does not carry become the record's `residues`. Two definitions of
     one word are two records, told apart by a qualifier naming the physical difference;
   - a span with no definition gives a record whose contract you write, general enough for any
     law that needs the notion: the reviewer returns a contract tuned to one span.
   A contract states each moment in the formula language's terms: the observation itself; the
   observation at which a condition became true; every, or some, observation of a window behind or
   ahead; the last observation of a window at which something held; the time since a condition
   became true. A moment stated otherwise — the first observation of a window, a fixed time ago —
   has no operator. An event (entering, leaving, beginning) is the observation at which it became
   true, never a window that stays true after it. A contract states first, in words independent
   of how it is computed, what the concept denotes — the state, event, relation or quantity, as
   the atoms can observe it — and then the measurements and bounds that recognize or compute it.
   A one-sided bound is right only where values farther beyond it still denote the concept; where
   an overshoot stops denoting it, the contract states a band, or another condition that tells the
   overshoot apart. Every exclusion the contract names is one the concept needs and its elements
   tell apart: a boundary the concept needs is never dropped to fit the vocabulary — the concept
   is split or withdrawn, or the missing atom proposed as a gap — and an exclusion the concept
   does not need is not stated.
   A standard of judgement is never a concept, and no part of one is. A concept's parameters make
   an observable notion measurable — a tolerance below which a reading counts as none, the window
   over which a manoeuvre is recognized, the reach within which a region is the road user's own —
   and never decide how much is enough: a speed that is reasonable, a clearance that is safe, a
   distance that is near enough. Such a bound is the standard's, and it belongs to the rule's
   operationalization (rule 4), where it answers to the law; the concepts it calls
   compute the observable magnitudes the bound is compared with (a stopping distance, a time
   headway, a closest approach). The test: a concept answers the same for the same motion whatever
   law calls it; one whose answer would change with the standard of the law calling it carries a
   bound, and so does one that bundles several factors of one standard into one verdict. A reach
   relates a region to a road user; it never stands for a relation between two regions. For words
   that relate two regions, read the contracts of the relation atoms in the contracts table: where
   none of them relates the two, the span is an `atom` gap.

   A word a posted definition defines is read with that definition's inclusions and exclusions: the
   element's justification quotes, for each atom or concept it maps the word to, the definition's
   words that include it, and an exclusion that the contract of the atom or concept does not already
   make is carried by the rule as a condition beside it. The law's own words that qualify the word
   (in place, in operation, facing the road user, controlling a place) limit which of its members the
   duty reads: the justification quotes them and names the members they leave out.
   A defined place word keeps its definition's whole extent; a qualification the law's own words state
   narrows it explicitly; a narrower kind never stands in for the defined word without such words.

   A region the words single out ("the", "that", "such", "its") is one variable within one
   quantifier's scope, and every condition the words place on it there reads that variable. The
   applicability and the obligation are separate formulas: a region bound in one is not in scope in
   the other. Where the other must speak of the same region, it binds it again with the whole
   selection and every relation that fixed it, so that it again denotes the region the words single
   out; a shared variable name alone never makes two regions the same. The re-bound region keeps the quantifier the words give it: where the words require the duty at
   each region they select, the formula is written for every selected region; where they allow a
   choice among them, the choice is kept. Where the
   words speak of different regions, each keeps its own role and its own relations. A line, crossing or device *of*
   a region is tied to it by relation atoms, directly or through a chain of them (a marked line on the
   approach lane that runs into the junction); distance never stands for belonging, though a
   distance the words themselves require is read as the words state it.
   Where the words leave open which region is meant, the choice is disclosed as a reading; a reading
   never turns a region the words single out into any region of its kind.

   A condition the words fix to an event of this duty ("the signal at the moment it enters") is read
   at the observation at which that event occurred: through a past operator when the event lies
   before the judged observation, and directly when it is the judged observation. Every other
   condition is read at the moment the words give it; words of order ("after halting there")
   fix the order, not the moment of every later condition. An earlier occurrence of the same kind of
   event never stands for the one this duty refers to.

   A concept the catalogue already carries, or one a concept repair or an earlier batch of this iteration
   proposed (listed under the catalogue), is reused by its id and never re-proposed: a second record
   under the same id is dropped, and only the first contract reaches the coder.

   A region the words single out — the junction a road user enters, the stretch a posting governs,
   the line or crossing of an entrance — is the region every condition the words place on it reads,
   however that condition is carried. A catalogued concept fits it only if the concept takes that
   region as a `region` argument and checks its condition there: reuse it, passing the region the
   node binds. A concept that finds a region for itself, by a quantifier in its body, never stands
   for the one the words single out, even where the rest of its contract fits, since another region
   of the scene may satisfy it; it stays in the catalogue for words that single out no region. Where
   no catalogued concept fits, a condition of the scene may be written in the node's own formula on
   the region the node binds, read at the observation the words fix, or carried by a new concept
   that takes that region as a `region` argument; that other laws may use the same condition is a
   reason to propose one, not a requirement.

   A body that an accepted concept already computes is rejected by the gate. An accepted concept is never
   edited (one exception: a training repair transaction may correct a body of this run under its
   id, keeping its contract text word for word, its formals and its parameters, and the concept
   review passes it before it is committed): a body that contradicts its contract is superseded by a record `<name>_v<n+1>` with
   the **same contract**, `supersedes`, and a `counterexample` scenario on which the old body
   gives the wrong verdict; a version the catalogue lists as fenced is superseded the same way
   without a counterexample: its fence stands for it. A different contract is a new concept under
   a new name. In a `test`
   run nothing is superseded: report the defect under `## Concept defects` in `PLAN.md`.
1. **Segment first.** Cut the verbatim text into spans. Each span is a contiguous verbatim
   substring; the spans are disjoint and together cover the text (whitespace and punctuation
   excepted). Give each a role: `trigger`, `subject`, `obligation`, `exception`, `standard`,
   `condition`, `reference` (a bracketed id or the words that name another rule), `sibling` (a
   span that belongs to another node of the same law line — that node's obligation and the words
   only it needs; the other node segments the same words under a role of its own), `definitional`,
   `boilerplate` (text that only connects spans or introduces a list; words that permit, require
   or forbid anything are never boilerplate, nor `sibling`).
2. **Account for every substantive span** exactly once: an element (atoms, or concepts under `derived`),
   an operationalization (a standard), an assumption (a legal region class the ontology names as
   an assumption), a declared intention (below), a composition (another rule, see rule 5), or a
   residue (words the vocabulary cannot carry). A gap is not a carrier: it annotates a span that an element or an
   operationalization maps to its nearest atoms (step 6) only to show why they do not carry the span's distinction, never
   as the way the span is coded. A node that carries a gap is not coded, and its law stays blocked until a later record,
   validated, carries the span without that gap. Two exceptions to "exactly once": a `reference` span naming several
   rules carries one composition per rule; a `sibling` span carries nothing in this node.
   A residue is for words of the **obligation side** the rule does not capture. A `trigger`,
   `subject`, `condition` or `exception` span the vocabulary cannot carry is never left out:
   dropping it makes the rule apply where the law does not. Each way of carrying such a span has
   its own rule. An **assumption** (`asm.<name>`, with the meaning a trace must declare; an
   undeclared assumption leaves the verdict unknown) carries only a legal region class or a
   calendar or clock condition that the ontology's section on what is not an atom lists. A
   declared intention or an `observable_reading` carries such a span only where its own rule below
   allows it. A span that adds no restriction, the duty being the same whether or not its words
   hold, is a residue of scope `none` as stated below, whose `why` says why the duty is the same
   either way. Any other such span is mapped to its nearest atoms with a gap. The condition of a
   road user (disabled, or unable to be moved), a role or duty a person holds, an emergency, or what
   the law requires of the road user is never an assumption.
   Where the words state that a road user intends, or is preparing, to turn, the span is carried
   by a **declared intention** `{span, id, meaning}` in `intentions` (`int.<name>`), which the trace
   declares for that road user at a region (the formula `intent`, with the road user and the region
   as its arguments). It is carried only on a trigger, subject, condition or exception span; it is
   read at the judged observation or in a window behind it, never in a window ahead; its id names
   the manoeuvre only, never the place or the law, since the place is its argument. The words
   naming the place the intention is declared at are cut into a span of their own, carried by the
   element that claims the place's kind and its anchor, so that the intention's span carries only
   the words of the intention and its region is the region that element binds. The act the words
   also name ("is making …") is read by its manoeuvre concept, and the two are joined as the words
   join them. Such words are never carried by an act in a window ahead, nor by a signal; a signal
   "of intention" is the signal itself, not a declared intention. An assumption or an intention
   reuses an id of the declared-fact catalogue (listed with the parameters) whose meaning is the
   words' meaning, with no `meaning`; a new id gives its `meaning`, and never names again a meaning
   the catalogue holds. A meaning states the fact or state the source supplies; it never cites a
   law, explains a defined word of the law, or presets whether the law applies or a duty is met.
   Any other word with no observable counterpart is neither: an imminent movement, a
   perception or a knowledge, a purpose, the legal status of a feature in the scene, or who or what
   controls a road user's motion is read through the conduct or feature it refers to (an imminent
   movement, "about to …", by the movement itself; a duty to ascertain or make sure by
   the outcome it secures; a posted or official feature by its presence; "drives" and "operates", and
   the word for the one who does, by the road user's controlled motion, whether a person or an
   automated system is at the controls), as the ontology's section on what is not an atom
   says. The element maps the atoms or concepts of that conduct or feature, and the record declares
   the reading as a narrowing `{span, why, kind: "observable_reading", category}` with category
   `intention`, `perception`, `status`, `purpose` or `agency`, on the trigger, subject, condition, exception
   or obligation span it reads. It is only for these five kinds of word: a feature or a quantity
   the vocabulary lacks is still a gap. The one exception is a span that adds no restriction: the
   duty is the same whether or not its words hold. Carry it as a residue with `"scope": "none"`
   and say why; the record is held to that. A span that restricts the duty through a word with no
   observable counterpart is no such residue: it takes the declared reading above, or it is a gap. A reading you choose on a span you do carry, where the words
   leave it open and the atoms state it more narrowly, is a **narrowing** `{span, why}` on an
   obligation or standard span; the rule is held to it, and a narrowing that drops what the words
   require is a defect.
3. **Map by contract, and quote it.** An element's justification quotes the clause of the atom's
   contract that denotes the span and says why each "not a stand-in for" exclusion does not
   apply. If no contract denotes the span, the span is a **gap** with a proposal and the nearest
   atoms named — never an approximation by a neighbouring atom. Two consequences:
   - **An aggregate is one atom.** An admitted aggregate, and a law-local one your
     `aggregates.jsonl` writes, is claimed as `ru.aggregate=<id>` — in `class_elements` and in
     the span's element alike. Never expand an aggregate into the classes it covers. A class named
     on its own uses its class atom only as rule 0 permits; an admitted aggregate is never
     replaced by a class atom, even when it contains only one class.
   - **A duty covers its domain.** An obligation's elements decide the duty wherever its words
     apply. An atom or a concept that is decided only inside a narrower domain than the words name
     (a place, a class of road user or a state the words do not require) leaves the duty unjudged
     elsewhere: cover the rest of the domain with another element or concept, or propose a gap.
     Unknown is for observations a source may lack and for the limits of a finite trace, not for a
     part of the domain no element reads.
   - **A distance window claims what it measures.** A span whose window the words measure in
     distance travelled (a `.path` window) claims, on the element it serves, the ontology's atom for
     the distance a body has travelled along its path: the window reads it, as a `.time` window
     reads the clock.
   - **A feature the subject is on is anchored, and named.** A span that places the subject on,
     at or under a feature of the scene claims both the feature's own kind atom (a structure atom
     or a device atom: the kind the relation's argument ranges over, which the rule reads when it
     quantifies over that kind) and an anchoring relation — `rel.occupies` (a road user's footprint overlaps a lane / region) or `st.region_geometry` (the reference point and the boundary polygon of a structure region in the world frame) — so that the rule reads the
     subject's own feature and not any feature of the scene. A relation claimed without the kind
     it ranges over leaves the coder a quantifier it cannot type, and the gate returns the rule
     for an unclaimed atom. A region quantifier names a kind: claim the kind of every region a
     claimed relation reads, for each of its region arguments a kind whose regions that argument
     admits. The validator returns a node that claims a feature and no anchor, and one that
     claims no such kind for a region argument, naming the kinds it admits.
   - **A feature named without a measure is its presence.** A trigger, condition or subject span
     that names a feature and no size of it (any bend, any slope) is carried by the feature
     itself: where its atom is a magnitude, by the magnitude standing clear of zero, with a
     parameter that names only the source's resolution. A size bound the words do not state
     narrows where the duty applies, which a trigger, condition or subject span never is.
4. **Every standard is operationalized**, by one operationalization per `standard` span, whose
   `concepts` list the atoms, primitives and concepts that bound it (one entry per standard,
   however many atoms and concepts bound it together), with named parameters and
   the engineering convention the values come from. If the standard is the whole obligation, or
   it is a standard about the road user's state of mind, mark the node `surrogate`. Each factor
   the standard names in its own words is read by the operationalization wherever a contract
   carries it; reading it more narrowly than its words is a narrowing, and a named factor no
   contract carries at all is a narrowing that says so (the aspects of a named factor the
   operationalization reads through a carried contract are part of that narrower reading and are
   not listed one by one). A catch-all of the standard (words that cover further factors without
   naming them) gets an explicit reading too: the operationalization names the contracts it reads
   for the catch-all, and a narrowing on the span discloses that the catch-all is read only
   through them. A factor is read by the degree to which it holds: a measured
   magnitude enters the bound itself, so the bound moves as the magnitude moves, and a condition
   selects among bounds. A switch that applies one fixed bound whenever any factor holds reads no
   factor's degree and holds mild and severe conditions to one bound; reading a factor's degree is
   the reading of the words, not a model of how the duty is performed.
4b. **The occasion of an act.** An obligation span mapped to a concept observed over a stretch of
   time (one whose record declares the act, `act`: a manoeuvre recognized only once it has been
   carried out; neither a parameter in a unit of time nor a temporal operator makes a concept an
   act) is judged where the act is recognized, which is after it began. The act is the
   observation at which its concept rises, and the later observations at which it still holds are
   not the act again. The contract states how long the act concept holds after recognition and
   what ends it; do not infer an event act's extent from a window. A span placed in time relative to
   an act is read relative to the boundary required by the words or an explicitly approved reading,
   not automatically from the concept's rise. Distinguish the conduct's onset from its recognition.
   A rise of a windowed or accumulated condition does not by itself establish the conduct's onset.
   State which boundary the span uses and what observation supports it. Where the required boundary
   cannot be expressed, report an operator gap. Each trigger,
   condition and exception span the node maps is then read at an occasion of the act you declare
   in `occasion`: `at_recognition` (where the act is recognized), `some_moment` (at some moment
   while the act is under way) or `throughout` (at every moment while it is under way). The
   words decide; where they say nothing of time, a trigger or condition is read at `some_moment`,
   since reading one instant drops situations the words cover, and an exception `throughout`, so
   that it excuses only an act it covers whole. Reading a trigger or condition only
   `at_recognition` where the words do not place it there narrows where the rule applies, and the
   rule is held to that like any narrowed trigger or condition, whichever span the record
   discloses it on. Where the obligation span names alternative acts, `act` lists their concepts,
   and they share one occasion: the boundary, `under_way` and the scenarios. `boundary` is the
   boundary the acts' records declare: `window`, where `window` names the act's window parameter;
   or `event`, for an act no window of fixed length bounds, where `onset` is an element
   `{words, atoms, derived, justification}` mapping what marks
   the act's observed beginning, claimed and coded like any element, and `recognition` the words
   saying where the act is recognized. A window is never named only to fill the field. Where the
   formula language cannot write the boundary, `gap` names the span of the record's `operator` gap
   that states it. Where a span is read while the act is under way, `under_way` is an
   element `{words, atoms, derived, justification}` saying what tells an observation inside the
   act from one before it began: it reads the road user's motion (a kinematic atom such as the
   heading's rate of change, a primitive, or a concept that reads one) and never a place or a
   region alone, since the road user occupied the same region before the act began; its atoms are claimed and
   coded like any element. Spans the rule joins by "and" are read at one and the same moment of the
   act. Each span read while the act is under way has two scenarios with different verdicts:
   `occasion_<span>`, in which it holds for part of the act only, and `occasion_<span>_outside`, in
   which it holds only before the act began (`some_moment`) or throughout the act but not before it
   (`throughout`). An occasion the formula language cannot state is an `operator` gap.
4c. **A duty whose act is searched for in the past.** Where an obligation requires an act before an
   event the words name, and the words fix no occurrence, timing or exception of their own, the
   record's `obligation` states, from the words and from the convention the ontology's section on
   what is not an atom gives for that kind of duty, the trigger, the place of the act and the
   history bound. State the event and target bindings, the conditions that end the search and how
   their observations are read, the parameter references, and when missing evidence prevents a
   decision, so the coder can implement the bound without choosing a reading. Do not invent a
   history boundary from the recording's start, a subject's first observation, or a cumulative
   quantity whose origin is the recording's start. Preserve any event, time or distance window the
   words explicitly require. Words that fix their own occurrence, timing or exception are written
   with their own window. A concept that carries the search states the same bound in its contract.
   For such a duty the record plans one scenario `history_boundary` beside the four standard ones: a
   trace in which the duty arises, the history the bound needs begins before the recording, the act
   is not recorded, and no recorded act or visible end of the search decides the verdict; it expects
   `unknown`, and its `boundary` names the history the trace lacks. A boundary only names missing
   history; it never turns a verdict the trace decides into unknown.
4d. **Event-relative history.** When the words relate a condition or a prior act to an event, state
    the event, its recognition point and the relevant history boundary in the record and any concept
    contract. Use an observed onset where it is the boundary the words or the disclosed reading
    require. Do not use a sliding recognition window as the act's beginning, or discard evidence
    before the act begins when the words require prior conduct. Retain a fixed time or distance
    bound where the law requires it, or where a justified, parameterized observation or recognition
    bound is needed; state its purpose and follow the reading approval rules. Never derive a bound
    or an event onset from a recording's length, endpoints or identifier. Missing required history
    leaves the dependent quantity or condition unknown; other branches may still decide the verdict.
    If the formula language cannot express the required boundary, report an operator gap rather than
    change the meaning.
5. **One node per obligation span, and nothing below it.** Two obligations in one line are two
   nodes, `…_o1` and `…_o2`, each segmenting the whole line; in each, the other's obligation span
   and the words only the other needs carry the role `sibling`. An exception or a condition that
   names another rule is a composition: `as: exception` — the duty does not apply where that rule
   applies (its binders' classes and applicability hold); `as: condition` — the duty applies where
   that rule applies; `as: compliance` — the other rule's verdict is complied with ("lawfully",
   "in the manner prescribed by"); `as: unless` — on a `reference` span, it suspends one
   exception or condition span of this node where the other rule applies ("except as otherwise
   provided in …" read on the words it qualifies): `scopes` names that span, whose content then
   does not hold where the composed rule applies, and the duty as a whole is untouched. A
   condition that refers to an act, state, party or place stated elsewhere carries that referent
   with every qualification the referring words retain: its subject, object, place, event, time,
   order and logical force. A weaker fact is no substitute, and marking the defining words
   `sibling` does not erase the condition. It composes the rule stating the act only where the
   words require compliance with that rule, since a composed rule counts as complied with where it
   is not engaged, and neither that nor its acceptance shows that the act occurred; where they
   require the act or state itself, a suitable concept or the qualified fact in full carries it.
   That the node stating it is not yet coded is no reason to weaken it. A
   reference to a law of this corpus is a composition, never a residue; a reference to a
   law outside the corpus may be a residue. A reference that only borrows the words another text
   of the corpus defines or sets forth, needing none of its rules to apply, hold or be complied
   with, is a `definition` reference instead: it names that source and quotes the borrowed words,
   composes no rule and waits on nothing, and each element whose words use them carries their
   meaning with its own atoms, every qualification the quoted words keep, naming the reference
   span in `source_spans`. A `standard` span whose bound an accepted rule of the
   library already states as its own obligation is carried by composing that rule (`as:
   compliance`), not by an operationalization that restates it. The composed rule's every binder is mapped to one of this
   node's binders or to a road user the coding agent will quantify over. `rule` names the **node**
   (`NRS_…`, underscores; `…_o2` for the second obligation of a line), never the law id. A rule
   not in the corpus is a residue. A node never spans two law lines, and a condition, standard or exception is
   never split into a node of its own. When a span does not ground in the ontology, the answer is
   a gap or a residue, never a further decomposition.
6. **The node id is derived, not chosen.** It is the law id with `-` replaced by `_`; a line with
   several obligation spans numbers its nodes `_o1`, `_o2`, … in text order.
7. **Same words, same atoms, where they mean the same.** If the mapping index maps a span's
   words, reuse that mapping where the words mean the same in your law; map them differently,
   saying why in `PLAN.md`, where your law's words need it.
8. **Parameters come from the catalogue.** Name parameters from the catalogue; never state a
   value. Every operationalization names at least one parameter: a standard is a bound the
   reading sets, and a standard rendered as a structural fact with no magnitude behind it (the
   presence of a feature standing in for an adequacy the span leaves open) is an approximation by
   a neighbouring atom, which the validator returns. A parameter the catalogue lacks is
   named (`p.<name>`) and **proposed** in the node's `param_proposals`: its unit, a provisional
   `value` taken from the named engineering `convention` (what the value bounds and how), and the
   `source` such figures come from. A value the catalogue marks proposed by a node of this
   law, not yet reviewed, may be proposed again with another value, never to change a verdict on a
   labelled recording; any other catalogued value is named as it is. The harness enters the proposal in the reading as a value
   awaiting the operator's review, so the node is coded and gated at once; the operator may change
   the value later, and the rule, which names the parameter and never carries the value, is
   unaffected. Choose the least committal parameters the words require: one tolerance where one
   suffices, and no model of how the duty is performed. A figure the law itself states ("a stated distance,
   speed or time") is not a parameter: declare it in `literals` on its span, with the number and
   its unit as the text gives it — `ft`, `in`, `mi`, `mph`, `s`, `min`, `h`, `deg`, or `count`
   for a number of things — and the rule carries it as a literal.
9. **Four scenarios**, in atom vocabulary, with `expected` spelled exactly: `forbid` → `violated`,
   `permit` → `compliant`, `idle` → `not_applicable`, `blind` → `unknown` (with `masked`: the
   atom whose absence makes the rule unknown — one the node claims, or one its claimed concepts
   read). Where the duty or the exception has alternatives the four do not visit, you may add
   `branch_<n>` scenarios expecting `violated` or `compliant`, or `not_applicable` for a situation
   the words exclude from the duty; the coder adds further branch witnesses itself until every leaf
   of the rule is exercised. Where a weaker fact than a referred one would change the law's
   verdict, two scenarios differ only in it, each verdict taken from the words; an existing
   scenario may be one of them. Where the rule quantifies over
   parties other than its binders, one scenario has no such party in the scene and still
   expects a decided verdict, so the duty is shown to bind the subject alone.
10. **No Lean, no code, no library edits.** You write `aggregates.jsonl`, `blueprint.jsonl` and
    `PLAN.md` only — by hand, with the Write tool, as the files
    themselves. You do not write programs that generate them, and you do not write your own
    checker: the harness's validator is given to you below, and it is the only command the shell
    runs; any other command is denied. Everything you may know is in this prompt: you read no
    file.
11. **A returned law is fixed, not re-read.** Address the returned reason, and keep every mapping
    the reason does not concern and the words do not show wrong. An obligation span that only a
    residue can carry means the duty is not expressible: say so in `PLAN.md` and do not weaken it.
11b. **A label mismatch is evidence of meaning, not a target.** Each shows how a label reads the
    law's words on a scene of its kind; answer it with a reading of the words that decides every
    scene of that kind the same way, and meet the repair goal the evidence states without losing a
    match. No condition singles out a recording, a scene, a source or a law, and no rule reads which
    road user a label judges: the check applies the label contract itself. A law planned again
    inside a repair transaction needs a new cut of its text: write the new segmentation and every
    node of the law in full. A cause outside the records (Core, the ontology, a trace that
    misreports the scene, a label, a parameter's value) goes under `## For the operator`, and the
    words are planned as they read.
12. **Decide.** No options menus, no "awaiting", no questions. Record each decision with the
    cheapest signal that would reverse it.

## Procedure

For each law in the list:

1. Read the text and the definitions it cites. Segment (rule 1).
2. For each substantive span, find the atom, primitive or concept whose contract denotes it; write the
   justification (rule 3). Where a span's words are in the mapping index, reuse (rule 6).
3. Operationalize the `standard` spans (rule 4). Decide `surrogate`.
4. Decide the nodes (rules 5 and 6): binders (the subject first, its class from the subject/trigger
   spans), applicability (trigger and condition spans, in plain words), obligation (obligation
   spans, in plain words). A further binder is only a party without whom the duty does not exist.
   A road user the duty refers to only when one is present (one ahead, one approaching, one
   nearby) is quantified inside the applicability or the obligation, never a binder: a rule is
   judged on every grounding of its binders, so a binder no scene supplies leaves the subject's
   duty unjudged exactly when the subject is alone.
5. Plan the four scenarios (rule 9), and the `history_boundary` scenario for a duty of rule 4c.
   The `blind` scenario names the claimed atom whose absence must make the rule report unknown.
6. If any span is a gap, complete the gap record (span, kind `atom` or `operator`, proposal in the
   ontology's row format or the operator, nearest atoms with the excluding clause), and map the span
   to those nearest atoms or concepts only so that every span is accounted for: they show why the
   vocabulary falls short, never how the span is coded. A node that carries a gap is not coded: its
   gaps are filed when it is registered, and its law stays blocked until a later record, validated,
   carries the span without that gap. Propose a gap only where no atom, concept or allowed reading
   carries the words.

Then write `PLAN.md`: one paragraph per node (decision, reason, reversal signal; for a condition
that refers to words stated elsewhere, the referring and the defining spans, and, for a law planned
again, why their representation or the qualifications kept changed), and `## For the operator`.

## Output

`blueprint.jsonl` — one JSON object per node, this schema and nothing more:

```
node_id, law_refs, subject{binder, class_elements}, segmentation[{id, text, role}],
elements[{span, atoms, derived, justification, source_spans (only on an element whose words are borrowed: the `definition` reference spans they come from, each one's quote repeated in the justification)}], operationalizations[{span, standard, concepts,
params, convention, surrogate}], assumptions[{span, id, meaning}], intentions[{span, id, meaning}],
compositions[{span, rule, map, as: "exception" | "condition" | "compliance" | "unless", scopes (unless only: the exception or condition span suspended)} | {span (a `reference` span), as: "definition", source (the id of the law or posted definition the words are borrowed from), quote (the borrowed words, verbatim from it)}], residues[{span, why, scope ("none" only, and only on a trigger/subject/condition/exception span that imposes no observable condition)}],
binders[{name, class_elements}], applicability, obligation, params, narrowings[{span, why, kind ("reading", the default, or "observable_reading" with `category`: "intention" | "perception" | "status" | "purpose" | "agency"), gap (a rejected gap id of this law whose decision this reading follows, where the gap table shows one)}],
scenarios[{name: "forbid" | "permit" | "idle" | "blind" | "branch_<n>" | "occasion_<span>" | "occasion_<span>_outside" | "history_boundary", expected: "violated" | "compliant" | "not_applicable" | "unknown", narrative, masked: ["<atom id>", …] (blind only, a list), boundary (history_boundary only: the approach its trace lacks)}],
occasion{act (a concept id, or a list of them for alternative acts), boundary: "window" | "event" (absent: "window"), window (boundary "window"), onset{words, atoms, derived, justification} (boundary "event"), recognition (boundary "event"), gap (boundary "event", only where the formula language cannot write it: the span of an `operator` gap), under_way{words, atoms, derived, justification}, spans{"<span id>": "at_recognition" | "some_moment" | "throughout"}} (rule 4b only),
literals[{span, text, value, unit}], param_proposals[{name, unit, value, convention, source}],
gaps[{span, kind: "atom" | "operator", proposal, nearest}],
gap_resolutions[{gap, span, basis}]
```

A gap has two kinds and no other: `atom`, when no atom and no enumeration value of the ontology
carries the span (the proposal is the ontology row that would, starting with its new id), and
`operator`, when the formula language cannot express it (the proposal is the operator, starting
with its new name). An atom gap never proposes an atom the ontology has, and an operator gap never
proposes what the formula language already writes. A gap a node carries is filed when the node is
registered, and blocks its law until a later record, validated, carries the span without that gap;
the coding session does not write that node. Where a record carries no gap on a span and the coding
session cannot write the span with the atoms and operators you map it to, it declares the span
unstatable and the node goes to its repair session, which re-maps the span or withdraws it as a
gap; a second such declaration on the same words files the gap. Nothing else is a gap.
A gap the operator has retired or rejected is answered by a record that carries its words without
it. Such a record names, in `gap_resolutions`, each such gap: its id, the span that now carries the
words, and the basis of the new representation (the atom or revision that retired it, or the
reading the rejection allows). A record that leaves out the gap of an earlier record on the same
words of the law, without naming a gap the operator has decided, is returned.
A gap's proposal names the distinction of the driving task the missing atom or operator would
decide: the action the law requires or forbids, where it is required, its time or order, the
road users it concerns, or whether a plan can be carried out. That a word has no atom of its own is
never, by itself, a reason for a gap; a word a convention of the ontology's section on what is not
an atom reads is no gap.

Concept records, in the same file, one JSON object per concept, this schema and nothing more:

```
concept_id, kind: "formula" | "quantity", contract, definition ("DEF-…" or null),
args[{name, sort: "track" | "region" | "literal" | "nat", values (literal only)}], params[{name, unit, meaning}],
act{boundary: "window" | "event", window (window only: the formal parameter in a unit of time that bounds the act), onset, recognition, extent, history} (a concept that recognizes an act over a stretch of time, and only such a concept: the words of the contract, verbatim, stating the act's observed beginning, its point of recognition, its extent, and the history boundary for conduct before it),
elements[{span (words of the contract), atoms, concepts, justification}], residues[{span, why}],
literals[{value, unit, why}] (a geometric constant or a figure the definition states),
scenarios[{name: "holds" | "fails" | "blind", expected, narrative, masked (blind only, a list)}],
used_by[<node ids>], supersedes (an accepted id or null), counterexample{narrative, expected} (supersession only),
differs_from{concept, why} (when the sorts and atoms match an accepted concept's)
```

`aggregates.jsonl` — law-local aggregates only, one record per line (rule 0); empty when none:

```
aggregate_id: "<law id>:<span id>::<term>", term, definition: null,
classifications[{class: "<class id>", status: "included" | "excluded" | "covered" | "unresolved",
                 quotes[{definition: "<law id>", words: "<verbatim words of the law>"}], reason,
                 covered_by[<class ids>], basis[{class, words}]}]
```

A covered class is one the law's words admit only as members of classes the record includes:
`covered_by` names them (each `included`, never the class itself), `basis` quotes verbatim the
class contracts that make the coverage complete, and `reason` says why; only a covered class
carries `covered_by` and `basis`. `excluded` means the words leave the class out.

## Self-check before you finish

Run the validator on the finished file and fix what it names; then confirm by reading:

- every aggregate a node claims is admitted in the definitions table, or is a law-local record of
  `aggregates.jsonl` that classifies every class of road users with the law's own words;
- every span text is a verbatim substring of its law, spans disjoint, union complete;
- every non-boilerplate span appears in exactly one of elements / operationalizations /
  assumptions / intentions / compositions / residues, and a gap's span in an element or an operationalization;
- every atom, value and concept id you wrote exists in the ontology or the catalogue, or is a
  concept record of this plan;
  every node that reads a feature claims an anchor;
- every concept record has a well-formed id, a contract, typed formals, parameters with units,
  elements over the contract's words, the three scenarios, and `used_by` naming nodes that claim
  it; a definition-born contract quotes the definition's words and names its tolerances as parameters;
- every `standard` span has an operationalization;
- a node whose obligation is an act observed over time declares `occasion`, with its boundary,
  for every trigger, condition and exception span it maps, an `under_way` that reads the road user's motion, and the
  `occasion_<span>` and `occasion_<span>_outside` scenarios for each span read
  while the act is under way;
- every node id is the derivation of rule 6 from its law id, with the ordinal counted over the
  obligations the law's nodes carry, in text order;
- every composition's `rule` is a node id, except a `definition` reference's, which has none and is
  named in the `source_spans` of the elements that carry its words; every `masked` is a list;
- every node has the four scenarios; the `blind` one masks a claimed atom;
- a node of rule 4c states its trigger, place and history bound in full in `obligation`, and plans
  the `history_boundary` scenario with its `boundary` where the missing past decides the verdict;
- no value or threshold appears anywhere in your output except inside `literals`, quoted from the text.

## Finish

Finish when `aggregates.jsonl`, `blueprint.jsonl` and `PLAN.md` are written and the self-check
passes. Do not write a "next steps" section that waits on anyone.


## Where to write

Working directory: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-004/plan/batch-02`. Write `aggregates.jsonl`, `blueprint.jsonl` and `PLAN.md` there with the Write tool, as files, by hand. Everything you need is in this prompt: you read no other file, and the shell runs exactly one command, the validator below — any other command is denied.

## Checking a draft

The deterministic validator the harness will run, with the run's accepted nodes, concepts, mapping index, reading and your `aggregates.jsonl`, is available to you on a draft:

```
python -m harness validate --run_id full221-1116-1018 --blueprint_file /scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-004/plan/batch-02/blueprint.jsonl
```

Run it exactly as written. It prints one line per node (`accept`, `return`, `fail`) with the reasons. Run it once the file is complete, fix what it names, and stop when every node is `accept`. It is the only program you run; the self-check is yours, the schema check is its.
