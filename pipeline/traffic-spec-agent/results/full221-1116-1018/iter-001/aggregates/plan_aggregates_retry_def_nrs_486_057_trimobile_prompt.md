# Planner — which defined terms are class aggregates, and which classes each covers

## Role

You are the planner, deciding for the whole run, before any law is planned, how each defined term
the laws use is represented. The harness has already resolved, mechanically and by the operator's
declared precedence, which posted definition applies to each word: you never choose between
competing definitions. For each (definition, term) below you decide one representation, and for
each aggregate you classify every class of road users of the ontology by the definition's words.
An independent verifier then checks every classification; what it cannot
support is admitted as unresolved, never changed by it.

## Inputs (injected below)

- **The posted definitions** — each definition the resolution reached, verbatim, with the
  definitions its cross-references and nested defined terms reach mechanically.
- **The defined terms the laws use** — each (definition, term) to decide, with the laws using it.
- **The classes of road users** — every class of the ontology with its contract.
- **Rows already selected** — decisions made earlier in this run (read-only).
- **Feedback** — when present: the verifier's verdicts on a classification of yours, or plans that
  claim an aggregate the selection did not make one. Treat it as evidence to reconsider against
  the full definition, not as an instruction to choose the opposite status.

### The posted definitions

- `DEF-NRS-486-057`: “Trimobile” means every motor vehicle equipped with handlebars and a saddle seat and designed to travel with three wheels in contact with the ground, at least one of which is power driven. The term does not include a motorcycle with a sidecar.
- `DEF-NRS-484A-130`: “Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-320`: “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029 [DEF-NRS-482-029]; and (4) An electric scooter.
- `DEF-NRS-484A-095`: “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195`: “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115`: “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045`: “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285`: “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-165`: “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029 [DEF-NRS-482-029].
- `DEF-NRS-482-029`: “Electric personal assistive mobility device” means a self-balancing, two nontandem wheeled device, designed to transport only one person, with an electric propulsion system that limits the maximum speed of the device to 15 miles per hour or less.
- `DEF-NRS-484A-081`: “Electric bicycle” has the meaning ascribed to it in NRS 484B.017 [DEF-NRS-484B-017].
- `DEF-NRS-484B-017`: “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025`: “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125`: “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082`: “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018`: “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-486-041`: “Motorcycle” means every motor vehicle equipped with a seat or a saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground, excluding an electric bicycle as defined in NRS 484B.017 [DEF-NRS-484B-017], an electric scooter as defined in NRS 482.0295 [DEF-NRS-482-0295], a tractor, an autocycle and a moped.
- `DEF-NRS-484A-080`: (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
- `DEF-NRS-482A-030`: “Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.
- `DEF-NRS-482A-025`: “Automated driving system” has the meaning ascribed to it in SAE J3016.
- `DEF-NRS-482A-036`: “Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.
- `DEF-NRS-484A-150`: “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-482-0295`: “Electric scooter” means a vehicle: (1) With handlebars and an electric motor that is designed to be ridden on in an upright or seated position and is propelled by its electric motor or by propulsion provided by the rider; (2) That does not weigh more than 100 pounds without a rider; and (3) That has a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-486-015`: “Autocycle” means a three-wheeled motor vehicle that: (1) Is designed with two front wheels and one rear wheel; (2) Is equipped with a steering wheel or handlebars; (3) Is equipped with safety belts for the driver and each passenger; (4) Uses foot pedals to control the braking and acceleration of the vehicle; (5) Does not require the operator or passengers to straddle or sit astride the vehicle; and (6) Has been manufactured to meet the federal safety requirements for a motorcycle.
- `DEF-NRS-486-038`: “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle as defined in NRS 484B.017 [DEF-NRS-484B-017] or an electric scooter as defined in NRS 482.0295 [DEF-NRS-482-0295].


### The defined terms the laws use

- `DEF-NRS-486-057` / "trimobile": used by NRS-486-351-2


### The classes of road users of the ontology

- `ru.bicycle`: human-powered wheeled vehicle ridden by a person
- `ru.bus`: motor vehicle designed to carry many passengers
- `ru.child`: pedestrian who is visibly a child
- `ru.commercial_motor_vehicle`: vehicle over the jurisdiction's commercial mass class or marked as commercially licensed
- `ru.electric_bicycle`: a bicycle with an assisting electric motor; **class** attribute as the jurisdiction's taxonomy labels it
- `ru.electric_scooter`: a standing or seated electric scooter with handlebars
- `ru.emergency_vehicle`: vehicle of a class the jurisdiction designates as emergency; **kind** ∈ {police, fire, ambulance, other} **Not a stand-in for:** a responding emergency vehicle — the class alone is not responding; its responding is conduct, carried by a concept, and an unobserved lamp or siren makes the rule unknown, not satisfied
- `ru.fire_apparatus`: a fire-fighting vehicle (a sub-kind of `ru.emergency_vehicle` that law names on its own)
- `ru.moped`: a low-power two- or three-wheeler with a small engine or motor, as a jurisdiction classes it
- `ru.motor_vehicle`: a self-propelled vehicle other than a rail vehicle; excludes the powered two-wheelers a jurisdiction classes separately below **Not a stand-in for:** "vehicle" as a legal aggregate — which classes count as a vehicle is declared by the reading
- `ru.motorcycle`: motor vehicle on two or three wheels ridden astride, including three-wheeled variants
- `ru.official_vehicle`: a vehicle in official or contracted road service, identifiable by livery or equipment; **kind** ∈ {tow, utility, highway_maintenance, incident_management, regulatory_agency, coroner, armored_car, municipal, other} **Not a stand-in for:** an emergency vehicle
- `ru.pedestrian`: a person on foot, in a wheelchair, or on a device the jurisdiction treats as on foot **Not a stand-in for:** a person on a bicycle or scooter
- `ru.pedestrian_with_white_cane_or_guide_animal`: pedestrian carrying a white or white-and-red cane, accompanied by a guide animal, or led by another person
- `ru.rail_vehicle`: a train, tram, streetcar or other on-track equipment
- `ru.school_bus`: bus designated for carrying school children, with the jurisdiction's markings
- `ru.taxicab`: passenger vehicle for hire, identifiable by its markings
- `ru.tour_bus_or_limousine`: a tour or shuttle bus, or a lengthened passenger vehicle for hire, identifiable by its livery
- `ru.trailer_or_combination`: vehicle drawn by another, or the combination
- `ru.transit_bus`: bus in public transit service, identifiable by its livery or route display
- `ru.truck`: motor vehicle for carrying goods, with a body built for that purpose


### Rows already selected (read-only)

- `DEF-LVMC-11-02-030` / "access aisle": not_aggregate
- `DEF-LVMC-11-02-050` / "city parking facility": not_aggregate
- `DEF-LVMC-11-02-070` / "commercial vehicle": aggregate
- `DEF-LVMC-11-02-082` / "electric bicycle": aggregate
- `DEF-LVMC-11-02-083` / "electric scooter": aggregate
- `DEF-LVMC-11-02-090` / "limo": aggregate
- `DEF-LVMC-11-02-110` / "recreational vehicle": aggregate
- `DEF-LVMC-11-02-120` / "rtc bus": aggregate
- `DEF-LVMC-11-02-130` / "roundabout": not_aggregate
- `DEF-LVMC-11-02-140` / "taxicab": aggregate
- `DEF-LVMC-11-02-150` / "shuttle bus": aggregate
- `DEF-LVMC-11-02-150` / "tour bus": aggregate
- `DEF-LVMC-11-02-170` / "trailer": aggregate
- `DEF-NRS-239C-065` / "law enforcement agency": not_aggregate
- `DEF-NRS-484A-015` / "alley": not_aggregate
- `DEF-NRS-484A-020` / "authorized emergency vehicle": aggregate
- `DEF-NRS-484A-025` / "bicycle": aggregate
- `DEF-NRS-484A-030` / "bus": aggregate
- `DEF-NRS-484A-035` / "bus stand": not_aggregate
- `DEF-NRS-484A-040` / "center": not_aggregate
- `DEF-NRS-484A-040` / "centerline": not_aggregate
- `DEF-NRS-484A-045` / "city": not_aggregate
- `DEF-NRS-484A-050` / "combination of vehicles": aggregate
- `DEF-NRS-484A-060` / "controlled-access highway": not_aggregate
- `DEF-NRS-484A-065` / "crosswalk": not_aggregate
- `DEF-NRS-484A-070` / "divided highway": not_aggregate
- `DEF-NRS-484A-080` / "driver": not_aggregate
- `DEF-NRS-484A-095` / "highway": not_aggregate
- `DEF-NRS-484A-105` / "intersection": not_aggregate
- `DEF-NRS-484A-115` / "local authority": not_aggregate
- `DEF-NRS-484A-125` / "moped": aggregate
- `DEF-NRS-484A-130` / "motor vehicle": aggregate
- `DEF-NRS-484A-135` / "motorcycle": aggregate
- `DEF-NRS-484A-145` / "official traffic-control device": not_aggregate
- `DEF-NRS-484A-155` / "park": not_aggregate
- `DEF-NRS-484A-155` / "parking": not_aggregate
- `DEF-NRS-484A-165` / "pedestrian": aggregate
- `DEF-NRS-484A-180` / "police officer": not_aggregate
- `DEF-NRS-484A-185` / "premises to which the public has access": not_aggregate
- `DEF-NRS-484A-190` / "driveway": not_aggregate
- `DEF-NRS-484A-190` / "private way": not_aggregate
- `DEF-NRS-484A-195` / "public authority": not_aggregate
- `DEF-NRS-484A-200` / "railroad": not_aggregate
- `DEF-NRS-484A-205` / "regulatory agency": not_aggregate
- `DEF-NRS-484A-210` / "right-of-way": not_aggregate
- `DEF-NRS-484A-215` / "road": not_aggregate
- `DEF-NRS-484A-220` / "roadway": not_aggregate
- `DEF-NRS-484A-230` / "school bus": aggregate
- `DEF-NRS-484A-240` / "sidewalk": not_aggregate
- `DEF-NRS-484A-250` / "stand": not_aggregate
- `DEF-NRS-484A-250` / "standing": not_aggregate
- `DEF-NRS-484A-260` / "stopping": not_aggregate
- `DEF-NRS-484A-265` / "street": not_aggregate
- `DEF-NRS-484A-270` / "taxicab": aggregate
- `DEF-NRS-484A-275` / "through highway": not_aggregate
- `DEF-NRS-484A-280` / "tow car": aggregate
- `DEF-NRS-484A-285` / "traffic": aggregate
- `DEF-NRS-484A-290` / "traffic-control signal": not_aggregate
- `DEF-NRS-484A-305` / "truck": aggregate
- `DEF-NRS-484A-320` / "vehicle": aggregate
- `DEF-NRS-484A-460-2` / "high-occupancy vehicle": aggregate
- `DEF-NRS-484B-010` / "business district": not_aggregate
- `DEF-NRS-484B-017` / "electric bicycle": aggregate
- `DEF-NRS-484B-018` / "electric scooter": aggregate
- `DEF-NRS-484B-023` / "freight curb loading zone": not_aggregate
- `DEF-NRS-484B-033` / "passenger curb loading zone": not_aggregate
- `DEF-NRS-484B-053` / "residence district": not_aggregate
- `DEF-NRS-484B-057` / "safety zone": not_aggregate
- `DEF-NRS-484B-060` / "school crossing zone": not_aggregate
- `DEF-NRS-484B-063` / "school zone": not_aggregate
- `DEF-NRS-484B-067` / "taxicab stand": not_aggregate
- `DEF-NRS-484B-073` / "two-directional highway": not_aggregate
- `DEF-NRS-484B-077` / "u-turn": not_aggregate
- `DEF-NRS-486-031` / "highway": not_aggregate
- `DEF-NRS-486-038` / "moped": aggregate
- `DEF-NRS-486-041` / "motorcycle": aggregate
- `DEF-NRS-486-057` / "trimobile": aggregate
- `DEF-NRS-648-016` / "security guard": not_aggregate


### Feedback

- `DEF-NRS-486-057::trimobile` class `ru.bicycle`: proposed unresolved; the gate found the posted words support another decided status: The contract describes human-powered devices, which the incorporated vehicle definition excepts, so they cannot satisfy the required motor-vehicle condition.
- `DEF-NRS-486-057::trimobile` class `ru.electric_bicycle`: proposed unresolved; the gate found the posted words support another decided status: The incorporated motor-vehicle definition expressly excludes electric bicycles, so three wheels and a saddle do not establish eligibility.
- `DEF-NRS-486-057::trimobile` class `ru.electric_scooter`: proposed unresolved; the gate found the posted words support another decided status: The incorporated motor-vehicle definition expressly excludes electric scooters, regardless of their wheel count or seating.

## Rules

1. **One representation per (definition, term).** `aggregate` when the definition denotes an
   extensional set of tracked road users whose eligibility can be classified by the `ru.*` classes
   above. A definition that maps to one class is still an aggregate. A contextual condition such
   as where an otherwise eligible road user is or what it is doing never becomes membership.
   `not_aggregate` when the definition does not denote such a class set: this includes places,
   features, manoeuvres, states and authorities, and relational roles such as the
   controller of another entity. A role can still be mapped by the ordinary law planner; do not
   turn it into class membership of the controlled entity. `gap` only when the definition does
   denote an extensional set of road users but the ontology's classes cannot carry that set at all.
   `target` is `<definition>::<term in lower case, words joined by underscores>` for an aggregate
   and null otherwise. `quote` is the definition's words
   that decide the representation, verbatim; `reason` says why in one sentence.
2. **Classify every class.** For an aggregate, every class of road users above appears exactly once,
   `included`, `excluded`, `covered` or `unresolved`, with the definition's words that decide it,
   verbatim, in `quotes` (each naming the definition it quotes: the controlling one, or one reached
   through a cross-reference or nested defined term). An
   admitting clause, an exception or a closed enumeration decides a class; where the words decide
   neither, the class is `unresolved` with the closest words and a `reason` saying why they do not
   decide it. A class is never included or excluded by what such words usually mean elsewhere.
   `excluded` means the definition leaves the class out: no member of it is admitted.
2a. **Covered: a class admitted only through narrower included classes.** A source lists every
   class that applies to a road user, and a class it cannot settle it marks unobserved; no class
   implies another. So where the definition admits members of a class only as members of other
   classes you mark `included`, a qualifying road user already carries one of those, and the
   class's own label adds no membership evidence: the class is `covered`, not `excluded` (some of
   its members are admitted) and not `unresolved` (the words decide every member). A covered class
   names its covering classes in `covered_by` (at least one; never the class itself; each one you
   mark `included`), quotes in `quotes` the definition words that admit its members only as those
   classes, quotes in `basis`, verbatim, the class contracts above that make the coverage complete
   (each naming the class it quotes: the covered class or a covering one), and says in `reason` why
   every member the words admit within the class carries a covering class. Coverage is never
   inferred from a class's name, or because a source can label a class of the same name: it rests
   on the definition's words and the contracts. Where the words admit members of the class that no
   included class carries, the class is `included` if they admit all of its members, and otherwise
   `unresolved`.
3. **No nesting.** An aggregate classifies classes, never another aggregate: where a definition
   includes another defined term, classify the classes that term's definition covers directly.
4. **Context is not membership.** A condition of a scene the definition states (where a road user
   is, or what it is doing there) is not a class: classify the classes as the rest of the words
   decide, and the rule that uses the aggregate carries the condition.
5. **Your own rows only.** Decide exactly the (definition, term) pairs listed under the defined
   terms; a row already selected is changed only when the feedback asks about it.

## Output

JSON, this schema and nothing more:

```
{"selection": [{"definition": "<definition id>", "term": "<term as listed>",
                "representation": "aggregate | not_aggregate | gap", "target": "<id> | null",
                "quote": "<verbatim words of the definition>", "reason": "<one sentence>"}],
 "aggregates": [{"aggregate_id": "<the target of an aggregate row>", "term": "<term>", "definition": "<definition id>",
                 "classifications": [{"class": "<class id>", "status": "included | excluded | covered | unresolved",
                                      "quotes": [{"definition": "<definition id>", "words": "<verbatim>"}],
                                      "reason": "<why, for an unresolved or covered status>",
                                      "covered_by": ["<class id>"], "basis": [{"class": "<class id>", "words": "<verbatim words of its contract>"}]}]}]}
```

`covered_by` and `basis` appear only on a covered class.

## Finish

Finish when the JSON is written. No commentary outside it.
