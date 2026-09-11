"""How good is a safety monitor? — the metric definitions.

Why not CARLA's Driving Score
-----------------------------
CARLA's Driving Score is `RouteCompletion x prod(infraction penalties)`. It
scores a *driver*: how far did it get, how much did it break on the way. A
safety monitor is not a driver. It is a detector over traces, and it can be
excellent while watching a terrible driver or useless while watching a perfect
one. Driving Score is therefore not merely a poor monitor metric, it is a metric
of a different object, and its multiplicative form actively misleads: a monitor
that never fires scores the same as one that is right, because neither *drives*.

The Leaderboard's infraction set is also small and fixed — collision, red light,
stop sign, off-road, route deviation, blocked. Roughly seven detectors. A
project whose target is the several hundred obligations of a real statute book
needs a metric that grows with the rule book, and Driving Score does not have a
place to put a rule in.

What a monitor is scored on instead
-----------------------------------
Four axes, reported separately and never blended into one number without also
printing the parts.

1. DETECTION, per rule, at the level of episodes rather than frames. A violation
   is an interval; frame accuracy is dominated by the long compliant stretches
   and reads ~99% for a monitor that never fires. Precision and recall are
   computed over matched intervals.

2. LATENCY. Frames between the true onset and the alarm. A monitor that reports
   a red-light entry two seconds late is correct and useless. This axis does not
   exist in any driving score and is the one a downstream intervention actually
   depends on.

3. COVERAGE. What fraction of the rule book is (a) formalized, (b) *witnessed* —
   the antecedent actually became true somewhere in the corpus — and (c)
   witnessed on both sides, compliant and violating. An unwitnessed rule is
   untested no matter how many captures it scored `compliant` on. This axis
   measures the DATASET, and for a project at the stage of building one it is
   the axis that should be reported first.

4. COST. Wall-clock per frame. A monitor that cannot keep up with the vehicle is
   an offline analysis tool.

Asymmetry, and why there is no single number by default
-------------------------------------------------------
A missed violation and a false alarm are not exchangeable. Missing one is a
safety failure; raising many destroys the monitor's usability and gets it turned
off, which is also a safety failure. They are reported as precision and recall
plus a false-alarm rate per hour of driving, which is the operating point an
integrator actually chooses against. `monitor_score` exists for leaderboard-style
comparison and always carries its components.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence, Tuple

from .evaluate import COMPLIANT, NOT_APPLICABLE, UNTESTABLE, VIOLATED

Interval = Tuple[int, int]


# --------------------------------------------------------------------------
# Interval matching
# --------------------------------------------------------------------------

def _overlap(a, b):
    # type: (Interval, Interval) -> int
    return max(0, min(a[1], b[1]) - max(a[0], b[0]) + 1)


def match_intervals(truth, alarms, fps, onset_tolerance_s=1.0):
    # type: (List[Interval], List[Interval], int, float) -> dict
    """One-to-one match between ground-truth violations and monitor alarms.

    An alarm matches a truth interval when the two overlap at all and the
    alarm's onset is no later than `onset_tolerance_s` after the truth onset.
    Overlap alone is too generous — an alarm that fires at the very end of a
    long violation is not a detection in any useful sense — and onset proximity
    alone is too strict for a rule whose formalization legitimately triggers a
    few frames early.

    Matching is greedy by |onset delta|, which is optimal here because the
    intervals within one capture are disjoint and ordered.
    """
    tolerance = int(round(onset_tolerance_s * fps))
    candidates = []
    for ti, tv in enumerate(truth):
        for ai, av in enumerate(alarms):
            if _overlap(tv, av) <= 0:
                continue
            delta = av[0] - tv[0]
            if delta > tolerance:
                continue
            candidates.append((abs(delta), delta, ti, ai))
    candidates.sort()

    used_t, used_a = set(), set()
    matches = []
    for _, delta, ti, ai in candidates:
        if ti in used_t or ai in used_a:
            continue
        used_t.add(ti)
        used_a.add(ai)
        matches.append({"truth": ti, "alarm": ai, "latency_frames": delta,
                        "latency_s": delta / float(fps)})
    return {
        "matches": matches,
        "tp": len(matches),
        "fn": len(truth) - len(matches),
        "fp": len(alarms) - len(matches),
        "missed": [truth[i] for i in range(len(truth)) if i not in used_t],
        "spurious": [alarms[i] for i in range(len(alarms)) if i not in used_a],
    }


# --------------------------------------------------------------------------
# Per-rule detection
# --------------------------------------------------------------------------

class RuleScore(object):
    def __init__(self, rule_id):
        self.rule_id = rule_id
        self.tp = 0
        self.fp = 0
        self.fn = 0
        self.latencies_s = []       # type: List[float]
        self.captures_applicable = 0
        self.captures_violating = 0
        self.captures_compliant = 0
        self.captures_untestable = 0
        self.captures_total = 0
        self.applicable_seconds = 0.0
        self.total_seconds = 0.0

    # ---- detection

    @property
    def precision(self):
        # type: () -> Optional[float]
        denom = self.tp + self.fp
        return None if denom == 0 else self.tp / float(denom)

    @property
    def recall(self):
        # type: () -> Optional[float]
        denom = self.tp + self.fn
        return None if denom == 0 else self.tp / float(denom)

    @property
    def f1(self):
        # type: () -> Optional[float]
        p, r = self.precision, self.recall
        if p is None or r is None:
            # Undefined: the rule raised no alarms AND had no violations to
            # find, so there is nothing to score. Distinct from the case below.
            return None
        if (p + r) == 0:
            # Defined and zero: the monitor fired, or should have, and got it
            # entirely wrong. Returning None here would drop the rule out of
            # `monitor_score`'s mean and RAISE the score for being maximally
            # wrong on it, which is the one thing an aggregate must never do.
            return 0.0
        return 2 * p * r / (p + r)

    @property
    def mean_latency_s(self):
        # type: () -> Optional[float]
        if not self.latencies_s:
            return None
        return sum(self.latencies_s) / len(self.latencies_s)

    @property
    def p95_latency_s(self):
        # type: () -> Optional[float]
        if not self.latencies_s:
            return None
        ordered = sorted(self.latencies_s)
        return ordered[min(len(ordered) - 1, int(0.95 * len(ordered)))]

    def false_alarms_per_hour(self):
        # type: () -> Optional[float]
        if self.total_seconds <= 0:
            return None
        return self.fp / (self.total_seconds / 3600.0)

    # ---- coverage

    @property
    def witnessed(self):
        # type: () -> bool
        """The obligation's situation actually arose somewhere in the corpus."""
        return self.captures_applicable > 0

    @property
    def two_sided(self):
        # type: () -> bool
        """Both a compliant and a violating witness exist.

        Only a two-sided rule is discriminating. A rule witnessed only on
        compliant footage cannot be distinguished from one that is incapable of
        reporting a violation at all.
        """
        return self.captures_violating > 0 and self.captures_compliant > 0

    def as_dict(self):
        return {
            "rule": self.rule_id,
            "tp": self.tp, "fp": self.fp, "fn": self.fn,
            "precision": self.precision, "recall": self.recall, "f1": self.f1,
            "mean_latency_s": self.mean_latency_s,
            "p95_latency_s": self.p95_latency_s,
            "false_alarms_per_hour": self.false_alarms_per_hour(),
            "captures_total": self.captures_total,
            "captures_applicable": self.captures_applicable,
            "captures_violating": self.captures_violating,
            "captures_compliant": self.captures_compliant,
            "captures_untestable": self.captures_untestable,
            "witnessed": self.witnessed,
            "two_sided": self.two_sided,
            "applicable_seconds": round(self.applicable_seconds, 2),
        }


def score_corpus(labels_by_capture, alarms_by_capture, durations_s, fps,
                 onset_tolerance_s=1.0):
    # type: (Dict[str, Dict[str, Any]], Dict[str, Dict[str, List[Interval]]], Dict[str, float], int, float) -> Dict[str, RuleScore]
    """Score a monitor over a whole corpus.

    `labels_by_capture[capture][rule]` is an `evaluate.Label` (ground truth).
    `alarms_by_capture[capture][rule]` is the monitor's alarm intervals. A rule
    absent from the monitor's output is scored as raising no alarm, which is
    what an unformalized rule does.
    """
    scores = {}  # type: Dict[str, RuleScore]
    for capture, labels in labels_by_capture.items():
        duration = durations_s.get(capture, 0.0)
        for rule_id, label in labels.items():
            score = scores.setdefault(rule_id, RuleScore(rule_id))
            score.captures_total += 1
            score.total_seconds += duration

            if label.verdict == UNTESTABLE:
                score.captures_untestable += 1
                continue
            if label.verdict == NOT_APPLICABLE:
                continue

            score.captures_applicable += 1
            score.applicable_seconds += sum(
                (b - a + 1) for a, b in label.applicable) / float(fps)
            if label.verdict == VIOLATED:
                score.captures_violating += 1
            elif label.verdict == COMPLIANT:
                score.captures_compliant += 1

            alarms = alarms_by_capture.get(capture, {}).get(rule_id, [])
            result = match_intervals(label.violations, alarms, fps,
                                     onset_tolerance_s)
            score.tp += result["tp"]
            score.fp += result["fp"]
            score.fn += result["fn"]
            score.latencies_s.extend(m["latency_s"] for m in result["matches"])
    return scores


# --------------------------------------------------------------------------
# Aggregates
# --------------------------------------------------------------------------

def coverage(scores, rulebook_size):
    # type: (Dict[str, RuleScore], int) -> dict
    """How much of the rule book the corpus actually exercises.

    `rulebook_size` is the number of obligations in the *statute*, not the
    number formalized. Dividing by what was formalized flatters the result by
    exactly the amount that was skipped, which is the number a reader most
    wants.
    """
    formalized = len(scores)
    witnessed = sum(1 for s in scores.values() if s.witnessed)
    two_sided = sum(1 for s in scores.values() if s.two_sided)
    untestable = sum(1 for s in scores.values()
                     if s.captures_untestable and not s.witnessed)
    return {
        "rulebook_obligations": rulebook_size,
        "formalized": formalized,
        "formalized_frac": formalized / float(rulebook_size) if rulebook_size else 0.0,
        "witnessed": witnessed,
        "witnessed_frac": witnessed / float(rulebook_size) if rulebook_size else 0.0,
        "two_sided": two_sided,
        "two_sided_frac": two_sided / float(rulebook_size) if rulebook_size else 0.0,
        "untestable_everywhere": untestable,
    }


def latency_factor(latency_s, budget_s=1.0):
    # type: (Optional[float], float) -> float
    """Decay applied to a rule's F1 for how late its alarms are.

    1.0 at or before the onset, falling linearly to 0 at twice the budget. A
    monitor that detects everything a full second late is worth roughly half a
    monitor that detects it as it happens, which is the trade an intervention
    system faces. Linear rather than exponential because a multiplicative
    exponential decay is exactly the property that makes CARLA's Driving Score
    hard to compare across systems.
    """
    if latency_s is None:
        return 1.0
    if latency_s <= 0:
        return 1.0
    return max(0.0, 1.0 - latency_s / (2.0 * budget_s))


def monitor_score(scores, rulebook_size, latency_budget_s=1.0):
    # type: (Dict[str, RuleScore], int, float) -> dict
    """One comparable number, always reported with its parts.

        MonitorScore = TwoSidedCoverage x mean_over_two_sided(F1 x LatencyFactor)

    The product is deliberate. The left factor says how much of the statute the
    corpus can speak to at all; the right says how well the monitor does where
    it can be scored. A monitor that formalizes three rules perfectly cannot
    beat one that covers two hundred well, and a corpus that witnesses nothing
    scores zero however good the monitor is — which is the honest reading when
    the dataset is the thing under construction.

    Rules that are not two-sided are excluded from the quality term and counted
    against the coverage term, so they can never inflate the result.
    """
    two_sided = [s for s in scores.values() if s.two_sided]
    quality = []
    for score in two_sided:
        f1 = score.f1
        if f1 is None:
            continue
        quality.append(f1 * latency_factor(score.mean_latency_s,
                                           latency_budget_s))
    cov = coverage(scores, rulebook_size)
    mean_quality = sum(quality) / len(quality) if quality else 0.0
    return {
        "monitor_score": cov["two_sided_frac"] * mean_quality,
        "two_sided_coverage": cov["two_sided_frac"],
        "mean_quality": mean_quality,
        "scored_rules": len(quality),
        "coverage": cov,
        "latency_budget_s": latency_budget_s,
    }
