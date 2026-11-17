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
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['dev.position', 'kin.position', 'kin.heading'], derived []
    s4: atoms ['rel.occupies', 'st.lane', 'st.roadway'], derived ['drv.motion.moving_across_carrier']
    s5: atoms ['rel.occupies', 'st.crosswalk'], derived []

  Compositions (span → node, as, map):
    s6: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o2 as exception map {'subject': 'subject'}

  How each is written:
    s2: the binder class `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
    s1: some device `d` of kind traffic_signal (`existsDevice`) with
        `dev_traffic_signal_shows(d, circular_green)` and, for every other state the atom's contract
        lists (circular_yellow, circular_red, flashing_red, flashing_yellow, dark, unknown and the
        four arrows in each of the four directions), `not dev_traffic_signal_shows(d, state)`:
        "circular green alone".
    s3: on the same `d`, with v = dev_position(d) − kin_position(subject) and h = kin_heading(subject)
        (read normalised): v·h > 0, (v·h)² ≥ cos² · |v|² with cos = p.ped_traffic_signal_facing_cos,
        and |v|² ≤ reach² with reach = p.ped_traffic_signal_facing_reach — compared on squares as the
        record states. The comparison reads both the device and the subject, which anchors `d`.
    s4: some roadway `r` the subject occupies, and some lane `l` the subject occupies for which
        `drv_motion_moving_across_carrier(subject, l; p.halt_speed_tolerance, p.crossing_motion_cos)`
        holds. No atom relating a lane to its roadway is claimed; the record's "a lane l of a
        roadway" is written as the subject occupying both, as its element lists.
    s5: obligation: some crosswalk `x` (`existsRegion crosswalk`, marked or unmarked alike) with
        `rel_occupies(subject, x)`.
    s6: each composition as `not (ruleApplies id [subject ↦ subject])` in the applicability.

  No choice beyond the record's was needed; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_2b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables. -/
def vSignal : Arg := .var "d"
def vRoadway : Arg := .var "r"
def vLane : Arg := .var "l"
def vCrosswalk : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrossingMotionCos : Term := .param "p.crossing_motion_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s1: the states of a signal head other than circular green (dev.traffic_signal's contract). -/
def otherStates : List String :=
  [ "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown" ] ++
  ([ "green_arrow", "yellow_arrow", "red_arrow", "flashing_yellow_arrow" ].flatMap fun a =>
    [ "left", "right", "straight", "u_turn" ].map fun dir => a ++ "(" ++ dir ++ ")")

def shows (state : String) : Formula := .atom "dev_traffic_signal_shows" [vSignal, .lit state] []

/-- s1: `d` displays circular green and no other state. -/
def circularGreenAlone : Formula :=
  otherStates.foldl (fun acc st => .and acc (.not (shows st))) (shows "circular_green")

/-- s3: the vector from the subject to the head, and the subject's heading. -/
def dx : Term := .sub (.measure "dev_position" [vSignal, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
def dy : Term := .sub (.measure "dev_position" [vSignal, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
def dotVH : Term := .add (.mul dx hx) (.mul dy hy)
def distSq : Term := .add (.mul dx dx) (.mul dy dy)

/-- s3: the subject faces `d`: the head ahead, within the facing angle and the facing reach. -/
def faces : Formula :=
  .and (.cmp dotVH .gt zeroMetres)
    (.and (.cmp (.mul dotVH dotVH) .ge
              (.mul (.mul pPedTrafficSignalFacingCos pPedTrafficSignalFacingCos) distSq))
          (.cmp distSq .le (.mul pPedTrafficSignalFacingReach pPedTrafficSignalFacingReach)))

/-- s4: the subject proceeds across the highway: it occupies a roadway, and a lane it occupies is
    one it moves across. -/
def proceedsAcross : Formula :=
  .and
    (.existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, vRoadway] []))
    (.existsRegion (.lit "lane") "l"
      (.and (.atom "rel_occupies" [vSubject, vLane] [])
            (.derived "drv_motion_moving_across_carrier" [vSubject, vLane]
              [pHaltSpeedTolerance, pCrossingMotionCos])))

/-- s6: another device directs the pedestrian as NRS 484B.283 provides. -/
def exceptions : List String :=
  [ "NRS_484B_283_1d1", "NRS_484B_283_1d2", "NRS_484B_283_1d3_o1", "NRS_484B_283_1d3_o2"
  , "NRS_484B_283_1d4_o1", "NRS_484B_283_1d4_o2" ]

def notDirectedOtherwise : Formula :=
  exceptions.foldl (fun acc id => .and acc (.not (.ruleApplies id [("subject", "subject")]))) .tt

/-- Applicability: s1 (trigger): When the signal is circular green alone:; s3 (condition): facing such a signal; s4 (trigger): may proceed across the highway -/
def applicability : Formula :=
  .and (.existsDevice (.lit "traffic_signal") "d" (.and circularGreenAlone faces))
    (.and proceedsAcross notDirectedOtherwise)

/-- Obligation: s5 (obligation): within any marked or unmarked crosswalk, -/
def obligation : Formula :=
  .existsRegion (.lit "crosswalk") "x" (.atom "rel_occupies" [vSubject, vCrosswalk] [])

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
