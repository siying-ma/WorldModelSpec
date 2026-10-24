"""The units of the pipeline, read from Core, which is their only authority: the spellings a reading
or a record may use and their exact factors to Core's units (`Decode.unit`, through the constructors
of `Foundations/Units.lean`), Core's units (`PUnit'`), their tags in exported JSON
(`PUnit'.toJson`), and their dimensions (`Dim.ofUnit`). Nothing here is typed by hand: a change in
Core changes what is read here. Conversions are exact rationals. Also the stated-figure reader."""
from __future__ import annotations
import re
from fractions import Fraction
from functools import lru_cache
from typing import NamedTuple

from ..store import paths


def _core(rel: str) -> str:
    return (paths.CORE / rel).read_text(encoding="utf-8")


def _between(text: str, start: str, end: str) -> str:
    i = text.index(start)
    return text[i:text.index(end, i)]


@lru_cache(maxsize=1)
def _spec() -> dict:
    ctor = {}                                           # a `Units` constructor of one integer → its factor
    for m in re.finditer(r"^def (\w+) \(n : Int\) : Q := ([^\n]+?)\s*(?:--.*)?$", _between(_core("Foundations/Units.lean"), "namespace Units", "end Units"), re.M):
        body = m.group(2).strip()
        k = re.fullmatch(r"Q\.ofInt (?:n|\(n \* (\d+)\))", body)
        q = re.fullmatch(r"Q\.mk' (?:n|\(n \* (\d+)\)) (\d+)", body)
        if k:
            ctor[m.group(1)] = Fraction(int(k.group(1) or 1))
        elif q:
            ctor[m.group(1)] = Fraction(int(q.group(1) or 1), int(q.group(2)))
    factors = {}
    for m in re.finditer(r"^\s*\| (\"[^=]+?) => pure \(\.(\w+), (?:Q\.ofInt 1|Units\.(\w+) 1)\)", _between(_core("Runtime/Decode.lean"), "def unit (path", "def paramValue"), re.M):
        k = ctor[m.group(3)] if m.group(3) else Fraction(1)
        for spelling in re.findall(r'"([^"]+)"', m.group(1)):
            factors[spelling] = (m.group(2), k)
    units = re.findall(r"\| (\w+)", _between(_core("Vocab/Params.lean"), "inductive PUnit'", "deriving"))
    tags = dict(re.findall(r"\| \.(\w+) => \"(\w+)\"", _between(_core("Language/Export.lean"), "def PUnit'.toJson", "def Q.toJson")))
    dims = {}
    for m in re.finditer(r"\| \.(\w+) => (?:⟨(-?\d+), (-?\d+), (-?\d+)⟩|one)", _between(_core("Evidence/Certificate.lean"), "def ofUnit", "def render")):
        dims[m.group(1)] = (int(m.group(2)), int(m.group(3)), int(m.group(4))) if m.group(2) else (0, 0, 0)
    ctors = re.findall(r"^def (\w+) \(", _between(_core("Foundations/Units.lean"), "namespace Units", "end Units"), re.M)
    return {"factors": factors, "units": units, "tags": tags, "dims": dims, "ctors": ctors}


#: Each spelling a reading or a record may use → (its Core unit, the exact factor to it).
FACTORS: dict[str, tuple[str, Fraction]] = _spec()["factors"]
#: Core's units (`PUnit'`), in their declared order.
CORE_UNITS: list[str] = _spec()["units"]
#: Each Core unit → its dimension, as exponents of (metre, second, degree).
DIMS: dict[str, tuple[int, int, int]] = _spec()["dims"]


def lean_unit(core: str) -> str:
    """The Lean constructor of a Core unit (`.metre`)."""
    if core not in CORE_UNITS:
        raise KeyError(core)
    return "." + core


def json_tag(core: str) -> str:
    """How exported JSON names a Core unit (`metre_per_second`)."""
    return _spec()["tags"][core]


def core_of_tag(tag: str) -> str | None:
    return next((c for c, t in _spec()["tags"].items() if t == tag), None)


def constructors() -> list[str]:
    """The constructors of `Units`, as a witness writes a quantity."""
    return list(_spec()["ctors"])


def spellings() -> list[str]:
    return sorted(FACTORS)


def to_core(value, unit: str) -> tuple[str, Fraction]:
    core, k = FACTORS[unit]
    return core, Fraction(str(value)) * k


#: Number words a statute spells out, and the unit words and abbreviations it uses, for `stated_figures`.
ONES = {w: i for i, w in enumerate("zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen "
                                   "sixteen seventeen eighteen nineteen".split())}
TENS = {w: 10 * i for i, w in enumerate("_ _ twenty thirty forty fifty sixty seventy eighty ninety".split()) if w != "_"}
SCALES = {"hundred": 100, "thousand": 1000}
FRACTION_WORDS = {"half": 2, "halves": 2, "third": 3, "thirds": 3, "quarter": 4, "quarters": 4}
UNIT_WORDS: dict[str, str] = {
    "feet": "ft", "foot": "ft", "ft.": "ft", "ft": "ft", "inches": "in", "inch": "in", "yards": "yd", "yard": "yd", "yd.": "yd", "yd": "yd",
    "miles per hour": "mph", "mile per hour": "mph", "mph": "mph", "m.p.h.": "mph", "miles": "mi", "mile": "mi", "mi.": "mi",
    "seconds": "s", "second": "s", "sec.": "s", "minutes": "min", "minute": "min", "min.": "min", "hours": "h", "hour": "h", "hr.": "h",
    "degrees": "deg", "degree": "deg"}
_WORD = "|".join(sorted(list(ONES) + list(TENS) + list(SCALES) + list(FRACTION_WORDS) + ["and"], key=len, reverse=True))
_DIGITS = r"\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?|\.\d+"
_UNIT = "|".join(re.escape(u) for u in sorted(UNIT_WORDS, key=len, reverse=True))
_FIGURE = re.compile(rf"(?<![\w./,-])((?:{_DIGITS})|(?:(?:{_WORD})(?:[\s-]+(?:{_WORD}))*))[\s-]+({_UNIT})(?![\w])", re.I)
_LEADING_AND = re.compile(r"(?:and(?:[\s-]+|$))+", re.I)


class Figure(NamedTuple):
    """A magnitude a text states: its Core unit and value, the words, and where they start."""
    core: str
    value: Fraction
    words: str
    start: int


class UnsupportedFigure(NamedTuple):
    """Number words before a unit the parser cannot read: never taken for "no figure"."""
    words: str
    start: int


def _number(phrase: str) -> Fraction | None:
    """The value of a number phrase (digits, a fraction, a mixed number, or number words), or None."""
    t = phrase.lower().strip()
    if re.fullmatch(r"[\d,]+(?:\.\d+)?|\.\d+", t):
        return Fraction(t.replace(",", ""))
    m = re.fullmatch(r"(?:(\d+)\s+)?(\d+)/(\d+)", t)
    if m:
        return (Fraction(int(m.group(1))) if m.group(1) else 0) + Fraction(int(m.group(2)), int(m.group(3))) if int(m.group(3)) else None
    words = [w for w in re.split(r"[\s-]+", t) if w]
    if words.count("and") > 1:
        return None
    if "and" in words:
        i = words.index("and")
        whole, part = words[:i], words[i + 1:]
        if not part or not whole:
            return None
        if part[-1] not in FRACTION_WORDS:                 # "one hundred and fifty": one integer
            return _integer(whole + part) if whole[-1] in SCALES else None
    elif words[-1] in FRACTION_WORDS:                      # "one-half", "three-quarters"
        whole, part = [], words
    else:
        whole, part = words, []
    w = _integer(whole) if whole else 0
    if w is None:
        return None
    if not part:
        return Fraction(w)
    den = FRACTION_WORDS[part[-1]]
    num = _integer(part[:-1]) if part[:-1] else 1
    if num is None or num == 0 or (num == 1) == part[-1].endswith("s") and part[-1] != "half":
        return None
    return Fraction(w) + Fraction(num, den)


def _integer(words: list[str]) -> int | None:
    """A number spelled in words ("four hundred", "twenty-four", "one thousand three hundred fifty"), or None."""
    if not words or any(w not in ONES and w not in TENS and w not in SCALES for w in words):
        return None
    total, current, last = 0, 0, None
    for w in words:
        if w in ONES:
            if last in ("ones",) or (last == "tens" and (ONES[w] == 0 or ONES[w] >= 10)):
                return None
            current += ONES[w]; last = "ones"
        elif w in TENS:
            if last in ("ones", "tens"):
                return None
            current += TENS[w]; last = "tens"
        elif w == "hundred":
            if last not in ("ones",) or current >= 10 or current == 0:
                return None
            current *= 100; last = "hundred"
        else:                                              # thousand
            if current == 0 or last == "thousand":
                return None
            total += current * 1000; current = 0; last = "thousand"
    return total + current


def _scan(text: str) -> list[Figure | UnsupportedFigure]:
    out: list[Figure | UnsupportedFigure] = []
    for m in _FIGURE.finditer(text):
        phrase, start = m.group(1), m.start()
        lead = _LEADING_AND.match(phrase)       # a coordinating "and" before a number is not part of it
        if lead:
            phrase, start = phrase[lead.end():], start + lead.end()
        if not phrase:
            continue
        v = _number(phrase)
        if v is None:
            out.append(UnsupportedFigure(text[start:m.end()], start))
            continue
        core, x = to_core(v, UNIT_WORDS[m.group(2).lower()])
        out.append(Figure(core, x, text[start:m.end()], start))
    return out


def stated_figures(text: str) -> list[Figure]:
    """The magnitudes a text states, each a whole phrase read with word boundaries: "four hundred
    feet", "twenty-four feet", "1/2 mile", "one and one-half miles", "15 mph", "2.5 seconds"."""
    return [f for f in _scan(text) if isinstance(f, Figure)]


def unsupported_figures(text: str) -> list[UnsupportedFigure]:
    """Number words before a unit that `stated_figures` cannot read, with where they start."""
    return [f for f in _scan(text) if isinstance(f, UnsupportedFigure)]
