/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    s2 (condition): When proper signs have been erected,
    s3 (subject): the driver of a vehicle
    s4 (sibling): shall stop or yield
    s5 (sibling): at a clearly marked stop line
    s6 (sibling): or, if there is none, before entering the crosswalk on the near side of the intersection
    s7 (sibling): or, if there is none, then at the point nearest the intersection
    s8 (sibling): where the driver has a view of approaching traffic on the through highway.
    s9 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,
    s10 (obligation): the driver shall yield the right-of-way
    s11 (condition): to other vehicles which have entered the intersection from such through highway
    s12 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s10: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s11: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway'], derived ['drv.motion.entering_region']

  Compositions (span → node, as, map):
    s9: NRS_484B_257_1_o1 as compliance map {'x': 'x'}

  How each is written:
    s3: the class of x is `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s1, s2 (`selection i c`): x enters intersection i at this observation
      (drv_motion_entering_region x i) through a travel region c it occupies whose entrance end is
      i (rel_occupies x c, st_lane_enters c i); a stop sign or a yield sign governs c or i; no
      human direction with role police_officer and no traffic signal that is not inoperative
      governs c or i. x's membership of traffic (DEF-NRS-484A-285::traffic) is conjoined in the
      applicability.
    s9: `.rule NRS_484B_257_1_o1 {x ↦ x}` conjoined in the applicability (compliance).
    s10, s11, s12: the obligation re-selects every (i, c) by the same `selection`, and for every
      highway h2 that i lies on and c does not (st_on_way), forbids a vehicle y other than x that
      either (s11) occupies i and has occupied it since an entry into i (`since`) at which it
      occupied a travel region c2 entering i and lying on h2, or (s12) occupies a travel region c2
      entering i and lying on h2, does not occupy i, and has its ground distance to i
      (st_region_geometry_distance) at most its speed times p.immediate_hazard_gap.
  No choice beyond the record's own readings was made; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"

def zeroMetres : Term := .lit Q.zero .metre

def vehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def traffic : Arg := .lit "DEF-NRS-484A-285::traffic"

def occupies (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []
def entersAt (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []

/-- Device `d` governs the approach carrier `c` or the intersection `i`. -/
def governsEither (d c i : String) : Formula :=
  .or (.atom "dev_governs" [.var d, .var c] []) (.atom "dev_governs" [.var d, .var i] [])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, vehicle] []

/-- s1, s2: x enters intersection `i` through carrier `c`, signed with a stop or yield sign and not
    controlled by a police officer or an operating traffic signal. -/
def selection (i c : String) : Formula :=
  .and (.derived "drv_motion_entering_region" [vX, .var i] [])
    (.and (occupies "x" c)
      (.and (entersAt c i)
        (.and (.or (.existsDevice (.lit "stop_sign") "ds" (governsEither "ds" c i))
                   (.existsDevice (.lit "yield_sign") "dy" (governsEither "dy" c i)))
          (.and (.not (.existsDevice (.lit "human_direction") "dh"
                  (.and (.atom "dev_human_direction_role" [.var "dh", .lit "police_officer"] [])
                        (governsEither "dh" c i))))
                (.not (.existsDevice (.lit "traffic_signal") "dt"
                  (.and (.not (.atom "dev_inoperative" [.var "dt"] []))
                        (governsEither "dt" c i))))))))

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; s2 (condition): When proper signs have been erected,; s9 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,; s11 (condition): to other vehicles which have entered the intersection from such through highway -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" (selection "i" "c")))
    (.and (.atom "ru_aggregate" [vX, traffic] [])
      (.rule "NRS_484B_257_1_o1" [("x", "x")]))

/-- s11: `y` occupies `i`, and has occupied it since an entry into `i` at which it occupied a
    carrier `c2` entering `i` and lying on `h2`. -/
def enteredFromThrough (i h2 : String) : Formula :=
  .and (occupies "y" i)
    (.since (occupies "y" i)
      (.and (.derived "drv_motion_entering_region" [.var "y", .var i] [])
        (.existsRegion (.lit "travel_region") "c2"
          (.and (occupies "y" "c2") (.and (entersAt "c2" i) (onWay "c2" h2))))))

/-- s12: `y` on a carrier `c2` entering `i` and lying on `h2`, outside `i`, within its speed times
    the critical gap of `i`. -/
def immediateHazard (i h2 : String) : Formula :=
  .existsRegion (.lit "travel_region") "c2"
    (.and (occupies "y" "c2")
      (.and (entersAt "c2" i)
        (.and (onWay "c2" h2)
          (.and (.not (occupies "y" i))
            (.cmp (.measure "st_region_geometry_distance" [.var "y", .var i]) .le
                  (.mul (.measure "kin_speed" [.var "y"]) pImmediateHazardGap))))))

/-- Obligation: s10 (obligation): the driver shall yield the right-of-way; s12 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c"
    (.implies (selection "i" "c")
      (.forallRegion (.lit "highway") "h2"
        (.implies (.and (onWay "i" "h2") (.not (onWay "c" "h2")))
          (.forallUser "y"
            (.implies (.and (.not (.same (.var "y") vX)) (.atom "ru_aggregate" [.var "y", vehicle] []))
              (.not (.or (enteredFromThrough "i" "h2") (immediateHazard "i" "h2")))))))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "approaching so closely on the through highway as to constitute an immediate hazard during the time the driver is moving across or within the intersection"
          concepts := ["kin.speed", "rel.occupies", "st.highway", "st.lane_enters", "st.on_way", "st.region_geometry"]
          params := ["p.immediate_hazard_gap"]
          convention := "Gap acceptance (HCM critical headway for a minor-street crossing or turn): a vehicle on an approach carrier of the intersection lying on the through highway (rel.occupies, st.lane_enters, st.on_way), outside the intersection, is an immediate hazard where its ground distance to the intersection (st.region_geometry) is at most its speed (kin.speed) times p.immediate_hazard_gap; the critical gap stands for the time the subject needs to move across or within the intersection, and the bound moves with the other vehicle's proximity and speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
