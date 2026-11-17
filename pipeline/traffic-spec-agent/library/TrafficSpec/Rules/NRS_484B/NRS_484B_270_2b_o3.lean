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

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    b4: the subject's class, ru_aggregate DEF-NRS-484A-130::motor_vehicle.
    b2: r a member of any of the three admitted aggregates (a disjunction of ru_aggregate).
    b3: r moving (kin_speed above p.halt_speed_tolerance) with rel_same_direction to the subject
        (p.overtake_same_direction_cos) at the judged observation.
    b1: r was ahead (rel_bearing "ahead" and rel_longitudinal_overlap below zero) with aligned
        headings at some observation of the p.overtake_window behind (`not (holdsFor (not …))`), and
        either r is not yet behind (rel_bearing "behind" with the projections apart) or
        drv.interaction.overtake_pass held at some observation of that window (the concept holds
        at the recognition only, so "has risen" is "held somewhere in the window").
    b9 ("again"): r on the subject's right (rel_bearing "right").
    b6: some lane (existsRegion "lane", i.e. st.lane) r occupies (rel_occupies) has
        st_lane_adjacency "count" equal to the literal one (Units.ratio 1 1, unit count).
    Obligation: for every r with that whole selection (re-written in the obligation), unless the
        subject is safely clear (b10), the subject's heading is right of no lane r occupies
        (drv.lane.heading_right_of_carrier, p.course_departure_sin_tol, p.halt_speed_tolerance).
    b10: r behind (as above) with rel_surface_gap (the body distance) at least r's kin_speed times
        the headway selected by Term.cond: ice/snow → p.following_headway_ice, else wet road or
        precipitation → p.following_headway_wet, else p.following_headway_dry.
    b11/b12: the `unless` compositions scope b12, which the node carries as a residue only
        (the authorization relaxes NRS 484B.213/217 and leaves this duty unchanged); b12 has no
        formula here, so there is nothing to conjoin them into, and no `.ruleApplies` is written.
  No narrowing of my own: every choice above is the record's applicability/obligation text.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2b_o3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCourseDepartureSinTol : Term := .param "p.course_departure_sin_tol"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The literal of b6: "only one" lane in the rider's direction (a count). -/
def oneLane : Term := .lit (Units.ratio 1 1) .count

/-- The overtaken road user and the lane it occupies (quantifier variables). -/
def vRider : Arg := .var "r"
def vLane : Arg := .var "L"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- b2: a bicycle, an electric bicycle or an electric scooter (each admitted aggregate whole). -/
def riderClass : Formula :=
  .or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [vRider, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- The two bodies' projections on the subject's heading share no length. -/
def apart : Formula := .cmp (.measure "rel_longitudinal_overlap" [vSubject, vRider]) .lt zeroMetres

/-- r ahead of the subject: bearing's longitudinal component positive, projections apart. -/
def riderAhead : Formula := .and (.atom "rel_bearing" [vSubject, vRider, .lit "ahead"] []) apart

/-- r behind the subject: bearing's longitudinal component negative, projections apart. -/
def riderBehind : Formula := .and (.atom "rel_bearing" [vSubject, vRider, .lit "behind"] []) apart

/-- b3: headings aligned. -/
def sameDirection : Formula := .atom "rel_same_direction" [vSubject, vRider] [pOvertakeSameDirectionCos]

/-- b1: the pass recognized (drv.interaction.overtake_pass). -/
def passRecognized : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vRider] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- b6: r occupies a lane whose count of lanes in its direction is the literal one. -/
def oneLaneForRider : Formula :=
  .existsRegion (.lit "lane") "L"
    (.and (.atom "rel_occupies" [vRider, vLane] [])
          (.cmp (.measure "st_lane_adjacency" [vLane, .lit "count"]) .eq oneLane))

/-- The whole selection of r (applicability; re-bound in the obligation). -/
def riderSelected : Formula :=
  .and (.not (.same vRider vSubject))
  (.and riderClass
  (.and (.cmp (.measure "kin_speed" [vRider]) .gt pHaltSpeedTolerance)
  (.and sameDirection
  -- b1: r was ahead with aligned headings at some observation of the window behind
  (.and (.not (.holdsFor .time pOvertakeWindow "subject" (.not (.and riderAhead sameDirection))))
  -- b1: the pass under way (r not yet behind) or recognized within the window
  (.and (.or (.not riderBehind)
             (.not (.holdsFor .time pOvertakeWindow "subject" (.not passRecognized))))
  -- b9 ("again"): r on the subject's right
  (.and (.atom "rel_bearing" [vSubject, vRider, .lit "right"] [])
  -- b6
  oneLaneForRider))))))

/-- Applicability: b1 (trigger): When overtaking or passing; b2 (trigger): a bicycle, an electric bicycle or an electric scooter; b3 (trigger): proceeding in the same direction,; b6 (condition): If there is only one lane for traffic proceeding in the same direction,; b12 (exception): when passing to the left of a bicycle, electric bicycle or electric scooter at a safe distance of not less than 3 feet between any portion of the vehicle and the bicycle, electric bicycle or electric scooter, this paragraph authorizes the driver, if it is safe, to pass: (1) To the left of the center of the highway. (2) In a no-passing zone. -/
def applicability : Formula := .existsUser "r" riderSelected

/-- b10: the following headway for the surface — ice or snow, else wet road or precipitation, else dry. -/
def headway : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingHeadwayIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingHeadwayWet pFollowingHeadwayDry)

/-- b10: the subject safely clear of r — r behind it at a body gap of at least r's speed times the headway. -/
def safelyClear : Formula :=
  .and riderBehind
    (.cmp (.measure "rel_surface_gap" [vSubject, vRider]) .ge
          (.mul (.measure "kin_speed" [vRider]) headway))

/-- b9: the subject's heading turned right of a lane r occupies. -/
def movesRight : Formula :=
  .existsRegion (.lit "lane") "L"
    (.and (.atom "rel_occupies" [vRider, vLane] [])
          (.derived "drv_lane_heading_right_of_carrier" [vSubject, vLane]
             [pCourseDepartureSinTol, pHaltSpeedTolerance]))

/-- Obligation: b9 (obligation): and shall not move again to the right side of the highway; b10 (standard): until the vehicle is safely clear of the overtaken bicycle, electric bicycle or electric scooter. -/
def obligation : Formula :=
  .forallUser "r"
    (.implies riderSelected
      (.implies (.not safelyClear) (.not movesRight)))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_2b_o3
