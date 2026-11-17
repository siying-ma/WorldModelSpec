/-
  NRS_484B_307_9c — NRS-484B-307-9c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red with a green turn arrow:
    s2 (subject): Pedestrians
    s3 (trigger): facing such a signal
    s4 (obligation): shall not enter the highway,
    s5 (exception): unless permitted to proceed by another device
    s6 (reference): as provided in NRS 484B.283 [NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4].

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['dev.position', 'kin.heading', 'kin.position', 'dev.governs', 'st.travel_region', 'st.intersection', 'st.lane_enters', 'st.region_geometry'], derived []
    s4: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.median_or_divider', 'st.safety_zone'], derived []
    s5: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.heading', 'kin.position', 'rel.occupies', 'st.roadway', 'st.lane'], derived []

  Compositions (span → node, as, map):
    s6: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o1 as exception map {'subject': 'subject'}

  How each span is written:
    s2: binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
    s1: some device h of kind traffic_signal shows circular_red, and green_arrow(left|right|u_turn),
        and does not show circular_green (`redWithGreenTurnArrow`).
    s3: the subject faces h (`faces`, with p.ped_traffic_signal_facing_cos/_reach, Δ from
        kin.position to dev.position, u = kin.heading); h controls an intersection i (dev_governs h i,
        or dev_governs h g with g a travel_region and st_lane_enters g i) whose
        st_region_geometry_distance from the subject is at most p.ped_traffic_signal_facing_reach.
    s5: excepted where some pedestrian_signal d shows walk, or dont_walk_flashing with countdown,
        the subject faces d (p.ped_signal_facing_cos/_reach), and the subject occupies a roadway or
        lane q that d governs (`permittedByPedSignal`).
    s6: `.not (.ruleApplies id [("subject","subject")])` for each of the four 283 rules.
    s4: obligation `¬(onRoadwayOrLane ∧ rises(onRoadwayOrLane ∨ on median ∨ on safety zone))`.
  No choice beyond the record's own s4 reading was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian (s2), claimed by id. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- The subject faces device `dev` (s3 for the vehicular head, s5 for the pedestrian head): with
    Δ the vector from the subject's kin.position to the device's dev.position and u its kin.heading,
    u·Δ > 0, (u·Δ)² ≥ cos² · |Δ|², |Δ|² ≤ reach². -/
def dX (dev : String) : Term :=
  .sub (.measure "dev_position" [.var dev, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dY (dev : String) : Term :=
  .sub (.measure "dev_position" [.var dev, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def dot (dev : String) : Term :=
  .add (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (dX dev))
       (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (dY dev))
def dist2 (dev : String) : Term := .add (.mul (dX dev) (dX dev)) (.mul (dY dev) (dY dev))
def faces (dev : String) (cosP reachP : Term) : Formula :=
  .and (.cmp (dot dev) .gt zeroMetres)
    (.and (.cmp (.mul (dot dev) (dot dev)) .ge (.mul (.mul cosP cosP) (dist2 dev)))
          (.cmp (dist2 dev) .le (.mul reachP reachP)))

def shows (dev ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var dev, .lit ind] []

/-- s1: a steady red with a green turn arrow: circular_red with green_arrow(dir), dir a turn
    direction, and not circular_green. -/
def redWithGreenTurnArrow : Formula :=
  .and (shows "h" "circular_red")
    (.and (.or (shows "h" "green_arrow(left)")
            (.or (shows "h" "green_arrow(right)") (shows "h" "green_arrow(u_turn)")))
          (.not (shows "h" "circular_green")))

/-- s3: "such a signal" controls a junction i the subject is within the facing reach of: h governs
    i, or a travel region g that is an approach to i (st.lane_enters). -/
def controlsNearbyJunction : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and
      (.or (.atom "dev_governs" [.var "h", .var "i"] [])
           (.existsRegion (.lit "travel_region") "g"
              (.and (.atom "dev_governs" [.var "h", .var "g"] [])
                    (.atom "st_lane_enters" [.var "g", .var "i"] []))))
      (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "i"]) .le pPedTrafficSignalFacingReach))

/-- s1 + s3: a traffic signal head showing the steady red with a green turn arrow, controlling a
    junction near the subject, which the subject faces. -/
def facingRedArrowSignal : Formula :=
  .existsDevice (.lit "traffic_signal") "h"
    (.and redWithGreenTurnArrow
      (.and (faces "h" pPedTrafficSignalFacingCos pPedTrafficSignalFacingReach) controlsNearbyJunction))

/-- The subject's footprint overlaps region `q` and `q` is governed by pedestrian head `d`. -/
def onGovernedBy (q : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var q] []) (.atom "dev_governs" [.var "d", .var q] [])

/-- s5: permitted to proceed by another device: the subject overlaps a roadway or lane governed by a
    pedestrian head it faces, showing walk or dont_walk_flashing with countdown. -/
def permittedByPedSignal : Formula :=
  .existsDevice (.lit "pedestrian_signal") "d"
    (.and
      (.or (.atom "dev_pedestrian_signal_state" [.var "d", .lit "walk"] [])
           (.and (.atom "dev_pedestrian_signal_state" [.var "d", .lit "dont_walk_flashing"] [])
                 (.atom "dev_pedestrian_signal_countdown" [.var "d"] [])))
      (.and (faces "d" pPedSignalFacingCos pPedSignalFacingReach)
            (.or (.existsRegion (.lit "roadway") "q" (onGovernedBy "q"))
                 (.existsRegion (.lit "lane") "q" (onGovernedBy "q")))))

def subjMap : List (String × String) := [("subject", "subject")]

/-- Applicability: s1, s3 (triggers); s5 (exception); s6 (compositions as exceptions). -/
def applicability : Formula :=
  .and facingRedArrowSignal
    (.and (.not permittedByPedSignal)
      (.and (.not (.ruleApplies "NRS_484B_283_1d1" subjMap))
        (.and (.not (.ruleApplies "NRS_484B_283_1d2" subjMap))
          (.and (.not (.ruleApplies "NRS_484B_283_1d3_o1" subjMap))
                (.not (.ruleApplies "NRS_484B_283_1d4_o1" subjMap))))))

def occ (kind : String) : Formula :=
  .existsRegion (.lit kind) "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- The footprint overlaps some roadway or lane. -/
def onRoadwayOrLane : Formula := .or (occ "roadway") (occ "lane")

/-- The footprint overlaps some roadway, lane, median or divider, or safety zone. -/
def withinCrossing : Formula :=
  .or onRoadwayOrLane (.or (occ "median_or_divider") (occ "safety_zone"))

/-- Obligation: s4: does not enter: not (on a roadway or lane here, and the crossing condition
    rises here). -/
def obligation : Formula := .not (.and onRoadwayOrLane (.rises withinCrossing))

def rule : Rule :=
  { id := "NRS_484B_307_9c"
    laws := ["NRS-484B-307-9c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9c
