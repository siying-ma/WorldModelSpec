# Verifier — do the quoted words support each proposed classification?

## Role

A planner has classified every class of road users of an ontology under one posted definition: each
class is proposed as included, excluded, covered or unresolved, with the words it says decide it. You
check each proposal against the posted words, class by class. You do not propose a status, a
replacement, a repair or a new mapping; you say only whether the words support what is proposed.

## Inputs (injected below)

- **The posted definition(s)** — the controlling definition, verbatim, and the definitions reached
  by its cross-references and nested defined terms.
- **The classes of road users** — every class with its contract: what membership in it means.
- **The proposed classification** — for each class, the proposed status, the quoted words and the
  planner's reason; for a covered class, also its covering classes (`covered_by`) and the quoted
  class contracts (`basis`) that the planner says make the coverage complete.

### The posted definition(s)

- `DEF-NRS-484A-230`: (1) “School bus” means every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver and which is: (a) Owned by or under the control of a public or governmental agency or a private school and regularly operated for the transportation of children to or from school or a school activity; or (b) Privately owned and regularly operated for compensation for the transportation of children to or from school or a school activity. (2) “School bus” does not include: (a) A passenger car operated under a contract to transport children to and from school; (b) A common carrier or commercial vehicle under the jurisdiction of the Surface Transportation Board or the Nevada Transportation Authority when such vehicle is operated in the regular conduct of its business in interstate or intrastate commerce within the State of Nevada; or (c) A multifunction school activity bus whose purposes do not include transporting students to and from home or school bus stops.
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
- `DEF-NRS-484A-080`: (1) Except as otherwise provided in subsection 2, “driver” means every person who drives or is in actual physical control of a vehicle. (2) If a vehicle is an autonomous vehicle, as defined in NRS 482A.030 [DEF-NRS-482A-030], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the autonomous vehicle is engaged, “driver” means a person who causes the automated driving system of the autonomous vehicle to engage. (3) If a vehicle is a fully autonomous vehicle, as defined in NRS 482A.036 [DEF-NRS-482A-036], and the automated driving system, as defined in NRS 482A.025 [DEF-NRS-482A-025], of the fully autonomous vehicle is engaged, “driver” does not include a natural person who causes the automated driving system of the fully autonomous vehicle to engage unless the natural person is the owner of the fully autonomous vehicle.
- `DEF-NRS-482A-030`: “Autonomous vehicle” means a motor vehicle that is equipped with an automated driving system which is designed to function at a level of driving automation of level 3, 4 or 5 pursuant to SAE J3016. The term includes a fully autonomous vehicle.
- `DEF-NRS-482A-025`: “Automated driving system” has the meaning ascribed to it in SAE J3016.
- `DEF-NRS-482A-036`: “Fully autonomous vehicle” means a vehicle equipped with an automated driving system which is designed to function at a level of driving automation of level 4 or 5 pursuant to SAE J3016.
- `DEF-NRS-484A-150`: “Owner” means a person who holds the legal title to a vehicle. The term includes a conditional vendee or lessee, in the event a vehicle is the subject of an agreement for the conditional sale or lease thereof, with or without the right of purchase upon performance of the conditions stated in the agreement and with an immediate right of possession vested in the conditional vendee or lessee. The term also includes a mortgagor, in the event of a mortgage of the vehicle, when the mortgagor of a vehicle is entitled to possession.
- `DEF-NRS-484A-160`: “Passenger car” means every motor vehicle, except motorcycles and motor-driven cycles, designed for carrying 10 passengers or less and used for the transportation of persons.
- `DEF-NRS-484A-135`: “Motorcycle” means every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground, excluding an electric bicycle, a tractor or a moped.
- `DEF-NRS-484A-055`: “Commercial vehicle” means every vehicle designed, maintained or used primarily for the transportation of property in furtherance of commercial enterprise.
- `DEF-NRS-484A-030`: “Bus” means a vehicle owned by the State, a political subdivision or a private school or nursery, designed for carrying more than 10 passengers and used for the transportation of persons, or a vehicle, other than a taxicab, designed and used for the transportation of persons for compensation.
- `DEF-NRS-484A-270`: “Taxicab” means a motor vehicle designed or constructed to accommodate and transport not more than six passengers, including the driver, and used to transport passengers for a charge or fee.


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


### The proposed classification

```json
{
 "aggregate_id": "DEF-NRS-484A-230::school_bus",
 "term": "school bus",
 "definition": "DEF-NRS-484A-230",
 "classifications": [
  {
   "class": "ru.bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-130",
     "words": "every vehicle which is self-propelled but not operated upon rails"
    },
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Devices moved by human power or used exclusively upon stationary rails"
    }
   ],
   "reason": "A human-powered device is not a vehicle, hence not a motor vehicle."
  },
  {
   "class": "ru.bus",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    },
    {
     "definition": "DEF-NRS-484A-230",
     "words": "regularly operated for the transportation of children to or from school or a school activity"
    }
   ],
   "reason": "Only buses regularly operated to transport children to or from school are admitted, and such a bus (e.g. privately owned for compensation) need not carry the jurisdiction's school bus markings, so the class does not decide membership."
  },
  {
   "class": "ru.child",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "A pedestrian is not a motor vehicle."
  },
  {
   "class": "ru.commercial_motor_vehicle",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "regularly operated for the transportation of children to or from school or a school activity"
    },
    {
     "definition": "DEF-NRS-484A-230",
     "words": "A common carrier or commercial vehicle under the jurisdiction of the Surface Transportation Board or the Nevada Transportation Authority when such vehicle is operated in the regular conduct of its business in interstate or intrastate commerce within the State of Nevada"
    }
   ],
   "reason": "Membership depends on capacity and regular school transport use, which the commercial mass or licensing class does not decide."
  },
  {
   "class": "ru.electric_bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-130",
     "words": "The term does not include an electric bicycle or an electric scooter."
    }
   ],
   "reason": "An electric bicycle is not a motor vehicle."
  },
  {
   "class": "ru.electric_scooter",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-130",
     "words": "The term does not include an electric bicycle or an electric scooter."
    }
   ],
   "reason": "An electric scooter is not a motor vehicle."
  },
  {
   "class": "ru.emergency_vehicle",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "The words neither name nor exclude emergency vehicles; membership turns on capacity and school transport use, which the class does not decide."
  },
  {
   "class": "ru.fire_apparatus",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "The words neither name nor exclude fire apparatus; membership turns on capacity and school transport use, which the class does not decide."
  },
  {
   "class": "ru.moped",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "A low-power two- or three-wheeler is not designed or used to carry more than 10 passengers in addition to the driver."
  },
  {
   "class": "ru.motor_vehicle",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    },
    {
     "definition": "DEF-NRS-484A-230",
     "words": "Privately owned and regularly operated for compensation for the transportation of children to or from school or a school activity"
    }
   ],
   "reason": "Only some motor vehicles are admitted, and a qualifying one need not carry the school bus markings of ru.school_bus, so no included class covers all of them."
  },
  {
   "class": "ru.motorcycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "A two- or three-wheeler ridden astride is not designed or used to carry more than 10 passengers in addition to the driver."
  },
  {
   "class": "ru.official_vehicle",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "Owned by or under the control of a public or governmental agency or a private school and regularly operated for the transportation of children to or from school or a school activity"
    }
   ],
   "reason": "An official or municipal vehicle may or may not be a large vehicle regularly transporting school children; the class does not decide it."
  },
  {
   "class": "ru.pedestrian",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "A pedestrian is not a motor vehicle."
  },
  {
   "class": "ru.pedestrian_with_white_cane_or_guide_animal",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "A pedestrian is not a motor vehicle."
  },
  {
   "class": "ru.rail_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-130",
     "words": "every vehicle which is self-propelled but not operated upon rails"
    }
   ],
   "reason": "Rail equipment is not a motor vehicle."
  },
  {
   "class": "ru.school_bus",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    },
    {
     "definition": "DEF-NRS-484A-230",
     "words": "regularly operated for the transportation of children to or from school or a school activity"
    }
   ],
   "reason": "A bus designated and marked for carrying school children is a motor vehicle carrying more than 10 passengers regularly operated to transport children to or from school."
  },
  {
   "class": "ru.taxicab",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "A passenger car operated under a contract to transport children to and from school"
    },
    {
     "definition": "DEF-NRS-484A-160",
     "words": "designed for carrying 10 passengers or less"
    }
   ],
   "reason": "The taxicab contract states no passenger capacity, so the words do not decide whether a vehicle for hire carries more than 10 passengers."
  },
  {
   "class": "ru.tour_bus_or_limousine",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "Privately owned and regularly operated for compensation for the transportation of children to or from school or a school activity"
    },
    {
     "definition": "DEF-NRS-484A-230",
     "words": "A common carrier or commercial vehicle under the jurisdiction of the Surface Transportation Board or the Nevada Transportation Authority when such vehicle is operated in the regular conduct of its business in interstate or intrastate commerce within the State of Nevada"
    }
   ],
   "reason": "A privately owned shuttle could be regularly operated for compensation to transport children, but carriers in regular commerce are excepted; the class does not decide which."
  },
  {
   "class": "ru.trailer_or_combination",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-130",
     "words": "every vehicle which is self-propelled but not operated upon rails"
    }
   ],
   "reason": "A drawn vehicle is not self-propelled, but the class also labels the combination, whose power unit the words do not decide."
  },
  {
   "class": "ru.transit_bus",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "Owned by or under the control of a public or governmental agency or a private school and regularly operated for the transportation of children to or from school or a school activity"
    }
   ],
   "reason": "A transit bus is admitted only if regularly operated to transport children to or from school, which public transit service does not decide."
  },
  {
   "class": "ru.truck",
   "status": "unresolved",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-230",
     "words": "every motor vehicle which is designed or used to carry more than 10 passengers in addition to the driver"
    }
   ],
   "reason": "The words admit a vehicle used to carry more than 10 passengers, which a goods body does not by itself rule out."
  }
 ]
}
```


## Verdicts

For each class, exactly one:

- **supported** — the posted words support the proposed status: for `included`, words that admit
  the class (an admitting clause, or a closed enumeration naming it) and no exception that removes
  it; for `excluded`, an exception or a closed enumeration that leaves it out, or admitting words
  that reach no member of the class as its contract describes it; for `covered`, admitting words
  that reach members of the class only as members of the classes in `covered_by`, each proposed
  `included`, and contracts (quoted in `basis`) under which every member the words admit within the
  class carries one of those classes; for `unresolved`, the words decide neither inclusion,
  exclusion nor coverage of the class as its contract describes it. An exception removes
  a class only where it names the class or describes what the class's contract describes; an
  exception about something no class of the ontology covers leaves the other classes decided.
- **contradicted** — the posted words support another decided status (included, excluded or
  covered) than the one proposed.
- **underdetermined** — the proposal is a decided status, but the words support no decided status.

A source lists every class that applies to a road user and marks unobserved a class it cannot
settle; no class implies another. A covered class is therefore one whose own label adds no
membership evidence: a qualifying road user is shown by a covering class. A coverage claim is
supported only on the posted words and the class contracts: not on a class's name, and not because
a source can label a class of the same name. Where the words admit a member of the class that
carries none of the covering classes, the coverage is not supported.

Judge from the posted words and the class contracts only; not from what such words usually mean
in other places. A condition of a scene the definition states (where or when a road user is) is
not a class and decides no class. Give a one-sentence reason for each verdict.

## Output

JSON, this schema and nothing more:

```
{"aggregate_id": "<the proposal's aggregate_id>",
 "classifications": [{"class": "<class id>", "verdict": "supported | contradicted | underdetermined", "reason": "<one sentence>"}]}
```

Every class of the proposal appears exactly once.

## Finish

Finish when the JSON is written. No commentary outside it.
