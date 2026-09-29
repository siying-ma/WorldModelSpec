"""Resolution of references inside corpus lines.

REFS   : line id -> [(substring in the text, [ids it resolves to])]. The generator inserts
         " [id, id]" right after the substring; the words of the law are not changed. Ids may
         be corpus lines, or DEF-* entries of definitions.jsonl. A substring may name a
         corpus section prefix ('NRS-484B-307-') to mean every line of that section.
XAPP   : line id -> [(src, chapter, section, path)] text from ANOTHER section appended verbatim.
APP_MORE: line id -> [paths] of the SAME section appended (in addition to the SPEC list).
DEFS   : definitions rendered to the planner after the laws, never as obligations.
UNRESOLVED: line id -> [{phrase, kind, note}] references that cannot be resolved inside the corpus.
"""
D_480_3 = 'DEF-NRS-484A-480-3'; D_460_2 = 'DEF-NRS-484A-460-2'; D_210 = 'DEF-NRS-484D-210-1-2'
D_420 = 'DEF-NRS-484B-420'; D_647 = 'DEF-LVMC-6-47-100-C'; D_60010 = 'DEF-LVMC-11-60-010'
D_185A = 'DEF-LVMC-11-40-185-A'; D_135A = 'DEF-LVMC-11-52-135-A'

# Definitions that are operative provisions cited by a line (kind 'provision'); the term
# definitions of the definition chapters are enumerated by make_laws.term_definitions().
DEFS = [
 # (id, src, ch, sec, paths, note)
 (D_480_3, 'NRS', '484A', '480', ['3'], "What 'flashing lights meeting the requirements of subsection 3 of NRS 484A.480' means: the lamps that make an authorized emergency vehicle observable as responding."),
 (D_460_2, 'NRS', '484A', '460', ['2', '4'], "How a high-occupancy-vehicle lane is designated and what its conditions are: the sign states the occupancy and the hours."),
 (D_210, 'NRS', '484D', '210', ['1', '2'], "The 'uppermost' and 'lowermost distribution of light': high beam and low beam."),
 (D_420, 'NRS', '484B', '420', [''], "The meaning of each hand-and-arm signal."),
 (D_647, 'LVMC', None, '6.47.100', ['C'], "The 'safety equipment' an ice cream truck engages: roof flashing amber light, extended yellow signal arm with alternately flashing amber lamps, hazard flashers."),
 (D_60010, 'LVMC', None, '11.60.010', [''], "Bus stops, bus stands, taxicab stands and route origin/destination points are designated by appropriate signs."),
 (D_185A, 'LVMC', None, '11.40.185', ['A'], "The local ordinance that NRS 484B.785(1) defers to: where an electric bicycle or electric scooter may be operated in the City."),
 (D_135A, 'LVMC', None, '11.52.135', ['A'], "How a parking space designated for the handicapped is signed."),
]

def _sec(prefix): return prefix  # marker: expand to every id starting with prefix

# A phrase that names no provision is NOT annotated: the ids would be the editor's reading of
# which rules 'the laws governing such movements' or 'as required by law' covers, not a
# resolution of a citation the statute makes. Seven such sites were removed on 2026-09-24;
# see laws/audit_and_scripts/ for the record. Only a phrase that names a provision is resolved.
REFS = {
 # ---- cross-line: subsection / paragraph of the same section ----
 'NRS-484B-250-1': [('subsection 4', ['NRS-484B-250-4'])],
 'NRS-484B-250-2': [('subsection 4', ['NRS-484B-250-4'])],
 'NRS-484B-250-3': [('subsection 4', ['NRS-484B-250-4'])],
 'NRS-484B-257-2': [('manner prescribed in subsection 1', ['NRS-484B-257-1'])],
 'NRS-484B-267-2f': [('proceed as required pursuant to subsection 1', ['NRS-484B-267-1a', 'NRS-484B-267-1b', 'NRS-484B-267-1c']),
                     ('proceed as required pursuant to NRS 484B.607', ['NRS-484B-607-1a', 'NRS-484B-607-1b', 'NRS-484B-607-1c', 'NRS-484B-607-1d']),
                     ('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-270-4': [('subsection 3', ['NRS-484B-270-3'])],
 'NRS-484B-283-1d3': [('subparagraph (1)', ['NRS-484B-283-1d1'])],
 'NRS-484B-283-1d4': [('subparagraph (1) or (2)', ['NRS-484B-283-1d1', 'NRS-484B-283-1d2'])],
 'NRS-484B-297-2': [('subsection 6', ['NRS-484B-297-6'])],
 'NRS-484B-307-8a': [('paragraphs (c) and (d)', ['(c) is appended below', 'NRS-484B-307-8d'])],
 'NRS-484B-307-9a': [('paragraph (b)', ['NRS-484B-307-9b'])],
 'NRS-484B-307-11': [('the provisions of this section', [_sec('NRS-484B-307-')])],
 'NRS-484B-403-1': [('prohibited by this section', ['NRS-484B-403-2', 'NRS-484B-403-3']),
                    ('NRS 484B.227, 484B.363 and 484B.407', ['NRS-484B-227-1', 'NRS-484B-363-3', 'NRS-484B-407'])],
 'NRS-484B-560-5': [('required to stop pursuant to subsection 1', ['NRS-484B-560-1'])],
 'NRS-484B-400-1': [('subsection 4 of NRS 484B.223', ['NRS-484B-223-4a', 'NRS-484B-223-4b'])],
 # ---- cross-section references to rules in the corpus ----
 'NRS-484B-217-2': [('in compliance with NRS 484B.413', ['NRS-484B-413-2'])],
 'NRS-484B-267-2a': [('subsection 1 of NRS 484B.600', ['NRS-484B-600-1a']), ('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-607-1a': [('subsection 1 of NRS 484B.600', ['NRS-484B-600-1a']), ('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-607-1b': [('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-607-1c': [('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-607-1d': [('subsection 3 of NRS 484A.480', [D_480_3])],
 'NRS-484B-650-1': [('NRS 484B.363 or 484B.600', ['NRS-484B-363-1', 'NRS-484B-363-2', 'NRS-484B-600-1a', 'NRS-484B-600-1b', 'NRS-484B-600-1c', 'NRS-484B-600-1e']),
                    ('in violation of NRS 484B.300', ['NRS-484B-300-1']),
                    ('in violation of NRS 484B.210', ['NRS-484B-210-3']),
                    ('in violation of NRS 484B.223', [_sec('NRS-484B-223-')]),
                    ('in violation of NRS 484B.127', ['LVMC-11-12-080-A', 'NRS-484B-127-2', 'NRS-484B-127-3']),
                    ('NRS 484B.250 to 484B.267, inclusive', [_sec('NRS-484B-250-'), 'NRS-484B-253', _sec('NRS-484B-257-'), 'NRS-484B-260', 'NRS-484B-263', _sec('NRS-484B-267-')])],
 'NRS-484B-270-2b': [('NRS 484B.213 and 484B.217', ['NRS-484B-213-1', 'NRS-484B-213-2a', 'NRS-484B-213-2b', 'NRS-484B-213-2c', 'NRS-484B-217-2'])],
 'NRS-484B-270-3': [('subsection 6 of NRS 484B.297', ['NRS-484B-297-6'])],
 'NRS-484B-300-1': [('Except as otherwise provided in NRS 484B.307', [_sec('NRS-484B-307-')])],
 'NRS-484B-307-2b': [('as provided in NRS 484B.283', ['NRS-484B-283-1d1', 'NRS-484B-283-1d2', 'NRS-484B-283-1d3', 'NRS-484B-283-1d4'])],
 'NRS-484B-307-4b': [('as provided in NRS 484B.283', ['NRS-484B-283-1d1', 'NRS-484B-283-1d2', 'NRS-484B-283-1d3', 'NRS-484B-283-1d4'])],
 'NRS-484B-307-8b': [('as provided in NRS 484B.283', ['NRS-484B-283-1d1', 'NRS-484B-283-1d2', 'NRS-484B-283-1d3', 'NRS-484B-283-1d4'])],
 'NRS-484B-307-9c': [('as provided in NRS 484B.283', ['NRS-484B-283-1d1', 'NRS-484B-283-1d2', 'NRS-484B-283-1d3', 'NRS-484B-283-1d4'])],
 'NRS-484B-208-1': [('pursuant to NRS 484A.460, if the driver complies with the requirements to travel in such a lane', [D_460_2, 'NRS-484B-323-1'])],
 'NRS-484B-323-1': [('subsection 2 of NRS 484A.460', [D_460_2])],
 'NRS-484B-769': [('in the manner required by NRS 484B.420', [D_420])],
 'NRS-484B-785-1a': [('an ordinance enacted pursuant to NRS 484A.469', [D_185A])],
 'NRS-484D-215-1': [('during the times specified in NRS 484D.100', ['NRS-484D-100-1']), ('subsection 2 of NRS 484D.210', [D_210])],
 'NRS-484D-215-2': [('during the times specified in NRS 484D.100', ['NRS-484D-100-1']), ('subsection 1 of NRS 484D.210', [D_210])],
 'NRS-484D-220-1': [('At all times specified in NRS 484D.100', ['NRS-484D-100-1'])],
 'NRS-484D-165-3': [('during the times mentioned in NRS 484D.100', ['NRS-484D-100-1'])],
 'LVMC-11-22-150-A': [('Subsection (C) of Section 6.47.100', [D_647])],
 'LVMC-11-22-150-B': [('Subsection (C) of Section 6.47.100', [D_647])],
 'LVMC-11-60-030-A1': [('designated in accordance with Section 11.60.010', [D_60010])],
 'LVMC-11-60-030-A2': [('designated in accordance with Section 11.60.010', [D_60010])],
 'LVMC-11-60-030-A5': [('in accordance with Section 11.60.010', [D_60010])],
 'LVMC-11-52-250': [('Except as provided in LVMC 11.52.030', ['LVMC-11-52-030-A', 'LVMC-11-52-030-B', 'LVMC-11-52-030-E'])],
 'LVMC-11-52-260': [('Except as provided in LVMC 11.52.030', ['LVMC-11-52-030-A', 'LVMC-11-52-030-B', 'LVMC-11-52-030-E'])],
 'LVMC-11-52-030-E': [('pursuant to LVMC 11.52.135', [D_135A])],
 # ---- references whose statutory target was dropped for a narrower municipal text ----
 'NRS-484B-283-1a': [('NRS 484B.287', ['NRS-484B-287-1c', 'NRS-484B-287-1d', 'NRS-484B-287-1e', 'LVMC-11-30-060-A', 'LVMC-11-30-060-B']), ('484B.290', ['LVMC-11-30-140-B']), ('484B.350', ['LVMC-11-46-030'])],
 'NRS-484B-283-1b': [('NRS 484B.287', ['NRS-484B-287-1c', 'NRS-484B-287-1d', 'NRS-484B-287-1e', 'LVMC-11-30-060-A', 'LVMC-11-30-060-B']), ('484B.290', ['LVMC-11-30-140-B']), ('484B.350', ['LVMC-11-46-030'])],
 'NRS-484B-283-1c_unused': [],
 'NRS-484B-283-1d1': [('NRS 484B.287', ['NRS-484B-287-1c', 'NRS-484B-287-1d', 'NRS-484B-287-1e', 'LVMC-11-30-060-A', 'LVMC-11-30-060-B']), ('484B.290', ['LVMC-11-30-140-B']), ('484B.350', ['LVMC-11-46-030'])],
 'NRS-484B-283-1d2': [('NRS 484B.287', ['NRS-484B-287-1c', 'NRS-484B-287-1d', 'NRS-484B-287-1e', 'LVMC-11-30-060-A', 'LVMC-11-30-060-B']), ('484B.290', ['LVMC-11-30-140-B']), ('484B.350', ['LVMC-11-46-030'])],
 'NRS-484B-287-1c': [('Except as provided in NRS 484B.290', ['LVMC-11-30-140-B'])],
 'NRS-484B-287-1d': [('Except as provided in NRS 484B.290', ['LVMC-11-30-140-B'])],
 'NRS-484B-287-1e': [('Except as provided in NRS 484B.290', ['LVMC-11-30-140-B'])],
}
# 283-1d3 / 1d4 also carry the lead-in
for _i in ('NRS-484B-283-1d3', 'NRS-484B-283-1d4'):
    REFS[_i] = [('NRS 484B.287', ['NRS-484B-287-1c', 'NRS-484B-287-1d', 'NRS-484B-287-1e', 'LVMC-11-30-060-A', 'LVMC-11-30-060-B']), ('484B.290', ['LVMC-11-30-140-B']), ('484B.350', ['LVMC-11-46-030'])] + REFS[_i]
for _i in ('NRS-484B-267-1a', 'NRS-484B-267-1b', 'NRS-484B-267-1c', 'NRS-484B-267-2b', 'NRS-484B-267-2c', 'NRS-484B-267-2d', 'NRS-484B-267-2e'):
    REFS[_i] = [('subsection 3 of NRS 484A.480', [D_480_3])]
del REFS['NRS-484B-283-1c_unused']

# notes on references whose target text is appended to the same line
_APPENDED = {
 'NRS-484A-480-5': [('Except as otherwise provided in subsection 4', ['(4) appended below'])],
 'NRS-484B-117-1': [('Except as otherwise provided in subsection 2', ['(2) appended below'])],
 'NRS-484B-210-1': [('Except as otherwise provided in subsection 4', ['(4) appended below'])],
 'NRS-484B-457-1': [('Except as otherwise provided in this section', ['(2) and (3) appended below'])],
 'NRS-484B-587-2a': [('as otherwise authorized by subsection 3', ['(3) appended below']), ('paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210', ['list appended below'])],
 'NRS-484B-587-2b': [('as otherwise authorized by subsection 3', ['(3) appended below'])],
 'NRS-484B-267-1b': [('paragraphs (a) to (f), inclusive, of subsection 4 of NRS 484B.210', ['list appended below'])],
 'NRS-484B-633-2': [('signposted as provided in this section', ['(3) appended below'])],
 'NRS-484B-637-2b': [('Except as otherwise provided in subsection 3', ['(3) and (4) appended below'])],
 'NRS-484D-165-3': [('lighted lamps meeting the requirements of subsection 1', ['(1) appended below'])],
 'NRS-484D-545-1': [('except as provided in subsection 3', ['(3) appended below'])],
 'LVMC-11-38-130': [('as provided in Section 11.38.080', ['11.38.080 appended below'])],
}
for _k, _v in _APPENDED.items():
    REFS[_k] = _v + REFS.get(_k, [])

# same-section paragraphs appended in addition to the SPEC list
APP_MORE = {
 'NRS-484A-480-5': ['4'],
 'NRS-484B-117-1': ['2'],
 'NRS-484B-210-1': ['4'],
 'NRS-484B-457-1': ['2', '3'],
 'NRS-484B-587-2b': ['3'],
 'NRS-484B-633-2': ['3'],
 'NRS-484B-637-2b': ['3', '4'],
 'NRS-484D-165-3': ['1'],
 'NRS-484D-545-1': ['3'],
}
# text from another section appended verbatim
XAPP = {
 'NRS-484B-267-1b': [('NRS', '484B', '210', '4')],
 'NRS-484B-587-2a': [('NRS', '484B', '210', '4')],
 'NRS-484B-587-2b': [('NRS', '484B', '210', '4')],
 'LVMC-11-38-130': [('LVMC', None, '11.38.080', '')],
}

SCHEDULE_NOTE = "a street list held by the City Clerk, not in the corpus and not observable on the road; the same sentence makes the posted sign or curb marking the condition, and the sign is the observable"
UNRESOLVED = {
 'NRS-484B-307-11': [dict(phrase="except as to those provisions which by their nature can have no application", kind='no_criterion', note="no rule of decision is given for which provisions apply at a mid-block signal; residue")],
 'NRS-484B-790-3': [dict(phrase="except those which by their nature can have no application", kind='no_criterion', note="which pedestrian duties a mobile carrying device inherits is left to the reader; residue")],
 'NRS-484A-480-5': [dict(phrase="49 C.F.R. § 571.108", kind='external_standard', note="federal lamp standard; the headlamp modulation it permits is not observable as distinct from flashing")],
 'NRS-484A-480-6': [dict(phrase="a vehicle operated pursuant to NRS 408.437", kind='external_class', note="Department of Transportation vehicles; not in the corpus; approximated by ru.official_vehicle kind highway_maintenance")],
 'NRS-484A-480-7': [dict(phrase="a motorcycle pursuant to NRS 486.261", kind='external_equipment', note="a blue insert of up to one inch in a motorcycle tail lamp; not distinguishable from a blue lamp at scene scale"),
                    dict(phrase="a vehicle operated pursuant to NRS 408.437", kind='external_class', note="as for the preceding line")],
 'NRS-484B-327-2': [dict(phrase="any additional penalty set forth in NRS 484B.130 or 484B.135", kind='penalty', note="penalty clause; no conduct")],
 'NRS-484B-550-1': [dict(phrase="Except as otherwise provided in this section", kind='penalty', note="the other subsections of 484B.550 are penalties; no conduct")],
 'NRS-484B-560-1': [dict(phrase="hazardous materials as that term is defined in 49 C.F.R. § 383.5", kind='federal_definition', note="the class is federal; the observable is the placard (ru.hazardous_materials_vehicle)")],
 'NRS-484B-560-5': [dict(phrase="commercial motor vehicle, as that term is defined in 49 C.F.R. § 383.5", kind='federal_definition', note="a weight-and-use class; estimated from vehicle class and size")],
 'NRS-484B-323-1': [dict(phrase="or established by regulation", kind='regulation', note="conditions not on the sign are not observable")],
 'NRS-484B-360-2': [dict(phrase="activity which is properly a part of a school program", kind='purpose', note="the purpose of a trip is not observable; reading assumption per trace")],
 'NRS-484D-185-1': [dict(phrase="as authorized in NRS 484B.748, 484B.757 or 484D.190", kind='external_class', note="tow cars at a hazard, private patrol vehicles, food vendors: permit-based classes; approximated by ru.official_vehicle / ru.vending_vehicle")],
 'NRS-484D-220-1': [dict(phrase="meeting the requirements of NRS 484D.110", kind='external_equipment', note="headlamp count and mounting height; equipment law, not conduct")],
 'NRS-486-251-1': [dict(phrase="as respectively required pursuant to NRS 486.011 to 486.381, inclusive", kind='external_equipment', note="the lamps a motorcycle carries (head lamp, tail lamp); the observable is a lit head lamp and tail lamp")],
 'LVMC-11-16-050': [dict(phrase="provided after a traffic study the City Traffic Engineer determines that such a prima facie speed is necessary", kind='administrative', note="whether the limit is in force at a given park is an administrative fact; reading assumption per map")],
 'LVMC-11-16-110': [dict(phrase="Schedule 25-VII", kind='schedule', note=SCHEDULE_NOTE), dict(phrase="Schedule 29-II", kind='schedule', note="truck routes; posted with signs per 11.48.080")],
 'LVMC-11-41-020': [dict(phrase="locations designated by Schedule 28-I", kind='schedule_region', note="the streets where golf carts may operate are listed, not signed; region as reading assumption")],
 'LVMC-11-44-020': [dict(phrase="Schedule 18-I", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-44-030': [dict(phrase="Schedule 18-II", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-44-040': [dict(phrase="Schedule 18-III", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-44-060': [dict(phrase="Schedule 18-V", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-44-080': [dict(phrase="Schedule 18-VI", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-48-030': [dict(phrase="Schedule 29-II", kind='schedule', note="truck routes; posted with signs per 11.48.080; the sign is the observable"),
                    dict(phrase="temporary truck routes hereafter designated by the Department of Public Works pursuant to Section 11.48.070", kind='external_designation', note="temporary routes are posted with temporary truck-route signs (11.48.070); the sign is the observable")],
 'LVMC-11-52-180-A': [dict(phrase="Schedule 17-I", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-52-180-B': [dict(phrase="Schedule 17-II", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-52-250': [dict(phrase="Schedule 17-IV", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-52-260': [dict(phrase="Schedule 17-V", kind='schedule', note=SCHEDULE_NOTE)],
 'LVMC-11-52-270': [dict(phrase="Schedule 17-VI", kind='schedule', note=SCHEDULE_NOTE),
                    dict(phrase="lawfully displays on the vehicle a special or temporary handicap parking permit or plate", kind='permit', note="a permit or plate is not reliably observable; residue")],
 'LVMC-11-52-030-E': [dict(phrase="displays a valid handicapped permit or license plate", kind='permit', note="not reliably observable; residue")],
 'LVMC-11-60-030-B1': [dict(phrase="\"celebrity home\" tour or to any function of a duly established and recognized nonprofit organization", kind='purpose', note="the purpose of the trip is not observable; residue")],
 'LVMC-11-68-030': [dict(phrase="the area designated under Section 11.68.040", kind='region_map', note="the Pedestrian Mall boundary is an ordinance exhibit map; region as reading assumption, or dev.zone_sign pedestrian_mall where posted")],
 'NRS-484B-607-1a': [dict(phrase="meeting the requirements of NRS 484B.748", kind='external_equipment', note="permits and standards for amber and steady-blue lamps (484B.748, 484D.185, .195, .200, .475); the observable is the lamp colour and mode (sig.warning_lamp)")],
}
for _i in ('NRS-484B-607-1b', 'NRS-484B-607-1c', 'NRS-484B-607-1d'):
    UNRESOLVED[_i] = UNRESOLVED['NRS-484B-607-1a']
