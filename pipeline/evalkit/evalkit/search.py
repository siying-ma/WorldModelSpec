"""Generating the corpus without setting parameters by hand.

The idea
--------
Nobody authors a scenario. Three things are authored once, and a search does the
rest:

  1. a MAP INDEX  — every place in a town where a situation class can physically
                    occur, computed offline from OpenDRIVE (see `sites.py`);
  2. a TEMPLATE   — a manoeuvre with a typed parameter vector and a scripted
                    controller, five or six of which cover most of a statute;
  3. an OBJECTIVE — the derived label itself.

The third is the part that makes this work. Because `evaluate.label_one` is a
cheap, fully automatic function of a trace, it can sit INSIDE the generation
loop. You do not need a person to say whether a generated run came out compliant
or violating: you run it, derive the label, and keep it if it landed where you
wanted. **The labelling pipeline and the generation pipeline are the same loop.**

Why bisection rather than sampling
----------------------------------
A corpus of unambiguous cases cannot falsify a threshold — every capture agrees
with a rule that is off by a factor of two, because none lies between the two
answers. What discriminates is a pair that straddles the legal boundary as
narrowly as the simulator can resolve. Binary search finds that pair in
`log2(range/tolerance)` runs, which is 8-12 for any realistic range, and it
finds it *without anyone knowing in advance where the boundary is* — which is
the point, since where it lands is exactly what the evaluation wants to measure.

The empirical flip point is also a result in its own right: compare it to the
statutory value and you have measured whether the formalization put its
threshold where the law puts it, with no annotation anywhere.

Determinism is a precondition, not a nicety
-------------------------------------------
Bisection assumes `simulate` is a function. In CARLA that holds only under
synchronous mode with a fixed delta, a seeded Traffic Manager, a fixed actor
spawn order, and a scripted ego controller rather than autopilot. `verify_determinism`
checks it instead of assuming it; a search over a noisy simulator converges to
noise.
"""

from __future__ import annotations

import json
from typing import Any, Callable, Dict, List, Optional, Sequence, Tuple

from .evaluate import (COMPLIANT, NOT_APPLICABLE, UNTESTABLE, VIOLATED,
                       label_one)


class ScenarioSpec(object):
    """One fully-determined run. Everything a simulator needs, and nothing else.

    A spec is a value: two specs that compare equal must produce the same trace.
    That is what makes a cached corpus re-derivable and a search reproducible.
    """

    def __init__(self, template, site, params, seed=0, duration_s=20.0,
                 town=None, notes=None):
        # type: (str, str, Dict[str, float], int, float, Optional[str], Optional[dict]) -> None
        self.template = template
        self.site = site
        self.params = dict(params)
        self.seed = seed
        self.duration_s = duration_s
        self.town = town
        self.notes = notes or {}

    def with_param(self, key, value):
        # type: (str, float) -> ScenarioSpec
        params = dict(self.params)
        params[key] = value
        return ScenarioSpec(self.template, self.site, params, self.seed,
                            self.duration_s, self.town, dict(self.notes))

    def key(self):
        # type: () -> str
        return json.dumps({"template": self.template, "site": self.site,
                           "params": self.params, "seed": self.seed,
                           "duration_s": self.duration_s, "town": self.town},
                          sort_keys=True)

    def as_dict(self):
        return {"template": self.template, "site": self.site,
                "params": self.params, "seed": self.seed,
                "duration_s": self.duration_s, "town": self.town,
                "notes": self.notes}

    def __repr__(self):
        return "ScenarioSpec(%s@%s, %s)" % (
            self.template, self.site,
            ", ".join("%s=%g" % kv for kv in sorted(self.params.items())))


class SearchResult(object):
    def __init__(self, reading_id, compliant=None, violating=None,
                 flip_value=None, runs=0, log=None, reason=""):
        self.reading_id = reading_id
        self.compliant = compliant      # type: Optional[ScenarioSpec]
        self.violating = violating      # type: Optional[ScenarioSpec]
        self.flip_value = flip_value    # type: Optional[float]
        self.runs = runs
        self.log = log or []
        self.reason = reason

    @property
    def two_sided(self):
        return self.compliant is not None and self.violating is not None

    def as_dict(self):
        return {"reading": self.reading_id, "two_sided": self.two_sided,
                "flip_value": self.flip_value, "runs": self.runs,
                "reason": self.reason,
                "compliant": self.compliant.as_dict() if self.compliant else None,
                "violating": self.violating.as_dict() if self.violating else None,
                "log": self.log}


def _verdict(reading, track):
    return label_one(reading, track).verdict


def bisect_pair(reading, base_spec, knob, low, high, simulate,
                tolerance=None, max_runs=14):
    # type: (Any, ScenarioSpec, str, float, float, Callable, Optional[float], int) -> SearchResult
    """Find the narrowest compliant/violating pair by bisecting one parameter.

    `knob` is the single component of the parameter vector that the obligation's
    threshold is monotone in — a following gap, an approach speed, a lateral
    offset. `low` and `high` must bracket the boundary; the search verifies
    that they do rather than trusting it, because an unbracketed bisection
    silently returns the endpoint and looks like a converged answer.

    Returns the two specs that straddle the flip and the empirical flip value.
    """
    tolerance = tolerance if tolerance is not None else abs(high - low) / 100.0
    log = []
    runs = 0

    def verdict_at(value):
        nonlocal runs
        spec = base_spec.with_param(knob, value)
        track = simulate(spec)
        runs += 1
        v = _verdict(reading, track)
        log.append({"run": runs, knob: value, "verdict": v})
        return spec, v

    lo_spec, lo_v = verdict_at(low)
    hi_spec, hi_v = verdict_at(high)

    # Untestable or never-applicable endpoints are not a failed search, they are
    # a different finding, and reporting them as "no pair found" would send
    # someone hunting for a parameter when the obligation cannot be witnessed
    # at this site at all.
    for value, v in ((low, lo_v), (high, hi_v)):
        if v == UNTESTABLE:
            return SearchResult(reading.id, runs=runs, log=log,
                                reason="obligation is UNTESTABLE on this "
                                       "capture: a fact it reads is not recorded")
    if lo_v == NOT_APPLICABLE and hi_v == NOT_APPLICABLE:
        return SearchResult(reading.id, runs=runs, log=log,
                            reason="antecedent never engages anywhere in "
                                   "[%g, %g]; wrong site or wrong template"
                                   % (low, high))
    if lo_v == hi_v:
        return SearchResult(reading.id, runs=runs, log=log,
                            reason="bracket does not straddle a flip: both "
                                   "ends are %r. Widen [%g, %g]."
                                   % (lo_v, low, high))

    good_v, bad_v = (lo_v, hi_v)
    good, bad = low, high
    good_spec, bad_spec = lo_spec, hi_spec

    while abs(bad - good) > tolerance and runs < max_runs:
        mid = (good + bad) / 2.0
        spec, v = verdict_at(mid)
        if v == good_v:
            good, good_spec = mid, spec
        elif v == bad_v:
            bad, bad_spec = mid, spec
        else:
            # A third verdict appeared mid-bracket — usually NOT_APPLICABLE,
            # meaning the antecedent stops engaging partway. Stop rather than
            # pretend the interval is still monotone.
            return SearchResult(reading.id, runs=runs, log=log,
                                reason="verdict %r appeared at %s=%g, so the "
                                       "bracket is not monotone" % (v, knob, mid))

    compliant = good_spec if good_v == COMPLIANT else bad_spec
    violating = bad_spec if bad_v == VIOLATED else good_spec
    if COMPLIANT not in (good_v, bad_v) or VIOLATED not in (good_v, bad_v):
        return SearchResult(reading.id, runs=runs, log=log,
                            reason="flip is between %r and %r, not between "
                                   "compliant and violated" % (good_v, bad_v))
    return SearchResult(reading.id, compliant=compliant, violating=violating,
                        flip_value=(good + bad) / 2.0, runs=runs, log=log,
                        reason="converged")


def find_witness(reading, specs, simulate, want=None, max_runs=40):
    # type: (Any, Sequence[ScenarioSpec], Callable, Optional[str], int) -> SearchResult
    """Search a candidate list for a spec that witnesses an obligation.

    Used for obligations with no numeric knob to bisect — a red-light entry, a
    wrong-way excursion — where the question is categorical: does any site and
    parameter combination make the antecedent engage, and can both outcomes be
    produced. Candidates come from the map index crossed with a template's
    discrete options, so this enumerates rather than guesses.
    """
    log = []
    compliant = violating = None
    runs = 0
    for spec in specs:
        if runs >= max_runs:
            break
        track = simulate(spec)
        runs += 1
        v = _verdict(reading, track)
        log.append({"run": runs, "site": spec.site, "verdict": v})
        if v == COMPLIANT and compliant is None:
            compliant = spec
        elif v == VIOLATED and violating is None:
            violating = spec
        if compliant is not None and violating is not None:
            break
    reason = "converged" if (compliant and violating) else (
        "searched %d candidates; found%s%s" % (
            runs,
            " a compliant witness" if compliant else " no compliant witness",
            " and a violating witness" if violating else " and no violating witness"))
    return SearchResult(reading.id, compliant=compliant, violating=violating,
                        runs=runs, log=log, reason=reason)


def verify_determinism(spec, simulate, repeats=3, tolerance_m=0.05):
    # type: (ScenarioSpec, Callable, int, float) -> dict
    """Run one spec several times and measure whether the traces agree.

    Bisection treats `simulate` as a function; if it is not, the search
    converges to simulator noise and the resulting "boundary" is meaningless.
    CARLA is deterministic only under synchronous mode with a fixed delta, a
    seeded Traffic Manager, a fixed spawn order and a scripted ego. This checks
    that rather than assuming it, and it is cheap: three runs per template, once.
    """
    tracks = [simulate(spec) for _ in range(repeats)]
    lengths = sorted(set(len(t) for t in tracks))
    if len(lengths) > 1:
        return {"deterministic": False, "reason": "frame counts differ: %s"
                % lengths, "max_position_drift_m": None}
    drift = 0.0
    reference = tracks[0]
    for other in tracks[1:]:
        for a, b in zip(reference.frames, other.frames):
            dx = (a.ego.get("x") or 0.0) - (b.ego.get("x") or 0.0)
            dy = (a.ego.get("y") or 0.0) - (b.ego.get("y") or 0.0)
            drift = max(drift, (dx * dx + dy * dy) ** 0.5)
    return {"deterministic": drift <= tolerance_m,
            "max_position_drift_m": drift,
            "repeats": repeats,
            "reason": ("agrees to %.3f m" % drift) if drift <= tolerance_m
                      else ("diverges by %.3f m — bisection over this simulator "
                            "converges to noise" % drift)}


def plan_campaign(readings, sites_by_tag, templates, budget_runs=None):
    # type: (List[Any], Dict[str, List[str]], Dict[str, dict], Optional[int]) -> dict
    """Turn a readings file into a list of searches to run, with a cost estimate.

    This is the artifact that replaces hand-authoring: for each obligation it
    names the template, the map sites its antecedent can occur at, the knob to
    bisect and the bracket — all looked up from the reading's own tags rather
    than chosen per scenario.
    """
    jobs = []
    unplannable = []
    for reading in readings:
        template = None
        for tag in reading.tags:
            if tag in templates:
                template = templates[tag]
                break
        if template is None:
            unplannable.append({"reading": reading.id,
                                "reason": "no template matches tags %s"
                                          % (reading.tags,)})
            continue
        sites = []
        for tag in template.get("site_tags", []):
            sites.extend(sites_by_tag.get(tag, []))
        if not sites:
            unplannable.append({"reading": reading.id,
                                "reason": "no map site with tags %s"
                                          % (template.get("site_tags"),)})
            continue
        knob = template.get("knob")
        # log2(range/tolerance) plus the two bracket probes; 14 is the cap in
        # `bisect_pair`, and a categorical search enumerates instead.
        per_site = 12 if knob else min(len(sites), 8)
        jobs.append({"reading": reading.id, "template": template["name"],
                     "knob": knob, "bracket": template.get("bracket"),
                     "sites": sites[:3], "runs_estimate": per_site * min(len(sites), 3)})
    total = sum(j["runs_estimate"] for j in jobs)
    return {"jobs": jobs, "unplannable": unplannable,
            "total_runs_estimate": total,
            "within_budget": None if budget_runs is None else total <= budget_runs}
