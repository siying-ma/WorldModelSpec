"""A formula, as the JSON `Core/Language/Export.lean` writes it, rendered as structured prose for the blind
reader. Deterministic and model-free: every constructor has one phrasing, atom and concept names
are glossed from the contracts the caller supplies, and nothing is summarised away."""
from __future__ import annotations
import re

_CMP = {"lt": "is less than", "le": "is at most", "eq": "equals", "ge": "is at least", "gt": "is more than"}
#: The annotations the rendering adds after a name: the contract's gloss in brackets, and a
#: parameter's note. A reader quoting the rule's words may leave them out.
_ANNOTATION = re.compile(r" \[[^\[\]]*\]| \((?:a bound the reading sets|a parameter the caller sets)\)")


def bare(text: str) -> str:
    """The text without the rendering's annotations."""
    return _ANNOTATION.sub("", str(text or ""))


class Unrendered(ValueError):
    """A construct of the export this renderer has no phrasing for: the review cannot run on it,
    since the reader would be shown the raw structure instead of prose."""


def _arg(a: dict) -> str:
    if "var" in a:
        return f"`{a['var']}`"
    if "lit" in a:
        return f"'{a['lit']}'"
    if "nat" in a:
        return str(a["nat"])
    raise Unrendered(f"argument {sorted(a) if isinstance(a, dict) else a!r}")


def _args(xs: list) -> str:
    return ", ".join(_arg(a) for a in xs)


def _num(lit: dict) -> str:
    q = lit.get("lit", {})
    num, den = q.get("num", 0), q.get("den", 1)
    val = f"{num}" if den == 1 else f"{num}/{den}"
    return f"{val} {lit.get('unit', '')}".strip()


def gloss(name: str, glosses: dict[str, str]) -> str:
    """The contract of a Lean name, by its atom id (accessor suffixes stripped) or concept id."""
    key = name.replace("_", ".", 1) if "." not in name else name
    cands = sorted((k for k in glosses if name == k.replace(".", "_") or name.startswith(k.replace(".", "_") + "_")),
                   key=len, reverse=True)
    if cands:
        return glosses[cands[0]]
    return glosses.get(key, "")


def term(t, glosses: dict[str, str]) -> str:
    if not isinstance(t, dict):
        raise Unrendered(f"term {t!r}")
    if "lit" in t:
        return _num(t)
    if "param" in t:
        return f"`{t['param']}` (a parameter the caller sets)"
    if "measure" in t:
        g = gloss(t["measure"], glosses)
        return f"the measured `{t['measure']}` of {_args(t.get('args', []))}" + (f" [{g}]" if g else "")
    if "quantity" in t:
        g = gloss(t["quantity"], glosses)
        ps = ", ".join(term(p, glosses) for p in t.get("params", []))
        return f"the concept `{t['quantity']}` of {_args(t.get('args', []))}" + (f" with {ps}" if ps else "") + (f" [{g}]" if g else "")
    if "distance_while" in t:
        return f"the path length `{t['distance_while']}` has travelled while ({formula(t['holds'], glosses)}) held continuously"
    if "since_rise" in t:
        return f"the time since ({formula(t['since_rise'], glosses)}) last became true"
    if "aggregate" in t:
        return (f"the {t['aggregate']} of {term(t['of'], glosses)} over the road users `{t['var']}` of the scene "
                f"for which ({formula(t['where'], glosses)})")
    for op, word in (("add", "plus"), ("sub", "minus"), ("mul", "times"), ("div", "divided by")):
        if op in t:
            a, b = t[op]
            return f"({term(a, glosses)} {word} {term(b, glosses)})"
    if "neg" in t:
        return f"the negative of {term(t['neg'], glosses)}"
    if "abs" in t:
        return f"the absolute value of {term(t['abs'], glosses)}"
    if "cond" in t:
        return (f"({term(t['then'], glosses)} where ({formula(t['cond'], glosses)}) holds, "
                f"otherwise {term(t['else'], glosses)})")
    raise Unrendered(f"term {sorted(t)}")


def formula(f, glosses: dict[str, str], depth: int = 0) -> str:
    pad = "  " * depth
    if f == "tt":
        return "true"
    if f == "ff":
        return "false"
    if not isinstance(f, dict):
        raise Unrendered(f"formula {f!r}")
    if "atom" in f:
        g = gloss(f["atom"], glosses)
        ps = ", ".join(term(p, glosses) for p in f.get("params", []))
        return f"`{f['atom']}` holds of {_args(f.get('args', []))}" + (f" at {ps}" if ps else "") + (f" [{g}]" if g else "")
    if "derived" in f:
        g = gloss(f["derived"], glosses)
        ps = ", ".join(term(p, glosses) for p in f.get("params", []))
        return f"the concept `{f['derived']}` holds of {_args(f.get('args', []))}" + (f" with {ps}" if ps else "") + (f" [{g}]" if g else "")
    if "cmp" in f:
        return f"{term(f['lhs'], glosses)} {_CMP[f['cmp']]} {term(f['rhs'], glosses)}"
    if "same" in f:
        a, b = f["same"]
        return f"{_arg(a)} and {_arg(b)} are the same entity"
    if "asm" in f:
        return f"the assumption `{f['asm']}` is declared true"
    if "not" in f:
        return f"it is not the case that ({formula(f['not'], glosses, depth)})"
    if "count" in f:
        return (f"the number of times ({formula(f['count'], glosses, depth)}) became true since "
                f"({formula(f['since'], glosses, depth)}) last became true {_CMP[f['op']]} {f['n']}")
    for op, word in (("and", "AND"), ("or", "OR"), ("implies", "IMPLIES"), ("until", "UNTIL"), ("since", "SINCE")):
        if op in f and isinstance(f[op], list) and len(f[op]) == 2:
            a, b = f[op]
            return f"(\n{pad}  {formula(a, glosses, depth + 1)}\n{pad}  {word}\n{pad}  {formula(b, glosses, depth + 1)}\n{pad})"
    if "always" in f:
        return f"from now on, always: ({formula(f['always'], glosses, depth)})"
    if "eventually" in f:
        return f"at some later observation: ({formula(f['eventually'], glosses, depth)})"
    if "holds_for" in f:
        return (f"at every observation of the last {term(f['length'], glosses)} of {f['holds_for']} of `{f['subject']}`: "
                f"({formula(f['body'], glosses, depth)})")
    if "within" in f:
        return (f"at some observation within the next {term(f['length'], glosses)} of {f['within']} of `{f['subject']}`: "
                f"({formula(f['body'], glosses, depth)})")
    if "at_last" in f:
        return (f"at the last observation of the last {term(f['length'], glosses)} of {f['at_last']} of `{f['subject']}` "
                f"at which ({formula(f['when'], glosses, depth)}) held: ({formula(f['body'], glosses, depth)}) — "
                f"false where it held at no observation of that stretch")
    if "until_within" in f:
        return (f"within the next {term(f['length'], glosses)} of {f['until_within']} of `{f['subject']}`, "
                f"({formula(f['hold'], glosses, depth)}) holds until ({formula(f['reach'], glosses, depth)})")
    if "rises" in f:
        return f"({formula(f['rises'], glosses, depth)}) holds now and did not hold at the previous observation"
    if "defined_when" in f:
        return f"provided that ({formula(f['defined_when'], glosses, depth)}) — undefined otherwise: ({formula(f['body'], glosses, depth)})"
    if "rule" in f:
        return f"the rule `{f['rule']}` is complied with (binders {f.get('map')})"
    if "rule_applies" in f:
        return f"the rule `{f['rule_applies']}` is engaged (binders {f.get('map')})"
    for key, phrase in (("exists_user", "some road user `{v}` of the scene"), ("forall_user", "every road user `{v}` of the scene"),
                        ("exists_region", "some region `{v}` of kind '{k}'"), ("forall_region", "every region `{v}` of kind '{k}'"),
                        ("exists_device", "some device `{v}` of kind '{k}'"), ("forall_device", "every device `{v}` of kind '{k}'")):
        if key in f:
            v = f.get("var", f.get(key)) if key.endswith(("region", "device")) else f[key]
            k = _arg(f.get(key)) if key.endswith(("region", "device")) and isinstance(f.get(key), dict) else (f.get(key) if key.endswith(("region", "device")) else "")
            head = phrase.format(v=v, k=k)
            return f"for {head}: ({formula(f['body'], glosses, depth)})"
    raise Unrendered(f"formula {sorted(f)}")


def render_concept(export: dict, glosses: dict[str, str]) -> str:
    """A concept's export (`Concept.toJson`) as prose: its formals, then its body."""
    lines = []
    args = ", ".join(f"`{a['name']}` (a {a['sort'].get('sort')}" + (f" among {a['sort'].get('values')}" if a['sort'].get('sort') == 'literal' else "") + ")"
                     for a in export.get("args", []))
    params = ", ".join(f"`{p['name']}` in {p['unit']}" for p in export.get("params", []))
    lines.append(f"Arguments: {args or '(none)'}.")
    lines.append(f"Parameters (bounds the caller sets): {params or '(none)'}.")
    if export.get("kind") == "quantity":
        lines.append("The value is: " + term(export["body"], glosses))
    else:
        lines.append("It holds at an observation exactly when:\n" + formula(export["body"], glosses))
    return "\n".join(lines)


def render_rule(export: dict, glosses: dict[str, str]) -> str:
    """A rule's export (`Rule.toJson`) as prose for the blind reader: each binder with its class
    formula, the applicability, the obligation, the assumptions. The operationalizations (whose
    `standard` field is the law's own words), the residues and the law ids are not rendered."""
    lines = ["Parties (each must satisfy its class at an observation for the rule to speak about it):"]
    for b in export.get("binders", []):
        lines.append(f"- `{b['name']}`: {formula(b.get('cls', 'tt'), glosses, 1)}")
    lines.append("")
    lines.append("The rule engages at an observation exactly when:\n" + formula(export.get("applicability", "tt"), glosses))
    lines.append("")
    lines.append("While engaged, it is complied with exactly when:\n" + formula(export.get("obligation", "tt"), glosses))
    asms = export.get("assumptions", [])
    lines.append("")
    lines.append("Assumptions the trace must declare: " + (", ".join(f"`{a}`" for a in asms) if asms else "(none)") + ".")
    return "\n".join(lines).replace("(a parameter the caller sets)", "(a bound the reading sets)")


def canonical(body, arg_names: list[str], param_names: list[str]) -> str:
    """The body with formals and bound variables renamed positionally, as sorted-key JSON, so two
    alpha-equivalent bodies compare equal."""
    import json
    names: dict[str, str] = {n: f"$a{i}" for i, n in enumerate(arg_names)}
    params: dict[str, str] = {n: f"$p{i}" for i, n in enumerate(param_names)}
    counter = [0]

    def ren(v: str) -> str:
        return names.get(v, v)

    def walk(x):
        if isinstance(x, list):
            return [walk(y) for y in x]
        if not isinstance(x, dict):
            return x
        out = {}
        binder = next((k for k in ("exists_user", "forall_user", "exists_region", "forall_region", "exists_device", "forall_device", "aggregate") if k in x), None)
        if binder:
            v = x["var"] if binder.endswith(("region", "device")) or binder == "aggregate" else x[binder]
            fresh = f"$b{counter[0]}"; counter[0] += 1
            saved = names.get(v)
            names[v] = fresh
            body = walk(x["body"]) if "body" in x else None
            if saved is None:
                names.pop(v, None)
            else:
                names[v] = saved
            out = dict(x)
            if binder == "aggregate":
                out["where"] = walk(x["where"]); out["of"] = walk(x["of"]); out["var"] = fresh
            else:
                out["body"] = body
                if binder.endswith(("region", "device")):
                    out["var"] = fresh; out[binder] = walk(x[binder])
                else:
                    out[binder] = fresh
            return out
        for k, v in x.items():
            if k == "var":
                out[k] = ren(v)
            elif k == "param":
                out[k] = params.get(v, v)
            elif k in ("subject", "distance_while"):
                out[k] = ren(v)
            else:
                out[k] = walk(v)
        return out

    return json.dumps(walk(body), sort_keys=True, separators=(",", ":"))


# ---------------------------------------------------------------------------------------------
# A case in time order: the same formula, its facts placed on the trace's time axis
# ---------------------------------------------------------------------------------------------
_TEMPORAL = ("holds_for", "within", "at_last", "until_within", "rises", "since", "until", "count", "always", "eventually",
             "since_rise", "distance_while")


def _conj(f) -> list:
    return [g for x in f["and"] for g in _conj(x)] if isinstance(f, dict) and set(f) == {"and"} else [f]


def _seconds(t) -> float | None:
    """A literal's value in seconds, or None when it is not a time literal."""
    if isinstance(t, dict) and isinstance(t.get("lit"), dict) and t.get("unit") in ("second", "s"):
        return t["lit"].get("num", 0) / (t["lit"].get("den", 1) or 1)
    return None


def _time_test(f):
    """`(op, seconds)` when the formula compares the observation's time (`kin_time`) with a literal."""
    if isinstance(f, dict) and "cmp" in f:
        lhs, rhs = f.get("lhs"), f.get("rhs")
        if isinstance(lhs, dict) and lhs.get("measure") == "kin_time" and _seconds(rhs) is not None:
            return f["cmp"], _seconds(rhs)
        if isinstance(rhs, dict) and rhs.get("measure") == "kin_time" and _seconds(lhs) is not None:
            return {"lt": "gt", "le": "ge", "gt": "lt", "ge": "le", "eq": "eq"}[f["cmp"]], _seconds(lhs)
    return None


def _narrow(lo: float, hi: float, tests: list) -> tuple[float, bool, float, bool] | None:
    """The interval from lo to hi (both included) restricted by time tests, as `(lo, lo_open, hi,
    hi_open)`: a strict test (`gt`, `lt`) leaves its end out. None where the interval is empty,
    a strict end included."""
    lo_open = hi_open = False
    for op, c in tests:
        if op in ("ge", "gt"):
            if c > lo or (c == lo and op == "gt"):
                lo, lo_open = c, op == "gt"
        elif op in ("le", "lt"):
            if c < hi or (c == hi and op == "lt"):
                hi, hi_open = c, op == "lt"
        elif op == "eq":
            if not (lo <= c <= hi) or (c == lo and lo_open) or (c == hi and hi_open):
                return None
            lo, hi, lo_open, hi_open = c, c, False, False
    if lo > hi or (lo == hi and (lo_open or hi_open)):
        return None
    return lo, lo_open, hi, hi_open


def _has_time(f) -> bool:
    if isinstance(f, dict):
        if any(k in f for k in _TEMPORAL) or (f.get("measure") == "kin_time"):
            return True
        return any(_has_time(v) for v in f.values())
    if isinstance(f, list):
        return any(_has_time(v) for v in f)
    return False


def _split_tests(body) -> tuple[list, list]:
    """A conjunction's time tests and its other facts."""
    tests, rest = [], []
    for g in _conj(body):
        t = _time_test(g)
        (tests if t else rest).append(t if t else g)
    return tests, rest


def timeline(case, at_ms: int, glosses: dict[str, str] | None = None, times: list[int] | None = None) -> str:
    """The case's facts in time order, as the same formula states them: a window behind `at` is the
    stretch from `at` less its length to `at`, a window ahead the stretch after `at`; a time test
    (`kin_time` against a literal) inside a window narrows it; "at some observation" (`not` of a
    window of `not`) and "at every observation" are kept apart; `rises` names the previous
    observation. Nothing is added: a fact the case does not state is not shown, a time not listed
    says nothing, and the trace contributes timestamps only. A time-bearing form this layout cannot
    place stays at `at` with the section marked partial; the canonical statement stays authoritative."""
    g = glosses or {}
    at = at_ms / 1000
    prev = max((t for t in (times or []) if t < at_ms), default=None)
    placed: list[tuple[tuple, int, str]] = []               # (span, order, text); span = (from, from_open, to, to_open)
    partial = False

    def put(span, text, order=0):
        placed.append((span, order, text))
    closed = lambda lo, hi: (lo, False, hi, False)

    def inner_time(x) -> bool:
        """A window's fact that itself involves another time: a nested window, a `rises`, a time
        test outside the guard. Not placed: the fact stays at `at` and the section is partial."""
        return _has_time(x)

    for f in _conj(case):
        if isinstance(f, dict) and f.get("holds_for") == "time" and _seconds(f.get("length")) is not None \
                and not any(inner_time(b["implies"][1]) if isinstance(b, dict) and "implies" in b and _time_test(b["implies"][0]) is not None
                            else inner_time(b) for b in _conj(f["body"])):
            lo = at - _seconds(f["length"])
            for b in _conj(f["body"]):
                if isinstance(b, dict) and "implies" in b and _time_test(b["implies"][0]) is not None:
                    span = _narrow(lo, at, [_time_test(b["implies"][0])])
                    if span is None:                          # the guard holds at no instant of the window: nothing stated
                        continue
                    word = "at that observation" if span[0] == span[2] else "at every observation"
                    for x in _conj(b["implies"][1]):
                        put(span, f"{word}: " + formula(x, g))
                else:
                    put(closed(lo, at), "at every observation: " + formula(b, g))
            continue
        if isinstance(f, dict) and set(f) == {"not"} and isinstance(f["not"], dict) and f["not"].get("holds_for") == "time" \
                and _seconds(f["not"].get("length")) is not None and isinstance(f["not"].get("body"), dict) and set(f["not"]["body"]) == {"not"}:
            tests, rest = _split_tests(f["not"]["body"]["not"])
            span = _narrow(at - _seconds(f["not"]["length"]), at, tests)
            if span is not None and rest and not any(inner_time(x) for x in rest):
                word = "at that observation" if span[0] == span[2] else "at some observation of this stretch, all together"
                put(span, f"{word}: " + "; ".join(formula(x, g) for x in rest))
                continue
        if isinstance(f, dict) and f.get("within") == "time" and _seconds(f.get("length")) is not None:
            tests, rest = _split_tests(f["body"])
            span = _narrow(at, at + _seconds(f["length"]), tests)
            if span is not None and rest and not any(inner_time(x) for x in rest):
                put(span, "at some observation of this stretch, all together: " + "; ".join(formula(x, g) for x in rest))
                continue
        if isinstance(f, dict) and "rises" in f and not _has_time(f["rises"]):
            if prev is not None:
                put(closed(prev / 1000, prev / 1000), f"it is not the case that ({formula(f['rises'], g)})", order=-1)
            else:
                put(closed(at, at), "at the observation before this one: it is not the case that (" + formula(f["rises"], g) + ")", order=-1)
            put(closed(at, at), formula(f["rises"], g))
            continue
        if _has_time(f):                                      # a form with another time that this layout does not place
            partial = True
        put(closed(at, at), formula(f, g))

    def when(span):
        lo, lo_open, hi, hi_open = span
        s = lambda x: f"{x:g} s"
        if lo == hi:
            return f"At t = {s(lo)}" + (" (the observation judged)" if lo == at else "")
        return (f"From t = {s(lo)}" + (" (not including it)" if lo_open else "") + f" to t = {s(hi)}" + (" (not including it)" if hi_open else ""))
    out = [f"The same facts, in time order (t in seconds on the trace's own clock, the observation time `kin_time`; the observation judged is t = {at:g} s). Only what the case "
           "states is listed; a time or a fact not listed is not stated" + ("; some facts involve other times in a form this layout does not "
           "place, and are listed at the observation judged — the full statement above is authoritative" if partial else "") + "."]
    groups: dict[tuple, list[tuple[int, str]]] = {}
    for span, order, text in placed:
        groups.setdefault(span, []).append((order, text))
    for span in sorted(groups, key=lambda k: (k[0], k[1], k[2], k[3])):
        out.append(f"- {when(span)}:")
        out += [f"  - {t}" for _o, t in sorted(groups[span], key=lambda x: x[0])]
    return "\n".join(out)
