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

### `NRS-484B-250-1` — Vehicle approaching or entering intersection (1)
_NRS 484B.250(1); with 484B.250(5)_

The driver of a vehicle approaching an intersection shall yield the right-of-way to a vehicle which has entered the intersection from a different highway. Except as otherwise provided in subsection 4 [NRS-484B-250-4], this section does not apply at intersections controlled by official traffic-control devices or to vehicles approaching each other from opposite directions, when the driver of one of the vehicles is intending to or is making a left turn.

### `NRS-484B-253` — Vehicle turning left
_NRS 484B.253_

The driver of a vehicle within an intersection intending to turn to the left shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection or so close thereto as to constitute an immediate hazard, but such driver, having so yielded and having given a signal when and as required, may make such left turn and the drivers of all other vehicles approaching the intersection from the opposite direction shall yield the right-of-way to the vehicle making the left turn.

### `NRS-484B-257-1` — Vehicle entering intersection marked stop or yield (1)
_NRS 484B.257(1)_

Except when traffic is being controlled by a police officer or a traffic-control signal: When proper signs have been erected, the driver of a vehicle shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. After having stopped or, in the event of a yield sign, slowed or stopped, the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

### `NRS-484B-307-9b` — Traffic controlled by official traffic-control devices (9)(b)
_NRS 484B.307(9)(b)_

Where the signal is a steady red with a green turn arrow: A person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter facing the signal may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if: (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter; (3) No other device at the place prohibits the turn, if applicable; and (4) The person yields the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

### `NRS-484B-307-9a` — Traffic controlled by official traffic-control devices (9)(a)
_NRS 484B.307(9)(a)_

Where the signal is a steady red with a green turn arrow: Except as otherwise provided in paragraph (b) [NRS-484B-307-9b], vehicular traffic facing the signal may enter the intersection only to make the movement indicated by the green turn arrow, but must yield the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection. Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

### The defined terms of these laws (read-only: resolved by the operator's declared precedence; aggregates selected and admitted by the run)

| law | term | applicable definition | representation | aggregate id (admitted) |
|---|---|---|---|---|
| NRS-484B-250-1 | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-250-1 | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-250-1 | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-250-1 | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-250-1 | highway | `DEF-NRS-484A-095` | not_aggregate |  |
| NRS-484B-250-1 | official traffic-control device | `DEF-NRS-484A-145` | not_aggregate |  |
| NRS-484B-253 | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-253 | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-253 | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-253 | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-257-1 | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-257-1 | police officer | `DEF-NRS-484A-180` | not_aggregate |  |
| NRS-484B-257-1 | traffic-control signal | `DEF-NRS-484A-290` | not_aggregate |  |
| NRS-484B-257-1 | driver | `DEF-NRS-484A-080` | not_aggregate |  |
| NRS-484B-257-1 | vehicle | `DEF-NRS-484A-320` | aggregate | `DEF-NRS-484A-320::vehicle` |
| NRS-484B-257-1 | stop | ambiguous: `DEF-NRS-484A-255`, `DEF-NRS-484A-260` (each states its own scope) | — | |
| NRS-484B-257-1 | crosswalk | `DEF-NRS-484A-065` | not_aggregate |  |
| NRS-484B-257-1 | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-257-1 | through highway | `DEF-NRS-484A-275` | not_aggregate |  |
| NRS-484B-257-1 | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-307-9b | motorcycle | `DEF-NRS-484A-135` | aggregate | `DEF-NRS-484A-135::motorcycle` |
| NRS-484B-307-9b | moped | `DEF-NRS-484A-125` | aggregate | `DEF-NRS-484A-125::moped` |
| NRS-484B-307-9b | trimobile | none applies | — | |
| NRS-484B-307-9b | bicycle | `DEF-NRS-484A-025` | aggregate | `DEF-NRS-484A-025::bicycle` |
| NRS-484B-307-9b | electric bicycle | `DEF-NRS-484B-017` | aggregate | `DEF-NRS-484B-017::electric_bicycle` |
| NRS-484B-307-9b | electric scooter | `DEF-NRS-484B-018` | aggregate | `DEF-NRS-484B-018::electric_scooter` |
| NRS-484B-307-9b | stop | ambiguous: `DEF-NRS-484A-255`, `DEF-NRS-484A-260` (each states its own scope) | — | |
| NRS-484B-307-9b | crosswalk | `DEF-NRS-484A-065` | not_aggregate |  |
| NRS-484B-307-9b | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-307-9b | official traffic-control device | `DEF-NRS-484A-145` | not_aggregate |  |
| NRS-484B-307-9b | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-307-9b | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-307-9b | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-307-9a | traffic | `DEF-NRS-484A-285` | aggregate | `DEF-NRS-484A-285::traffic` |
| NRS-484B-307-9a | intersection | `DEF-NRS-484A-105` | not_aggregate |  |
| NRS-484B-307-9a | right-of-way | `DEF-NRS-484A-210` | not_aggregate |  |
| NRS-484B-307-9a | pedestrian | `DEF-NRS-484A-165` | aggregate | `DEF-NRS-484A-165::pedestrian` |
| NRS-484B-307-9a | crosswalk | `DEF-NRS-484A-065` | not_aggregate |  |
| NRS-484B-307-9a | driver | `DEF-NRS-484A-080` | not_aggregate |  |

### The definitions that apply

### `DEF-NRS-484A-080` — Driver defined
_NRS 484A.080_

(1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030, and the automated driving system, as defined in NRS 482A.025, of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036, and the automated driving system, as defined in NRS 482A.025, of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.

### `DEF-NRS-484A-320` — Vehicle defined
_NRS 484A.320_

“Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029; and (4) An electric scooter.

### `DEF-NRS-484A-095` — Highway defined
_NRS 484A.095_

“Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.

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

“Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029.

### `DEF-NRS-484A-081` — Electric bicycle defined
_NRS 484A.081_

“Electric bicycle” has the meaning ascribed to it in NRS 484B.017.

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

### `DEF-NRS-484A-150` — Owner defined
_NRS 484A.150_

“Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.

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

### `DEF-NRS-484A-210` — Right-of-way defined
_NRS 484A.210_

“Right-of-way” means the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other.

### `DEF-NRS-484A-145` — Official traffic-control device defined
_NRS 484A.145_

“Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.

### `DEF-NRS-484A-200` — Railroad defined
_NRS 484A.200_

“Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.

### `DEF-NRS-484A-180` — Police officer defined
_NRS 484A.180_

“Police officer” means every officer authorized to direct or regulate traffic or to make arrests for violations of traffic laws, ordinances or regulations.

### `DEF-NRS-484A-290` — Traffic-control signal defined
_NRS 484A.290_

“Traffic-control signal” means any official traffic-control device, whether manually, electrically or mechanically operated, placed or erected by a public authority or railroad, by which traffic is alternately directed to stop or proceed.

### `DEF-NRS-484A-255` — Stop defined
_NRS 484A.255_

“Stop,” when required, means complete cessation from movement.

### `DEF-NRS-484A-260` — Stop / stopping defined
_NRS 484A.260_

“Stop” or “stopping” means, when prohibited, any halting, even momentarily, of a vehicle, whether occupied or not, except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device.

### `DEF-NRS-484A-065` — Crosswalk defined
_NRS 484A.065_

“Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.

### `DEF-NRS-484A-240` — Sidewalk defined
_NRS 484A.240_

“Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.

### `DEF-NRS-484A-275` — Through highway defined
_NRS 484A.275_

“Through highway” means every highway or portion thereof on which vehicular traffic is given the right-of-way, and at the entrances to which vehicular traffic from intersecting highways is required by law to yield right-of-way to vehicles on such through highway in obedience to either an authorized stop sign or a yield sign, or other official traffic-control device.

### `DEF-NRS-484A-135` — Motorcycle defined
_NRS 484A.135_

“Motorcycle” means every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground, excluding an electric bicycle, a tractor or a moped.

### `DEF-NRS-484A-130` — Motor vehicle defined
_NRS 484A.130_

“Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.
### Texts these words name (posted text the harness took from the corpus, whole, with the definitions that apply to it: a `definition` reference quotes the words it borrows from here; their own duties are not planned here)

#### `NRS-484B-250-4` — Vehicle approaching or entering intersection (4)
_NRS 484B.250(4)_

When a vehicle enters an intersection controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection, the driver of the vehicle shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. After making such a stop, the driver shall proceed cautiously, yielding to vehicles which have previously completed a stop or are within the intersection.

Posted definitions that apply to its words:

- `DEF-NRS-484A-320` — “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029; and (4) An electric scooter.
- `DEF-NRS-484A-095` — “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195` — “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115` — “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045` — “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285` — “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-165` — “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029.
- `DEF-NRS-484A-081` — “Electric bicycle” has the meaning ascribed to it in NRS 484B.017.
- `DEF-NRS-484B-017` — “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025` — “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125` — “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018` — “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484A-105` — “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-070` — “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015` — “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215` — “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-290` — “Traffic-control signal” means any official traffic-control device, whether manually, electrically or mechanically operated, placed or erected by a public authority or railroad, by which traffic is alternately directed to stop or proceed.
- `DEF-NRS-484A-145` — “Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.
- `DEF-NRS-484A-200` — “Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.
- `DEF-NRS-484A-080` — (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030, and the automated driving system, as defined in NRS 482A.025, of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036, and the automated driving system, as defined in NRS 482A.025, of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
- `DEF-NRS-484A-150` — “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-484A-255` — “Stop,” when required, means complete cessation from movement.
- `DEF-NRS-484A-260` — “Stop” or “stopping” means, when prohibited, any halting, even momentarily, of a vehicle, whether occupied or not, except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device.
- `DEF-NRS-484A-065` — “Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.
- `DEF-NRS-484A-240` — “Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.
- `DEF-NRS-484A-275` — “Through highway” means every highway or portion thereof on which vehicular traffic is given the right-of-way, and at the entrances to which vehicular traffic from intersecting highways is required by law to yield right-of-way to vehicles on such through highway in obedience to either an authorized stop sign or a yield sign, or other official traffic-control device.
- `DEF-NRS-484A-210` — “Right-of-way” means the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other.


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
| `LVMC_11_38_030` | LVMC-11-38-030 | x | drv.motion.moving, rel.occupies, ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.electric_scooter, ru.moped, st.sidewalk | composable (build) | planned |
| `LVMC_11_43_010_A` | LVMC-11-43-010-A | x | drv.motion.clockwise_about_region, kin.position, kin.speed, kin.velocity, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.region_geometry, st.roundabout | composable (build) | planned |
| `NRS_484B_263_o1` | NRS-484B-263 | x | drv.motion.entering_region, drv.motion.leaving_region, drv.motion.moving, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | composable (build) | planned |
| `NRS_484B_227_1_o1` | NRS-484B-227-1 | x | drv.motion.against_carrier_direction, kin.speed, kin.velocity, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.lane_direction, st.median_or_divider, st.on_way, st.roadway | composable (build) | planned |
| `NRS_484B_210_3` | NRS-484B-210-3 | x | drv.interaction.passing_on_right, kin.speed, rel.bearing, rel.longitudinal_overlap, rel.occupies, rel.same_direction, ru.aggregate=DEF-NRS-484A-320::vehicle, st.road_edge, st.shoulder | composable (build) | planned |
| `NRS_484B_227_1_o2` | NRS-484B-227-1 | x | drv.motion.against_carrier_direction, kin.speed, kin.velocity, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_direction, st.median_or_divider, st.on_way, st.roadway | composable (build) | planned |
| `NRS_484B_113_2` | NRS-484B-113-2 | x | drv.motion.reversing, drv.motion.yawing, kin.heading, kin.velocity, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.intersection | composable (build) | planned |
| `NRS_484B_297_6_o3` | NRS-484B-297-6 | x | drv.motion.moving, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.highway, st.obstruction, st.on_way, st.region_geometry, st.sidewalk | not composable: operator | blocked |
| `NRS_484B_297_6_o2` | NRS-484B-297-6 | x | drv.motion.moving, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-165::pedestrian, st.bicycle_lane_or_path, st.highway, st.obstruction, st.on_way, st.region_geometry, st.sidewalk | not composable: operator | blocked |
| `NRS_484B_270_7b` | NRS-484B-270-7b | x | drv.interaction.overtaking_alongside, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.longitudinal_overlap, rel.same_direction, rel.surface_gap, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484A-130::motor_vehicle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | composable (build) | planned |
| `NRS_484B_440_1_o3` | NRS-484B-440-1 | x | drv.motion.halted, kin.engine_running, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hazard, st.highway, st.roadway, st.sight_distance | composable (build) | planned |
| `NRS_484B_440_1_o1` | NRS-484B-440-1 | x | dev.governs, dev.human_direction, dev.stop_sign, dev.traffic_signal, drv.motion.halted, kin.engine_running, kin.speed, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hazard, st.highway, st.region_geometry, st.roadway, st.shoulder, st.travel_region | composable (build) | planned |
| `NRS_484B_440_1_o2` | NRS-484B-440-1 | x | drv.motion.halted, kin.engine_running, kin.speed, rel.longitudinal_overlap, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hazard, st.highway, st.lane, st.lane_width, st.on_way, st.region_geometry, st.roadway | composable (build) | planned |
| `NRS_484B_223_4b` | NRS-484B-223-4b | x | drv.motion.heading_change_since_entry, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_enters, st.on_way, st.turn_lane | composable (build) | planned |
| `NRS_484B_413_2` | NRS-484B-413-2 | x | drv.motion.veering_left, drv.motion.veering_right, kin.path_length, kin.speed, kin.velocity, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, sig.hand_signal, sig.turn_indicator, st.lane_direction, st.travel_region | composable (build) | planned |
| `NRS_484B_560_7a` | NRS-484B-560-7a | x | dev.governs, dev.human_direction, drv.motion.entering_region, drv.motion.halted, drv.position.within_clearance_since_entry, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.railway_crossing, st.region_geometry, st.travel_region | composable (build) | planned |
| `NRS_484B_600_1a` | NRS-484B-600-1a | x | drv.motion.moving, drv.motion.stopping_distance, env.ice_or_snow, env.precipitation, env.visibility, env.wet_road, kin.extent, kin.speed, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-320::vehicle, st.curvature, st.lane, st.lane_width, st.sight_distance | composable (build) | planned |
| `NRS_484B_223_4a` | NRS-484B-223-4a | x | drv.motion.heading_change_since_entry, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_enters, st.on_way, st.turn_lane | composable (build) | planned |
| `NRS_484B_400_1_o1` | NRS-484B-400-1 | x | drv.motion.entering_region, drv.motion.heading_change_since_entry, drv.road.opposed_directions, kin.path_length, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane_direction, st.lane_enters, st.on_way, st.travel_region, st.turn_lane | composable (build) | planned |
| `NRS_484B_250_4_o1` | NRS-484B-250-4 | x | dev.governs, dev.inoperative, dev.traffic_signal, drv.motion.entering_region, drv.motion.halted, kin.speed, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane_enters, st.on_way, st.region_geometry, st.sight_along_way, st.stop_line, st.travel_region | composable (build) | planned |
| `NRS_484B_400_1_o2` | NRS-484B-400-1 | x | drv.motion.entering_region, drv.motion.heading_change_since_entry, drv.road.opposed_directions, kin.path_length, kin.yaw_rate, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.highway, st.intersection, st.lane, st.lane_adjacency, st.lane_direction, st.lane_enters, st.on_way, st.travel_region, st.turn_lane | composable (build) | planned |
| `NRS_484B_250_4_o2` | NRS-484B-250-4 | x | dev.governs, dev.inoperative, dev.traffic_signal, drv.motion.entering_region, drv.motion.halted, kin.speed, prim.closest_approach_distance, prim.closest_approach_within, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection, st.lane_enters, st.travel_region | composable (build) | planned |
| `NRS_484B_257_1_o1` | NRS-484B-257-1 | x | dev.governs, dev.human_direction, dev.inoperative, dev.stop_sign, dev.traffic_signal, dev.yield_sign, drv.motion.entering_region, drv.motion.halted, drv.motion.slowing, kin.accel_longitudinal, kin.heading, kin.speed, kin.velocity, prim.region_offset_along, rel.occupies, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.crosswalk, st.entrance_of, st.highway, st.intersection, st.lane_enters, st.on_way, st.region_geometry, st.sight_along_way, st.stop_line, st.travel_region | not composable: replanning | returned |
| `NRS_484B_769` | NRS-484B-769 | x | rel.occupies, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter, sig.hand_signal, sig.turn_indicator, st.roadway | composable (build) | planned |
| `NRS_484B_263_o2` | NRS-484B-263 | x | drv.motion.entering_region, drv.motion.leaving_region, drv.motion.moving, kin.speed, prim.closest_approach_within, rel.occupies, rel.surface_gap, ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | composable (build) | planned |
| `NRS_484B_363_3` | NRS-484B-363-3 | x | dev.governs, dev.speed_limit_beacon, dev.zone_sign, drv.motion.u_turn, drv.motion.yawing, kin.yaw_rate, prim.conditions_hold, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, ru.child, st.region_geometry, st.travel_region | composable (build) | planned |

### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)
`callers in a current plan` counts the accepted nodes, this run's and its base run's, that call the concept directly and are current: not fenced, and listed in their law's current plan (a node of a law this run does not plan is its base run's current record). A fenced node, an accepted node its law's current plan no longer lists, and a node of a law being planned again or waiting for the operator are not counted.

| id | kind | contract | definition | args | params | reads | calls | callers in a current plan |
|---|---|---|---|---|---|---|---|---|
| `drv.interaction.overtaking_alongside` | formula | Road user x is overtaking road user y alongside at the observation: the side-by-side phase of an overtaking, on either side of y. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Either side of y counts. Not denoted: the approach from behind or the return ahead of y, the side on which x passes, where either body is on the road, a lane change, contact, or the clearance between the bodies. |  | x:track, y:track | aligned_cosine (ratio), speed_margin (m/s) | kin.speed, rel.longitudinal_overlap, rel.same_direction | no concept | 1 |
| `drv.interaction.passing_on_right` | formula | Road user x is passing road user y on y's right at the observation: the side-by-side phase of an overtaking. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), y lies on x's left (the lateral component of rel.bearing of y from x, in x's frame), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Not denoted: the approach from behind or the return ahead of y, where either body is on the road, a lane change, contact, or the clearance between the bodies. |  | x:track, y:track | aligned_cosine (ratio), speed_margin (m/s) | kin.speed, rel.bearing, rel.longitudinal_overlap, rel.same_direction | no concept | 1 |
| `drv.motion.against_carrier_direction` | formula | A road user moves against the designated direction of a travel carrier at the observation. It holds where the road user is moving (drv.motion.moving with speed_floor) and the component of its velocity along the carrier's designated direction is below minus opposed_cosine times its speed: the angle between its velocity and that direction is wider than the angle whose cosine is minus opposed_cosine. Velocity (kin.velocity) and speed (kin.speed) are in m/s in the world frame; the designated direction (st.lane_direction) is read normalised and is unknown where the carrier carries none. Crossing the carrier, or any motion at a smaller angle to the designated direction than that, is not against it. Not denoted: the road user's heading opposing the carrier (a body backing along a lane faces against it but moves with it), two road users being oncoming, or the road user being on the carrier: the caller states occupancy. |  | x:track, r:region | speed_floor (m/s), opposed_cosine (ratio) | kin.speed, kin.velocity, st.lane_direction | `drv.motion.moving` | 2 |
| `drv.motion.clockwise_about_region` | formula | A road user moves clockwise about a structure region's reference point at the observation, viewed from above in the world frame, whose positive sense of rotation is counter-clockwise (the sense in which a yaw rate is positive). It holds where the road user is moving (drv.motion.moving with speed_floor) and the cross product of the vector from the region's reference point to the road user's reference point with the road user's velocity is negative and larger in magnitude than sine_tolerance times the product of that vector's length and the road user's speed, compared as squares: the sine of the angle from that radius vector to the velocity is below minus sine_tolerance. The region's reference point is read from st.region_geometry, the road user's from kin.position, its velocity from kin.velocity and its speed from kin.speed, in m and m/s. Motion toward or away from the reference point, within the tolerance, is neither sense. Not denoted: travel against a carrier's designated direction, a change of the road user's heading, or the road user being inside the region: the caller states occupancy. |  | x:track, r:region | speed_floor (m/s), sine_tolerance (ratio) | kin.position, kin.speed, kin.velocity, st.region_geometry | `drv.motion.moving` | 1 |
| `drv.motion.entering_region` | formula | Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before. The entry is that one observation; the later observations at which the overlap continues are not the entry again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, the region x came from, or its whole body being inside r: an overlap by any part of the footprint counts. |  | x:track, r:region |  | rel.occupies | no concept | 7 |
| `drv.motion.halted` | formula | A road user is at a standstill at the observation. This is the corpus definition of a required stop, "complete cessation from movement", observed on sampled speeds: the road user's speed (kin.speed, m/s) is at or below speed_floor, the source's speed resolution, below which a reading counts as no movement. The state holds at each observation at which the speed is that low, with no minimum duration. Not denoted: where the road user stands, why it stands, or whether its engine runs or a brake is set. | DEF-NRS-484A-255 | x:track | speed_floor (m/s) | kin.speed | no concept | 6 |
| `drv.motion.heading_change_since_entry` | quantity | The signed heading change of road user x since its footprint last began to overlap region r, in degrees, left positive: zero at the observation at which the overlap began, integrated from x's yaw rate (kin.yaw_rate) with step as the sampling step bound, not ended by x leaving r and restarted only by its next entry into r. Unknown where that entry is not observed with the overlap known at every observation since, where two consecutive observations since lie further apart than step, or where a yaw rate since the entry is missing. Not denoted: a turn manoeuvre by itself (a caller compares the change with its own bound, and a bend of the way inside the region changes it too), or the heading change over a fixed window. **Review notes (not confirmed differences):** The body agrees with the contract on the tested exit case: accumulation continues after the road user leaves the region.; The body agrees with the contract when time since entry exceeds step: step bounds consecutive sampling intervals, not the total integration duration.; A test of zero change at entry with a preceding observation more than step earlier was unusable: the harness reported insufficient temporal sampling. No divergence is established for that boundary case. |  | x:track, r:region | step (ms) | kin.time, kin.yaw_rate, rel.occupies | no concept | 4 |
| `drv.motion.leaving_region` | formula | Road user x leaves structure region r at the observation: its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation. The exit is that one observation; the later observations at which x stays off r are not the exit again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, or the region x moves into. **Review notes (not confirmed differences):** The tested exit, with observed overlap followed by observed non-overlap, agrees with the contract: the body holds.; The tested consecutive observations outside the region agree with the contract: the body fails at the second observation. |  | x:track, r:region |  | rel.occupies | no concept | 2 |
| `drv.motion.moving` | formula | A road user is in motion at the observation: its speed exceeds speed_floor. The floor names only the source's speed resolution, below which a reading counts as no motion; speed (kin.speed) is in m/s. The concept says nothing of the direction of motion relative to the body or to the road, of a manoeuvre, or of who or what controls the motion. Not denoted: a halt held for a duration, travel along a particular carrier, or a road user being driven by a person. |  | x:track | speed_floor (m/s) | kin.speed | no concept | 4 |
| `drv.motion.reversing` | formula | A road user moves backwards relative to its own body at the observation: the component of its velocity along its heading is below minus speed_floor. Velocity (kin.velocity) is in m/s in the world frame and heading (kin.heading) is read normalised; speed_floor is the source's speed resolution, so a standing or barely creeping body is not reversing. It is read from kinematics only, never from the gear selected: a vehicle in reverse gear that rolls forward is not reversing, and one in a forward gear that rolls backwards is. Not denoted: a turn, the path followed, or the place the road user is in. |  | x:track | speed_floor (m/s) | kin.heading, kin.velocity | no concept | 1 |
| `drv.motion.slowing` | formula | Road user x is slowing while moving forward at the observation: the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, read normalised) exceeds speed_floor, and its longitudinal acceleration (kin.accel_longitudinal, m/s², signed along the heading) is below minus decel_floor, the source's acceleration resolution. Not denoted: slowing while backing, a brake lamp or a brake input, a halt, or how much the speed has fallen. |  | x:track | speed_floor (m/s), decel_floor (m/s^2) | kin.accel_longitudinal, kin.heading, kin.velocity | no concept | 0 |
| `drv.motion.stopping_distance` | quantity | The distance road user x would cover from the observation to a standstill if it kept its present speed for reaction_time and then slowed at the constant deceleration deceleration: its speed (kin.speed, m/s) times reaction_time, plus the square of its speed divided by twice deceleration; in metres, zero for a body at a standstill. Not denoted: the distance x actually covers before a later halt, the deceleration the surface, the grade or the vehicle allows (the caller passes deceleration), whether anything lies within the distance, or whether x is required to stop. |  | x:track | reaction_time (s), deceleration (m/s^2) | kin.speed | no concept | 1 |
| `drv.motion.turning_left` | formula | Road user x is turning to its left at the observation: it is moving (drv.motion.moving with speed_floor) and its yaw rate (kin.yaw_rate, deg/s, left positive) exceeds yaw_floor, the source's yaw-rate resolution. It does not tell a turn at a junction from following a left-hand bend: the caller states the place. Not denoted: a completed turn manoeuvre, an intention to turn, or a turn indicator. |  | x:track | speed_floor (m/s), yaw_floor (deg/s) | kin.speed, kin.yaw_rate | `drv.motion.moving` | 0 |
| `drv.motion.u_turn` | formula | Road user x has turned so as to proceed in the opposite direction: the turning that the corpus defines as "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not", observed as a reversal of x's heading. It holds at an observation where the absolute value of x's signed heading change over the window behind it (prim.heading_change with window; degrees, left positive) differs from the literal half turn by no more than reversal_tolerance: the heading now points the opposite way within the tolerance, and a heading change that has gone past the half turn by more than the tolerance (a loop back toward the first direction) does not count. A turning made in several movements, forward and backing, counts, since the heading change is integrated through all of them. The act begins within the window behind the observation of recognition; it is recognized at the observation at which this condition rises; it holds at the later observations at which the reversal still lies within the window behind them, which are not the act again, and it ends when the reversal leaves that window. Unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing. Not denoted: a turning by less than a reversal, or the place of the turning: the caller states the highway or the zone. | DEF-NRS-484B-077 | x:track | window (s), reversal_tolerance (deg) | kin.yaw_rate | no concept | 1 |
| `drv.motion.veering_left` | formula | Road user x departs to the left of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the left of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, exceeds sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is above sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways. |  | x:track, c:region | speed_floor (m/s), sine_tolerance (ratio) | kin.speed, kin.velocity, st.lane_direction | `drv.motion.moving` | 1 |
| `drv.motion.veering_right` | formula | Road user x departs to the right of a travel carrier's designated direction at the observation: it moves forward along the carrier while its velocity points to the right of the carrier's direction by more than a tolerance. It holds where x is moving (drv.motion.moving with speed_floor), the component of its velocity (kin.velocity, m/s, world frame) along the carrier's designated direction (st.lane_direction, read normalised) is positive, and the cross product of that direction with the velocity, left positive, is below minus sine_tolerance times x's speed (kin.speed): the sine of the angle from the designated direction to the velocity is below minus sine_tolerance. Unknown where the carrier carries no designated direction. Not denoted: x's heading (a body may point across a carrier while moving along it), motion against the carrier's direction, x being on the carrier (the caller states occupancy), a signal, or how far x has moved sideways. |  | x:track, c:region | speed_floor (m/s), sine_tolerance (ratio) | kin.speed, kin.velocity, st.lane_direction | `drv.motion.moving` | 1 |
| `drv.motion.yawing` | formula | A road user's heading is changing at the observation: the absolute value of its yaw rate exceeds yaw_floor. Yaw rate (kin.yaw_rate) is in deg/s, left positive, and either hand counts; yaw_floor is the source's yaw-rate resolution. Not denoted: a turn at a junction, a lane change, or the curvature of the road: a road user yaws wherever its path bends, and one running straight does not. |  | x:track | yaw_floor (deg/s) | kin.yaw_rate | no concept | 2 |
| `drv.position.within_clearance_since_entry` | formula | Road user x has entered structure region r and has not since stood clear of it by clearance: x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before) at the observation or at an earlier one, and at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance. It becomes true at an entry, holds while x stays on r or within clearance of it, becomes false at the first observation at which x's body stands at clearance or more from r, and stays false until x's next entry. Unknown where it is undecided whether x entered r at an observation since which the distance stayed below clearance (at x's first observation, whether it entered there is unknown), or where the distance is unobserved at an observation that decides it. Not denoted: the side of r on which the body stands (a body that backs out of r and stays within clearance of it still holds), x's direction or speed, or a halt: the caller reads those. **Review notes (not confirmed differences):** A tested first observation with fully observed distance greater than a positive clearance returned fails, agreeing with the contract; it supplies no divergence.; dismissed: divergence 1 (holds_wrongly) at t=1000 ms: With clearance set to zero metres, x enters r at the judged observation. Its distance is zero, hence at clearance rather than below it; the body nevertheless … — contract: fails, body: holds; contract: "at every observation from that entry up to the observation the ground distance from x's body outline to r …" — The contract says unconditionally that the state becomes true at an entry, and the record discloses the reading that the distance is not tested at the entry observation. That is a choice among the meanings the contract's words allow. The divergence also arises only because the caller set clearance to zero, so it turns on the size of a parameter the caller sets. — "It becomes true at an entry, holds while x stays on r or within clearance of it" |  | x:track, r:region | clearance (m) | rel.occupies, st.region_geometry | `drv.motion.entering_region` | 1 |
| `drv.road.opposed_directions` | formula | The designated directions of two travel carriers point opposite ways: the dot product of their designated directions (st.lane_direction, read normalised, world frame) is below minus opposed_cosine, so the angle between them is wider than the angle whose cosine is minus opposed_cosine. Unknown where either carrier carries no designated direction. Not denoted: the motion or heading of any road user on them, the carriers lying on the same way, or their entering the same intersection: the caller states those. |  | c1:region, c2:region | opposed_cosine (ratio) | st.lane_direction | no concept | 2 |

Concept families (the fixed grammar `drv.<family>.<name>`): motion, position, lane, interaction, road, control, user, env.

| words | atoms | node |
|---|---|---|
| (a) must walk or otherwise travel as far to the side of the highway near the sidewalk | rel.occupies, st.highway, st.region_geometry, st.sidewalk | NRS_484B_297_6_o2 |
| (a) when there are no children present; | dev.governs, dev.zone_sign, ru.child, st.region_geometry, st.travel_region | NRS_484B_363_3 |
| (c) may walk or otherwise travel in a lane provided for bicycles, electric bicycles or electric scoo | rel.occupies, st.bicycle_lane_or_path | NRS_484B_297_6_o2 |
| (d) if the zone is designated by an operational speed limit beacon, | dev.governs, dev.speed_limit_beacon, rel.occupies, st.travel_region | NRS_484B_363_3 |
| (d) must return to the sidewalk | rel.occupies, st.sidewalk | NRS_484B_297_6_o3 |
| (e) if the zone is not designated by an operational speed limit beacon, | dev.governs, dev.speed_limit_beacon, st.travel_region | NRS_484B_363_3 |
| a clear view of such stopped vehicles shall be available from a distance of 200 feet in each directi | drv.motion.halted, kin.speed, st.sight_distance | NRS_484B_440_1_o3 |
| a pedestrian | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_297_6_o2 |
| a signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall | drv.motion.veering_left, drv.motion.veering_right, kin.path_length, kin.speed, kin.velocity, rel.occupies, sig.hand_signal, sig.turn_indicator, st.lane_direction, st.travel_region | NRS_484B_413_2 |
| a single right lane to be used only for turning | st.lane, st.lane_adjacency, st.turn_lane | NRS_484B_223_4a |
| a vehicle must | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_223_4a |
| about to enter or exit a controlled-access highway | drv.motion.entering_region, drv.motion.leaving_region, rel.occupies, st.controlled_access | NRS_484B_263_o2 |
| all vehicular travel shall be in a counterclockwise direction | drv.motion.clockwise_about_region, kin.position, kin.speed, kin.velocity, ru.aggregate=DEF-NRS-484A-320::vehicle, st.region_geometry, st.roundabout | LVMC_11_43_010_A |
| an operator of a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_769 |
| an unobstructed width of the highway | rel.occupies, st.highway, st.lane, st.on_way, st.region_geometry | NRS_484B_440_1_o2 |
| and not less than the last 300 feet traveled | kin.path_length | NRS_484B_413_2 |
| and shall continue to yield the right-of-way | drv.motion.entering_region, drv.motion.leaving_region, rel.occupies | NRS_484B_263_o2 |
| and the yellow lights of the speed limit beacon are not flashing in the manner which indicates that  | dev.speed_limit_beacon | NRS_484B_363_3 |
| any vehicle, whether attended or unattended, | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_440_1_o2 |
| as used in this section, “completely cross” means to travel across a railroad track or tracks in suc | drv.position.within_clearance_since_entry, rel.occupies, st.railway_crossing, st.region_geometry | NRS_484B_560_7a |
| at an intersection | drv.motion.entering_region, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_400_1_o2 |
| at: a rate of speed | kin.speed | NRS_484B_600_1a |
| be driven in the right turn lane only for the purpose of making a right turn | drv.motion.heading_change_since_entry, kin.yaw_rate, rel.occupies, st.intersection, st.lane, st.lane_adjacency, st.lane_enters, st.turn_lane | NRS_484B_223_4a |
| both the approach for the right turn and the right turn must be made from the right turn lane | kin.path_length, rel.occupies, st.intersection, st.lane_enters, st.turn_lane | NRS_484B_400_1_o1 |
| controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, b | dev.governs, dev.inoperative, dev.traffic_signal, rel.occupies, st.lane_enters, st.travel_region | NRS_484B_250_4_o2 |
| corner | rel.occupies, st.intersection | NRS_484B_113_2 |
| during the times when the sign designating the school zone or school crossing zone indicates that th | dev.zone_sign, prim.conditions_hold | NRS_484B_363_3 |
| established by a public authority | st.intersection, st.median_or_divider | NRS_484B_227_1_o2 |
| every vehicle driven | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_227_1_o2 |
| except that the operator may give a signal for a right turn by extending his or her right hand and a | sig.hand_signal | NRS_484B_769 |
| except through an opening in the barrier or dividing section or space | rel.occupies, st.median_or_divider | NRS_484B_227_1_o2 |
| except when traffic is being controlled by a police officer or a traffic-control signal: | dev.governs, dev.human_direction, dev.inoperative, dev.traffic_signal, ru.aggregate=DEF-NRS-484A-285::traffic, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_1_o1 |
| if a highway has been designed to provide | st.highway, st.on_way | NRS_484B_223_4a |
| if the area between the lane and the sidewalk is impassable; | st.obstruction, st.region_geometry | NRS_484B_297_6_o2 |
| if the driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_400_1_o2 |
| if the highway has a right turn lane | drv.road.opposed_directions, st.highway, st.lane_direction, st.lane_enters, st.on_way, st.turn_lane | NRS_484B_400_1_o2 |
| in an area designated as a school zone or school crossing zone | dev.governs, dev.zone_sign, rel.occupies, st.travel_region | NRS_484B_363_3 |
| including, without limitation, a short section of the sidewalk that is missing or impassable, | st.obstruction, st.region_geometry, st.sidewalk | NRS_484B_297_6_o2 |
| it is unlawful for any person to drive or operate a vehicle of any kind or character | drv.motion.moving, kin.speed, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_600_1a |
| it is unlawful for the driver of any vehicle: | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_560_7a |
| may proceed | rel.occupies, st.highway, st.on_way, st.sidewalk | NRS_484B_297_6_o2 |
| must be driven only upon the right-hand roadway | drv.motion.against_carrier_direction, kin.speed, kin.velocity, rel.occupies, st.lane_direction, st.roadway | NRS_484B_227_1_o1 |
| must not be driven over, across or within any dividing space, barrier or section or make any left tu | drv.motion.against_carrier_direction, kin.speed, kin.velocity, rel.occupies, st.lane_direction, st.median_or_divider, st.roadway | NRS_484B_227_1_o2 |
| no motorcycle or motor scooter | ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.electric_scooter, ru.moped | LVMC_11_38_030 |
| no person shall stop, park or leave standing | dev.governs, dev.human_direction, dev.stop_sign, dev.traffic_signal, drv.motion.halted, kin.speed, rel.ahead_behind_in_lane, rel.occupies, rel.surface_gap, st.travel_region | NRS_484B_440_1_o1 |
| not travel through an intersection | drv.motion.heading_change_since_entry, kin.yaw_rate, rel.occupies, st.intersection, st.lane_enters | NRS_484B_223_4b |
| of a vehicle. | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_413_2 |
| on the immediately adjacent highway to move around such an obstruction. | rel.occupies, st.highway, st.on_way, st.sidewalk | NRS_484B_297_6_o2 |
| opposite a standing vehicle | drv.motion.halted, kin.speed, rel.longitudinal_overlap | NRS_484B_440_1_o2 |
| or are within the intersection. | rel.occupies, st.intersection | NRS_484B_250_4_o2 |
| or at a crossover or intersection | rel.occupies, st.intersection, st.median_or_divider | NRS_484B_227_1_o2 |
| or must be made from the extreme right lane. | kin.path_length, rel.occupies, st.lane, st.lane_adjacency, st.lane_enters | NRS_484B_400_1_o2 |
| prior to changing the course | drv.motion.veering_left, drv.motion.veering_right, rel.occupies | NRS_484B_413_2 |
| shall be ridden upon any sidewalk | drv.motion.moving, rel.occupies, st.sidewalk | LVMC_11_38_030 |
| shall give all signals by hand and arm | sig.hand_signal, sig.turn_indicator | NRS_484B_769 |
| shall not back into an intersection, on or over a crosswalk, or around a | drv.motion.reversing, drv.motion.yawing, kin.heading, kin.velocity, kin.yaw_rate, rel.occupies, st.crosswalk, st.intersection | NRS_484B_113_2 |
| shall not make a u-turn | drv.motion.u_turn | NRS_484B_363_3 |
| shall not overtake and pass another vehicle upon the right | drv.interaction.passing_on_right, kin.speed, rel.bearing, rel.longitudinal_overlap, rel.same_direction, ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_210_3 |
| shall not: overtake and pass a motor vehicle | drv.interaction.overtaking_alongside, kin.speed, rel.longitudinal_overlap, rel.same_direction, ru.aggregate=DEF-NRS-484A-130::motor_vehicle | NRS_484B_270_7b |
| shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop | drv.motion.halted, kin.speed, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | NRS_484B_250_4_o1 |
| shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswal | drv.motion.halted, drv.motion.slowing, kin.accel_longitudinal, kin.heading, kin.speed, kin.velocity, prim.region_offset_along, rel.occupies, st.crosswalk, st.entrance_of, st.intersection, st.lane_enters, st.region_geometry, st.stop_line, st.travel_region | NRS_484B_257_1_o1 |
| shall yield the right-of-way | drv.motion.entering_region, drv.motion.leaving_region, rel.occupies | NRS_484B_263_o1 |
| such a pedestrian: | ru.aggregate=DEF-NRS-484A-165::pedestrian | NRS_484B_297_6_o2 |
| the driver of a vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_363_3 |
| the driver of the vehicle | ru.aggregate=DEF-NRS-484A-320::vehicle | NRS_484B_250_4_o2 |
| the driver shall proceed | drv.motion.entering_region, rel.occupies, st.intersection | NRS_484B_250_4_o2 |
| the operator of a bicycle, an electric bicycle or an electric scooter | ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter | NRS_484B_270_7b |
| the turn is a right turn, | drv.motion.heading_change_since_entry, kin.yaw_rate, rel.occupies | NRS_484B_400_1_o2 |
| this section shall not apply to the driver of any vehicle which is disabled while on the paved or ma | kin.engine_running, rel.occupies, sig.hazard, st.roadway | NRS_484B_440_1_o2 |
| to all vehicles approaching on the highway | drv.motion.moving, kin.speed, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.controlled_access | NRS_484B_263_o2 |
| to fail to completely cross the track or tracks without stopping due to insufficient: (1) space for  | dev.governs, dev.human_direction, drv.motion.halted, kin.speed, rel.occupies, st.travel_region | NRS_484B_560_7a |
| to that traffic | ru.aggregate=DEF-NRS-484A-285::traffic | NRS_484B_263_o2 |
| upon a divided highway | rel.occupies, st.highway, st.median_or_divider, st.on_way, st.roadway | NRS_484B_227_1_o2 |
| upon a roadway | rel.occupies, st.roadway | NRS_484B_769 |
| upon any highway | rel.occupies, st.highway | NRS_484B_440_1_o2 |
| upon the paved or main-traveled part of the highway | rel.occupies, st.roadway | NRS_484B_440_1_o2 |
| vehicles | ru.aggregate=DEF-NRS-484A-320::vehicle | LVMC_11_43_010_A |
| walking or otherwise traveling on a sidewalk | drv.motion.moving, kin.speed, rel.occupies, st.sidewalk | NRS_484B_297_6_o2 |
| when a vehicle enters an intersection | drv.motion.entering_region, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection | NRS_484B_250_4_o2 |
| when crossing at grade any track or tracks of a railroad, | drv.motion.entering_region, drv.position.within_clearance_since_entry, rel.occupies, st.railway_crossing, st.region_geometry | NRS_484B_560_7a |
| when proper signs have been erected, | dev.governs, dev.stop_sign, dev.yield_sign, drv.motion.entering_region, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_257_1_o1 |
| when such movement requires driving off the paved portion of the highway | rel.occupies, st.road_edge, st.shoulder | NRS_484B_210_3 |
| which have previously completed a stop | drv.motion.halted, kin.speed, rel.occupies, st.intersection, st.lane_enters, st.travel_region | NRS_484B_250_4_o2 |
| while being driven in the right turn lane | rel.occupies, st.turn_lane | NRS_484B_223_4b |
| who encounters an obstruction to his or her mobility on the sidewalk, | st.obstruction, st.region_geometry | NRS_484B_297_6_o2 |
| within a roundabout | rel.occupies, st.roundabout | LVMC_11_43_010_A |
| yielding to vehicles | drv.motion.entering_region, rel.occupies, ru.aggregate=DEF-NRS-484A-320::vehicle, st.intersection | NRS_484B_250_4_o2 |

| parameter | unit | convention |
|---|---|---|
| `p.access_crossing_reach` | m | Access reach: the ground distance from a vehicle's body to a driveway or alley entrance within which its presence in a bicycle lane counts as part of entering or exiting it; about one passenger-car length. |
| `p.braking_decel_dry` | m/s^2 | Braking deceleration on a dry surface: a firm, controlled stop most drivers make on dry pavement. |
| `p.braking_decel_ice` | m/s^2 | Braking deceleration on an icy or snow-covered surface: the deceleration packed snow or ice allows under controlled braking. |
| `p.braking_decel_wet` | m/s^2 | Design braking deceleration: the deceleration most drivers keep within their lane and control on a wet surface, used by the stopping sight distance model. |
| `p.child_presence_reach` | m | Presence reach: the ground distance from a child's body to a travel region of a school zone within which the child counts as present in the zone; the width of a sidewalk and verge beside the roadway. |
| `p.circulation_sine_tolerance` | ratio | Direction tolerance: the sine of the largest angle off a radial line within which motion about a point counts as neither sense of rotation, covering heading and position noise on entry and exit paths. |
| `p.conflict_clearance` | m | Conflict radius: the centre distance at predicted closest approach below which two road users' paths count as in conflict; about the half-length plus half-width of two passenger cars. |
| `p.course_departure_sine` | ratio | Course-departure tolerance: the sine of the angle between a road user's velocity and its carrier's designated direction beyond which it counts as leaving its direct course rather than tracking the carrier; about three degrees, above heading noise and lane-keeping drift. |
| `p.curve_lateral_accel` | m/s^2 | Curve lateral acceleration: the lateral acceleration (speed squared times curvature) above which a curve is taken faster than ordinary drivers' comfort and control margin. |
| `p.deceleration_resolution` | m/s^2 | Sensor resolution: the smallest longitudinal deceleration the acquisition standard separates from steady speed; a deceleration at or below it counts as no slowing. |
| `p.entering_combination_length` | m | Design-vehicle length: the overall length of the longest combination of vehicles a highway is designed to carry, standing for 'any other vehicle or combination of vehicles' that may enter the space. |
| `p.entry_time_headway` | s | Safe time headway: the time gap kept to the vehicle ahead, applied once ahead of and once behind the entering vehicle at the subject's speed. |
| `p.free_passage_width` | m | Free-passage width: the smallest width of an unoccupied lane beside a standing vehicle that lets another vehicle pass; a design passenger-car width plus lateral clearance. |
| `p.heading_since_step_carla_scene_graph` | ms | The sampling period of the carla_scene_graph acquisition standard, 20 Hz (one scene every 50 ms): the step bound of headingSince, the largest gap between two consecutive scenes it integrates across; not a look-back window and not an action window. |
| `p.immediate_hazard_gap` | s | Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach, counts as an immediate hazard to a road user about to cross or join its path. |
| `p.intersection_sight_distance` | m | Intersection sight distance: the length of the crossing way, in the smaller of its two directions, that a driver halted on a stop-controlled approach must be able to see to judge a gap in approaching traffic. |
| `p.lateral_margin_time` | s | Speed-proportional lateral margin: the lateral room beside a vehicle, both sides together, that grows with speed to absorb lateral wander; the speed times this time must fit in the lane width beyond the vehicle's width. |
| `p.low_beam_reveal_distance` | m | Low-beam reveal distance: the distance ahead to which the lowermost distribution of light reveals persons and vehicles, as the multiple-beam equipment standard sets it for the lowermost beam. |
| `p.merge_time_headway` | s | Safe merge headway: the time an approaching vehicle on the highway would take, at its own speed, to close the gap to a vehicle entering or leaving the highway; a smaller gap is not reasonable safety. |
| `p.obstruction_encounter_reach` | m | Encounter reach: the ground distance from a pedestrian's body to an obstruction within which the pedestrian has come up against it. |
| `p.offroad_stop_reach` | m | Off-road stopping reach: the ground distance from a halted vehicle's body to a shoulder within which moving off the main-traveled part counts as practicable; about one lane width of lateral movement. |
| `p.oncoming_heading_cosine` | ratio | Oncoming tolerance: the cosine of the largest angle off exactly opposed headings within which two road users count as oncoming; about 45 degrees, covering bends and lane offsets on a two-way road. |
| `p.opposed_carriers_cosine` | ratio | Direction tolerance: minus the cosine of the narrowest angle between two carriers' designated directions that counts as opposite directions; carriers within about 45 degrees of exactly opposed count. |
| `p.opposed_direction_cosine` | ratio | Direction tolerance: minus the cosine of the narrowest angle between a velocity and a carrier's designated direction that counts as travel against it; motion at a smaller angle, crossing included, does not. |
| `p.opposite_lane_reach` | m | Beside reach: the largest ground distance from a standing vehicle's body to a lane within which the lane counts as opposite the vehicle; covers the lateral gap between the body and the next lane's edge. |
| `p.overtaking_speed_margin` | m/s | Speed resolution of a speed difference: the smallest excess of the subject's speed over the other's that counts as gaining on it rather than keeping pace. |
| `p.passing_lateral_clearance` | m | Passing clearance: the smallest surface gap between a cycle or scooter and a motor vehicle it passes alongside at which the pass endangers neither the rider nor the vehicle's occupants; the three-foot passing-clearance convention applied from the rider's side. |
| `p.pedestrian_detour_offset` | m | Pedestrian detour width: the largest distance from the sidewalk at which a pedestrian walking on the adjacent highway counts as keeping to the side nearest the sidewalk; one pedestrian design width plus shy distance. |
| `p.perception_reaction_time` | s | Perception-reaction time: the time a driver keeps its speed before braking begins, in the stopping sight distance model. |
| `p.same_direction_cosine` | ratio | Heading alignment tolerance: the cosine of the largest angle between two headings that still counts as travelling the same way. |
| `p.sidewalk_return_time` | s | Return time: the time after a pedestrian has passed an obstruction within which a return to the sidewalk counts as made as soon as practicable; a few walking steps at the design walking speed. |
| `p.speed_resolution` | m/s | Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion. |
| `p.stop_point_tolerance` | m | Stop-point tolerance: the largest ground distance between a halted body and the line, crossing or intersection edge at which the halt counts as made at that place; a body farther upstream is outside the stopping zone. |
| `p.stopping_conflict_gap` | m | Conflict standoff: the largest surface gap from a halted road user's body to another road user ahead of it at which the halt counts as necessary to avoid a conflict; a queue spacing at standstill. |
| `p.traffic_time_headway` | s | Minimum time headway in traffic: the time gap to the road user ahead in the lane below which the speed is too high for the traffic. |
| `p.turn_approach_length` | m | Turn approach: the distance travelled just before entering an intersection over which a turning vehicle's approach is judged; about two passenger-car lengths, shorter than the storage of a short turn bay. |
| `p.turn_recognition_angle` | deg | Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets. |
| `p.u_turn_reversal_tolerance` | deg | Reversal tolerance: the largest difference between the size of the heading change over the window and a half turn within which the road user counts as proceeding in the opposite direction; covers the offset of a turn into a lane of the opposite direction and heading noise. |
| `p.u_turn_window` | s | U-turn recognition window: the longest time over which a reversal of heading, made in one movement or in several forward and backing movements, is recognized as one turning; a multi-point turn on a narrow street. |
| `p.yaw_rate_resolution` | deg/s | Sensor resolution: the smallest yaw rate the acquisition standard separates from a straight path; a yaw rate at or below it counts as no heading change. |

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

### Declared-fact ids (assumptions `asm.*`, declared intentions `int.*`): reuse an id whose meaning is the words' meaning
| id | meaning | status |
|---|---|---|
| `asm.outside_business_district` | The place of the observation lies outside every business district declared for the map or the trace. | proposed |
| `asm.outside_school_operation_margin` | The time of the observation lies at least a half hour after the school the zone serves last ceased operation and at least a half hour before it next begins operation, as declared for the map or the trace. | proposed |
| `asm.pupils_in_class` | The time of the observation lies within the hours during which the pupils of the school the zone serves are in class, as declared for the map or the trace. | proposed |
| `asm.school_not_in_session_day` | The calendar day of the observation is one on which the school the zone serves is not in session, as declared for the map or the trace. | proposed |
| `asm.within_business_or_residence_district` | The place of the observation lies inside a business district or a residence district declared for the map or the trace. | proposed |
| `asm.within_city_limits` | The place of the observation lies inside the territorial limits of an incorporated city, as declared for the map or the trace. | proposed |
| `int.left_turn` | The source's current plan for the road user includes a left turn at the target region. | proposed |
| `int.turn` | The source's current plan for the road user includes a turn, to either hand, at the target region. | proposed |

| id | state | kind | span | proposal | decision |
|---|---|---|---|---|---|
| G17 | proposed | atom | in a caravan or motorcade | `ru.procession_member` | a road user travelling as a member of an organized group of vehicles proceeding together in a c |  |
| G18 | proposed | atom | including, without limitation, a short section of the sidewalk that is missing o | st.impassable_section | a stretch of a sidewalk, or of the ground between a sidewalk and the roadway, that a pedestrian  |  |
| G19 | proposed | atom | (b) When operating or parking a disabled vehicle; | ru.disabled | the vehicle cannot move under its own power (breakdown, damage, a flat tyre), as the source records it; de |  |
| G20 | proposed | atom | (f) In an emergency. | env.emergency | a sudden peril at the observation that a road user's conduct answers to (a fire, a medical emergency of  |  |
| G21 | proposed | atom | and (c) When directed by an official traffic control device. | `dev.lamps_on_sign` | a regulatory sign directing road users to display lighted lamps (headlamps on) where it governs, a |  |
| G22 | proposed | operator | or in compliance with law | An operator that decides whether, at an observation, some rule of the set that is engaged for the subject there is compl |  |

# Feedback from iteration 3

concept `drv.position.entered_via`: re-proposed by a repair session
concept `drv.position.entered_via`: gate WITNESS_FAIL — blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_250_1`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_253_o1`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_253_o2`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_257_1_o2`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9b_o1`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9a_o1`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9a_o2`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9b_o2`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9b_o3`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_307_9b_o4`: not coded — uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Laws by state

- blocked: 7
- planned: 17
- returned: 5

## Returned laws and why

- `NRS-484B-250-1` (attempt 0): uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
- `NRS-484B-253` (attempt 0): uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
- `NRS-484B-257-1` (attempt 0): uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks — accepted already and not to be re-planned: NRS_484B_257_1_o1
- `NRS-484B-307-9a` (attempt 0): uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
- `NRS-484B-307-9b` (attempt 0): uses concept `drv.position.entered_via`, failed: gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Concepts by state

- accepted: 19
- failed: 1

## Returned concepts and why

- `drv.position.entered_via` (failed, attempt 3; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Repair evidence

No law-level label-repair evidence is supplied for this session.

## Your previous record of these laws

### `NRS-484B-250-1`: the plan of iteration 1 and what followed

`NRS_484B_250_1` — its duty: “shall yield the right-of-way” (characters 52–80)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `s5` “Except as otherwise provided in subsection 4 [NRS-484B-250-4],” composes `NRS_484B_250_4_o1` as unless: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_250_1",
 "law_refs": [
  "NRS-484B-250-1"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "The driver of a vehicle",
   "role": "subject"
  },
  {
   "id": "s2",
   "text": "approaching an intersection",
   "role": "trigger"
  },
  {
   "id": "s3",
   "text": "shall yield the right-of-way",
   "role": "obligation"
  },
  {
   "id": "s4",
   "text": "to a vehicle which has entered the intersection from a different highway.",
   "role": "condition"
  },
  {
   "id": "s5",
   "text": "Except as otherwise provided in subsection 4 [NRS-484B-250-4],",
   "role": "reference"
  },
  {
   "id": "s6",
   "text": "this section does not apply at intersections controlled by official traffic-control devices",
   "role": "exception"
  },
  {
   "id": "s7",
   "text": "or to vehicles approaching each other from opposite directions,",
   "role": "exception"
  },
  {
   "id": "s8",
   "text": "when the driver of one of the vehicles is intending to",
   "role": "exception"
  },
  {
   "id": "s9",
   "text": "or is making a left turn.",
   "role": "exception"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'vehicle' is admitted as DEF-NRS-484A-320::vehicle; 'the driver' is read through the vehicle's controlled motion (DEF-NRS-484A-080)."
  },
  {
   "span": "s2",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "'approaching an intersection': x occupies (rel.occupies) a carrier of kind st.travel_region whose entrance end is the intersection (st.lane_enters 'the carrier is an approach to that intersection'); the yield is decided at the observation at which x enters it (drv.motion.entering_region), where x still occupies that approach carrier. st.lane_enters is not a stand-in for the subject's presence in the intersection, which rel.occupies reads."
  },
  {
   "span": "s3",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "'yield the right-of-way' (DEF-NRS-484A-210 'the right ... to proceed in a lawful manner in preference to another vehicle'): x does not enter the intersection (drv.motion.entering_region over rel.occupies) while a vehicle owed precedence is in it."
  },
  {
   "span": "s4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region",
    "st.on_way",
    "st.highway"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "'a vehicle' is the admitted aggregate. 'which has entered the intersection' is rel.occupies of y and the intersection on y's current entry, and 'from a different highway' is the carrier y entered through (drv.position.entered_via, st.lane_enters) lying on a st.highway ('the entire public way between its boundary lines') through st.on_way ('the public way ... a structure region lies on') on which x's approach carrier does not lie. The intersection lies on every way that meets there, so the way is read from the carriers, never the intersection."
  },
  {
   "span": "s6",
   "atoms": [
    "dev.traffic_signal",
    "dev.stop_sign",
    "dev.yield_sign",
    "dev.governs",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'official traffic-control devices' (DEF-NRS-484A-145 'every sign, signal, marking and device ... for the purpose of regulating, warning or guiding traffic') that control the intersection: a dev.traffic_signal, dev.stop_sign ('regulatory sign requiring a full halt') or dev.yield_sign ('regulatory sign requiring yielding') governing the intersection or x's approach carrier (dev.governs 'the travel regions whose traffic the device controls ... or an intersection'). dev.governs is not a stand-in for a position."
  },
  {
   "span": "s7",
   "atoms": [
    "st.lane_enters",
    "st.travel_region",
    "rel.occupies"
   ],
   "derived": [
    "drv.road.opposed_directions",
    "drv.position.entered_via"
   ],
   "justification": "'approaching each other from opposite directions': read, as rel.oncoming's contract directs, through the carriers they approach through: x's approach carrier and the carrier y entered through (drv.position.entered_via) have opposed designated directions (drv.road.opposed_directions over st.lane_direction). rel.oncoming is not used: a turn makes current headings cease to be opposed while the approach direction is unchanged."
  },
  {
   "span": "s9",
   "atoms": [
    "kin.yaw_rate",
    "rel.occupies"
   ],
   "derived": [
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "'is making a left turn': the vehicle's heading change since it entered the intersection (drv.motion.heading_change_since_entry, left positive, integrated from kin.yaw_rate) is at least the turn recognition angle; a bend of the way inside the region also changes it, which a right-angled junction does not offer."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [
  {
   "span": "s8",
   "id": "int.left_turn",
   "meaning": "The source's current plan for the road user includes a left turn at the target region."
  }
 ],
 "compositions": [
  {
   "span": "s5",
   "rule": "NRS_484B_250_4_o1",
   "map": {
    "x": "x"
   },
   "as": "unless",
   "scopes": "s6"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "x is a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) and enters intersection i (st.intersection) at this observation (drv.motion.entering_region x i) from an approach carrier c it occupies (st.travel_region, st.lane_enters c i). Device exception (s6): the duty does not apply where some dev.traffic_signal, dev.stop_sign or dev.yield_sign governs i or c (dev.governs) at this observation; this exception is suspended where NRS_484B_250_4_o1 applies to x here (ruleApplies NRS_484B_250_4_o1 {x -> x}: an entry under an inoperative signal).",
 "obligation": "At this entry no vehicle y other than x (ru.aggregate=DEF-NRS-484A-320::vehicle) occupies i having entered it from a different highway: y occupies i, entered it through a carrier c2 (drv.position.entered_via y i c2, st.lane_enters c2 i) that lies on a highway h2 (st.highway, st.on_way c2 h2) on which c does not lie (st.on_way c h2 false). Pair exception (s7 to s9): a y is excluded where c and c2 have opposed designated directions (drv.road.opposed_directions c c2 with p.opposed_carriers_cosine) and x or y intends a left turn at i (intent int.left_turn x i, or intent int.left_turn y i) or is making one (drv.motion.heading_change_since_entry of x or of y and i, with step p.heading_since_step_carla_scene_graph, at least p.turn_recognition_angle).",
 "params": [
  "p.opposed_carriers_cosine",
  "p.heading_since_step_carla_scene_graph",
  "p.turn_recognition_angle"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "'the driver' is read through the vehicle's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s3",
   "why": "The yield is judged at x's entry into the intersection: an entry while a vehicle from a different highway is in it is the failure to yield.",
   "kind": "reading"
  },
  {
   "span": "s6",
   "why": "'official' is read through the device's presence; the devices that control an intersection are read as traffic signals, stop signs and yield signs governing the intersection or the subject's approach (a marking or a warning sign alone controls no right-of-way there).",
   "kind": "observable_reading",
   "category": "status"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "No device governs i or its approaches. Vehicle y entered i from carrier c2 on highway h2; x, on carrier c on highway h (c not on h2), enters i while y occupies i."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "As forbid, but x waits on c until y has left i and enters i as the only road user in the scene."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "A dev.stop_sign governs c; signals are absent; x enters i while y occupies i."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but rel.occupies of y and i is not observed at x's entry.",
   "masked": [
    "rel.occupies"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "A dev.traffic_signal governing i is dev.inoperative (NRS_484B_250_4_o1 applies); y entered i from a different highway; x enters i while y occupies it."
  },
  {
   "name": "branch_2",
   "expected": "compliant",
   "narrative": "At a skewed junction, y entered i through c2 on another highway whose designated direction is opposed to c's, and int.left_turn y i is declared; x enters while y is in i: the pair is excepted."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.opposed_carriers_cosine",
   "unit": "ratio",
   "value": 0.7,
   "convention": "Direction tolerance: minus the cosine of the narrowest angle between two carriers' designated directions that counts as opposite directions; carriers within about 45 degrees of exactly opposed count.",
   "source": "Junction geometry: approaches meeting at an intersection skewed by up to 45 degrees (AASHTO Green Book ch. 9)"
  },
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "Geometry of a right-angled junction (AASHTO Green Book ch. 9 intersection angles)"
  }
 ],
 "gaps": []
}
```

### `NRS-484B-253`: the plan of iteration 1 and what followed

`NRS_484B_253_o1` — its duty: “shall yield the right-of-way” (characters 77–105)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- composes no rule

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_253_o1",
 "law_refs": [
  "NRS-484B-253"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "The driver of a vehicle",
   "role": "subject"
  },
  {
   "id": "s2",
   "text": "within an intersection",
   "role": "trigger"
  },
  {
   "id": "s3",
   "text": "intending to turn to the left",
   "role": "trigger"
  },
  {
   "id": "s4",
   "text": "shall yield the right-of-way",
   "role": "obligation"
  },
  {
   "id": "s5",
   "text": "to any vehicle approaching from the opposite direction",
   "role": "condition"
  },
  {
   "id": "s6",
   "text": "which is within the intersection",
   "role": "condition"
  },
  {
   "id": "s7",
   "text": "or so close thereto as to constitute an immediate hazard,",
   "role": "standard"
  },
  {
   "id": "s8",
   "text": "but such driver, having so yielded",
   "role": "sibling"
  },
  {
   "id": "s9",
   "text": "and having given a signal",
   "role": "sibling"
  },
  {
   "id": "s10",
   "text": "when and as required,",
   "role": "sibling"
  },
  {
   "id": "s11",
   "text": "may make such left turn",
   "role": "sibling"
  },
  {
   "id": "s12",
   "text": "and the drivers of all other vehicles",
   "role": "sibling"
  },
  {
   "id": "s13",
   "text": "approaching the intersection from the opposite direction",
   "role": "sibling"
  },
  {
   "id": "s14",
   "text": "shall yield the right-of-way",
   "role": "sibling"
  },
  {
   "id": "s15",
   "text": "to the vehicle making the left turn.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'vehicle' is the admitted aggregate DEF-NRS-484A-320::vehicle; 'the driver' is read through its controlled motion."
  },
  {
   "span": "s2",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "'within an intersection': rel.occupies 'a road user's footprint overlaps a lane / region' of a st.intersection; the carrier x came in through (drv.position.entered_via, st.lane_enters) fixes its approach direction for s5."
  },
  {
   "span": "s4",
   "atoms": [
    "kin.yaw_rate",
    "kin.speed"
   ],
   "derived": [
    "drv.motion.turning_left"
   ],
   "justification": "'shall yield the right-of-way' (DEF-NRS-484A-210 'the right ... to proceed ... in preference'): a driver already within the intersection proceeds in preference by making its left turn; yielding is not turning left (drv.motion.turning_left: moving with kin.yaw_rate, left positive, above the resolution) while a vehicle owed precedence is present."
  },
  {
   "span": "s5",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "rel.occupies",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [
    "drv.road.opposed_directions",
    "drv.position.entered_via"
   ],
   "justification": "'any vehicle' is the admitted aggregate. 'approaching from the opposite direction' is read, as rel.oncoming's 'not a stand-in' clause directs, through the carriers: y's approach carrier of the intersection (one it occupies, or the one it entered through) has a designated direction opposed to that of x's approach carrier (drv.road.opposed_directions)."
  },
  {
   "span": "s6",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [],
   "justification": "'which is within the intersection': rel.occupies of y and the intersection x is in."
  }
 ],
 "operationalizations": [
  {
   "span": "s7",
   "standard": "so close to the intersection as to constitute an immediate hazard",
   "concepts": [
    "st.region_geometry",
    "kin.speed"
   ],
   "params": [
    "p.immediate_hazard_gap"
   ],
   "convention": "Gap acceptance (HCM critical headway): an approaching vehicle outside the intersection is an immediate hazard where its ground distance to the intersection (st.region_geometry 'the ground distance from a road user's body outline to it') is at most its speed (kin.speed) times p.immediate_hazard_gap, so the bound moves with both proximity and speed.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [
  {
   "span": "s3",
   "id": "int.left_turn",
   "meaning": "The source's current plan for the road user includes a left turn at the target region."
  }
 ],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "x is a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) within intersection i (st.intersection, rel.occupies x i) on an entry through approach carrier c (drv.position.entered_via x i c, st.travel_region, st.lane_enters c i), and the source declares at this observation that x intends a left turn at i (intent int.left_turn x i).",
 "obligation": "x is not turning left (drv.motion.turning_left x with p.speed_resolution and p.yaw_rate_resolution) at this observation if some vehicle y other than x (ru.aggregate=DEF-NRS-484A-320::vehicle) approaches from the opposite direction and is within i or so close to i as to be an immediate hazard: either (a) y occupies i, having entered it through a carrier c2 (drv.position.entered_via y i c2, st.lane_enters c2 i) with drv.road.opposed_directions c c2 (p.opposed_carriers_cosine); or (b) y occupies an approach carrier c2 of i (rel.occupies y c2, st.lane_enters c2 i) with drv.road.opposed_directions c c2, y does not occupy i, and st_region_geometry_distance y i is at most kin_speed y times p.immediate_hazard_gap.",
 "params": [
  "p.speed_resolution",
  "p.yaw_rate_resolution",
  "p.opposed_carriers_cosine",
  "p.immediate_hazard_gap"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "'the driver' is read through the vehicle's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s4",
   "why": "Yielding by a driver already within the intersection is read as not turning left while the opposing vehicle is present; creeping straight ahead is not read as a failure to yield.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x occupies i after entering via c, int.left_turn x i declared; vehicle y on c2 (opposed to c, st.lane_enters c2 i) is 20 m from i at 15 m/s; x moves at 4 m/s with kin.yaw_rate 15 deg/s."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x waits halted in i until y has passed, then turns left (kin.yaw_rate 15 deg/s, 4 m/s) as the only road user in the scene."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x occupies i and the source declares int.left_turn x i false (x goes straight)."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but kin.yaw_rate of x is not observed.",
   "masked": [
    "kin.yaw_rate"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "Vehicle y occupies i, having entered through c2 opposed to c; x turns left (moving, kin.yaw_rate 12 deg/s)."
  },
  {
   "name": "branch_2",
   "expected": "compliant",
   "narrative": "Vehicle y on c2 opposed to c is 200 m from i at 15 m/s; x turns left."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "carla_scene_graph acquisition standard: speed resolution of the recorded kinematics"
  },
  {
   "name": "p.yaw_rate_resolution",
   "unit": "deg/s",
   "value": 2.0,
   "convention": "Sensor resolution: the smallest yaw rate the acquisition standard separates from a straight path; a yaw rate at or below it counts as no heading change.",
   "source": "carla_scene_graph acquisition standard: yaw-rate resolution of the recorded kinematics"
  },
  {
   "name": "p.opposed_carriers_cosine",
   "unit": "ratio",
   "value": 0.7,
   "convention": "Direction tolerance: minus the cosine of the narrowest angle between two carriers' designated directions that counts as opposite directions; carriers within about 45 degrees of exactly opposed count.",
   "source": "Junction geometry: approaches meeting at an intersection skewed by up to 45 degrees (AASHTO Green Book ch. 9)"
  },
  {
   "name": "p.immediate_hazard_gap",
   "unit": "s",
   "value": 4.1,
   "convention": "Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach, counts as an immediate hazard to a road user about to cross or join its path.",
   "source": "HCM 7th ed. Exhibit 20-11 base critical headway (major-street left turn)"
  }
 ],
 "gaps": []
}
```

`NRS_484B_253_o2` — its duty: “shall yield the right-of-way” (characters 454–482)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `s8` “but such driver, having so yielded” composes `NRS_484B_253_o1` as compliance: its duty at characters 77–105; not accepted, never coded

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_253_o2",
 "law_refs": [
  "NRS-484B-253"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "The driver of a vehicle",
   "role": "condition"
  },
  {
   "id": "s2",
   "text": "within an intersection",
   "role": "condition"
  },
  {
   "id": "s3",
   "text": "intending to turn to the left",
   "role": "condition"
  },
  {
   "id": "s4",
   "text": "shall yield the right-of-way",
   "role": "sibling"
  },
  {
   "id": "s5",
   "text": "to any vehicle approaching from the opposite direction",
   "role": "sibling"
  },
  {
   "id": "s6",
   "text": "which is within the intersection",
   "role": "sibling"
  },
  {
   "id": "s7",
   "text": "or so close thereto as to constitute an immediate hazard,",
   "role": "sibling"
  },
  {
   "id": "s8",
   "text": "but such driver, having so yielded",
   "role": "condition"
  },
  {
   "id": "s9",
   "text": "and having given a signal",
   "role": "condition"
  },
  {
   "id": "s10",
   "text": "when and as required,",
   "role": "reference"
  },
  {
   "id": "s11",
   "text": "may make such left turn",
   "role": "condition"
  },
  {
   "id": "s12",
   "text": "and the drivers of all other vehicles",
   "role": "subject"
  },
  {
   "id": "s13",
   "text": "approaching the intersection from the opposite direction",
   "role": "trigger"
  },
  {
   "id": "s14",
   "text": "shall yield the right-of-way",
   "role": "obligation"
  },
  {
   "id": "s15",
   "text": "to the vehicle making the left turn.",
   "role": "condition"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "The turning vehicle y is of the admitted aggregate DEF-NRS-484A-320::vehicle; 'the driver' is read through its controlled motion."
  },
  {
   "span": "s2",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [],
   "justification": "'within an intersection': rel.occupies 'a road user's footprint overlaps a lane / region' of y and the st.intersection x approaches."
  },
  {
   "span": "s9",
   "atoms": [
    "sig.turn_indicator",
    "sig.hand_signal",
    "rel.occupies",
    "st.travel_region",
    "st.intersection"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "'having given a signal': sig.turn_indicator state left ('the signal that precedes a manoeuvre') or sig.hand_signal meaning left ('a driver's or rider's arm signal'), at some observation of y's continuous presence on its approach carrier (the one it entered through, drv.position.entered_via) or in the intersection up to now. Neither is a stand-in for the turn itself, which s11 reads."
  },
  {
   "span": "s11",
   "atoms": [
    "kin.yaw_rate",
    "kin.speed",
    "rel.occupies"
   ],
   "derived": [
    "drv.motion.turning_left",
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "'may make such left turn': y is making it, turning left now (drv.motion.turning_left: moving, kin.yaw_rate left positive above resolution) or having turned left since entering the intersection by at least the turn recognition angle (drv.motion.heading_change_since_entry)."
  },
  {
   "span": "s12",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'the drivers of all other vehicles': x, any vehicle of the admitted aggregate other than the turning one, read through its controlled motion."
  },
  {
   "span": "s13",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [
    "drv.motion.entering_region",
    "drv.road.opposed_directions",
    "drv.position.entered_via"
   ],
   "justification": "'approaching the intersection': x occupies an approach carrier c (st.lane_enters) and its yield is decided at its entry (drv.motion.entering_region). 'from the opposite direction' relative to the turning vehicle: c and the carrier y entered through (drv.position.entered_via) have opposed designated directions (drv.road.opposed_directions), as rel.oncoming's 'not a stand-in' clause directs."
  },
  {
   "span": "s14",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "'shall yield the right-of-way' (DEF-NRS-484A-210): x does not enter the intersection while the turning vehicle is owed precedence."
  },
  {
   "span": "s15",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [],
   "justification": "'the vehicle making the left turn': the vehicle y (admitted aggregate) in the intersection that s11 reads as making the turn."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [
  {
   "span": "s3",
   "id": "int.left_turn",
   "meaning": "The source's current plan for the road user includes a left turn at the target region."
  }
 ],
 "compositions": [
  {
   "span": "s8",
   "rule": "NRS_484B_253_o1",
   "map": {
    "x": "y"
   },
   "as": "compliance"
  }
 ],
 "residues": [
  {
   "span": "s10",
   "why": "'when and as required' refers to the signalling requirements of a law outside this corpus (no bracketed id resolves it); the signal itself is read on s9."
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "x is a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) and enters intersection i (st.intersection) at this observation (drv.motion.entering_region x i) from an approach carrier c it occupies (st.travel_region, st.lane_enters c i).",
 "obligation": "At this entry no vehicle y other than x (ru.aggregate=DEF-NRS-484A-320::vehicle) is making a left turn in i under the words' conditions: y occupies i, having entered it through a carrier c2 (drv.position.entered_via y i c2, st.lane_enters c2 i) with drv.road.opposed_directions c c2 (p.opposed_carriers_cosine); the source declares int.left_turn y i; y is making the turn (drv.motion.turning_left y with p.speed_resolution and p.yaw_rate_resolution, or drv.motion.heading_change_since_entry y i with step p.heading_since_step_carla_scene_graph at least p.turn_recognition_angle); y has so yielded (rule NRS_484B_253_o1 {x -> y} complied with at every observation since y's current overlap of i began); and y has given a signal (sig.turn_indicator left, or sig.hand_signal left) at some observation since y last came onto c2 while it has stayed on c2 or in i since.",
 "params": [
  "p.opposed_carriers_cosine",
  "p.speed_resolution",
  "p.yaw_rate_resolution",
  "p.heading_since_step_carla_scene_graph",
  "p.turn_recognition_angle"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "'the driver' of the turning vehicle is read through its controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s12",
   "why": "'the drivers' are read through the vehicles' controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s14",
   "why": "The yield is judged at x's entry into the intersection while the turning vehicle is in it.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "y entered i through c2 with sig.turn_indicator left on c2, int.left_turn y i declared, waited in i while no opposing vehicle was near, and now turns left (kin.yaw_rate 15 deg/s, 4 m/s); x on c (opposed to c2) enters i."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x waits on c and enters i after y has left it, as the only road user in i."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x drives along a road segment and enters no intersection."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but neither sig.turn_indicator nor sig.hand_signal of y is observed.",
   "masked": [
    "sig.turn_indicator",
    "sig.hand_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "compliant",
   "narrative": "As forbid, but y's sig.turn_indicator is off and sig.hand_signal no_signal at every observation: y gave no signal, and x owes it no precedence under this duty."
  },
  {
   "name": "branch_2",
   "expected": "compliant",
   "narrative": "As forbid, but y began its turn while x was 15 m from i at 15 m/s on c, so NRS_484B_253_o1 was not complied with by y: y has not so yielded."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.opposed_carriers_cosine",
   "unit": "ratio",
   "value": 0.7,
   "convention": "Direction tolerance: minus the cosine of the narrowest angle between two carriers' designated directions that counts as opposite directions; carriers within about 45 degrees of exactly opposed count.",
   "source": "Junction geometry: approaches meeting at an intersection skewed by up to 45 degrees (AASHTO Green Book ch. 9)"
  },
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "carla_scene_graph acquisition standard: speed resolution of the recorded kinematics"
  },
  {
   "name": "p.yaw_rate_resolution",
   "unit": "deg/s",
   "value": 2.0,
   "convention": "Sensor resolution: the smallest yaw rate the acquisition standard separates from a straight path; a yaw rate at or below it counts as no heading change.",
   "source": "carla_scene_graph acquisition standard: yaw-rate resolution of the recorded kinematics"
  },
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "Geometry of a right-angled junction (AASHTO Green Book ch. 9 intersection angles)"
  }
 ],
 "gaps": []
}
```

### `NRS-484B-257-1`: the plan of iteration 1 and what followed

`NRS_484B_257_1_o1` — its duty: “shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection” (characters 150–353)

- iteration 1: planned; validator accept; coded: gate OK (18 witnesses, 23 names, composes nothing)
- state: accepted
- composes no rule

The record, as accepted:

```json
{
 "node_id": "NRS_484B_257_1_o1",
 "law_refs": [
  "NRS-484B-257-1"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Except when traffic is being controlled by a police officer or a traffic-control signal:",
   "role": "exception"
  },
  {
   "id": "s2",
   "text": "When proper signs have been erected,",
   "role": "condition"
  },
  {
   "id": "s3",
   "text": "the driver of a vehicle",
   "role": "subject"
  },
  {
   "id": "s4",
   "text": "shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection",
   "role": "obligation"
  },
  {
   "id": "s8",
   "text": "where the driver has a view of approaching traffic on the through highway.",
   "role": "standard"
  },
  {
   "id": "s9",
   "text": "After having stopped or, in the event of a yield sign, slowed or stopped,",
   "role": "sibling"
  },
  {
   "id": "s10",
   "text": "the driver shall yield the right-of-way",
   "role": "sibling"
  },
  {
   "id": "s11",
   "text": "to other vehicles which have entered the intersection from such through highway",
   "role": "sibling"
  },
  {
   "id": "s12",
   "text": "or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "dev.human_direction",
    "dev.traffic_signal",
    "dev.inoperative",
    "dev.governs",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "'traffic' is the admitted aggregate DEF-NRS-484A-285::traffic; the traffic whose control matters is the subject's own flow, so x is read as a member. 'being controlled by a police officer' is dev.human_direction 'a person directing traffic' with role police_officer (DEF-NRS-484A-180 'every officer authorized to direct or regulate traffic') governing the intersection or x's approach carrier (dev.governs); 'or a traffic-control signal' is a dev.traffic_signal governing them that is not dev.inoperative ('showing no valid indication'): a dark signal controls nothing, and NRS 484B.250(4) then governs."
  },
  {
   "span": "s2",
   "atoms": [
    "dev.stop_sign",
    "dev.yield_sign",
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "'proper signs' are dev.stop_sign ('regulatory sign requiring a full halt') or dev.yield_sign ('regulatory sign requiring yielding without a mandatory halt') governing (dev.governs) x's approach carrier c (rel.occupies, st.lane_enters c i) or the intersection; the duty is owed on the approach to x's entry into the intersection (drv.motion.entering_region)."
  },
  {
   "span": "s3",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'vehicle' is the admitted aggregate DEF-NRS-484A-320::vehicle; 'the driver' is read through its controlled motion."
  },
  {
   "span": "s4",
   "atoms": [
    "kin.speed",
    "kin.velocity",
    "kin.heading",
    "kin.accel_longitudinal",
    "st.stop_line",
    "st.entrance_of",
    "st.lane_enters",
    "st.travel_region",
    "st.region_geometry",
    "prim.region_offset_along",
    "st.crosswalk",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.halted",
    "drv.motion.slowing"
   ],
   "justification": "'stop' (required: DEF-NRS-484A-255 'complete cessation from movement') is drv.motion.halted; 'or yield' at a yield sign is, by the words of the next sentence ('in the event of a yield sign, slowed or stopped'), a halt or slowing (drv.motion.slowing: forward motion with kin.accel_longitudinal below minus the resolution); kin.accel_longitudinal is not a stand-in for speed, and both are read. The places are read as in NRS_484B_250_4_o1: st.stop_line recorded by st.entrance_of as marking x's approach carrier (st.lane_enters, st.travel_region), nearness by st.region_geometry, side by prim.region_offset_along along the carrier's direction; else the st.crosswalk st.entrance_of records as marking that carrier, with the halt's footprint not overlapping it (rel.occupies); else a halt with the footprint outside the st.intersection."
  }
 ],
 "operationalizations": [
  {
   "span": "s8",
   "standard": "a view of approaching traffic on the through highway: how much of the through highway must be in view",
   "concepts": [
    "st.sight_along_way",
    "st.highway",
    "st.on_way"
   ],
   "params": [
    "p.intersection_sight_distance"
   ],
   "convention": "Intersection sight distance for a stop- or yield-controlled approach (AASHTO Green Book cases B and C): from the place of the act, the through highway (a st.highway on which the intersection lies, st.on_way, and the subject's approach carrier does not) is in view for at least p.intersection_sight_distance (st.sight_along_way, the smaller of its two directions); not a stand-in for whether an actual road user is seen.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "x is a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) and enters intersection i (st.intersection) at this observation (drv.motion.entering_region x i) through an approach carrier c it occupies (st.travel_region, st.lane_enters c i); a dev.stop_sign or dev.yield_sign governs c or i (dev.governs) at this observation; and traffic is not being controlled by a police officer or a traffic-control signal: x being a member of traffic (ru.aggregate=DEF-NRS-484A-285::traffic), no dev.human_direction with role police_officer and no dev.traffic_signal that is not dev.inoperative governs c or i at this observation. Where x occupies several carriers entering i and the verdict differs between them, which governs is unknown.",
 "obligation": "Act: where a dev.stop_sign governs c or i, x halted (drv.motion.halted x with p.speed_resolution) at the place; where only a dev.yield_sign governs, x halted at the place or was slowing (drv.motion.slowing x with p.speed_resolution and p.deceleration_resolution) at some observation of the approach before passing the place (before the place is behind x along c by prim.region_offset_along; for place (3), before x enters i). Place, in the words' order: (1) where a stop line s (st.stop_line) is recorded as marking c (st.entrance_of s c): at s, x's body within p.stop_point_tolerance of s (st_region_geometry_distance) and s not behind x along c (prim.region_offset_along x s c at least zero); (2) where the source observes that no stop line marks c and a crosswalk w is recorded as marking c (st.entrance_of w c): before entering w, x's footprint not overlapping w, within p.stop_point_tolerance of w and w ahead along c; (3) where the source observes that neither marks c: x's footprint outside i, within p.stop_point_tolerance of i, or farther upstream where a highway h on which i lies and c does not (st.on_way i h; st.on_way c h false) is in view from x for at least p.intersection_sight_distance (st_sight_along_way x h). History bound (the approach convention): the search runs back from this entry to the approach start, the last observation before the entry at which x, on c, is outside the governing place's stopping zone upstream (not on it, short of it along c, farther than p.stop_point_tolerance), or to x's previous entry into i, whichever is later; the act found there meets the duty, reaching either end without it violates it, reaching neither leaves it unknown. An act before the previous entry into i never counts; an observed exit from the stopping zone upstream begins a new approach; crossing the mark, a change of carrier, a lateral move, a reverse within the zone and speed noise begin none. Missing evidence: whether this is an entry through c is unknown where the observation before it does not show x on a mapped carrier; a mark whose association with c is unobserved governs unknown; where the lists are observed and exclude c, the next place governs; a recorded act at a place known to govern decides compliance whatever else is missing.",
 "params": [
  "p.speed_resolution",
  "p.deceleration_resolution",
  "p.stop_point_tolerance",
  "p.intersection_sight_distance"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "'traffic is being controlled' is read as control of x's own approach or of the intersection it enters, x being a member of the traffic aggregate; the officer's role and the signal's presence are read as their official status.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s2",
   "why": "'proper signs' are read through the presence of a stop or yield sign governing the approach or the intersection.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s3",
   "why": "'the driver' is read through the vehicle's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s4",
   "why": "At a yield sign the act owed at the place is read as the 'slowed or stopped' the next sentence names; yielding to traffic is the other node's duty.",
   "kind": "reading"
  },
  {
   "span": "s4",
   "why": "'clearly marked' is read through the represented stop line.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s4",
   "why": "A halt within p.stop_point_tolerance of the intersection counts, and one farther upstream counts where the view bound holds; that no nearer point with the view existed is not checked.",
   "kind": "reading"
  },
  {
   "span": "s8",
   "why": "'the through highway' is read as a highway the intersection lies on that the subject's signed approach carrier does not lie on; its designation is presumed from the sign on the subject's approach.",
   "kind": "observable_reading",
   "category": "status"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "dev.stop_sign governs lane c (st.lane_enters c i); stop line s marks c; no officer and no signal. x is first observed 80 m upstream at 12 m/s, never falls to the speed resolution and enters i."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "As forbid, but x halts with its body 0.5 m short of s, then enters i."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "No sign governs c or i; x enters i without halting."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but dev.governs is not observed for the stop sign.",
   "masked": [
    "dev.governs"
   ]
  },
  {
   "name": "branch_1",
   "expected": "compliant",
   "narrative": "dev.yield_sign governs c; x, moving forward at 10 m/s, decelerates at 2 m/s² 30 m upstream of s and enters i at 4 m/s without halting."
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "As forbid, but a dev.human_direction with role police_officer governs i while x rolls through."
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "As forbid, but the recording begins with x 1.5 m short of s at 1 m/s; no halt is recorded before x enters i.",
   "boundary": "x's approach start on c, the last observation outside the stopping zone upstream of s, lies before the recording."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "carla_scene_graph acquisition standard: speed resolution of the recorded kinematics"
  },
  {
   "name": "p.deceleration_resolution",
   "unit": "m/s^2",
   "value": 0.3,
   "convention": "Sensor resolution: the smallest longitudinal deceleration the acquisition standard separates from steady speed; a deceleration at or below it counts as no slowing.",
   "source": "carla_scene_graph acquisition standard: acceleration resolution of the recorded kinematics"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "Stop-point tolerance: the largest ground distance between a halted body and the line, crossing or intersection edge at which the halt counts as made at that place; a body farther upstream is outside the stopping zone.",
   "source": "MUTCD 2009 section 3B.16 stop-line placement (at least 4 ft ahead of the crosswalk) and vehicle positioning variability at a stop"
  },
  {
   "name": "p.intersection_sight_distance",
   "unit": "m",
   "value": 100,
   "convention": "Intersection sight distance: the length of the crossing way, in the smaller of its two directions, that a driver halted on a stop-controlled approach must be able to see to judge a gap in approaching traffic.",
   "source": "AASHTO A Policy on Geometric Design of Highways and Streets (2018) section 9.5.3, case B departure sight triangles at a low urban design speed"
  }
 ],
 "gaps": [],
 "planned_on": {},
 "context": "c9c29d1263c61f5e048b3252"
}
```

It differs from the record planned in iteration 1 in: `context`, `planned_on`.

`NRS_484B_257_1_o2` — its duty: “the driver shall yield the right-of-way” (characters 503–542)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `s9` “After having stopped or, in the event of a yield sign, slowed or stopped,” composes `NRS_484B_257_1_o1` as compliance: its duty at characters 150–353; accepted

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_257_1_o2",
 "law_refs": [
  "NRS-484B-257-1"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "s1",
   "text": "Except when traffic is being controlled by a police officer or a traffic-control signal:",
   "role": "exception"
  },
  {
   "id": "s2",
   "text": "When proper signs have been erected,",
   "role": "condition"
  },
  {
   "id": "s3",
   "text": "the driver of a vehicle",
   "role": "subject"
  },
  {
   "id": "s4",
   "text": "shall stop or yield",
   "role": "sibling"
  },
  {
   "id": "s5",
   "text": "at a clearly marked stop line",
   "role": "sibling"
  },
  {
   "id": "s6",
   "text": "or, if there is none, before entering the crosswalk on the near side of the intersection",
   "role": "sibling"
  },
  {
   "id": "s7",
   "text": "or, if there is none, then at the point nearest the intersection",
   "role": "sibling"
  },
  {
   "id": "s8",
   "text": "where the driver has a view of approaching traffic on the through highway.",
   "role": "sibling"
  },
  {
   "id": "s9",
   "text": "After having stopped or, in the event of a yield sign, slowed or stopped,",
   "role": "condition"
  },
  {
   "id": "s10",
   "text": "the driver shall yield the right-of-way",
   "role": "obligation"
  },
  {
   "id": "s11",
   "text": "to other vehicles which have entered the intersection from such through highway",
   "role": "condition"
  },
  {
   "id": "s12",
   "text": "or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.",
   "role": "standard"
  }
 ],
 "elements": [
  {
   "span": "s1",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "dev.human_direction",
    "dev.traffic_signal",
    "dev.inoperative",
    "dev.governs",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [],
   "justification": "As in NRS_484B_257_1_o1: x as a member of the admitted traffic aggregate; a dev.human_direction with role police_officer, or a dev.traffic_signal not dev.inoperative, governing x's approach carrier or the intersection (dev.governs)."
  },
  {
   "span": "s2",
   "atoms": [
    "dev.stop_sign",
    "dev.yield_sign",
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "As in NRS_484B_257_1_o1: a dev.stop_sign or dev.yield_sign governing x's approach carrier or the intersection, at x's entry (drv.motion.entering_region)."
  },
  {
   "span": "s3",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "'vehicle' is the admitted aggregate; 'the driver' is read through its controlled motion."
  },
  {
   "span": "s10",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "'shall yield the right-of-way' (DEF-NRS-484A-210 'to proceed ... in preference to another vehicle'): x does not enter the intersection (drv.motion.entering_region over rel.occupies) while a through-highway vehicle is owed precedence."
  },
  {
   "span": "s11",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle",
    "rel.occupies",
    "st.intersection",
    "st.lane_enters",
    "st.travel_region",
    "st.on_way",
    "st.highway"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "'other vehicles' are the admitted aggregate. 'which have entered the intersection from such through highway': y occupies the intersection, having entered it through a carrier (drv.position.entered_via, st.lane_enters) that lies on the through highway (st.on_way 'the public way ... a structure region lies on', of kind st.highway) on which x's approach carrier does not lie."
  }
 ],
 "operationalizations": [
  {
   "span": "s12",
   "standard": "approaching so closely on the through highway as to constitute an immediate hazard during the time the driver is moving across or within the intersection",
   "concepts": [
    "st.region_geometry",
    "kin.speed",
    "rel.occupies",
    "st.lane_enters",
    "st.on_way",
    "st.highway"
   ],
   "params": [
    "p.immediate_hazard_gap"
   ],
   "convention": "Gap acceptance (HCM critical headway for a minor-street crossing or turn): a vehicle on an approach carrier of the intersection lying on the through highway (rel.occupies, st.lane_enters, st.on_way), outside the intersection, is an immediate hazard where its ground distance to the intersection (st.region_geometry) is at most its speed (kin.speed) times p.immediate_hazard_gap; the critical gap stands for the time the subject needs to move across or within the intersection, and the bound moves with the other vehicle's proximity and speed.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "s9",
   "rule": "NRS_484B_257_1_o1",
   "map": {
    "x": "x"
   },
   "as": "compliance"
  }
 ],
 "residues": [],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "As NRS_484B_257_1_o1: x is a vehicle entering intersection i at this observation (drv.motion.entering_region x i) through an approach carrier c it occupies (st.lane_enters c i); a dev.stop_sign or dev.yield_sign governs c or i; x, a member of traffic (ru.aggregate=DEF-NRS-484A-285::traffic), is not controlled by a dev.human_direction with role police_officer or a dev.traffic_signal that is not dev.inoperative governing c or i. And NRS_484B_257_1_o1 is complied with for x at this observation (rule NRS_484B_257_1_o1 {x -> x}): that rule being engaged at exactly this entry, its compliance is the fact the words refer to, that x stopped, or under a yield sign slowed or stopped, on this approach.",
 "obligation": "At this entry, for every highway h2 (st.highway) on which i lies and c does not (st.on_way i h2; st.on_way c h2 false), no vehicle y other than x (ru.aggregate=DEF-NRS-484A-320::vehicle) either (1) occupies i, having entered it through a carrier c2 that lies on h2 (drv.position.entered_via y i c2, st.lane_enters c2 i, st.on_way c2 h2), or (2) occupies an approach carrier c2 of i lying on h2 (rel.occupies y c2, st.lane_enters c2 i, st.on_way c2 h2), does not occupy i, and st_region_geometry_distance y i is at most kin_speed y times p.immediate_hazard_gap.",
 "params": [
  "p.immediate_hazard_gap"
 ],
 "narrowings": [
  {
   "span": "s1",
   "why": "Control of traffic is read as control of x's own approach or intersection; officer and signal presence are read as their status.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s2",
   "why": "'proper signs' are read through the presence of a stop or yield sign.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "s3",
   "why": "'the driver' is read through the vehicle's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "s10",
   "why": "The yield is judged at x's entry into the intersection.",
   "kind": "reading"
  },
  {
   "span": "s12",
   "why": "'during the time such driver is moving across or within the intersection' is read through the critical gap, not through a prediction of x's own crossing time; 'such through highway' is a highway the intersection lies on and x's signed approach does not.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "dev.stop_sign governs c; x halts at the stop line marking c, then enters i while vehicle y on approach carrier c2 of the crossing highway h2 is 25 m from i at 15 m/s."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "As forbid, but x enters i as the only road user in the scene."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "No sign governs c or i; x enters i."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "As forbid, but kin.speed is not observed.",
   "masked": [
    "kin.speed"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "x halts at its stop line and enters i while vehicle y, which entered i through c2 on h2, occupies i."
  },
  {
   "name": "branch_2",
   "expected": "not_applicable",
   "narrative": "As forbid, but x never halted or slowed on the approach (NRS_484B_257_1_o1 not complied with): this duty does not arise."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.immediate_hazard_gap",
   "unit": "s",
   "value": 4.1,
   "convention": "Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach, counts as an immediate hazard to a road user about to cross or join its path.",
   "source": "HCM 7th ed. Exhibit 20-11 base critical headway (major-street left turn)"
  }
 ],
 "gaps": []
}
```

### `NRS-484B-307-9b`: the plan of iteration 1 and what followed

`NRS_484B_307_9b_o1` — its duty: “(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;” (characters 296–552)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- composes no rule

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9b_o1",
 "law_refs": [
  "NRS-484B-307-9b"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "segmentation": [
  {
   "id": "c1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "c2",
   "text": "A person driving a motorcycle, moped or",
   "role": "subject"
  },
  {
   "id": "c3",
   "text": "trimobile",
   "role": "subject"
  },
  {
   "id": "c4",
   "text": "or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "c5",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "c6",
   "text": "may proceed straight through or turn in the direction opposite that indicated by the green turn arrow",
   "role": "trigger"
  },
  {
   "id": "c7",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "c8",
   "text": "(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;",
   "role": "obligation"
  },
  {
   "id": "c9",
   "text": "(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;",
   "role": "sibling"
  },
  {
   "id": "c11",
   "text": "(3) No other device at the place prohibits the turn, if applicable;",
   "role": "sibling"
  },
  {
   "id": "c12",
   "text": "and",
   "role": "boilerplate"
  },
  {
   "id": "c13",
   "text": "(4) The person yields the right-of-way",
   "role": "sibling"
  },
  {
   "id": "c15",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "c1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"a signal head; state ∈ {... circular_red, ... green_arrow(dir) ...}\" and \"several states may be displayed at once\": a steady red with a green turn arrow is circular_red displayed together with green_arrow(dir), dir left or right. No 'not a stand-in' clause applies."
  },
  {
   "span": "c2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-135::motorcycle (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\") and DEF-NRS-484A-125::moped (\"a motor-driven scooter, motor-driven cycle or similar vehicle\"), claimed by id and never expanded. 'A person driving' names who controls the machine, read through its controlled motion (observable_reading agency)."
  },
  {
   "span": "c4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-025::bicycle (\"a device propelled by human power upon which a person may ride\"), DEF-NRS-484B-017::electric_bicycle (\"a device upon which a person may ride, having two or three wheels\") and DEF-NRS-484B-018::electric_scooter (\"a vehicle with handlebars and an electric motor\"). 'riding' is read through the machine's controlled motion (observable_reading agency)."
  },
  {
   "span": "c5",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal is the signal governing the approach the person enters through: dev.governs (\"the travel regions whose traffic the device controls ... or an intersection\") on the carrier c with st.lane_enters(c, i) (\"the intersection region a directed approach carrier runs into at its entrance end\") that x came in through (drv.position.entered_via: \"x is inside region r on its current entry and came in through region c\"), or on i itself. dev.governs is 'not a stand-in' for a position and is not used as one."
  },
  {
   "span": "c6",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "kin.yaw_rate"
   ],
   "derived": [
    "drv.motion.entering_region",
    "drv.motion.leaving_region",
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "Proceeding through the intersection is the passage from x's entry (drv.motion.entering_region: \"its footprint overlaps r (rel.occupies) at the observation and did not at the observation before\") to its leaving (drv.motion.leaving_region). Straight through or a turn opposite the arrow is read at the leaving by drv.motion.heading_change_since_entry (\"The signed heading change of road user x since its footprint last began to overlap region r, in degrees, left positive\", from kin.yaw_rate): straight where its size stays below the turn recognition angle, opposite where it reaches that angle on the side away from the arrow."
  },
  {
   "span": "c8",
   "atoms": [
    "kin.speed",
    "prim.region_offset_along",
    "rel.occupies",
    "st.crosswalk",
    "st.stop_line",
    "st.entrance_of",
    "st.lane_enters",
    "st.region_geometry",
    "st.intersection",
    "st.travel_region"
   ],
   "derived": [
    "drv.motion.halted"
   ],
   "justification": "'stops', a stop required, takes DEF-NRS-484A-255 (\"complete cessation from movement\"): drv.motion.halted (kin.speed at or below the resolution). The places: the pavement marking indicating where the stop must be made is a st.stop_line (\"the transverse line marking where vehicles halt for a device\") recorded as marking x's approach carrier c (st.entrance_of: \"exactly that carrier's entrance, the line or crossing a vehicle approaching through that carrier halts at or before\"); the crosswalk on the nearest side is a st.crosswalk recorded as marking c; failing both, the entrance end of c at the st.intersection (st.lane_enters). Before entering is read along c's designated direction (prim.region_offset_along) with the distance to the place (st.region_geometry) within the stop-point tolerance, and the footprint not yet overlapping the crosswalk or the intersection (rel.occupies). st.intersection is 'not a stand-in' for a crosswalk or a stop line: each place is read on its own."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [
  {
   "span": "c3",
   "why": "Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2, whose definition takes \"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\": the duty is the same whether or not the word is read.",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "x carries ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle or ru.aggregate=DEF-NRS-484B-018::electric_scooter; at the observation x leaves an intersection i (drv.motion.leaving_region(x, i)); at the observation of its latest entry into i (drv.motion.entering_region(x, i), read through a past operator) x came in through a carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)) and a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right; and at the leaving observation the heading change since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows a straight-through passage (its absolute value below p.turn_recognition_angle) or a turn opposite d (at most minus p.turn_recognition_angle where d is left, at least p.turn_recognition_angle where d is right).",
 "obligation": "A halt before the entry, searched in the past (the approach convention). Event: x's entry into i that the applicability names, made through carrier c (the carrier x occupied at the observation before the entry with st.lane_enters(c, i)). Place, in order: a stop line recorded as marking c (st.entrance_of(line, c)); where c's marks are observed and include no stop line, a crosswalk recorded as marking c; where neither is recorded for c, the entrance end of c at i. Act: an observation at which x is halted (drv.motion.halted with p.speed_resolution) while occupying c, its body within p.stop_point_tolerance of the place (st.region_geometry distance), not past it along c's designated direction (prim.region_offset_along of the place from x not negative), and its footprint overlapping neither i nor, where the place is a crosswalk, that crosswalk. Search: back from the entry, ending at the approach start (the last observation before the entry at which x, on c, is outside the place's stopping zone upstream: off the mark, short of it and farther from it than p.stop_point_tolerance) or at x's previous entry into i through the same place; nothing else ends it. Verdict: complied where the search finds the act; violated where it reaches either end without it; unknown only where it reaches neither (the recording begins inside the approach) or where c's association with a mark, c's direction or x's place relative to the mark is unobserved and the verdict turns on it. Judged at the leaving observation, the search running from the entry.",
 "params": [
  "p.speed_resolution",
  "p.stop_point_tolerance",
  "p.turn_recognition_angle",
  "p.heading_since_step_carla_scene_graph"
 ],
 "narrowings": [
  {
   "span": "c2",
   "why": "'A person driving' is read through the machine's controlled motion: the duty binds the motorcycle's or moped's conduct whoever controls it.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c4",
   "why": "'riding' is read through the machine's controlled motion: the duty binds the conduct of the bicycle, electric bicycle or electric scooter whoever rides it.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c8",
   "why": "The places are read in the order the words give them under the ontology's approach convention: the pavement marking indicating where the stop must be made is the stop line marking the approach; failing one, the crosswalk on the near side is the crosswalk marking the approach; failing both, the entrance of the intersection. A sign that indicates a stopping point without a line is not carried by any atom and is not read.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motorcycle) approaches i on lane c, which a stop line marks (st.entrance_of); it never halts on c, enters i while s governing c displays circular_red with green_arrow(left), and leaves straight through. The search back from the entry reaches the approach start without a halt."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x (ru.bicycle) halts on c within p.stop_point_tolerance of the stop line marking c, short of it, then enters i under circular_red with green_arrow(left) and leaves straight through."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x (ru.motorcycle) enters i while s displays circular_green and leaves straight through."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x halts on c short of a stop line within p.stop_point_tolerance and then goes straight through under circular_red with green_arrow(left), but the source does not observe which carriers the line marks, so whether the halt was at the governing place is unknown.",
   "masked": [
    "st.entrance_of"
   ]
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "x's recording begins with x already on c inside the stopping zone of the stop line, rolling slowly; no halt is recorded before it enters i under circular_red with green_arrow(left) and leaves straight through. The search reaches neither the approach start nor a previous entry.",
   "boundary": "the start of x's approach on c, outside the stop line's stopping zone upstream, which lies before the recording"
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "speed resolution of the carla_scene_graph acquisition standard"
  },
  {
   "name": "p.stop_point_tolerance",
   "unit": "m",
   "value": 2.0,
   "convention": "Stop-point tolerance: the largest ground distance between a halted body and the line, crossing or intersection edge at which the halt counts as made at that place; a body farther upstream is outside the stopping zone.",
   "source": "MUTCD stop-line placement practice"
  },
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "intersection geometry design conventions (AASHTO Green Book)"
  }
 ],
 "gaps": []
}
```

`NRS_484B_307_9b_o2` — its duty: “(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;” (characters 553–871)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- composes no rule

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9b_o2",
 "law_refs": [
  "NRS-484B-307-9b"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "segmentation": [
  {
   "id": "c1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "c2",
   "text": "A person driving a motorcycle, moped or",
   "role": "subject"
  },
  {
   "id": "c3",
   "text": "trimobile",
   "role": "subject"
  },
  {
   "id": "c4",
   "text": "or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "c5",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "c6",
   "text": "may proceed straight through or turn in the direction opposite that indicated by the green turn arrow",
   "role": "trigger"
  },
  {
   "id": "c7",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "c8",
   "text": "(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;",
   "role": "sibling"
  },
  {
   "id": "c9",
   "text": "(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;",
   "role": "obligation"
  },
  {
   "id": "c11",
   "text": "(3) No other device at the place prohibits the turn, if applicable;",
   "role": "sibling"
  },
  {
   "id": "c12",
   "text": "and",
   "role": "boilerplate"
  },
  {
   "id": "c13",
   "text": "(4) The person yields the right-of-way",
   "role": "sibling"
  },
  {
   "id": "c15",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "c1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"a signal head; state ∈ {... circular_red, ... green_arrow(dir) ...}\" and \"several states may be displayed at once\": a steady red with a green turn arrow is circular_red displayed together with green_arrow(dir), dir left or right."
  },
  {
   "span": "c2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-135::motorcycle (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\") and DEF-NRS-484A-125::moped (\"a motor-driven scooter, motor-driven cycle or similar vehicle\"), claimed by id. 'A person driving' is read through the machine's controlled motion."
  },
  {
   "span": "c4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-025::bicycle (\"a device propelled by human power upon which a person may ride\"), DEF-NRS-484B-017::electric_bicycle (\"a device upon which a person may ride, having two or three wheels\") and DEF-NRS-484B-018::electric_scooter (\"a vehicle with handlebars and an electric motor\")."
  },
  {
   "span": "c5",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal: dev.governs (\"the travel regions whose traffic the device controls ... or an intersection\") on the carrier c with st.lane_enters(c, i) that x came in through (drv.position.entered_via: \"came in through region c\"), or on i itself."
  },
  {
   "span": "c6",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "kin.yaw_rate"
   ],
   "derived": [
    "drv.motion.entering_region",
    "drv.motion.leaving_region",
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "The passage from x's entry into i (drv.motion.entering_region) to its leaving (drv.motion.leaving_region); straight through or opposite the arrow is read at the leaving by drv.motion.heading_change_since_entry (\"in degrees, left positive\", from kin.yaw_rate) against the turn recognition angle."
  },
  {
   "span": "c9",
   "atoms": [
    "dev.traffic_signal",
    "dev.governs",
    "kin.speed",
    "rel.occupies",
    "st.lane_enters",
    "st.travel_region"
   ],
   "derived": [
    "drv.motion.halted"
   ],
   "justification": "Waiting is remaining halted (drv.motion.halted: \"complete cessation from movement\", kin.speed at or below the resolution) on the approach carrier c (rel.occupies, st.lane_enters). The applicable official traffic-control device is the signal s facing x (dev.governs on c or i; its presence is the evidence of its official status). A complete cycle of its lights is the span between two successive rises of the same display; the rises of s's circular_red with green_arrow(d) display (dev.traffic_signal) are counted from the start of the wait, the first rise opening the first complete cycle, so two complete cycles need more rises than the literal. That the signal does not change because it malfunctions or fails to detect x is read through its outcome on the head: during the wait s never displays an indication permitting x's movement, neither circular_green nor a green_arrow in the direction of x's movement (dev.traffic_signal state). Why the head stayed as it was (a fault, a detector) is not observable."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [
  {
   "span": "c3",
   "why": "Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read.",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "As NRS_484B_307_9b_o1: x carries one of the five aggregates of spans c2 and c4; at the observation x leaves intersection i (drv.motion.leaving_region(x, i)); at its latest entry into i (read through a past operator) it came in through carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)) while a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right; and at the leaving the heading change since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows a straight-through passage (absolute value below p.turn_recognition_angle) or a turn opposite d.",
 "obligation": "Read at the observation of x's latest entry into i, through a past operator from the leaving observation. Let the wait be the latest run of consecutive observations before the entry at which x is halted (drv.motion.halted with p.speed_resolution) while occupying c. Counted from the start of that run (Formula.count with edge: s displays circular_red together with green_arrow(d) and did not at the observation before; since: x halted while occupying c), the rises of that display number more than the literal of span c9 (comparison gt): the first rise counted opens the first complete cycle and each later one closes a cycle. And at no observation of the wait does s display circular_green, or green_arrow in the direction of x's movement (straight for a straight-through passage, the side of the turn for a turn). Where the wait began before the recording (x halted on c at its first observation), the count is unknown, not a violation.",
 "params": [
  "p.speed_resolution",
  "p.turn_recognition_angle",
  "p.heading_since_step_carla_scene_graph"
 ],
 "narrowings": [
  {
   "span": "c2",
   "why": "'A person driving' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c4",
   "why": "'riding' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c9",
   "why": "'the applicable official traffic-control device' is the signal head governing the person's approach; its presence on the road is read as the evidence of its official status.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "c9",
   "why": "'does not change because of a malfunction or because the signal failed to detect the presence' turns on the device's detection, which is not observable; it is read through the outcome the condition secures: throughout the wait the head never displays an indication that permits the person's movement. A wait the signal ends by serving the person is not a failure to detect, and the permission then does not cover a later entry against the red.",
   "kind": "observable_reading",
   "category": "perception"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motorcycle) halts on c; s governing c rises to circular_red with green_arrow(left) once during the wait; x then enters i under that display and leaves straight through: the rises counted do not exceed the literal."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x (ru.bicycle) halts on c and stays halted while s's circular_red with green_arrow(left) display rises more times than the literal, never showing circular_green or green_arrow(straight); x then enters under the display and leaves straight through."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x is a ru.motor_vehicle that carries none of the five aggregates (a passenger car); it waits and then goes straight through under circular_red with green_arrow(left)."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x halts on c, waits and then goes straight through, but the source does not observe s's state during the wait.",
   "masked": [
    "dev.traffic_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "violated",
   "narrative": "x halts on c through more rises of circular_red with green_arrow(left) than the literal, but during the wait s also displays circular_green for c, which x lets pass; x later enters straight through under the red with the arrow: the signal did change, so the condition fails."
  },
  {
   "name": "history_boundary",
   "expected": "unknown",
   "narrative": "x's recording begins with x already halted on c; a single rise of circular_red with green_arrow(left) is recorded before x enters i straight through, and the start of the wait is not recorded.",
   "boundary": "the start of x's halt on c, which lies before the recording"
  }
 ],
 "literals": [
  {
   "span": "c9",
   "text": "two",
   "value": 2,
   "unit": "count"
  }
 ],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "speed resolution of the carla_scene_graph acquisition standard"
  },
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "intersection geometry design conventions (AASHTO Green Book)"
  }
 ],
 "gaps": []
}
```

`NRS_484B_307_9b_o3` — its duty: “(3) No other device at the place prohibits the turn, if applicable;” (characters 872–939)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- composes no rule

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9b_o3",
 "law_refs": [
  "NRS-484B-307-9b"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "segmentation": [
  {
   "id": "c1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "c2",
   "text": "A person driving a motorcycle, moped or",
   "role": "subject"
  },
  {
   "id": "c3",
   "text": "trimobile",
   "role": "subject"
  },
  {
   "id": "c4",
   "text": "or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "c5",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "c6",
   "text": "may proceed straight through or turn in the direction opposite that indicated by the green turn arrow",
   "role": "trigger"
  },
  {
   "id": "c7",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "c8",
   "text": "(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;",
   "role": "sibling"
  },
  {
   "id": "c9",
   "text": "(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;",
   "role": "sibling"
  },
  {
   "id": "c11",
   "text": "(3) No other device at the place prohibits the turn, if applicable;",
   "role": "obligation"
  },
  {
   "id": "c12",
   "text": "and",
   "role": "boilerplate"
  },
  {
   "id": "c13",
   "text": "(4) The person yields the right-of-way",
   "role": "sibling"
  },
  {
   "id": "c15",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "sibling"
  }
 ],
 "elements": [
  {
   "span": "c1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"several states may be displayed at once\": circular_red displayed together with green_arrow(dir), dir left or right."
  },
  {
   "span": "c2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-135::motorcycle (\"every motor vehicle equipped with a seat or saddle for the use of the driver\") and DEF-NRS-484A-125::moped (\"a motor-driven scooter, motor-driven cycle or similar vehicle\"), claimed by id."
  },
  {
   "span": "c4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-025::bicycle (\"a device propelled by human power upon which a person may ride\"), DEF-NRS-484B-017::electric_bicycle (\"a device upon which a person may ride, having two or three wheels\") and DEF-NRS-484B-018::electric_scooter (\"a vehicle with handlebars and an electric motor\")."
  },
  {
   "span": "c5",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal: dev.governs (\"the travel regions whose traffic the device controls ... or an intersection\") on the carrier c with st.lane_enters(c, i) that x came in through (drv.position.entered_via), or on i itself."
  },
  {
   "span": "c6",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "kin.yaw_rate"
   ],
   "derived": [
    "drv.motion.entering_region",
    "drv.motion.leaving_region",
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "The passage from x's entry into i to its leaving; straight through or opposite the arrow read at the leaving by drv.motion.heading_change_since_entry (\"in degrees, left positive\", from kin.yaw_rate) against the turn recognition angle."
  },
  {
   "span": "c11",
   "atoms": [
    "dev.regulatory_sign",
    "dev.traffic_signal",
    "dev.governs",
    "prim.conditions_hold",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection"
   ],
   "derived": [],
   "justification": "A device at the place that prohibits the turn: a dev.regulatory_sign (\"a point regulation by catalogue code\") of code no_left_turn for a left turn or no_right_turn for a right turn, whose structured conditions hold for x at the entry (prim.conditions_hold: \"the structured conditions of a device ... hold at the observation for a road user\"), or a traffic signal head displaying red_arrow(dir) in the turn's direction (dev.traffic_signal); either governing (dev.governs) the carrier c x entered through (st.lane_enters(c, i)) or the intersection i. 'if applicable': a straight-through passage makes no turn, and the condition is met. A prohibition sign is 'not a stand-in' for a manoeuvre: it is read as the condition it is."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [
  {
   "span": "c3",
   "why": "Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read.",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "As NRS_484B_307_9b_o1: x carries one of the five aggregates of spans c2 and c4; at the observation x leaves intersection i (drv.motion.leaving_region(x, i)); at its latest entry into i (read through a past operator) it came in through carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)) while a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right; and at the leaving the heading change since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows a straight-through passage (absolute value below p.turn_recognition_angle) or a turn opposite d.",
 "obligation": "Where the passage is a turn (the heading change since the entry at least p.turn_recognition_angle in absolute value; its sign gives the side): at the observation of x's entry into i (read through a past operator) no device governing c or i (dev.governs) prohibits a turn to that side: no dev.regulatory_sign of code no_left_turn (for a left turn) or no_right_turn (for a right turn) whose conditions hold for x there (prim.conditions_hold), and no traffic signal head displaying red_arrow toward that side. A straight-through passage meets this condition.",
 "params": [
  "p.turn_recognition_angle",
  "p.heading_since_step_carla_scene_graph"
 ],
 "narrowings": [
  {
   "span": "c2",
   "why": "'A person driving' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c4",
   "why": "'riding' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c11",
   "why": "'No other device at the place prohibits the turn' is read as the turn prohibitions the closed set carries: a no-left-turn or no-right-turn sign whose posted conditions hold, or a red arrow toward the turn's side, governing the approach or the intersection, at the entry.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motorcycle) enters i through c under circular_red with green_arrow(left) and turns right; a dev.regulatory_sign of code no_right_turn with empty conditions governs c."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x (ru.bicycle) enters i through c under circular_red with green_arrow(left) and turns right; no sign or red arrow prohibiting a right turn governs c or i."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x (ru.motorcycle) enters under circular_red with green_arrow(left) and turns left, the movement the arrow indicates."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x turns right under circular_red with green_arrow(left); a no_right_turn sign stands at the approach but the source does not observe which regions it governs.",
   "masked": [
    "dev.governs"
   ]
  },
  {
   "name": "branch_1",
   "expected": "compliant",
   "narrative": "x (ru.moped) enters under circular_red with green_arrow(left) and goes straight through while a no_right_turn sign governs c: no turn is made, so the condition is met."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "intersection geometry design conventions (AASHTO Green Book)"
  }
 ],
 "gaps": []
}
```

`NRS_484B_307_9b_o4` — its duty: “to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.” (characters 983–1089)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- composes no rule

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9b_o4",
 "law_refs": [
  "NRS-484B-307-9b"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-135::motorcycle",
   "ru.aggregate=DEF-NRS-484A-125::moped",
   "ru.aggregate=DEF-NRS-484A-025::bicycle",
   "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
   "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
  ]
 },
 "segmentation": [
  {
   "id": "c1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "c2",
   "text": "A person driving a motorcycle, moped or",
   "role": "subject"
  },
  {
   "id": "c3",
   "text": "trimobile",
   "role": "subject"
  },
  {
   "id": "c4",
   "text": "or riding a bicycle, an electric bicycle or an electric scooter",
   "role": "subject"
  },
  {
   "id": "c5",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "c6",
   "text": "may proceed straight through or turn in the direction opposite that indicated by the green turn arrow",
   "role": "trigger"
  },
  {
   "id": "c7",
   "text": "if:",
   "role": "boilerplate"
  },
  {
   "id": "c8",
   "text": "(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;",
   "role": "sibling"
  },
  {
   "id": "c9",
   "text": "(2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;",
   "role": "sibling"
  },
  {
   "id": "c11",
   "text": "(3) No other device at the place prohibits the turn, if applicable;",
   "role": "sibling"
  },
  {
   "id": "c12",
   "text": "and",
   "role": "boilerplate"
  },
  {
   "id": "c13",
   "text": "(4) The person yields the right-of-way",
   "role": "standard"
  },
  {
   "id": "c15",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "obligation"
  }
 ],
 "elements": [
  {
   "span": "c1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"several states may be displayed at once\": circular_red displayed together with green_arrow(dir), dir left or right."
  },
  {
   "span": "c2",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-135::motorcycle (\"every motor vehicle equipped with a seat or saddle for the use of the driver\") and DEF-NRS-484A-125::moped (\"a motor-driven scooter, motor-driven cycle or similar vehicle\"), claimed by id."
  },
  {
   "span": "c4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ],
   "derived": [],
   "justification": "The admitted aggregates DEF-NRS-484A-025::bicycle (\"a device propelled by human power upon which a person may ride\"), DEF-NRS-484B-017::electric_bicycle (\"a device upon which a person may ride, having two or three wheels\") and DEF-NRS-484B-018::electric_scooter (\"a vehicle with handlebars and an electric motor\")."
  },
  {
   "span": "c5",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal: dev.governs (\"the travel regions whose traffic the device controls ... or an intersection\") on the carrier c with st.lane_enters(c, i) that x came in through (drv.position.entered_via), or on i itself."
  },
  {
   "span": "c6",
   "atoms": [
    "rel.occupies",
    "st.intersection",
    "kin.yaw_rate"
   ],
   "derived": [
    "drv.motion.entering_region",
    "drv.motion.leaving_region",
    "drv.motion.heading_change_since_entry"
   ],
   "justification": "The passage from x's entry into i to its leaving; straight through or opposite the arrow read at the leaving by drv.motion.heading_change_since_entry (\"in degrees, left positive\", from kin.yaw_rate) against the turn recognition angle."
  },
  {
   "span": "c15",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.lane_enters",
    "st.intersection"
   ],
   "derived": [],
   "justification": "The parties yielded to. 'pedestrians' is the admitted aggregate DEF-NRS-484A-165::pedestrian (\"a person afoot, a person in a manual or motorized wheelchair\"); 'within an adjacent crosswalk' is the pedestrian's footprint overlapping (rel.occupies) a st.crosswalk recorded as marking the entrance of a carrier entering i (st.entrance_of: \"the carrier whose entrance into an intersection a stop line or a crosswalk marks\"; st.lane_enters). Distance is not used for adjacency. 'other traffic' is the admitted aggregate DEF-NRS-484A-285::traffic (\"pedestrians, ridden or herded animals, vehicles and other conveyances\"), every member other than x; 'using the intersection' is its footprint overlapping i (rel.occupies)."
  }
 ],
 "operationalizations": [
  {
   "span": "c13",
   "standard": "yields the right-of-way: not proceeding where the parties' \"direction, speed and proximity\" \"give rise to the danger of a crash unless one grants precedence to the other\" (DEF-NRS-484A-210)",
   "concepts": [
    "drv.motion.moving",
    "kin.speed",
    "prim.closest_approach_within",
    "prim.closest_approach_distance"
   ],
   "params": [
    "p.speed_resolution",
    "p.immediate_hazard_gap",
    "p.conflict_clearance"
   ],
   "convention": "Gap-acceptance and surrogate-safety convention: the person grants precedence where they do not proceed (not moving, drv.motion.moving) while a party is in danger of a crash with them; that danger is the predicted closest approach under constant velocities, within the critical gap, coming nearer than the conflict radius, so direction, speed and proximity all enter the prediction by their degree.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [],
 "residues": [
  {
   "span": "c3",
   "why": "Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read.",
   "scope": "none"
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-135::motorcycle",
    "ru.aggregate=DEF-NRS-484A-125::moped",
    "ru.aggregate=DEF-NRS-484A-025::bicycle",
    "ru.aggregate=DEF-NRS-484B-017::electric_bicycle",
    "ru.aggregate=DEF-NRS-484B-018::electric_scooter"
   ]
  }
 ],
 "applicability": "As NRS_484B_307_9b_o1: x carries one of the five aggregates of spans c2 and c4; at the observation x leaves intersection i (drv.motion.leaving_region(x, i)); at its latest entry into i (read through a past operator) it came in through carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)) while a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right; and at the leaving the heading change since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows a straight-through passage (absolute value below p.turn_recognition_angle) or a turn opposite d.",
 "obligation": "At every observation from that entry up to the leaving (read through a past operator from the leaving observation) at which x occupies i and is moving (drv.motion.moving with p.speed_resolution): for every road user p carrying ru.aggregate=DEF-NRS-484A-165::pedestrian that occupies a crosswalk w recorded as marking the entrance of some carrier c2 entering i (st.entrance_of(w, c2), st.lane_enters(c2, i)), and for every road user u other than x carrying ru.aggregate=DEF-NRS-484A-285::traffic that occupies i, it is not the case that x and that road user approach within p.immediate_hazard_gap (prim.closest_approach_within) with a closest-approach centre distance (prim.closest_approach_distance) below p.conflict_clearance.",
 "params": [
  "p.speed_resolution",
  "p.immediate_hazard_gap",
  "p.conflict_clearance",
  "p.turn_recognition_angle",
  "p.heading_since_step_carla_scene_graph"
 ],
 "narrowings": [
  {
   "span": "c2",
   "why": "'A person driving' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c4",
   "why": "'riding' is read through the machine's controlled motion.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "c15",
   "why": "'lawfully' is not read: every pedestrian in such a crosswalk and every other member of traffic inside the intersection is yielded to. 'an adjacent crosswalk' is read as a crosswalk recorded as marking the entrance of a carrier entering the intersection; a crosswalk across the exit of a one-way leg is not read.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motorcycle) goes straight through i under circular_red with green_arrow(left); while it moves inside i a ru.pedestrian occupies the crosswalk at the far side, marking the entrance of the opposing carrier, and prim.closest_approach_within holds over p.immediate_hazard_gap with a prim.closest_approach_distance below p.conflict_clearance."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x (ru.bicycle) goes straight through i under circular_red with green_arrow(left) with no other road user in the scene."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x (ru.motorcycle) enters i under circular_red with green_arrow(left) and turns left, the movement the arrow indicates."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x goes straight through i under circular_red with green_arrow(left) near a crossing pedestrian, but the source does not observe x's footprint overlap with i.",
   "masked": [
    "rel.occupies"
   ]
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "speed resolution of the carla_scene_graph acquisition standard"
  },
  {
   "name": "p.immediate_hazard_gap",
   "unit": "s",
   "value": 4.1,
   "convention": "Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach, counts as an immediate hazard to a road user about to cross or join its path.",
   "source": "Highway Capacity Manual critical-gap values"
  },
  {
   "name": "p.conflict_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "Conflict radius: the centre distance at predicted closest approach below which two road users' paths count as in conflict; about the half-length plus half-width of two passenger cars.",
   "source": "surrogate safety measures (closest-approach conflict radius)"
  },
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "intersection geometry design conventions (AASHTO Green Book)"
  }
 ],
 "gaps": []
}
```

### `NRS-484B-307-9a`: the plan of iteration 1 and what followed

`NRS_484B_307_9a_o1` — its duty: “only to make the movement indicated by the green turn arrow,” (characters 186–246)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `b2` “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],” composes `NRS_484B_307_9b_o1` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9a_o1",
 "law_refs": [
  "NRS-484B-307-9a"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-285::traffic"
  ]
 },
 "segmentation": [
  {
   "id": "b1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "b2",
   "text": "Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],",
   "role": "reference"
  },
  {
   "id": "b3",
   "text": "vehicular traffic",
   "role": "subject"
  },
  {
   "id": "b4",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "b5",
   "text": "may enter the intersection",
   "role": "trigger"
  },
  {
   "id": "b6",
   "text": "only to make the movement indicated by the green turn arrow,",
   "role": "obligation"
  },
  {
   "id": "b7",
   "text": "but must yield the right-of-way",
   "role": "sibling"
  },
  {
   "id": "b9",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "sibling"
  },
  {
   "id": "b11",
   "text": "Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.",
   "role": "definitional"
  }
 ],
 "elements": [
  {
   "span": "b1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"a signal head; state ∈ {circular_green, circular_yellow, circular_red, green_arrow(dir), ...}\" and \"several states may be displayed at once\": a steady red with a green turn arrow is a head displaying circular_red together with green_arrow(dir), dir left or right. 'The signal' is the head tied to the subject's approach in span b4. No 'not a stand-in' clause applies."
  },
  {
   "span": "b3",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'traffic' is the admitted aggregate DEF-NRS-484A-285::traffic (\"pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel\"). The law's own qualifier 'vehicular' leaves out the members that are not conveyances: pedestrians (\"a person afoot, a person in a manual or motorized wheelchair\", the admitted aggregate DEF-NRS-484A-165::pedestrian, which the rule requires the subject not to carry) and ridden or herded animals, for which the ontology has no class and nothing is read. Cycles and scooters stay in, as 'other conveyances'; paragraph (b) is written as an exception for them, which confirms they are vehicular traffic here."
  },
  {
   "span": "b4",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal is the signal governing the approach the subject enters through. dev.governs: \"the travel regions whose traffic the device controls ... or an intersection, read as control of the junction itself\"; st.lane_enters: \"the intersection region a directed approach carrier runs into at its entrance end\"; drv.position.entered_via (proposed this iteration): \"x is inside region r on its current entry and came in through region c\". The approach carrier c is the one x occupied at its entry with st.lane_enters(c, i); the signal governs c or i. dev.governs is 'not a stand-in' for a position and is not used as one."
  },
  {
   "span": "b5",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "drv.motion.entering_region (proposed this iteration): \"Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before\"; r is the st.intersection, \"the region where two roadways meet\"."
  },
  {
   "span": "b6",
   "atoms": [
    "kin.yaw_rate",
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.heading_change_since_entry",
    "drv.motion.leaving_region"
   ],
   "justification": "The movement made through the intersection is read at x's leaving of it (drv.motion.leaving_region: \"its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation\") by drv.motion.heading_change_since_entry: \"The signed heading change of road user x since its footprint last began to overlap region r, in degrees, left positive\", integrated from kin.yaw_rate. A left arrow indicates a change of at least the turn recognition angle to the left, a right arrow one to the right. The concept is 'not' a turn by itself; the rule compares it with its own bound."
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "b2",
   "rule": "NRS_484B_307_9b_o1",
   "map": {
    "x": "x"
   },
   "as": "exception"
  }
 ],
 "residues": [
  {
   "span": "b11",
   "why": "An advisory to drivers turning with the arrow about what opposing traffic faces at the same time; it permits, requires and forbids nothing, and no rule reads it."
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-285::traffic"
   ]
  }
 ],
 "applicability": "x carries ru.aggregate=DEF-NRS-484A-285::traffic and does not carry ru.aggregate=DEF-NRS-484A-165::pedestrian; at the observation x leaves an intersection i (drv.motion.leaving_region(x, i)); at the observation of its latest entry into i (drv.motion.entering_region(x, i), read through a past operator) x came in through a carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)), and a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right. Not engaged where NRS_484B_307_9b_o1 applies to x (composition, exception).",
 "obligation": "At that leaving observation the heading change of x since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows the movement a green arrow displayed at the entry indicates: at least p.turn_recognition_angle where d is left, at most minus p.turn_recognition_angle where d is right. Where arrows of both directions were displayed, the movement either indicates complies.",
 "params": [
  "p.turn_recognition_angle",
  "p.heading_since_step_carla_scene_graph"
 ],
 "narrowings": [
  {
   "span": "b6",
   "why": "The movement indicated by the arrow is read as the side and the size of the heading change through the intersection, judged when the subject leaves it: a passage turning at least the turn recognition angle toward the arrow's side complies, whatever lane it exits into.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motor_vehicle) enters intersection i from lane c that a signal s governs; s displays circular_red with green_arrow(left) at the entry; x crosses i and leaves it with a heading change since entry well inside p.turn_recognition_angle (straight through)."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The same entry under circular_red with green_arrow(left); x leaves i with a heading change since entry above p.turn_recognition_angle to the left."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "s displays circular_green at x's entry into i; x crosses straight through."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x enters i from lane c and crosses straight through, but the source does not observe s's state at the entry.",
   "masked": [
    "dev.traffic_signal"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "x is a ru.bicycle; it enters i under circular_red with green_arrow(left) and leaves straight through: paragraph (b) applies (NRS_484B_307_9b_o1 engaged), so this duty does not."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.turn_recognition_angle",
   "unit": "deg",
   "value": 45,
   "convention": "Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a straight crossing; half the right angle of a turn at a right-angled junction, leaving room for skewed junctions and lane offsets.",
   "source": "intersection geometry design conventions (AASHTO Green Book)"
  }
 ],
 "gaps": []
}
```

`NRS_484B_307_9a_o2` — its duty: “to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.” (characters 279–385)

- iteration 1: planned; validator accept; not coded
- iteration 2: validator accept; not coded
- iteration 3: validator accept; not coded
- state: not accepted, never coded
- span `b2` “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],” composes `NRS_484B_307_9b_o1` as exception: a node of another law, below

The record, as planned in iteration 1:

```json
{
 "node_id": "NRS_484B_307_9a_o2",
 "law_refs": [
  "NRS-484B-307-9a"
 ],
 "subject": {
  "binder": "x",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-285::traffic"
  ]
 },
 "segmentation": [
  {
   "id": "b1",
   "text": "Where the signal is a steady red with a green turn arrow:",
   "role": "trigger"
  },
  {
   "id": "b2",
   "text": "Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],",
   "role": "reference"
  },
  {
   "id": "b3",
   "text": "vehicular traffic",
   "role": "subject"
  },
  {
   "id": "b4",
   "text": "facing the signal",
   "role": "trigger"
  },
  {
   "id": "b5",
   "text": "may enter the intersection",
   "role": "trigger"
  },
  {
   "id": "b6",
   "text": "only to make the movement indicated by the green turn arrow,",
   "role": "sibling"
  },
  {
   "id": "b7",
   "text": "but must yield the right-of-way",
   "role": "standard"
  },
  {
   "id": "b9",
   "text": "to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.",
   "role": "obligation"
  },
  {
   "id": "b11",
   "text": "Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.",
   "role": "definitional"
  }
 ],
 "elements": [
  {
   "span": "b1",
   "atoms": [
    "dev.traffic_signal"
   ],
   "derived": [],
   "justification": "dev.traffic_signal: \"a signal head; state ∈ {circular_green, circular_yellow, circular_red, green_arrow(dir), ...}\" and \"several states may be displayed at once\": a steady red with a green turn arrow is a head displaying circular_red together with green_arrow(dir), dir left or right. No 'not a stand-in' clause applies."
  },
  {
   "span": "b3",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "ru.aggregate=DEF-NRS-484A-165::pedestrian"
   ],
   "derived": [],
   "justification": "'traffic' is the admitted aggregate DEF-NRS-484A-285::traffic (\"pedestrians, ridden or herded animals, vehicles and other conveyances\"). The qualifier 'vehicular' leaves out pedestrians (DEF-NRS-484A-165::pedestrian, \"a person afoot\", which the subject must not carry) and ridden or herded animals, which have no class atom; cycles and scooters stay in as 'other conveyances'."
  },
  {
   "span": "b4",
   "atoms": [
    "dev.governs",
    "st.lane_enters",
    "st.travel_region",
    "st.intersection",
    "rel.occupies"
   ],
   "derived": [
    "drv.position.entered_via"
   ],
   "justification": "Facing the signal is the signal governing the approach the subject enters through: dev.governs (\"the travel regions whose traffic the device controls ... or an intersection\") on the carrier c with st.lane_enters(c, i) (\"the intersection region a directed approach carrier runs into at its entrance end\") that x came in through (drv.position.entered_via: \"x is inside region r on its current entry and came in through region c\"), or on i itself."
  },
  {
   "span": "b5",
   "atoms": [
    "rel.occupies",
    "st.intersection"
   ],
   "derived": [
    "drv.motion.entering_region"
   ],
   "justification": "drv.motion.entering_region: \"its footprint overlaps r (rel.occupies) at the observation and did not at the observation before\", r the st.intersection."
  },
  {
   "span": "b9",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-165::pedestrian",
    "ru.aggregate=DEF-NRS-484A-285::traffic",
    "rel.occupies",
    "st.crosswalk",
    "st.entrance_of",
    "st.lane_enters",
    "st.intersection"
   ],
   "derived": [],
   "justification": "The parties yielded to. 'pedestrians' is the admitted aggregate DEF-NRS-484A-165::pedestrian (\"a person afoot, a person in a manual or motorized wheelchair\"); 'within an adjacent crosswalk' is the pedestrian's footprint overlapping (rel.occupies) a st.crosswalk (\"marked crossing, or the unmarked prolongation of sidewalks at an intersection\") adjacent to i: a crosswalk recorded as marking the entrance of a carrier entering i (st.entrance_of: \"the carrier whose entrance into an intersection a stop line or a crosswalk marks\"; st.lane_enters). Distance is not used for adjacency. 'other traffic' is the admitted aggregate DEF-NRS-484A-285::traffic, every member other than x; 'using the intersection' is its footprint overlapping i (rel.occupies)."
  }
 ],
 "operationalizations": [
  {
   "span": "b7",
   "standard": "yield the right-of-way: not proceeding where the parties' \"direction, speed and proximity\" \"give rise to the danger of a crash unless one grants precedence to the other\" (DEF-NRS-484A-210)",
   "concepts": [
    "drv.motion.moving",
    "kin.speed",
    "prim.closest_approach_within",
    "prim.closest_approach_distance"
   ],
   "params": [
    "p.speed_resolution",
    "p.immediate_hazard_gap",
    "p.conflict_clearance"
   ],
   "convention": "Gap-acceptance and surrogate-safety convention: the subject grants precedence where it does not proceed (it is not moving, drv.motion.moving) while a party is in danger of a crash with it; that danger is their predicted closest approach under constant velocities, within the critical gap, coming nearer than the conflict radius, so direction, speed and proximity all enter the prediction by their degree.",
   "surrogate": false
  }
 ],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "b2",
   "rule": "NRS_484B_307_9b_o1",
   "map": {
    "x": "x"
   },
   "as": "exception"
  }
 ],
 "residues": [
  {
   "span": "b11",
   "why": "An advisory to drivers turning with the arrow about what opposing traffic faces at the same time; it permits, requires and forbids nothing, and no rule reads it."
  }
 ],
 "binders": [
  {
   "name": "x",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-285::traffic"
   ]
  }
 ],
 "applicability": "x carries ru.aggregate=DEF-NRS-484A-285::traffic and does not carry ru.aggregate=DEF-NRS-484A-165::pedestrian; at the observation x occupies an intersection i on a passage whose entry (drv.motion.entering_region(x, i), the latest, read through a past operator) came through a carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)), and at that entry a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right. Not engaged where NRS_484B_307_9b_o1 applies to x (composition, exception).",
 "obligation": "Where x is moving at the observation (drv.motion.moving with p.speed_resolution): for every road user p carrying ru.aggregate=DEF-NRS-484A-165::pedestrian that occupies a crosswalk w recorded as marking the entrance of some carrier c2 entering i (st.entrance_of(w, c2), st.lane_enters(c2, i)), and for every road user u other than x carrying ru.aggregate=DEF-NRS-484A-285::traffic that occupies i, it is not the case that x and that road user approach within p.immediate_hazard_gap (prim.closest_approach_within) with a closest-approach centre distance (prim.closest_approach_distance) below p.conflict_clearance.",
 "params": [
  "p.speed_resolution",
  "p.immediate_hazard_gap",
  "p.conflict_clearance"
 ],
 "narrowings": [
  {
   "span": "b9",
   "why": "'lawfully' is not read: every pedestrian in such a crosswalk and every other member of traffic inside the intersection is yielded to. 'an adjacent crosswalk' is read as a crosswalk recorded as marking the entrance of a carrier entering the intersection; a crosswalk across the exit of a one-way leg marks no entrance and is not read.",
   "kind": "reading"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "x (ru.motor_vehicle) entered i under circular_red with green_arrow(left) and is turning left, moving; a ru.pedestrian occupies the crosswalk that marks the entrance of the carrier on the leg x turns into, and prim.closest_approach_within holds over p.immediate_hazard_gap with a prim.closest_approach_distance below p.conflict_clearance."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "x enters i under circular_red with green_arrow(left) and turns left with no other road user in the scene."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "x enters i while s displays circular_green."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "x moves through i with a pedestrian approaching in a crosswalk at the entrance of the leg x turns into, but the source does not observe s's state at x's entry.",
   "masked": [
    "dev.traffic_signal"
   ]
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.speed_resolution",
   "unit": "m/s",
   "value": 0.2,
   "convention": "Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts as no motion.",
   "source": "speed resolution of the carla_scene_graph acquisition standard"
  },
  {
   "name": "p.immediate_hazard_gap",
   "unit": "s",
   "value": 4.1,
   "convention": "Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach, counts as an immediate hazard to a road user about to cross or join its path.",
   "source": "Highway Capacity Manual critical-gap values"
  },
  {
   "name": "p.conflict_clearance",
   "unit": "m",
   "value": 3.0,
   "convention": "Conflict radius: the centre distance at predicted closest approach below which two road users' paths count as in conflict; about the half-length plus half-width of two passenger cars.",
   "source": "surrogate safety measures (closest-approach conflict radius)"
  }
 ],
 "gaps": []
}
```

### Nodes of other laws these records compose

`NRS_484B_250_4_o1` (NRS-484B-250-4) — its duty: “shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection” (characters 231–510)

- state: accepted; the record as accepted
- applicability: x is a vehicle (ru.aggregate=DEF-NRS-484A-320::vehicle) and enters an intersection i (st.intersection) at this observation (drv.motion.entering_region x i) through an approach carrier c: a region of kind st.travel_region that x occupies at this observation with st.lane_enters c i. At this observation some traffic signal d (dev.traffic_signal) that governs i or c (dev.governs d i, or dev.governs d c) is inoperative (dev.inoperative d). Where x occupies several carriers entering i and the verdict differs between them, which governs is unknown; a rule never picks the carrier that favours x.
- obligation: Act: x halted (drv.motion.halted x with p.speed_resolution) at the place the words name, taken in their order, on the approach that leads to this entry. Place: (1) where a stop line s (st.stop_line) is recorded as marking c (st.entrance_of s c): at s, an observation at which x is halted, its body within p.stop_point_tolerance of s (st_region_geometry_distance x s) and s not behind x along c's designated direction (prim.region_offset_along x s c at least zero); (2) where the source observes the stop lines' entrances and none marks c, and a crosswalk w is recorded as marking c (st.entrance_of w c): before entering w, an observation at which x is halted, its footprint not overlapping w (rel.occupies x w false), its body within p.stop_point_tolerance of w and w ahead of x along c (prim.region_offset_along x w c positive); (3) where the source observes that no stop line and no crosswalk marks c: an observation at which x is halted with its footprint outside i (rel.occupies x i false), within p.stop_point_tolerance of i, or farther upstream where a highway h on which i lies and c does not (st.on_way i h; st.on_way c h false) is in view from x for at least p.intersection_sight_distance (st_sight_along_way x h). History bound (the ontology's approach convention): the search runs back from this entry and ends at the approach start, the last observation before the entry at which x, on c, is outside the governing place's stopping zone upstream (not on the place, short of it along c by prim.region_offset_along, and farther from it than p.stop_point_tolerance by st_region_geometry_distance; for place (3) the place is c's entrance end at i), or at x's previous entry into i, whichever is later. A halt found in that stretch meets the duty; reaching either end without one violates it; reaching neither (the recording begins inside the approach) leaves it unknown. A halt before the previous entry into i never counts for this entry. An observed exit from the stopping zone upstream begins a new approach and the halt is owed again; crossing the mark, moving on, a change of carrier or a lateral move within this entry, a reverse that stays within the zone and speed noise begin none. Missing evidence: whether this is an entry through c is unknown where the observation before it does not show x on a mapped carrier; where a stop line's or crosswalk's association with c is unobserved, whether it governs is unknown; where the association lists are observed and exclude c, the next place in the words' order governs and the duty is not unknown on that ground; a recorded halt at a place known to govern decides compliance whatever else is missing.
- composes no rule

`NRS_484B_307_9b_o1` (NRS-484B-307-9b) — its duty: “(1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;” (characters 296–552)

- state: not accepted, not coded since; the record as planned in iteration 1
- applicability: x carries ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle or ru.aggregate=DEF-NRS-484B-018::electric_scooter; at the observation x leaves an intersection i (drv.motion.leaving_region(x, i)); at the observation of its latest entry into i (drv.motion.entering_region(x, i), read through a past operator) x came in through a carrier c with st.lane_enters(c, i) (drv.position.entered_via(x, i, c)) and a traffic signal s that governs c or i (dev.governs) displayed circular_red together with green_arrow(d), d left or right; and at the leaving observation the heading change since that entry (drv.motion.heading_change_since_entry(x, i) with step p.heading_since_step_carla_scene_graph) shows a straight-through passage (its absolute value below p.turn_recognition_angle) or a turn opposite d (at most minus p.turn_recognition_angle where d is left, at least p.turn_recognition_angle where d is right).
- obligation: A halt before the entry, searched in the past (the approach convention). Event: x's entry into i that the applicability names, made through carrier c (the carrier x occupied at the observation before the entry with st.lane_enters(c, i)). Place, in order: a stop line recorded as marking c (st.entrance_of(line, c)); where c's marks are observed and include no stop line, a crosswalk recorded as marking c; where neither is recorded for c, the entrance end of c at i. Act: an observation at which x is halted (drv.motion.halted with p.speed_resolution) while occupying c, its body within p.stop_point_tolerance of the place (st.region_geometry distance), not past it along c's designated direction (prim.region_offset_along of the place from x not negative), and its footprint overlapping neither i nor, where the place is a crosswalk, that crosswalk. Search: back from the entry, ending at the approach start (the last observation before the entry at which x, on c, is outside the place's stopping zone upstream: off the mark, short of it and farther from it than p.stop_point_tolerance) or at x's previous entry into i through the same place; nothing else ends it. Verdict: complied where the search finds the act; violated where it reaches either end without it; unknown only where it reaches neither (the recording begins inside the approach) or where c's association with a mark, c's direction or x's place relative to the mark is unobserved and the verdict turns on it. Judged at the leaving observation, the search running from the entry.
- composes no rule


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
   residue (words the vocabulary cannot carry). A gap is not a carrier: it annotates a span an element or an operationalization
   carries with its nearest atoms (step 6). Two exceptions to "exactly once": a `reference` span naming several
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
   ontology's row format or the operator, nearest atoms with the excluding clause), and still map
   the span to those nearest atoms or concepts: the coding session tries them, and the gap is filed
   only if it confirms the words cannot be written with them.

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
gaps[{span, kind: "atom" | "operator", proposal, nearest}]
```

A gap has two kinds and no other: `atom`, when no atom and no enumeration value of the ontology
carries the span (the proposal is the ontology row that would, starting with its new id), and
`operator`, when the formula language cannot express it (the proposal is the operator, starting
with its new name). An atom gap never proposes an atom the ontology has, and an operator gap never
proposes what the formula language already writes. A gap is filed, and blocks its law until the
operator decides it, only when the coding session confirms the span cannot be written with the
atoms and operators you map it to; nothing else is a gap.
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

Working directory: `/local-scratch2/sma407/smoke31-run/pipeline/traffic-spec-agent/results/smoke31-1111-0039/iter-004/plan`. Write `aggregates.jsonl`, `blueprint.jsonl` and `PLAN.md` there with the Write tool, as files, by hand. Everything you need is in this prompt: you read no other file, and the shell runs exactly one command, the validator below — any other command is denied.

## Checking a draft

The deterministic validator the harness will run, with the run's accepted nodes, concepts, mapping index, reading and your `aggregates.jsonl`, is available to you on a draft:

```
python -m harness validate --run_id smoke31-1111-0039 --blueprint_file /local-scratch2/sma407/smoke31-run/pipeline/traffic-spec-agent/results/smoke31-1111-0039/iter-004/plan/blueprint.jsonl
```

Run it exactly as written. It prints one line per node (`accept`, `return`, `fail`) with the reasons. Run it once the file is complete, fix what it names, and stop when every node is `accept`. It is the only program you run; the self-check is yours, the schema check is its.
