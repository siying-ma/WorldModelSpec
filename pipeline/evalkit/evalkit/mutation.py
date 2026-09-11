"""Label-free dataset quality: can this corpus tell a right rule from a wrong one?

The question this answers
-------------------------
Detection metrics score the monitor. They say nothing about whether the corpus
is capable of scoring it. A corpus of unambiguous cases — every following
episode at 40 m, every speed either 20 or 90 km/h — will award a perfect F1 to a
rule whose threshold is off by a factor of two, because no capture lies between
the two answers. That corpus has no discriminating power and no metric computed
from it will say so.

Mutation testing says so, and needs no labels at all. Perturb a constant in a
reading, re-derive the labels, and ask whether any capture's verdict changed. If
none did, the corpus cannot distinguish the original constant from the mutant:
the constant is *unpinned by the data*, and any agreement the monitor scored on
it is luck.

This is the metric to report first while the dataset is the thing being built.
It is computable on day one, before a single monitor exists, and it points
directly at which scenario to record next: the mutants that survive name the
parameter values the corpus is missing.

Relation to boundary sweeping
-----------------------------
A surviving mutant is a request for a capture near that threshold. Generating
one is `corpus`-side work; killing it is what makes the corpus discriminating.
The two together form the loop that turns a smoke test into an evaluation.
"""

from __future__ import annotations

import copy
import json
from typing import Any, Callable, Dict, Iterator, List, Optional, Tuple

from .evaluate import label_capture


def _walk_numbers(node, path=()):
    # type: (Any, tuple) -> Iterator[Tuple[tuple, float]]
    """Every numeric literal in an expression, with the route to it."""
    if isinstance(node, bool):
        return
    if isinstance(node, (int, float)):
        yield path, float(node)
    elif isinstance(node, list):
        for i, item in enumerate(node):
            for found in _walk_numbers(item, path + (i,)):
                yield found
    elif isinstance(node, dict):
        for key in sorted(node):
            if key == "lit":
                continue
            for found in _walk_numbers(node[key], path + (key,)):
                yield found


def _set_at(node, path, value):
    # type: (Any, tuple, Any) -> None
    for step in path[:-1]:
        node = node[step]
    node[path[-1]] = value


def mutants(reading, factors=(0.5, 0.8, 1.25, 2.0)):
    # type: (Any, tuple) -> List[Tuple[str, Any]]
    """Scaled variants of each numeric constant in a reading.

    Multiplicative rather than additive, because the constants span metres,
    seconds and km/h and a fixed delta would be a rounding error in one and a
    sign change in another. The factors bracket the plausible mis-reading range:
    a doubled or halved threshold is what a genuine misinterpretation of a
    clause produces, and 0.8/1.25 catch a corpus that only separates gross
    errors.
    """
    out = []
    for where, expr in (("applies_when", reading.applies_when),
                        ("violated_when", reading.violated_when)):
        for path, value in _walk_numbers(expr):
            if value == 0:
                continue
            for factor in factors:
                mutated = copy.deepcopy(reading)
                target = (mutated.applies_when if where == "applies_when"
                          else mutated.violated_when)
                _set_at(target, path, value * factor)
                name = "%s:%s=%g->%g" % (where, ".".join(str(p) for p in path),
                                         value, value * factor)
                out.append((name, mutated))
    return out


def kill_report(reading, tracks, factors=(0.5, 0.8, 1.25, 2.0)):
    # type: (Any, List[Any], tuple) -> dict
    """Which mutants of one reading the corpus can detect.

    A mutant is KILLED when it produces a different verdict, or materially
    different violation onsets, on at least one capture. It SURVIVES otherwise,
    and a surviving mutant is a hole in the corpus, not in the reading.
    """
    baseline = {}
    for track in tracks:
        label = label_capture([reading], track)[reading.id]
        baseline[track.capture] = (label.verdict, tuple(label.onsets))

    killed, survived = [], []
    for name, mutant in mutants(reading, factors):
        differs_on = []
        for track in tracks:
            label = label_capture([mutant], track)[mutant.id]
            if (label.verdict, tuple(label.onsets)) != baseline[track.capture]:
                differs_on.append(track.capture)
        if differs_on:
            killed.append({"mutant": name, "detected_on": differs_on[:5],
                           "n_captures": len(differs_on)})
        else:
            survived.append(name)

    total = len(killed) + len(survived)
    return {
        "reading": reading.id,
        "mutants": total,
        "killed": len(killed),
        "survived": len(survived),
        "mutation_score": (len(killed) / float(total)) if total else None,
        "killed_detail": killed,
        "surviving_mutants": survived,
        "baseline_verdicts": dict((k, v[0]) for k, v in baseline.items()),
    }


def corpus_mutation_report(readings, tracks, factors=(0.5, 0.8, 1.25, 2.0)):
    # type: (List[Any], List[Any], tuple) -> dict
    reports = [kill_report(r, tracks, factors) for r in readings]
    scored = [r for r in reports if r["mutation_score"] is not None]
    overall = (sum(r["killed"] for r in scored)
               / float(sum(r["mutants"] for r in scored))) if scored else None
    return {
        "captures": len(tracks),
        "readings": len(readings),
        "overall_mutation_score": overall,
        "per_reading": reports,
        "interpretation": (
            "A surviving mutant names a constant this corpus cannot pin down. "
            "It is a request for a capture near that threshold, not a defect in "
            "the reading."),
    }
