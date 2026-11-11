/-
  NRS_484B_440_1_o2 — NRS-484B-440-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (trigger): Upon any highway
    g2 (condition): outside of a business or residence district
    g3 (sibling): no person shall stop, park or leave standing
    g4 (subject): any vehicle, whether attended or unattended,
    g5 (trigger): upon the paved or main-traveled part of the highway
    g6 (sibling): when it is practicable to stop, park or so leave such vehicle off such part of the highway,
    g7 (boilerplate): but in every event
    g8 (obligation): an unobstructed width of the highway
    g9 (trigger): opposite a standing vehicle
    g10 (standard): shall be left for the free passage of other vehicles
    g11 (boilerplate): and
    g12 (sibling): a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    g1: atoms ['rel.occupies', 'st.highway'], derived []
    g4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g5: atoms ['rel.occupies', 'st.roadway'], derived []
    g8: atoms ['st.lane', 'st.on_way', 'st.highway', 'rel.occupies', 'st.region_geometry'], derived []
    g9: atoms ['kin.speed', 'rel.longitudinal_overlap'], derived ['drv.motion.halted']
    g13: atoms ['kin.engine_running', 'sig.hazard', 'rel.occupies', 'st.roadway'], derived []

  How each is written:
    g4: `ru_aggregate x "DEF-NRS-484A-320::vehicle"` as the class of x.
    g9 (standing): x halted, `drv_motion_halted x [p.speed_resolution]` (reads kin.speed).
    g1 + g5: some highway region h and some roadway region r on it (`st_on_way r h`) whose
      footprint x overlaps (`rel_occupies x r`): x is upon the main-travelled part of a highway.
    g2: `not (asm asm.within_business_or_residence_district)`.
    g13: x is not read as disabled: not (engine not running and hazard lamps on). Its place on the
      roadway is the roadway occupancy g5 already requires.
    g8 + g10: the obligation re-selects h exactly as the applicability does (a highway with a
      roadway on it that x occupies), then asks for some lane L on h (`st_on_way L h`) that x does
      not occupy, whose ground distance from x's body (`st_region_geometry_distance`) is at most
      p.opposite_lane_reach, whose `st_lane_width` is at least p.free_passage_width, and that no road
      user other than x, halted (`drv_motion_halted`) and overlapping x along x's heading
      (`rel_longitudinal_overlap x y > 0`), occupies.

  Choices the record left open: none beyond the record's own narrowing on g8.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFreePassageWidth : Term := .param "p.free_passage_width"
def pOppositeLaneReach : Term := .param "p.opposite_lane_reach"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- A road user at a standstill (drv.motion.halted at the speed resolution). -/
def halted (v : Arg) : Formula := .derived "drv_motion_halted" [v] [pSpeedResolution]

/-- g1 + g5: x's footprint overlaps a roadway `r` lying on the highway `h`. -/
def onRoadwayOf (h : String) : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "st_on_way" [.var "r", .var h] [])
          (.atom "rel_occupies" [vX, .var "r"] []))

/-- g13: x read as disabled — engine not running with hazard lamps flashing. -/
def disabled : Formula :=
  .and (.not (.atom "kin_engine_running" [vX] [])) (.atom "sig_hazard" [vX] [])

/-- Applicability: g1 (trigger): Upon any highway; g2 (condition): outside of a business or residence district; g5 (trigger): upon the paved or main-traveled part of the highway; g9 (trigger): opposite a standing vehicle; g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and (halted vX)
    (.and (.existsRegion (.lit "highway") "h" (onRoadwayOf "h"))
      (.and (.not (.asm "asm.within_business_or_residence_district"))
        (.not disabled)))

/-- g8 + g10: lane `L` is free for passage — no other halted road user alongside x occupies it. -/
def unobstructed (l : String) : Formula :=
  .forallUser "y"
    (.implies
      (.and (.not (.same (.var "y") vX))
        (.and (halted (.var "y"))
              (.cmp (.measure "rel_longitudinal_overlap" [vX, .var "y"]) .gt zeroMetres)))
      (.not (.atom "rel_occupies" [.var "y", .var l] [])))

/-- Obligation: g8 (obligation): an unobstructed width of the highway; g10 (standard): shall be left for the free passage of other vehicles -/
def obligation : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (onRoadwayOf "h")
      (.existsRegion (.lit "lane") "L"
        (.and (.atom "st_on_way" [.var "L", .var "h"] [])
          (.and (.not (.atom "rel_occupies" [vX, .var "L"] []))
            (.and (.cmp (.measure "st_region_geometry_distance" [vX, .var "L"]) .le pOppositeLaneReach)
              (.and (.cmp (.measure "st_lane_width" [.var "L"]) .ge pFreePassageWidth)
                (unobstructed "L")))))))

def rule : Rule :=
  { id := "NRS_484B_440_1_o2"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_business_or_residence_district"]
    intentions := []
    operationalizations :=
      [ { standard := "an unobstructed width left for the free passage of other vehicles"
          concepts := ["drv.motion.halted", "rel.longitudinal_overlap", "st.lane_width"]
          params := ["p.free_passage_width", "p.opposite_lane_reach", "p.speed_resolution"]
          convention := "Free-passage convention: the width left for passage is a lane beside the standing vehicle, not overlapped by it and not taken by another halted road user alongside it, whose measured width (st.lane_width) is at least a design passenger-car width plus lateral clearance."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o2
