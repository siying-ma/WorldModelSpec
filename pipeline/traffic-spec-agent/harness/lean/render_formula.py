"""A formula, as the JSON `Core/Language/Export.lean` writes it, rendered as structured prose for the
concept reviewer and its judges. Deterministic and model-free: every constructor has one phrasing, atom, primitive and
concept names are glossed from the contracts the caller supplies, and nothing is summarised away."""
from __future__ import annotations
import re

_CMP = {"lt": "is less than", "le": "is at most", "eq": "equals", "ge": "is at least", "gt": "is more than"}
#: The annotations the rendering adds after a name: the contract's gloss in brackets, and a
#: parameter's note. A reader quoting the rule's words may leave them out.
_ANNOTATION = re.compile(r" \[[^\[\]]*\]| \((?:a bound the reading sets|a parameter the caller sets)\)")


def bare(text: str) -> str:
    """The text without the rendering's annotations."""
    return _ANNOTATION.sub("", str(text or ""))


#: How a judge's contracts mark the meaning of an assumption a case states: the source's declaration.
DECLARED_BY_SOURCE = "declared by the source: "


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
    """The contract of a Lean name, by its atom id (accessor suffixes stripped), primitive id or
    concept id."""
    key = name.replace("_", ".", 1) if "." not in name else name
    cands = sorted((k for k in glosses if name == k.replace(".", "_") or name.startswith(k.replace(".", "_") + "_")),
                   key=len, reverse=True)
    if cands:
        return glosses[cands[0]]
    return glosses.get(key, "")


def _called(name: str) -> str:
    """A called name as the reader is told what it is: an ontology primitive (`prim_*`) as the
    primitive, any other name a body calls as the concept."""
    return f"the {'primitive' if str(name).startswith('prim_') else 'concept'} `{name}`"


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
        return f"{_called(t['quantity'])} of {_args(t.get('args', []))}" + (f" with {ps}" if ps else "") + (f" [{g}]" if g else "")
    if "distance_while" in t:
        return f"the path length `{t['distance_while']}` has travelled while ({formula(t['holds'], glosses)}) held continuously"
    if "since_rise" in t:
        return f"the time since ({formula(t['since_rise'], glosses)}) last became true"
    if "heading_since" in t:
        return (f"the heading change of `{t['heading_since']}` since ({formula(t['onset'], glosses)}) last became true, "
                f"integrated with steps of at most {term(t['max_step'], glosses)}")
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
        return f"{_called(f['derived'])} holds of {_args(f.get('args', []))}" + (f" with {ps}" if ps else "") + (f" [{g}]" if g else "")
    if "cmp" in f:
        return f"{term(f['lhs'], glosses)} {_CMP[f['cmp']]} {term(f['rhs'], glosses)}"
    if "same" in f:
        a, b = f["same"]
        return f"{_arg(a)} and {_arg(b)} are the same entity"
    if "asm" in f:
        return f"the assumption `{f['asm']}` is declared true"
    if "int" in f:
        who, target = f["args"]
        return f"road user {_arg(who)} is declared to intend `{f['int']}` at region {_arg(target)}"
    if "not" in f and isinstance(f["not"], dict) and set(f["not"]) == {"asm"}:
        # a direct negation of an assumption holds exactly where the source declares it false
        aid = f["not"]["asm"]
        g = gloss(aid, glosses).removeprefix(DECLARED_BY_SOURCE)
        return f"the source declares the assumption `{aid}`" + (f" [{g}]" if g else "") + " false"
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
        if binder:                                  # every subexpression the binder scopes is walked inside its scope
            v = x["var"] if binder.endswith(("region", "device")) or binder == "aggregate" else x[binder]
            fresh = f"$b{counter[0]}"; counter[0] += 1
            out = dict(x)
            if binder.endswith(("region", "device")):
                out[binder] = walk(x[binder])         # the kind ranged over: outside the scope
            saved = names.get(v)
            names[v] = fresh
            for k in ("body", "where", "of"):
                if k in x:
                    out[k] = walk(x[k])
            if saved is None:
                names.pop(v, None)
            else:
                names[v] = saved
            if binder == "aggregate" or binder.endswith(("region", "device")):
                out["var"] = fresh
            else:
                out[binder] = fresh
            return out
        for k, v in x.items():
            if k == "var":
                out[k] = ren(v)
            elif k == "param":
                out[k] = params.get(v, v)
            elif k in ("subject", "distance_while", "heading_since"):
                out[k] = ren(v)
            else:
                out[k] = walk(v)
        return out

    return json.dumps(walk(body), sort_keys=True, separators=(",", ":"))


# ---------------------------------------------------------------------------------------------
# A case in time order: the same formula, its facts placed on the trace's time axis
# ---------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------
# The executed facts of a trace: what a judge reads when no case formula states them
# ---------------------------------------------------------------------------------------------
def _value(v) -> str:
    """A trace value as written: a number, a string, a list or an object, compactly."""
    import json
    return json.dumps(v, ensure_ascii=False, separators=(", ", ": "))


def _fields(obj: dict, skip: tuple[str, ...] = ()) -> list[str]:
    """Every key of a trace object and its value, nested objects flattened to dotted keys."""
    out = []
    for k, v in obj.items():
        if k in skip:
            continue
        if isinstance(v, dict) and v:
            out += [f"{k}.{x}" for x in _fields(v)]
        else:
            out.append(f"{k} {_value(v)}")
    return out


def _has(obj, path: list[str]) -> bool:
    for k in path:
        if not isinstance(obj, dict) or k not in obj:
            return False
        obj = obj[k]
    return True


def trace_facts(trace: dict, grounding: dict, at: int, instance: dict | None = None, read: list[str] | None = None,
                occupancy: dict[int, list[str]] | None = None, regions: dict | None = None) -> str:
    """Every input Core reads that the trace states, scene by scene in time order: each user (its
    classes, kinematics, posture, signals, everything written), each structure and device with
    every attribute, the environment, the assumptions, each declared intention with the source that
    declares it, the supplied relations, the occupancy as
    written; then the occupancy the harness derived from the geometry before running (`occupancy`,
    by timestamp: `track-region` pairs), apart. A field the body reads (`read`: trace paths such as
    `users[].kin.speed`) that a user, structure or device leaves out is written "not observed",
    never false or zero. The grounding, the regions a concept's region formals name (with the kind
    of structure each is), the instant judged and the instance head it. Numbers are in
    Core units, as every trace writes them. Only the keys the decoder reads are facts: the keys of
    the written trace it does not read were never executed, and are listed after the facts, by
    path, as the reviewer's unverified annotations."""
    from .surface import read_part, unread_keys
    annotations, trace = unread_keys(trace), read_part(trace)
    read = read or []
    by_kind = {"users": [], "structures": [], "devices": []}
    for p in read:
        m = re.match(r"(users|structures|devices)\[\]\.(.+)$", p)
        if m:
            by_kind[m.group(1)].append(m.group(2).split("."))
    inst = instance or {}
    head = ["### The executed facts",
            "",
            "What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees "
            "per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.",
            "",
            "- grounding: " + (", ".join(f"`{f}` = track {t}" for f, t in (grounding or {}).items()) or "none"),
            f"- the observation judged: t = {at} ms"]
    if regions:
        kinds = {st.get("id"): st.get("kind") for sc in ((trace or {}).get("scenes") or []) if isinstance(sc, dict)
                 for st in sc.get("structures") or [] if isinstance(st, dict)}
        head.insert(-1, "- regions: " + ", ".join(f"`{f}` = region {r}" + (f" ({kinds[r]})" if kinds.get(r) else " (no structure of the trace)")
                                                  for f, r in regions.items()))
    for key, label in (("literals", "literal formals"), ("nats", "nat formals"), ("params", "parameters")):
        vals = inst.get(key) or {}
        if vals:
            head.append(f"- {label}: " + ", ".join(f"`{f}` = " + (f"{v[0]} {v[1]}" if isinstance(v, list) and len(v) == 2 else _value(v))
                                                   for f, v in vals.items()))
    out = head + [""]
    for sc in sorted(((trace or {}).get("scenes") or []), key=lambda s: s.get("t") if isinstance(s, dict) and isinstance(s.get("t"), int) else 0):
        if not isinstance(sc, dict):
            continue
        out.append(f"Scene t = {sc.get('t')} ms" + (" (the observation judged)" if sc.get("t") == at else "") + ":")
        for kind, idk, label in (("users", "track", "track"), ("structures", "id", "structure"), ("devices", "id", "device")):
            for e in sc.get(kind) or []:
                if not isinstance(e, dict):
                    continue
                facts = _fields(e, (idk,))
                missing = [".".join(p) for p in by_kind[kind] if not _has(e, p)]
                out.append(f"- {label} {e.get(idk)}: " + ("; ".join(facts) or "nothing stated")
                           + (f"; not observed: {', '.join(missing)}" if missing else ""))
        for m in sc.get("relations") or []:
            if isinstance(m, dict):
                out.append(f"- supplied relation {m.get('a')}-{m.get('b')}: " + "; ".join(_fields(m, ("a", "b"))))
        for d in sc.get("intents") or []:
            if isinstance(d, dict):
                vals = "; ".join(f"`{v[0]}` {_value(v[1])}" for v in d.get("values") or [] if isinstance(v, list) and len(v) == 2)
                out.append(f"- declared intention of track {d.get('vehicle')} at region {d.get('target')} (declared by: {d.get('source')}): "
                           + (vals or "no id decided"))
        rest = {k: v for k, v in sc.items() if k not in ("t", "users", "structures", "devices", "relations", "intents")}
        for k, v in rest.items():
            out.append(f"- {k}: " + ("; ".join(_fields(v)) if isinstance(v, dict) else _value(v)))
        derived = (occupancy or {}).get(sc.get("t"))
        if derived is not None:
            out.append("- occupancy derived from the geometry before running: " + (", ".join(derived) or "none"))
    if annotations:
        out += ["", "Unverified annotations of the reviewer — keys the decoder does not read, so nothing above rests on them "
                "and they are no fact of the case: " + ", ".join(f"`{a}`" for a in annotations[:20])
                + (f" and {len(annotations) - 20} more" if len(annotations) > 20 else "")]
    return "\n".join(out) + "\n"
