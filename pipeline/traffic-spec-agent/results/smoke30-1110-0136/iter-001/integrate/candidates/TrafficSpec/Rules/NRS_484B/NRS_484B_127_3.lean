/-
  NRS_484B_127_3 — NRS-484B-127-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Motor vehicles
    s2 (trigger): being driven
    s3 (condition): upon any highway
    s4 (condition): outside of a business district
    s5 (condition): in a caravan or motorcade
    s6 (condition): whether or not towing other vehicles
    s7 (obligation): shall be operated to allow
    s8 (standard): sufficient space between each such vehicle or combination of vehicles so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    s2: atoms [], derived ['drv.motion.moving']
    s3: atoms ['st.highway', 'rel.occupies'], derived []
    s7: atoms ['rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'ru.aggregate=DEF-NRS-484A-050::combination_of_vehicles'], derived []

  How each span is written:
    s1: the class of x is `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`, the aggregate claimed whole.
    s2: `drv_motion_moving x` with the speed resolution `p.motion_speed_tolerance`.
    s3: some region of kind `highway` that x occupies (`rel_occupies`): the kind as named, so a
        quantifier over it covers every kind refining it.
    s4, s5: the declared assumptions `asm.outside_business_district`, `asm.caravan_or_motorcade`.
    s6: the node's residue; no condition.
    s7, s8: for every road user y other than x that is a member of the vehicle aggregate or of the
        combination-of-vehicles aggregate and is ahead of x in its lane (`rel_ahead_behind_in_lane y x`),
        the surface gap from x to y is at least the design length plus the time headway times x's
        speed, counted once ahead of and once behind the entering vehicle, as the operationalization
        states. The gap is read without a component (`rel_surface_gap x y`), which the atom's
        contract makes the distance between the nearest points of the two bodies, as the record
        writes `rel.surface_gap(x, y)`. With no such road user the universal holds: the duty is met.

  No choice beyond the record's was needed: no narrowing of this file's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCaravanEntryTimeHeadway : Term := .param "p.caravan_entry_time_headway"
def pCaravanEntryVehicleLength : Term := .param "p.caravan_entry_vehicle_length"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vY : Arg := .var "y"
def vH : Arg := .var "h"

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- s2: x is being driven — in motion beyond the speed resolution. -/
def beingDriven : Formula := .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]

/-- s3: x is upon some highway. -/
def uponHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vX, vH] [])

/-- Applicability: s2 (trigger): being driven; s3 (condition): upon any highway; s4 (condition): outside of a business district; s5 (condition): in a caravan or motorcade; s6 (condition): whether or not towing other vehicles -/
def applicability : Formula :=
  .and beingDriven
    (.and uponHighway
      (.and (.asm "asm.outside_business_district") (.asm "asm.caravan_or_motorcade")))

/-- s7: y is a vehicle or combination of vehicles ahead of x in its lane. -/
def vehicleAhead : Formula :=
  .and (.not (.same vX vY))
    (.and
      (.or (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-320::vehicle"] [])
           (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-050::combination_of_vehicles"] []))
      (.atom "rel_ahead_behind_in_lane" [vY, vX] []))

/-- s8: the entering design vehicle's length plus the time headway at x's speed, ahead of and
    behind the entering vehicle. -/
def entryBound : Term :=
  .add (.add pCaravanEntryVehicleLength (.mul pCaravanEntryTimeHeadway (.measure "kin_speed" [vX])))
    (.mul pCaravanEntryTimeHeadway (.measure "kin_speed" [vX]))

/-- Obligation: s7 (obligation): shall be operated to allow; s8 (standard): sufficient space between each such vehicle or combination of vehicles so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger -/
def obligation : Formula :=
  .forallUser "y"
    (.implies vehicleAhead
      (.cmp (.measure "rel_surface_gap" [vX, vY]) .ge entryBound))

def rule : Rule :=
  { id := "NRS_484B_127_3"
    laws := ["NRS-484B-127-3"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.outside_business_district", "asm.caravan_or_motorcade"]
    intentions := []
    operationalizations :=
      [ { standard := "sufficient space ... so as to enable any other vehicle or combination of vehicles to enter and occupy such space without danger"
          concepts := ["kin.speed", "rel.ahead_behind_in_lane", "rel.surface_gap"]
          params := ["p.caravan_entry_vehicle_length", "p.caravan_entry_time_headway"]
          convention := "Gap-acceptance convention for a merging vehicle: the space must hold the entering design vehicle (the longest combination of vehicles, so that 'any other vehicle or combination' fits) plus an accepted time headway ahead of it and another behind it at the caravan's speed. The bound is p.caravan_entry_vehicle_length plus p.caravan_entry_time_headway times x's kin.speed, the headway term counted once for the gap ahead of the entering vehicle and once for the gap behind it; the bound grows with the speed, so the degree of the speed factor is read. 'each such vehicle or combination of vehicles' is the road user ahead in the lane, a member of the vehicle aggregate or of the combination-of-vehicles aggregate."
          surrogate := false } ]
    residues := ["The words extend the duty to vehicles towing others and to those not towing alike: whether a caravan vehicle tows adds no condition, and a towed unit ahead is already a member of the vehicle or combination-of-vehicles aggregate the obligation reads."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_127_3
