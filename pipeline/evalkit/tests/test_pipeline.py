"""Unit tests. Run: python -m pytest tests/ -q   (or python tests/test_pipeline.py)

Everything here uses a synthetic fact track, so the semantics of the expression
language and the metrics are pinned independently of any capture, simulator or
scene graph. A test that needs CARLA is not a unit test.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from evalkit.evaluate import (COMPLIANT, NOT_APPLICABLE, UNTESTABLE, VIOLATED,
                              intervals, label_one)
from evalkit.facts import (ABSENT, DERIVED, SG, SIM, FactTrack, Frame,
                           finite_difference_speed, unwrap_degrees)
from evalkit.metrics import (RuleScore, coverage, latency_factor,
                             match_intervals, monitor_score, score_corpus)
from evalkit.reading import Reading, evaluate_track, referenced_paths
from evalkit.mutation import kill_report, mutants

FPS = 20
ALL_SIM = {}


def track(speeds, fps=FPS, actors_per_frame=None, junction=None,
          provenance=None, capture="synthetic"):
    """A fact track with a speed profile and optional actors/junction flags."""
    frames = []
    for i, speed in enumerate(speeds):
        ego = {
            "speed_mps": speed, "speed_kph": speed * 3.6,
            "lane": {"on_road": True, "is_junction":
                     bool(junction[i]) if junction else False,
                     "wrong_way": False, "lanes_to_right": 0},
            "posted": {"speed_limit_kph": None},
            "lead": {"present": False, "headway_s": None},
        }
        frames.append(Frame(i, i / float(fps), ego, None,
                            (actors_per_frame or {}).get(i, [])))
    prov = {"ego.speed_kph": SIM, "ego.speed_mps": SIM,
            "ego.lane.on_road": SIM, "ego.lane.is_junction": SIM,
            "ego.lane.wrong_way": SIM, "ego.lane.lanes_to_right": SIM,
            "ego.posted.speed_limit_kph": SIM,
            "ego.lead.present": SIM, "ego.lead.headway_s": SIM}
    prov.update(provenance or {})
    return FactTrack(capture, fps, frames, prov)


def reading(applies, violated, rid="R"):
    return Reading(rid, "TEST", "test", "test", applies, violated)


# ---------------------------------------------------------------- intervals

def test_intervals_inclusive_and_maximal():
    assert intervals([False, True, True, False, True]) == [(1, 2), (4, 4)]
    assert intervals([True, True]) == [(0, 1)]
    assert intervals([False, False]) == []


# --------------------------------------------------------- three-valued core

def test_missing_value_is_unknown_not_false():
    """The property the whole design rests on: a gap must not read as
    compliance. `posted.speed_limit_kph` is None here, so the comparison is
    UNKNOWN and the frame is neither applicable nor a violation."""
    t = track([10.0] * 5)
    values = evaluate_track({"gt": ["ego.speed_kph", "ego.posted.speed_limit_kph"]}, t)
    assert values == [None] * 5


def test_kleene_and_short_circuits_to_false():
    t = track([10.0] * 3)
    expr = {"all": [{"gt": ["ego.speed_kph", 1000.0]},
                    {"gt": ["ego.speed_kph", "ego.posted.speed_limit_kph"]}]}
    # one conjunct is definitely False, so the unknown one cannot rescue it
    assert evaluate_track(expr, t) == [False] * 3


def test_untestable_beats_not_applicable():
    """A field the capture cannot supply yields UNTESTABLE, which is a claim
    about the recording, not NOT_APPLICABLE, which is a claim about the world."""
    t = track([10.0] * 5, provenance={"ego.lane.wrong_way": ABSENT})
    label = label_one(reading("ego.lane.on_road",
                              {"sustained": [0.1, "ego.lane.wrong_way"]}), t)
    assert label.verdict == UNTESTABLE
    assert label.untestable_paths == ["ego.lane.wrong_way"]


# ------------------------------------------------------------------ temporal

def test_sustained_closes_its_window_at_the_end():
    """A 0.5 s window at 20 Hz is 10 frames. Speeding starts at frame 5, so the
    window first closes at frame 14 -- which is the instant the obligation is
    actually breached and the instant a monitor should alarm."""
    speeds = [5.0] * 5 + [20.0] * 20
    t = track(speeds)
    values = evaluate_track({"sustained": [0.5, {"gt": ["ego.speed_kph", 50.0]}]}, t)
    assert values[13] is False
    assert values[14] is True


def test_sustained_is_false_not_unknown_at_the_start_of_a_trace():
    t = track([20.0] * 4)
    values = evaluate_track({"sustained": [1.0, {"gt": ["ego.speed_kph", 1.0]}]}, t)
    assert all(v is False for v in values)


def test_onset_fires_once_per_transition():
    t = track([0.0] * 6, junction=[0, 0, 1, 1, 0, 1])
    values = evaluate_track({"onset": "ego.lane.is_junction"}, t)
    assert [bool(v) for v in values] == [False, False, True, False, False, True]


def test_ever_before_is_monotone():
    t = track([10.0, 10.0, 0.0, 10.0, 10.0])
    values = evaluate_track({"ever_before": {"lt": ["ego.speed_mps", 1.0]}}, t)
    assert [bool(v) for v in values] == [False, False, True, True, True]


def test_within_off_the_end_of_the_trace_is_unknown():
    """A capture that simply ended must not convict a driver of never doing the
    thing the clause required."""
    t = track([0.0] * 3)
    values = evaluate_track({"within": [5.0, {"gt": ["ego.speed_mps", 99.0]}]}, t)
    assert values[-1] is None


# ------------------------------------------------------------------- actors

def test_exists_actor_binds_actor_paths():
    actors = {2: [{"cls": "car", "rel": {"centre_distance_m": 3.0}}],
              3: [{"cls": "car", "rel": {"centre_distance_m": 30.0}}]}
    t = track([10.0] * 4, actors_per_frame=actors)
    expr = {"exists_actor": {"lt": ["actor.rel.centre_distance_m", 5.0]}}
    assert [bool(v) for v in evaluate_track(expr, t)] == [False, False, True, False]


# ------------------------------------------------------------------- labels

def test_verdicts_and_gating():
    speeds = [5.0] * 10 + [20.0] * 20 + [5.0] * 10
    t = track(speeds)
    r = reading({"gt": ["ego.speed_kph", 0.5]},
                {"sustained": [0.25, {"gt": ["ego.speed_kph", 50.0]}]})
    label = label_one(r, t)
    assert label.verdict == VIOLATED
    assert len(label.violations) == 1
    assert label.onsets[0] == 14        # 10 + 5 frames of window - 1

    calm = label_one(r, track([5.0] * 40))
    assert calm.verdict == COMPLIANT

    stopped = label_one(r, track([0.0] * 40))
    assert stopped.verdict == NOT_APPLICABLE


def test_violation_is_gated_by_the_antecedent():
    """A breach outside the clause's scope is not a breach."""
    t = track([100.0] * 20)
    r = reading("ego.lane.is_junction", {"gt": ["ego.speed_kph", 1.0]})
    assert label_one(r, t).verdict == NOT_APPLICABLE


# ------------------------------------------------------------------ metrics

def test_match_respects_onset_tolerance():
    truth = [(100, 200)]
    assert match_intervals(truth, [(105, 210)], FPS, 1.0)["tp"] == 1
    late = match_intervals(truth, [(150, 210)], FPS, 1.0)
    assert late["tp"] == 0 and late["fn"] == 1 and late["fp"] == 1


def test_latency_is_signed_and_early_alarms_are_free():
    result = match_intervals([(100, 200)], [(110, 190)], FPS, 1.0)
    assert abs(result["matches"][0]["latency_s"] - 0.5) < 1e-9
    assert latency_factor(0.5, budget_s=1.0) == 0.75
    assert latency_factor(-0.3) == 1.0
    assert latency_factor(2.0, budget_s=1.0) == 0.0


def test_one_to_one_matching():
    result = match_intervals([(0, 10)], [(0, 5), (6, 9)], FPS, 1.0)
    assert result["tp"] == 1 and result["fp"] == 1


def test_two_sided_requires_both_witnesses():
    s = RuleScore("R")
    s.captures_violating = 3
    assert s.witnessed is False and s.two_sided is False
    s.captures_applicable = 3
    assert s.witnessed is True and s.two_sided is False
    s.captures_compliant = 1
    assert s.two_sided is True


def test_monitor_score_is_bounded_by_coverage():
    """A perfect monitor on one obligation of a hundred cannot score highly."""
    s = RuleScore("R")
    s.captures_applicable = 2
    s.captures_violating = 1
    s.captures_compliant = 1
    s.tp, s.fp, s.fn = 5, 0, 0
    summary = monitor_score({"R": s}, rulebook_size=100)
    assert abs(summary["mean_quality"] - 1.0) < 1e-9
    assert abs(summary["monitor_score"] - 0.01) < 1e-9


def test_unwitnessed_rules_never_inflate_the_score():
    good = RuleScore("good")
    good.captures_applicable = 2; good.captures_violating = 1
    good.captures_compliant = 1; good.tp = 3
    silent = RuleScore("silent")          # never engaged anywhere
    silent.captures_total = 10
    summary = monitor_score({"good": good, "silent": silent}, rulebook_size=2)
    assert summary["scored_rules"] == 1
    assert abs(summary["two_sided_coverage"] - 0.5) < 1e-9


# ----------------------------------------------------------------- mutation

def test_surviving_mutant_means_the_corpus_cannot_pin_the_constant():
    r = reading({"gt": ["ego.speed_kph", 0.5]},
                {"sustained": [0.25, {"gt": ["ego.speed_kph", 50.0]}]}, rid="S")
    # Every capture is far from the 50 km/h line, so halving or doubling it
    # changes nothing and the constant is unpinned.
    far = [track([5.0] * 40, capture="slow"), track([200.0] * 40, capture="fast")]
    unpinned = kill_report(r, far, factors=(0.8, 1.25))
    assert unpinned["survived"] > 0

    # Add a capture that sits between the mutants and they die.
    near = far + [track([55.0 / 3.6] * 40, capture="near")]
    pinned = kill_report(r, near, factors=(0.8, 1.25))
    assert pinned["mutation_score"] > unpinned["mutation_score"]


def test_mutants_are_generated_for_every_constant():
    r = reading({"gt": ["ego.speed_kph", 0.5]},
                {"sustained": [0.25, {"gt": ["ego.speed_kph", 50.0]}]})
    names = [n for n, _ in mutants(r, factors=(2.0,))]
    assert len(names) == 3       # 0.5, 0.25, 50.0


# -------------------------------------------------------- fact-track helpers

def test_finite_difference_recovers_a_constant_speed():
    positions = [(i * 0.5, 0.0) for i in range(40)]     # 0.5 m per frame
    speeds = finite_difference_speed(positions, 20, window=1)
    assert abs(speeds[10] - 10.0) < 1e-9                # 0.5 m * 20 Hz


def test_unwrap_prevents_a_fake_yaw_rate_at_the_heading_wrap():
    raw = [179.0, -179.0]
    assert abs(unwrap_degrees(raw)[1] - 181.0) < 1e-9


def test_referenced_paths_finds_paths_inside_temporal_operators():
    expr = {"sustained": [1.0, {"all": ["ego.lane.is_junction",
                                        {"gt": ["ego.speed_kph", 5]}]}]}
    assert referenced_paths(expr) == {"ego.lane.is_junction", "ego.speed_kph"}



def test_completely_wrong_rule_scores_zero_not_undefined():
    """Regression: an F1 of None for a maximally wrong rule dropped it out of
    the aggregate mean and RAISED the monitor's score."""
    wrong = RuleScore("wrong")
    wrong.captures_applicable = 2
    wrong.captures_violating = 1
    wrong.captures_compliant = 1
    wrong.tp, wrong.fp, wrong.fn = 0, 5, 5
    assert wrong.f1 == 0.0

    idle = RuleScore("idle")          # nothing to find, nothing raised
    idle.captures_applicable = 1
    idle.captures_violating = 1
    idle.captures_compliant = 1
    assert idle.f1 is None

    summary = monitor_score({"wrong": wrong}, rulebook_size=1)
    assert summary["monitor_score"] == 0.0


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
    print("\n%d test(s) failed" % failures if failures else "\nall tests passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(_run_all())
