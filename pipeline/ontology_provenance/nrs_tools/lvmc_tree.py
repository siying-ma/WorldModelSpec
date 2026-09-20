"""Las Vegas Municipal Code (Municode) section text -> subsection tree, same node shape as nrs_tree."""
import json, re, sys
HIST = re.compile(r"^\(?(Ord\.|Ords\.|Prior|prior code|1949 code|code §|§|\d{2,4} §|\d+ \(part\)|\d{4}[:;)]|\d+, \d{4}|\d+-\d+-\d+\)|For (?:other )?provisions|Editor|Cross reference|Note—|Footnotes|---|Ord\. No\.|\d+—|Ord\. \d+ has|\(part\))")
LAB = re.compile(r'^\(([A-Z]|[a-z]|\d+)\)$')
LEVEL = {'U': 1, 'd': 2, 'l': 3}
def kind(lab):
    if lab.isupper(): return 'U'
    if lab.isdigit(): return 'd'
    return 'l'

def parse(text):
    root = {'label': '', 'text': '', 'subs': []}
    stack = [root]            # stack of open nodes by depth
    cur = root
    for raw in text.split('\n'):
        l = raw.strip()
        if not l or HIST.match(l): continue
        if l.startswith('→'):
            # flush-left continuation belongs to the parent of the current item
            parent = stack[-2] if len(stack) > 1 else root
            parent['tail'] = (parent.get('tail', '') + ' ' + l[1:].strip()).strip(); continue
        m = LAB.match(l)
        if m:
            lab = m.group(1); k = kind(lab)
            # find depth: pop while top has same or deeper kind
            depth = {'U': 1, 'd': 2, 'l': 3}[k]
            # LVMC sometimes starts with (1) at top level (no (A)); adapt: depth = position in stack
            while len(stack) > 1 and stack[-1].get('kind') and LEVEL[stack[-1]['kind']] >= depth:
                stack.pop()
            node = {'label': lab, 'text': '', 'subs': [], 'kind': k}
            stack[-1]['subs'].append(node); stack.append(node); cur = node
            continue
        cur['text'] = (cur['text'] + ' ' + l).strip()
    return root

def load():
    return json.load(open('lvmc/lvmc.json'))

def show(node, ind=0):
    t = node['text'] + (' →' + node['tail'] if node.get('tail') else '')
    print(f"{'  '*ind}[{node['label']}] {t}")
    for s in node['subs']: show(s, ind+1)

def get(tree, path):
    node = tree
    if path:
        for p in path.split('.'):
            node = next(s for s in node['subs'] if s['label'] == p)
    return node

if __name__ == '__main__':
    d = load()
    for sec in sys.argv[1:]:
        e = d[sec]; print(f"\n=== LVMC {sec} {e['title']}")
        show(parse(e['text']))
