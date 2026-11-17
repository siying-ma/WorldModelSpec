# Coding agent — from one blueprint node to a rule and its witnesses

## Role

You implement **one node**: a `Rule` value in Lean whose formulas say exactly what the node's
elements, operationalizations and compositions say, and a witness file whose scenarios show the
rule firing, holding, idling, and reporting unknown when a claimed atom is unobserved. You do not
reinterpret the law: the blueprint is the reading. Where the blueprint is wrong, you end the session and
say so in `task_result.md`; you do not repair it in Lean.

You are a one-shot session with a budget of gate runs. Nothing waits for a reply.

## Inputs (injected below)

- **The node** — its blueprint record, then, whole, each source text its `definition` references
  borrow words from, with the definitions that apply to it.
- **Files** — the rule file and the witness file you own; nothing else may change. Both exist
  already: the harness wrote them from the node, they build, and every declaration the gate
  compares (id, laws, binders, assumptions, operationalizations, residues, surrogate), every
  parameter as a `Term`, and the four scenarios with their verdicts and masked atoms are filled
  in. Your work is the formulas and the scenes.
- **Core surface** — generated from the library and cited to its files: the formula language,
  the `Rule`/`Scenario` records, the catalogue of accepted concepts a rule may call, every atom's
  Lean accessor with the scene field it reads, the primitives with their contracts and parameter
  order, the enumeration spellings and Lean constructors, the world records a witness builds,
  the `Units` constructors and the `Build.*` builders. It is complete for this task.
- **Contracts** — what each name the node claims denotes, and each atom its claimed primitives
  and concepts read: write each by its contract.
- **Reading** — the run's values for the node's parameters. A witness is evaluated against
  these values (its own `reading` field is ignored), so its geometry is built to break or keep
  each bound by a clear margin. No value goes into the rule.
- **Example** — an accepted node of this library, the pattern to follow.
- **Skeletons** — the two files as the harness wrote them.
- **Gate** — the command to run and the verdicts it can return.

{
 "node_id": "NRS_484B_587_2b",
 "law_refs": [
  "NRS-484B-587-2b"
 ],
 "subject": {
  "binder": "subject",
  "class_elements": [
   "ru.aggregate=DEF-NRS-484A-320::vehicle"
  ]
 },
 "segmentation": [
  {
   "id": "e1",
   "text": "Except if required by an emergency",
   "role": "exception"
  },
  {
   "id": "e2",
   "text": "or as otherwise authorized by subsection 3",
   "role": "exception"
  },
  {
   "id": "e3",
   "text": "[(3) appended below],",
   "role": "boilerplate"
  },
  {
   "id": "e4",
   "text": "a person shall not drive a vehicle",
   "role": "subject"
  },
  {
   "id": "e5",
   "text": "on a controlled-access highway:",
   "role": "trigger"
  },
  {
   "id": "e6",
   "text": "Across any solid white line that separates an entrance or exit lane from a marked traffic lane.",
   "role": "obligation"
  },
  {
   "id": "e7",
   "text": "A person driving a vehicle described in",
   "role": "exception"
  },
  {
   "id": "e8",
   "text": "paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210",
   "role": "reference"
  },
  {
   "id": "e10",
   "text": "may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.",
   "role": "exception"
  },
  {
   "id": "e11",
   "text": "The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to:",
   "role": "definitional"
  },
  {
   "id": "e12",
   "text": "(a) An authorized emergency vehicle described in NRS 484A.480;",
   "role": "exception"
  },
  {
   "id": "e13",
   "text": "(b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;",
   "role": "exception"
  },
  {
   "id": "e14",
   "text": "(c) A traffic incident management vehicle;",
   "role": "exception"
  },
  {
   "id": "e15",
   "text": "(d) A tow car;",
   "role": "exception"
  },
  {
   "id": "e16",
   "text": "(e) A coroner vehicle;",
   "role": "exception"
  },
  {
   "id": "e17",
   "text": "or (f) A public transit motor bus,",
   "role": "exception"
  },
  {
   "id": "e18",
   "text": "that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.",
   "role": "exception"
  }
 ],
 "elements": [
  {
   "span": "e1",
   "atoms": [
    "ru.emergency_vehicle",
    "sig.warning_lamp",
    "sig.hazard"
   ],
   "derived": [],
   "justification": "An emergency requiring the movement is not observable; it is read through the conduct that shows it: the subject's hazard lamps flashing (sig.hazard, \"both indicators flashing together\"), or the subject an emergency vehicle (ru.emergency_vehicle, \"vehicle of a class the jurisdiction designates as emergency\") showing a lit warning lamp (sig.warning_lamp, \"a warning lamp lit\"). ru.emergency_vehicle is \"not a stand-in for a responding emergency vehicle — the class alone is not responding\": the class is read only together with its lit warning lamp."
  },
  {
   "span": "e2",
   "atoms": [
    "dev.regulatory_sign"
   ],
   "derived": [],
   "justification": "Authorization by subsection 3 is the permission subsection 3 states (spans e7, e10, e12-e18): a shoulder-use permission posted by a dev.regulatory_sign, \"a point regulation by catalogue code\", of code shoulder_use_permitted; this span joins that permission to the duty as an exception."
  },
  {
   "span": "e4",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [
    "drv.motion.complete_halt"
   ],
   "justification": "\"vehicle\" is the admitted aggregate DEF-NRS-484A-320::vehicle, \"every device in, upon or by which any person or property is or may be transported or drawn upon a highway\". \"drive\" is read through the vehicle's controlled motion: the vehicle is moving, drv.motion.complete_halt not holding with p.halt_speed_tolerance."
  },
  {
   "span": "e5",
   "atoms": [
    "rel.occupies",
    "st.controlled_access"
   ],
   "derived": [],
   "justification": "\"Controlled-access highway\" (DEF-NRS-484A-060, \"every highway to or from which ... persons have no legal right of access except at such points only\"): st.controlled_access, \"a highway with access only at designated points, and its entrance and exit lanes\", whose region the subject's footprint overlaps (rel.occupies)."
  },
  {
   "span": "e6",
   "atoms": [
    "st.lane_marking",
    "st.lane",
    "dev.governs",
    "dev.regulatory_sign"
   ],
   "derived": [
    "drv.lane.entering_adjacent_lane"
   ],
   "justification": "Driving across the line between two lanes is the subject's footprint first reaching from lane r1 into the neighbouring lane r2 on side s: drv.lane.entering_adjacent_lane, \"Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1\". The line crossed is the marking on side s of r1: st.lane_marking, \"per side of a lane: type ... colour\", of type solid or double_solid and colour white. It separates an entrance or exit lane from a marked traffic lane where, of r1 and r2 (st.lane), one is governed (dev.governs) by a dev.regulatory_sign of code entrance or exit and the other is governed by no such sign. The regulatory sign is \"not a stand-in for a road feature\": the lane's role is read from the sign that indicates it, as subsection 1 reads entrances and exits."
  },
  {
   "span": "e7",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ],
   "derived": [],
   "justification": "The person driving a vehicle of the classes listed (e12-e17): the subject vehicle, admitted aggregate DEF-NRS-484A-320::vehicle; which vehicles are described is read from the list."
  },
  {
   "span": "e10",
   "atoms": [
    "rel.occupies",
    "st.shoulder",
    "st.controlled_access",
    "dev.governs",
    "dev.regulatory_sign",
    "prim.conditions_hold"
   ],
   "derived": [],
   "justification": "On a paved shoulder of a controlled-access highway: the subject occupies (rel.occupies) a paved st.shoulder while it occupies the st.controlled_access region; the signage allowing that vehicle to use the shoulder is a dev.regulatory_sign of code shoulder_use_permitted governing that shoulder (dev.governs), whose conditions hold for the subject (prim.conditions_hold, \"the structured conditions of a device ... hold at the observation for a road user\")."
  },
  {
   "span": "e12",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle"
   ],
   "derived": [],
   "justification": "\"Authorized emergency vehicle\" is the admitted aggregate DEF-NRS-484A-020::authorized_emergency_vehicle, \"a vehicle permitted to depart from certain traffic laws when equipped and operated in the manner provided by law\"; the words borrowed through the reference e8 list it as \"(a) An authorized emergency vehicle described in NRS 484A.480;\". The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e13",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle"
   ],
   "derived": [],
   "justification": "\"(b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;\": a member of DEF-NRS-484A-020::authorized_emergency_vehicle, \"a vehicle permitted to depart from certain traffic laws\". The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e14",
   "atoms": [
    "ru.official_vehicle"
   ],
   "derived": [],
   "justification": "\"(c) A traffic incident management vehicle;\": ru.official_vehicle, \"a vehicle in official or contracted road service\", kind incident_management; not an emergency vehicle. The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e15",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-280::tow_car"
   ],
   "derived": [],
   "justification": "\"(d) A tow car;\": the admitted aggregate DEF-NRS-484A-280::tow_car, \"a motor vehicle which has been altered or designed and equipped for and exclusively used in the business of towing vehicles\". The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e16",
   "atoms": [
    "ru.official_vehicle"
   ],
   "derived": [],
   "justification": "\"(e) A coroner vehicle;\": ru.official_vehicle, \"a vehicle in official or contracted road service\", kind coroner; not an emergency vehicle. The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e17",
   "atoms": [
    "ru.aggregate=DEF-NRS-484A-030::bus",
    "ru.transit_bus"
   ],
   "derived": [],
   "justification": "\"or (f) A public transit motor bus,\": a member of DEF-NRS-484A-030::bus (\"a vehicle ... designed and used for the transportation of persons for compensation\") that is ru.transit_bus, \"bus in public transit service\". The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  },
  {
   "span": "e18",
   "atoms": [
    "rel.occupies",
    "st.highway",
    "st.on_way",
    "st.shoulder",
    "dev.governs",
    "dev.regulatory_sign",
    "prim.conditions_hold"
   ],
   "derived": [],
   "justification": "Being driven on the paved shoulder of a highway: the listed vehicle occupies (rel.occupies) a paved st.shoulder lying on (st.on_way) the st.highway it is on, governed (dev.governs) by a dev.regulatory_sign of code shoulder_use_permitted whose conditions hold for it (prim.conditions_hold). The list borrowed through e8 from NRS 484B.210(4) reads, in part, \"(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;\".",
   "source_spans": [
    "e8"
   ]
  }
 ],
 "operationalizations": [],
 "assumptions": [],
 "intentions": [],
 "compositions": [
  {
   "span": "e8",
   "as": "definition",
   "source": "NRS-484B-210-1",
   "quote": "(c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;",
   "why": "The reference borrows only the list of vehicle classes NRS 484B.210(4) sets forth (an authorized emergency vehicle, one under permit as such, a traffic incident management vehicle, a tow car, a coroner vehicle, a public transit motor bus) to name which vehicles subsection 3 permits on a signed paved shoulder; no rule of NRS 484B.210 (its passing on the right, or its exemption from it) needs to apply, hold or be complied with for this duty or its exception, and the list's words are appended in this line and carried by its own elements."
  }
 ],
 "residues": [
  {
   "span": "e11",
   "why": "Introduces the list of NRS 484B.210(4) as appended; the exemption from the passing rule of NRS 484B.210(1)(c)(1) it states is that section's, not this duty's, and is not read here."
  }
 ],
 "binders": [
  {
   "name": "subject",
   "class_elements": [
    "ru.aggregate=DEF-NRS-484A-320::vehicle"
   ]
  }
 ],
 "applicability": "The subject is a vehicle in motion (drv.motion.complete_halt(subject) with p.halt_speed_tolerance does not hold) whose footprint overlaps a controlled-access highway ca (rel.occupies, st.controlled_access). Exceptions: the duty does not apply where the subject's hazard lamps flash (sig.hazard) or it is an emergency vehicle with a lit warning lamp (ru.emergency_vehicle, sig.warning_lamp); nor where the subject, a listed vehicle (DEF-NRS-484A-020::authorized_emergency_vehicle, ru.official_vehicle of kind incident_management or coroner, DEF-NRS-484A-280::tow_car, or DEF-NRS-484A-030::bus with ru.transit_bus), occupies a paved shoulder on the highway it is on that a shoulder_use_permitted dev.regulatory_sign governs with its conditions holding for it.",
 "obligation": "At no such observation does drv.lane.entering_adjacent_lane(subject, r1, r2, s) hold, for lanes r1 and r2 and a side s in {left, right}, where the st.lane_marking on side s of r1 is of type solid or double_solid and colour white, and of r1 and r2 one is governed (dev.governs) by a dev.regulatory_sign of code entrance or exit and the other by no such sign.",
 "params": [
  "p.halt_speed_tolerance"
 ],
 "narrowings": [
  {
   "span": "e4",
   "why": "\"a person shall not drive\" is read through the vehicle's controlled motion: a vehicle in motion is driven, whoever or whatever controls it.",
   "kind": "observable_reading",
   "category": "agency"
  },
  {
   "span": "e1",
   "why": "An emergency is read through the conduct that shows it: hazard lamps flashing, or an emergency vehicle showing a lit warning lamp.",
   "kind": "observable_reading",
   "category": "purpose"
  },
  {
   "span": "e6",
   "why": "An entrance or exit lane is read as a lane an entrance- or exit-coded regulatory sign governs, and a marked traffic lane as a mapped lane no such sign governs.",
   "kind": "observable_reading",
   "category": "status"
  },
  {
   "span": "e6",
   "why": "Driving across the line is read at the observation the footprint first reaches over it into the neighbouring lane; a solid_broken marking, whose solid side cannot be told from the per-side record, is not read as a solid line.",
   "kind": "reading"
  },
  {
   "span": "e10",
   "why": "\"lawfully placed\" signage is read from the presence of a shoulder_use_permitted sign governing the shoulder.",
   "kind": "observable_reading",
   "category": "status"
  }
 ],
 "scenarios": [
  {
   "name": "forbid",
   "expected": "violated",
   "narrative": "On a controlled-access highway, the subject car in an entrance lane (governed by an entrance-coded sign) moves at 22 m/s and its footprint first reaches into the adjacent through lane across a solid white marking on that side."
  },
  {
   "name": "permit",
   "expected": "compliant",
   "narrative": "The subject car in the entrance lane merges into the through lane where the marking between them on that side is broken white."
  },
  {
   "name": "idle",
   "expected": "not_applicable",
   "narrative": "The subject car changes lanes across a solid white line on a surface street; it never overlaps a controlled-access region."
  },
  {
   "name": "blind",
   "expected": "unknown",
   "narrative": "The subject car moves from the entrance lane into the through lane on a controlled-access highway; the source does not observe lane markings.",
   "masked": [
    "st.lane_marking"
   ]
  },
  {
   "name": "branch_1",
   "expected": "not_applicable",
   "narrative": "An emergency vehicle with lit warning lamps crosses the solid white line from the through lane into an exit lane."
  },
  {
   "name": "branch_2",
   "expected": "compliant",
   "narrative": "The subject car crosses a solid white line between two through lanes, neither governed by an entrance or exit sign."
  }
 ],
 "literals": [],
 "param_proposals": [
  {
   "name": "p.halt_speed_tolerance",
   "unit": "m/s",
   "value": 0.1,
   "convention": "the speed at or below which a sampled speed counts as no movement: the source's speed resolution",
   "source": "speed resolution of vehicle tracking sources"
  }
 ],
 "gaps": [],
 "gap_resolutions": [],
 "planned_on": {}
}

### Definition sources (posted text the harness took from the corpus, whole, with the definitions that apply to it: a `definition` reference of the record borrows words from it; its own duties are not judged here)

#### `NRS-484B-210-1` — When overtaking on right side allowed (1)
_NRS 484B.210(1); with 484B.210(4)_

The driver of a vehicle may overtake and pass upon the right of another vehicle only under the following conditions: (a) When the driver of the vehicle overtaken is making or signaling to make a left turn. (b) Upon a highway with unobstructed pavement which is not occupied by parked vehicles and which is of sufficient width for two or more lines of moving vehicles in each direction. (c) Upon a highway with unobstructed pavement which is not marked as a traffic lane and which is not occupied by parked vehicles, if the vehicle that is overtaking and passing another vehicle: (1) Except as otherwise provided in subsection 4 [(4) appended below], does not travel more than 200 feet in the section of pavement not marked as a traffic lane; or (2) While being driven in the section of pavement not marked as a traffic lane, does not travel through an intersection or past any private way that is used to enter or exit the highway. (d) Upon any highway on which traffic is restricted to one direction of movement, where the highway is free from obstructions and of sufficient width for two or more lines of moving vehicles. The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to: (a) An authorized emergency vehicle described in NRS 484A.480; (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490; (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle; or (f) A public transit motor bus, that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.

Posted definitions that apply to its words:

- `DEF-NRS-484A-080` — (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
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
- `DEF-NRS-482A-030` — “Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.
- `DEF-NRS-484A-130` — “Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-482A-025` — “Automated driving system” has the meaning ascribed to it in SAE J3016.
- `DEF-NRS-482A-036` — “Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.
- `DEF-NRS-484A-150` — “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-484A-105` — “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-220` — “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-070` — “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015` — “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265` — “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215` — “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-190` — “Private way” or “driveway” means every way or place in private ownership and used for vehicular travel by the owner and those having express or implied permission from the owner, but not by other persons.
- `DEF-NRS-484A-020` — “Authorized emergency vehicle” means a vehicle permitted to depart from certain traffic laws when equipped and operated in the manner provided by law.
- `DEF-NRS-484A-280` — “Tow car” means a motor vehicle which has been altered or designed and equipped for and exclusively used in the business of towing vehicles by means of a crane, hoist, tow bar, towline or dolly, or is otherwise exclusively used to render assistance to other vehicles.
- `DEF-NRS-484A-030` — “Bus” means a vehicle owned by the State, a political subdivision or a private school or nursery, designed for carrying more than 10 passengers and used for the transportation of persons, or a vehicle, other than a taxicab, designed and used for the transportation of persons for compensation.
- `DEF-NRS-484A-270` — “Taxicab” means a motor vehicle designed or constructed to accommodate and transport not more than six passengers, including the driver, and used to transport passengers for a charge or fee.


- rule: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_587_2b.lean` — `namespace TrafficSpec.Rules.NRS_484B_587_2b`, `def rule : Rule`
- witness: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_587_2b.lean` — `namespace TrafficSpecWitness.NRS_484B_587_2b`, `def scenarios : List Scenario`
- imports: the rule file imports `TrafficSpec.Core.Language.Rule` only; the witness file imports `TrafficSpec.Rules.NRS_484B.NRS_484B_587_2b` and `TrafficSpec.Core.Evidence.Builders`
- both files exist already, written by the harness from the node (below); they build, and every declaration the gate compares is filled in — your work is the formulas and the scenes

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

### The `Rule`, `Binder`, `Operationalization` and `Scenario` values (`Language/Rule.lean`, `Vocab/Params.lean`, `Evidence/Builders.lean`)
```lean
structure Binder where
  name : String
  cls : Formula

structure Rule where
  id : String                                   -- the node id, derived from the law id
  laws : List String                            -- the corpus ids this rule formalizes
  binders : List Binder
  applicability : Formula
  obligation : Formula
  assumptions : List AsmId := []
  intentions : List IntId := []                 -- the declared intentions its formulas read
  operationalizations : List Operationalization := []
  residues : List String := []                  -- what the text says and the rule does not capture
  narrowings : List Narrowing := []             -- readings the coder chose on carried spans
  surrogate : Bool := false

structure Operationalization where
  standard : String            -- the clause's words for the standard
  concepts : List String       -- the `drv.*` and atom ids that bound it (one standard may pair several)
  params : List ParamName      -- the parameters the bound uses
  convention : String          -- where the values come from
  surrogate : Bool := false    -- true when the standard is the whole duty

inductive Verdict
  | violated
  | compliant
  | notApplicable
  | unknown (why : List UnknownReason)

structure Scenario where
  name : String
  rule : String
  trace : Trace
  reading : Reading
  manifest : Manifest
  grounding : List (String × TrackId)
  regions : List (String × RegionId) := []   -- an instance's region formals, each a region of the trace
  expected : Verdict
  window : Option (Timestamp × Timestamp) := none
  boundary : String := ""
```
`AsmId` and `ParamName` are `String`. A witness's `expected` is `.violated`, `.compliant`, `.notApplicable`
or `.unknown []` (compared by tag). `grounding` maps binder names to track ids; `window` is a closed range
of timestamps (milliseconds). `boundary` is set only on a scenario the plan declares a history boundary for:
that witness stays unknown for a window truncated at its trace's start, and for nothing else.

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

### Concept catalogue (accepted concepts; call by Lean name = id with `.` → `_`)
| id | kind | contract | definition | args | params | reads | calls |
|---|---|---|---|---|---|---|---|
| `drv.lane.entering_adjacent_lane` | formula | Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The event is recognized at the first observation at which a's footprint overlaps r2, and conduct before the previous observation is not read. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, where there is no previous observation, or where the adjacency of the two lanes is not observed, it is unknown. |  | a:track, r1:region, r2:region, s:literal['left', 'right'] |  | rel.occupies, st.lane_adjacency | no concept |
| `drv.motion.complete_halt` | formula | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. | DEF-NRS-484A-255 | a:track | speed_tol (m/s) | kin.speed | no concept |

### Atom ids (`Vocab/Ontology/Ids.lean`; a manifest, a claim and `Build.manifest` use the id, a formula uses the Lean name = id with `.` → `_`)
`ru.motor_vehicle`, `ru.motorcycle`, `ru.moped`, `ru.bus`, `ru.transit_bus`, `ru.school_bus`, `ru.taxicab`, `ru.tour_bus_or_limousine`, `ru.truck`, `ru.commercial_motor_vehicle`, `ru.trailer_or_combination`, `ru.bicycle`, `ru.electric_bicycle`, `ru.electric_scooter`, `ru.pedestrian`, `ru.pedestrian_with_white_cane_or_guide_animal`, `ru.child`, `ru.emergency_vehicle`, `ru.fire_apparatus`, `ru.official_vehicle`, `ru.rail_vehicle`, `ru.occupant_count`, `ru.rider_posture`, `ru.subject`, `ru.aggregate`, `kin.time`, `kin.position`, `kin.heading`, `kin.velocity`, `kin.speed`, `kin.accel_longitudinal`, `kin.yaw_rate`, `kin.extent`, `kin.steer_angle`, `kin.path_length`, `kin.engine_running`, `kin.parking_brake`, `kin.gear`, `kin.throttle`, `kin.service_brake`, `st.highway`, `st.travel_region`, `st.roadway`, `st.lane`, `st.lane_direction`, `st.lane_adjacency`, `st.lane_connectivity`, `st.lane_enters`, `st.on_way`, `st.entrance_of`, `st.lane_marking`, `st.centre_line`, `st.road_edge`, `st.shoulder`, `st.sidewalk`, `st.median_or_divider`, `st.one_way_roadway`, `st.intersection`, `st.crosswalk`, `st.stop_line`, `st.driveway_or_alley_entrance`, `st.alley`, `st.curvature`, `st.grade`, `st.crest`, `st.sight_distance`, `st.sight_along_way`, `st.railway_crossing`, `st.controlled_access`, `st.elevated_structure`, `st.bicycle_lane_or_path`, `st.reserved_lane`, `st.centre_turn_lane`, `st.turn_lane`, `st.parking_space`, `st.curb_zone`, `st.transit_stop`, `st.safety_zone`, `st.pedestrian_grade_separation`, `st.fire_hydrant`, `st.fire_station_entrance`, `st.roundabout`, `st.lane_width`, `st.region_geometry`, `st.obstruction`, `rel.occupies`, `dev.traffic_signal`, `dev.pedestrian_signal`, `dev.lane_control_signal`, `dev.speed_limit_beacon`, `dev.crossing_warning_signal`, `dev.stop_sign`, `dev.yield_sign`, `dev.speed_limit_sign`, `dev.regulatory_sign`, `dev.zone_sign`, `dev.railway_signal_or_gate`, `dev.temporary_traffic_control`, `dev.human_direction`, `dev.governs`, `dev.position`, `dev.inoperative`, `sig.turn_indicator`, `sig.brake_lamp`, `sig.hazard`, `sig.headlamp`, `sig.position_lamp`, `sig.compression_brake`, `sig.warning_lamp`, `sig.siren`, `sig.horn`, `sig.hand_signal`, `sig.door_open`, `env.darkness`, `env.precipitation`, `env.wet_road`, `env.ice_or_snow`, `env.visibility`, `env.civil_time`, `rel.centre_distance`, `rel.surface_gap`, `rel.ahead_behind_in_lane`, `rel.longitudinal_overlap`, `rel.oncoming`, `rel.same_direction`, `rel.bearing`, `rel.contact`, `rel.visible`

Names a formula may use in `Formula.atom` (`Semantics.boolAtomNames`):
```
"ru_subject", "ru_aggregate", "ru_rider_posture", "ru_rider_posture_on_seat", "ru_rider_posture_standing_on_deck",
    "ru_rider_posture_holding_another_vehicle", "ru_rider_posture_stunt", "ru_emergency_vehicle_kind",
    "ru_official_vehicle_kind", "kin_engine_running", "kin_parking_brake",
    "st_road_edge_paved", "st_shoulder_paved", "st_median_or_divider_opening",
    "st_crosswalk_marked", "st_reserved_lane_class", "st_turn_lane_side", "st_parking_space_designation",
    "st_curb_zone_kind", "st_curb_zone_colour", "st_obstruction_kind", "st_lane_adjacency", "st_lane_adjacency_left",
    "st_lane_adjacency_right", "st_lane_connectivity", "st_lane_enters", "st_on_way", "st_entrance_of", "st_lane_marking", "st_lane_marking_left", "st_lane_marking_right",
    "rel_occupies", "dev_traffic_signal_shows", "dev_traffic_signal_uncovered", "dev_pedestrian_signal_state",
    "dev_pedestrian_signal_countdown", "dev_lane_control_signal_state", "dev_speed_limit_beacon_flashing",
    "dev_crossing_warning_signal_active", "dev_speed_limit_sign_kind", "dev_regulatory_sign_code",
    "dev_zone_sign_kind", "dev_zone_sign_end", "dev_railway_signal_or_gate_lights",
    "dev_railway_signal_or_gate_gate", "dev_railway_signal_or_gate_bell", "dev_human_direction_role",
    "dev_human_direction_indication", "dev_governs", "dev_inoperative",
    "sig_turn_indicator", "sig_brake_lamp", "sig_hazard", "sig_headlamp", "sig_position_lamp",
    "sig_warning_lamp", "sig_siren", "sig_horn", "sig_hand_signal",
    "sig_door_open", "sig_compression_brake", "env_darkness", "env_precipitation", "env_wet_road",
    "env_ice_or_snow", "rel_ahead_behind_in_lane", "rel_ahead_in_lane", "rel_behind_in_lane", "rel_oncoming",
    "rel_same_direction", "rel_bearing", "rel_contact", "rel_visible"
```
Names a formula may use in `Term.measure` (`Semantics.measureNames`):
```
"kin_time", "kin_position", "kin_heading", "kin_velocity", "kin_speed", "kin_accel_longitudinal",
    "kin_yaw_rate", "kin_extent", "kin_steer_angle", "kin_path_length", "kin_gear", "kin_throttle", "kin_service_brake", "ru_occupant_count",
    "ru_rider_posture_hands_on_controls", "ru_electric_bicycle_class", "st_lane_direction", "st_lane_adjacency",
    "st_lane_adjacency_ordinal", "st_lane_adjacency_count", "st_lane_width", "st_curvature", "st_grade",
    "st_sight_distance", "st_sight_along_way", "st_parking_space_angle", "st_region_geometry", "st_region_geometry_distance",
    "dev_position", "dev_speed_limit_sign_value", "env_visibility", "env_civil_time",
    "rel_centre_distance", "rel_surface_gap", "rel_longitudinal_overlap", "rel_bearing"
```
Argument kinds per position (`Semantics.atomArgSorts`; `none` marks a literal position such as a side or a selector):
```lean
def atomArgSorts (name : String) : Option (List (Option EntityKind)) :=
  let t := some EntityKind.track; let r := some EntityKind.region; let d := some EntityKind.device
  match name with
  | "rel_occupies" => some [t, r]
  | "ru_aggregate" => some [t, none]
  | "dev_governs" => some [d, r]
  | "st_region_geometry_distance" | "st_sight_along_way" => some [t, r]
  | "st_lane_adjacency" => some [r, none, r]
  | "st_lane_adjacency_left" | "st_lane_adjacency_right" | "st_lane_connectivity" | "st_lane_enters" | "st_on_way"
  | "st_entrance_of" => some [r, r]
  | "st_lane_marking" => some [r, none, none, none]
  | "rel_oncoming" | "rel_same_direction" | "rel_ahead_behind_in_lane" | "rel_ahead_in_lane"
  | "rel_behind_in_lane" | "rel_contact" | "rel_visible" | "rel_centre_distance" | "rel_longitudinal_overlap" => some [t, t]
  | "rel_surface_gap" | "rel_bearing" => some [t, t, none]
  | n =>
    if !knowsAtom n then none
    else if n.startsWith "env_" || n == "kin_time" then some []
    else if n.startsWith "ru_" || n.startsWith "kin_" || n.startsWith "sig_" then some [t, none, none]
    else if n.startsWith "st_" then some [r, none, none]
    else if n.startsWith "dev_" then some [d, none, none]
    else none

```

### Atom accessors (`Vocab/Atoms.lean`): the name a formula uses, its arguments, and the scene field it reads
```lean
def ru_transit_bus (s : Scene) (x : TrackId) : Option Bool := hasClass s x .transitBus
def ru_child (s : Scene) (x : TrackId) : Option Bool := hasClass s x .child
def ru_emergency_vehicle (s : Scene) (x : TrackId) : Option Bool := hasClass s x .emergencyVehicle
def ru_official_vehicle (s : Scene) (x : TrackId) : Option Bool := hasClass s x .officialVehicle
def ru_aggregate (s : Scene) (x : TrackId) (members : List RoadUserClass) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def ru_occupant_count (s : Scene) (x : TrackId) : Option Nat := (s.user x).bind (·.occupants)
def ru_emergency_vehicle_kind (s : Scene) (x : TrackId) : Option EmergencyKind := (s.user x).bind (·.emergencyKind)
def ru_official_vehicle_kind (s : Scene) (x : TrackId) : Option OfficialKind := (s.user x).bind (·.officialKind)
def kin_speed (s : Scene) (x : TrackId) : Option Q := (s.user x).bind (·.kin.speed)
def isKind (s : Scene) (r : RegionId) (k : StructureKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_highway (s : Scene) (r : RegionId) : Option Bool := isKind s r .highway
def st_lane (s : Scene) (r : RegionId) : Option Bool := isKind s r .lane
def st_lane_adjacency (s : Scene) (r : RegionId) : Option LaneInfo := (s.structure? r).bind (·.lane)
def st_lane_adjacency_left (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.leftNeighbour)
def st_lane_adjacency_right (s : Scene) (r : RegionId) : Option RegionId := (st_lane_adjacency s r).bind (·.rightNeighbour)
def st_lane_adjacency_ordinal (s : Scene) (r : RegionId) : Option Nat := (st_lane_adjacency s r).bind (·.ordinalFromLeft)
def st_lane_adjacency_count (s : Scene) (r : RegionId) : Option Nat := (st_lane_adjacency s r).bind (·.countInDirection)
def st_lane_left_of (s : Scene) (r r' : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_lane_right_of (s : Scene) (r r' : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def st_on_way (s : Scene) (r : RegionId) : Option (List RegionId) := (s.structure? r).bind (·.ways)
def st_lane_marking (s : Scene) (r : RegionId) : Option ((Option (MarkingType × MarkingColour)) × (Option (MarkingType × MarkingColour))) :=  -- (body continues in Vocab/Atoms.lean)
def st_lane_marking_left (s : Scene) (r : RegionId) : Option (MarkingType × MarkingColour) := (st_lane_adjacency s r).bind (·.markingLeft)
def st_lane_marking_right (s : Scene) (r : RegionId) : Option (MarkingType × MarkingColour) := (st_lane_adjacency s r).bind (·.markingRight)
def st_shoulder (s : Scene) (r : RegionId) : Option Bool := isKind s r .shoulder
def st_shoulder_paved (s : Scene) (r : RegionId) : Option Bool := (s.structure? r).bind (·.paved)
def st_controlled_access (s : Scene) (r : RegionId) : Option Bool := isKind s r .controlledAccess
def footprint (s : Scene) (x : TrackId) : Option (List Vec) := do
def regionsOfKind (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def regionCandidates (s : Scene) (k : StructureKind) : List RegionId :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies (s : Scene) (x : TrackId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def rel_occupies_regions (s : Scene) (x : TrackId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devKind (s : Scene) (d : DeviceId) (k : DeviceKind) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def dev_regulatory_sign (s : Scene) (d : DeviceId) : Option Bool := devKind s d .regulatorySign
def dev_regulatory_sign_code (s : Scene) (d : DeviceId) : Option SignCode := (s.device d).bind (·.code)
def dev_regulatory_sign_conditions (s : Scene) (d : DeviceId) : Option Conditions := (s.device d).bind (·.conditions)
def dev_zone_sign (s : Scene) (d : DeviceId) : Option Bool := devKind s d .zoneSign
def dev_zone_sign_kind (s : Scene) (d : DeviceId) : Option ZoneKind := (s.device d).bind (·.zoneKind)
def dev_zone_sign_end (s : Scene) (d : DeviceId) : Option Bool := (s.device d).bind (·.isEnd)
def dev_zone_sign_conditions (s : Scene) (d : DeviceId) : Option Conditions := (s.device d).bind (·.conditions)
def dev_governs (s : Scene) (d : DeviceId) (r : RegionId) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def dev_governs_regions (s : Scene) (d : DeviceId) : Option (List RegionId) :=  -- (body continues in Vocab/Atoms.lean)
def devicesOfKind (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def deviceCandidates (s : Scene) (k : DeviceKind) : List DeviceId :=  -- (body continues in Vocab/Atoms.lean)
def sig_hazard (s : Scene) (x : TrackId) : Option Bool := (s.user x).bind (·.sig.hazard)
def sig_warning_lamp (s : Scene) (x : TrackId) : Option (List WarningLamp) := (s.user x).bind (·.sig.warningLamps)
def sig_warning_lamp_colour (s : Scene) (x : TrackId) (c : LampColour) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def sig_warning_lamp_shows (s : Scene) (x : TrackId) (c : LampColour) (m : LampMode) : Option Bool :=  -- (body continues in Vocab/Atoms.lean)
def env_civil_time (s : Scene) : Option CivilTime := s.env.civilTime
```

(The accessor and primitive tables are cut to what the record claims and what its concepts read; every other name is off limits for this task, and the whole tables are in the files named.)

### Primitives (`Vocab/Primitives.lean`): Lean signature (the parameters after the tracks are the formula's `params`, in order), contract, formula arity
```lean
def prim_conditions_hold (c : Ctx) (d : DeviceId) (x : TrackId) : Array R
    -- The legend conditions of device d hold now for road user x: a time window on a listed day (or a calendar class the scene declares), any occupancy or class condition, children present.
    -- formula form: args [d, x] params []
```
Argument kinds (`Primitives.argSorts`):
```lean
def argSorts (name : String) : Option (List (Option EntityKind)) :=
  let t := some EntityKind.track
  match name with
  | "prim_heading_change" => some [t]
  | "prim_closest_approach_within" | "prim_closest_approach_time" | "prim_closest_approach_distance" => some [t, t]
  | "prim_conditions_hold" => some [some EntityKind.device, t]
  | "prim_region_lateral_offset" => some [t, some EntityKind.region]
  | "prim_region_offset_along" => some [t, some EntityKind.region, some EntityKind.region]
  | _ => none

```
A Boolean primitive is `.derived "prim_x" args params`; a `QR`-valued one is `Term.quantity "prim_x" args params`.

### Enumeration spellings (`Vocab/Ontology/*.lean`): `Arg.lit` spelling → Lean constructor (the spelling for `existsRegion (.lit "kind")` and literal arguments, the constructor for `Build.*` and class lists)
- `DeviceKind`: `traffic_signal`→`.trafficSignal`, `pedestrian_signal`→`.pedestrianSignal`, `lane_control_signal`→`.laneControlSignal`, `speed_limit_beacon`→`.speedLimitBeacon`, `crossing_warning_signal`→`.crossingWarningSignal`, `stop_sign`→`.stopSign`, `yield_sign`→`.yieldSign`, `speed_limit_sign`→`.speedLimitSign`, `regulatory_sign`→`.regulatorySign`, `zone_sign`→`.zoneSign`, `railway_signal_or_gate`→`.railwaySignalOrGate`, `temporary_traffic_control`→`.temporaryTrafficControl`, `human_direction`→`.humanDirection`
- `ArrowDir`: `left`→`.left`, `right`→`.right`, `straight`→`.straight`, `u_turn`→`.uTurn`
- `SignalIndication`: `circular_green`→`.circularGreen`, `circular_yellow`→`.circularYellow`, `circular_red`→`.circularRed`, `flashing_red`→`.flashingRed`, `flashing_yellow`→`.flashingYellow`, `dark`→`.dark`, `unknown`→`.unknown`, `green_arrow(<ArrowDir>)`→`.greenArrow`, `yellow_arrow(<ArrowDir>)`→`.yellowArrow`, `red_arrow(<ArrowDir>)`→`.redArrow`, `flashing_yellow_arrow(<ArrowDir>)`→`.flashingYellowArrow`
- `PedSignalState`: `walk`→`.walk`, `dont_walk_flashing`→`.dontWalkFlashing`, `dont_walk_steady`→`.dontWalkSteady`, `dark`→`.dark`
- `LaneControlState`: `green_down_arrow`→`.greenDownArrow`, `red_x`→`.redX`, `yellow_x`→`.yellowX`, `dark`→`.dark`, `yellow_arrow(<ArrowDir>)`→`.yellowArrow`
- `SpeedSignKind`: `maximum`→`.maximum`, `minimum`→`.minimum`, `structure_maximum`→`.structureMaximum`, `zone`→`.zone`
- `SignCode`: `no_left_turn`→`.noLeftTurn`, `no_right_turn`→`.noRightTurn`, `no_u_turn`→`.noUTurn`, `no_straight`→`.noStraight`, `one_way`→`.oneWay`, `keep_right`→`.keepRight`, `do_not_enter`→`.doNotEnter`, `wrong_way`→`.wrongWay`, `no_stopping`→`.noStopping`, `no_standing`→`.noStanding`, `no_parking`→`.noParking`, `angle_parking`→`.angleParking`, `right_turn_only`→`.rightTurnOnly`, `entrance`→`.entrance`, `exit`→`.exit`, `closed_to_traffic`→`.closedToTraffic`, `exempt_crossing`→`.exemptCrossing`, `abandoned_crossing`→`.abandonedCrossing`, `shoulder_use_permitted`→`.shoulderUsePermitted`, `bicycles_prohibited`→`.bicyclesProhibited`, `pedestrians_prohibited`→`.pedestriansProhibited`, `nonmotorized_prohibited`→`.nonmotorizedProhibited`, `motor_vehicles_prohibited`→`.motorVehiclesProhibited`, `truck_route`→`.truckRoute`, `no_trucks`→`.noTrucks`
- `ZoneKind`: `school`→`.school`, `school_crossing`→`.schoolCrossing`, `pedestrian_safety`→`.pedestrianSafety`, `temporary_traffic_control`→`.temporaryTrafficControl`, `no_passing`→`.noPassing`, `high_occupancy_lane`→`.highOccupancyLane`, `heavy_vehicle_lane`→`.heavyVehicleLane`, `speed_zone`→`.speedZone`, `narrow_highway`→`.narrowHighway`, `hazardous_place`→`.hazardousPlace`, `parking_restricted`→`.parkingRestricted`, `trail`→`.trail`
- `RailLights`: `flashing`→`.flashing`, `dark`→`.dark`
- `GateState`: `up`→`.up`, `lowering`→`.lowering`, `down`→`.down`, `raising`→`.raising`, `none`→`.none`
- `HumanRole`: `police_officer`→`.policeOfficer`, `flagger`→`.flagger`, `school_crossing_guard`→`.schoolCrossingGuard`, `railroad_flagger`→`.railroadFlagger`
- `HumanIndication`: `stop`→`.stop`, `proceed`→`.proceed`, `slow`→`.slow`, `turn(<ArrowDir>)`→`.turn`
- `RoadUserClass`: `motor_vehicle`→`.motorVehicle`, `motorcycle`→`.motorcycle`, `moped`→`.moped`, `bus`→`.bus`, `transit_bus`→`.transitBus`, `school_bus`→`.schoolBus`, `taxicab`→`.taxicab`, `tour_bus_or_limousine`→`.tourBusOrLimousine`, `truck`→`.truck`, `commercial_motor_vehicle`→`.commercialMotorVehicle`, `trailer_or_combination`→`.trailerOrCombination`, `bicycle`→`.bicycle`, `electric_bicycle`→`.electricBicycle`, `electric_scooter`→`.electricScooter`, `pedestrian`→`.pedestrian`, `pedestrian_with_white_cane_or_guide_animal`→`.pedestrianWithWhiteCaneOrGuideAnimal`, `child`→`.child`, `emergency_vehicle`→`.emergencyVehicle`, `fire_apparatus`→`.fireApparatus`, `official_vehicle`→`.officialVehicle`, `rail_vehicle`→`.railVehicle`
- `EmergencyKind`: `police`→`.police`, `fire`→`.fire`, `ambulance`→`.ambulance`, `other`→`.other`
- `OfficialKind`: `tow`→`.tow`, `utility`→`.utility`, `highway_maintenance`→`.highwayMaintenance`, `incident_management`→`.incidentManagement`, `regulatory_agency`→`.regulatoryAgency`, `coroner`→`.coroner`, `armored_car`→`.armoredCar`, `municipal`→`.municipal`, `other`→`.other`
- `TurnIndicatorState`: `off`→`.off`, `left`→`.left`, `right`→`.right`
- `HeadlampState`: `off`→`.off`, `low_beam`→`.lowBeam`, `high_beam`→`.highBeam`
- `LampColour`: `red`→`.red`, `blue`→`.blue`, `amber`→`.amber`, `white`→`.white`
- `LampMode`: `flashing`→`.flashing`, `rotating`→`.rotating`, `steady`→`.steady`
- `Facing`: `front`→`.front`, `rear`→`.rear`, `side`→`.side`
- `HandSignal`: `no_signal`→`.noSignal`, `left`→`.left`, `right`→`.right`, `stop_or_slow`→`.stopOrSlow`, `re_enter`→`.reEnter`
- `DoorSide`: `traffic`→`.traffic`, `curb`→`.curb`
- `StructureKind`: `highway`→`.highway`, `travel_region`→`.travelRegion`, `roadway`→`.roadway`, `lane`→`.lane`, `centre_line`→`.centreLine`, `road_edge`→`.roadEdge`, `shoulder`→`.shoulder`, `sidewalk`→`.sidewalk`, `median_or_divider`→`.medianOrDivider`, `one_way_roadway`→`.oneWayRoadway`, `intersection`→`.intersection`, `crosswalk`→`.crosswalk`, `stop_line`→`.stopLine`, `driveway_or_alley_entrance`→`.drivewayOrAlleyEntrance`, `alley`→`.alley`, `crest`→`.crest`, `railway_crossing`→`.railwayCrossing`, `controlled_access`→`.controlledAccess`, `elevated_structure`→`.elevatedStructure`, `bicycle_lane_or_path`→`.bicycleLaneOrPath`, `reserved_lane`→`.reservedLane`, `centre_turn_lane`→`.centreTurnLane`, `turn_lane`→`.turnLane`, `parking_space`→`.parkingSpace`, `curb_zone`→`.curbZone`, `transit_stop`→`.transitStop`, `safety_zone`→`.safetyZone`, `pedestrian_grade_separation`→`.pedestrianGradeSeparation`, `fire_hydrant`→`.fireHydrant`, `fire_station_entrance`→`.fireStationEntrance`, `roundabout`→`.roundabout`, `obstruction`→`.obstruction` (abstract, read by a formula only and never a structure's label or unobserved kind: `travel_region`)
- `MarkingType`: `none`→`.none`, `broken`→`.broken`, `solid`→`.solid`, `double_solid`→`.doubleSolid`, `solid_broken`→`.solidBroken`, `dotted`→`.dotted`, `curb`→`.curb`
- `MarkingColour`: `white`→`.white`, `yellow`→`.yellow`, `other`→`.other`
- `ReservedClass`: `high_occupancy`→`.highOccupancy`, `bus`→`.bus`, `heavy_vehicle`→`.heavyVehicle`, `other`→`.other`
- `TurnSide`: `left`→`.left`, `right`→`.right`
- `ParkingDesignation`: `general`→`.general`, `disabled`→`.disabled`, `disabled_side_lift`→`.disabledSideLift`, `access_aisle`→`.accessAisle`, `municipal`→`.municipal`, `charging`→`.charging`
- `CurbZoneKind`: `passenger_loading`→`.passengerLoading`, `freight_loading`→`.freightLoading`, `tour_bus_loading`→`.tourBusLoading`, `restricted_parking`→`.restrictedParking`, `bus_stop`→`.busStop`, `taxicab_stand`→`.taxicabStand`, `fire_lane`→`.fireLane`, `no_stopping`→`.noStopping`, `no_parking`→`.noParking`
- `CurbColour`: `red`→`.red`, `yellow`→`.yellow`, `white`→`.white`, `blue`→`.blue`, `gray`→`.gray`, `none`→`.none`
- `ObstructionKind`: `debris`→`.debris`, `excavation`→`.excavation`, `hose`→`.hose`, `barrier`→`.barrier`, `stalled_vehicle_wreckage`→`.stalledVehicleWreckage`, `sidewalk_fixture`→`.sidewalkFixture`, `mail_drop_box`→`.mailDropBox`, `other`→`.other`

### The world a witness builds (`Vocab/World.lean`)
```lean
structure Kin where
  position : Option Vec := none          -- m
  heading : Option Vec := none           -- unit vector
  velocity : Option Vec := none          -- m/s
  speed : Option Q := none               -- m/s
  accelLongitudinal : Option Q := none   -- m/s², signed along heading
  yawRate : Option Q := none             -- deg/s
  extent : Option (Q × Q × Q) := none    -- half-length, half-width, half-height, m
  steerAngle : Option Q := none          -- deg
  pathLength : Option Q := none          -- m since the start of the trace
  engineRunning : Option Bool := none    -- propulsion available
  parkingBrake : Option Bool := none     -- parking brake set
  gear : Option Int := none              -- negative reverse, zero neutral, positive forward
  throttle : Option Q := none            -- fraction of full travel applied
  serviceBrake : Option Q := none        -- fraction of full travel applied

structure Posture where
  onSeat : Option Bool := none
  handsOnControls : Option Nat := none
  standingOnDeck : Option Bool := none
  holdingAnotherVehicle : Option Bool := none
  stunt : Option Bool := none

structure WarningLamp where
  colour : LampColour
  mode : LampMode
  facing : Facing

structure Signals where
  turnIndicator : Option TurnIndicatorState := none
  brakeLamp : Option Bool := none
  hazard : Option Bool := none
  headlamp : Option HeadlampState := none
  positionLamp : Option Bool := none
  warningLamps : Option (List WarningLamp) := none
  siren : Option Bool := none
  horn : Option Bool := none
  handSignal : Option HandSignal := none
  doorsOpen : Option (List DoorSide) := none
  compressionBrake : Option Bool := none

structure RoadUser where
  track : TrackId
  classes : Option (List RoadUserClass) := none   -- a user may be several (a school bus is a bus)
  /-- Classes the source cannot tell for this user: membership in them is unknown, not false. -/
  unobservedClasses : List RoadUserClass := []
  emergencyKind : Option EmergencyKind := none
  officialKind : Option OfficialKind := none
  eBikeClass : Option Nat := none
  occupants : Option Nat := none
  posture : Posture := {}
  kin : Kin := {}
  sig : Signals := {}
  sightAlongWay : Option (List (RegionId × Q)) := none   -- per way, m

structure LaneInfo where
  direction : Option Vec := none
  leftNeighbour : Option RegionId := none
  rightNeighbour : Option RegionId := none
  ordinalFromLeft : Option Nat := none
  countInDirection : Option Nat := none
  leadsTo : Option (List RegionId) := none
  entersIntersection : Option RegionId := none   -- the intersection this carrier is an approach to
  markingLeft : Option (MarkingType × MarkingColour) := none
  markingRight : Option (MarkingType × MarkingColour) := none
  width : Option Q := none

structure Structure where
  id : RegionId
  kind : StructureKind
  /-- Kinds the source cannot tell for this region: whether it is one of them is unknown, not false. -/
  unobservedKinds : List StructureKind := []
  position : Option Vec := none             -- reference point (point-like structures)
  boundary : Option (List Vec) := none      -- polygon, for regions
  lane : Option LaneInfo := none
  paved : Option Bool := none
  opening : Option Bool := none
  marked : Option Bool := none
  curvature : Option Q := none              -- 1/m
  grade : Option Q := none                  -- ratio
  sightDistance : Option Q := none          -- m
  ways : Option (List RegionId) := none     -- the highway regions it lies on
  /-- For a stop line or a crosswalk: the carriers whose entrance into an intersection it marks.
      `entranceObserved` says the list is complete; where it is not, which carriers the line marks is
      unknown and `entranceOf` is empty. -/
  entranceOf : List RegionId := []
  entranceObserved : Bool := false
  reservedClass : Option ReservedClass := none
  turnSide : Option TurnSide := none
  parkingAngle : Option Q := none           -- deg
  designation : Option ParkingDesignation := none
  curbKind : Option CurbZoneKind := none
  curbColour : Option CurbColour := none
  obstructionKind : Option ObstructionKind := none

structure CivilTime where
  year : Nat
  month : Nat
  day : Nat
  weekday : Nat        -- 0 = Monday … 6 = Sunday
  minuteOfDay : Nat    -- 0 … 1439

structure TimeWindow where
  weekdays : List Nat := []
  calendarClass : Option AsmId := none
  startMinute : Nat := 0
  endMinute : Nat := 1440

structure Conditions where
  windows : List TimeWindow := []
  minOccupancy : Option Nat := none
  durationLimit : Option Q := none          -- s
  vehicleClass : Option RoadUserClass := none
  whenChildrenPresent : Bool := false

structure Device where
  id : DeviceId
  kind : DeviceKind
  /-- Kinds the source cannot tell for this device: whether it is one of them is unknown, not false. -/
  unobservedKinds : List DeviceKind := []
  position : Option Vec := none
  governs : List RegionId := []
  /-- Whether the source observes which regions the device governs; where it does not, `governs`
      is empty and no region is decidedly governed or not. -/
  governsObserved : Bool := true
  indications : Option (List SignalIndication) := none
  uncovered : Option Bool := none
  inoperative : Option Bool := none
  pedState : Option PedSignalState := none
  countdown : Option Bool := none
  laneControl : Option LaneControlState := none
  flashing : Option Bool := none
  active : Option Bool := none
  speedValue : Option Q := none                     -- m/s
  speedKind : Option SpeedSignKind := none
  code : Option SignCode := none
  zoneKind : Option ZoneKind := none
  isEnd : Option Bool := none
  conditions : Option Conditions := none
  railLights : Option RailLights := none
  gate : Option GateState := none
  bell : Option Bool := none
  humanRole : Option HumanRole := none
  humanIndication : Option HumanIndication := none

structure Env where
  darkness : Option Bool := none
  precipitation : Option Bool := none
  wetRoad : Option Bool := none
  iceOrSnow : Option Bool := none
  visibility : Option Q := none              -- m
  civilTime : Option CivilTime := none

structure MeasuredRelation where
  a : TrackId
  b : TrackId
  centreDistance : Option Q := none
  surfaceGap : Option (Q × Q) := none        -- nearest-point gap along, across a's heading; ≥ 0
  aAheadOfB : Option Bool := none
  longitudinalOverlap : Option Q := none     -- shared length of the projections on a's heading
  oncoming : Option Bool := none
  sameDirection : Option Bool := none
  bearing : Option Vec := none               -- b relative to a, in a's frame (long, lat)
  contact : Option Bool := none
  visible : Option Bool := none              -- b in a's line of sight

structure Scene where
  t : Timestamp
  subject : Option TrackId := none
  users : List RoadUser := []
  structures : List Structure := []
  devices : List Device := []
  /-- The tracks whose occupancy was observed: for them every region not listed in `occupies` is
      not occupied; for any other track `rel.occupies` is unknown. -/
  occupancyObserved : List TrackId := []
  occupies : List (TrackId × RegionId) := []
  relations : List MeasuredRelation := []
  env : Env := {}
  assumptions : List (AsmId × Bool) := []
  intents : List DeclaredIntent := []
  links : List (TrackId × TrackId) := []
```
Every `Option` field is `none` when unobserved, and an atom that reads a `none` field is unknown
(`absentAtom`), never false. A witness that wants an atom decided sets the field it reads.

### Units constructors (`Foundations/Units.lean`, namespace `Units`; every quantity in a witness or a declared literal is written through one)
```lean
def metres (n : Int) : Q := Q.ofInt n
def centimetres (n : Int) : Q := Q.mk' n 100
def millimetres (n : Int) : Q := Q.mk' n 1000
def micrometres (n : Int) : Q := Q.mk' n 1000000
def kilometres (n : Int) : Q := Q.ofInt (n * 1000)
def inches (n : Int) : Q := Q.mk' (n * 254) 10000          -- 25.4 mm exactly
def feet (n : Int) : Q := Q.mk' (n * 3048) 10000           -- 304.8 mm exactly
def yards (n : Int) : Q := Q.mk' (n * 9144) 10000
def miles (n : Int) : Q := Q.mk' (n * 1609344) 1000        -- 1609.344 m exactly
def seconds (n : Int) : Q := Q.ofInt n
def milliseconds (n : Int) : Q := Q.mk' n 1000
def minutes (n : Int) : Q := Q.ofInt (n * 60)
def hours (n : Int) : Q := Q.ofInt (n * 3600)
def metresPerSecond (n : Int) : Q := Q.ofInt n
def micrometresPerSecond (n : Int) : Q := Q.mk' n 1000000
def kmh (n : Int) : Q := Q.mk' (n * 1000) 3600              -- exactly 5/18 m/s per km/h
def mph (n : Int) : Q := Q.mk' (n * 44704) 100000           -- 0.44704 m/s exactly
def perMetre (n : Int) : Q := Q.ofInt n
def metresPerSecondSq (n : Int) : Q := Q.ofInt n
def micrometresPerSecondSq (n : Int) : Q := Q.mk' n 1000000
def degrees (n : Int) : Q := Q.ofInt n
def millidegrees (n : Int) : Q := Q.mk' n 1000
def ratio (a : Int) (b : Nat) : Q := Q.mk' a b
def percent (n : Int) : Q := Q.mk' n 100
```
`Q` is an exact rational: `Q.zero`, `Q.ofInt n`, `Q.mk' num den`, `Q.add/sub/mul/div/neg/half`; `Vec := Q × Q`, +x east, +y north. A `Term.lit q <unit>` carries one of the unit tags `.metre`, `.second`, `.metrePerSecond`, `.metrePerSecondSq`, `.degree`, `.degreePerSecond`, `.perMetre`, `.ratio`, `.count`.

### Builders (`Evidence/Builders.lean`, namespace `Build`; witnesses are built with these and record-update syntax `{ x with field := some v }`)
```lean
-- Cardinal unit headings in the world frame (+x east, +y north).
def east : Vec
def west : Vec
def north : Vec
def south : Vec
def scale (h : Vec) (k : Q) : Vec
-- A road user with position, heading and speed; velocity follows the heading, path length is the caller's (cumulative) figure, extents are half-length/half-width/half-height.
def user (track : TrackId) (classes : List RoadUserClass) (pos : Vec) (heading : Vec) (speed : Q) (halfExtent : Q × Q × Q) (pathLength : Option Q := none) : RoadUser
-- A road user of which only the position (and classes) was observed.
def sparseUser (track : TrackId) (classes : List RoadUserClass) (pos : Vec) : RoadUser
def withSignals (u : RoadUser) (f : Signals → Signals) : RoadUser
def withKin (u : RoadUser) (f : Kin → Kin) : RoadUser
-- A measured relation from `a` to `b`, with the measured fields the source supplies.
def relation (a b : TrackId) (f : MeasuredRelation → MeasuredRelation := id) : MeasuredRelation
def withRelations (s : Scene) (rs : List MeasuredRelation) : Scene
-- A region of a kind with a polygon boundary.
def region (id : RegionId) (kind : StructureKind) (boundary : List Vec) : Structure
-- An axis-aligned rectangular region from two corners.
def rect (id : RegionId) (kind : StructureKind) (x0 y0 x1 y1 : Q) : Structure
-- A lane with its direction and neighbours.
def lane (id : RegionId) (boundary : List Vec) (direction : Vec) (left right : Option RegionId := none) (ordinal count : Option Nat := none) (leadsTo : Option (List RegionId) := none) (enters : Option RegionId := none) : Structure
def point (id : RegionId) (kind : StructureKind) (pos : Vec) : Structure
def device (id : DeviceId) (kind : DeviceKind) (governs : List RegionId) (pos : Option Vec := none) : Device
def signal (id : DeviceId) (governs : List RegionId) (shows : List SignalIndication) : Device
def sign (id : DeviceId) (kind : DeviceKind) (governs : List RegionId) : Device
def speedLimit (id : DeviceId) (governs : List RegionId) (value : Q) (kind : SpeedSignKind) : Device
def zoneSign (id : DeviceId) (governs : List RegionId) (kind : ZoneKind) (isEnd : Bool) (conditions : Option Conditions := none) : Device
-- Occupancy from the geometry: every user inside every region whose boundary contains its position.
def occupancyFromGeometry (users : List RoadUser) (structures : List Structure) : List (TrackId × RegionId)
-- A scene; occupancy is derived from geometry unless given.
def scene (t : Timestamp) (subject : Option TrackId) (users : List RoadUser) (structures : List Structure) (devices : List Device) (occupies : Option (List (TrackId × RegionId)) := none) (env : Env := {}) (assumptions : List (AsmId × Bool) := []) (intents : List DeclaredIntent := []) : Scene
-- A trace from a scene generator over instants `t0, t0 + dt, …` (`dt` in seconds).
def trace (n : Nat) (t0 : Timestamp) (dt : Q) (f : Nat → Timestamp → Scene) : Trace
-- Repeat the first and last scenes for `before`/`after` seconds at spacing `dt`, so that windows at the ends of the interesting part are covered rather than truncated.
def pad (τ : Trace) (before after dt : Q) : Trace
def masked (m : Manifest) (τ : Trace) : Trace
-- A manifest that observes every atom except the listed ids (for a `blind` witness).
def manifest (absent : List String := []) (gap : Q := Q.zero) : Manifest
-- The operators that look back from the observation they judge, by the tag their truncation at the start of a trace carries: only these leave a history-boundary witness unknown.
def pastOps : List String
```
`Build.scene` derives occupancy from geometry (a user is in every region whose polygon contains its
position) unless `occupies` is given; `occupancyObserved` is every user built. `Build.trace n t0 dt f`
calls `f k t` for `k < n` at `t = t0 + k·dt` (dt in seconds, timestamps in milliseconds).
`Build.manifest ["<atom id>", …]` observes every atom except the listed ids: the `blind` witness.

### Contracts

| id | contract |
|---|---|
| `dev.governs` | relation: the travel regions whose traffic the device controls — a lane, reserved lane, turn lane, centre turn lane, bicycle lane or path, roadway, one-way roadway or shoulder — or an intersection, read as control of the junction itself and of nothing else (no closure to the lanes that enter it); never a highway, a controlled-access region or a region no vehicle travels in. Unknown where the source does not observe what a device governs **Not a stand-in for:** a position — the region a device governs is not where a halt is required |
| `dev.regulatory_sign` | a point regulation by catalogue **code**, with the same structured **conditions** attribute as `dev.zone_sign`, read as that row says (unconditional when empty, unknown when absent), where the sign states hours, days, a duration or a class: no_left_turn, no_right_turn, no_u_turn, no_straight, one_way, keep_right, do_not_enter, wrong_way, no_stopping, no_standing, no_parking, angle_parking, right_turn_only, entrance, exit, closed_to_traffic, exempt_crossing, abandoned_crossing, shoulder_use_permitted, bicycles_prohibited, pedestrians_prohibited, nonmotorized_prohibited, motor_vehicles_prohibited, truck_route, no_trucks **Not a stand-in for:** a manoeuvre or a road feature — a prohibition sign is a condition, a warning sign is not the hazard it warns of, and a sign is not a signal |
| `dev.zone_sign` | a sign that begins or ends a signed zone along the road; **kind** ∈ {school, school_crossing, pedestrian_safety, temporary_traffic_control, no_passing, high_occupancy_lane, heavy_vehicle_lane, speed_zone, narrow_highway, hazardous_place, parking_restricted, trail}; **end** attribute; **conditions** attribute: a structured reading of the sign's legend — a list of time windows (a set of weekdays or a calendar class such as school days, a start and an end time of day), a minimum occupancy, a duration limit, a vehicle class, or a "when children present" flag; a legend read with no restriction is the empty set (unconditional), a legend not read is absent (every condition unknown) **Not a stand-in for:** whether the condition holds now — that is `prim.conditions_hold` |
| `drv.lane.entering_adjacent_lane` | Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The event is recognized at the first observation at which a's footprint overlaps r2, and conduct before the previous observation is not read. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, where there is no previous observation, or where the adjacency of the two lanes is not observed, it is unknown. |
| `drv.motion.complete_halt` | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. |
| `env.civil_time` | the local calendar time of the observation: date, weekday, time of day (from the recording's metadata, not from the scene) **Not a stand-in for:** `kin.time`, which orders observations within a trace and carries no date |
| `kin.speed` | magnitude of velocity |
| `prim.conditions_hold` | the structured conditions of a device (`dev.zone_sign`, `dev.regulatory_sign`) hold at the observation for a road user: `env.civil_time` falls in one of its time windows on one of its days (a calendar class is an assumption), and any occupancy or class condition is met |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `ru.aggregate` | membership of a legal aggregate: the atom's literal argument is an aggregate id, `<definition id>::<term>` for the posted definition that applies, or `<law id>:<span>::<term>` for a definition the law itself makes, and the run's reading classifies every road-user class under that id by the definition's words as included, excluded (the definition leaves it out), covered (the definition admits its members only as members of named included classes, which a road user carries beside it, so its own label adds no membership evidence) or unresolved; true when the user carries an included class, unknown when no included class holds and the user carries an unresolved class or an included or unresolved class it might carry is unobserved, false otherwise: a covered or excluded class decides nothing **Not a stand-in for:** a named road-user class for which the applicable definitions and the run's representation decisions permit its own class atom — that class's own atom; an admitted aggregate stays an aggregate even when it contains only one class; a relational role such as who drives or controls a vehicle — never membership; nor a role the text describes by conduct (responding, overtaking) — a role is a derived concept |
| `ru.child` | pedestrian who is visibly a child |
| `ru.emergency_vehicle` | vehicle of a class the jurisdiction designates as emergency; **kind** ∈ {police, fire, ambulance, other} **Not a stand-in for:** a responding emergency vehicle — the class alone is not responding; its responding is conduct, carried by a concept, and an unobserved lamp or siren makes the rule unknown, not satisfied |
| `ru.occupant_count` | the number of persons in or on a vehicle (an integer attribute of a road user). A source that observes a change in it — a person arriving at or leaving a vehicle — but not a total, declares the count absent: what it observes then is the arrival or the departure, which is not this atom |
| `ru.official_vehicle` | a vehicle in official or contracted road service, identifiable by livery or equipment; **kind** ∈ {tow, utility, highway_maintenance, incident_management, regulatory_agency, coroner, armored_car, municipal, other} **Not a stand-in for:** an emergency vehicle |
| `ru.transit_bus` | bus in public transit service, identifiable by its livery or route display |
| `sig.hazard` | both indicators flashing together |
| `sig.warning_lamp` | a warning lamp lit; **colour** ∈ {red, blue, amber, white}, **mode** ∈ {flashing, rotating, steady}, **facing** ∈ {front, rear, side} **Not a stand-in for:** an audible warning |
| `st.controlled_access` | a highway with access only at designated points, and its entrance and exit lanes |
| `st.highway` | the entire public way between its boundary lines, including sidewalks and shoulders **Not a stand-in for:** the roadway |
| `st.lane` | a longitudinal strip of roadway for one line of vehicles **Not a stand-in for:** a half of the roadway or a lateral position within a lane — lane membership is not an offset from the edge, and lane ordinal equals roadway half only on a two-lane road **Refines:** `st.travel_region` |
| `st.lane_adjacency` | left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes |
| `st.lane_marking` | per side of a lane: **type** ∈ {none, broken, solid, double_solid, solid_broken, dotted, curb}, **colour** ∈ {white, yellow, other} |
| `st.on_way` | relation: the public way (a `highway` region) a structure region lies on — a lane, roadway, shoulder, crosswalk, stop line, median or any other part of it; an intersection lies on every way that meets there **Not a stand-in for:** nearness to a way (`st.region_geometry`), or the lane a lane leads into (`st.lane_connectivity`) |
| `st.shoulder` | the part of the highway beside the roadway not intended for vehicular traffic; **paved** attribute **Refines:** `st.travel_region` |

| parameter | value | unit | convention |
|---|---|---|---|
| `p.halt_speed_tolerance` | 0.1 | m/s | the speed at or below which a sampled speed counts as no movement: the source's speed resolution |

Admitted aggregates the node claims (a witness's road user is a member when it carries an included class; one carrying only an unresolved class makes the atom unknown):

- `DEF-NRS-484A-020::authorized_emergency_vehicle`: included (none); unresolved ru.bus, ru.commercial_motor_vehicle, ru.electric_bicycle, ru.electric_scooter, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.rail_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484A-030::bus`: included (none); unresolved ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.school_bus, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484A-280::tow_car`: included (none); unresolved ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck
- `DEF-NRS-484A-320::vehicle`: included ru.bus, ru.commercial_motor_vehicle, ru.emergency_vehicle, ru.fire_apparatus, ru.moped, ru.motor_vehicle, ru.motorcycle, ru.official_vehicle, ru.school_bus, ru.taxicab, ru.tour_bus_or_limousine, ru.trailer_or_combination, ru.transit_bus, ru.truck; unresolved ru.electric_scooter, ru.rail_vehicle

The catalogue is `results/full221-1116-1018/reading.json` (read-only). Values enter a witness's geometry only: a `forbid` scene breaks the bound by a clear margin, a `permit` scene keeps it by one.

Acquisition standard: profile `carla_scene_graph`. Every `headingSince` step bound in a rule is exactly `.param "p.heading_since_step_carla_scene_graph"`, the operator's reviewed parameter: name it as it is, never propose it or a value for it.

(no node accepted yet in this library; the skeletons below are the pattern, the Core surface the vocabulary)

```lean
-- library/TrafficSpec/Rules/NRS_484B/NRS_484B_587_2b.lean (as written by the harness)
/-
  NRS_484B_587_2b — NRS-484B-587-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except if required by an emergency
    e2 (exception): or as otherwise authorized by subsection 3
    e3 (boilerplate): [(3) appended below],
    e4 (subject): a person shall not drive a vehicle
    e5 (trigger): on a controlled-access highway:
    e6 (obligation): Across any solid white line that separates an entrance or exit lane from a marked traffic lane.
    e7 (exception): A person driving a vehicle described in
    e8 (reference): paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210
    e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.
    e11 (definitional): The provisions of subparagraph (1) of paragraph (c) of subsection 1 do not apply to:
    e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;
    e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;
    e14 (exception): (c) A traffic incident management vehicle;
    e15 (exception): (d) A tow car;
    e16 (exception): (e) A coroner vehicle;
    e17 (exception): or (f) A public transit motor bus,
    e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.

  Elements (span → atoms, derived):
    e1: atoms ['ru.emergency_vehicle', 'sig.warning_lamp', 'sig.hazard'], derived []
    e2: atoms ['dev.regulatory_sign'], derived []
    e4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    e5: atoms ['rel.occupies', 'st.controlled_access'], derived []
    e6: atoms ['st.lane_marking', 'st.lane', 'dev.governs', 'dev.regulatory_sign'], derived ['drv.lane.entering_adjacent_lane']
    e7: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e10: atoms ['rel.occupies', 'st.shoulder', 'st.controlled_access', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived []
    e12: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived [], borrowing ['e8']
    e13: atoms ['ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle'], derived [], borrowing ['e8']
    e14: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e15: atoms ['ru.aggregate=DEF-NRS-484A-280::tow_car'], derived [], borrowing ['e8']
    e16: atoms ['ru.official_vehicle'], derived [], borrowing ['e8']
    e17: atoms ['ru.aggregate=DEF-NRS-484A-030::bus', 'ru.transit_bus'], derived [], borrowing ['e8']
    e18: atoms ['rel.occupies', 'st.highway', 'st.on_way', 'st.shoulder', 'dev.governs', 'dev.regulatory_sign', 'prim.conditions_hold'], derived [], borrowing ['e8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    e8: NRS-484B-210-1: (c) A traffic incident management vehicle; (d) A tow car; (e) A coroner vehicle;

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_587_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- TODO(code): class formulas, applicability and obligation — from the node's elements,
-- operationalizations and compositions, using only the claimed names. `.tt` is the placeholder.

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .tt  -- TODO

/-- Applicability: e1 (exception): Except if required by an emergency; e2 (exception): or as otherwise authorized by subsection 3; e5 (trigger): on a controlled-access highway:; e7 (exception): A person driving a vehicle described in; e10 (exception): may drive that vehicle on a paved shoulder of a controlled-access highway where lawfully placed signage allows that vehicle to use the shoulder in that manner.; e12 (exception): (a) An authorized emergency vehicle described in NRS 484A.480;; e13 (exception): (b) A vehicle which has been issued a permit to operate as an authorized emergency vehicle pursuant to NRS 484A.490;; e14 (exception): (c) A traffic incident management vehicle;; e15 (exception): (d) A tow car;; e16 (exception): (e) A coroner vehicle;; e17 (exception): or (f) A public transit motor bus,; e18 (exception): that is being driven on the paved shoulder of a highway where lawfully placed signage allows that vehicle to use the shoulder in that manner. -/
def applicability : Formula := .tt  -- TODO

/-- Obligation: e6 (obligation): Across any solid white line that separates an entrance or exit lane from a marked traffic lane. -/
def obligation : Formula := .tt  -- TODO

def rule : Rule :=
  { id := "NRS_484B_587_2b"
    laws := ["NRS-484B-587-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["Introduces the list of NRS 484B.210(4) as appended; the exemption from the passing rule of NRS 484B.210(1)(c)(1) it states is that section's, not this duty's, and is not read here."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_587_2b

```

```lean
-- library/TrafficSpecWitness/NRS_484B/NRS_484B_587_2b.lean (as written by the harness)
/-
  Witnesses for NRS_484B_587_2b.

  TODO(code): describe the geometry once built — the carriageway, the bodies, the instants; every
  figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): On a controlled-access highway, the subject car in an entrance lane (governed by an entrance-coded sign) moves at 22 m/s and its footprint first reaches into the adjacent through lane across a solid white marking on that side. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `permit` (compliant): The subject car in the entrance lane merges into the through lane where the marking between them on that side is broken white. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `idle` (not_applicable): The subject car changes lanes across a solid white line on a surface street; it never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `blind` (unknown): The subject car moves from the entrance lane into the through lane on a controlled-access highway; the source does not observe lane markings. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_1` (not_applicable): An emergency vehicle with lit warning lamps crosses the solid white line from the through lane into an exit lane. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

/-- `branch_2` (compliant): The subject car crosses a solid white line between two through lanes, neither governed by an entrance or exit sign. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ ]  -- TODO users: Build.user <track> [<classes>] (x, y) <heading> <speed> (halfLen, halfWid, halfHt)
      [ ]  -- TODO structures: Build.rect / Build.lane / Build.point …
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_587_2b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_marking"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_587_2b

```

Run exactly this command, nothing more and nothing else:

```
python -m harness gate --run_id full221-1116-1018 --node_id NRS_484B_587_2b
```

It prints the verdict and its details. The verdicts on your files: SCOPE_VIOLATION, BUILD_FAIL, UNSOUND, CHECK_FAIL, UNANCHORED_VARIABLE, DECLARATION_MISMATCH, SCOPE_NARROWED, UNEXPRESSED, UNCLAIMED_ATOM, UNUSED_CLAIM, BARE_LITERAL, WITNESS_FAIL, VACUOUS, PARAM_MISMATCH, GATE_TIMEOUT, OK. `INFRA` is not one: the toolchain or the run did not let the gate judge your files. Budget: 6 runs; the harness re-runs the gate itself after you stop, on the files as they are then.


## Access

- You **edit** `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_587_2b.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_587_2b.lean` with the Edit and Write tools, and write
  `task_result.md` (and, when you report a concept, `dependency_defect.json`) in your working
  directory. Nothing else is writable.
- You **may read**, with the Read tool and by absolute path, the Core files under `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Core`
  when a question is not answered by the surface above (a primitive's exact reading of a field, a
  tolerance's sense). Read the one file that answers it; do not page through Core to re-derive
  what the surface already states. Core is frozen: you never edit it, and you never work around
  it. Nothing else is readable: not the harness, not other nodes' files beyond the example above,
  not the readings, the ontology or the law corpus. The gate is the interface to the harness; the
  node is the interface to the law.
- The **shell runs exactly one command**, the gate command below, as written: it runs from your
  working directory, so it needs no `cd`. Any other command — `cat`, `sed`, `grep`, `lake`,
  `python`, a redirection, a second command after `&&` — is denied and wastes a turn. If the
  gate's behaviour surprises you, report it in `task_result.md`; do not re-implement the gate.

## How evaluation reads a built scene

- Three values. An atom whose scene field is `none` is **unknown**, never false; a formula over
  an unknown atom is unknown unless another operand decides it (`and` with a false, `or` with a
  true). `idle` therefore needs a decided-false applicability, not an unobserved one; `blind`
  needs the masked atom to be the one that decides.
- `Build.user` sets position, heading, velocity, speed and extent; every other field
  (`sig`, `posture`, `occupants`, …) is set with `withSignals`/`withKin` or `{ u with … }`.
  `Build.scene` derives occupancy from the polygons unless `occupies` is given; a body across two
  regions is stated, since a reference point lies in one polygon.
- A binder is grounded to a track by `grounding`; a quantifier ranges over the scene's regions,
  devices or users of the kind named. A region that must exist for a leaf to speak is built.
- `holdsFor`/`since`/`once`-shaped lookbacks are truncated at the trace start and report unknown
  there: pad the trace (`Build.pad`) or set `window` to the instants the witness speaks about.
- The episode verdict aggregates the instants: violated if any instant is violated, else unknown
  if any is unknown, else compliant if any is compliant, else not applicable. A `permit` witness
  with one violated instant fails, and one with an unknown instant reports unknown.
- The rule's `manifest` in a witness is `Build.manifest` (all observed) or
  `Build.manifest ["<atom id>", …]` (those absent) — the `blind` witness masks the node's
  `masked` ids and nothing else.

## Hard rules

1. **Two files.** Edit `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpec/Rules/NRS_484B/NRS_484B_587_2b.lean` and `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/library/TrafficSpecWitness/NRS_484B/NRS_484B_587_2b.lean` only; their paths and the namespace
   `TrafficSpec.Rules.NRS_484B_587_2b` are derived from the node id and are not yours to choose. Declare
   every definition with `def`, never `private def`: each file has its own namespace, and every
   part of a rule or a witness stays reachable to the tools that inspect it.
2. **The rule declares what the node declares.** `laws`, `binders` (names, order), `assumptions`,
   `intentions`, `operationalizations`, `residues`, `surrogate` are the skeleton's; leave them. A residue is the
   plan's: words nothing carries. Where the record leaves the writing of a span the node carries
   open, you choose only among meanings its words already allow, and you declare each such choice
   — the formulas state the span more narrowly than its words — as a **narrowing**
   `{ span := "<span id>", why := "<why>", kind := "reading" }` in `narrowings`, and the header
   comment explains it. Where the span's words cannot be stated at
   all — no atom denotes them (`kind := "no_atom"`) or the language has no operator for them
   (`kind := "no_operator"`) — you declare that instead of a reading: the gate returns the node
   as `UNEXPRESSED` for the repair session to withdraw the span as a gap or re-map it, and a
   second such declaration on the same span files the gap with your words; a reading written
   around a missing operator is not a narrowing. `no_atom` means no atom of the surface can carry
   the words. Words that an atom of the surface can carry, but which the node does not claim, are a
   defect of the node's mapping: you never declare `no_atom` on them and never write them with that
   atom; the node is wrong, and you report it. The gate holds every narrowing to a span of the
   node's duty or its standards; a span that decides when the rule applies (a trigger, subject,
   condition or exception) is never narrowed, nor written with a weaker fact than the qualified one
   the record states: it is carried as the node maps it, or the node is wrong and you report it. Your narrowings are kept on the rule's record and shown to every later planning and repair
   session; a choice written only in prose is lost. `narrowings` holds only the readings you chose: the record's own
   narrowings, its observable readings included, are the plan's and are never restated there.
3. **Formulas use only claimed names.** Every atom, primitive and concept in `applicability`, the
   binder classes and `obligation` is claimed by an element or operationalization of the node,
   and every claimed name is used. Arguments are the node's binders, quantifier variables, or
   enumeration spellings from the Core surface. A claim of an aggregate is written as the
   atom `ru_aggregate` with the binder and the aggregate's id (what follows `=` in the claim)
   as its literal argument: the id, never the classes it covers.
3b. **Every quantified variable is anchored.** A region, device or user the rule quantifies over
   must be related to a binder through the formula — an anchoring relation (`rel_occupies` (a road user's footprint overlaps a lane / region) or `st_region_geometry` (the reference point and the boundary polygon of a structure region in the world frame) (or an accessor of one)) between a
   binder and the variable, a relation to a variable that is itself anchored, a relation to a
   binder, or a comparison that reads both. A quantifier with no such tie asks whether any entity
   of the scene qualifies, and the gate returns `UNANCHORED_VARIABLE`. If the node claims no
   anchoring atom, the node is wrong: report it. A region kind the record names is written as
   named: where a kind is refined by others, a quantifier over it covers them, and no exclusion the
   record does not state is added.
3c. **One region across formulas.** The applicability and the obligation are separate formulas: a
   region bound in one is not in scope in the other. Where the obligation speaks of the region the
   applicability selected, write in it the record's whole selection of that region again, with
   every relation and declared intention that fixed it, so that it denotes the same region; a shared
   variable name alone never makes two regions the same, and a quantifier over the kind alone never
   replaces the record's whole selection. Keep the quantifier the record states over the selected
   regions: where the record requires the duty at each region selected, write it for every selected
   region; where it allows a choice among them, keep the choice. A record that leaves either open
   is the record's defect: report it.
4. **Parameters, not values.** A quantity enters as `.param "<name>"` from the node's `params`.
   The only literals are zero, enumeration spellings, and the node's declared `literals`, each
   written through the `Units` constructor of its unit (`Units.<unit> <figure>`). What a formula
   may not say is listed with the formula language; the gate returns `CHECK_FAIL` on it.
   For `headingSince`, a shared concept takes the step bound through its own time formal; a rule
   uses exactly the reviewed step parameter named by the run's acquisition profile. Do not
   introduce a literal, alias, or expression for that bound.
5. **Standards are the node's operationalizations**, nothing else: the concept and parameters
   named there, no substitute.
6. **Compositions follow the node's `as`.** `exception`: `.not (.ruleApplies "<id>" map)` in the
   applicability; `condition`: `.ruleApplies "<id>" map` in the applicability; `compliance`:
   `.rule "<id>" map` where the node places it; `unless`: `.not (.ruleApplies "<id>" map)`
   conjoined into the formula of the span named in `scopes` (an exception or condition), so that
   span's content does not hold where that rule applies and the applicability as a whole is
   untouched. `map` binds every binder of the composed rule; a
   binder the node has no variable for is bound by `.existsUser "<var>" (…)` around the
   composition. You never inline another rule's content. A `definition` composition is no call:
   it records words borrowed from a source text, shown whole below the node, and the elements
   naming its span in `source_spans` write their meaning with their own atoms; never write
   `.rule` or `.ruleApplies` for it.
6a. **Observable readings.** A span the node reads through conduct (`kind: "observable_reading"`
   in its narrowings) is written from its element's atoms as any span is. It is the plan's
   narrowing, already on record: you do not restate it, and you never declare one the node does not.
   A declared intention the node carries (`intentions`) is the formula `intent` of the road user and
   the region the element of its place's span binds, read at the judged observation or in a window
   behind it, never in a window ahead.
6b. **The occasion of an act.** Where the node declares `occasion`, write a span read
   `at_recognition` at the declared recognition point. For `boundary: "window"`, write one read
   `some_moment` as `.not (.holdsFor .time W s (.not (.and U φ)))`, and one read `throughout` as
   `.holdsFor .time W s (.implies U φ)`, with `W` the occasion's `window` parameter, `s` the subject
   and `U` the formula of the `under_way` element, written from its atoms like any element and never
   `.tt`. For `boundary: "event"`, write the onset formula from the record's `onset` element and
   read `some_moment` or `throughout` over the declared act stretch from its observed onset to the
   recognition being judged, respecting the concept contract's extent. Use the declared onset of
   that occurrence; a fixed-length window, an unrelated edge, or an earlier occurrence is no
   substitute. Use the available operators only where their semantics express that boundary and
   quantification. Spans joined by `.and` and read at the same occasion are read together, so a
   `some_moment` reading requires one common observation for their conjunction, not different
   observations for its parts. Read `U` only as the record maps it. The contract states how long the
   act concept holds and what ends it; do not infer an event act's extent from a window. Where the
   record uses the act as an event, judge it once at its declared recognition, using
   `.rises (<act>)` for recognition represented by the concept becoming true. Missing required
   history leaves the dependent expression unknown where Core cannot decide it; other branches may
   still decide the verdict. Where the declared boundary or quantification cannot be expressed,
   report `no_operator` on its words instead of inventing a window. A named occasion `gap` follows
   that same route. A concept declaring `act` must implement the boundary its record states: its
   window formal is the actual look-back length for a window boundary, and its declared onset
   supplies the boundary for an event act. The `occasion_<span>_outside` witness places the span
   only outside the declared act stretch.
6c. **A duty with a history bound.** Where the node's `obligation` states a history bound, a search
   into the past ends exactly where the record says and nowhere else. Do not invent a history
   boundary from the recording's start, a subject's first observation, or a cumulative quantity
   whose origin is the recording's start. Preserve any event, time or distance window the record
   requires. A path length since the trace began is refused inside a search into the past. Each atom
   and primitive is used only as its contract states. Where the plan declares a history-boundary
   scenario, its witness is a trace in which the duty arises, the history the bound needs begins
   before the recording, the act is unrecorded, and no recorded act or visible end of the search
   decides the verdict; its `boundary` names the history the trace lacks, and it expects unknown. No
   other witness is unknown for a window truncated at the start of its trace.
7. **Witnesses are built, not described.** Each scenario is a `Scenario` built with the `Build.*`
   constructors from the node's narrative: `forbid` expects violated, `permit` compliant, `idle`
   not applicable, `blind` unknown with the masked atoms absent in its manifest. A scenario
   names the instants it speaks about (`window`) when the rule looks back in time. The planned
   scenarios are the minimum, not the set: the gate's adequacy rule fails the rule when a leaf
   moves no decided witness, and a duty with alternatives (two devices, two ways to comply, an
   exception with two limbs) has leaves the planned scenes never reach. Add `branch_<n>`
   witnesses, each expecting `violated` or `compliant`, or `not_applicable` where it shows a
   situation the words exclude from the duty, with a one-line narrative in a comment, until every
   leaf is exercised; they are the rule's tests, yours to write, not evidence of the reading. Every
   scenario the node plans (`branch_<n>`, `occasion_<span>`) is a witness of that name with the
   planned verdict. A fact the source does not observe is unknown, never made false to reach
   `not_applicable`. Literal values of one atom's enumeration tested in separate disjuncts count as
   one leaf: one scene exercises them.
8. **No history of your own.** The trace is a list of built scenes; you do not read captures,
   and you do not import anything but `TrafficSpec.Core.Language.Rule` in the rule file and the rule plus
   `TrafficSpec.Core.Evidence.Builders` in the witness file. A sign whose legend states no
   restriction carries `conditions := some {}`; `none` is a legend not read, on which every
   condition is unknown. A relation Core computes from the scene is never supplied; supply only one
   it cannot compute (the gate fails a witness that supplies one Core computes).
9. **Closed, total values.** No `sorry`, `admit`, `axiom`, `unsafe`, `partial`, `opaque`,
   `implemented_by`, `extern`, `native_decide`, `panic!`, `#eval`, `run_cmd`, `initialize` or `elab`
   anywhere in the two files; the rule is
   data and the gate checks its axioms.
10. **The gate decides.** Run it after each edit. Its verdict is the only acceptance signal; your
   own reading of your code is not.

## Procedure

Decide from the surface, then write; the surface is the API, the example is the style.

1. Read the node. List the atoms, primitives and concepts it claims and the parameters it names;
   pair each with the accessor, primitive or catalogue line of the surface that carries it.
2. Write the rule in one pass: binders → class formulas from `class_elements`; applicability from
   the trigger/condition elements; obligation from the obligation elements and
   operationalizations; compositions as `.rule`/`.ruleApplies`. Replace every `TODO` and `.tt`.
3. Write the four witnesses from the narratives, against the reading's values.
4. Run the gate. On `BUILD_FAIL`, `UNSOUND` or `CHECK_FAIL`, fix the Lean. On
   `UNANCHORED_VARIABLE`, tie the variable to a binder with a claimed anchoring atom, or report
   that the node claims none. On
   `DECLARATION_MISMATCH`, `UNCLAIMED_ATOM`, `UNUSED_CLAIM` or `BARE_LITERAL`, fix the rule
   against the node once; if the verdict persists, the node and the blueprint disagree — end the session
   and report it. On `WITNESS_FAIL`, first decide whether the witness or the formula is wrong
   against the node's narrative, then fix that one. On `VACUOUS`, a leaf does no work in any
   witness: either a witness must exercise it or the formula carries an atom the node should not
   have claimed — report the second case, do not delete the atom.
5. Finish on `OK`, or when the budget is spent, or when the node itself is wrong.

## Output

The two files, and `task_result.md` with: the final verdict; each gate run's verdict and what
changed after it; every choice the node left open and what you chose; **Why I finished**. If the
node is wrong, say which span, why, and what the plan agent must change.

**A concept that is wrong.** If a concept the node calls, directly or through another concept,
computes on a situation what its own contract excludes, write `dependency_defect.json`: the JSON object `{"concept_id": "<id>", "contract_words": "<its contract's words that decide it, verbatim>",
"kind": "holds_wrongly | fails_wrongly | undecided" (a quantity: "value_wrongly | undecided"), "situation": "<one sentence>",
"contract_verdict": "holds | fails"` (a quantity: `"contract_value": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}`)`,
"instance": {"literals": {...}, "nats": {...}, "params": {"<parameter>": [<value>, "<unit>"]}}, "grounding": {"<track formal>": <track id>},
"regions": {"<region formal>": <region id>},
"trace": {"scenes": [...]}, "at": <timestamp of a scene, ms>}`
— and finish. The harness runs the concept on your trace and an adjudicator judges the report by
the concept's contract before anything is charged; a report it does not uphold is your session's
defect, and the gate's verdict stands.

## Finish

Finish on `OK` with `task_result.md` written, or when the budget is spent, or when the node is
wrong. Never edit the blueprint, the ontology, Core, or another node's files.


## Where to write

Working directory: `/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-002/code/NRS_484B_587_2b`. Write `task_result.md` there.
