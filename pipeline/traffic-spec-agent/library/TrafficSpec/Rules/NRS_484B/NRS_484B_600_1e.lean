/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (condition): In any event,
    s3 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity'], derived []
    s3: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s3: 80 mph — 80 miles per hour

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1 — the subject. Membership of the vehicle aggregate is the binder's class: the atom
      `ru_aggregate` of `v` under the id DEF-NRS-484A-320::vehicle, never the classes it covers.
      "any person to drive or operate" is read, as the record's own narrowing on s1 says, through
      the vehicle's controlled motion, and the record's atom for it is `kin.velocity`: the
      applicability is that `v`'s velocity is not the zero vector, written axis-free as
      |v_x| + |v_y| > 0 over the two components the measure gives (the only components Core reads).
      A vehicle at a standstill is driven at no rate of speed, so the paragraph does not engage.
    s2 — residue, as the record states it: "In any event" adds no observable condition.
    s3 — the duty. `kin.speed`, the magnitude of velocity at the observation, must not exceed the
      figure the text itself states: `Units.mph 80`, carried as a literal in miles per hour.
      "greater than 80" violated is exactly `not (speed ≤ 80 mph)`, written as the bound
      `speed ≤ 80 mph`.

  No narrowing is declared: s1 and s3 are written with the atoms the record maps to them, and the
  reading of "drive or operate" through controlled motion is the record's own narrowing, not this
  session's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The components of `v`'s velocity, in m/s (`kin.velocity`). -/
def velX : Term := .measure "kin_velocity" [vV, .lit "x"]
def velY : Term := .measure "kin_velocity" [vV, .lit "y"]

/-- `v`'s rate of speed at the observation: the magnitude of its velocity (`kin.speed`). -/
def speedOfV : Term := .measure "kin_speed" [vV]

def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- 80 miles per hour: the figure s3 states, through its `Units` constructor. -/
def eightyMilesPerHour : Term := .lit (Units.mph 80) .metrePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s2 (condition): In any event, — no observable condition of its own (residue);
    what remains of s1 beside the binder's class is that `v` is in controlled motion: its velocity
    is not the zero vector. -/
def applicability : Formula :=
  .cmp (.add (.abs velX) (.abs velY)) .gt zeroSpeed

/-- Obligation: s3 (obligation): a rate of speed greater than 80 miles per hour. -/
def obligation : Formula :=
  .cmp speedOfV .le eightyMilesPerHour

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["\"In any event\" imposes no observable condition: it states that the absolute bound holds whatever the circumstances, so the duty is the same whether or not any condition of the road, the weather or the posted limits holds. Dropping it changes no verdict."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
