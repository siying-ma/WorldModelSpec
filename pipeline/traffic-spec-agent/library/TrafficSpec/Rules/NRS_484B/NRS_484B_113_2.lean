/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): Shall not back
    s3 (condition): into an intersection
    s4 (condition): on or over a crosswalk
    s5 (condition): or around a
    s6 (condition): street
    s7 (condition): corner

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms [], derived ['drv.motion.backing']
    s3: atoms ['st.intersection', 'rel.occupies'], derived []
    s4: atoms ['st.crosswalk', 'rel.occupies'], derived []
    s5: atoms [], derived ['drv.motion.turning']
    s7: atoms ['st.intersection', 'rel.occupies'], derived []

  How each is written (the record's applicability and obligation, verbatim in structure):
    s1: binder class `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`; the driver is read through the
        vehicle's motion (the record's observable reading, not restated).
    s2: obligation `not drv_motion_backing(x; p.motion_speed_tolerance)` at the observation.
    s3: `existsRegion intersection i: rises(rel_occupies(x, i))` — entry at this observation.
    s4: `existsRegion crosswalk c: rel_occupies(x, c)`.
    s5–s7: `asm.within_city_limits ∧ drv_motion_turning(x; p.yaw_rate_tolerance) ∧
        existsRegion intersection j: rel_occupies(x, j)`.
    The applicability is the disjunction of the three places. No choice was left open by the
    record: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: `x` enters an intersection at this observation — its footprint begins to overlap one. -/
def intoIntersection : Formula :=
  .existsRegion (.lit "intersection") "i" (.rises (.atom "rel_occupies" [vX, .var "i"] []))

/-- s4: `x`'s footprint overlaps a crosswalk (marked or unmarked). -/
def onCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [vX, .var "c"] [])

/-- s5–s7: `x` rounds a street corner — inside a city (s6), yawing (s5), its footprint on an
    intersection (s7). -/
def aroundStreetCorner : Formula :=
  .and (.asm "asm.within_city_limits")
    (.and (.derived "drv_motion_turning" [vX] [pYawRateTolerance])
      (.existsRegion (.lit "intersection") "j" (.atom "rel_occupies" [vX, .var "j"] [])))

/-- Applicability: s3 (condition): into an intersection; s4 (condition): on or over a crosswalk; s5 (condition): or around a; s6 (condition): street; s7 (condition): corner -/
def applicability : Formula :=
  .or intoIntersection (.or onCrosswalk aroundStreetCorner)

/-- Obligation: s2 (obligation): Shall not back -/
def obligation : Formula :=
  .not (.derived "drv_motion_backing" [vX] [pMotionSpeedTolerance])

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2
