"""Write sources/<chapter>.json for the sections INCORPORATED names, from saved official chapter pages.

The pages are the Nevada Legislature's chapter pages (NRS-<chapter>.html) saved with a record of where
and when each was captured (SOURCES.json beside them). Each section keeps its catchline as `title` and
its paragraphs, then its source note, as `text`, one per line, in the form nrs_tree.parse reads.

    python incorporated_sources.py <directory of the saved pages>
"""
import hashlib, html, json, re, sys
from pathlib import Path

from references import INCORPORATED

HERE = Path(__file__).resolve().parent
_PARA = re.compile(r'<p class="?(SectBody|SourceNote)"?>(.*?)</p>', re.S)


def _plain(fragment):
    text = html.unescape(re.sub(r'<[^>]+>', '', fragment)).replace(' ', ' ').replace('\xa0', ' ')
    return ' '.join(text.split())


def section(page, ch, sec):
    """(title, text) of NRS <ch>.<sec> on a chapter page."""
    anchor = re.search(rf'<a name="?NRS{re.escape(ch)}Sec{re.escape(sec)}"?></a>', page)
    assert anchor, ('section not on the page', ch, sec)
    start = page.rfind('<p class="SectBody">', 0, anchor.start())
    lines, title = [], None
    for m in _PARA.finditer(page, start):
        kind, body = m.groups()
        if kind == 'SectBody' and lines and re.search(r'<a name="?NRS\w+Sec', body):
            break                                              # the next section begins
        text = _plain(body)
        if title is None:
            head = re.match(rf'^NRS {re.escape(ch)}\.{re.escape(sec)} (.*?defined\.)(?: (.*))?$', text)
            assert head, ('no catchline', ch, sec, text[:120])
            title, text = head.group(1), head.group(2)
            if not text:                                       # the catchline stands alone; the text follows
                continue
        num = re.match(r'^(\d+)\. (.*)$', text)
        lines.append(f"{num.group(1)}.  {num.group(2)}" if num else text)
        if kind == 'SourceNote':
            break
    assert lines and lines[-1].startswith('('), ('no source note', ch, sec)
    return title, '\n'.join(lines)


def main(saved):
    saved = Path(saved)
    record = {r['file']: r for r in json.loads((saved / 'SOURCES.json').read_text(encoding='utf-8'))}
    by_chapter = {}
    for ch, sec in INCORPORATED:
        by_chapter.setdefault(ch, []).append(sec)
    provenance = []
    for ch, secs in sorted(by_chapter.items()):
        name = f'NRS-{ch}.html'
        raw = (saved / name).read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        assert digest == record[name]['sha256'], ('the saved page differs from its record', name)
        page = raw.decode('cp1252')
        out = {}
        for sec in secs:
            title, text = section(page, ch, sec)
            out[sec] = {'title': title, 'text': text}
        (HERE / 'sources' / f'{ch}.json').write_text(json.dumps(out, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        provenance.append({**record[name], 'sections': secs})
    (HERE / 'sources' / 'INCORPORATED_SOURCES.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=1) + '\n',
                                                                 encoding='utf-8')


if __name__ == '__main__':
    main(sys.argv[1])
