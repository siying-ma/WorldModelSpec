"""The rule every hand-written trace is held to on measured relations, as Lean the gates', the
certificate's and the concept review's programs include: a relation Core can compute from the scene
is not supplied.

A trace may supply a relation between two road users (`relations[]`: a centre distance, a surface
gap, ahead-of, overlap, oncoming, same direction, bearing, contact, visibility), and an atom reads a
supplied value in place of computing it, so a supplied value could contradict the scene's own
geometry. For every scene, every supplied pair and every field Core also computes, the check clears
that field and asks Core for the value: where Core computes one, the supplied field is a defect of
the trace, printed `RELCHECK` ("remove it; Core computes it from the scene"). A field Core cannot
compute there (its geometry is not in the scene) may be supplied, and `visible` is never computed.
Whether Core computes a value does not depend on a relation's tolerance parameter, so the check
passes zero. Which atoms read which supplied field, with how many parameters, is read from Core's
`Atoms.lean`, never typed here. Traces a source records never pass this check.
"""
from __future__ import annotations
import re
from functools import lru_cache
from ..store import paths

_DEF = re.compile(r"def (rel_\w+) \(s : Scene\) \(a b : TrackId\)((?: \(\w+ : Q\))*) : Option ([^:=]+?) :=\s*\n\s*"
                  r"match \(s\.relation a b\)\.bind \(·\.(\w+)\) with")


@lru_cache(maxsize=1)
def computable() -> tuple[tuple[str, int, str, str], ...]:
    """(atom, number of Q parameters, value type, supplied field) of each relation Core both reads
    from a trace and computes."""
    src = (paths.CORE / "Vocab" / "Atoms.lean").read_text(encoding="utf-8")
    return tuple((m.group(1), len(re.findall(r"\(\w+ : Q\)", m.group(2))), " ".join(m.group(3).split()), m.group(4))
                 for m in _DEF.finditer(src))


def json_key(field: str) -> str:
    """The trace key of a supplied field (`aAheadOfB` → `a_ahead_of_b`), as the decoder spells it."""
    return re.sub(r"(?<!^)(?=[A-Z])", "_", field).lower()


def atom_keys() -> dict[str, str]:
    """Each computable relation atom's trace key."""
    return {atom: json_key(field) for atom, _n, _k, field in computable()}


def lean_defs() -> str:
    """The Lean definition `RelCheck.run name τ`: one `RELCHECK` line per supplied field Core
    computes, `RELCHECK\\t<name>\\t<t>\\t<a>-<b>\\t<atom>: …`."""
    arms = []
    for atom, nparams, _kind, field in computable():
        call = f"{atom} (cleared fun x => {{ x with {field} := none }}) m.a m.b" + " Q.zero" * nparams
        arms.append(f'''      if m.{field}.isSome && ({call}).isSome then
        IO.println s!"RELCHECK\\t{{name}}\\t{{s.t}}\\t{{m.a}}-{{m.b}}\\t{atom}: supplied, but Core computes it from the scene; remove it from the trace"''')
    return '''namespace RelCheck
open TrafficSpec
def run (name : String) (τ : Trace) : IO Unit := do
  for s in τ do
    for m in s.relations do
      let cleared (f : MeasuredRelation → MeasuredRelation) : Scene :=
        { s with relations := s.relations.map fun x => if x.a == m.a && x.b == m.b then f x else x }
''' + "\n".join(arms) + '''
end RelCheck
'''
