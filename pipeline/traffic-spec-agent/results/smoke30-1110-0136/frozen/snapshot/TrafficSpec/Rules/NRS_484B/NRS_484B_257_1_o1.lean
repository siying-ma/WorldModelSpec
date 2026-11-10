/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer
    s2 (exception): or a traffic-control signal:
    s3 (trigger): When proper signs have been erected,
    s4 (subject): the driver of a vehicle
    s5 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection
    s6 (standard): where the driver has a view of approaching traffic on the through highway.
    s7 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped, the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs'], derived []
    s3: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['kin.speed', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.region_geometry', 'prim.region_offset_along', 'rel.occupies', 'st.lane_enters', 'st.travel_region'], derived ['drv.motion.stopped']

  How they are written.
    The event. An entry of x into an intersection i (`entered`): `rises (rel_occupies x i)`. The
    approach carrier c is a travel region with `st_lane_enters c i` that x occupied, outside i, at
    the observation before the entry (`onBefore`): `since (entered i) (occ c ∧ ¬ occ i)`, which at
    an entry reads exactly the observation before it (the entry itself falsifies the second
    operand, and the observation before is no entry).
    s3: a stop sign or a yield sign governing c or i (`dev_governs`), each by its device kind.
    s1: x is a member of DEF-NRS-484A-285::traffic and a human_direction with role police_officer
        governs c or i, at the entry observation.
    s2: a traffic_signal governing c or i that is not inoperative and does not show dark.
    s4: the binder's class, ru_aggregate DEF-NRS-484A-320::vehicle.
    s5: the act (`act`): a halt (drv.motion.stopped with p.motion_speed_tolerance), or, where no
        stop sign governs c or i (so, the carrier being selected, only a yield sign does), kin.speed
        at most p.yield_sign_check_speed. The act counts at an observation at which x occupies c,
        does not occupy i, is on the upstream side of the place along c's direction
        (prim_region_offset_along ≥ 0) and within p.stop_point_tolerance of it
        (st_region_geometry_distance). The place, in the words' order: a stop line recorded as
        marking c (st_entrance_of); where every stop line's association is decided and none marks
        c, a crosswalk recorded as marking c, with x not occupying it; where neither is recorded,
        the intersection i itself.
    s6: at the intersection-edge place, the act counts only at an observation where, for every
        highway h with st_on_way i h and not st_on_way c h, st_sight_along_way x h is at least
        p.approach_view_sight_distance.
    History bound: from the observation before the entry, `since (¬ end) (act at the place)`, end
        being the approach start (x on c, offset to the place > 0 and distance to it beyond
        p.stop_point_tolerance) or x's previous entry into i from c (`entered i ∧ onBefore c i`).
        The search reaching the trace start without either is unknown (`since`'s unobserved past).
    Several carriers: the duty is written for every selected carrier; where all selected carriers
        comply it is met, where all fail it is violated, otherwise undefined (`definedWhen`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pApproachViewSightDistance : Term := .param "p.approach_view_sight_distance"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldSignCheckSpeed : Term := .param "p.yield_sign_check_speed"

def zeroMetres : Term := .lit Q.zero .metre

/-- x's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- The entry of x into intersection `i`: overlapping it here and not at the observation before. -/
def entered (i : String) : Formula := .rises (occ i)

/-- At an entry into `i`: x occupied carrier `c`, outside `i`, at the observation before it. -/
def onBefore (c i : String) : Formula := .since (entered i) (.and (occ c) (.not (occ i)))

/-- `c` is the carrier x approached `i` through. -/
def approach (c i : String) : Formula :=
  .and (.atom "st_lane_enters" [.var c, .var i] []) (onBefore c i)

/-- Device `d` governs carrier `c` or intersection `i`. -/
def governsCI (d c i : String) : Formula :=
  .or (.atom "dev_governs" [.var d, .var c] []) (.atom "dev_governs" [.var d, .var i] [])

/-- s3: a stop sign governs `c` or `i`. -/
def stopSignGoverns (c i : String) : Formula :=
  .existsDevice (.lit "stop_sign") "dStop" (governsCI "dStop" c i)

/-- s3: a yield sign governs `c` or `i`. -/
def yieldSignGoverns (c i : String) : Formula :=
  .existsDevice (.lit "yield_sign") "dYield" (governsCI "dYield" c i)

/-- s3: proper signs erected for the approach. -/
def signed (c i : String) : Formula := .or (stopSignGoverns c i) (yieldSignGoverns c i)

/-- s1: x's traffic controlled by a police officer. -/
def byOfficer (c i : String) : Formula :=
  .and (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] [])
    (.existsDevice (.lit "human_direction") "dOfficer"
      (.and (.atom "dev_human_direction_role" [.var "dOfficer", .lit "police_officer"] [])
        (governsCI "dOfficer" c i)))

/-- s2: x's traffic controlled by a traffic-control signal that directs. -/
def bySignal (c i : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "dSignal"
    (.and (governsCI "dSignal" c i)
      (.and (.not (.atom "dev_inoperative" [.var "dSignal"] []))
        (.not (.atom "dev_traffic_signal_shows" [.var "dSignal", .lit "dark"] []))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer; s2 (exception): or a traffic-control signal:; s3 (trigger): When proper signs have been erected, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (entered "i")
      (.existsRegion (.lit "travel_region") "c"
        (.and (approach "c" "i")
          (.and (signed "c" "i")
            (.not (.or (byOfficer "c" "i") (bySignal "c" "i")))))))

/-- Signed distance from x to the place `r` along carrier `c`'s direction (positive: short of it). -/
def offsetAlong (r c : String) : Term := .quantity "prim_region_offset_along" [vX, .var r, .var c] []

/-- Distance between x's body and the place `r`. -/
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vX, .var r]

/-- s5: stop, or, where no stop sign governs, slow to the yield check speed. -/
def act (c i : String) : Formula :=
  .or (.derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance])
    (.and (.not (stopSignGoverns c i))
      (.cmp (.measure "kin_speed" [vX]) .le pYieldSignCheckSpeed))

/-- s5: the act made at place `r` of carrier `c`: on c, outside i, upstream of r and within the
    stop-point tolerance of it. -/
def actAt (c i r : String) : Formula :=
  .and (occ c)
    (.and (.not (occ i))
      (.and (.cmp (offsetAlong r c) .ge zeroMetres)
        (.and (.cmp (distTo r) .le pStopPointTolerance)
          (act c i))))

/-- The approach start for place `r`: x on c, short of r and farther from it than the tolerance. -/
def approachStart (c r : String) : Formula :=
  .and (occ c)
    (.and (.cmp (offsetAlong r c) .gt zeroMetres)
      (.cmp (distTo r) .gt pStopPointTolerance))

/-- The search back for `φ`, ending at the approach start for `r` or at x's previous entry into
    `i` from `c`. -/
def search (c i r : String) (φ : Formula) : Formula :=
  .since (.not (.or (approachStart c r) (.and (entered i) (onBefore c i)))) φ

/-- (1) A stop line recorded as marking c. -/
def viaStopLine (c i : String) : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (.atom "st_entrance_of" [.var "s", .var c] [])
      (search c i "s" (actAt c i "s")))

/-- c's stop-line association observed and listing none. -/
def noStopLine (c : String) : Formula :=
  .forallRegion (.lit "stop_line") "s2" (.not (.atom "st_entrance_of" [.var "s2", .var c] []))

/-- (2) Where there is no stop line, a crosswalk recorded as marking c, x not overlapping it. -/
def viaCrosswalk (c i : String) : Formula :=
  .and (noStopLine c)
    (.existsRegion (.lit "crosswalk") "w"
      (.and (.atom "st_entrance_of" [.var "w", .var c] [])
        (search c i "w" (.and (.not (occ "w")) (actAt c i "w")))))

/-- c's crosswalk association observed and listing none. -/
def noCrosswalk (c : String) : Formula :=
  .forallRegion (.lit "crosswalk") "w2" (.not (.atom "st_entrance_of" [.var "w2", .var c] []))

/-- s6: a view along every through highway: a highway i lies on and c does not. -/
def throughView (c i : String) : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.and (.atom "st_on_way" [.var i, .var "h"] []) (.not (.atom "st_on_way" [.var c, .var "h"] [])))
      (.cmp (.measure "st_sight_along_way" [vX, .var "h"]) .ge pApproachViewSightDistance))

/-- (3) Where neither is recorded, the entrance end of c at i, where the view is had. -/
def viaEdge (c i : String) : Formula :=
  .and (noStopLine c)
    (.and (noCrosswalk c)
      (search c i i (.and (throughView c i) (actAt c i i))))

/-- The duty through carrier `c`, judged at the entry from the observation before it. -/
def duty (c i : String) : Formula :=
  .since (entered i)
    (.and (.not (occ i))
      (.or (viaStopLine c i) (.or (viaCrosswalk c i) (viaEdge c i))))

/-- The carrier selection of the applicability. -/
def selected (c i : String) : Formula := .and (approach c i) (signed c i)

def allMet (i : String) : Formula :=
  .forallRegion (.lit "travel_region") "c" (.implies (selected "c" i) (duty "c" i))

def allFail (i : String) : Formula :=
  .forallRegion (.lit "travel_region") "c" (.implies (selected "c" i) (.not (duty "c" i)))

/-- Obligation: s5 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection; s6 (standard): where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (entered "i")
      (.definedWhen (.or (allMet "i") (allFail "i")) (allMet "i")))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "has a view of approaching traffic on the through highway"
          concepts := ["st.highway", "st.on_way", "st.sight_along_way"]
          params := ["p.approach_view_sight_distance"]
          convention := "The view of approaching traffic on the through highway is a sight distance along that way (st.sight_along_way 'within which another vehicle on that way could be seen from the road user's eye') at least the stopping sight distance of the approach-speed design convention. The through highway is a st.highway the intersection lies on (st.on_way) and x's approach carrier does not: the way whose traffic the sign on x's approach makes x yield to (DEF-NRS-484A-275 'at the entrances to which vehicular traffic from intersecting highways is required by law to yield')."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1
