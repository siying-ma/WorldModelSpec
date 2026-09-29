"""Unit factors to Core units, mirroring `Units.lean` and `Decode.unit` exactly (rationals)."""
from __future__ import annotations
from fractions import Fraction

FACTORS: dict[str, tuple[str, Fraction]] = {
    "m": ("metre", Fraction(1)), "metre": ("metre", Fraction(1)),
    "ft": ("metre", Fraction(3048, 10000)), "foot": ("metre", Fraction(3048, 10000)), "feet": ("metre", Fraction(3048, 10000)),
    "in": ("metre", Fraction(254, 10000)), "inch": ("metre", Fraction(254, 10000)), "inches": ("metre", Fraction(254, 10000)),
    "yd": ("metre", Fraction(9144, 10000)), "mi": ("metre", Fraction(1609344, 1000)), "mile": ("metre", Fraction(1609344, 1000)), "miles": ("metre", Fraction(1609344, 1000)),
    "km": ("metre", Fraction(1000)),
    "s": ("second", Fraction(1)), "second": ("second", Fraction(1)), "seconds": ("second", Fraction(1)),
    "ms": ("second", Fraction(1, 1000)), "min": ("second", Fraction(60)), "minute": ("second", Fraction(60)), "minutes": ("second", Fraction(60)),
    "h": ("second", Fraction(3600)), "hour": ("second", Fraction(3600)), "hours": ("second", Fraction(3600)),
    "m/s": ("metrePerSecond", Fraction(1)), "mph": ("metrePerSecond", Fraction(44704, 100000)), "mi/h": ("metrePerSecond", Fraction(44704, 100000)),
    "km/h": ("metrePerSecond", Fraction(1000, 3600)), "kph": ("metrePerSecond", Fraction(1000, 3600)),
    "m/s2": ("metrePerSecondSq", Fraction(1)), "m/s^2": ("metrePerSecondSq", Fraction(1)),
    "deg": ("degree", Fraction(1)), "degree": ("degree", Fraction(1)), "degrees": ("degree", Fraction(1)),
    "deg/s": ("degreePerSecond", Fraction(1)), "ratio": ("ratio", Fraction(1)), "count": ("count", Fraction(1)),
}


def to_core(value, unit: str) -> tuple[str, Fraction]:
    core, k = FACTORS[unit]
    return core, Fraction(str(value)) * k
