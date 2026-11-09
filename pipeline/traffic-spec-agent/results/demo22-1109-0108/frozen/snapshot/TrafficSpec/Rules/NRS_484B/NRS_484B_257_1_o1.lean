/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    c1 (condition): When proper signs have been erected,
    s1 (subject): the driver of a vehicle
    ob1 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway.
    sib1 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped, the driver shall yield the right-of-way to other vehicles which have entered the intersection from such through highway or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    c1: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.lane_enters', 'st.intersection'], derived []
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'kin.speed', 'rel.occupies', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'st.region_geometry', 'st.travel_region', 'st.lane_direction', 'st.lane_enters', 'st.intersection', 'st.on_way', 'st.highway', 'st.sight_along_way', 'prim.region_offset_along'], derived ['drv.motion.standstill', 'drv.motion.region_entry']

  How each span is written.

    s1 — `clsV`: the duty binds the vehicle whose controlled motion the ontology reads as the
    driver's: the admitted aggregate DEF-NRS-484A-320::vehicle, one atom on the binder `v`.

    c1 — `properSignGoverns`: a stop sign or a yield sign (the device quantifiers read
    `dev.stop_sign` and `dev.yield_sign` as their kinds) whose governance (`dev.governs`) falls on
    the carrier the subject occupies, so the sign read is the one governing this approach. The
    carrier is selected by `approachSelected`: `rel.occupies` on a travel region (the quantifier's
    kind) whose entrance end is the junction (`st.lane_enters` on an `st.intersection` region).
    The carrier is never the junction itself (`same`), which is a travel region too but no
    approach to itself.

    e1 — `trafficControlled`: the subject is a member of DEF-NRS-484A-285::traffic (the traffic
    being controlled), and either a person directing traffic in the role police_officer, with the
    direction given (`dev.human_direction` role and indication — a person present but directing
    nothing engages nothing), or a traffic-control signal (`dev.traffic_signal`) governs the
    junction the subject approaches or its own approach carrier (`dev.governs` on `j` or on `l`).
    Negated in the applicability.

    ob1 — the duty. The event is the subject's entry into that junction
    (`drv.motion.region_entry`). At that observation the act must be found by a search back
    through the subject's history: `actFound` counts the onsets of `actedAtPlace` since the latest
    end of the search, the end being the start of that approach (`approachStarted`) or an entry
    into the same junction (`entersIntersection`). A search that reaches neither end, because the
    history begins before the recording, is unknown, and the duty with it.
      The act, `actedAtPlace`: the halt (`drv.motion.standstill` within
    p.standstill_speed_tolerance) or, where the governing sign is a yield sign, a speed
    (`kin.speed`) at or below p.yield_sign_slowed_max_speed; the subject's footprint not yet in
    the junction (`rel.occupies`); and the place, read in the words' own order by `atPlace`: the
    stop line recorded as marking that carrier (`st.stop_line`, `st.entrance_of`), else — where
    the carrier's stop lines are observed and none marks it — the crosswalk recorded as marking it
    (`st.crosswalk`), else the view point on the crossing way. At a mark, `atMark` holds where the
    distance between body and mark (`st.region_geometry`) is at most p.stop_point_tolerance and
    the mark is not yet passed, the side read by the sign of `prim.region_offset_along` along the
    carrier's designated direction; `carrierDirected` states that the carrier carries that
    direction (`st.lane_direction`), so that the duty is unknown where it is unobserved.
      The start of the approach, `approachStarted`: the subject on that carrier, off the mark,
    short of it and farther from it than p.stop_point_tolerance — and, for the view point, with
    the sight along the crossing way still short of the view distance.

  Readings chosen here (declared in `narrowings`, on the duty's span ob1):
    1. The third place has no region in a scene: no atom denotes "the point nearest the
       intersection where the driver has a view". It is written as an observation at which the
       subject, on the approach carrier and not yet in the junction, has the sight along the
       crossing way (`st.sight_along_way`, the lesser of its two directions) at or above
       p.intersecting_way_view_distance; "nearest the intersection" is not read as a spatial
       minimum, and the start of the approach for that place is the last observation on the
       carrier at which that sight fell short of the distance.
    2. "the through highway" is read as a highway region (`st.highway`) the junction lies on
       (`st.on_way`) that the subject's own approach carrier does not lie on. `dev.governs`
       records the carrier a sign governs and no atom places a sign at a way's entrance, so the
       crossing way is identified by the junction and the carrier, not by the sign's position.
    3. The search back from the entry counts the act at its onset (the rising edges of the act
       since the start of the search's latest run), so an act that already held at the first
       observation after the search's end is not counted.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The quantified entities: the junction, the approach carrier, a mark of its entrance, the
    crossing way, the two signs, the officer and the signal head. -/
def jV : Arg := .var "j"
def lV : Arg := .var "l"
def mV : Arg := .var "m"
def wV : Arg := .var "w"
def sgV : Arg := .var "sg"
def ygV : Arg := .var "yg"
def oV : Arg := .var "o"
def tsV : Arg := .var "ts"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectingWayViewDistance : Term := .param "p.intersecting_way_view_distance"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldSignSlowedMaxSpeed : Term := .param "p.yield_sign_slowed_max_speed"

def zeroMetres : Term := .lit Q.zero .metre
def zeroRatio : Term := .lit Q.zero .ratio

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

-- c1: a proper sign erected for this approach ------------------------------------------------

/-- A stop sign governing the carrier `l`. -/
def stopSignGoverns : Formula :=
  .existsDevice (.lit "stop_sign") "sg" (.atom "dev_governs" [sgV, lV] [])
/-- A yield sign governing the carrier `l`. -/
def yieldSignGoverns : Formula :=
  .existsDevice (.lit "yield_sign") "yg" (.atom "dev_governs" [ygV, lV] [])
/-- "proper signs have been erected": one of the two signs this section names governs `l`. -/
def properSignGoverns : Formula := .or stopSignGoverns yieldSignGoverns

-- e1: traffic controlled by a police officer or a traffic-control signal -----------------------

/-- One indication a person directing traffic may give. -/
def officerIndicates (k : String) : Formula :=
  .atom "dev_human_direction_indication" [oV, .lit k] []

/-- The direction given: the atom carries it, so a person present but directing nothing is none. -/
def directionGiven : Formula :=
  .or (officerIndicates "stop")
    (.or (officerIndicates "proceed")
      (.or (officerIndicates "slow")
        (.or (officerIndicates "turn(left)")
          (.or (officerIndicates "turn(right)")
            (.or (officerIndicates "turn(straight)") (officerIndicates "turn(u_turn)"))))))

/-- The device controls the junction the subject approaches, or its own approach carrier. -/
def governsApproach (x : Arg) : Formula :=
  .or (.atom "dev_governs" [x, jV] []) (.atom "dev_governs" [x, lV] [])

def officerControls : Formula :=
  .existsDevice (.lit "human_direction") "o"
    (.and (.atom "dev_human_direction_role" [oV, .lit "police_officer"] [])
      (.and directionGiven (governsApproach oV)))

def signalControls : Formula :=
  .existsDevice (.lit "traffic_signal") "ts" (governsApproach tsV)

/-- "traffic is being controlled by a police officer or a traffic-control signal". -/
def trafficControlled : Formula :=
  .and (.atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] [])
    (.or officerControls signalControls)

-- The approach: the carrier the subject occupies whose entrance end is the junction ------------

def approachSelected : Formula :=
  .and (.not (.same lV jV))
    (.and (.atom "rel_occupies" [vV, lV] [])
      (.atom "st_lane_enters" [lV, jV] []))

/-- Applicability: e1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; c1 (condition): When proper signs have been erected, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.existsRegion (.lit "travel_region") "l"
      (.and approachSelected
        (.and properSignGoverns (.not trafficControlled))))

-- ob1: the act, the place, the event and the search -------------------------------------------

/-- The carrier carries a designated direction, the direction the side of a mark is read along. -/
def laneDirectionMagnitude : Term :=
  .add (.abs (.measure "st_lane_direction" [lV, .lit "x"]))
    (.abs (.measure "st_lane_direction" [lV, .lit "y"]))
def carrierDirected : Formula := .cmp laneDirectionMagnitude .gt zeroRatio

/-- "stop or yield": the halt, or under a yield sign a speed at or below the slowed maximum. -/
def speedActed : Formula :=
  .or (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])
    (.and yieldSignGoverns
      (.cmp (.measure "kin_speed" [vV]) .le pYieldSignSlowedMaxSpeed))

def markOffset (mk : Arg) : Term := .quantity "prim_region_offset_along" [vV, mk, lV] []
def markDistance (mk : Arg) : Term := .measure "st_region_geometry_distance" [vV, mk]

/-- At the mark: within the stop-point tolerance of it and not yet past it. -/
def atMark (mk : Arg) : Formula :=
  .and (.cmp (markDistance mk) .le pStopPointTolerance)
    (.cmp (markOffset mk) .ge zeroMetres)

/-- Before the mark: on the carrier, short of the mark and farther from it than the tolerance. -/
def beforeMark (mk : Arg) : Formula :=
  .and (.cmp (markDistance mk) .gt pStopPointTolerance)
    (.cmp (markOffset mk) .gt zeroMetres)

/-- The sight along the crossing way — a highway the junction lies on and the carrier does not —
    compared with the view distance. -/
def crossingWaySight (op : CmpOp) : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [jV, wV] [])
      (.and (.not (.atom "st_on_way" [lV, wV] []))
        (.cmp (.measure "st_sight_along_way" [vV, wV]) op pIntersectingWayViewDistance)))

/-- A stop line is recorded as marking this carrier's entrance. -/
def stopLineMarks : Formula :=
  .existsRegion (.lit "stop_line") "m" (.atom "st_entrance_of" [mV, lV] [])
/-- A crosswalk is recorded as marking this carrier's entrance. -/
def crosswalkMarks : Formula :=
  .existsRegion (.lit "crosswalk") "m" (.atom "st_entrance_of" [mV, lV] [])

/-- The place, in the words' own order: the stop line marking this carrier; if there is none, the
    crosswalk marking it; if there is none, the view point on the crossing way. -/
def atPlace (mark : Arg → Formula) (view : Formula) : Formula :=
  .or
    (.existsRegion (.lit "stop_line") "m"
      (.and (.atom "st_entrance_of" [mV, lV] []) (mark mV)))
    (.or
      (.and (.not stopLineMarks)
        (.existsRegion (.lit "crosswalk") "m"
          (.and (.atom "st_entrance_of" [mV, lV] []) (mark mV))))
      (.and (.not stopLineMarks) (.and (.not crosswalkMarks) view)))

/-- The act at the place: the halt or the slowed speed, the footprint not yet in the junction,
    at the place the words name. -/
def actedAtPlace : Formula :=
  .and speedActed
    (.and (.not (.atom "rel_occupies" [vV, jV] []))
      (atPlace atMark (crossingWaySight .ge)))

/-- The start of that approach: on the carrier, before the place. -/
def approachStarted : Formula :=
  .and (.atom "rel_occupies" [vV, lV] [])
    (atPlace beforeMark (crossingWaySight .lt))

/-- The event the duty is judged at: the subject's entry into that junction. -/
def entersIntersection : Formula := .derived "drv_motion_region_entry" [vV, jV] []

/-- Where the search back ends: the start of that approach, or a previous entry into the junction. -/
def searchEnd : Formula := .or approachStarted entersIntersection

/-- The act is found between the end of the search and the entry. -/
def actFound : Formula := .count actedAtPlace (.not searchEnd) .ge 1

/-- Obligation: ob1 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.forallRegion (.lit "travel_region") "l"
      (.implies (.and approachSelected (.and properSignGoverns carrierDirected))
        (.implies entersIntersection actFound)))

def rule : Rule :=
  { id := "NRS_484B_257_1_o1"
    laws := ["NRS-484B-257-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "The point the third place names has no region in a scene: it is written as an observation at which the subject, on the approach carrier and not yet in the junction, has the sight along the crossing way at or above p.intersecting_way_view_distance. 'Nearest the intersection' is not read as a spatial minimum, and the start of the approach for that place is the last observation on the carrier at which that sight fell short of the distance."
          kind := "reading" }
      , { span := "ob1"
          why := "'the through highway' is read as a highway region the junction lies on that the subject's own approach carrier does not lie on. dev.governs records the carrier a sign governs and no atom places a sign at a way's entrance, so the crossing way is identified by the junction and the carrier, not by the sign's position on it."
          kind := "reading" }
      , { span := "ob1"
          why := "The search back from the entry counts the act at its onset — the rising edges of the act since the start of the search's latest run — so an act that already held at the first observation after the end of the search is not counted."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1
