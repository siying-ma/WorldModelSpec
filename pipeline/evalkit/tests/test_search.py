"""Tests for the parameter search, with a mock simulator.

The mock is a *function* of the spec by construction, which is the property the
real simulator has to be made to have and which `verify_determinism` checks.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from evalkit.evaluate import COMPLIANT, NOT_APPLICABLE, VIOLATED
from evalkit.facts import SIM, FactTrack, Frame
from evalkit.reading import load_readings
from evalkit.search import (ScenarioSpec, bisect_pair, find_witness,
                            plan_campaign, verify_determinism)

FPS = 20
READINGS = dict((r.id, r) for r in load_readings(
    os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                 "readings", "bc_mva_part3.jsonl")))

PROV = {"ego.speed_mps": SIM, "ego.speed_kph": SIM, "ego.lane.on_road": SIM,
        "ego.lane.is_junction": SIM, "ego.lead.present": SIM,
        "ego.lead.headway_s": SIM, "ego.posted.speed_limit_kph": SIM,
        "ego.lane.wrong_way": SIM, "ego.lane.lanes_to_right": SIM,
        "ego.posted.stop_ahead_m": SIM, "ego.posted.crosswalk_ahead_m": SIM,
        "signal.state": SIM, "signal.governs_ego_lane": SIM,
        "actor.rel.centre_distance_m": SIM, "actor.is_emergency": SIM,
        "actor.emergency_lights_on": SIM, "actor.rel.heading_dot": SIM,
        "actor.rel.longitudinal_m": SIM, "actor.rel.lateral_m": SIM,
        "actor.cls": SIM, "actor.rel.ahead": SIM}


def follow_sim(spec, n=200):
    """Mock: the ego follows a lead at a constant headway given by the spec.

    Deliberately continuous in the knob, so the bisection has a real boundary to
    find rather than a step the mock put there on purpose.
    """
    headway = spec.params["headway_s"]
    speed = spec.params.get("speed_mps", 10.0)
    frames = []
    for i in range(n):
        ego = {"speed_mps": speed, "speed_kph": speed * 3.6,
               "lane": {"on_road": True, "is_junction": False,
                        "wrong_way": False, "lanes_to_right": 0},
               "posted": {"speed_limit_kph": None},
               "lead": {"present": True, "headway_s": headway}}
        frames.append(Frame(i, i / float(FPS), ego, None, []))
    return FactTrack(spec.key()[:24], FPS, frames, dict(PROV))


def speed_sim(spec, n=200):
    v = spec.params["speed_kph"]
    frames = []
    for i in range(n):
        ego = {"speed_mps": v / 3.6, "speed_kph": v,
               "lane": {"on_road": True, "is_junction": False,
                        "wrong_way": False, "lanes_to_right": 0},
               "posted": {"speed_limit_kph": None},
               "lead": {"present": False, "headway_s": None}}
        frames.append(Frame(i, i / float(FPS), ego, None, []))
    return FactTrack(spec.key()[:24], FPS, frames, dict(PROV))


def base(template="follow", **params):
    return ScenarioSpec(template, "site_0", params)


# ------------------------------------------------------------------ bisection

def test_bisection_finds_the_statutory_boundary_without_being_told_it():
    """BC-MVA-162-1 quantifies 'reasonable and prudent' as a 2.0 s headway.
    The search is never given that number; it is given a bracket and the label
    function, and it has to land on it."""
    result = bisect_pair(READINGS["BC-MVA-162-1"], base(headway_s=0.0),
                         "headway_s", low=0.5, high=6.0, simulate=follow_sim,
                         tolerance=0.02)
    assert result.two_sided, result.reason
    assert abs(result.flip_value - 2.0) < 0.05, result.flip_value
    assert result.violating.params["headway_s"] < 2.0
    assert result.compliant.params["headway_s"] > 2.0
    assert result.runs <= 14


def test_bisection_is_logarithmic_not_linear():
    result = bisect_pair(READINGS["BC-MVA-162-1"], base(headway_s=0.0),
                         "headway_s", 0.5, 6.0, follow_sim, tolerance=0.02)
    # log2(5.5/0.02) ≈ 8.1, plus the two bracket probes
    assert result.runs <= 12, result.runs


def test_speed_boundary_lands_on_the_posted_default():
    result = bisect_pair(READINGS["BC-MVA-146-1"], base("speed", speed_kph=0.0),
                         "speed_kph", 10.0, 120.0, speed_sim, tolerance=0.5)
    assert result.two_sided, result.reason
    assert abs(result.flip_value - 50.0) < 1.0, result.flip_value


# --------------------------------------------------------- refusal to converge

def test_unbracketed_search_reports_instead_of_returning_an_endpoint():
    """Both ends compliant: an unguarded bisection would return the endpoint and
    look converged."""
    result = bisect_pair(READINGS["BC-MVA-162-1"], base(headway_s=0.0),
                         "headway_s", 3.0, 6.0, follow_sim)
    assert not result.two_sided
    assert "does not straddle" in result.reason


def test_never_applicable_is_distinguished_from_no_pair_found():
    def no_lead(spec, n=100):
        track = follow_sim(spec, n)
        for f in track.frames:
            f.ego["lead"] = {"present": False, "headway_s": None}
        return track
    result = bisect_pair(READINGS["BC-MVA-162-1"], base(headway_s=0.0),
                         "headway_s", 0.5, 6.0, no_lead)
    assert not result.two_sided
    assert "antecedent never engages" in result.reason


def test_untestable_is_reported_as_a_recording_problem():
    def missing_field(spec, n=60):
        track = follow_sim(spec, n)
        track.provenance["ego.lane.wrong_way"] = "absent"
        return track
    result = bisect_pair(READINGS["BC-MVA-150-1"], base(headway_s=1.0),
                         "headway_s", 0.5, 6.0, missing_field)
    assert not result.two_sided
    assert "UNTESTABLE" in result.reason


# -------------------------------------------------------------- categorical

def test_find_witness_stops_as_soon_as_both_sides_are_seen():
    calls = {"n": 0}

    def sim(spec):
        calls["n"] += 1
        return speed_sim(spec)
    specs = [base("speed", speed_kph=v) for v in (20.0, 90.0, 30.0, 80.0)]
    result = find_witness(READINGS["BC-MVA-146-1"], specs, sim)
    assert result.two_sided
    assert calls["n"] == 2       # stops at the first pair, does not enumerate


# ------------------------------------------------------------- determinism

def test_determinism_check_catches_a_noisy_simulator():
    ok = verify_determinism(base(headway_s=1.5), follow_sim)
    assert ok["deterministic"] and ok["max_position_drift_m"] == 0.0

    state = {"n": 0}

    def jittery(spec):
        state["n"] += 1
        track = follow_sim(spec, 60)
        for f in track.frames:
            f.ego["x"] = state["n"] * 1.0
            f.ego["y"] = 0.0
        return track
    bad = verify_determinism(base(headway_s=1.5), jittery)
    assert not bad["deterministic"]
    assert "converges to noise" in bad["reason"]


# --------------------------------------------------------------- campaign

def test_campaign_plan_names_a_template_or_says_why_it_cannot():
    templates = {
        "following": {"name": "longitudinal", "knob": "headway_s",
                      "bracket": [0.3, 6.0], "site_tags": ["straight_multilane"]},
        "speed": {"name": "cruise", "knob": "speed_kph", "bracket": [10, 120],
                  "site_tags": ["straight_multilane"]},
    }
    sites = {"straight_multilane": ["Town03:site_%d" % i for i in range(5)]}
    plan = plan_campaign(list(READINGS.values()), sites, templates)
    planned = set(j["reading"] for j in plan["jobs"])
    assert "BC-MVA-162-1" in planned
    assert plan["total_runs_estimate"] > 0
    # Obligations with no matching template are named, not silently dropped.
    assert any(u["reading"] == "BC-MVA-129-1" for u in plan["unplannable"])


def _run_all():
    failures = 0
    for name, fn in sorted(globals().items()):
        if not name.startswith("test_") or not callable(fn):
            continue
        try:
            fn()
            print("  ok    %s" % name)
        except Exception as exc:                        # noqa: BLE001
            failures += 1
            print("  FAIL  %s: %s: %s" % (name, type(exc).__name__, exc))
    print("\n%d failed" % failures if failures else "\nall tests passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(_run_all())
