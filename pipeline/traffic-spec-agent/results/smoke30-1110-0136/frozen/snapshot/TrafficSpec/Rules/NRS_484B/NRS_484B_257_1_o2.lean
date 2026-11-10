/-
  NRS_484B_257_1_o2 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer
    s2 (exception): or a traffic-control signal:
    s3 (trigger): When proper signs have been erected,
    s4 (subject): the driver of a vehicle
    s5 (sibling): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    s6 (condition): After having stopped
    s7 (condition): or, in the event of a yield sign,
    s8 (standard): slowed
    s9 (condition): or stopped,
    s10 (subject): the driver
    s11 (obligation): shall yield
    s12 (standard): the right-of-way
    s13 (condition): to other vehicles which have entered the intersection
    s14 (condition): from such through highway
    s15 (condition): or which are approaching
    s16 (standard): so closely on such through highway as to constitute an immediate hazard
    s17 (condition): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs'], derived []
    s3: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived ['drv.motion.stopped']
    s7: atoms ['dev.yield_sign', 'dev.governs'], derived []
    s9: atoms [], derived ['drv.motion.stopped']
    s10: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s11: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']
    s13: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s14: atoms ['st.highway', 'st.on_way'], derived []
    s15: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region'], derived []
    s17: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']

  How each span is written:
    s4/s10: the binder class, `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s17: the judged observation: x occupies an intersection i (`existsRegion intersection i`,
      `rel_occupies x i`) and is moving (`drv_motion_moving x` with p.motion_speed_tolerance).
    s3: a stop sign or a yield sign governs x's approach carrier c or i (`existsDevice stop_sign` /
      `existsDevice yield_sign` with `dev_governs d c ∨ dev_governs d i`), read at the judged
      observation. The approach carrier c is a travel region with `st_lane_enters c i` that x
      occupied at the entry of its current occupancy of i: `since (occ x i) (rises (occ x i) ∧ occ x c ∧ …)`,
      so the observation at which `occ x i` last rose is the entry.
    s1/s2: at that entry, neither x as a member of the traffic (`ru_aggregate x DEF-NRS-484A-285::traffic`)
      is directed by a human direction of role police_officer governing c or i, nor does a
      traffic signal govern c or i that is not inoperative (`dev_inoperative`) and does not show dark
      (`dev_traffic_signal_shows d dark`, the state attribute of dev.traffic_signal).
    s6/s9: at that entry, `since (occ x c) (occ x c ∧ ¬occ x i ∧ halt)`: at some observation since x
      last came onto c (c occupied at every observation from it up to the entry), with x on c and
      outside i, `drv_motion_stopped x` with p.motion_speed_tolerance.
    s7/s8: the halt's alternative: a yield sign governs c or i and no stop sign does, and
      `kin_speed x ≤ p.yield_sign_check_speed`; the "only a yield sign governs" test is read at
      that same observation (devices do not change within a crossing, so this decides alike with
      reading it at the judged observation).
    s13/s14: a vehicle y other than x (`ru_aggregate y vehicle`, `¬ same x y`) occupying i that
      has occupied i continuously since an observation at which it occupied a carrier cy with
      `st_lane_enters cy i` (`since (occ y i) (occ y cy)`), cy lying on (`st_on_way`) a highway h
      that i lies on and c does not.
    s15/s16: or y occupies such a carrier cy, is outside i, and its ground distance to i
      (`st_region_geometry_distance y i`) is at most `kin_speed y × p.immediate_hazard_time_gap`
      (a ratio bound written as a product).
    s11/s12: the obligation: for every i and c the applicability selects (its selection written
      again: occupancy and motion, the approach carrier, the sign, the entry through c after the
      halt or slowing) and every y it selects (its whole selection), not both
      `prim_closest_approach_within x y` and `prim_closest_approach_distance x y <
      p.conflict_centre_clearance`, both with p.conflict_time_horizon. The exceptions s1/s2 are
      not repeated there: they fix no region and no road user, only whether the rule is engaged,
      and the applicability already requires them absent at the entry; repeated, their leaves
      could decide nothing the applicability has not (a vehicle is always a member of the traffic).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pYieldSignCheckSpeed : Term := .param "p.yield_sign_check_speed"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggTraffic : String := "DEF-NRS-484A-285::traffic"

/-- A road user's footprint overlaps a region. -/
def occ (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []

/-- Carrier `c` is an approach to intersection `i`. -/
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []

/-- Device `d` governs the approach carrier `c` or the intersection `i`. -/
def governsCI (d c i : String) : Formula :=
  .or (.atom "dev_governs" [.var d, .var c] []) (.atom "dev_governs" [.var d, .var i] [])

/-- s3/s7: a sign of `kind` governs `c` or `i`. -/
def signed (kind d c i : String) : Formula := .existsDevice (.lit kind) d (governsCI d c i)

def stopSigned (c i : String) : Formula := signed "stop_sign" "dStop" c i
def yieldSigned (c i : String) : Formula := signed "yield_sign" "dYield" c i

/-- s7: only a yield sign governs. -/
def onlyYield (c i : String) : Formula := .and (yieldSigned c i) (.not (stopSigned c i))

/-- s1: x, a member of the traffic, is controlled by a police officer's direction governing `c` or `i`. -/
def policeControl (c i : String) : Formula :=
  .and (.atom "ru_aggregate" [vX, .lit aggTraffic] [])
    (.existsDevice (.lit "human_direction") "dHuman"
      (.and (.atom "dev_human_direction_role" [.var "dHuman", .lit "police_officer"] []) (governsCI "dHuman" c i)))

/-- s2: a traffic signal governs `c` or `i`, neither inoperative nor dark. -/
def signalControl (c i : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "dSignal"
    (.and (governsCI "dSignal" c i)
      (.and (.not (.atom "dev_inoperative" [.var "dSignal"] []))
        (.not (.atom "dev_traffic_signal_shows" [.var "dSignal", .lit "dark"] []))))

/-- s6/s7/s8/s9: since x last came onto `c`, with x on `c` outside `i`, a halt, or where only a
    yield sign governs a speed at or below the check speed. -/
def stoppedOrSlowed (c i : String) : Formula :=
  .since (occ "x" c)
    (.and (occ "x" c)
      (.and (.not (occ "x" i))
        (.or (.derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance])
          (.and (onlyYield c i) (.cmp (.measure "kin_speed" [vX]) .le pYieldSignCheckSpeed)))))

/-- The entry of x's current occupancy of `i`, through `c`, after the halt or slowing; with
    `uncontrolled`, also free of the exceptions s1/s2 at that entry. -/
def enteredThrough (c i : String) (uncontrolled : Bool) : Formula :=
  let approach : Formula := .and (occ "x" c) (stoppedOrSlowed c i)
  .since (occ "x" i)
    (.and (.rises (occ "x" i))
      (if uncontrolled then
        .and (.not (policeControl c i)) (.and (.not (signalControl c i)) approach)
      else approach))

/-- s17/s3 with the entry: the selection of the intersection `i` and x's approach carrier `c`. -/
def selection (i c : String) (uncontrolled : Bool) : Formula :=
  .and (occ "x" i)
    (.and (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
      (.and (enters c i)
        (.and (.or (stopSigned c i) (yieldSigned c i))
          (enteredThrough c i uncontrolled))))

/-- s14: carrier `cy` lies on a highway that `i` lies on and `c` does not. -/
def throughWay (cy i c : String) : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [.var cy, .var "h"] [])
      (.and (.atom "st_on_way" [.var i, .var "h"] [])
        (.not (.atom "st_on_way" [.var c, .var "h"] []))))

/-- s13/s14: y has entered `i` from the through highway. -/
def enteredFromThrough (y i c : String) : Formula :=
  .and (occ y i)
    (.existsRegion (.lit "travel_region") "cy"
      (.and (enters "cy" i)
        (.and (throughWay "cy" i c) (.since (occ y i) (occ y "cy")))))

/-- s15/s16: y approaches `i` on the through highway close enough to be an immediate hazard. -/
def approachingHazard (y i c : String) : Formula :=
  .existsRegion (.lit "travel_region") "cy"
    (.and (occ y "cy")
      (.and (.not (occ y i))
        (.and (enters "cy" i)
          (.and (throughWay "cy" i c)
            (.cmp (.measure "st_region_geometry_distance" [.var y, .var i]) .le
              (.mul (.measure "kin_speed" [.var y]) pImmediateHazardTimeGap))))))

/-- The vehicles owed precedence at `i` for x approaching through `c`. -/
def owed (y i c : String) : Formula :=
  .and (.atom "ru_aggregate" [.var y, .lit aggVehicle] [])
    (.and (.not (.same vX (.var y)))
      (.or (enteredFromThrough y i c) (approachingHazard y i c)))

/-- s12: a predicted closest approach within the horizon below the clearance. -/
def conflict (y : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var y] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var y] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit aggVehicle] []

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer; s2 (exception): or a traffic-control signal:; s3 (trigger): When proper signs have been erected,; s6 (condition): After having stopped; s7 (condition): or, in the event of a yield sign,; s9 (condition): or stopped,; s13 (condition): to other vehicles which have entered the intersection; s14 (condition): from such through highway; s15 (condition): or which are approaching; s17 (condition): during the time such driver is moving across or within the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.and (selection "i" "c" true) (.existsUser "y" (owed "y" "i" "c"))))

/-- Obligation: s8 (standard): slowed; s11 (obligation): shall yield; s12 (standard): the right-of-way; s16 (standard): so closely on such through highway as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (selection "i" "c" false)
        (.forallUser "y" (.implies (owed "y" "i" "c") (.not (conflict "y"))))))

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
      [ { standard := "slowed (in the event of a yield sign)"
          concepts := ["kin.speed"]
          params := ["p.yield_sign_check_speed"]
          convention := "A vehicle at a yield-controlled approach has slowed where its speed (kin.speed, 'magnitude of velocity') fell to or below the yield-control check speed of the intersection-sight-distance model at some observation on its approach carrier outside the intersection since it last came onto it."
          surrogate := false }
      , { standard := "the right-of-way (DEF-NRS-484A-210: 'circumstances of direction, speed and proximity as to give rise to the danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false }
      , { standard := "approaching so closely on such through highway as to constitute an immediate hazard"
          concepts := ["kin.speed", "st.highway", "st.on_way", "st.region_geometry"]
          params := ["p.immediate_hazard_time_gap"]
          convention := "Gap acceptance: a vehicle approaching on the through highway (its carrier on the through way, st.on_way, st.highway) is an immediate hazard during the subject's crossing where its time to reach the intersection is at most the critical gap: its ground distance to i (st.region_geometry) is at most its speed (kin.speed) times the critical gap."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o2
