"""The operator's list of the run's observable readings and of the identity-class carriers that may
stand in for a conduct or a status. A report: it files no gap, returns no record, holds no law and
grants nothing; the validator alone refuses a reading carried by identity classes only.

It lists, over the latest record of each node of the run (its iterations' plans and repairs, then
its accepted nodes):
(a) every observable reading, with its span's words and the ids that carry the span;
(b) every observable reading whose span is carried by identity classes together with ids of another
    family: a static check cannot tell whether the other ids are the conduct the words refer to;
(c) every record that declares no observable reading and carries, by identity classes only, a span
    whose words name a duty, a role or a status (`DUTY_WORDINGS`);
(d) every observable reading whose span decides when the rule applies (a trigger, subject, condition
    or exception span, `SCOPE_ROLES`), grouped by that role, with the span's words, the reading's
    category, the ids that carry the span, the reading's stated `why` and where the record was read.
    Whether the words belong to the category the reading claims is for the operator to check; the
    part lists, it judges no reading;
(e) every gap the run filed (`gaps_measured.jsonl`), grouped by the name of the atom or operator it
    proposes, so that one requirement filed on several laws reads as one family;
(f) every phrase a gap or a narrowing is on that the spans of two or more records carry in more than
    one way (a gap, a narrowing, a residue, a composition, or atoms alone), with each record's span
    and its way: the same words read differently across the run, for the operator to compare.
    Neither part decides which way is right;
(g) every declared fact (`fact.*`) a record of the run declares, with its catalogue terms and the laws
    and nodes whose records read it: what a data source must supply, and where its absence leaves a
    verdict unknown."""
from __future__ import annotations
import json
import re
from pathlib import Path

from ..checks.validate_a import OBSERVABLE_READING, OBSERVABLE_THROUGH, SCOPE_ROLES, identity_and_more, identity_only, span_carriers
from ..model.blueprint import Node
from ..store import jsonl

#: The operator's file, beside `TO_USER.md`.
VIEW_NAME = "OBSERVABLE_READINGS.md"

#: Words that, said of a road user, name a duty, a role or a status no identity class shows, matched
#: case-insensitively as substrings of a span's words. A report heuristic for part (c): it names no
#: law, decides nothing and refuses nothing; a span it misses is simply not listed.
DUTY_WORDINGS = ("official duties", "official duty", "performance of official", "in the course of his or her duties",
                 "course of his or her official", "on duty", "authorized emergency vehicle", "responding to an emergency",
                 "law enforcement", "peace officer", "police officer", "security guard")


def view_file(run) -> Path:
    return run.dir / VIEW_NAME


def duty_words(text: str) -> list[str]:
    t = (text or "").lower()
    return [w for w in DUTY_WORDINGS if w in t]


def _rows(path: Path) -> list[dict]:
    """The rows of a record file a session wrote; a line that is no JSON object is skipped, since a
    report reads what is there and decides nothing."""
    out = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return out
    for line in lines:
        try:
            row = json.loads(line)
        except ValueError:
            continue
        if isinstance(row, dict) and isinstance(row.get("node_id"), str):
            out.append(row)
    return out


def source_kind(src: str) -> str:
    """Which record a source path names: an iteration's plan, a repair session's record, or the
    accepted nodes."""
    return "accepted" if src == "accepted_nodes.jsonl" else "repair" if "/repair/" in src else "plan"


def run_records(run_dir: Path, accepted: dict[str, dict]) -> dict[str, tuple[str, dict]]:
    """node id ↦ (where the record was read, the record): the latest record of each node over the
    run's iterations in order (each iteration's plan, then its repairs), and each accepted node no
    iteration file holds."""
    out: dict[str, tuple[str, dict]] = {}
    iters = sorted((p for p in run_dir.glob("iter-*") if p.is_dir() and re.fullmatch(r"iter-\d+", p.name)), key=lambda p: int(p.name[5:]))
    for it in iters:
        files = [it / "plan" / "blueprint.jsonl"] + sorted(it.glob("repair/*/record.jsonl"))
        for f in files:
            for row in _rows(f):
                out[row["node_id"]] = (f.relative_to(run_dir).as_posix(), row)
    for nid, row in accepted.items():
        out.setdefault(nid, ("accepted_nodes.jsonl", row))
    return out


def entries(records: dict[str, tuple[str, dict]]) -> dict[str, list[dict] | dict[str, list[dict]]]:
    """The four parts of the report over `records` (node id ↦ (source, record)), each entry a dict
    with the node, its source, the span, its words, its category (parts a, b, d) or matched wordings
    (part c), and the ids that carry the span; part d is keyed by scope role, and its entries add the
    role, the reading's `why` and the kind of source. A span's role is read from the record's
    segmentation as the validator reads it."""
    a, b, c = [], [], []
    d: dict[str, list[dict]] = {r: [] for r in sorted(SCOPE_ROLES)}
    for nid, (src, rec) in sorted(records.items()):
        node = Node(rec)
        try:
            spans = node.spans()
        except (KeyError, TypeError, AttributeError):
            continue
        obs = [n for n in rec.get("narrowings") or [] if isinstance(n, dict) and n.get("kind") == OBSERVABLE_READING]
        for n in obs:
            sid = n.get("span")
            ids = span_carriers(node, sid)
            e = {"node": nid, "source": src, "span": sid, "words": (spans.get(sid) or {}).get("text", ""),
                 "category": n.get("category"), "carriers": ids, "identity_only": identity_only(ids),
                 "refused": n.get("category") in OBSERVABLE_THROUGH and identity_only(ids)}
            a.append(e)
            if identity_and_more(ids):
                b.append(e)
            role = (spans.get(sid) or {}).get("role")
            if role in SCOPE_ROLES:
                d[role].append({**e, "role": role, "why": " ".join(str(n.get("why") or "").split()), "source_kind": source_kind(src)})
        if obs:
            continue
        for sid, s in spans.items():
            hits = duty_words(s.get("text", "") if isinstance(s, dict) else "")
            ids = span_carriers(node, sid)
            if hits and identity_only(ids):
                c.append({"node": nid, "source": src, "span": sid, "words": s.get("text", ""), "wordings": hits, "carriers": ids})
    return {"a": a, "b": b, "c": c, "d": d}


def _line(e: dict) -> str:
    what = f"`{e['category']}`" if "category" in e else "matches " + ", ".join(f"\"{w}\"" for w in e["wordings"])
    flag = (" — carried by identity classes only: the validator returns this record" if e.get("refused")
            else " — carried by identity classes only" if e.get("identity_only") else "")
    return (f"- `{e['node']}` span {e['span']} \"{e['words']}\" · {what} · carried by "
            f"{', '.join(f'`{i}`' for i in e['carriers']) or 'nothing'} · from `{e['source']}`{flag}")


def _scope_line(e: dict) -> str:
    return (f"- `{e['node']}` span {e['span']} ({e['role']}) \"{' '.join(str(e['words']).split())}\" · `{e['category']}` · carried by "
            f"{', '.join(f'`{i}`' for i in e['carriers']) or 'nothing'} · why: \"{e['why']}\" · from `{e['source']}` ({e['source_kind']})")


def render(parts: dict[str, list[dict]], iteration: int) -> str:
    out = [f"# Observable readings and identity-class carriers (as of iteration {iteration})", "",
           "Rebuilt in full from the latest record of each node of the run each time it is written. A report: nothing here "
           "files a gap, returns a record, holds a law or grants a change.", "",
           "## (a) Every observable reading, with the ids that carry its span", ""]
    out += [_line(e) for e in parts["a"]] or ["(none)"]
    out += ["", "## (b) Readings whose span identity classes carry together with ids of another family "
                "(whether those ids are the conduct or the feature the words refer to is for the operator to check)", ""]
    out += [_line(e) for e in parts["b"]] or ["(none)"]
    out += ["", "## (c) Records with no observable reading whose span names a duty, a role or a status and is carried "
                "by identity classes only", ""]
    out += [_line(e) for e in parts["c"]] or ["(none)"]
    out += ["", "## (d) Observable readings on a span that decides when the rule applies, by its role "
                "(whether the words belong to the category claimed is for the operator to check; nothing here judges a reading)"]
    for role, es in parts.get("d", {}).items():
        out += ["", f"### {role}", ""]
        out += [_scope_line(e) for e in es] or ["(none)"]
    return "\n".join(out) + "\n"


def proposed_name(proposal: str) -> str:
    """The atom or operator a gap proposes, as its proposal names it: the identifier the proposal
    opens with (written as a name: a dotted id, a signature, or with backquotes), else the first
    identifier in backquotes, else the first dotted id of the ontology's form; a namespace in front
    of an operator (`Formula.`, `Term.`) is not part of its name. Empty when the proposal names none."""
    text = str(proposal or "").strip()
    lead = re.match(r"^`?([A-Za-z_][\w.]*)`?\s*(?:\(|\||:|$)", text) or re.match(r"^`([A-Za-z_][\w.]*)", text)
    name = (lead.group(1) if lead else None) or next(iter(re.findall(r"`([A-Za-z_][\w.]*)", text)), None) \
        or next(iter(re.findall(r"\b[a-z]+\.[a-z_]\w*", text)), "")
    return re.sub(r"^[A-Z]\w*\.", "", name)


def gap_families(gaps: list[dict]) -> dict[str, list[dict]]:
    """The run's gaps by the name they propose (`proposed_name`), those that name none under ""."""
    out: dict[str, list[dict]] = {}
    for g in gaps:
        if isinstance(g, dict) and g.get("id"):
            out.setdefault(proposed_name(g.get("proposal", "")), []).append(g)
    return dict(sorted(out.items(), key=lambda kv: (kv[0] == "", kv[0])))


def phrase(text: str) -> str:
    """Words as a phrase is compared: bracketed citations dropped, lower case, single spaces, no
    punctuation at either end and no list connector in front."""
    t = " ".join(re.sub(r"\[[^\]]*\]", " ", str(text or "")).lower().split())
    return re.sub(r"^(?:or|and|but|nor)\s+", "", re.sub(r"^[\W_]+|[\W_]+$", "", t))


def way(rec: dict, sid) -> str:
    """How a record carries one of its spans: a gap, a narrowing, a residue, a composition (any
    that apply, joined), or its atoms alone."""
    on = lambda key: any(isinstance(x, dict) and x.get("span") == sid for x in rec.get(key) or [])
    return "+".join(k for k, key in (("gap", "gaps"), ("narrowing", "narrowings"), ("residue", "residues"), ("composition", "compositions"))
                    if on(key)) or "atoms"


def shared_phrases(records: dict[str, tuple[str, dict]], gaps: list[dict]) -> list[dict]:
    """Part (f): each phrase a gap of the run or a narrowing of a record is on, with every record
    whose span (other than a `sibling` span) contains it, kept where two or more records carry it in
    two or more ways; each holder is (node, span, role, way, the gap ids the run filed on that span)."""
    filed: dict[str, list[tuple[str, str]]] = {}
    for g in gaps:
        if isinstance(g, dict) and g.get("node_id"):
            filed.setdefault(g["node_id"], []).append((phrase(g.get("span", "")), g.get("id", "")))
    phrases = {phrase(g.get("span", "")) for g in gaps if isinstance(g, dict)}
    for _nid, (_src, rec) in records.items():
        spans = {s.get("id"): s for s in rec.get("segmentation") or [] if isinstance(s, dict)}
        phrases |= {phrase((spans.get(n.get("span")) or {}).get("text", "")) for n in rec.get("narrowings") or [] if isinstance(n, dict)}
    out = []
    for ph in sorted(p for p in phrases if p):
        pat = re.compile(r"(?<!\w)" + re.escape(ph) + r"(?!\w)")
        holders = []
        for nid, (_src, rec) in sorted(records.items()):
            for s in rec.get("segmentation") or []:
                if isinstance(s, dict) and s.get("role") != "sibling" and pat.search(words := phrase(s.get("text", ""))):
                    ids = [i for w, i in filed.get(nid, []) if w and w in words]
                    holders.append({"node": nid, "span": s.get("id"), "role": s.get("role"), "way": way(rec, s.get("id")), "gaps": ids})
        if len({h["node"] for h in holders}) >= 2 and len({h["way"] for h in holders}) >= 2:
            out.append({"phrase": ph, "holders": holders})
    return out


def render_gap_parts(families: dict[str, list[dict]], shared: list[dict]) -> str:
    out = ["", "Parts (e) and (f) are leads for the operator's review, a grouping only, not established defects: nothing in them "
                "merges a gap or judges a reading.", "", "## (e) The run's gaps by the atom or operator they propose", ""]
    for name, gs in families.items():
        laws = sorted({l for g in gs for l in g.get("law_refs") or []})
        out.append(f"- {'`' + name + '`' if name else '(no name proposed)'}: " + ", ".join(f"{g['id']} ({g.get('kind')})" for g in gs)
                   + f" · laws {', '.join(f'`{l}`' for l in laws) or 'none'}")
    if not families:
        out.append("(none)")
    out += ["", "## (f) Phrases a gap or a narrowing is on that the run's records carry in more than one way", ""]
    for e in shared:
        out.append(f"- \"{e['phrase']}\"")
        by_way: dict[str, list[dict]] = {}
        for h in e["holders"]:
            by_way.setdefault(h["way"], []).append(h)
        for w, hs in sorted(by_way.items()):
            out.append(f"  - {w}: " + ", ".join(f"`{h['node']}` {h['span']} ({h['role']}{'; ' + ', '.join(h['gaps']) if h['gaps'] else ''})" for h in hs))
    if not shared:
        out.append("(none)")
    return "\n".join(out) + "\n"


def declared_facts(records: dict[str, tuple[str, dict]], catalogue: dict[str, dict]) -> dict[str, dict]:
    """Part (g): each `fact.*` id the records declare ↦ its catalogue entry (`catalogue`: the run
    reading's declarations by id, else the first record's own terms) and the nodes and laws that read it."""
    out: dict[str, dict] = {}
    for nid, (_src, rec) in sorted(records.items()):
        for d in rec.get("facts") or []:
            if isinstance(d, dict) and str(d.get("id") or "").startswith("fact."):
                e = out.setdefault(d["id"], {"entry": catalogue.get(d["id"]) or d, "nodes": set(), "laws": set()})
                e["nodes"].add(nid)
                e["laws"] |= set(rec.get("law_refs") or [])
    return out


def render_declared_facts(facts: dict[str, dict]) -> str:
    out = ["", "## (g) Declared facts the run's records read, with the laws that read them (what a data source must supply)", ""]
    for fid, e in sorted(facts.items()):
        d = e["entry"]
        ws = lambda x: " ".join(str(x or "").split())
        out.append(f"- `{fid}` ({ws(d.get('kind')) or '?'}, {ws(d.get('subjects')) or '?'}): {ws(d.get('meaning'))}"
                   + (" — proposed, unreviewed" if d.get("proposed") else ""))
        out.append(f"  - true when: {ws(d.get('true_when'))}; false when: {ws(d.get('false_when'))}")
        out.append(f"  - laws {', '.join(f'`{l}`' for l in sorted(e['laws']))} · nodes {', '.join(f'`{n}`' for n in sorted(e['nodes']))}")
    if not facts:
        out.append("(none)")
    return "\n".join(out) + "\n"


def current_view(run) -> str:
    from ..model.reading import Reading
    records = run_records(run.dir, dict(run.accepted_nodes))
    gaps = jsonl.read_strict(run.dir / "gaps_measured.jsonl")
    reading = getattr(run, "reading_file", None)                # a run without a reading reports each fact by its records' terms
    catalogue = Reading(Path(reading)).declarations() if reading else {}
    return (render(entries(records), run.iteration) + render_gap_parts(gap_families(gaps), shared_phrases(records, gaps))
            + render_declared_facts(declared_facts(records, catalogue)))


def write_current_view(run) -> None:
    """Write the view over the previous one. A view that cannot be computed says why and stops
    nothing: it is a report."""
    try:
        text = current_view(run)
    except Exception as e:                                       # a report never stops the run
        text = f"# Observable readings and identity-class carriers\n\nThe view cannot be rebuilt: {type(e).__name__}: {str(e)[:300]}\n"
    jsonl.write_atomic(view_file(run), text)
