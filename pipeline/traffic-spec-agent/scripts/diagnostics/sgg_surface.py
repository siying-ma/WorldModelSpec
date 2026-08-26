"""The generator's attribute surface, derived from `carla_sgg/` source.

Why this exists
---------------
The schema's account of which keys a scene graph carries was originally taken by
loading recorded captures and collecting the keys that appeared. That is
circular evidence — the captures were produced by capture scripts in this
project — and it under-reports: a key written only on a branch our scenarios
never took is invisible to that method, and its absence then reads in the schema
as "the generator does not emit it", which is the direction that wrongly
discards a formalizable law.

This module reads `carla_sgg/*.py` instead, and the CARLA API for the enums the
generator iterates. No capture, no database, no capture script is consulted.
Every entry names the line that writes it, so `run_spec doctor` can re-derive the
surface and fail when the schema and the generator disagree.

Why the parser and not a regular expression
-------------------------------------------
The first version of this module matched assignments with `\\s*=`, which also
matches the first character of `==`. Two comparisons in `sgg_abstractor.py`
therefore read as writes and invented three attribute keys that do not exist. A
negative lookahead fixes that instance, but not the class: `=` inside a string
literal, a keyword default, a walrus and an augmented assignment all look alike
to a regex. `ast` separates an `Assign` from a `Compare` by construction.

The same first version also ignored WHICH node a key was written to, and that
decides whether the key survives: `sgg_abstractor.py` copies `graph.nodes[actor]`
into the RSV node for ACTORS only, so a key written on an actor node reaches the
RSV while one written on a base-graph waypoint node does not — every waypoint of
a lane is collapsed into a single attribute-free lane node. Recovering the index
expression is what separates the two.

What the generator does with attributes
--------------------------------------
`sgg.py::__add_to_graph` creates every actor-like node with a fixed set of
keyword attributes, and is the single funnel every actor, signal, sign, landmark
and scenery path goes through. Type-specific branches then add more. The
abstraction copies the dict WHOLE — `Node(name, base_class, attr=graph.nodes[
actor])`, by reference — so nothing on an actor node is filtered out. Structure
nodes are built as `Node(name=...)` with no `attr`, and the class defaults it to
`{}`, so a lane, road, junction or off-road node carries no attributes at all.
"""

from __future__ import annotations

import ast
from pathlib import Path

# This file lives in `scripts/diagnostics/`, so three hops reach the repo root.
REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Where the generator lives, alongside this repository.
SGG_DIR = REPO_ROOT.parent / "sg" / "carla_scene_graphs" / "carla_sgg"

# Node index expressions that denote an ACTOR node, whose attributes the
# abstraction copies into the RSV.
ACTOR_INDICES = ("actor_name", "'ego'", '"ego"')


def _src(name: str) -> str:
    return (SGG_DIR / name).read_text(encoding="utf-8", errors="replace")


def _tree(name: str) -> ast.AST:
    return ast.parse(_src(name))


def _subscript_assignments(tree: ast.AST) -> list[tuple[str, str, int]]:
    """Every `<container>[<string literal>] = ...` as (container, key, line)."""
    out: list[tuple[str, str, int]] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            targets = node.targets
        elif isinstance(node, ast.AugAssign):
            targets = [node.target]
        else:
            continue
        for t in targets:
            if (isinstance(t, ast.Subscript)
                    and isinstance(t.slice, ast.Constant)
                    and isinstance(t.slice.value, str)):
                try:
                    container = ast.unparse(t.value)
                except Exception:                       # pragma: no cover
                    container = "<unparseable>"
                out.append((container, t.slice.value, t.lineno))
    return out


def vehicle_light_names() -> list[str]:
    """The `light_*` suffixes: the enum the generator iterates.

    One boolean is written per member of `carla.VehicleLightState.names`, so the
    key set is fixed by the CARLA API rather than by any map or scenario. Falls
    back to the member list of the pinned CARLA line when the module is not
    importable, so `doctor` still runs outside the simulator environment.
    """
    try:
        import carla  # type: ignore
        return list(carla.VehicleLightState.names)
    except Exception:
        return ["NONE", "Position", "LowBeam", "HighBeam", "Brake",
                "RightBlinker", "LeftBlinker", "Reverse", "Fog", "Interior",
                "Special1", "Special2", "All"]


def add_to_graph_attrs() -> dict[str, int]:
    """The keyword attributes every actor-like node is created with."""
    for node in ast.walk(_tree("sgg.py")):
        if (isinstance(node, ast.Call)
                and isinstance(node.func, ast.Attribute)
                and node.func.attr == "add_node"
                and node.args
                and isinstance(node.args[0], ast.Name)
                and node.args[0].id == "actor_name"):
            return {kw.arg: node.lineno for kw in node.keywords if kw.arg}
    return {}


def direct_writes() -> dict[str, tuple[str, str]]:
    """Keys written directly onto a node, classified by which node."""
    out: dict[str, tuple[str, str]] = {}
    for fname in ("sgg.py", "sgg_abstractor.py"):
        for container, key, lineno in _subscript_assignments(_tree(fname)):
            on_node = ".nodes[" in container
            on_rsv = container.endswith(".attr")
            if not (on_node or on_rsv):
                continue
            scope = ("actor"
                     if on_rsv or any(a in container for a in ACTOR_INDICES)
                     else "base_graph_only")
            out[key] = (f"{fname}:{lineno}", scope)
    return out


def helper_writes() -> dict[str, str]:
    """Keys written by `copy_carla_control` / `copy_carla_actor_state`.

    Both are called on the ego node alone, which is the whole basis for every
    EGO ONLY marking in the schema — a property of the call site.
    """
    out: dict[str, str] = {}
    for fn in ast.walk(_tree("sgg.py")):
        if not (isinstance(fn, ast.FunctionDef)
                and fn.name in ("copy_carla_control", "copy_carla_actor_state")):
            continue
        for container, key, lineno in _subscript_assignments(fn):
            if container == "attr_dict":
                out[key] = f"sgg.py:{lineno}"
        # `copy_vector(attr_dict, '<prefix>', v)` fans one call out into _x/_y/_z
        for node in ast.walk(fn):
            if (isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Name)
                    and node.func.id == "copy_vector"
                    and len(node.args) >= 2
                    and isinstance(node.args[1], ast.Constant)):
                for axis in ("x", "y", "z"):
                    out[f"{node.args[1].value}_{axis}"] = \
                        f"sgg.py:{node.lineno} copy_vector"
    return out


def surface() -> dict[str, list[str]]:
    """Every attribute key an RSV actor-like node can carry -> where it is set."""
    keys: dict[str, list[str]] = {}
    for k, lineno in add_to_graph_attrs().items():
        keys.setdefault(k, []).append(f"sgg.py:{lineno} __add_to_graph")
    for k, (where, scope) in direct_writes().items():
        if scope == "actor":
            keys.setdefault(k, []).append(where)
    for k, where in helper_writes().items():
        keys.setdefault(k, []).append(where)
    for name in vehicle_light_names():
        keys.setdefault(f"light_{name}", []).append(
            "sgg.py, per carla.VehicleLightState.names")
    return dict(sorted(keys.items()))


def base_graph_only_keys() -> dict[str, str]:
    """Keys the BASE graph carries that the RSV cannot.

    Written on waypoint nodes, which the abstraction collapses into one
    attribute-free lane node. Not reachable by extending carla/adapter.py — only
    by choosing a different abstraction.
    """
    return {k: where for k, (where, scope) in direct_writes().items()
            if scope == "base_graph_only"}


# Functions whose keyword arguments are the generator's caller-supplied
# settings. Anything a caller can change is something a capture this pipeline
# did not produce may have changed, so this list bounds what
# `capture_preconditions` must account for — the section is then complete over
# the generator's own signature rather than over the settings someone thought of.
PARAMETER_SITES = (
    ("sgg.py", "__initialization"),
    ("sgg.py", "init_to_world"),
    ("sgg.py", "generate_graph_for_frame"),
    ("sgg_abstractor.py", "process_to_junction_rsv"),
)

# Positional arguments that are inputs rather than settings.
NOT_SETTINGS = ("self", "cls", "graph", "carla_client", "frame_num")


def parameters() -> dict[str, str]:
    """Every caller-supplied generator parameter -> `file:line function`."""
    out: dict[str, str] = {}
    for fname, fn in PARAMETER_SITES:
        for node in ast.walk(_tree(fname)):
            if not (isinstance(node, ast.FunctionDef) and node.name == fn):
                continue
            a = node.args
            for arg in list(a.posonlyargs) + list(a.args) + list(a.kwonlyargs):
                if arg.arg not in NOT_SETTINGS:
                    out[arg.arg] = f"{fname}:{node.lineno} {fn}"
    return out


if __name__ == "__main__":
    s = surface()
    print(f"{len(s)} RSV attribute keys derived from {SGG_DIR}\n")
    for k, where in s.items():
        print(f"  {k:<34} {where[0]}")
    bg = base_graph_only_keys()
    print(f"\n{len(bg)} keys on BASE-graph waypoint nodes only "
          f"(collapsed by the abstraction):")
    for k, where in sorted(bg.items()):
        print(f"  {k:<34} {where}")
    ps = parameters()
    print(f"\n{len(ps)} caller-supplied parameters:")
    for k, where in sorted(ps.items()):
        print(f"  {k:<34} {where}")
