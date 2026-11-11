/-
  NRS_484B_250_4_o2 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When a vehicle enters an intersection
    s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    s3 (subject): the driver of the vehicle
    s4 (sibling): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop
    s5 (sibling): at a clearly marked stop line
    s6 (sibling): or, if there is none, before entering the crosswalk on the near side of the intersection
    s7 (sibling): or, if there is none, at the point nearest the intersection
    s8 (sibling): where the driver has a view of approaching traffic on the through highway.
    s9 (condition): After making such a stop,
    s10 (trigger): the driver shall proceed
    s11 (standard): cautiously,
    s12 (obligation): yielding to vehicles
    s13 (condition): which have previously completed a stop
    s14 (condition): or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s10: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s12: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s13: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'kin.speed'], derived ['drv.motion.halted']
    s14: atoms ['rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    s9: NRS_484B_250_4_o1 as compliance map {'x': 'x'}

  How each is written:
    s1/s10 (the entry): `drv_motion_entering_region x i` over the intersections `i` of the scene,
      with x on an approach carrier `c` of i (`rel_occupies x c`, `st_lane_enters c i`, `c` a
      travel region). The duty is judged at that one observation.
    s2: some traffic signal `d` (the device quantifier's kind) governs i or c (`dev_governs`, either
      suffices) and is `dev_inoperative` at the entry.
    s3: the subject's class, `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s9: `.rule NRS_484B_250_4_o1 {x ↦ x}` conjoined into the applicability (compliance).
    s12/s14: no vehicle y other than x occupies i at the entry.
    s12/s13: no vehicle y other than x is on another approach carrier c2 of i (x not on c2) with
      `since (y on c2 and not in i) (x's halt begins on c — halted, rises — while y is halted on
      c2 and was halted at the observation before)`. "Halted at the observation before" is written
      `halted y ∧ ¬ rises (halted y)`.
    s11: no road user z other than x with `prim_closest_approach_within x z h` and
      `prim_closest_approach_distance x z h < p.conflict_clearance`, h = p.immediate_hazard_gap.
    The obligation repeats the applicability's whole selection of i and c (entry, carrier, the
    inoperative signal) and requires the duty for every such pair.
  No choice beyond the record's: no narrowing of my own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vY : Arg := .var "y"
def vC2 : Arg := .var "c2"
def vZ : Arg := .var "z"

def vehicle (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-320::vehicle"] []
def occupies (a r : Arg) : Formula := .atom "rel_occupies" [a, r] []
def entering (a r : Arg) : Formula := .derived "drv_motion_entering_region" [a, r] []
def halted (a : Arg) : Formula := .derived "drv_motion_halted" [a] [pSpeedResolution]
def laneEnters (c r : Arg) : Formula := .atom "st_lane_enters" [c, r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- s2: a traffic signal governing the intersection i or the approach carrier c is inoperative. -/
def signalInoperative : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.or (.atom "dev_governs" [vD, vI] []) (.atom "dev_governs" [vD, vC] []))
          (.atom "dev_inoperative" [vD] []))

/-- s1, s10, s2: x enters i through its approach carrier c, under an inoperative signal. -/
def entry : Formula :=
  .and (entering vX vI) (.and (occupies vX vC) (.and (laneEnters vC vI) signalInoperative))

/-- Applicability: s1 (trigger): When a vehicle enters an intersection; s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,; s9 (condition): After making such a stop,; s10 (trigger): the driver shall proceed; s13 (condition): which have previously completed a stop; s14 (condition): or are within the intersection. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" entry))
       (.rule "NRS_484B_250_4_o1" [("x", "x")])

/-- s12, s14: no vehicle other than x is within i. -/
def noVehicleWithin : Formula :=
  .forallUser "y" (.implies (.and (.not (.same vY vX)) (vehicle vY)) (.not (occupies vY vI)))

/-- s13: y has stayed on c2 and out of i since x's halt on c began while y was already halted on c2. -/
def stoppedFirst : Formula :=
  .since (.and (occupies vY vC2) (.not (occupies vY vI)))
    (.and (.and (.rises (halted vX)) (occupies vX vC))
          (.and (.and (halted vY) (.not (.rises (halted vY)))) (occupies vY vC2)))

/-- s12, s13: no vehicle other than x waits on another approach carrier of i having stopped first. -/
def noVehicleStoppedFirst : Formula :=
  .forallUser "y" (.implies (.and (.not (.same vY vX)) (vehicle vY))
    (.forallRegion (.lit "travel_region") "c2"
      (.not (.and (.and (laneEnters vC2 vI) (.not (occupies vX vC2))) stoppedFirst))))

/-- s11: no road user other than x in predicted conflict with x. -/
def noConflict : Formula :=
  .forallUser "z" (.implies (.not (.same vZ vX))
    (.not (.and (.derived "prim_closest_approach_within" [vX, vZ] [pImmediateHazardGap])
                (.cmp (.quantity "prim_closest_approach_distance" [vX, vZ] [pImmediateHazardGap])
                  .lt pConflictClearance))))

/-- Obligation: s11 (standard): cautiously,; s12 (obligation): yielding to vehicles -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c"
    (.implies entry (.and noVehicleWithin (.and noVehicleStoppedFirst noConflict))))

def rule : Rule :=
  { id := "NRS_484B_250_4_o2"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "proceed cautiously"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.immediate_hazard_gap", "p.conflict_clearance"]
          convention := "Surrogate safety measure of a conflict (FHWA SSAM): at x's entry, no other road user's centre is predicted, under constant velocities, to come within p.conflict_clearance of x's within p.immediate_hazard_gap. The primitives are not a stand-in for contact or the danger of a crash by themselves; the bound the parameters set is the standard's."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_250_4_o2
