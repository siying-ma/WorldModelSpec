/-
  NRS_484B_270_2b_o3 — NRS-484B-270-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): When overtaking or passing
    b2 (trigger): a bicycle, an electric bicycle or an electric scooter
    b3 (trigger): proceeding in the same direction,
    b4 (subject): the driver of a motor vehicle
    b5 (sibling): shall exercise due care and:
    b6 (condition): If there is only one lane for traffic proceeding in the same direction,
    b7 (sibling): pass to the left of the bicycle, electric bicycle or electric scooter
    b8 (sibling): at a safe distance, which must be not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter,
    b9 (obligation): and shall not move again to the right side of the highway
    b10 (standard): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter.
    b11 (reference): Except as otherwise provided in NRS 484B.213 and 484B.217 [NRS-484B-213-1, NRS-484B-213-2a, NRS-484B-213-2b, NRS-484B-213-2c, NRS-484B-217-2],
    b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone.

  Elements (span → atoms, derived):
    b1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    b2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b3: atoms ['rel.same_direction', 'kin.speed'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    b6: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    b9: atoms ['rel.occupies', 'st.lane', 'rel.bearing'], derived ['drv.lane.heading_right_of_carrier']

  Compositions (span → node, as, map):
    b11: NRS_484B_213_1 as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2a as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2b as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_213_2c as unless map {'subject': 'subject'} scopes b12
    b11: NRS_484B_217_2 as unless map {'subject': 'subject'} scopes b12

  Literals the text states (each written through its Units constructor):
    b6: 1 count — one

  How each span is written.
    b4  `clsSubject`: ru_aggregate(subject, DEF-NRS-484A-130::motor_vehicle).
    b2  `isRider`: the disjunction of the three admitted aggregates on the quantified road user
        `rider`; `.not (.same rider subject)` keeps the subject out.
    b3  `proceeding`: kin_speed(rider) > p.halt_speed_tolerance; `sameDirection`:
        rel_same_direction(subject, rider) with p.overtake_same_direction_cos.
    b1  `overtaking`: at some observation of the time window p.overtake_window behind, the rider
        was ahead (rel_bearing "ahead", rel_longitudinal_overlap < 0) with aligned headings
        (written `.not (.holdsFor … (.not …))`); and either the rider is not yet behind
        (rel_bearing "behind", overlap < 0) or drv_interaction_overtake_pass(subject, rider)
        rose at some observation of that window (`.rises` of the concept, inside the same
        `.not (.holdsFor … (.not …))`).
    b9  "again": `riderOnRight` = rel_bearing(subject, rider, "right") (lateral component < 0)
        is part of the selection; the move to the right is
        drv_lane_heading_right_of_carrier(subject, lane) with p.course_departure_sin_tol and
        p.halt_speed_tolerance for a lane the rider occupies (rel_occupies).
    b6  `oneLane`: some lane (`existsRegion "lane"`, the st.lane claim) the rider occupies whose
        st_lane_adjacency "count" equals the literal one (`Units.ratio 1 1`, unit count).
    b10 `safelyClear`: rider behind (as in b1) and rel_surface_gap(subject, rider) (distance) at
        least kin_speed(rider) times the headway, selected with `Term.cond`: p.following_headway_ice
        where env_ice_or_snow, else p.following_headway_wet where env_wet_road or
        env_precipitation, else p.following_headway_dry.
    Obligation: for every rider re-bound with the whole selection of the applicability (the
        `selection` formula, the lane quantifier of b6 included), safely clear or no lane the
        rider occupies has the subject heading to its right.
    b11 compositions (unless, scoped to b12): b12 is carried as the node's residue (scope "none":
        it relaxes other rules and leaves this duty unchanged), so no formula of this rule
        carries b12, and there is no formula into which the `.not (.ruleApplies …)` terms could
        be conjoined without leaving them idle. They are not written; see task_result.md.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2b_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The quantified overtaken rider and the lane it occupies. -/
def vRider : Arg := .var "rider"
def vLane : Arg := .var "lane"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseDepartureSinTol : Term := .param "p.course_departure_sin_tol"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- b6: the literal "one" (count). -/
def oneCount : Term := .lit (Units.ratio 1 1) .count

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- b2: a bicycle, an electric bicycle or an electric scooter. -/
def isRider : Formula :=
  .or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- b3: proceeding (moving). -/
def proceeding : Formula := .cmp (.measure "kin_speed" [vRider]) .gt pHaltSpeedTolerance

/-- b3: in the same direction. -/
def sameDirection : Formula := .atom "rel_same_direction" [vSubject, vRider] [pOvertakeSameDirectionCos]

/-- The two bodies' projections on the subject's heading share no length. -/
def noOverlap : Formula := .cmp (.measure "rel_longitudinal_overlap" [vSubject, vRider]) .lt zeroMetres

def riderAhead : Formula := .and (.atom "rel_bearing" [vSubject, vRider, .lit "ahead"] []) noOverlap
def riderBehind : Formula := .and (.atom "rel_bearing" [vSubject, vRider, .lit "behind"] []) noOverlap

/-- b1: the rider was ahead with aligned headings at some observation of the window behind. -/
def wasAheadAligned : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not (.and riderAhead sameDirection)))

/-- b1: the completed pass has risen at some observation of the window behind. -/
def passRecognized : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject"
    (.not (.rises (.derived "drv_interaction_overtake_pass" [vSubject, vRider]
      [pOvertakeWindow, pOvertakeSameDirectionCos]))))

/-- b1: overtaking or passing, under way or just completed. -/
def overtaking : Formula := .and wasAheadAligned (.or (.not riderBehind) passRecognized)

/-- b9 ("again"): the rider on the subject's right. -/
def riderOnRight : Formula := .atom "rel_bearing" [vSubject, vRider, .lit "right"] []

/-- b6: the rider occupies a lane whose count of lanes in its direction is one. -/
def oneLane : Formula :=
  .existsRegion (.lit "lane") "lane"
    (.and (.atom "rel_occupies" [vRider, vLane] [])
      (.cmp (.measure "st_lane_adjacency" [vLane, .lit "count"]) .eq oneCount))

/-- The whole selection of the overtaken rider. -/
def selection : Formula :=
  .and (.not (.same vRider vSubject))
    (.and isRider
      (.and proceeding
        (.and sameDirection
          (.and overtaking
            (.and riderOnRight oneLane)))))

/-- Applicability: b1 (trigger): When overtaking or passing; b2 (trigger): a bicycle, an electric bicycle or an electric scooter; b3 (trigger): proceeding in the same direction,; b6 (condition): If there is only one lane for traffic proceeding in the same direction,; b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone. -/
def applicability : Formula := .existsUser "rider" selection

/-- b10: the following headway for the surface. -/
def headway : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingHeadwayIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingHeadwayWet pFollowingHeadwayDry)

/-- b10: safely clear of the overtaken rider. -/
def safelyClear : Formula :=
  .and riderBehind
    (.cmp (.measure "rel_surface_gap" [vSubject, vRider]) .ge
      (.mul (.measure "kin_speed" [vRider]) headway))

/-- b9: the subject moves to the right of a lane the rider occupies. -/
def movesRight : Formula :=
  .existsRegion (.lit "lane") "lane"
    (.and (.atom "rel_occupies" [vRider, vLane] [])
      (.derived "drv_lane_heading_right_of_carrier" [vSubject, vLane]
        [pCourseDepartureSinTol, pHaltSpeedTolerance]))

/-- Obligation: b9 (obligation): and shall not move again to the right side of the highway; b10 (standard): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter. -/
def obligation : Formula :=
  .forallUser "rider" (.implies selection (.or safelyClear (.not movesRight)))

def rule : Rule :=
  { id := "NRS_484B_270_2b_o3"
    laws := ["NRS-484B-270-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "until the vehicle is safely clear of the overtaken bicycle"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.bearing", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice"]
          convention := "time headway: the subject (the vehicle) is safely clear of the overtaken rider where the rider is behind it (rel.bearing longitudinal component negative, rel.longitudinal_overlap negative) with a gap between the bodies (rel.surface_gap) of at least the rider's speed times the following headway for the surface - ice or snow, else wet road or precipitation, else dry - so that the rider, following, keeps the headway a following road user keeps"
          surrogate := false } ]
    residues := ["the authorization lets a driver passing a rider at the stated clearance pass left of the center or in a no-passing zone, conduct other rules (NRS 484B.213, 484B.217) forbid; it relaxes those rules and leaves the duty not to move back right before being clear unchanged"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_2b_o3
