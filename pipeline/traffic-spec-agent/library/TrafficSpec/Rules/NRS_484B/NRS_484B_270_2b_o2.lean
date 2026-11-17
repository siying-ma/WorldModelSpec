/-
  NRS_484B_270_2b_o2 — NRS-484B-270-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): When overtaking or passing
    b2 (trigger): a bicycle, an electric bicycle or an electric scooter
    b3 (trigger): proceeding in the same direction,
    b4 (subject): the driver of a motor vehicle
    b5 (sibling): shall exercise due care and:
    b6 (condition): If there is only one lane for traffic proceeding in the same direction,
    b7 (obligation): pass to the left of the bicycle, electric bicycle or electric scooter
    b8 (standard): at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter,
    b9 (sibling): and shall not move again to the right side of the highway
    b10 (sibling): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter.
    b11 (reference): Except as otherwise provided in NRS 484B.213 and 484B.217 [NRS-484B-213-1, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2],
    b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone.

  Elements (span → atoms, derived):
    b1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    b2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b3: atoms ['rel.same_direction', 'kin.speed'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    b6: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    b7: atoms ['rel.bearing', 'rel.longitudinal_overlap', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []

  Compositions (span → node, as, map):
    b11: NRS_484B_213_1 as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2a as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2b as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2c as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_217_2 as unless map {'subject': 'subject'} scopes b12

  Literals the text states (each written through its Units constructor):
    b6: 1 count — one
    b8: 3 ft — 3 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    b4: the subject binder's class is `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`;
        'the driver' is read through the vehicle's controlled motion (the record's observable reading).
    b1: `rises (drv_interaction_overtake_pass subject r [p.overtake_window, p.overtake_same_direction_cos])`
        at the judged observation, for a road user r that is not the subject (`not (same subject r)`).
        The concept holds at the recognition only; `rises` judges the act once there.
    b2: r is a member of one of the three admitted aggregates (a disjunction of three `ru_aggregate`).
    b3: at some observation of the window behind (length p.overtake_window, the concept's window),
        r was moving (`kin_speed r > p.halt_speed_tolerance`) with its heading aligned with the
        subject's (`rel_same_direction subject r [p.overtake_same_direction_cos]`), at one common
        observation, as the record's applicability states. "Some observation of the window" is
        `not (holdsFor .time W subject (not φ))`.
    b6: at some observation of that window at which the two were side by side
        (`rel_longitudinal_overlap subject r ≥ 0`), r occupied (`rel_occupies`) a lane
        (`existsRegion "lane"`) whose count of lanes in its direction (`st_lane_adjacency l "count"`)
        is the stated one. The lane is anchored to r by `rel_occupies`.
    b7 + b8: for every road user r re-selected with the applicability's whole selection (written again
        in the obligation by the same `selection` function), at every observation of the window behind
        at which the two are side by side, r lies on the subject's right (`rel_bearing subject r "right"`,
        lateral component negative) and the nearest-point distance between the bodies
        (`rel_surface_gap subject r`, the distance read without a component) is at least the larger of
        the stated 3 feet and p.bicycle_pass_safe_gap. The larger of the two is written with `Term.cond`
        (3 ft where 3 ft ≥ the parameter, the parameter otherwise), one comparison over the selection.
    b11/b12: the five compositions are `unless` scoped to b12. b12 is the node's residue (scope none):
        the authorization relaxes NRS 484B.213 / 484B.217 and leaves this duty unchanged, so b12 has no
        formula in this rule and the compositions, which only restrict b12, have nothing to restrict
        here; the applicability is untouched by them. No `.ruleApplies` is written.
  No narrowing is chosen beyond the record's own.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2b_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBicyclePassSafeGap : Term := .param "p.bicycle_pass_safe_gap"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- b6: the literal "one" (count of lanes in the direction). -/
def oneLane : Term := .lit (Q.ofInt 1) .count
/-- b8: the literal "3 feet". -/
def threeFeet : Term := .lit (Units.feet 3) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Some observation of the window behind (the overtake window) at which φ holds. -/
def onceInWindow (φ : Formula) : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not φ))

/-- b1/b7: the two bodies side by side (projections on the subject's heading share length ≥ 0). -/
def sideBySide (r : Arg) : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, r]) .ge zeroMetres

/-- b2: a bicycle, an electric bicycle or an electric scooter. -/
def riderClass (r : Arg) : Formula :=
  .or (.atom "ru_aggregate" [r, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [r, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [r, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- b3: proceeding (moving) in the same direction, at some observation of the window. -/
def proceedingSameDirection (r : Arg) : Formula :=
  onceInWindow
    (.and (.cmp (.measure "kin_speed" [r]) .gt pHaltSpeedTolerance)
          (.atom "rel_same_direction" [vSubject, r] [pOvertakeSameDirectionCos]))

/-- b6: at some observation of the window at which the two are side by side, r occupies a lane
    whose count of lanes in its direction is one. -/
def onlyOneLane (r : Arg) : Formula :=
  onceInWindow
    (.and (sideBySide r)
          (.existsRegion (.lit "lane") "l"
            (.and (.atom "rel_occupies" [r, .var "l"] [])
                  (.cmp (.measure "st_lane_adjacency" [.var "l", .lit "count"]) .eq oneLane))))

/-- b1, b2, b3, b6: the whole selection of the overtaken road user r. -/
def selection (r : Arg) : Formula :=
  .and (.rises (.derived "drv_interaction_overtake_pass" [vSubject, r]
                  [pOvertakeWindow, pOvertakeSameDirectionCos]))
    (.and (.not (.same vSubject r))
      (.and (riderClass r)
        (.and (proceedingSameDirection r)
              (onlyOneLane r))))

/-- Applicability: b1 (trigger): When overtaking or passing; b2 (trigger): a bicycle, an electric bicycle or an electric scooter; b3 (trigger): proceeding in the same direction,; b6 (condition): If there is only one lane for traffic proceeding in the same direction,; b12 (exception): residue, no formula (see header). -/
def applicability : Formula :=
  .existsUser "r" (selection (.var "r"))

/-- b8: the larger of the stated 3 feet and the reading's clearance. -/
def requiredGap : Term :=
  .cond (.cmp threeFeet .ge pBicyclePassSafeGap) threeFeet pBicyclePassSafeGap

/-- Obligation: b7 (obligation): pass to the left of the bicycle, electric bicycle or electric scooter; b8 (standard): at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, -/
def obligation : Formula :=
  .forallUser "r"
    (.implies (selection (.var "r"))
      (.holdsFor .time pOvertakeWindow "subject"
        (.implies (sideBySide (.var "r"))
          (.and (.atom "rel_bearing" [vSubject, .var "r", .lit "right"] [])
                (.cmp (.measure "rel_surface_gap" [vSubject, .var "r"]) .ge requiredGap)))))

def rule : Rule :=
  { id := "NRS_484B_270_2b_o2"
    laws := ["NRS-484B-270-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle"
          concepts := ["rel.surface_gap"]
          params := ["p.bicycle_pass_safe_gap"]
          convention := "lateral passing clearance: the distance between the nearest points of the two bodies (rel.surface_gap, 'distance between the nearest points of two bodies', which is the distance between any portion of the vehicle and the rider's device) is at least the larger of the stated 3 feet and the bicyclist operating-space clearance the reading sets, at every observation at which the two are side by side"
          surrogate := false } ]
    residues := ["the authorization lets a driver passing a rider at the stated clearance pass left of the center or in a no-passing zone, conduct other rules (NRS 484B.213, 484B.217) forbid; it relaxes those rules and leaves the duty to pass on the left at a safe distance unchanged"]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_2b_o2
