

# The abstraction this pipeline consumes. Edges emitted by any other
# abstraction function are not in our graphs.
ABSTRACTION = "process_to_junction_rsv"

# Helpers the abstraction calls that also add edges.
EDGE_HELPERS = ("__add_to_graph", "init_to_world", "generate_graph_for_frame")


def edge_label_sites() -> dict[str, list[str]]:
    """Relation label -> the `file:line` sites that emit it, in OUR abstraction.

    A label emitted at more than one site is OVERLOADED: the same word denotes
    different things depending on which loop drew it, and a rule that reads it
    as one meaning silently accepts the other. `isIn` is the documented case;
    it is not the only one, which is why this is derived rather than listed.

    Labels whose value is a variable rather than a literal — the proximity band
    and the directional relation — are grouped under a placeholder naming the
    expression, since the concrete labels come from the threshold tables.
    """
    out: dict[str, list[str]] = {}
    for fname in ("sgg.py", "sgg_abstractor.py"):
        tree = _tree(fname)
        for fn in ast.walk(tree):
            if not isinstance(fn, ast.FunctionDef):
                continue
            if fn.name != ABSTRACTION and fn.name not in EDGE_HELPERS:
                continue
            for node in ast.walk(fn):
                if not (isinstance(node, ast.Call)
                        and isinstance(node.func, ast.Attribute)
                        and node.func.attr == "add_edge"):
                    continue
                for kw in node.keywords:
                    if kw.arg not in ("label", "dist_relationship"):
                        continue
                    if isinstance(kw.value, ast.Constant):
                        label = kw.value.value
                    else:
                        label = f"<{ast.unparse(kw.value)}>"
                    out.setdefault(label, []).append(f"{fname}:{node.lineno}")
    return {k: sorted(set(v)) for k, v in sorted(out.items())}


def overloaded_labels() -> dict[str, list[str]]:
    """Labels emitted at more than one site in the abstraction we consume."""
    return {k: v for k, v in edge_label_sites().items() if len(v) > 1}
