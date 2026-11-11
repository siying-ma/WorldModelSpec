/-
  NRS_484B_127_3 — NRS-484B-127-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (subject): Motor vehicles being driven
    c2 (trigger): upon any highway
    c3 (condition): outside of a business district
    c4 (condition): in a caravan or motorcade
    c5 (condition): whether or not towing other vehicles
    c6 (obligation): shall be operated to allow sufficient space between each such vehicle or combination of vehicles
    c7 (standard): so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    c2: atoms ['st.highway', 'rel.occupies'], derived []
    c4: atoms ['rel.ahead_behind_in_lane', 'rel.same_direction', 'ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    c6: atoms ['rel.surface_gap', 'rel.ahead_behind_in_lane', 'rel.same_direction', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles'], derived []

  How each span is written:
    c1: the binder class, `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`; 'being driven' is the
        record's observable reading (agency) and adds no atom.
    c2: some region of kind `highway` (st.highway, the whole public way, not the roadway) that x
        occupies (rel.occupies).
    c3: the declared assumption `asm.outside_business_district`.
    c4: declared `no_atom` (see `narrowings`): the record carries the gap `ru.procession_member` on
        this span and its own justification says its nearest atoms (rel.ahead_behind_in_lane,
        rel.same_direction) hold for any two vehicles following each other in a lane, so they do not
        carry 'in a caravan or motorcade'. Written with them, the rule would hold every following
        motor vehicle outside a business district to a caravan's gap. The record is also at odds
        with itself here: its applicability's nearest reading needs a motor vehicle ahead of x,
        while its `branch_1` scenario has the lead car (nothing ahead) bound and compliant.
    c5: residue (the node's); the combination's body is read through the aggregate in c6.
    c6/c7: for every road user y that is a vehicle (DEF-NRS-484A-320::vehicle) or a combination of
        vehicles (DEF-NRS-484A-050::combination_of_vehicles), ahead of x in its lane
        (rel_ahead_behind_in_lane y x: y ahead of x) and travelling x's way (rel_same_direction,
        p.same_direction_cosine): the longitudinal component of rel.surface_gap from x to y (along
        x's heading) is at least p.entering_combination_length + p.entry_time_headway · speed(x)
        + p.entry_time_headway · speed(x), the two headways written apart as the record states them.
        'y other than x' needs no `same` test: x is never ahead of itself in a lane. 'belongs to x's
        caravan' in the obligation is the same gap as c4 and is not written.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The road user ahead whose gap is judged, and the highway x is on. -/
def vY : Arg := .var "y"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pEnteringCombinationLength : Term := .param "p.entering_combination_length"
def pEntryTimeHeadway : Term := .param "p.entry_time_headway"
def pSameDirectionCosine : Term := .param "p.same_direction_cosine"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- c2: x occupies a highway region. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "r" (.atom "rel_occupies" [vX, vR] [])

/-- c3: the place lies outside every business district. -/
def outsideBusinessDistrict : Formula := .asm "asm.outside_business_district"

/-- Applicability: c2 (trigger): upon any highway; c3 (condition): outside of a business district; c4 (condition): in a caravan or motorcade (no_atom, see header); c5 (condition): whether or not towing other vehicles (residue) -/
def applicability : Formula := .and onHighway outsideBusinessDistrict

/-- c6: y is a vehicle or a combination of vehicles. -/
def vehicleOrCombination : Formula :=
  .or (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-050::combination_of_vehicles"] [])

/-- c6/c7: y is ahead of x in its lane and travels x's way. -/
def aheadSameWay : Formula :=
  .and (.atom "rel_ahead_behind_in_lane" [vY, vX] [])
       (.atom "rel_same_direction" [vY, vX] [pSameDirectionCosine])

/-- c7: the entering combination's length plus a time headway at x's speed ahead of it and one behind it. -/
def speedX : Term := .measure "kin_speed" [vX]
def sufficientSpace : Term :=
  .add pEnteringCombinationLength (.add (.mul pEntryTimeHeadway speedX) (.mul pEntryTimeHeadway speedX))

/-- c6/c7: the longitudinal gap from x to y holds the entering combination with its headways. -/
def gapSufficient : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, vY, .lit "longitudinal"]) .ge sufficientSpace

/-- Obligation: c6 (obligation): shall be operated to allow sufficient space between each such vehicle or combination of vehicles; c7 (standard): so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger -/
def obligation : Formula :=
  .forallUser "y" (.implies (.and vehicleOrCombination aheadSameWay) gapSufficient)

def rule : Rule :=
  { id := "NRS_484B_127_3"
    laws := ["NRS-484B-127-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.outside_business_district"]
    intentions := []
    operationalizations :=
      [ { standard := "sufficient space ... so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger"
          concepts := ["kin.speed", "rel.ahead_behind_in_lane", "rel.same_direction", "rel.surface_gap"]
          params := ["p.entering_combination_length", "p.entry_time_headway", "p.same_direction_cosine"]
          convention := "Gap acceptance for a vehicle merging into a column: the space between consecutive caravan vehicles must hold the longest combination of vehicles that may enter (a design-vehicle length) plus a time headway at the subject's current speed to the caravan vehicle ahead of the entering one and the same headway from the subject behind it; the bound rises with the subject's speed (kin.speed). 'each such vehicle or combination of vehicles' is the caravan vehicle ahead of the subject, a vehicle (DEF-NRS-484A-320::vehicle) or a combination (DEF-NRS-484A-050::combination_of_vehicles, 'two or more vehicles coupled together'), in the subject's lane (rel.ahead_behind_in_lane) and direction (rel.same_direction)."
          surrogate := false } ]
    residues := ["The duty is the same for a caravan vehicle that tows another vehicle and for one that does not: the words say so ('whether or not'); a towing vehicle and what it tows form a combination of vehicles, whose gap to the vehicle ahead is read from the combination's body through the aggregate the standard names."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "c4"
          why := "'in a caravan or motorcade' is membership of an organized group of vehicles proceeding together; no atom of the surface denotes it (the record's gap ru.procession_member). The nearest atoms the record maps, rel.ahead_behind_in_lane and rel.same_direction with the motor-vehicle aggregate, hold for any two vehicles following each other in a lane, members of a group or not, as the record's own justification says: written with them, the caravan gap (22.4 m plus two 2 s headways) would bind every following motor vehicle outside a business district. The record's nearest reading (a motor vehicle ahead of x) also contradicts its own branch_1 (the lead car, with nothing ahead, bound and compliant). The same membership ('belongs to x's caravan') is unwritten in the obligation."
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_3
