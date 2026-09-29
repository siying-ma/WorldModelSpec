"""A formula, as the JSON `Core/Language/Export.lean` writes it, rendered as structured prose for the blind
reader. Deterministic and model-free: every constructor has one phrasing, atom and concept names
are glossed from the contracts the caller supplies, and nothing is summarised away."""
from __future__ import annotations
import re

_CMP = {"lt": "is less than", "le": "is at most", "eq": "equals", "ge": "is at least", "gt": "is more than"}


def _arg(a: dict) -> str:
    if "var" in a:
        return f"`{a['var']}`"
    if "lit" in a:
        return f"'{a['lit']}'"
    return str(a.get("nat", "?"))


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
        return str(t)
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
    return str(t)


def formula(f, glosses: dict[str, str], depth: int = 0) -> str:
    pad = "  " * depth
    if f == "tt":
        return "true"
    if f == "ff":
        return "false"
    if not isinstance(f, dict):
        return str(f)
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
    for op, word in (("and", "AND"), ("or", "OR"), ("implies", "IMPLIES"), ("until", "UNTIL"), ("since", "SINCE")):
        if op in f:
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
    if "until_within" in f:
        return (f"within the next {term(f['length'], glosses)} of {f['until_within']} of `{f['subject']}`, "
                f"({formula(f['hold'], glosses, depth)}) holds until ({formula(f['reach'], glosses, depth)})")
    if "rises" in f:
        return f"({formula(f['rises'], glosses, depth)}) holds now and did not hold at the previous observation"
    if "defined_when" in f:
        return f"provided that ({formula(f['defined_when'], glosses, depth)}) — undefined otherwise: ({formula(f['body'], glosses, depth)})"
    if "count" in f:
        return (f"the number of times ({formula(f['count'], glosses, depth)}) became true since "
                f"({formula(f['since'], glosses, depth)}) last became true {_CMP[f['op']]} {f['n']}")
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
    return str(f)


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
