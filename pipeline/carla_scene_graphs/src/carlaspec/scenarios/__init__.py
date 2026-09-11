"""Importing this package registers every scenario.

One module per law (or per rule, where a law was decomposed into rules needing
different geography). Adding a scenario means adding a module here and importing
it below — nothing else in the pipeline changes.
"""

from . import emergency, following, junction, lane, red_light, speed, stop_sign  # noqa: F401

__all__ = [
    "emergency",
    "following",
    "junction",
    "lane",
    "red_light",
    "speed",
    "stop_sign",
]
