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

- `DEF-NRS-484A-320`: “Vehicle” means every device in, upon or by which any person or property is or may be transported or drawn upon a highway, except: (1) Devices moved by human power or used exclusively upon stationary rails; (2) Electric bicycles; (3) Electric personal assistive mobility devices as defined in NRS 482.029; and (4) An electric scooter.
- `DEF-NRS-484A-095`: “Highway” means the entire width between the boundary lines of every way dedicated to a public authority when any part of the way is open to the use of the public for purposes of vehicular traffic, whether or not the public authority is maintaining the way.
- `DEF-NRS-484A-195`: “Public authority” means the Department of Transportation or the local authority having jurisdiction to enact laws or ordinances or adopt regulations relating to traffic over a highway.
- `DEF-NRS-484A-115`: “Local authority” means the governing board of a county, city or other political subdivision having authority to enact laws or ordinances or promulgate regulations relating to traffic over a highway.
- `DEF-NRS-484A-045`: “City” means any incorporated city, whether incorporated under general or special law.
- `DEF-NRS-484A-285`: “Traffic” means pedestrians, ridden or herded animals, vehicles and other conveyances either singly or together using any highway for purposes of travel.
- `DEF-NRS-484A-165`: “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029.
- `DEF-NRS-484A-081`: “Electric bicycle” has the meaning ascribed to it in NRS 484B.017.
- `DEF-NRS-484B-017`: “Electric bicycle” means a device upon which a person may ride, having two or three wheels, or every such device generally recognized as a bicycle that has fully operable pedals, a seat or saddle for the rider, an electric motor which produces not more than 750 watts and meets the requirements of one of the following three classes: (1) “Class 1 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 20 miles per hour. (2) “Class 2 electric bicycle” means an electric bicycle equipped with a motor that may be used exclusively to propel the bicycle and is not capable of providing assistance when the bicycle reaches the speed of 20 miles per hour. (3) “Class 3 electric bicycle” means an electric bicycle equipped with a motor that provides assistance only when the rider is pedaling and ceases to provide assistance when the bicycle reaches the speed of 28 miles per hour. The term does not include a moped or an electric scooter.
- `DEF-NRS-484A-025`: “Bicycle” means a device propelled by human power upon which a person may ride, having two tandem wheels either of which is over 14 inches in diameter, or every such device generally recognized as a bicycle though equipped with two front or two rear wheels except a moped.
- `DEF-NRS-484A-125`: “Moped” means a motor-driven scooter, motor-driven cycle or similar vehicle that is propelled by a small engine which produces not more than 2 gross brake horsepower, has a displacement of not more than 50 cubic centimeters or produces not more than 1500 watts final output, and: (1) Is designed to travel on not more than three wheels in contact with the ground but is not a tractor; and (2) Is capable of a maximum speed of not more than 30 miles per hour on a flat surface with not more than 1 percent grade in any direction when the motor is engaged. The term does not include an electric bicycle or an electric scooter.
- `DEF-NRS-484A-082`: “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.
- `DEF-NRS-484B-018`: “Electric scooter” means a vehicle with handlebars and an electric motor that is designed to be ridden on in an upright or seated position and propelled by its electric motor or by propulsion provided by the rider. Such a vehicle: (1) Must not weigh more than 100 pounds without a rider; and (2) Must have a maximum speed of not more than 20 miles per hour when powered solely by its electric motor.


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
 "aggregate_id": "DEF-NRS-484A-320::vehicle",
 "term": "vehicle",
 "definition": "DEF-NRS-484A-320",
 "classifications": [
  {
   "class": "ru.bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Devices moved by human power or used exclusively upon stationary rails"
    }
   ]
  },
  {
   "class": "ru.bus",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.child",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.commercial_motor_vehicle",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.electric_bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Electric bicycles"
    }
   ]
  },
  {
   "class": "ru.electric_scooter",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "An electric scooter"
    }
   ]
  },
  {
   "class": "ru.emergency_vehicle",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.fire_apparatus",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.moped",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    },
    {
     "definition": "DEF-NRS-484A-125",
     "words": "a motor-driven scooter, motor-driven cycle or similar vehicle"
    }
   ]
  },
  {
   "class": "ru.motor_vehicle",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.motorcycle",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.official_vehicle",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.pedestrian",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    },
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Devices moved by human power or used exclusively upon stationary rails"
    }
   ]
  },
  {
   "class": "ru.pedestrian_with_white_cane_or_guide_animal",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    },
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Devices moved by human power or used exclusively upon stationary rails"
    }
   ]
  },
  {
   "class": "ru.rail_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "Devices moved by human power or used exclusively upon stationary rails"
    }
   ]
  },
  {
   "class": "ru.school_bus",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.taxicab",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.tour_bus_or_limousine",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.trailer_or_combination",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.transit_bus",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
  },
  {
   "class": "ru.truck",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-320",
     "words": "every device in, upon or by which any person or property is or may be transported or drawn upon a highway"
    }
   ]
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
