"""Scenario-driven CARLA captures for traffic-spec-agent.

Records compliant/violating counterpart captures for each formalized traffic law,
together with ground truth read from the CARLA server, so
`python -m scripts.run_spec monitor` has something independent to diff its Lean
verdicts against.

Import order matters: `runner` fixes sys.path for CARLA's bundled `agents`
package before anything touches `carla_sgg`.
"""

__all__ = ["driving", "geometry", "labeler", "oracle", "paths", "runner",
           "scenario", "scenarios"]
