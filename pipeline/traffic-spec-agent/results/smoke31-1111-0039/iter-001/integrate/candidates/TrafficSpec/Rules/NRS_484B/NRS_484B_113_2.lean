/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (subject): The driver of a vehicle
    b2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a
    b5 (condition): street
    b6 (condition): corner

  Elements (span → atoms, derived):
    b1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b2: atoms ['st.intersection', 'st.crosswalk', 'rel.occupies', 'kin.velocity', 'kin.heading', 'kin.yaw_rate'], derived ['drv.motion.reversing', 'drv.motion.yawing']
    b6: atoms ['st.intersection', 'rel.occupies'], derived []

  How each is written:
    b1: the class of `x` is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`; the driver is read through
        the vehicle's conduct (the record's observable reading). The record's applicability is that
        class and nothing else, so `applicability` adds no condition of its own.
    b2: "back" is `drv_motion_reversing x` (speed_floor p.speed_resolution), read from kinematics
        (kin.velocity, kin.heading) and never from the gear. Three alternatives, joined by `or` under
        one `not`:
        (a) "back into an intersection": reversing, and for some `intersection` region r the
            footprint begins here to overlap it: `rises (rel_occupies x r)` inside the region
            quantifier, so the entry is the entry into that one region;
        (b) "on or over a crosswalk": reversing, and x occupies some `crosswalk` region;
        (c) "around a street corner": `asm.within_city_limits` (b5, "street") holds, x is reversing
            and yawing (`drv_motion_yawing x`, yaw_floor p.yaw_rate_resolution), and x occupies some
            `intersection` region (b6, "corner", as the record maps it).
    b5: the declared assumption `asm.within_city_limits`, conjoined into (c) where the record places it.
    b6: `rel_occupies x r` over `intersection` regions, inside (c).

  No choice beyond the record's own was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"
def pYawRateResolution : Term := .param "p.yaw_rate_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: the record's is the class of `x` alone ("x is a vehicle"), carried by `clsX`;
    b5 and b6 are conditions of the corner limb of the obligation, where the record places them. -/
def applicability : Formula := .tt

/-- b2 "back": x moves backwards relative to its own body. -/
def reversing : Formula := .derived "drv_motion_reversing" [vX] [pSpeedResolution]

/-- b2 "around": x's heading changes. -/
def yawing : Formula := .derived "drv_motion_yawing" [vX] [pYawRateResolution]

/-- (a) b2 "back into an intersection": reversing as the footprint begins to overlap an intersection. -/
def backIntoIntersection : Formula :=
  .and reversing
    (.existsRegion (.lit "intersection") "r" (.rises (.atom "rel_occupies" [vX, .var "r"] [])))

/-- (b) b2 "on or over a crosswalk": reversing while the footprint overlaps a crosswalk. -/
def backOverCrosswalk : Formula :=
  .and reversing
    (.existsRegion (.lit "crosswalk") "c" (.atom "rel_occupies" [vX, .var "c"] []))

/-- (c) b2/b5/b6 "around a street corner": within city limits, reversing and yawing while the
    footprint overlaps an intersection. -/
def backAroundCorner : Formula :=
  .and (.asm "asm.within_city_limits")
    (.and reversing
      (.and yawing
        (.existsRegion (.lit "intersection") "k" (.atom "rel_occupies" [vX, .var "k"] []))))

/-- Obligation: b2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a
    street corner. -/
def obligation : Formula :=
  .not (.or backIntoIntersection (.or backOverCrosswalk backAroundCorner))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2
