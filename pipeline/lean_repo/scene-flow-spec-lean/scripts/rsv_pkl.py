#!/usr/bin/env python3
"""
Inspect a carla_sgg RSV scene-graph pickle (rsv/<frame>.pkl) WITHOUT needing CARLA.

The pkl is a pickled networkx graph whose NODES are `carla_sgg.sgg_abstractor.Node`
objects and whose EDGES carry a `label`. We can't import the real CARLA classes, so
we remap them to lightweight stand-ins (exactly like the repo's adapter does), then
walk the graph and print what's inside.

USAGE (run inside the repo's conda env, which has networkx):
    python inspect_rsv_pkl.py sceneflow_sample/data/rsv/0.pkl
    python inspect_rsv_pkl.py sceneflow_sample/data/rsv/0.pkl --max-nodes 40 --max-edges 60
"""
from __future__ import annotations
import argparse, pickle, collections
from pathlib import Path
from typing import Any


class SimpleNode:
    """Stand-in for carla_sgg.sgg_abstractor.Node (name, base_class, attr)."""
    def __init__(self, name=None, base_class=None, attr=None):
        self.name = name
        self.base_class = base_class
        self.attr = attr or {}
    def __repr__(self):
        return f"Node({self.name!r}, base_class={self.base_class!r})"


class SimpleCarlaValue:
    """Placeholder for CARLA enum/value objects stored in some node attrs."""
    def __new__(cls, *args, **kw):
        obj = super().__new__(cls)
        obj.args = args
        return obj
    def __repr__(self):
        return "carla_value" if not getattr(self, "args", None) else f"carla_value{self.args!r}"


class _Ignored:
    """Absorbs reconstruction of any class we can't/don't want to import
    (e.g. shapely geometries, CARLA enums). We don't need these values."""
    def __init__(self, *a, **k):
        pass
    def __setstate__(self, state):
        pass
    def __repr__(self):
        return f"<ignored:{getattr(type(self), '_qn', '?')}>"


def _make_stub(qualname: str):
    # Return a real CLASS (not a function) so pickle's NEWOBJ/REDUCE both work.
    return type("Stub_" + qualname.replace(".", "_"), (_Ignored,), {"_qn": qualname})


class SGUnpickler(pickle.Unpickler):
    def persistent_load(self, pid):
        if pid == "please_ignore_me":
            return None
        return super().persistent_load(pid)

    def find_class(self, module, name):
        # our CARLA stand-ins
        if (module, name) in {("__main__", "Node"), ("carla_sgg.sgg_abstractor", "Node")}:
            return SimpleNode
        if module == "carla.libcarla":
            return SimpleCarlaValue
        # everything else: resolve normally, but if the module/class is missing
        # (shapely, extra carla bits, …) substitute a harmless placeholder so we
        # can still read the graph structure, labels, and simple attributes.
        try:
            return super().find_class(module, name)
        except (ModuleNotFoundError, ImportError, AttributeError):
            return _make_stub(f"{module}.{name}")


def load_graph(path: Path):
    with path.open("rb") as f:
        return SGUnpickler(f).load()


def short(v: Any, n: int = 60) -> str:
    s = repr(v)
    return s if len(s) <= n else s[: n - 1] + "…"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("pkl", type=Path)
    ap.add_argument("--max-nodes", type=int, default=25)
    ap.add_argument("--max-edges", type=int, default=40)
    ap.add_argument("--attrs-per-node", type=int, default=8)
    args = ap.parse_args()

    g = load_graph(args.pkl)

    print(f"=== {args.pkl} ===")
    print(f"graph object     : {type(g).__module__}.{type(g).__name__}")
    print(f"# nodes          : {g.number_of_nodes()}")
    print(f"# edges          : {g.number_of_edges()}")
    if getattr(g, "graph", None):
        print(f"graph-level keys : {list(g.graph.keys())}")

    # --- node base_class histogram ---
    base_hist = collections.Counter(getattr(n, "base_class", None) for n in g.nodes)
    print("\n--- node base_class counts ---")
    for k, c in base_hist.most_common():
        print(f"  {str(k):20s} {c}")

    # --- edge label histogram ---
    lab_hist = collections.Counter(
        (d.get("label") if isinstance(d, dict) else None) for _, _, d in g.edges(data=True)
    )
    print("\n--- edge label counts ---")
    for k, c in lab_hist.most_common():
        print(f"  {str(k):20s} {c}")

    # --- a sample of nodes with their attributes ---
    print(f"\n--- sample nodes (up to {args.max_nodes}) ---")
    for i, n in enumerate(g.nodes):
        if i >= args.max_nodes:
            print(f"  … ({g.number_of_nodes() - args.max_nodes} more)")
            break
        name = getattr(n, "name", str(n))
        bc = getattr(n, "base_class", None)
        attr = getattr(n, "attr", {}) or {}
        keys = list(attr.keys())
        print(f"  [{name}]  base_class={bc}  ({len(keys)} attrs)")
        for k in keys[: args.attrs_per_node]:
            print(f"        {k} = {short(attr[k])}")
        if len(keys) > args.attrs_per_node:
            print(f"        … +{len(keys) - args.attrs_per_node} more attr keys: "
                  f"{keys[args.attrs_per_node:args.attrs_per_node+8]}")

    # --- a sample of edges ---
    print(f"\n--- sample edges (up to {args.max_edges}) ---")
    for i, (u, v, d) in enumerate(g.edges(data=True)):
        if i >= args.max_edges:
            print(f"  … ({g.number_of_edges() - args.max_edges} more)")
            break
        un = getattr(u, "name", str(u))
        vn = getattr(v, "name", str(v))
        label = d.get("label") if isinstance(d, dict) else None
        extra = {k: v2 for k, v2 in (d or {}).items() if k != "label"}
        extra_s = f"  {short(extra, 50)}" if extra else ""
        print(f"  {un}  --{label}-->  {vn}{extra_s}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())