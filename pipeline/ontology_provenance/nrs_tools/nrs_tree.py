import json, re, sys
NUM = re.compile(r'^(\d+)\.\s+(.*)$')
LET = re.compile(r'^\(([a-z])\)\s*(.*)$')
PAR = re.compile(r'^\((\d+)\)\s*(.*)$')
ROM = re.compile(r'^\(([ivx]+)\)\s*(.*)$')

def parse(text):
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    root = {'label': '', 'text': '', 'subs': []}
    cur = {1: root}; depth_of = {}
    intro = []
    prev = ''
    for l in lines:
        # a wrapped cross-reference ("...provided in paragraph\n(b), vehicular...") is a
        # continuation of the previous line, not a new paragraph
        if re.match(r'^\([a-z0-9]+\)', l) and (prev.rstrip().endswith(('paragraph','paragraphs','subparagraph','subparagraphs')) or re.match(r'^\([a-z0-9]+\)\s*(?:,|of\b|or\b|and\b)', l)):
            node = cur[max(cur)]
            node['text'] = (node['text']+' '+l).strip(); prev = l; continue
        prev = l
        if l.startswith('Ê'):  # flush-left continuation ("Ê any transparent ...")
            node = cur.get(max(cur)); node['tail'] = node.get('tail','') + ' ' + l[1:].strip(); continue
        l = re.sub(r'^\[Effective[^\]]*\]\s*', '', l).strip()
        if not l: continue
        if l.startswith('[') or l.startswith('(Added') or l.startswith('—('): continue
        m = NUM.match(l)
        if m: node={'label':m.group(1),'text':m.group(2),'subs':[]}; root['subs'].append(node); cur={1:root,2:node}; continue
        m = LET.match(l)
        if m and 2 in cur: node={'label':m.group(1),'text':m.group(2),'subs':[]}; cur[2]['subs'].append(node); cur={k:v for k,v in cur.items() if k<=2}; cur[3]=node; continue
        m = PAR.match(l)
        if m and 3 in cur: node={'label':m.group(1),'text':m.group(2),'subs':[]}; cur[3]['subs'].append(node); cur={k:v for k,v in cur.items() if k<=3}; cur[4]=node; continue
        m = ROM.match(l)
        if m and 4 in cur: node={'label':m.group(1),'text':m.group(2),'subs':[]}; cur[4]['subs'].append(node); cur[5]=node; continue
        # continuation
        node = cur[max(cur)]
        if node is root: root['text'] = (root['text']+' '+l).strip()
        else: node['text'] = (node['text']+' '+l).strip()
    return root

def load(ch):
    return json.load(open(f'{ch}.json'))

def show(node, ind=0, out=None):
    pre = '  '*ind
    lab = node['label']
    t = node['text'] + (' Ê' + node['tail'] if node.get('tail') else '')
    print(f"{pre}[{lab}] {t}")
    for s in node['subs']: show(s, ind+1)

def get(tree, path):
    """path like '1' or '1.a' or '1.a.2' ; '' = section intro"""
    node = tree
    if path:
        for p in path.split('.'):
            node = next(s for s in node['subs'] if s['label']==p)
    return node

if __name__ == '__main__':
    ch = sys.argv[1]; d = load(ch)
    for sec in sys.argv[2:]:
        e = d[sec]; print(f"\n=== NRS {ch}.{sec} {e['title']}")
        show(parse(e['text']))
