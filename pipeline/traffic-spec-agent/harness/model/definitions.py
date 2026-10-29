"""Which posted definition applies to the words of a law: a generic resolver over the run's posted
corpus files (`laws.jsonl` and the `definitions.jsonl` beside it) and the operator's declared
definition precedence (`config/definition_precedence.json`). It reads nothing else.

A definition is a clause, not a record: a record of `definitions.jsonl` yields a candidate only
where its text holds a quoted term, or several joined by commas, `or` or `and`, followed (after at
most one comma-set qualifier such as `, when required,`) by a definitional verb of the closed list
`DEFINITIONAL_VERBS`. A record that only regulates something its title names yields none. A
record whose text begins "As used in this section" defines for its own section only. A clause
"has the meaning ascribed to it in <code> <chapter>.<section>" is a cross-reference, followed to
the posted record it cites, transitively, a cycle or a citation of an unposted record leaving the
term unresolved.

A use of a term in a law or in another definition is matched case-insensitively on whole tokens,
the last token in its singular or plural form, the longest term first (`motor vehicle` wins over
the `vehicle` inside it). A term of several words is also used where its head is the subject of
"is" or "are" and its modifiers are the whole predicate, in one clause ("the lanes are paved" uses
`paved lane`); such a use is recorded `split` with its words, and never displaces a contiguous one.
An inline citation `[DEF-…]` is read apart from the words and removed before matching. Once a
law's term resolves, the same precedence is applied from each reached definition's own place to
the defined terms its text uses. This finite dependency graph supplies the posted meanings needed
to interpret nested words; it does not make an unrelated definition elsewhere in the same code
applicable.

For a term a law uses, the first step that finds a candidate decides:
- `inline_or_section`: a definition the law cites inline; else a section-only definition of the
  law's own section;
- `own_chapter`: a definition of the law's own chapter of its code;
- `general_chapter`: a definition of its code's general chapter;
- `fallback_code`: a definition of the general chapter of the code its code falls back to.
A section-only definition is never used outside its section; a definition in another chapter of
the same code is never reached. One candidate at the deciding step resolves the term; several
make it ambiguous: each is shown, none may key an aggregate. A term no step finds has no
applicable definition. The configuration names the codes, how many id segments make a chapter,
each code's general chapter and its fallback, and the order of the steps.
"""
from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

from . import corpus

DEFAULT_PRECEDENCE = Path(__file__).resolve().parents[2] / "config" / "definition_precedence.json"
#: The closed list of definitional verbs, as they follow the quoted term(s).
DEFINITIONAL_VERBS = ("means", "includes", "has the meaning ascribed to it in", "has the meaning ascribed to")
_QUOTE = r"[“\"]([^”\"]+?)[,.]?[”\"]"
_CLAUSE = re.compile(_QUOTE + r"((?:\s*,?\s*(?:or|and)?\s*" + _QUOTE + r")*)\s*(?:,?\s*[^,.;:“”\"]{1,40},)?\s+("
                     + "|".join(re.escape(v) for v in DEFINITIONAL_VERBS) + r")\b")
_CITATION = re.compile(r"\b([A-Z]{2,})\s+(\d[\dA-Z]*(?:\.\d[\dA-Z]*)+)")
_INLINE = re.compile(r"\[(DEF-[A-Za-z0-9-]+)\]")
_TOKEN = re.compile(r"[a-z0-9]+(?:[-'][a-z0-9]+)*")
SECTION_ONLY = re.compile(r"^\W*(?:\(\w+\)\s*)?as used in this section\b", re.I)
#: A split use of a defined term stays inside one clause: no punctuation between its words.
_CLAUSE_BREAK = re.compile(r"[.,;:!?()\[\]\n]")
_COPULA = ("is", "are")
_RELATIVE = ("that", "which")
#: A noun after a preposition (and at most one determiner) is not the subject of the copula.
_DETERMINER = frozenset(("the", "a", "an", "each", "every", "any", "both", "either", "such", "this", "that", "these", "those"))
_PREPOSITION = frozenset(("of", "on", "upon", "in", "into", "onto", "at", "to", "from", "with", "without", "by", "for", "beside",
                          "near", "along", "across", "over", "under", "behind", "within", "between", "through", "toward",
                          "towards", "past", "around", "beyond", "off", "than"))
#: The words after which a copular predicate has ended: the modifiers qualify the subject, not a
#: following noun.
_PREDICATE_END = frozenset(("and", "or", "but", "nor", "if", "when", "where", "while", "unless", "until", "then", "so",
                            "as", "at", "in", "on", "within", "from", "to", "for", "by", "with", "except", "before",
                            "after", "because", "than"))


@dataclass
class Place:
    code: str
    chapter: str
    section: str


@dataclass
class Candidate:
    definition: str
    term: str
    verb: str
    section_only: bool
    place: Place
    cites: list[str] = field(default_factory=list)


def load_precedence(path: Path | None = None) -> dict:
    return json.loads(Path(path or DEFAULT_PRECEDENCE).read_text(encoding="utf-8"))


def precedence_digest(path: Path | None = None) -> str:
    return hashlib.sha256(Path(path or DEFAULT_PRECEDENCE).read_bytes()).hexdigest()


def place_of(ident: str, config: dict) -> Place | None:
    """Code, chapter and section of a law or definition id, by the configured id grammar."""
    parts = ident.split("-")
    if parts and parts[0] == "DEF":
        parts = parts[1:]
    code = config["codes"].get(parts[0]) if parts else None
    if code is None:
        return None
    n = int(code.get("chapter_segments", 1))
    if len(parts) < 2 + n:
        return None
    return Place(parts[0], ".".join(parts[1:1 + n]), parts[1 + n])


def tokens(text: str) -> list[str]:
    return [re.sub(r"'s$", "", t) for t in _TOKEN.findall(str(text).lower())]


def _same(term_tok: str, law_tok: str) -> bool:
    if law_tok == term_tok or law_tok in (term_tok + "s", term_tok + "es"):
        return True
    return term_tok.endswith("y") and law_tok == term_tok[:-1] + "ies"


def extract(defs: list[dict], config: dict) -> list[Candidate]:
    """Every definitional clause of the posted definitions, one candidate per term it defines."""
    out = []
    for d in defs:
        text = str(d.get("text", ""))
        where = place_of(str(d.get("id", "")), config)
        if where is None:
            continue
        section_only = bool(SECTION_ONLY.match(text))
        for m in _CLAUSE.finditer(text):
            terms = [m.group(1)] + re.findall(_QUOTE, m.group(2) or "")
            verb = m.group(4)
            cites = []
            if verb.startswith("has the meaning"):
                cm = _CITATION.match(text[m.end():].strip())
                if cm:
                    cites = [citation_id(cm.group(1), cm.group(2), config)]
            for t in terms:
                term = " ".join(tokens(t))
                if term:
                    out.append(Candidate(str(d["id"]), term, verb, section_only, where, [c for c in cites if c]))
    return out


def citation_id(code: str, number: str, config: dict) -> str | None:
    """`<code> <chapter>.<section>` ↦ `DEF-<code>-<chapter>-<section>`; the chapter is every dotted
    part but the last."""
    if code not in config["codes"]:
        return None
    parts = number.split(".")
    return "DEF-" + code + "-" + "-".join(parts[:-1] + [parts[-1]])


def uses(law_text: str, terms: list[str]) -> list[str]:
    """The defined terms a law's words use (`matches`, contiguous ones first)."""
    return [term for term, _how, _words in matches(law_text, terms)]


def matches(law_text: str, terms: list[str]) -> list[tuple[str, str, str]]:
    """(term, how, words) for each defined term a law's words use; inline citations are not words.

    `contiguous`: the term's tokens in order, longest first, without overlaps. `split`: a term of
    several tokens none of whose uses is contiguous, used in the bounded copular form `<head> [that|
    which] is|are [not] <modifiers>` inside one clause (no punctuation between), the head in its
    singular or plural form and not the object of a preposition, and the modifiers ending the
    predicate (`_PREDICATE_END`). The modifiers must follow the copula whose subject is the head:
    co-occurring words are not a use. A split use only adds a term; it never displaces a contiguous
    one."""
    words = _INLINE.sub(" ", law_text)
    toks = tokens(words)
    by_len = sorted({tuple(t.split()) for t in terms}, key=lambda t: -len(t))
    found: list[tuple[str, str, str]] = []
    i = 0
    while i < len(toks):
        hit = None
        for t in by_len:
            n = len(t)
            if i + n <= len(toks) and all(a == b for a, b in zip(t[:-1], toks[i:i + n - 1])) and _same(t[-1], toks[i + n - 1]):
                hit = t
                break
        if hit:
            if all(f[0] != " ".join(hit) for f in found):
                found.append((" ".join(hit), "contiguous", " ".join(toks[i:i + len(hit)])))
            i += len(hit)
        else:
            i += 1
    several = [t for t in by_len if len(t) > 1]
    for clause in _CLAUSE_BREAK.split(words):
        ct = tokens(clause)
        for i in range(len(ct)):
            j = i + 1 + (i + 1 < len(ct) and ct[i + 1] in _RELATIVE)
            if j >= len(ct) or ct[j] not in _COPULA:
                continue
            p = i - 1 - (i > 0 and ct[i - 1] in _DETERMINER)
            if p >= 0 and ct[p] in _PREPOSITION:
                continue
            k = j + 1 + (j + 1 < len(ct) and ct[j + 1] == "not")
            for t in several:
                end = k + len(t) - 1
                if (_same(t[-1], ct[i]) and tuple(ct[k:end]) == t[:-1] and (end == len(ct) or ct[end] in _PREDICATE_END)
                        and all(f[0] != " ".join(t) for f in found)):
                    found.append((" ".join(t), "split", " ".join(ct[i:end])))
                    break
    return found


def _chain(first: str, by_id: dict[str, list[Candidate]], posted: set[str]) -> tuple[list[str], str | None]:
    """The records a resolved definition reaches through cross-references, and why the chain
    breaks (a cycle, or a citation of a record not posted), or None."""
    chain, cur = [first], first
    while True:
        cands = by_id.get(cur, [])
        cites = [c for cand in cands for c in cand.cites]
        if not cites:
            return chain, None
        nxt = cites[0]
        if nxt not in posted:
            return chain, f"cites {nxt}, which is not posted"
        if nxt in chain:
            return chain, f"cross-reference cycle through {nxt}"
        chain.append(nxt); cur = nxt


def _indexes(cands: list[Candidate]) -> tuple[dict[str, list[Candidate]], dict[str, list[Candidate]]]:
    by_term: dict[str, list[Candidate]] = {}
    by_id: dict[str, list[Candidate]] = {}
    for c in cands:
        by_term.setdefault(c.term, []).append(c)
        by_id.setdefault(c.definition, []).append(c)
    return by_term, by_id


def _resolve_term(term: str, where: Place | None, inline: set[str], by_term: dict[str, list[Candidate]],
                  by_id: dict[str, list[Candidate]], config: dict, posted: set[str]) -> dict:
    """Resolve one known defined term at `where` by the operator's declared precedence."""
    cs = by_term.get(term, [])
    step, found = None, []
    for s in config.get("steps", []):
        if s == "inline_or_section":
            found = [c for c in cs if c.definition in inline] or \
                    [c for c in cs if c.section_only and where and
                     (c.place.code, c.place.chapter, c.place.section) == (where.code, where.chapter, where.section)]
        elif s == "own_chapter":
            found = [c for c in cs if not c.section_only and where and
                     (c.place.code, c.place.chapter) == (where.code, where.chapter)]
        elif s == "general_chapter":
            g = config["codes"].get(where.code, {}).get("general") if where else None
            found = [c for c in cs if not c.section_only and where and
                     (c.place.code, c.place.chapter) == (where.code, g)]
        elif s == "fallback_code":
            fb = config["codes"].get(where.code, {}).get("fallback") if where else None
            g = config["codes"].get(fb, {}).get("general") if fb else None
            found = [c for c in cs if not c.section_only and fb and
                     (c.place.code, c.place.chapter) == (fb, g)]
        found = sorted({c.definition: c for c in found}.values(), key=lambda c: c.definition)
        if found:
            step = s
            break
    if not found:
        return {"term": term, "status": "unresolved", "definition": None, "step": None,
                "chain": [], "candidates": sorted({c.definition for c in cs})}
    if len(found) > 1:
        return {"term": term, "status": "ambiguous", "definition": None, "step": step,
                "chain": [], "candidates": [c.definition for c in found]}
    chain, broken = _chain(found[0].definition, by_id, posted)
    return {"term": term, "status": "unresolved" if broken else "resolved",
            "definition": found[0].definition, "step": step, "chain": chain,
            "candidates": [found[0].definition]} | ({"why": broken} if broken else {})


def _dependencies(first_chain: list[str], defs_by_id: dict[str, dict], cands: list[Candidate],
                  config: dict, posted: set[str]) -> list[dict]:
    """The transitive defined-term edges used by the definitions in `first_chain`.

    The graph is flattened in deterministic discovery order. A back edge is recorded as `cycle`
    and never traversed again; shared dependencies likewise expand only once. The term a record
    itself defines is excluded from its body scan, so its quoted definiendum is not a self-use.
    """
    by_term, by_id = _indexes(cands)
    all_terms = sorted(by_term)
    expanded: set[str] = set()
    out: list[dict] = []

    def visit(source: str, ancestors: tuple[str, ...]) -> None:
        if source in expanded:
            return
        expanded.add(source)
        text = str(defs_by_id.get(source, {}).get("text", ""))
        where = place_of(source, config)
        inline = set(_INLINE.findall(text))
        defined_here = {c.term for c in by_id.get(source, [])}
        for term, how, said in matches(text, all_terms):
            if term in defined_here:
                continue
            row = {"from": source, **_resolve_term(term, where, inline, by_term, by_id, config, posted), **_found(how, said)}
            reached = list(row.get("chain") or [])
            back = next((d for d in reached if d in ancestors + (source,)), None)
            if back:
                row["cycle"] = list(ancestors + (source, back))
            out.append(row)
            if row["status"] == "resolved" and not back:
                for d in reached:
                    visit(d, ancestors + (source,))

    for definition in first_chain:
        visit(definition, ())
    return out


def resolve_law(law: corpus.Law, cands: list[Candidate], config: dict, posted: set[str]) -> list[dict]:
    """The resolution rows of one law: each defined term its words use, with the definition that
    applies and the step that decided it, or why none applies."""
    where = place_of(law.id, config)
    inline = set(_INLINE.findall(law.text))
    by_term, by_id = _indexes(cands)
    terms = set(by_term) | {c.term for c in cands if c.definition in inline}
    found = matches(law.text, sorted(terms))
    rows = []
    for term, how, said in ([m for m in found if m[1] == "contiguous"] + [(c.term, "inline", "") for c in cands if c.definition in inline]
                            + [m for m in found if m[1] == "split"]):
        if any(r["term"] == term for r in rows):
            continue
        rows.append({**_resolve_term(term, where, inline, by_term, by_id, config, posted), **_found(how, said)})
    return rows


def _found(how: str, words: str) -> dict:
    """What a row records of how its term was found: only a split use is marked, with its words."""
    return {"match": "split", "words": words} if how == "split" else {}


def resolve_table(laws: list[corpus.Law], defs: list[dict], config: dict) -> dict:
    """The persisted shape: compact law rows and one nested-term dependency graph per root
    definition. A definition used by hundreds of laws is resolved once, never copied hundreds of
    times."""
    cands = extract(defs, config)
    posted = {str(d.get("id")) for d in defs}
    defs_by_id = {str(d.get("id")): d for d in defs}
    law_rows = {law.id: resolve_law(law, cands, config, posted) for law in laws}
    roots = {row["definition"]: list(row["chain"])
             for rows in law_rows.values() for row in rows if row["status"] == "resolved"}
    return {"laws": law_rows,
            "dependencies": {definition: _dependencies(chain, defs_by_id, cands, config, posted)
                             for definition, chain in sorted(roots.items())}}


def row_for_definition(table: dict, definition: str) -> dict | None:
    """One resolved root row for `definition`; its definition-local dependencies are identical
    wherever that root is used because they resolve from each definition's own place."""
    for rows in table.get("laws", {}).values():
        for row in rows:
            if row.get("status") == "resolved" and row.get("definition") == definition:
                return row
    return None


def source_ids(table: dict, definition: str) -> list[str]:
    """The controlling definition, explicit cross-references and every resolved nested source."""
    closure = resolution_closure(table, definition)
    out: list[str] = []
    for d in closure["chain"] + [d for dep in closure["dependencies"] if dep.get("status") == "resolved"
                                  for d in dep.get("chain", [])]:
        if d not in out:
            out.append(d)
    return out


def resolution_closure(table: dict, definition: str) -> dict:
    """The exact mechanical resolution evidence whose digest governs an aggregate admission."""
    row = row_for_definition(table, definition)
    dependencies = table.get("dependencies", {}).get(definition)
    if dependencies is None and row is not None:                 # compatibility with early run tables
        dependencies = row.get("dependencies", [])
    return {"chain": list(row.get("chain") or [definition]),
            "dependencies": list(dependencies or [])} if row else {"chain": [definition], "dependencies": []}


# ---------------------------------------------------------------------------------------------
# The run's persisted table, and what reads it
# ---------------------------------------------------------------------------------------------
def table_file(run) -> Path:
    return run.dir / "definition_resolution.json"


def precedence_path(run) -> Path:
    return Path(run.opts.definition_precedence or DEFAULT_PRECEDENCE)


def write_table(run, laws: list[corpus.Law], defs: list[dict]) -> dict:
    """Resolve every law of the run and save the table; the one computation every reader shares."""
    path = precedence_path(run)
    table = {"precedence": {"path": str(path), "sha256": precedence_digest(path)},
             **resolve_table(laws, defs, load_precedence(path))}
    table_file(run).write_text(json.dumps(table, ensure_ascii=False, indent=1), encoding="utf-8")
    return table


def load_table(run) -> dict:
    f = table_file(run)
    return json.loads(f.read_text(encoding="utf-8")) if f.exists() else {"precedence": {}, "laws": {}}


def rows_for(run, law_id: str) -> list[dict]:
    return load_table(run).get("laws", {}).get(law_id, [])


def applicable(run, law_id: str) -> list[dict]:
    """The posted records that apply to a law's words: every record of a resolved term's chain, and
    resolved nested-definition closure, and every candidate of an ambiguous root term, each once.
    A record whose term the law's words use only split carries those words under `split`."""
    defs = {str(d.get("id")): d for d in corpus.load_definitions(run.opts.laws)}
    table = load_table(run)
    ids: list[str] = []
    rows = table.get("laws", {}).get(law_id, [])
    for r in rows:
        reached = source_ids(table, r["definition"]) if r.get("status") == "resolved" else []
        for i in reached + (r.get("candidates") if r.get("status") == "ambiguous" else []):
            if i not in ids:
                ids.append(i)
    whole = {i for r in rows if r.get("match") != "split" for i in [r.get("definition"), *(r.get("candidates") or [])] if i}
    split = {}
    for r in rows:
        for i in [r.get("definition"), *(r.get("candidates") or [])] if r.get("match") == "split" else []:
            if i and i not in whole:
                split.setdefault(i, r["words"])
    return [{**defs[i], "split": split[i]} if i in split else defs[i] for i in ids if i in defs]


def precedence_hash(run) -> str:
    return load_table(run).get("precedence", {}).get("sha256", "")
