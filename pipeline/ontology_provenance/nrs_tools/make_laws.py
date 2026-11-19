"""Generate laws.jsonl (verbatim statutory obligations) from parsed NRS and LVMC section trees.

Cutting rules (see traffic-spec-agent/laws/README.md): one paragraph per line; lead-in
stems that end in ':' are prepended; qualifying paragraphs are appended verbatim; enumeration
conjunctions ('; and', '; or', trailing ';') become full stops; nothing else is changed.
"""
import json, re
from pathlib import Path

import nrs_tree, lvmc_tree

# Output directories (the corpus layout under traffic-spec-agent/laws/)
LAWS_ROOT = Path(__file__).resolve().parents[2] / "traffic-spec-agent" / "laws"
CORPUS_DIR = LAWS_ROOT / "full_list"          # the four JSONL views and definitions.jsonl
AUDIT_DIR = LAWS_ROOT / "audit_and_scripts"   # OVERLAPS.md, CONCRETE_DEPENDENCIES.md

from references import INCORPORATED
NRS = {c: nrs_tree.load(c) for c in ('484A', '484B', '484D', '486') + tuple(sorted({ch for ch, _ in INCORPORATED}))}
LVMC = lvmc_tree.load()

_INCORPORATION = re.compile(r'(?:defined (?:in|by)|meaning ascribed to (?:it|them) in)\s+(?:(?:subsections?|paragraphs?) [\w(), ]+? of\s+)?NRS\s+(\d+[A-Z]?)\.(\d+)')

def missing_incorporations(texts, definition_ids):
    """(text id, cited section) for each place a text takes a term's meaning from an NRS section
    ("as defined in NRS 482.029", "has the meaning ascribed to it in NRS 489.113") whose
    definition `DEF-NRS-<chapter>-<section>` is not among `definition_ids`."""
    return [(o['id'], f"NRS {ch}.{sec}") for o in texts for ch, sec in _INCORPORATION.findall(o['text'])
            if f"DEF-NRS-{ch}-{sec}" not in definition_ids]

def mark_incorporations(text, definition_ids):
    """`text` with the definition id `[DEF-NRS-<chapter>-<section>]` after each NRS section it takes a
    term's meaning from, where that definition is among `definition_ids`, as a cited provision is
    marked: the definition the text names is the one its term means."""
    def mark(m):
        did = f"DEF-NRS-{m.group(1)}-{m.group(2)}"
        follows = text[m.end():m.end() + len(did) + 3]
        return m.group(0) + (f" [{did}]" if did in definition_ids and not follows.startswith(f" [{did}]") else '')
    return _INCORPORATION.sub(mark, text)

def split_title(title, root_text):
    title = re.sub(r'\s+', ' ', title).strip()
    root_text = root_text.strip()
    # A version note "[Effective ...]" closes the catchline and is no part of the text. The page
    # wraps catchline, note and text across the title and the text, so the note is found in
    # their join: before it is the catchline, after it the text.
    whole = (title + ' ' + root_text).strip()
    note = re.search(r'\s*\[Effective[^\]]*\]\s*', whole)
    if note:
        catchline = whole[:note.start()]
        assert catchline.endswith('.') and '[' not in catchline, ('version note inside a text', title)
        return catchline[:-1], whole[note.end():]
    if title.endswith('.'):
        return title[:-1], root_text
    if '. ' in title:
        i = title.rfind('. ')
        return title[:i], (title[i+2:] + ' ' + root_text).strip()
    j = root_text.find('.')
    if 0 <= j < 220:
        return (title + ' ' + root_text[:j]).strip(), root_text[j+1:].strip()
    return title, root_text

def section(src, ch, sec):
    if src == 'NRS':
        e = NRS[ch][sec]
        tree = nrs_tree.parse(e['text'])
        title, root = split_title(e['title'], tree['text'])
        tree['text'] = root
        return title, tree, nrs_tree.get
    e = LVMC[sec]
    tree = lvmc_tree.parse(e['text'])
    return e['title'], tree, lvmc_tree.get

def flatten(node):
    parts = [node['text']]
    if node.get('tail'): parts.append(node['tail'].strip())
    for s in node['subs']:
        parts.append(f"({s['label']}) " + flatten(s))
    return ' '.join(p for p in parts if p)

def clean(t):
    t = re.sub(r'\s+([,.;:])', r'\1', t)
    t = re.sub(r'\s+', ' ', t).strip()
    return t.replace('Ê', '').strip()

def trim(t):
    t = clean(t)
    t = re.sub(r';\s*(?:and|or)$', '.', t)
    t = re.sub(r'[;:]$', '.', t)
    return t

def path_label(path):
    return ''.join(f'({p})' for p in path.split('.')) if path else ''

def build(src, ch, sec, path, appended=(), pre=(), xapp=()):
    title, tree, get = section(src, ch, sec)
    leadins = []
    node = tree
    if path:
        if tree['text'].rstrip().endswith(':'):
            leadins.append(tree['text'])
        parts = path.split('.')
        for k in range(1, len(parts)):
            anc = get(tree, '.'.join(parts[:k]))
            if anc['text'].rstrip().endswith(':'):
                leadins.append(anc['text'])
        node = get(tree, path)
    text = ' '.join(trim(flatten(get(tree, p))) for p in pre)
    text = (text + ' ' if text else '') + trim(' '.join(leadins + [flatten(node)]))
    for ap in appended:
        text += ' ' + trim(flatten(get(tree, ap)))
    xlabels = []
    for (xs, xch, xsec, xpath) in xapp:
        _, xtree, xget = section(xs, xch, xsec)
        node = xget(xtree, xpath)
        lead = [xtree['text']] if (xpath and xtree['text'].rstrip().endswith(':')) else []
        text += ' ' + trim(' '.join(lead + [flatten(node)]))
        xlabels.append((f"NRS {xch}.{xsec}" if xs == 'NRS' else f"LVMC {xsec}") + path_label(xpath))
    text = clean(text)
    label = f"NRS {ch}.{sec}" if src == 'NRS' else f"LVMC {sec}"
    srcs = f"{label}{path_label(path)}"
    extra = list(pre) + list(appended)
    if extra or xlabels:
        srcs += '; with ' + ', '.join([f"{label.split(' ',1)[1]}{path_label(a)}" for a in extra] + xlabels)
    return title, text, srcs

def lid(src, ch, sec, path):
    if src == 'NRS':
        return f"NRS-{ch}-{sec}" + ('-' + path.replace('.', '') if path else '')
    return 'LVMC-' + sec.replace('.', '-') + ('-' + path.replace('.', '') if path else '')

D = 'driver'; P = 'pedestrian'; R = 'rider'; M = 'motorcyclist'

def N(ch, sec, path='', app=(), subj=D, theme='', pre=(), overlaps=()):
    return ('NRS', ch, sec, path, app, subj, theme, pre, overlaps)
def L(sec, path='', app=(), subj=D, theme='', pre=(), overlaps=()):
    return ('LVMC', None, sec, path, app, subj, theme, pre, overlaps)

SPEC = [
 # ================= NRS 484A =================
 N('484A','450','2',subj=D,theme='intersections_and_right_of_way'),
 N('484A','450','3',subj=D,theme='intersections_and_right_of_way'),
 N('484A','480','5',subj=D,theme='lamps_and_warnings'),
 N('484A','480','6',subj=D,theme='lamps_and_warnings'),
 N('484A','480','7',subj=D,theme='lamps_and_warnings'),
 # ================= NRS 484B =================
 N('484B','100','',subj='any_person',theme='officers_and_flaggers'),
 N('484B','110','',theme='vulnerable_road_users'),
 N('484B','113','1',theme='backing_and_starting'), N('484B','113','2',theme='backing_and_starting'), N('484B','113','3',theme='backing_and_starting'),
 N('484B','117','1',theme='roadway_position'), N('484B','120','',theme='roadway_position'),
 N('484B','127','1',theme='following'), N('484B','127','2',subj='truck_driver',theme='following'), N('484B','127','3',theme='following'),
 N('484B','153','2',subj='occupant',theme='doors_and_boarding'), N('484B','153','3',subj='occupant',theme='doors_and_boarding'),
 N('484B','200','1',theme='roadway_position'), N('484B','203','1',theme='roadway_position'),
 N('484B','207','1',theme='overtaking'), N('484B','207','2',theme='overtaking'),
 N('484B','208','1',('2',),theme='lanes'),
 N('484B','210','1',theme='overtaking'), N('484B','210','2',theme='overtaking'), N('484B','210','3',theme='overtaking'),
 N('484B','213','1',theme='overtaking'), N('484B','213','2.a',('3',),theme='overtaking'), N('484B','213','2.b',('3',),theme='overtaking'), N('484B','213','2.c',('3',),theme='overtaking'),
 N('484B','217','2',('3','4'),theme='overtaking'),
 N('484B','220','1',theme='roadway_position'), N('484B','220','2',theme='roadway_position'),
 N('484B','223','1.a',theme='lanes'), N('484B','223','1.b',theme='lanes'), N('484B','223','2',theme='lanes'),
 N('484B','223','3.a',theme='lanes'), N('484B','223','3.b',theme='lanes'), N('484B','223','3.c',theme='lanes'),
 N('484B','223','4.a',theme='lanes'), N('484B','223','4.b',theme='lanes'),
 N('484B','227','1',theme='roadway_position'),
 N('484B','250','1',('5',),theme='intersections_and_right_of_way'), N('484B','250','2',('5',),theme='intersections_and_right_of_way'),
 N('484B','250','3',('5',),theme='intersections_and_right_of_way'), N('484B','250','4',theme='intersections_and_right_of_way'),
 N('484B','253','',theme='intersections_and_right_of_way'),
 N('484B','257','1',theme='intersections_and_right_of_way'), N('484B','257','2',theme='intersections_and_right_of_way'),
 N('484B','260','',theme='intersections_and_right_of_way'), N('484B','263','',theme='controlled_access'),
] + [N('484B','267','1.'+c,theme='emergency_and_incident') for c in 'abc'] \
  + [N('484B','267','2.'+c,('4',),theme='emergency_and_incident') for c in 'abcdef'] + [
 N('484B','270','1',theme='vulnerable_road_users'), N('484B','270','2.a',theme='vulnerable_road_users'), N('484B','270','2.b',theme='vulnerable_road_users'),
 N('484B','270','3',theme='vulnerable_road_users'), N('484B','270','4',theme='vulnerable_road_users'),
 N('484B','270','5.a',theme='vulnerable_road_users'), N('484B','270','5.b',theme='vulnerable_road_users'),
 N('484B','270','7.a',subj=R,theme='cycles_and_devices'), N('484B','270','7.b',subj=R,theme='cycles_and_devices'),
 N('484B','280','1.a',theme='vulnerable_road_users'), N('484B','280','1.b',theme='vulnerable_road_users'), N('484B','280','1.c',theme='vulnerable_road_users'),
 N('484B','283','1.a',('4',),theme='vulnerable_road_users'), N('484B','283','1.b',subj=P,theme='pedestrian_duties'), N('484B','283','1.c',theme='vulnerable_road_users'),
 N('484B','283','1.d.1',theme='vulnerable_road_users'), N('484B','283','1.d.2',subj=P,theme='pedestrian_duties'),
 N('484B','283','1.d.3',subj=P,theme='pedestrian_duties'), N('484B','283','1.d.4',subj=P,theme='pedestrian_duties'),
] + [N('484B','287','1.'+c,subj=P,theme='pedestrian_duties') for c in 'abcde'] + [
 N('484B','290','',theme='vulnerable_road_users'), N('484B','293','',subj=P,theme='pedestrian_duties'),
 N('484B','297','1',subj=P,theme='pedestrian_duties'), N('484B','297','2',subj=P,theme='pedestrian_duties'), N('484B','297','6',subj=P,theme='pedestrian_duties'),
 N('484B','300','1',theme='devices_and_signals'),
 N('484B','307','2.a',theme='devices_and_signals'), N('484B','307','2.b',subj=P,theme='pedestrian_duties'),
 N('484B','307','3.a',theme='devices_and_signals'), N('484B','307','4.a',theme='devices_and_signals'), N('484B','307','4.b',subj=P,theme='pedestrian_duties'),
 N('484B','307','5.a',theme='devices_and_signals'), N('484B','307','6.a',theme='devices_and_signals'), N('484B','307','7.a',theme='devices_and_signals'),
 N('484B','307','8.a',('8.c',),theme='devices_and_signals'), N('484B','307','8.b',subj=P,theme='pedestrian_duties'), N('484B','307','8.c',theme='devices_and_signals'),
 N('484B','307','8.d',subj=R,theme='devices_and_signals'), N('484B','307','8.e',theme='devices_and_signals'),
 N('484B','307','9.a',theme='devices_and_signals'), N('484B','307','9.b',subj=R,theme='devices_and_signals'), N('484B','307','9.c',subj=P,theme='pedestrian_duties'),
 N('484B','307','11',theme='devices_and_signals'), N('484B','307','12.a',theme='devices_and_signals'), N('484B','307','12.b',theme='devices_and_signals'),
 N('484B','310','1',theme='devices_and_signals'), N('484B','310','2',theme='devices_and_signals'),
 N('484B','323','1',('3',),theme='lanes'), N('484B','327','2',theme='devices_and_signals'), N('484B','330','1',theme='officers_and_flaggers'),
 N('484B','350','1.a',('4',),theme='school'), N('484B','350','1.b',('4',),theme='school'), N('484B','353','1',('2',),theme='school'),
 N('484B','360','1',subj='school_bus_driver',theme='school'), N('484B','360','2',subj='school_bus_driver',theme='school'),
 N('484B','363','1',('9',),theme='school'), N('484B','363','2',('9',),theme='school'), N('484B','363','3',('9',),theme='school'), N('484B','363','4',('9',),theme='school'),
 N('484B','400','1',theme='turns_and_signals'), N('484B','400','2.a',theme='turns_and_signals'), N('484B','400','2.b',theme='turns_and_signals'), N('484B','400','2.c',theme='turns_and_signals'),
 N('484B','400','3',theme='turns_and_signals'), N('484B','400','4',theme='turns_and_signals'), N('484B','400','5',theme='turns_and_signals'),
 N('484B','403','1',theme='turns_and_signals'), N('484B','403','2',theme='turns_and_signals'), N('484B','403','3',theme='turns_and_signals'),
 N('484B','407','',theme='turns_and_signals'), N('484B','410','',theme='backing_and_starting'),
 N('484B','413','1',theme='turns_and_signals'), N('484B','413','2',theme='turns_and_signals'), N('484B','413','3',theme='turns_and_signals'),
 N('484B','440','1',('2',),theme='stopping_standing_parking'),
] + [N('484B','450','1.'+c,theme='stopping_standing_parking') for c in 'bcdefghijklmo'] + [
 N('484B','450','1.a',('3',),theme='stopping_standing_parking'), N('484B','450','1.n',('2',),theme='stopping_standing_parking'),
 N('484B','457','1',theme='stopping_standing_parking'), N('484B','460','',theme='stopping_standing_parking'), N('484B','473','2',theme='lamps_and_warnings'),
 N('484B','477','1.a',theme='stopping_standing_parking'), N('484B','477','1.b',theme='stopping_standing_parking'), N('484B','477','2',theme='stopping_standing_parking'),
 N('484B','490','',theme='stopping_standing_parking'), N('484B','493','',theme='stopping_standing_parking'), N('484B','497','',theme='stopping_standing_parking'),
 N('484B','500','',theme='stopping_standing_parking'), N('484B','503','',theme='stopping_standing_parking'), N('484B','507','1',('2',),theme='stopping_standing_parking'),
 N('484B','510','',theme='stopping_standing_parking'), N('484B','513','',subj='bus_or_taxicab_operator',theme='stopping_standing_parking'),
 N('484B','517','',theme='stopping_standing_parking'), N('484B','533','',theme='stopping_standing_parking'),
 N('484B','550','1',('2',),theme='officers_and_flaggers'),
 N('484B','553','1',theme='railroad'), N('484B','553','2',theme='railroad'), N('484B','557','',theme='railroad'),
 N('484B','560','1',('4',),subj='bus_or_hazmat_driver',theme='railroad'), N('484B','560','3',theme='railroad'), N('484B','560','5',subj='commercial_driver',theme='railroad'),
 N('484B','560','6',theme='railroad'), N('484B','560','7.a',('8',),theme='railroad'), N('484B','560','7.b',theme='railroad'),
 N('484B','587','1',theme='controlled_access'), N('484B','587','2.a',('3',),theme='controlled_access'), N('484B','587','2.b',theme='controlled_access'),
 N('484B','600','1.a',theme='speed'), N('484B','600','1.b',theme='speed'), N('484B','600','1.c',theme='speed'), N('484B','600','1.e',theme='speed'),
 N('484B','603','1',theme='speed'),
] + [N('484B','607','1.'+c,('3',),theme='emergency_and_incident') for c in 'abcd'] + [
 N('484B','620','2',theme='speed'), N('484B','623','1',theme='speed'),
 N('484B','627','1.a',theme='speed'), N('484B','627','1.b',theme='speed'), N('484B','627','1.c',theme='speed'), N('484B','627','2',theme='speed'),
 N('484B','630','1',('3',),theme='speed'), N('484B','633','2',theme='speed'), N('484B','637','2.b',subj='low_speed_vehicle_operator',theme='speed'),
 N('484B','650','1',theme='conduct_standard'), N('484B','653','1.a',theme='conduct_standard'),
 N('484B','700','1',('2','4'),subj='emergency_vehicle_driver',theme='emergency_and_incident'),
 N('484B','703','1',theme='processions'), N('484B','707','1',subj='procession_vehicle',theme='processions'), N('484B','707','2',subj='procession_vehicle',theme='processions'),
 N('484B','710','',theme='emergency_and_incident'),
 N('484B','768','1',('2',),subj=R,theme='cycles_and_devices'), N('484B','769','',subj=R,theme='cycles_and_devices'),
 N('484B','770','1',subj=R,theme='cycles_and_devices'), N('484B','770','2',subj=R,theme='cycles_and_devices'), N('484B','773','',subj=R,theme='cycles_and_devices'),
 N('484B','777','1',('2',),subj=R,theme='cycles_and_devices'), N('484B','777','3',subj=R,theme='cycles_and_devices'), N('484B','780','',subj=R,theme='cycles_and_devices'),
 N('484B','783','1',subj=R,theme='cycles_and_devices'), N('484B','785','1.a',subj=R,theme='cycles_and_devices'),
] + [N('484B','787','2.'+c,subj='delivery_device_operator',theme='cycles_and_devices') for c in 'abc'] \
  + [N('484B','790','2.'+c,subj='delivery_device_operator',theme='cycles_and_devices') for c in 'abc'] + [
 N('484B','790','3',subj='delivery_device_operator',theme='cycles_and_devices'),
 N('484B','913','',theme='misc'),
 # ================= NRS 484D =================
 N('484D','100','1',theme='lamps_and_warnings'), N('484D','165','1',theme='lamps_and_warnings'), N('484D','165','3',theme='lamps_and_warnings'), N('484D','165','4',theme='lamps_and_warnings'),
 N('484D','185','1',theme='lamps_and_warnings'), N('484D','205','4',theme='lamps_and_warnings'),
 N('484D','215','1',theme='lamps_and_warnings'), N('484D','215','2',theme='lamps_and_warnings'), N('484D','220','1',theme='lamps_and_warnings'),
 N('484D','285','1',theme='lamps_and_warnings'), N('484D','400','2',theme='lamps_and_warnings'), N('484D','400','5',subj='emergency_vehicle_driver',theme='lamps_and_warnings'),
 N('484D','515','1',theme='misc'), N('484D','545','1',subj='slow_vehicle_operator',theme='lamps_and_warnings'),
 # ================= NRS 486 (motorcycles, mopeds, trimobiles) =================
 N('486','181','1',subj=M,theme='motorcycles'),
 N('486','191','1',subj=M,theme='motorcycles'),
 N('486','211','',subj=M,theme='motorcycles'),
 N('486','231','2',('3','4','5','6'),subj=M,theme='motorcycles'),
 N('486','251','1',subj=M,theme='motorcycles'),
 N('486','341','',subj=D,theme='motorcycles'),
 N('486','351','1',subj=M,theme='motorcycles'),
 N('486','351','2',('3',),subj=M,theme='motorcycles'),
 N('486','351','4',('5',),subj='moped_rider',theme='motorcycles'),
 # ================= Las Vegas Municipal Code, Title 11 =================
 L('11.06.030',subj='any_person',theme='officers_and_flaggers',overlaps=('NRS-484B-100',)),
 L('11.12.020',theme='turns_and_signals'),
 L('11.12.050',theme='turns_and_signals',overlaps=('NRS-484B-403-1','NRS-484B-403-3')),
 L('11.12.060',theme='turns_and_signals'),
 L('11.12.070','A',theme='intersections_and_right_of_way',overlaps=('NRS-484B-257-1',)),
 L('11.12.070','B',theme='intersections_and_right_of_way',overlaps=('NRS-484B-257-1',)),
 L('11.12.080','A',('C',),theme='following',overlaps=('NRS-484B-127-1',)),
 L('11.12.080','B',('C',),subj='truck_driver',theme='following',overlaps=('NRS-484B-127-2',)),
 L('11.12.090',theme='vulnerable_road_users'),
 L('11.12.100','C',theme='lanes',overlaps=('NRS-484B-223-3a',)),
 L('11.16.020',theme='speed',overlaps=('NRS-484B-363-1',)),
 L('11.16.030',theme='speed'),
 L('11.16.040',theme='speed'),
 L('11.16.050',theme='speed'),
 L('11.16.060',theme='speed'),
 L('11.16.070',theme='speed',overlaps=('NRS-484B-363-2',)),
 L('11.16.090','A',theme='conduct_standard'),
 L('11.16.110',subj='truck_driver',theme='speed'),
 L('11.18.020',theme='school'),
 L('11.18.030','B',theme='lanes',overlaps=('NRS-484B-223-1a',)),
 L('11.20.040',theme='intersections_and_right_of_way',overlaps=('NRS-484A-450-2',)),
 L('11.20.060',theme='intersections_and_right_of_way',overlaps=('NRS-484B-260',)),
 L('11.20.070',theme='intersections_and_right_of_way'),
 L('11.22.010',theme='conduct_standard'),
 L('11.22.020',theme='conduct_standard'),
 L('11.22.040',theme='roadway_position',overlaps=('NRS-484B-117-1',)),
 L('11.22.050',theme='controlled_access',overlaps=('NRS-484B-587-1',)),
 L('11.22.055',theme='lamps_and_warnings',overlaps=('NRS-484D-285-1',)),
 L('11.22.070',theme='vulnerable_road_users',overlaps=('NRS-484B-110',)),
 L('11.22.090',subj='occupant',theme='doors_and_boarding',overlaps=('NRS-484B-153-2','NRS-484B-153-3')),
 L('11.22.100',theme='devices_and_signals',overlaps=('NRS-484B-327-2',)),
 L('11.22.120','B',pre=('A',),subj=R,theme='cycles_and_devices'),
 L('11.22.130','A',subj=R,theme='cycles_and_devices'),
 L('11.22.130','B',subj=R,theme='cycles_and_devices'),
 L('11.22.130','C',subj=R,theme='cycles_and_devices'),
 L('11.22.150','A',theme='speed'),
 L('11.22.150','B',theme='speed'),
 L('11.27.010','A',('B',),theme='roadway_position'),
 L('11.28.050',theme='lamps_and_warnings',overlaps=('NRS-484D-400-2',)),
 L('11.28.060',subj='emergency_vehicle_driver',theme='lamps_and_warnings',overlaps=('NRS-484D-400-5',)),
 L('11.30.020',theme='vulnerable_road_users',overlaps=('NRS-484B-283-1a','NRS-484B-283-1b')),
 L('11.30.030',theme='vulnerable_road_users',overlaps=('NRS-484B-283-1c',)),
 L('11.30.040',subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-293',)),
 L('11.30.050',subj=P,theme='pedestrian_duties'),
 L('11.30.060','A',('C',),subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-287-1a',)),
 L('11.30.060','B',('C',),subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-287-1b',)),
 L('11.30.070','A',subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-287-1c',)),
 L('11.30.070','B',subj=P,theme='pedestrian_duties'),
 L('11.30.080',subj=P,theme='pedestrian_duties'),
 L('11.30.090',subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-297-1',)),
 L('11.30.100',subj=P,theme='pedestrian_duties',overlaps=('NRS-484B-297-2',)),
 L('11.30.130',theme='vulnerable_road_users',overlaps=('NRS-484B-280-1a','NRS-484B-280-1b','NRS-484B-280-1c')),
 L('11.30.140','B',theme='vulnerable_road_users',overlaps=('NRS-484B-290',)),
 L('11.32.040',theme='devices_and_signals',overlaps=('NRS-484B-307-12a','NRS-484B-307-12b')),
 L('11.38.010',subj=M,theme='motorcycles',overlaps=('NRS-486-191-1','NRS-486-181-1')),
 L('11.38.020',subj=M,theme='motorcycles',overlaps=('NRS-486-181-1',)),
 L('11.38.030',subj=M,theme='motorcycles'),
 L('11.38.040',subj=M,theme='motorcycles'),
 L('11.38.050',subj=M,theme='motorcycles',overlaps=('NRS-486-351-1',)),
 L('11.38.120','A',subj=M,theme='motorcycles'),
 L('11.38.120','B',subj=M,theme='motorcycles',overlaps=('NRS-486-251-1',)),
 L('11.38.130',subj=M,theme='motorcycles'),
 L('11.40.070',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-300-1',)),
 L('11.40.080',subj=R,theme='cycles_and_devices'),
 L('11.40.090',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-770-1','NRS-484B-770-2')),
 L('11.40.100',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-777-1',)),
 L('11.40.110',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-777-3',)),
 L('11.40.120',subj=R,theme='cycles_and_devices'),
 L('11.40.130',subj=R,theme='cycles_and_devices'),
 L('11.40.140',subj=R,theme='cycles_and_devices'),
 L('11.40.150',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-773',)),
 L('11.40.160',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-780',)),
 L('11.40.170',subj=R,theme='cycles_and_devices'),
 L('11.40.180','A',subj=R,theme='cycles_and_devices'),
 L('11.40.180','B',subj=R,theme='cycles_and_devices'),
 L('11.40.180','C',subj=R,theme='cycles_and_devices'),
 L('11.40.185','B',subj=R,theme='cycles_and_devices'),
 L('11.40.185','C',subj=R,theme='cycles_and_devices'),
 L('11.40.190',subj=R,theme='cycles_and_devices',overlaps=('NRS-484B-783-1',)),
 L('11.41.020',subj='golf_cart_operator',theme='roadway_position'),
 L('11.42.020',theme='roadway_position',overlaps=('NRS-484B-220-1',)),
 L('11.42.030',theme='lanes'),
 L('11.43.010','A',theme='roundabouts'),
 L('11.43.010','B',theme='roundabouts'),
 L('11.43.010','C.1',theme='roundabouts'),
 L('11.43.010','C.2',theme='roundabouts'),
 L('11.44.020',theme='stopping_standing_parking',overlaps=('NRS-484B-503',)),
 L('11.44.030',theme='stopping_standing_parking'),
 L('11.44.040',theme='stopping_standing_parking'),
 L('11.44.060',theme='stopping_standing_parking',overlaps=('NRS-484B-507-1',)),
 L('11.44.080',theme='stopping_standing_parking'),
 L('11.46.030',theme='school',overlaps=('NRS-484B-350-1a','NRS-484B-350-1b')),
 L('11.48.030',subj='truck_driver',theme='truck_routes'),
 L('11.48.050',subj='truck_driver',theme='truck_routes'),
 L('11.48.060',subj='truck_driver',theme='truck_routes'),
 L('11.52.030','A',theme='stopping_standing_parking'),
 L('11.52.030','B',theme='stopping_standing_parking'),
 L('11.52.030','E',theme='stopping_standing_parking'),
 L('11.52.040','A',theme='stopping_standing_parking'),
 L('11.52.040','B',theme='stopping_standing_parking',overlaps=('NRS-484B-457-1',)),
 L('11.52.050',theme='stopping_standing_parking',overlaps=('NRS-484B-477-1b',)),
 L('11.52.060',theme='stopping_standing_parking'),
 L('11.52.070',theme='stopping_standing_parking',overlaps=('NRS-484B-460',)),
 L('11.52.110',theme='stopping_standing_parking',overlaps=('NRS-484B-533',)),
 L('11.52.130','A.1',('B',),theme='stopping_standing_parking',overlaps=('NRS-484B-450-1o',)),
 L('11.52.130','A.2',theme='stopping_standing_parking'),
 L('11.52.130','A.3',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1o',)),
 L('11.52.130','A.4',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1d',)),
 L('11.52.130','A.5',theme='stopping_standing_parking'),
 L('11.52.130','A.6',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1a',)),
 L('11.52.130','A.7',('B',),theme='stopping_standing_parking',overlaps=('NRS-484B-450-1b','NRS-484B-450-1n')),
 L('11.52.130','A.8',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1i',)),
 L('11.52.130','A.9',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1j',)),
 L('11.52.130','A.10',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1l',)),
 L('11.52.130','A.11',theme='stopping_standing_parking'),
 L('11.52.130','A.12',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1f',)),
 L('11.52.130','A.13',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1g',)),
 L('11.52.130','A.14',theme='stopping_standing_parking',overlaps=('NRS-484B-270-3',)),
 L('11.52.130','A.15',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1k',)),
 L('11.52.130','A.16',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1m',)),
 L('11.52.136',theme='stopping_standing_parking'),
 L('11.52.180','A',theme='stopping_standing_parking',overlaps=('NRS-484B-477-1a',)),
 L('11.52.180','B',theme='stopping_standing_parking'),
 L('11.52.180','C',theme='stopping_standing_parking'),
 L('11.52.240',theme='stopping_standing_parking',overlaps=('NRS-484B-450-1o',)),
 L('11.52.250',theme='stopping_standing_parking'),
 L('11.52.260',theme='stopping_standing_parking'),
 L('11.52.270',theme='stopping_standing_parking'),
 L('11.52.300',subj='any_person',theme='stopping_standing_parking'),
 L('11.52.305','A',('B',),subj='commercial_or_rv_operator',theme='stopping_standing_parking'),
 L('11.52.340',theme='stopping_standing_parking'),
 L('11.60.020',theme='stopping_standing_parking',overlaps=('NRS-484B-517',)),
 L('11.60.030','A.1',subj='bus_operator',theme='stopping_standing_parking',overlaps=('NRS-484B-513',)),
 L('11.60.030','A.2',subj='bus_operator',theme='stopping_standing_parking',overlaps=('NRS-484B-513',)),
 L('11.60.030','A.4',subj='bus_operator',theme='stopping_standing_parking'),
 L('11.60.030','A.5',subj='bus_operator',theme='stopping_standing_parking'),
 L('11.60.030','B.1',('B.2',),subj='tour_bus_operator',theme='stopping_standing_parking'),
 L('11.60.040',subj='taxicab_operator',theme='stopping_standing_parking',overlaps=('NRS-484B-513',)),
 L('11.60.080',theme='stopping_standing_parking',overlaps=('NRS-484B-517',)),
 L('11.60.090',subj='taxicab_operator',theme='turns_and_signals'),
 L('11.68.030',theme='roadway_position'),
]

if __name__ == '__main__':
    out = []; seen = set()
    from references import REFS, APP_MORE, XAPP, DEFS, UNRESOLVED
    for src, ch, sec, path, app, subj, theme, pre, overlaps in SPEC:
        i0 = lid(src, ch, sec, path)
        app = tuple(app) + tuple(APP_MORE.get(i0, ()))
        try:
            title, text, srcs = build(src, ch, sec, path, app, pre, XAPP.get(i0, ()))
        except StopIteration:
            print('MISSING PATH', src, ch, sec, path, app, pre); continue
        i = lid(src, ch, sec, path)
        assert i not in seen, i
        seen.add(i)
        short = title.split(';')[0].split(':')[0].strip()
        rec = {'id': i, 'title': short + (f" {path_label(path)}" if path else ''), 'text': text,
               'source': srcs, 'subject': subj, 'theme': theme}
        if overlaps: rec['overlaps'] = list(overlaps)
        out.append(rec)
    ids = {o['id'] for o in out}
    for o in out:
        for ov in o.get('overlaps', []):
            assert ov in ids, ('dangling overlap', o['id'], ov)
    # ---- resolve overlaps: keep the narrower text, drop the other (overlaps.py) ----
    from overlaps import DROP, PARTIAL, CRITERION
    for d, (kept, _) in DROP.items():
        assert d in ids, ('drop of unknown id', d)
        for k in kept: assert k in ids and k not in DROP, ('kept id missing or itself dropped', d, k)
    for pid, (others, _) in PARTIAL.items():
        assert pid in ids and pid not in DROP
        for o in others: assert o in ids and o not in DROP, ('partial partner dropped', pid, o)
    tagged = {o['id'] for o in out if 'overlaps' in o}
    unresolved = tagged - set(DROP) - set(PARTIAL) - {k for kept, _ in DROP.values() for k in kept}
    assert not unresolved, ('overlap-tagged lines without a decision', sorted(unresolved))
    supersedes = {}
    for d, (kept, _) in DROP.items():
        for k in kept: supersedes.setdefault(k, []).append(d)
    kept_rows = []
    for o in out:
        if o['id'] in DROP: continue
        o.pop('overlaps', None)
        if o['id'] in supersedes: o['supersedes'] = sorted(supersedes[o['id']])
        kept_rows.append(o)
    out = kept_rows
    # ---- reference annotation: every internal reference gets the id(s) it resolves to ----
    kept_ids = [o['id'] for o in out]
    def expand(ids):
        res = []
        for x in ids:
            if x.endswith('-') and not x.startswith('DEF'):
                res += [k for k in kept_ids if k.startswith(x)]
            else:
                res.append(x)
        return res
    def_ids = {d[0] for d in DEFS}
    def annotate(o):
        """The line's references resolved in place (REFS) and its unresolvable ones marked (UNRESOLVED)."""
        rs = REFS.get(o['id'])
        if rs:
            allrefs = []
            for sub, ids in rs:
                ids = expand(ids)
                for x in ids:
                    assert x in kept_ids or x in def_ids or ' ' in x, ('ref to unknown id', o['id'], x)
                assert sub in o['text'], ('ref substring not found', o['id'], sub)
                o['text'] = o['text'].replace(sub, sub + ' [' + ', '.join(ids) + ']', 1)
                allrefs += [x for x in ids if ' ' not in x]
            seen = set(); o['refs'] = [x for x in allrefs if not (x in seen or seen.add(x))]
        u = UNRESOLVED.get(o['id'])
        if u:
            for e in u: assert e['phrase'] in o['text'], ('unresolved phrase not found', o['id'], e['phrase'][:50])
            o['unresolved'] = u
    for o in out:
        annotate(o)
    # ---- definitions.jsonl: every term definition of the definition chapters, then the cited provisions ----
    corpus_text = ' '.join(o['text'] for o in out).lower()
    def term_definitions():
        recs = []
        # NRS 484A.015-.320 (chapter-wide), 484B.003-.077 (rules of the road), 484B.637(1) (low-speed
        # vehicle, defined inside a rule section), 486.011-.057 (motorcycles); NOT 484B.800-.827,
        # which define terms for the traffic-stop data chapter and no rule of the road.
        ranges = {'484A': (15, 320), '484B': (3, 77), '486': (11, 57)}
        for ch, (lo, hi) in ranges.items():
            for sec, e in sorted(NRS[ch].items()):
                n = int(re.sub(r'\D', '', sec))
                m = re.match(r'^\s*[\u201c"]([^\u201d"]+)[\u201d"]\s+(?:and\s+[\u201c"]([^\u201d"]+)[\u201d"]\s+)?defined', e['title'])
                if not (lo <= n <= hi and m): continue
                terms = [t.strip() for t in m.groups() if t]
                title, tree, get = section('NRS', ch, sec)
                recs.append((f"DEF-NRS-{ch}-{sec}", 'NRS', terms, f"NRS {ch}.{sec}", clean(flatten(tree))))
        # the term definitions of other chapters a corpus text incorporates by citation
        for ch, sec in INCORPORATED:
            e = NRS[ch][sec]
            m = re.match(r'^\s*[\u201c"]([^\u201d"]+)[\u201d"]\s+(?:and\s+[\u201c"]([^\u201d"]+)[\u201d"]\s+)?defined', e['title'])
            assert m, ('an incorporated section is no term definition', ch, sec, e['title'])
            title, tree, get = section('NRS', ch, sec)
            recs.append((f"DEF-NRS-{ch}-{sec}", 'NRS', [t.strip() for t in m.groups() if t], f"NRS {ch}.{sec}", clean(flatten(tree))))
        title, tree, get = section('NRS', '484B', '637')
        recs.append(("DEF-NRS-484B-637-1", 'NRS', ['Low-speed vehicle', 'Neighborhood occupantless vehicle'], "NRS 484B.637(1), (4)",
                     clean(flatten(get(tree, '1')) + ' ' + flatten(get(tree, '4')))))
        for sec, e in sorted(LVMC.items()):
            if sec.startswith('11.02.') and sec not in ('11.02.010', '11.02.020'):
                title, tree, get = section('LVMC', None, sec)
                recs.append((f"DEF-LVMC-{sec.replace('.', '-')}", 'LVMC', [title.split('\u2014')[0].strip()], f"LVMC {sec}", clean(flatten(tree))))
        return recs
    term_recs = term_definitions()
    definition_ids = {r[0] for r in term_recs} | {d[0] for d in DEFS}
    def mark(o):                                       # a law's cited term definitions, marked like its cited provisions
        marked = mark_incorporations(o['text'], definition_ids)
        if marked != o['text']:
            o['text'] = marked
            o['refs'] = list(o.get('refs', [])) + [x for x in re.findall(r'\[(DEF-NRS-[\w-]+)\]', marked) if x not in o.get('refs', [])]
    for o in out:
        mark(o)
    # ---- OVERLAPS.md: the record of every decision ----
    by_kept = {}
    for d, (kept, why) in DROP.items():
        by_kept.setdefault(tuple(kept), []).append((d, why))
    lines = ["# Overlapping obligations — which text was kept, and why", "",
             "Generated by `pipeline/ontology_provenance/nrs_tools/make_laws.py` from `overlaps.py`; edit that",
             "file, not this one. The corpus carries the kept line with a `supersedes` field naming the",
             "dropped ids; the dropped lines are not in `laws.jsonl`.", "", "## Criterion", "", CRITERION, "",
             f"## Decisions ({len(DROP)} lines dropped, {len(set(k for kept,_ in DROP.values() for k in kept))} lines kept as the narrower text)", "",
             "| kept | dropped | why the kept text is the narrower definition |", "|---|---|---|"]
    def label(i):
        return i.replace('NRS-','NRS ').replace('LVMC-','LVMC ')
    for kept, items in sorted(by_kept.items(), key=lambda kv: kv[0]):
        for d, why in items:
            lines.append(f"| {', '.join('`'+k+'`' for k in kept)} | `{d}` | {why} |")
    lines += ["", f"## Partial overlaps — both texts kept ({len(PARTIAL)})", "",
              "| line | flagged against | why both stay |", "|---|---|---|"]
    for pid, (others, why) in PARTIAL.items():
        lines.append(f"| `{pid}` | {', '.join('`'+o+'`' for o in others)} | {why} |")
    lines += ["", "## Tally", "",
              f"- dropped municipal lines: {sum(1 for d in DROP if d.startswith('LVMC'))}",
              f"- dropped statutory lines: {sum(1 for d in DROP if d.startswith('NRS'))}",
              f"- lines in the corpus after resolution: {len(out)}", ""]
    open(AUDIT_DIR / 'OVERLAPS.md', 'w', encoding='utf-8').write('\n'.join(lines))
    # ---- classification into the four views (tiers.py) ----
    from tiers import tier, bucket, EXCLUDED, BLOCKING, UNOBSERVABLE, SCOPE_EDITS
    for k in list(EXCLUDED) + list(BLOCKING) + list(UNOBSERVABLE):
        assert k in kept_ids, ('tiers.py names a line not in the corpus', k)
    for o in out:
        o['tier'] = tier(o); o['bucket'] = bucket(o)
        if o['id'] in EXCLUDED: o['excluded_reason'] = EXCLUDED[o['id']]
        if o['id'] in UNOBSERVABLE: o['unobservable_reason'] = UNOBSERVABLE[o['id']]
        # 2026-09-20: every line that carries an unresolved reference is unresolvable (user decision);
        # `blocking` states the reason, from BLOCKING where the mark is the trigger itself, else the kinds
        if o['bucket'] not in ('excluded', 'unobservable') and o.get('unresolved'):
            o['bucket'] = 'unresolvable'
            o['blocking'] = BLOCKING.get(o['id']) or ('carries an unresolved reference: ' + ', '.join(sorted({e['kind'] for e in o['unresolved']})))
        elif o['id'] in BLOCKING:
            o['bucket'] = 'unresolvable'; o['blocking'] = BLOCKING[o['id']]
    # 2026-09-20: when the narrower text kept in the overlap resolution turns out to be unresolvable,
    # the broader statutory text it superseded is reinstated if it is itself resolvable
    by_id = {o['id']: o for o in out}
    dropped_rows = {}
    for src, ch, sec, path, app, subj, theme, pre, overlaps in SPEC:
        i0 = lid(src, ch, sec, path)
        if i0 in DROP and i0 not in by_id:
            try:
                title, text, srcs = build(src, ch, sec, path, tuple(app) + tuple(APP_MORE.get(i0, ())), pre, XAPP.get(i0, ()))
            except StopIteration:
                continue
            short = title.split(';')[0].split(':')[0].strip()
            dropped_rows[i0] = {'id': i0, 'title': short + (f" {path_label(path)}" if path else ''), 'text': text,
                                'source': srcs, 'subject': subj, 'theme': theme}
    reinstated = []
    for o in list(out):
        if o['bucket'] == 'unresolvable' and o.get('supersedes'):
            for d in o['supersedes']:
                if d in dropped_rows and d not in UNRESOLVED and d not in EXCLUDED and d not in by_id:
                    r = dropped_rows[d]
                    annotate(r); mark(r)
                    r['tier'] = tier(r); r['bucket'] = 'judgement' if r['tier'] in ('S', 'Q') else 'concrete'
                    r['reinstated_for'] = o['id']
                    out.append(r); by_id[d] = r; reinstated.append((d, o['id']))
    if reinstated:
        print('reinstated (survivor unresolvable):', reinstated)
    for k in list(REFS) + list(UNRESOLVED) + list(APP_MORE) + list(XAPP):
        assert k in by_id, ('reference table names a line not in the corpus', k)
    # ---- definitions.jsonl, written once the set of lines is final: a provision's `used_by` names
    # every line that cites it, reinstated lines included ----
    with open(CORPUS_DIR / 'definitions.jsonl', 'w', encoding='utf-8') as f:
        for did, applies, terms, label, text in term_recs:
            text = mark_incorporations(text, definition_ids)
            hit = [t for t in terms if re.search(r'\b' + re.escape(t.lower()) + r'(?:s|es)?\b', corpus_text)]
            f.write(json.dumps({'id': did, 'kind': 'term', 'applies_to': applies, 'terms': terms,
                                'title': ' / '.join(terms) + ' defined', 'text': text, 'source': label,
                                'term_in_corpus': bool(hit)}, ensure_ascii=False) + '\n')
        for did, dsrc, dch, dsec, dpaths, note in DEFS:
            title, tree, get = section(dsrc, dch, dsec)
            parts = []
            for p in dpaths:
                node = get(tree, p)
                lead = [tree['text']] if (p and tree['text'].rstrip().endswith(':')) else []
                parts.append(trim(' '.join(lead + [flatten(node)])))
            label = f"NRS {dch}.{dsec}" if dsrc == 'NRS' else f"LVMC {dsec}"
            used = sorted(o['id'] for o in out if did in o.get('refs', []))
            f.write(json.dumps({'id': did, 'kind': 'provision', 'applies_to': dsrc, 'title': title, 'text': clean(' '.join(parts)),
                                'source': label + ', '.join(path_label(p) for p in dpaths) if any(dpaths) else label,
                                'note': note, 'used_by': used}, ensure_ascii=False) + '\n')
    # ---- every term a corpus text takes from a cited section is itself a definition of the corpus ----
    defs_written = [json.loads(l) for l in open(CORPUS_DIR / 'definitions.jsonl', encoding='utf-8')]
    missing = missing_incorporations(defs_written + out, {d['id'] for d in defs_written})
    assert not missing, ('a text takes a term from a section that is no definition of the corpus: '
                         'add it to INCORPORATED in references.py', missing)
    # scope edits (tiers.SCOPE_EDITS), applied to the final set of lines, reinstated ones included
    for k in SCOPE_EDITS:
        assert k in by_id, ('tiers.py SCOPE_EDITS names a line not in the corpus', k)
        words, why = SCOPE_EDITS[k]
        assert by_id[k]['text'].count(words) == 1, ('scope edit does not match exactly once', k, words)
        by_id[k]['text'] = by_id[k]['text'].replace(words, '', 1)
        by_id[k]['scope_edit'] = {'removed': words.strip(), 'reason': why}
    views = {'excluded': [], 'unobservable': [], 'unresolvable': [], 'judgement': [], 'concrete': []}
    for o in out: views[o['bucket']].append(o)
    for name in ('excluded', 'unobservable', 'unresolvable'):
        with open(CORPUS_DIR / f'{name}.jsonl', 'w', encoding='utf-8') as f:
            for o in views[name]: f.write(json.dumps(o, ensure_ascii=False) + '\n')
    # the pipeline corpus = concrete + judgement; a reference into a removed line becomes an
    # unresolved mark of kind 'removed_target' (the bracketed id stays in the text as the record)
    removed = {o['id']: o['bucket'] for o in out if o['bucket'] in ('excluded', 'unobservable', 'unresolvable')}
    corpus = [o for o in out if o['bucket'] in ('concrete', 'judgement')]
    for o in corpus:
        gone = [r for r in o.get('refs', []) if r in removed]
        if gone:
            o.setdefault('unresolved', [])
            for r in gone:
                o['unresolved'].append({'phrase': f'[{r}]' if f'[{r}]' in o['text'] else r, 'kind': 'removed_target',
                                        'note': f'{r} is in {removed[r]}.jsonl and not in the pipeline corpus; the reference is a residue'})
            o['refs'] = [r for r in o['refs'] if r not in removed]
    with open(CORPUS_DIR / 'laws_full.jsonl', 'w', encoding='utf-8') as f:
        for o in out:
            if o['bucket'] not in ('unresolvable', 'unobservable'): f.write(json.dumps(o, ensure_ascii=False) + '\n')
    with open(CORPUS_DIR / 'laws.jsonl', 'w', encoding='utf-8') as f:
        for o in corpus: f.write(json.dumps(o, ensure_ascii=False) + '\n')
    # ---- dependency audit of the concrete view (§4 of the split request) ----
    where = {o['id']: o['bucket'] for o in out}
    LAWFUL = re.compile(r"lawful(?:ly)? (?:within|riding|parked|placed|passing|turning|rate|displays|pursuant|entitled)|lawful turning", re.I)
    dep_lines = ["# Concrete view — dependency audit", "",
                 "Generated by `make_laws.py`. For every line of `concrete.jsonl` (tier C, no judgement element),",
                 "the ids its references resolve to (`refs`) and the view each target lives in. A target outside",
                 "`concrete.jsonl` means the rule cannot be closed inside this view: it composes a judgement rule,",
                 "an unresolvable one, or one that was excluded. `lawfully …` phrases are references to the other",
                 "road user's rules without an explicit id; they are listed separately.", "",
                 "| concrete line | refs → view | lawfully-phrases |", "|---|---|---|"]
    outside = Counter_ = {}
    from collections import Counter
    tally = Counter(); cross = []
    for o in views['concrete']:
        refs = o.get('refs', [])
        law = sorted(set(m.group(0) for m in LAWFUL.finditer(o['text'])))
        if not refs and not law: continue
        cells = []
        for r in refs:
            v = 'definition' if r.startswith('DEF-') else where.get(r, 'missing')
            tally[v] += 1
            if v not in ('concrete', 'definition'): cross.append((o['id'], r, v))
            cells.append(f"`{r}` → {v}")
        dep_lines.append(f"| `{o['id']}` | {'<br>'.join(cells) or '—'} | {', '.join(law) or '—'} |")
    dep_lines += ["", "## Tally of reference targets from concrete lines", ""] + [f"- {k}: {v}" for k, v in sorted(tally.items())]
    dep_lines += ["", "## Concrete lines that depend on a line outside the concrete view", "", "| concrete line | target | target's view |", "|---|---|---|"]
    dep_lines += [f"| `{a}` | `{b}` | {c} |" for a, b, c in cross]
    open(AUDIT_DIR / 'CONCRETE_DEPENDENCIES.md', 'w', encoding='utf-8').write('\n'.join(dep_lines) + '\n')
    from collections import Counter
    print(len(out), 'lines in laws_full;', len(corpus), 'in the pipeline corpus;', Counter(o['id'].split('-')[0] + ('-' + o['id'].split('-')[1] if o['id'].startswith('NRS') else '') for o in out))
    print(Counter(o['subject'] for o in out))
    print(sum(len(o['text']) for o in out), 'chars')

    # The files written above carry the analysis fields (subject, theme, tier, refs, …). The agent
    # reads posted law only; publish.py moves the analysis into laws/audit_and_scripts/ sidecars.
    import importlib
    importlib.import_module("publish" if __package__ in (None, "") else f"{__package__}.publish").main()
