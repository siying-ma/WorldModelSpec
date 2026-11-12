/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    g2 (condition): When proper signs have been erected,
    g3 (subject): the driver of a vehicle
    g4 (sibling): shall stop or yield
    g5 (sibling): at a clearly marked stop line
    g6 (sibling): or, if there is none, before entering the crosswalk on the near side of the intersection
    g7 (sibling): or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    g8 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,
    g9 (subject): the driver
    g10 (obligation): shall yield
    g11 (standard): the right-of-way
    g12 (condition): to other vehicles which have entered the intersection from such through highway
    g13 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard
    g14 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    g1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    g2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    g3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g8: atoms ['dev.stop_sign', 'dev.yield_sign', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'rel.occupies', 'st.lane_direction', 'prim.region_offset_along', 'kin.path_length'], derived ['drv.motion.at_rest', 'drv.motion.decelerating']
    g9: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g10: atoms [], derived ['drv.motion.at_rest']
    g12: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region', 'st.on_way', 'st.highway', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs'], derived []
    g14: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.at_rest']

  How each is written.
    g3/g9: ego's class is ru_aggregate DEF-NRS-484A-320::vehicle (the record's agency reading).
    g14: the judged observation: ego overlaps an intersection i and is not drv.motion.at_rest, and
      ego has overlapped i at every observation since the entry (a `since` over rel_occupies ego i).
    entry: the last observation at which ego occupied a travel region c (its approach carrier)
      and not yet i, after which it has overlapped i continuously; c enters i (st_lane_enters c i).
      Requiring ego outside i there makes "entered from c" an observed transition and decides
      the binding of c to i itself false rather than leaving it to i's absent lane relations.
    g2: at the entry, a stop sign or a yield sign governs c (dev_governs over the devices of each
      kind); status read through presence (the record's narrowing).
    g1: at the entry, not (ego is DEF-NRS-484A-285::traffic and either a human_direction device
      of role police_officer governs c or i, or a traffic_signal head governs c or i and is not
      dev_inoperative).
    g8: at the entry, `since (ego occupies c) act`: the act was made at some observation of ego's
      current stay on c (the approach start is the start of that stay, the history of the act's
      search; where the stay reaches the trace start without the act, `since` is unknown, as the
      applicability states). The act: ego at the governing place, and either drv.motion.at_rest,
      or (no stop sign governs c, a yield sign does, and drv.motion.decelerating held at some
      observation of the `.path` window p.yield_slowing_distance behind, read through ego's
      kin.path_length). The governing place: a stop line marking c (st_entrance_of); where none,
      a crosswalk marking c that ego does not occupy; where neither, i with ego outside it. Ego is
      at the place where its body lies within p.stop_point_tolerance of the region
      (st_region_geometry_distance) and its reference point is not past it along c
      (prim_region_offset_along ego r c ≥ 0, the side read along c's st.lane_direction). The
      stopping zone of the yield limb is that same "at the place" relation.
    g12: b, a DEF-NRS-484A-320::vehicle other than ego, overlaps i and, since a past observation at
      which it occupied a through carrier cb, has overlapped i at every observation. A through
      carrier: it enters i, lies on a highway on which c does not lie, and no stop or yield sign
      governs it.
    g13 (operationalization): b occupies such a carrier cb and its body's ground distance to i is
      at or below kin_speed b × p.immediate_hazard_time.
    g10/g11 (operationalization): ego is not in conflict with each such b: not both
      prim_closest_approach_within ego b and prim_closest_approach_distance ego b below
      p.conflict_clearance, both with horizon p.conflict_horizon. g10's "at rest" limb is not
      written in the obligation: the duty is judged only where ego is not at rest (g14), so that
      limb is false wherever the obligation is read.
    The obligation repeats the applicability's whole selection of i and c (`judgedWith`) and
    states the duty for every selected pair. Its copy of g1 reads the control itself (officer or
    operating signal over c or i) without ego's DEF-NRS-484A-285::traffic membership: every
    class the binder's DEF-NRS-484A-320::vehicle includes is a traffic class, so wherever the
    rule is engaged the membership holds and the two copies select the same pairs; the
    membership is read once, in the applicability.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- Quantified variables: the intersection, ego's carrier, the other vehicle and its carrier. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vB : Arg := .var "b"
def vCb : Arg := .var "cb"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pDecelTolerance : Term := .param "p.decel_tolerance"
def pImmediateHazardTime : Term := .param "p.immediate_hazard_time"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldSlowingDistance : Term := .param "p.yield_slowing_distance"

def zeroMetres : Term := .lit Q.zero .metre

def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
def atRest (x : Arg) : Formula := .derived "drv_motion_at_rest" [x] [pRestSpeedTolerance]
def decelerating (x : Arg) : Formula :=
  .derived "drv_motion_decelerating" [x] [pDecelTolerance, pRestSpeedTolerance]

/-- A sign of the kind governs the carrier `r` (g2, g8, g12). -/
def signGoverns (kind d : String) (r : Arg) : Formula :=
  .existsDevice (.lit kind) d (.atom "dev_governs" [.var d, r] [])

/-- g1: a police officer or an operating signal head governs c or i. -/
def control : Formula :=
    (.or
      (.existsDevice (.lit "human_direction") "dOfficer"
        (.and (.atom "dev_human_direction_role" [.var "dOfficer", .lit "police_officer"] [])
          (.or (.atom "dev_governs" [.var "dOfficer", vC] [])
               (.atom "dev_governs" [.var "dOfficer", vI] []))))
      (.existsDevice (.lit "traffic_signal") "dSignal"
        (.and
          (.or (.atom "dev_governs" [.var "dSignal", vC] [])
               (.atom "dev_governs" [.var "dSignal", vI] []))
          (.not (.atom "dev_inoperative" [.var "dSignal"] [])))))

/-- g1: ego, as traffic, is controlled so. -/
def controlled : Formula :=
  .and (.atom "ru_aggregate" [vEgo, .lit "DEF-NRS-484A-285::traffic"] []) control

/-- g8: ego's body within the stop-point tolerance of region `r`, its reference point not past `r`
    along c. -/
def near (r : Arg) : Formula :=
  .and (.cmp (.measure "st_region_geometry_distance" [vEgo, r]) .le pStopPointTolerance)
    (.cmp (.quantity "prim_region_offset_along" [vEgo, r, vC] []) .ge zeroMetres)

/-- Some region of the kind marks c's entrance. -/
def marksC (kind v : String) : Formula :=
  .existsRegion (.lit kind) v (.atom "st_entrance_of" [.var v, vC] [])

/-- g8 (g5–g7): ego at the governing place: the stop line marking c; else short of the crosswalk
    marking c; else outside i at c's entrance end. -/
def atPlace : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "l"
      (.and (.atom "st_entrance_of" [.var "l", vC] []) (near (.var "l"))))
    (.or
      (.and (.not (marksC "stop_line" "l"))
        (.existsRegion (.lit "crosswalk") "w"
          (.and (.atom "st_entrance_of" [.var "w", vC] [])
            (.and (.not (occupies vEgo (.var "w"))) (near (.var "w"))))))
      (.and (.not (marksC "stop_line" "l"))
        (.and (.not (marksC "crosswalk" "w"))
          (.and (.not (occupies vEgo vI)) (near vI)))))

/-- g8: a deceleration at some observation of the last p.yield_slowing_distance travelled. -/
def slowed : Formula :=
  .not (.holdsFor .path pYieldSlowingDistance "ego" (.not (decelerating vEgo)))

/-- g8: the act at an observation: at the place, at rest; or, under a yield sign alone, slowed. -/
def act : Formula :=
  .and atPlace
    (.or (atRest vEgo)
      (.and (.not (signGoverns "stop_sign" "dStop" vC))
        (.and (signGoverns "yield_sign" "dYield" vC) slowed)))

/-- The entry observation on c: c enters i, a sign governs c, no control (g1, `ctl`), and the
    act made during ego's stay on c. -/
def entryWith (ctl : Formula) : Formula :=
  .and (.and (occupies vEgo vC) (.not (occupies vEgo vI)))
    (.and (.atom "st_lane_enters" [vC, vI] [])
      (.and (.or (signGoverns "stop_sign" "dStop" vC) (signGoverns "yield_sign" "dYield" vC))
        (.and (.not ctl) (.since (occupies vEgo vC) act))))

/-- g14: ego moving within i, entered from c as `entryWith ctl` states. -/
def judgedWith (ctl : Formula) : Formula :=
  .and (occupies vEgo vI)
    (.and (.not (atRest vEgo)) (.since (occupies vEgo vI) (entryWith ctl)))

/-- The applicability's selection of i and c. -/
def judged : Formula := judgedWith controlled

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := isVehicle vEgo

/-- Applicability: g1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; g2 (condition): When proper signs have been erected,; g8 (condition): After having stopped or, in the event of a yield sign, slowed or stopped,; g12 (condition): to other vehicles which have entered the intersection from such through highway; g14 (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" judged)

/-- g12: cb is a carrier of the through highway entering i. -/
def throughCarrier : Formula :=
  .and (.atom "st_lane_enters" [vCb, vI] [])
    (.and
      (.existsRegion (.lit "highway") "h"
        (.and (.atom "st_on_way" [vCb, .var "h"] []) (.not (.atom "st_on_way" [vC, .var "h"] []))))
      (.and (.not (signGoverns "stop_sign" "dStopB" vCb))
        (.not (signGoverns "yield_sign" "dYieldB" vCb))))

/-- g12: b overlaps i after an entry from a through carrier. -/
def enteredFromThrough : Formula :=
  .and (occupies vB vI)
    (.since (occupies vB vI)
      (.existsRegion (.lit "travel_region") "cb" (.and (occupies vB vCb) throughCarrier)))

/-- g13: b on a through carrier, its distance to i at or below its speed times the critical headway. -/
def immediateHazard : Formula :=
  .existsRegion (.lit "travel_region") "cb"
    (.and (occupies vB vCb)
      (.and throughCarrier
        (.cmp (.measure "st_region_geometry_distance" [vB, vI]) .le
          (.mul (.measure "kin_speed" [vB]) pImmediateHazardTime))))

/-- g11: projected conflict between ego and b. -/
def inConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, vB] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vEgo, vB] [pConflictHorizon]) .lt
      pConflictClearance)

/-- Obligation: g10 (obligation): shall yield; g11 (standard): the right-of-way; g13 (standard): or which are approaching so closely on such through highway as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (judgedWith control)
        (.forallUser "b"
          (.implies
            (.and (isVehicle vB)
              (.and (.not (.same vB vEgo)) (.or enteredFromThrough immediateHazard)))
            (.not inConflict)))))

def rule : Rule :=
  { id := "NRS_484B_257_1_o2"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\""
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity enter by degree through the projected velocities and positions."
          surrogate := false }
      , { standard := "approaching so closely on such through highway as to constitute an immediate hazard"
          concepts := ["kin.speed", "rel.occupies", "st.lane_enters", "st.on_way", "st.region_geometry"]
          params := ["p.immediate_hazard_time"]
          convention := "Gap acceptance: a vehicle b on a carrier c_b of the through highway whose entrance end is i (st.lane_enters, st.on_way, rel.occupies) is an immediate hazard during ego's crossing where its time to reach the intersection is below the critical headway, read as the ground distance from its body to i (st.region_geometry) at or below its speed (kin.speed) times the critical headway; distance and speed enter by degree."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
