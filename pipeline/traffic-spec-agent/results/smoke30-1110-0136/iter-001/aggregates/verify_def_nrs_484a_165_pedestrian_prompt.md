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

- `DEF-NRS-484A-165`: “Pedestrian” means a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029.


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
 "aggregate_id": "DEF-NRS-484A-165::pedestrian",
 "term": "pedestrian",
 "definition": "DEF-NRS-484A-165",
 "classifications": [
  {
   "class": "ru.bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.bus",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.child",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.commercial_motor_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.electric_bicycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.electric_scooter",
   "status": "covered",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ],
   "reason": "The only scooter riders the words could admit are persons on an electric personal assistive mobility device, whom the jurisdiction treats as on foot, so they carry ru.pedestrian.",
   "covered_by": [
    "ru.pedestrian"
   ],
   "basis": [
    {
     "class": "ru.electric_scooter",
     "words": "a standing or seated electric scooter with handlebars"
    },
    {
     "class": "ru.pedestrian",
     "words": "a person on foot, in a wheelchair, or on a device the jurisdiction treats as on foot"
    }
   ]
  },
  {
   "class": "ru.emergency_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.fire_apparatus",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.moped",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.motor_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.motorcycle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.official_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.pedestrian",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.pedestrian_with_white_cane_or_guide_animal",
   "status": "included",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.rail_vehicle",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.school_bus",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.taxicab",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.tour_bus_or_limousine",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.trailer_or_combination",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.transit_bus",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
    }
   ]
  },
  {
   "class": "ru.truck",
   "status": "excluded",
   "quotes": [
    {
     "definition": "DEF-NRS-484A-165",
     "words": "a person afoot, a person in a manual or motorized wheelchair, or a person on an electric personal assistive mobility device as defined in NRS 482.029"
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
