/-
  NRS_484B_440_1_o1 — NRS-484B-440-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (trigger): Upon any highway
    g2 (condition): outside of a business or residence district
    g3 (obligation): no person shall stop, park or leave standing
    g4 (subject): any vehicle, whether attended or unattended,
    g5 (condition): upon the paved or main-traveled part of the highway
    g6 (standard): when it is practicable to stop, park or so leave such vehicle off such part of the highway,
    g7 (boilerplate): but in every event
    g8 (sibling): an unobstructed width of the highway
    g9 (sibling): opposite a standing vehicle
    g10 (sibling): shall be left for the free passage of other vehicles
    g11 (boilerplate): and
    g12 (sibling): a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    g1: atoms ['rel.occupies', 'st.highway'], derived []
    g3: atoms ['kin.speed', 'rel.ahead_behind_in_lane', 'rel.surface_gap', 'dev.human_direction', 'dev.traffic_signal', 'dev.stop_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived ['drv.motion.halted']
    g4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g5: atoms ['rel.occupies', 'st.roadway'], derived []
    g13: atoms ['kin.engine_running', 'sig.hazard', 'rel.occupies', 'st.roadway'], derived []

  How each span is written:
    g4: `ru_aggregate x DEF-NRS-484A-320::vehicle`, the binder's class.
    g1: some region of kind highway that x occupies (`rel_occupies`), in the applicability.
    g2: the assumption `asm.within_business_or_residence_district` does not hold.
    g13: not (x's engine not running, x's hazard lamps on, and x occupying some roadway); the
      roadway is bound afresh by its own quantifier, as the record's applicability states it.
    g3: the halt is `drv_motion_halted x` with `p.speed_resolution`; its definitional exclusions
      are a disjunction: some other road user y (`not (same x y)`) ahead of x in its lane
      (`rel_ahead_behind_in_lane y x`, y ahead of x) with the surface gap from x to y (its
      distance, no component) at most `p.stopping_conflict_gap`; or a human direction indicating
      stop, a traffic signal showing circular_red, red_arrow (any of its four directions) or
      flashing_red, or a stop sign, governing (`dev_governs`) some travel region x occupies.
    g5: some region of kind roadway that x occupies, in the obligation, as the record's
      obligation places it.
    g6: some shoulder whose ground distance from x's body (`st_region_geometry_distance`) is at
      most `p.offroad_stop_reach`; the shoulder is anchored to x by that distance.
  No choice beyond the record's words was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOffroadStopReach : Term := .param "p.offroad_stop_reach"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStoppingConflictGap : Term := .param "p.stopping_conflict_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- `x` occupies region `r`. -/
def occX (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- g1: x is upon a highway. -/
def onHighway : Formula := .existsRegion (.lit "highway") "hw" (occX "hw")

/-- g2: the place lies inside a business or residence district. -/
def inDistrict : Formula := .asm "asm.within_business_or_residence_district"

/-- g13: x disabled on the roadway — engine not running, hazard lamps on, on a roadway. -/
def disabledOnRoadway : Formula :=
  .and (.not (.atom "kin_engine_running" [vX] []))
    (.and (.atom "sig_hazard" [vX] [])
      (.existsRegion (.lit "roadway") "rdx" (occX "rdx")))

/-- Applicability: g1 (trigger): Upon any highway; g2 (condition): outside of a business or residence district; g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and onHighway (.and (.not inDistrict) (.not disabledOnRoadway))

/-- g3: x is halted. -/
def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]

/-- g5: x's footprint overlaps a roadway. -/
def onRoadway : Formula := .existsRegion (.lit "roadway") "rd" (occX "rd")

/-- g6: some shoulder lies within the off-road stopping reach of x's body. -/
def shoulderWithinReach : Formula :=
  .existsRegion (.lit "shoulder") "sh"
    (.cmp (.measure "st_region_geometry_distance" [vX, .var "sh"]) .le pOffroadStopReach)

/-- g3 exclusion: some other road user ahead of x in its lane within the conflict standoff gap. -/
def avoidsConflict : Formula :=
  .existsUser "y"
    (.and (.not (.same vX (.var "y")))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "y", vX] [])
        (.cmp (.measure "rel_surface_gap" [vX, .var "y"]) .le pStoppingConflictGap)))

/-- Device `d` governs a travel region `x` occupies (`r` names the region variable). -/
def governsWhereX (d r : String) : Formula :=
  .existsRegion (.lit "travel_region") r
    (.and (occX r) (.atom "dev_governs" [.var d, .var r] []))

/-- g3 exclusion: a police officer's stop direction governs where x is. -/
def humanStop : Formula :=
  .existsDevice (.lit "human_direction") "dh"
    (.and (.atom "dev_human_direction_indication" [.var "dh", .lit "stop"] [])
      (governsWhereX "dh" "trh"))

/-- A red indication of signal `d`: circular red, a red arrow, or flashing red. -/
def showsRed (d : String) : Formula :=
  let shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit i] []
  .or (shows "circular_red")
    (.or (shows "red_arrow(left)")
      (.or (shows "red_arrow(right)")
        (.or (shows "red_arrow(straight)")
          (.or (shows "red_arrow(u_turn)") (shows "flashing_red")))))

/-- g3 exclusion: a traffic signal showing red governs where x is. -/
def signalRed : Formula :=
  .existsDevice (.lit "traffic_signal") "dsig"
    (.and (showsRed "dsig") (governsWhereX "dsig" "trs"))

/-- g3 exclusion: a stop sign governs where x is. -/
def stopSign : Formula :=
  .existsDevice (.lit "stop_sign") "dstop" (governsWhereX "dstop" "trp")

/-- The exclusions of the defined 'stop'. -/
def excluded : Formula :=
  .or avoidsConflict (.or humanStop (.or signalRed stopSign))

/-- Obligation: g3 (obligation): no person shall stop, park or leave standing; g6 (standard): when it is practicable to stop, park or so leave such vehicle off such part of the highway, -/
def obligation : Formula :=
  .not (.and halted
    (.and onRoadway
      (.and shoulderWithinReach (.not excluded))))

def rule : Rule :=
  { id := "NRS_484B_440_1_o1"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_business_or_residence_district"]
    intentions := []
    operationalizations :=
      [ { standard := "practicable to stop, park or so leave such vehicle off such part of the highway"
          concepts := ["st.region_geometry", "st.shoulder"]
          params := ["p.offroad_stop_reach"]
          convention := "Off-road stopping convention: moving off the main-traveled part is practicable where a shoulder lies within the reach of a short lateral move from the halted vehicle's body; the ground distance from the body to the nearest shoulder is the measured magnitude compared with the reach."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o1
