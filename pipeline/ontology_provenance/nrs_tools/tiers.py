"""Classification of every corpus line into one of four views (CORPUS_AUDIT_2026-09-19.md §3–§4).

Precedence: EXCLUDED > unresolvable > tier S/Q > tier C.
  excluded.jsonl     lines that do not judge a driving situation (apparel, equipment legality, a permission)
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
LVMC-11-12-080-A LVMC-11-12-090 LVMC-11-22-010 LVMC-11-22-020 LVMC-11-22-150-A LVMC-11-40-130 LVMC-11-40-185-B""".split())

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
    if i in BLOCKING: return 'unresolvable'
    return 'judgement' if tier(row) in ('S', 'Q') else 'concrete'
