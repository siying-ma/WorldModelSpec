/-
  NRS_484B_217_2 — NRS-484B-217-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): Except as otherwise provided in subsections 3 and 4,
    s2 (subject): a driver
    s3 (obligation): shall not drive on the left side of the highway within such zone or drive across or on the left side of any pavement striping designed to mark such zone throughout its length.
    s6 (exception): A driver may drive across a pavement striping marking such zone
    s7 (exception): to an adjoining highway if the driver has first given the appropriate turn signal
    s8 (standard): and there will be no impediment to
    s8b (exception): oncoming or following traffic.
    s9 (exception): Except where otherwise provided,
    s10 (exception): a driver may drive across a pavement striping marking such a zone
    s11 (exception): to make a left-hand turn
    s12 (exception): if the driver has first given the appropriate turn signal
    s13 (reference): in compliance with NRS 484B.413 [NRS-484B-413-2],
    s14 (standard): if it is safe
    s15 (standard): and if it would not be an impediment to
    s15b (exception): oncoming or following traffic.

  How each span is written.
    s2  `clsSubject`: the subject is a member of the admitted aggregate DEF-NRS-484A-320::vehicle
        (`ru_aggregate`), the driver read through the vehicle's controlled motion (the plan's
        observable reading).
    s3  `applicability`: the subject occupies a highway `h` on which a centre line `c` lies
        (`st_on_way c h`), and is in a no-passing zone: it occupies a travel region that a zone sign
        of kind no_passing, not an end sign, governs (`zoneBySign`), or it occupies a lane whose left
        marking is solid or double_solid yellow (`zoneByMarking`); a solid_broken left marking (any
        colour, as the record states) leaves the zone unknown (`definedWhen` over `ff`).
        `obligation`: for every highway `h` the subject occupies and every centre line `c` on `h`,
        the body does not reach past `c` to its left (`crossing c`): twice the lateral offset of `c`
        (`prim_region_lateral_offset`, left positive) is below the full width (`kin_extent` width)
        less twice `p.lateral_position_tolerance` — the offset below half the width less the
        tolerance, written without a divisor. Every observation is judged ("throughout its length").
    s6/s10 the permitted crossing is the same `crossing c`.
    s7/s12 the signal: `sig_turn_indicator` left or `sig_hand_signal` left at the last observation
        before the crossing began, the crossing holding at every observation since
        (`.since (crossing c) (signal ∧ ¬crossing c)`). The signal is shared by both exceptions
        (E3, E4) and is written once, outside their disjunction.
    s7  E3 (`toAdjoiningHighway`): within `p.vehicle_turn_window` ahead the subject occupies a highway
        `h2` other than `h` and no longer occupies `h`.
    s8/s8b/s15/s15b `noImpediment`: no road user `u` other than the subject, a member of
        DEF-NRS-484A-285::traffic, that is oncoming (`rel_oncoming`, `p.oncoming_heading_cos`) or
        following (`rel_bearing` behind and `rel_same_direction`, `p.contest_same_direction_cos`),
        has a closest approach within `p.conflict_horizon` at a centre distance below
        `p.conflict_centre_clearance`. Shared by E3 and E4, written once outside their disjunction.
    s10/s11 E4 (`toLeftTurn`): the declared intention int.left_turn of the subject holds at the
        observation at an intersection or a driveway/alley entrance lying on `h` (`st_on_way`).
    s13 compliance with NRS_484B_413_2 for the course change of this turn: within
        `p.vehicle_turn_window` behind, at the last observation at which NRS_484B_413_2 engages for
        the subject (`ruleApplies`), it is complied with (`rule`, `atLast`); where it engages at no
        observation of that window, the composition holds (`holdsFor` of its non-engagement).
    s14 `safe`: no road user other than the subject is in contact with it (`rel_contact`) or has the
        closest approach above.
    s9  residue (the plan's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_217_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pContestSameDirectionCos : Term := .param "p.contest_same_direction_cos"
def pLateralPositionTolerance : Term := .param "p.lateral_position_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables. -/
def vH : Arg := .var "h"
def vC : Arg := .var "c"
def vR : Arg := .var "r"
def vD : Arg := .var "d"
def vL : Arg := .var "l"
def vH2 : Arg := .var "h2"
def vT : Arg := .var "t"
def vU : Arg := .var "u"
def vV : Arg := .var "v"

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: the subject occupies a highway on which a centre line lies. -/
def onDividedHighway : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (occupies vH)
      (.existsRegion (.lit "centre_line") "c" (.atom "st_on_way" [vC, vH] [])))

/-- s3: the zone indicated by a sign — a travel region the subject occupies that a no_passing zone
    sign (not an end sign) governs. -/
def zoneBySign : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (occupies vR)
      (.existsDevice (.lit "zone_sign") "d"
        (.and (.atom "dev_governs" [vD, vR] [])
          (.and (.atom "dev_zone_sign_kind" [vD, .lit "no_passing"] [])
                (.not (.atom "dev_zone_sign_end" [vD] []))))))

def leftMarking (ty col : String) : Formula := .atom "st_lane_marking" [vL, .lit "left", .lit ty, .lit col] []

/-- s3: the zone indicated by a marking — a lane the subject occupies whose left marking is solid or
    double_solid yellow; a solid_broken left marking leaves membership unknown. -/
def zoneByMarking : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (occupies vL)
      (.or (.or (leftMarking "solid" "yellow") (leftMarking "double_solid" "yellow"))
           (.definedWhen (.not (.atom "st_lane_marking" [vL, .lit "left", .lit "solid_broken"] [])) .ff)))

/-- Applicability (s3). -/
def applicability : Formula := .and onDividedHighway (.or zoneBySign zoneByMarking)

/-- s3/s6/s10: the body reaches past centre line `c` to its left: its lateral offset below half the
    width less the tolerance (both sides doubled, so no divisor). -/
def crossing : Formula :=
  let off : Term := .quantity "prim_region_lateral_offset" [vSubject, vC] []
  let width : Term := .measure "kin_extent" [vSubject, .lit "width"]
  .cmp (.add off off) .lt (.sub (.sub width pLateralPositionTolerance) pLateralPositionTolerance)

/-- s7/s12: the appropriate turn signal, left. -/
def signalLeft : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit "left"] [])
      (.atom "sig_hand_signal" [vSubject, .lit "left"] [])

/-- s7/s12: the signal given at the last observation before the crossing began. -/
def signalledFirst : Formula := .since crossing (.and signalLeft (.not crossing))

/-- The traffic-conflict technique: centres approach within the horizon to below the clearance. -/
def conflict (u : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, u] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, u] [pConflictHorizon]) .lt
             pConflictCentreClearance)

/-- s8/s8b/s15/s15b: no oncoming or following member of traffic is impeded. -/
def noImpediment : Formula :=
  .forallUser "u"
    (.implies
      (.and (.not (.same vU vSubject))
        (.and (.atom "ru_aggregate" [vU, .lit "DEF-NRS-484A-285::traffic"] [])
          (.or (.atom "rel_oncoming" [vSubject, vU] [pOncomingHeadingCos])
               (.and (.atom "rel_bearing" [vSubject, vU, .lit "behind"] [])
                     (.atom "rel_same_direction" [vSubject, vU] [pContestSameDirectionCos])))))
      (.not (conflict vU)))

/-- s14: it is safe — no other road user in contact with the subject or in conflict with it. -/
def safe : Formula :=
  .forallUser "v"
    (.implies (.not (.same vV vSubject))
      (.and (.not (.atom "rel_contact" [vSubject, vV] [])) (.not (conflict vV))))

/-- s7 (E3): to an adjoining highway — within the turn window ahead the subject occupies a highway
    other than `h` and no longer occupies `h`. -/
def toAdjoiningHighway : Formula :=
  .within .time pVehicleTurnWindow "subject"
    (.existsRegion (.lit "highway") "h2"
      (.and (occupies vH2)
        (.and (.not (.same vH2 vH)) (.not (occupies vH)))))

def turnTarget (kind : String) : Formula :=
  .existsRegion (.lit kind) "t"
    (.and (.atom "st_on_way" [vT, vH] []) (.intent "int.left_turn" vSubject vT))

def map413 : List (String × String) := [("subject", "subject")]

/-- s13: compliance with NRS_484B_413_2 at the course change of the turn, the last observation in the
    turn window behind at which it engages; complied with where it engages nowhere in that window. -/
def compliance413 : Formula :=
  .or (.atLast .time pVehicleTurnWindow "subject" (.ruleApplies "NRS_484B_413_2" map413)
         (.rule "NRS_484B_413_2" map413))
      (.holdsFor .time pVehicleTurnWindow "subject" (.not (.ruleApplies "NRS_484B_413_2" map413)))

/-- s10/s11/s13/s14 (E4): to make a left-hand turn at an intersection or a driveway/alley entrance on
    `h`, the signal complying with NRS_484B_413_2, and safe. -/
def toLeftTurn : Formula :=
  .and (.or (turnTarget "intersection") (turnTarget "driveway_or_alley_entrance"))
       (.and compliance413 safe)

/-- Obligation (s3, excused by s6–s15b). -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (occupies vH)
      (.forallRegion (.lit "centre_line") "c"
        (.implies (.atom "st_on_way" [vC, vH] [])
          (.or (.not crossing)
            (.and signalledFirst
              (.and noImpediment (.or toAdjoiningHighway toLeftTurn)))))))

def rule : Rule :=
  { id := "NRS_484B_217_2"
    laws := ["NRS-484B-217-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "no impediment to oncoming or following traffic"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a road user of traffic is impeded where its centre and the subject's, under constant velocities, approach within the conflict horizon to a centre distance below the conflict clearance; oncoming is rel.oncoming within the opposed-heading tolerance, following is a road user behind the subject (negative longitudinal bearing) with headings aligned within the same-direction tolerance; read at every observation of the crossing"
          surrogate := false }
      , { standard := "it is safe"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: the crossing is safe where no road user of the scene is in contact with the subject and none approaches the subject's centre, under constant velocities, within the conflict horizon to a centre distance below the conflict clearance; read at every observation of the crossing"
          surrogate := false }
      , { standard := "no impediment to oncoming or following traffic"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "as for s8: traffic-conflict technique on oncoming (rel.oncoming) and following (behind, headings aligned) members of traffic, read at every observation of the crossing"
          surrogate := false } ]
    residues := ["'Except where otherwise provided' defers to provisions it does not name; those provisions are judged by their own rules, and this rule's verdict on crossing the striping to make a left-hand turn is the same whether or not they apply."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_217_2
