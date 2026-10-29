/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    e2 (obligation): In any event, a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived []
    e2: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    e2: 80 mph — 80 miles per hour

  How each span is written.

    e1 (subject), class of `v`: the single atom `ru_aggregate` with the admitted aggregate id
      `DEF-NRS-484A-320::vehicle` as its literal argument; the classes that id covers are never
      written here. 'any person to drive or operate' is the record's observable reading through the
      vehicle's own controlled motion, written as `kin_speed v > 0` — zero is the only magnitude
      this file states of its own, and a vehicle in motion is taken to be driven. Nothing of place
      is read into the span: no region quantifier and no occupancy appear, since the span names
      none and the definition's 'may be ... transported or drawn upon a highway' is a property of
      the class the reading classifies under the aggregate id, not a region the vehicle occupies.

    e2 (obligation), 'In any event, a rate of speed greater than 80 miles per hour': `kin_speed v`
      is not above the rate the text itself states, written as the declared literal 80 mph through
      `Units.mph`, so that the comparison is made in one unit (the ontology gives `kin.speed` in
      m/s and `Units.mph` converts exactly). 'In any event' adds no condition of the scene — it
      says the bound holds whatever else is posted or reasonable and whatever the place — so the
      duty is stated wherever a vehicle is in controlled motion, with no posting, no place and no
      further circumstance consulted. No device, region or environment atom is read.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- e2: the rate the text states, 80 miles per hour. -/
def statedRate : Term := .lit (Units.mph 80) .metrePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula :=
  .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e1: the vehicle is in controlled motion. -/
def inMotion : Formula := .cmp (.measure "kin_speed" [vV]) .gt zeroSpeed

/-- Applicability: e1 (subject): a vehicle is in controlled motion. -/
def applicability : Formula := inMotion

/-- Obligation: e2 (obligation): In any event, a rate of speed greater than 80 miles per hour. -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vV]) .le statedRate

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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
