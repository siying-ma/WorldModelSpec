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

- `DEF-NRS-484A-080`: (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
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
- `DEF-NRS-482A-030`: “Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.
- `DEF-NRS-484A-130`: “Motor vehicle” means every vehicle which is self-propelled but not operated upon rails. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-482A-025`: “Automated driving system” has the meaning ascribed to it in SAE J3016.
- `DEF-NRS-482A-036`: “Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.
- `DEF-NRS-484A-150`: “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-484A-105`: “Intersection” means: (1) The area embraced within the prolongation or connection of the lateral curb lines, or, if none, then the lateral boundary lines of the roadways of two highways which join one another at, or approximately at, right angles, or the area within which vehicles traveling upon different highways joining at any other angle may come in conflict. (2) Where a highway includes two roadways 30 feet or more apart, then every crossing of each roadway of such divided highway by an intersecting highway shall be regarded as a separate intersection. In the event such intersecting highway also includes two roadways 30 feet or more apart, then every crossing of two roadways of such highways shall be regarded as a separate intersection. (3) The junction of an alley with a street, road or highway shall not constitute an intersection.
- `DEF-NRS-484A-220`: “Roadway” means that portion of a highway which is improved and ordinarily used for vehicular traffic, exclusive of the shoulder.
- `DEF-NRS-484A-070`: “Divided highway” means a highway divided into two or more roadways by means of a physical barrier or dividing section, constructed so as to impede the conflict of vehicular traffic traveling in opposite directions.
- `DEF-NRS-484A-015`: “Alley” means a highway: (1) Within a city block set apart for public use, vehicular traffic and local convenience. (2) Which primarily services access to the rear entrance of abutting property. (3) Designed for the special accommodation of abutting property, but not a cul-de-sac.
- `DEF-NRS-484A-265`: “Street” means the entire width between the boundary lines of every highway inside the territorial limits of a city when any part of such highway is open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-215`: “Road” means the entire width between the boundary lines of every highway outside the territorial limits of a city and open to the use of the public for purposes of vehicular traffic.
- `DEF-NRS-484A-065`: “Crosswalk” means: (1) That part of a highway at an intersection included within the connections of the lateral lines of the sidewalks on opposite sides of the highway measured from the curbs or, in the absence of curbs, from the edges of the traveled portions of highways; or (2) Any portion of a highway at an intersection or elsewhere distinctly indicated for pedestrian crossing by lines or other markings on the surface.
- `DEF-NRS-484A-240`: “Sidewalk” means that portion of a highway between the curb lines or the lateral lines of a highway and the adjacent property lines intended for the use of pedestrians.
- `DEF-NRS-484A-050`: “Combination of vehicles” means two or more vehicles coupled together.
- `DEF-NRS-484A-060`: “Controlled-access highway” means every highway to or from which owners or occupants of abutting lands and other persons have no legal right of access except at such points only and in such manner as may be determined by a public authority.
- `DEF-NRS-484A-040`: “Center” or “centerline” means a continuous or broken line marked upon the surface of a highway by paint or otherwise to indicate each portion of a highway allocated to traffic proceeding in the two opposite directions, and, if a line is not marked, it is an imaginary line in the highway equally distant from the edges or curbs of the highway.
- `DEF-NRS-484A-145`: “Official traffic-control device” means every sign, signal, marking and device not inconsistent with chapters 484A to 484E, inclusive, of NRS or prohibited by law, placed or erected by a public authority or railroad for the purpose of regulating, warning or guiding traffic.
- `DEF-NRS-484A-200`: “Railroad” means a carrier of persons or property upon cars, other than streetcars, operated upon stationary rails.
- `DEF-NRS-484A-180`: “Police officer” means every officer authorized to direct or regulate traffic or to make arrests for violations of traffic laws, ordinances or regulations.
- `DEF-NRS-484A-155`: “Park” or “parking” means the standing of a vehicle, whether occupied or not, otherwise than temporarily for the purpose of and while actually engaged in loading or unloading of merchandise or passengers.
- `DEF-NRS-484A-250`: “Stand” or “standing” means the halting of a vehicle, whether occupied or not, otherwise than for the purpose of and while actually engaged in receiving or discharging passengers.
- `DEF-NRS-484A-135`: “Motorcycle” means every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground, excluding an electric bicycle, a tractor or a moped.
- `DEF-NRS-484A-185`: (1) “Premises to which the public has access” means property in private or public ownership onto which members of the public regularly enter, are reasonably likely to enter, or are invited or permitted to enter as invitees or licensees, whether or not access to the property by some members of the public is restricted or controlled by a person or a device. (2) The term includes, but is not limited to: (a) A parking deck, parking garage or other parking structure. (b) A paved or unpaved parking lot or other paved or unpaved area where vehicles are parked or are reasonably likely to be parked. (c) A way that provides access to or is appurtenant to: (1) A place of business; (2) A governmental building; (3) An apartment building; (4) A mobile home park; (5) A residential area or residential community which is gated or enclosed or the access to which is restricted or controlled by a person or a device; or (6) Any other similar area, community, building or structure. (3) The term does not include: (a) A private way on a farm. (b) The driveway of an individual dwelling.
- `DEF-NRS-484A-190`: “Private way” or “driveway” means every way or place in private ownership and used for vehicular travel by the owner and those having express or implied permission from the owner, but not by other persons.


### The defined terms the laws use

- `DEF-NRS-484A-040` / "center": used by NRS-484B-213-1, NRS-484B-223-3a, NRS-484B-223-3b, NRS-484B-223-3c, NRS-484B-270-2b
- `DEF-NRS-484A-040` / "centerline": used by NRS-484B-400-2a, NRS-484B-400-2b
- `DEF-NRS-484A-045` / "city": used by LVMC-11-18-020, LVMC-11-22-020, LVMC-11-22-120-B, LVMC-11-27-010-A, LVMC-11-38-030, LVMC-11-40-180-B, LVMC-11-52-070, LVMC-11-52-130-A2, LVMC-11-52-340, NRS-484B-208-1
- `DEF-NRS-484A-050` / "combination of vehicles": used by NRS-484B-127-2, NRS-484B-127-3
- `DEF-NRS-484A-060` / "controlled-access highway": used by NRS-484B-208-1, NRS-484B-263, NRS-484B-587-1, NRS-484B-587-2a, NRS-484B-587-2b, NRS-484B-627-1c
- `DEF-NRS-484A-065` / "crosswalk": used by LVMC-11-18-020, LVMC-11-30-030, LVMC-11-30-050, LVMC-11-30-060-A, LVMC-11-30-070-B, LVMC-11-52-130-A12, NRS-484A-450-2, NRS-484A-450-3, NRS-484B-113-2, NRS-484B-250-4, NRS-484B-257-1, NRS-484B-280-1c, NRS-484B-283-1a, NRS-484B-287-1c, NRS-484B-293, NRS-484B-307-2a, NRS-484B-307-2b, NRS-484B-307-3a, NRS-484B-307-4a, NRS-484B-307-5a, NRS-484B-307-7a, NRS-484B-307-8a, NRS-484B-307-9a, NRS-484B-307-9b, NRS-484B-310-1, NRS-484B-450-1e
- `DEF-NRS-484A-070` / "divided highway": used by NRS-484B-227-1, NRS-484B-403-3
- `DEF-NRS-484A-080` / "driver": used by LVMC-11-12-070-B, LVMC-11-16-030, LVMC-11-16-040, LVMC-11-20-060, LVMC-11-30-030, LVMC-11-30-140-B, NRS-484A-450-2, NRS-484A-450-3, NRS-484B-113-2, NRS-484B-113-3, NRS-484B-117-1, NRS-484B-127-1, NRS-484B-127-2, NRS-484B-203-1, NRS-484B-208-1, NRS-484B-210-1, NRS-484B-210-2, NRS-484B-210-3, NRS-484B-213-2a, NRS-484B-217-2, NRS-484B-223-1b, NRS-484B-250-1, NRS-484B-250-2, NRS-484B-250-4, NRS-484B-253, NRS-484B-257-1, NRS-484B-257-2, NRS-484B-260, NRS-484B-263, NRS-484B-267-1a, NRS-484B-267-1b, NRS-484B-267-1c, NRS-484B-267-2a, NRS-484B-267-2b, NRS-484B-267-2c, NRS-484B-267-2d, NRS-484B-267-2e, NRS-484B-267-2f, NRS-484B-270-1, NRS-484B-270-2a, NRS-484B-270-2b, NRS-484B-270-3, NRS-484B-270-4, NRS-484B-270-5a, NRS-484B-280-1a, NRS-484B-280-1c, NRS-484B-283-1a, NRS-484B-283-1b, NRS-484B-283-1d1, NRS-484B-300-1, NRS-484B-307-12a, NRS-484B-307-12b, NRS-484B-307-3a, NRS-484B-307-9a, NRS-484B-310-1, NRS-484B-330-1, NRS-484B-363-3, NRS-484B-363-4, NRS-484B-400-1, NRS-484B-400-2a, NRS-484B-400-2b, NRS-484B-403-2, NRS-484B-403-3, NRS-484B-407, NRS-484B-413-3, NRS-484B-440-1, NRS-484B-507-1, NRS-484B-510, NRS-484B-517, NRS-484B-557, NRS-484B-560-3, NRS-484B-560-7a, NRS-484B-560-7b, NRS-484B-603-1, NRS-484B-627-1a, NRS-484B-627-1b, NRS-484B-627-1c, NRS-484D-215-1, NRS-484D-400-5, NRS-486-351-2
- `DEF-NRS-484A-095` / "highway": used by LVMC-11-16-040, LVMC-11-16-060, LVMC-11-16-090-A, LVMC-11-22-020, LVMC-11-22-100, NRS-484A-450-2, NRS-484A-450-3, NRS-484B-127-1, NRS-484B-127-2, NRS-484B-127-3, NRS-484B-203-1, NRS-484B-208-1, NRS-484B-210-1, NRS-484B-210-3, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2, NRS-484B-220-1, NRS-484B-223-1b, NRS-484B-223-3a, NRS-484B-223-3b, NRS-484B-223-3c, NRS-484B-223-4a, NRS-484B-223-4b, NRS-484B-250-1, NRS-484B-250-2, NRS-484B-260, NRS-484B-263, NRS-484B-267-1b, NRS-484B-270-2b, NRS-484B-280-1c, NRS-484B-283-1a, NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4, NRS-484B-297-2, NRS-484B-297-6, NRS-484B-307-12a, NRS-484B-307-12b, NRS-484B-307-2b, NRS-484B-307-4b, NRS-484B-307-8a, NRS-484B-307-8b, NRS-484B-307-8c, NRS-484B-307-9c, NRS-484B-330-1, NRS-484B-400-1, NRS-484B-400-2a, NRS-484B-400-2b, NRS-484B-410, NRS-484B-440-1, NRS-484B-450-1g, NRS-484B-450-1j, NRS-484B-450-1k, NRS-484B-450-1l, NRS-484B-450-1m, NRS-484B-457-1, NRS-484B-460, NRS-484B-473-2, NRS-484B-490, NRS-484B-533, NRS-484B-557, NRS-484B-560-3, NRS-484B-587-2a, NRS-484B-587-2b, NRS-484B-600-1a, NRS-484B-600-1c, NRS-484B-603-1, NRS-484B-627-1a, NRS-484B-627-1b, NRS-484B-627-1c, NRS-484B-633-2, NRS-484B-653-1a, NRS-484B-913, NRS-484D-100-1, NRS-484D-165-3, NRS-484D-215-1
- `DEF-NRS-484A-105` / "intersection": used by LVMC-11-12-070-B, LVMC-11-16-040, LVMC-11-18-020, LVMC-11-30-030, LVMC-11-30-060-A, LVMC-11-52-130-A11, LVMC-11-60-090, NRS-484A-450-2, NRS-484A-450-3, NRS-484B-113-2, NRS-484B-208-1, NRS-484B-210-1, NRS-484B-213-2b, NRS-484B-223-4b, NRS-484B-227-1, NRS-484B-250-1, NRS-484B-250-2, NRS-484B-250-4, NRS-484B-253, NRS-484B-257-1, NRS-484B-257-2, NRS-484B-267-1b, NRS-484B-270-4, NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-307-2a, NRS-484B-307-3a, NRS-484B-307-4a, NRS-484B-307-5a, NRS-484B-307-6a, NRS-484B-307-7a, NRS-484B-307-8a, NRS-484B-307-8c, NRS-484B-307-8d, NRS-484B-307-9a, NRS-484B-307-9b, NRS-484B-310-1, NRS-484B-400-1, NRS-484B-400-2a, NRS-484B-400-2b, NRS-484B-403-3, NRS-484B-450-1c, NRS-484B-603-1
- `DEF-NRS-484A-115` / "local authority": used by NRS-484B-457-1, NRS-484B-477-1a, NRS-484B-477-1b, NRS-484B-557, NRS-484B-633-2
- `DEF-NRS-484A-125` / "moped": used by NRS-484B-307-8d, NRS-484B-307-9b
- `DEF-NRS-484A-130` / "motor vehicle": used by LVMC-11-16-090-A, LVMC-11-52-300, NRS-484B-127-3, NRS-484B-208-1, NRS-484B-270-1, NRS-484B-270-2a, NRS-484B-270-2b, NRS-484B-270-3, NRS-484B-270-4, NRS-484B-270-5a, NRS-484B-270-7a, NRS-484B-270-7b, NRS-484B-280-1a, NRS-484B-280-1c, NRS-484B-363-1, NRS-484B-363-2, NRS-484B-507-1, NRS-484B-620-2, NRS-484B-627-1a, NRS-484B-627-1b, NRS-484B-627-1c, NRS-484D-215-1, NRS-486-341
- `DEF-NRS-484A-135` / "motorcycle": used by LVMC-11-38-030, NRS-484B-307-8d, NRS-484B-307-9b
- `DEF-NRS-484A-145` / "official traffic-control device": used by NRS-484B-250-1, NRS-484B-250-2, NRS-484B-283-1a, NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, NRS-484B-300-1, NRS-484B-307-8d, NRS-484B-307-9b, NRS-484B-310-1, NRS-484B-403-2, NRS-484B-450-1a, NRS-484B-450-1c, NRS-484B-450-1e, NRS-484B-450-1g, NRS-484B-450-1h, NRS-484B-450-1i, NRS-484B-450-1j, NRS-484B-450-1k, NRS-484B-450-1l, NRS-484B-450-1m, NRS-484B-450-1o, NRS-484B-460, NRS-484B-490, NRS-484B-493, NRS-484B-497, NRS-484B-500, NRS-484B-557, NRS-484B-560-7b, NRS-484B-587-1
- `DEF-NRS-484A-155` / "park": used by LVMC-11-40-170, LVMC-11-52-030-A, LVMC-11-52-030-B, LVMC-11-52-040-A, LVMC-11-52-070, LVMC-11-52-130-A11, LVMC-11-52-130-A12, LVMC-11-52-130-A2, LVMC-11-52-130-A4, LVMC-11-52-130-A5, LVMC-11-52-130-A7, LVMC-11-52-136, LVMC-11-52-180-C, LVMC-11-52-300, LVMC-11-52-305-A, LVMC-11-52-340, LVMC-11-60-030-A1, LVMC-11-60-030-A5, LVMC-11-60-040, NRS-484B-270-3, NRS-484B-440-1, NRS-484B-450-1a, NRS-484B-450-1c, NRS-484B-450-1e, NRS-484B-450-1g, NRS-484B-450-1h, NRS-484B-450-1i, NRS-484B-450-1j, NRS-484B-450-1k, NRS-484B-450-1l, NRS-484B-450-1m, NRS-484B-450-1o, NRS-484B-460, NRS-484B-477-1a, NRS-484B-477-1b, NRS-484B-477-2, NRS-484B-490, NRS-484B-493, NRS-484B-497, NRS-484B-500, NRS-484B-503, NRS-484B-507-1, NRS-484B-510, NRS-484B-517
- `DEF-NRS-484A-155` / "parking": used by LVMC-11-52-030-A, LVMC-11-52-030-B, LVMC-11-52-070, LVMC-11-52-130-A4, LVMC-11-52-130-A7, LVMC-11-52-340, LVMC-11-60-040, NRS-484B-270-3, NRS-484B-410, NRS-484B-450-1k, NRS-484B-450-1o, NRS-484B-457-1, NRS-484B-460, NRS-484B-473-2, NRS-484B-490, NRS-484B-497, NRS-484B-510
- `DEF-NRS-484A-165` / "pedestrian": used by LVMC-11-20-060, LVMC-11-30-030, LVMC-11-30-050, LVMC-11-30-060-A, LVMC-11-30-060-B, LVMC-11-30-070-B, LVMC-11-30-090, LVMC-11-30-140-B, LVMC-11-40-080, LVMC-11-40-140, LVMC-11-40-170, LVMC-11-40-180-B, LVMC-11-40-180-C, LVMC-11-46-030, NRS-484B-113-3, NRS-484B-270-3, NRS-484B-280-1a, NRS-484B-280-1c, NRS-484B-283-1a, NRS-484B-283-1b, NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4, NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, NRS-484B-293, NRS-484B-297-2, NRS-484B-297-6, NRS-484B-307-2a, NRS-484B-307-2b, NRS-484B-307-3a, NRS-484B-307-4a, NRS-484B-307-4b, NRS-484B-307-5a, NRS-484B-307-7a, NRS-484B-307-8a, NRS-484B-307-8b, NRS-484B-307-8c, NRS-484B-307-8d, NRS-484B-307-9a, NRS-484B-307-9b, NRS-484B-307-9c, NRS-484B-450-1a, NRS-484B-603-1, NRS-484B-777-1, NRS-484D-400-5
- `DEF-NRS-484A-180` / "police officer": used by LVMC-11-40-070, LVMC-11-52-130-A11, LVMC-11-52-130-A12, LVMC-11-52-130-A2, LVMC-11-52-130-A4, LVMC-11-52-130-A5, LVMC-11-52-130-A7, NRS-484B-257-1, NRS-484B-257-2, NRS-484B-270-3, NRS-484B-300-1, NRS-484B-450-1a, NRS-484B-450-1c, NRS-484B-450-1e, NRS-484B-450-1g, NRS-484B-450-1h, NRS-484B-450-1i, NRS-484B-450-1j, NRS-484B-450-1k, NRS-484B-450-1l, NRS-484B-450-1m, NRS-484B-450-1o, NRS-484B-560-7b, NRS-486-351-1
- `DEF-NRS-484A-185` / "premises to which the public has access": used by NRS-484B-653-1a


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


### Feedback

(none)

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
