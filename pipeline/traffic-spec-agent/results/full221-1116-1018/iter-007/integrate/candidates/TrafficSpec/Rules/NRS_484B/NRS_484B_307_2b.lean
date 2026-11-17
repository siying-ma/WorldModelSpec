/-
  NRS_484B_307_2b — NRS-484B-307-2b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When the signal is circular green alone:
    s2 (subject): Pedestrians
    s3 (condition): facing such a signal
    s4 (trigger): may proceed across the highway
    s5 (obligation): within any marked or unmarked crosswalk,
    s6 (reference): unless directed otherwise by another device as provided in NRS 484B.283 [NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4].

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal', 'dev.governs', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'st.on_way', 'st.highway'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['dev.position', 'kin.position', 'kin.heading'], derived []
    s4: atoms ['rel.occupies', 'st.lane', 'st.roadway', 'st.on_way', 'st.highway'], derived ['drv.motion.moving_across_carrier']
    s5: atoms ['rel.occupies', 'st.crosswalk'], derived []

  Compositions (span → node, as, map):
    s6: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o2 as exception map {'subject': 'subject'}

  How each span is written.
    s2: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"` as the binder's class.
    s4: one highway `w` (quantifier of kind `highway`) carries the whole applicability, so the
        highway crossed (s4) is the highway the signal is tied to (s1). The subject occupies a
        roadway `r` lying on `w` and a lane `l` lying on `w` for which
        `drv_motion_moving_across_carrier(subject, l; p.halt_speed_tolerance, p.crossing_motion_cos)`
        holds.
    s1: some device `d` of kind `traffic_signal` shows `circular_green` and none of the other
        indications of its contract (every other spelling of `SignalIndication`, each arrow in each
        of its four directions, `dark` and `unknown` included): "alone". It is tied to `w` by an
        intersection `i` lying on `w` (`st_on_way i w`) that `d` governs directly, or that a travel
        region `g` `d` governs enters (`st_lane_enters g i`).
    s3: with Δ = dev_position(d) − kin_position(subject) and h = kin_heading(subject):
        h·Δ > 0, (h·Δ)² ≥ cos² · |Δ|², |Δ|² ≤ reach² — the squared forms of the record. The
        facing is read on the same `d` as s1, inside its quantifier.
    s5: some region of kind `crosswalk` the subject occupies (marked or not: the kind covers both).
    s6: each composed rule as `.not (.ruleApplies id [("subject","subject")])` in the applicability.

  No choice beyond the record's was made: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables. -/
def vW : Arg := .var "w"
def vR : Arg := .var "r"
def vL : Arg := .var "l"
def vD : Arg := .var "d"
def vI : Arg := .var "i"
def vG : Arg := .var "g"
def vX : Arg := .var "x"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

def occupies (a : Arg) : Formula := .atom "rel_occupies" [vSubject, a] []
def onWay (a b : Arg) : Formula := .atom "st_on_way" [a, b] []

/-- s4: the subject proceeds across highway `w`: it occupies a roadway and a lane lying on `w`,
    moving across that lane's designated direction. -/
def crossesHighway : Formula :=
  .and
    (.existsRegion (.lit "roadway") "r" (.and (occupies vR) (onWay vR vW)))
    (.existsRegion (.lit "lane") "l"
      (.and (occupies vL)
        (.and (onWay vL vW)
          (.derived "drv_motion_moving_across_carrier" [vSubject, vL]
            [pHaltSpeedTolerance, pCrossingMotionCos]))))

/-- Every indication of `dev.traffic_signal`'s contract other than `circular_green`. -/
def otherIndications : List String :=
  ["circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown"] ++
  (["green_arrow", "yellow_arrow", "red_arrow", "flashing_yellow_arrow"].flatMap fun k =>
    ["left", "right", "straight", "u_turn"].map fun dir => k ++ "(" ++ dir ++ ")")

def shows (k : String) : Formula := .atom "dev_traffic_signal_shows" [vD, .lit k] []

/-- s1: `d` displays circular green and no other state. -/
def circularGreenAlone : Formula :=
  otherIndications.foldl (fun acc k => .and acc (.not (shows k))) (shows "circular_green")

/-- s1: `d` is a signal of highway `w`: it controls an intersection on `w`, directly or through
    a travel region it governs that enters that intersection. -/
def signalOfHighway : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (onWay vI vW)
      (.or (.atom "dev_governs" [vD, vI] [])
        (.existsRegion (.lit "travel_region") "g"
          (.and (.atom "dev_governs" [vD, vG] []) (.atom "st_lane_enters" [vG, vI] [])))))

/-- s3: the subject faces head `d`. -/
def dX : Term := .sub (.measure "dev_position" [vD, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dY : Term := .sub (.measure "dev_position" [vD, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hX : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hY : Term := .measure "kin_heading" [vSubject, .lit "y"]
def dot : Term := .add (.mul hX dX) (.mul hY dY)
def dist2 : Term := .add (.mul dX dX) (.mul dY dY)

def facing : Formula :=
  .and (.cmp dot .gt zeroMetres)
    (.and (.cmp (.mul dot dot) .ge (.mul (.mul pPedTrafficSignalFacingCos pPedTrafficSignalFacingCos) dist2))
      (.cmp dist2 .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach)))

/-- s6: another device directs the pedestrian as NRS 484B.283 provides. -/
def exceptions : List String :=
  ["NRS_484B_283_1d1", "NRS_484B_283_1d2", "NRS_484B_283_1d3_o1", "NRS_484B_283_1d3_o2",
   "NRS_484B_283_1d4_o1", "NRS_484B_283_1d4_o2"]

def notExcepted : Formula :=
  exceptions.foldl (fun acc rid => .and acc (.not (.ruleApplies rid [("subject", "subject")]))) .tt

/-- Applicability: s1 (trigger): When the signal is circular green alone:; s3 (condition): facing such a signal; s4 (trigger): may proceed across the highway -/
def applicability : Formula :=
  .and
    (.existsRegion (.lit "highway") "w"
      (.and crossesHighway
        (.existsDevice (.lit "traffic_signal") "d"
          (.and circularGreenAlone (.and signalOfHighway facing)))))
    notExcepted

/-- Obligation: s5 (obligation): within any marked or unmarked crosswalk, -/
def obligation : Formula :=
  .existsRegion (.lit "crosswalk") "x" (occupies vX)

def rule : Rule :=
  { id := "NRS_484B_307_2b"
    laws := ["NRS-484B-307-2b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_2b
