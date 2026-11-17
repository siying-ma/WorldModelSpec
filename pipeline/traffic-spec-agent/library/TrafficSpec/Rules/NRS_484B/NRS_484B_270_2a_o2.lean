/-
  NRS_484B_270_2a_o2 — NRS-484B-270-2a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): When overtaking or passing
    a2 (trigger): a bicycle, an electric bicycle or an electric scooter
    a3 (trigger): proceeding in the same direction,
    a4 (subject): the driver of a motor vehicle
    a5 (sibling): shall exercise due care and:
    a6 (condition): If there is more than one lane for traffic proceeding in the same direction,
    a7 (obligation): move the vehicle to the lane to the immediate left,
    a8 (standard): if the lane is available and moving into the lane is reasonably safe.

  Elements (span → atoms, derived):
    a1: atoms ['rel.longitudinal_overlap'], derived ['drv.interaction.overtake_pass']
    a2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    a3: atoms ['rel.same_direction', 'kin.speed'], derived []
    a4: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    a6: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency'], derived []
    a7: atoms ['rel.occupies', 'st.lane', 'st.lane_adjacency', 'rel.longitudinal_overlap', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Literals the text states (each written through its Units constructor):
    a6: 1 count — one

  How each span is written:
    a4: the binder class, `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
    a1: the rider r is selected at the observation at which
        `drv_interaction_overtake_pass(subject, r)` rises (window p.overtake_window, same_dir_cos
        p.overtake_same_direction_cos); "side by side" is `rel_longitudinal_overlap(subject, r) ≥ 0`.
    a2: r is not the subject and is a member of one of the three admitted aggregates (a disjunction).
    a3: at some observation of the window behind (`¬ holdsFor W ¬ …`), r's speed is above
        p.halt_speed_tolerance and `rel_same_direction(subject, r, p.overtake_same_direction_cos)`.
    a6: at some observation of the window behind at which the two are side by side, r occupies a
        lane whose `st_lane_adjacency_count` is above the literal one.
    a7: re-binding r with its whole selection (a1, a2, a3, a6), the subject is a member of
        DEF-NRS-484A-320::vehicle, and at every observation of the window behind at which the two
        are side by side the subject occupies the left neighbour (`st_lane_adjacency_left`) of a
        lane r occupies and occupies no lane r occupies.
    a8: the duty is excused where, at the pass's start (`atLast` over the window behind, at the
        last observation at which r was ahead — `rel_bearing … "ahead"` — with no shared length and
        headings aligned), a lane r occupies has no left neighbour, or its left neighbour is governed
        by a temporary traffic control device, or a road user other than the subject and r
        occupying it has a surface gap to the subject below the subject's speed times the headway
        (ice or snow: p.following_headway_ice; else wet road or precipitation:
        p.following_headway_wet; else p.following_headway_dry), selected with `Term.cond`.

  Choices the record left open (declared in `narrowings`):
    a8: "r's lane" is read as some lane r occupies at the pass's start: the left lane is
        unavailable or unsafe where it is so beside some lane the rider occupies.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_270_2a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- a6: the literal "one" (lanes), a count. -/
def oneLane : Term := .lit (Units.ratio 1 1) .count

def vR : Arg := .var "r"

/-- The two bodies side by side: their projections on the subject's heading share length. -/
def sideBySide : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, vR]) .ge zeroMetres

/-- a2: r is a bicycle, an electric bicycle or an electric scooter (not the subject). -/
def riderClass : Formula :=
  .and (.not (.same vSubject vR))
    (.or (.atom "ru_aggregate" [vR, .lit "DEF-NRS-484A-025::bicycle"] [])
      (.or (.atom "ru_aggregate" [vR, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
        (.atom "ru_aggregate" [vR, .lit "DEF-NRS-484B-018::electric_scooter"] [])))

/-- a1: the pass of r by the subject is recognized here. -/
def passRecognized : Formula :=
  .rises (.derived "drv_interaction_overtake_pass" [vSubject, vR]
    [pOvertakeWindow, pOvertakeSameDirectionCos])

/-- a3: at some observation of the window behind, r moved with its heading aligned with the subject's. -/
def proceedingSameDirection : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject"
    (.not (.and (.cmp (.measure "kin_speed" [vR]) .gt pHaltSpeedTolerance)
      (.atom "rel_same_direction" [vSubject, vR] [pOvertakeSameDirectionCos]))))

/-- a6: at some observation of the window behind at which the two were side by side, r occupied a
    lane with more than one lane in its direction. -/
def moreThanOneLane : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject"
    (.not (.and sideBySide
      (.existsRegion (.lit "lane") "lr"
        (.and (.atom "rel_occupies" [vR, .var "lr"] [])
          (.cmp (.measure "st_lane_adjacency_count" [.var "lr"]) .gt oneLane))))))

/-- The whole selection of r: a1, a2, a3, a6. -/
def selection : Formula :=
  .and riderClass (.and passRecognized (.and proceedingSameDirection moreThanOneLane))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Applicability: a1 (trigger): When overtaking or passing; a2 (trigger): a bicycle, an electric bicycle or an electric scooter; a3 (trigger): proceeding in the same direction,; a6 (condition): If there is more than one lane for traffic proceeding in the same direction, -/
def applicability : Formula := .existsUser "r" selection

/-- a8: the pass's start — r ahead of the subject, no shared length, headings aligned. -/
def passStart : Formula :=
  .and (.atom "rel_bearing" [vSubject, vR, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vR]) .lt zeroMetres)
      (.atom "rel_same_direction" [vSubject, vR] [pOvertakeSameDirectionCos]))

/-- a8: the following headway for the surface: ice or snow, else wet road or precipitation, else dry. -/
def headway : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingHeadwayIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingHeadwayWet pFollowingHeadwayDry)

/-- a8: the left lane `lg` is not reasonably safe: a road user other than the subject and r
    occupying it is nearer the subject's body than the subject's speed times the headway. -/
def unsafeLane : Formula :=
  .existsUser "u"
    (.and (.not (.same (.var "u") vSubject))
      (.and (.not (.same (.var "u") vR))
        (.and (.atom "rel_occupies" [.var "u", .var "lg"] [])
          (.cmp (.measure "rel_surface_gap" [vSubject, .var "u"]) .lt
            (.mul (.measure "kin_speed" [vSubject]) headway)))))

/-- a8: the left lane `lg` is not available: a temporary traffic control device governs it. -/
def closedLane : Formula :=
  .existsDevice (.lit "temporary_traffic_control") "d" (.atom "dev_governs" [.var "d", .var "lg"] [])

/-- a8: at the pass's start, the lane to the immediate left of a lane r occupies is missing,
    unavailable or not reasonably safe. -/
def leftLaneUnavailableOrUnsafe : Formula :=
  .atLast .time pOvertakeWindow "subject" passStart
    (.existsRegion (.lit "lane") "le"
      (.and (.atom "rel_occupies" [vR, .var "le"] [])
        (.or (.not (.existsRegion (.lit "lane") "lf" (.atom "st_lane_adjacency_left" [.var "le", .var "lf"] [])))
          (.existsRegion (.lit "lane") "lg"
            (.and (.atom "st_lane_adjacency_left" [.var "le", .var "lg"] [])
              (.or closedLane unsafeLane))))))

/-- a7: while side by side, the subject is in the left neighbour of a lane r occupies and in no
    lane r occupies. -/
def inLeftLaneWhileAlongside : Formula :=
  .holdsFor .time pOvertakeWindow "subject"
    (.implies sideBySide
      (.and
        (.existsRegion (.lit "lane") "la"
          (.and (.atom "rel_occupies" [vR, .var "la"] [])
            (.existsRegion (.lit "lane") "lb"
              (.and (.atom "st_lane_adjacency_left" [.var "la", .var "lb"] [])
                (.atom "rel_occupies" [vSubject, .var "lb"] [])))))
        (.forallRegion (.lit "lane") "lc"
          (.implies (.atom "rel_occupies" [vR, .var "lc"] [])
            (.not (.atom "rel_occupies" [vSubject, .var "lc"] []))))))

/-- Obligation: a7 (obligation): move the vehicle to the lane to the immediate left,; a8 (standard): if the lane is available and moving into the lane is reasonably safe. -/
def obligation : Formula :=
  .forallUser "r"
    (.implies selection
      (.or leftLaneUnavailableOrUnsafe
        (.and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])
          inLeftLaneWhileAlongside)))

def rule : Rule :=
  { id := "NRS_484B_270_2a_o2"
    laws := ["NRS-484B-270-2a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "if the lane is available and moving into the lane is reasonably safe"
          concepts := ["dev.governs", "dev.temporary_traffic_control", "env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.bearing", "rel.occupies", "rel.surface_gap", "st.lane_adjacency"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice"]
          convention := "gap acceptance at the start of the pass: at the last observation of the window behind at which the rider was ahead of the subject (rel.bearing longitudinal component positive, no shared length) with aligned headings, the lane to the rider's lane's immediate left exists (st.lane_adjacency), no temporary traffic control device governs it (available), and no road user other than the subject and the rider occupying it is nearer the subject's body (rel.surface_gap) than the subject's speed times the following headway for the surface: ice or snow, else wet road or precipitation, else dry (reasonably safe)"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "a8"
          why := "'the lane' to the rider's lane's immediate left is read beside some lane the rider occupies at the pass's start: the left lane is missing, unavailable or unsafe where it is so beside some lane the rider occupies"
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_270_2a_o2
