"""Classification of every corpus line into one of four views (CORPUS_AUDIT_2026-09-19.md §3–§4).

Precedence: EXCLUDED > UNOBSERVABLE > unresolvable > tier S/Q > tier C.
  excluded.jsonl     lines that do not judge a driving situation (apparel, equipment legality, a permission,
                     a rider's own body configuration on their own machine)
  unobservable.jsonl lines whose every duty is one no planned source can observe; kept apart from
                     excluded.jsonl because the reason is the source, not the law, and it reverses
                     the moment a source supplies the signal
  unresolvable.jsonl every line that carries an `unresolved` reference (references.UNRESOLVED), whether the
                     mark is the trigger itself (BLOCKING, reason stated) or a peripheral reference (kinds stated);
                     decided 2026-09-20. Also kept out of laws_full.jsonl.
  judgement.jsonl    tier S (the obligation is only a standard) and tier Q (a concrete rule with a judgement element)
  concrete.jsonl     tier C, no judgement element
`JDG_WORDS` is the vocabulary the audit swept for; `FALSE_POSITIVE` names lines where a matched word is
not a standard (a 'safety zone', 'appropriate signs', the 'purpose' of a turn evidenced by the turn).
"""
import re

JDG_WORDS = re.compile(r"\b(reasonabl\w*|prudent|safe(?:ly|ty)?|practicable|immediate hazard|hazardous|hazard\b|due care|due regard|caution\w*|careful\w*|careless\w*|imprudent|necessary|necessity|impede\w*|interfer\w*|clearly visible|clear (?:and unobstructed )?view|obstruct\w*|knows, or reasonably should know|intentionally|wilful\w*|willful\w*|wanton|sufficient\w*|appropriate|proper(?:ly)?|unreasonabl\w*|danger\w*|expeditious\w*|unusual|unsafe|full time and attention|possible|endanger\w*|purpose)\b", re.I)

EXCLUDED = {
 # rider and passenger apparel
 'NRS-486-231-2': "helmet and eye protection: judges what a person wears, not how a road user moves; no planned source observes it",
 'LVMC-11-38-130': "protective footwear: apparel, not conduct",
 'LVMC-11-40-185-C': "helmets on minors: apparel, and needs age estimation",
 # equipment legality while driving
 'NRS-484A-480-5': "alternately flashing headlamps: what the vehicle is fitted with, not how it is driven",
 'NRS-484A-480-6': "red lamp visible from the front: equipment legality",
 'NRS-484A-480-7': "blue lamp: equipment legality",
 'NRS-484D-545-1': "slow-moving-vehicle emblem: equipment display",
 'NRS-484D-515-1': "tire chains where posted: equipment fitted, not conduct",
 'NRS-484D-185-1': "flashing amber warning light: equipment legality, and its only condition is a judgement ('unusual traffic hazard')",
 'NRS-484B-783-1': "bicycle lamps and reflectors at night: equipment fitted",
 # a permission, not an obligation
 'NRS-484B-700-1': "privileges of a responding emergency vehicle: a permission that switches other rules off; an applicability record, not a rule to monitor",
 # how a rider sits on their own machine: the whole duty is the rider's body configuration, which is
 # neither conduct a driving plan can perform nor a fact one turns on (decided 2026-09-29)
 'NRS-484B-770-1': "riding on or astride the seat of a bicycle: the rider's own posture, not conduct a driving plan performs or reacts to",
 'NRS-486-191-1': "riding on the permanent seat of a motorcycle or moped: the rider's own posture",
 'NRS-486-211': "at least one hand on the handlebar: the rider's own posture",
 'NRS-484B-780': "carrying a package that prevents a hand on the handlebars: the rider's own posture",
 'LVMC-11-38-040': "holding to a moving vehicle to be propelled: the rider's own posture",
 'LVMC-11-40-150': "attaching oneself or the machine to a vehicle: the rider's own posture",
 'LVMC-11-40-185-B': "stunts, wheelies and riding on handlebars: the rider's own posture",
 'NRS-484B-770-2': "carrying more persons than a cycle is designed for: how many ride the machine and where they sit, not conduct a driving plan performs or reacts to",
 'NRS-486-181-1': "carrying a passenger on a motorcycle not designed for one: as above",
 # outside the operational design domain, ordinary urban Las Vegas driving: the law is triggered by
 # a rare actor or event, or needs a road the valley does not have; evidence in
 # LONGTAIL_ENCOUNTER_RATES_2026-10-12.md (decided 2026-10-13)
 'NRS-484B-703-1': "outside the ODD: triggered by a funeral procession",
 'NRS-484B-707-1': "outside the ODD: triggered by a funeral procession",
 'NRS-484B-707-2': "outside the ODD: triggered by a funeral procession",
 'LVMC-11-22-150-A': "outside the ODD: triggered by an ice-cream truck with its signal arm out",
 'LVMC-11-22-150-B': "outside the ODD: triggered by an ice-cream truck with its signal arm out",
 'LVMC-11-12-090': "outside the ODD: triggered by a horse ridden or drawing a vehicle",
 'NRS-484B-787-2a': "outside the ODD: a personal delivery device's duty; deployment confined to the UNLV area",
 'NRS-484B-787-2b': "outside the ODD: a personal delivery device's duty; deployment confined to the UNLV area",
 'NRS-484B-787-2c': "outside the ODD: a personal delivery device's duty; deployment confined to the UNLV area",
 'NRS-484B-790-2a': "outside the ODD: a mobile carrying device's duty; no deployment found in the valley",
 'NRS-484B-790-2b': "outside the ODD: a mobile carrying device's duty; no deployment found in the valley",
 'NRS-484B-790-2c': "outside the ODD: a mobile carrying device's duty; no deployment found in the valley",
 'NRS-484B-637-2b': "outside the ODD: a low-speed vehicle's duty; golf carts only in approved developments",
 'NRS-484B-553-1': "outside the ODD: triggered by a train approaching a grade crossing",
 'NRS-484B-553-2': "outside the ODD: triggered by a crossing gate closed or moving",
 'NRS-484B-560-6': "outside the ODD: triggered by tracks not clear of a train",
 'LVMC-11-30-080': "outside the ODD: triggered by a crossing gate closed or moving",
 'NRS-484B-120': "outside the ODD: canyons and mountain highways, a road the valley does not have",
 'NRS-484B-630-1': "outside the ODD: a two-lane rural highway with turnouts, a road the valley does not have",
 # ego scope: the system under test is a vehicle driver; a law binding only a skateboard or moped
 # rider judges a road user whose conduct is not under test (decided 2026-10-13)
 'LVMC-11-22-130-A': "ego scope: binds a rider of a coaster, skates, scooter or skateboard",
 'LVMC-11-22-130-B': "ego scope: binds a rider of a coaster, skates, scooter or skateboard",
 'LVMC-11-22-130-C': "ego scope: binds a rider of a coaster, skates, scooter or skateboard",
 'NRS-486-351-4': "ego scope: binds a moped rider",
}

# Words removed from a corpus line because they name an item outside the operational design domain
# that the rest of the line does not need; the line stays. Each edit is (the words removed, the reason),
# applied by make_laws.py and recorded on the line as `scope_edit` in laws_meta.jsonl; the corpus
# README lists them. The unedited text stays in sources/ and in laws/example/archive/corpus_2026-09-20/
# (decided 2026-10-13).
SCOPE_EDITS = {
 'LVMC-11-22-100': ("horse or ", "a ridden horse is outside the ODD; the duty to drive no vehicle over newly laid pavement stays"),
}

# Lines whose EVERY duty rests on a signal no planned source observes, so no verdict about them can
# be founded. Neither source carries sound: CARLA has no audio and no horn on carla.Vehicle (its
# VehicleLightState.Special1/Special2 are light flags reserved for sirens), and the real-video logs
# ship cameras and lidar and no microphone. A line that merely CONTAINS such a duty beside an
# observable one stays in the corpus and carries a residue instead.
UNOBSERVABLE = {
 'NRS-484B-270-5b': "the whole duty is an audible warning with the horn; no planned source carries sound",
 'NRS-484B-280-1b': "the whole duty is an audible warning with the horn; no planned source carries sound",
 'NRS-484D-400-2': "both limbs are the horn -- sounding it when necessary and not otherwise; no planned source carries sound",
 'NRS-484D-285-1': "the conduct judged is use of a compression brake, whose statutory test is that it is audible",
}

# unresolved marks that block the trigger or the obligation itself (not a peripheral exception or a penalty)
BLOCKING = {
 'NRS-484B-307-11': "no criterion for which signal provisions apply at a mid-block signal",
 'NRS-484B-790-3': "no criterion for which pedestrian duties a mobile carrying device inherits",
 'NRS-484B-360-2': "the trip's purpose ('properly a part of a school program') is the trigger",
 'LVMC-11-16-050': "whether the park limit is in force is an administrative determination per park",
 'LVMC-11-41-020': "the permitted streets are a schedule with no sign; the region is the whole rule",
 'LVMC-11-52-030-E': "lawful use of a blue-curb space turns on a permit or plate that is not reliably observable",
 'LVMC-11-60-030-B1': "the exception turns on the purpose of the trip (celebrity tour, nonprofit function)",
 'LVMC-11-68-030': "the Pedestrian Mall boundary is an ordinance exhibit map; the region is the whole rule",
}

# Tier S: the obligation is nothing but a standard of care
TIER_S = set("""NRS-484B-113-1 NRS-484B-127-3 NRS-484B-210-2 NRS-484B-270-1 NRS-484B-270-5a NRS-484B-270-5b NRS-484B-270-7a
NRS-484B-270-7b NRS-484B-280-1a NRS-484B-280-1b NRS-484B-280-1c NRS-484B-293 NRS-484B-310-2 NRS-484B-403-1 NRS-484B-410
NRS-484B-413-1 NRS-484B-600-1a NRS-484B-600-1b NRS-484B-603-1 NRS-484B-607-1b NRS-484B-607-1c NRS-484B-267-2b NRS-484B-267-2c
NRS-484B-623-1 NRS-484B-627-2 NRS-484B-653-1a NRS-484B-707-1 NRS-484B-787-2c NRS-484B-790-2c NRS-484D-400-2
NRS-484B-127-1 LVMC-11-12-090 LVMC-11-22-010 LVMC-11-22-020 LVMC-11-22-150-A LVMC-11-40-130 LVMC-11-40-185-B""".split())

# lines where every matched word is not a judgement standard -> tier C
FALSE_POSITIVE = set("""NRS-484B-110 NRS-484B-223-3a NRS-484B-223-4a NRS-484B-500 NRS-484B-620-2 NRS-484B-703-1 NRS-484B-633-2
NRS-484D-215-1 NRS-484D-215-2 LVMC-11-12-060 LVMC-11-38-040 LVMC-11-22-120-B LVMC-11-27-010-A LVMC-11-18-020
LVMC-11-40-180-B LVMC-11-22-150-B LVMC-11-48-050 LVMC-11-18-030-B LVMC-11-16-110""".split())

def tier(row):
    i = row['id']
    if i in TIER_S: return 'S'
    if i in FALSE_POSITIVE: return 'C'
    return 'Q' if JDG_WORDS.search(row['text']) else 'C'

def bucket(row):
    i = row['id']
    if i in EXCLUDED: return 'excluded'
    if i in UNOBSERVABLE: return 'unobservable'
    if i in BLOCKING: return 'unresolvable'
    return 'judgement' if tier(row) in ('S', 'Q') else 'concrete'
