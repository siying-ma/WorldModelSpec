"""Unit factors to Core units, mirroring `Units.lean` and `Decode.unit` exactly (rationals)."""
from __future__ import annotations
import re
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
    "deg/s": ("degreePerSecond", Fraction(1)), "1/m": ("perMetre", Fraction(1)), "per_metre": ("perMetre", Fraction(1)),
    "ratio": ("ratio", Fraction(1)), "count": ("count", Fraction(1)),
}


def to_core(value, unit: str) -> tuple[str, Fraction]:
    core, k = FACTORS[unit]
    return core, Fraction(str(value)) * k


#: Number words a statute spells out, and the unit words it uses, for `stated_figures`.
NUMBER_WORDS: dict[str, Fraction] = {
    "one-half": Fraction(1, 2), "one": Fraction(1), "two": Fraction(2), "three": Fraction(3), "four": Fraction(4),
    "five": Fraction(5), "six": Fraction(6), "seven": Fraction(7), "eight": Fraction(8), "nine": Fraction(9),
    "ten": Fraction(10), "fifteen": Fraction(15), "twenty": Fraction(20), "thirty": Fraction(30), "fifty": Fraction(50),
    "hundred": Fraction(100)}
UNIT_WORDS: dict[str, str] = {
    "feet": "ft", "foot": "ft", "inches": "in", "inch": "in", "miles per hour": "mph", "mile per hour": "mph",
    "miles": "mi", "mile": "mi", "seconds": "s", "second": "s", "minutes": "min", "minute": "min",
    "hours": "h", "hour": "h", "degrees": "deg"}
_FIGURE = re.compile(r"(\d[\d,]*(?:\.\d+)?|" + "|".join(sorted(NUMBER_WORDS, key=len, reverse=True)) + r")[\s-]+("
                     + "|".join(sorted(UNIT_WORDS, key=len, reverse=True)) + r")\b", re.I)


def stated_figures(text: str) -> list[tuple[str, Fraction, str]]:
    """The magnitudes a text states, as (Core unit, value in Core units, the words): "100 feet",
    "one-half hour", "15 miles per hour"."""
    out = []
    for m in _FIGURE.finditer(text):
        n = m.group(1).lower().replace(",", "")
        v = NUMBER_WORDS[n] if n in NUMBER_WORDS else Fraction(n)
        core, x = to_core(v, UNIT_WORDS[m.group(2).lower()])
        out.append((core, x, m.group(0)))
    return out
