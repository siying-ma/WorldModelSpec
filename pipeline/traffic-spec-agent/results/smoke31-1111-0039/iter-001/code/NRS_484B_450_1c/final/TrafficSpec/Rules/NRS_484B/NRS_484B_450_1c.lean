/-
  NRS_484B_450_1c — NRS-484B-450-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    h1 (obligation): A person shall not stop, stand or park
    h2 (subject): a vehicle,
    h3 (standard): except when necessary to avoid conflict with
    h4 (exception): other traffic
    h5 (exception): or in compliance with law
    h6 (exception): or the directions of a police officer or official traffic-control device,
    h7 (boilerplate): in any of the following places:
    h8 (trigger): Within an intersection.

  Elements (span → atoms, derived):
    h1: atoms ['kin.speed'], derived ['drv.motion.halted']
    h2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    h4: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    h5: atoms ['ru.emergency_vehicle', 'sig.warning_lamp', 'sig.siren'], derived []
    h6: atoms ['dev.human_direction', 'dev.traffic_signal', 'dev.stop_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    h8: atoms ['rel.occupies', 'st.intersection'], derived []

  How each is written:
    h2: the class of x is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    h8: applicability — some region of kind intersection that x occupies (`rel_occupies`).
    h1: the prohibited state is `drv_motion_halted x` at `p.speed_resolution`; the obligation is
        its negation, or one of the exceptions below.
    h3 + h4: some road user y other than x (`.not (.same y x)`), a member of
        DEF-NRS-484A-285::traffic, ahead of x (`rel_bearing x y "ahead"`: the longitudinal
        component positive in x's frame) at a surface gap (`rel_surface_gap x y`, the distance
        between the bodies, the record naming no component) at most `p.stopping_conflict_gap`.
    h5: some road user of class emergency vehicle in the scene showing a warning lamp of any
        colour flashing or rotating (the colours as separate disjuncts, the atom taking one), or
        sounding a siren.
    h6: the intersection the applicability selected is re-selected in the obligation by its whole
        selection (an intersection x occupies), and the exception is required at every such
        intersection: the place the words name is "within an intersection", each one x is in.
        A device directs the stop at intersection i when it governs a travel region c that is i
        itself, or a carrier x occupies whose entrance end is i (`st_lane_enters c i`); written
        once over c so each device leaf appears once. Devices: a human direction of role
        police_officer with indication stop; a traffic signal showing circular_red, red_arrow (any
        direction) or flashing_red; a stop sign.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_450_1c

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vY : Arg := .var "y"
def vE : Arg := .var "e"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStoppingConflictGap : Term := .param "p.stopping_conflict_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- h8: x's footprint overlaps the intersection `i`. -/
def inIntersection : Formula := .atom "rel_occupies" [vX, vI] []

/-- Applicability: h8 (trigger): Within an intersection. -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" inIntersection

/-- h1: x halted at the observation. -/
def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]

/-- h3 + h4: another member of traffic ahead of x within the conflict standoff. -/
def conflict : Formula :=
  .existsUser "y"
    (.and (.not (.same vY vX))
      (.and (.atom "ru_aggregate" [vY, .lit "DEF-NRS-484A-285::traffic"] [])
        (.and (.atom "rel_bearing" [vX, vY, .lit "ahead"] [])
          (.cmp (.measure "rel_surface_gap" [vX, vY]) .le pStoppingConflictGap))))

/-- h5: a warning lamp of any colour, flashing or rotating. -/
def warningLampLit : Formula :=
  let lamp (col mode : String) : Formula := .atom "sig_warning_lamp" [vE, .lit col, .lit mode] []
  .or (lamp "red" "flashing") (.or (lamp "red" "rotating")
    (.or (lamp "blue" "flashing") (.or (lamp "blue" "rotating")
      (.or (lamp "amber" "flashing") (.or (lamp "amber" "rotating")
        (.or (lamp "white" "flashing") (lamp "white" "rotating")))))))

/-- h5: an emergency vehicle in the scene showing its warning lamps or sounding its siren. -/
def emergency : Formula :=
  .existsUser "e"
    (.and (.atom "ru_emergency_vehicle" [vE] [])
      (.or warningLampLit (.atom "sig_siren" [vE] [])))

/-- h6: a red indication of a traffic signal. -/
def signalRed : Formula :=
  let shows (k : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit k] []
  .or (shows "circular_red")
    (.or (shows "red_arrow(left)")
      (.or (shows "red_arrow(right)")
        (.or (shows "red_arrow(straight)")
          (.or (shows "red_arrow(u_turn)") (shows "flashing_red")))))

/-- h6: a police officer, a traffic signal or a stop sign directing a stop governs region `c`. -/
def directsStopAt : Formula :=
  .or
    (.existsDevice (.lit "human_direction") "d"
      (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
        (.and (.atom "dev_human_direction_indication" [vD, .lit "stop"] [])
          (.atom "dev_governs" [vD, vC] []))))
    (.or
      (.existsDevice (.lit "traffic_signal") "d"
        (.and signalRed (.atom "dev_governs" [vD, vC] [])))
      (.existsDevice (.lit "stop_sign") "d"
        (.atom "dev_governs" [vD, vC] [])))

/-- h6: the stop is directed at `i` or at the carrier x entered `i` through. -/
def directed : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and
      (.or (.same vC vI)
        (.and (.atom "rel_occupies" [vX, vC] []) (.atom "st_lane_enters" [vC, vI] [])))
      directsStopAt)

/-- Obligation: h1 (obligation): A person shall not stop, stand or park; h3 (standard): except when necessary to avoid conflict with -/
def obligation : Formula :=
  .or (.not halted)
    (.or conflict
      (.or emergency
        (.forallRegion (.lit "intersection") "i" (.implies inIntersection directed))))

def rule : Rule :=
  { id := "NRS_484B_450_1c"
    laws := ["NRS-484B-450-1c"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "necessary to avoid conflict"
          concepts := ["rel.bearing", "rel.surface_gap"]
          params := ["p.stopping_conflict_gap"]
          convention := "Conflict-standoff convention: a halt is necessary to avoid a conflict where another member of traffic lies ahead of the halted vehicle (the longitudinal component of rel.bearing positive, in the vehicle's frame) at a surface gap no greater than a queue spacing at standstill; the measured gap is compared with the bound."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_450_1c
