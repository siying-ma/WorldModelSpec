/-
  NRS_484B_250_4_o1 — NRS-484B-250-4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): When a vehicle enters an intersection
    s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection,
    s3 (subject): the driver of the vehicle
    s4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection
    s8 (standard): where the driver has a view of approaching traffic on the through highway.
    s9 (sibling): After making such a stop,
    s10 (sibling): the driver shall proceed
    s11 (sibling): cautiously,
    s12 (sibling): yielding to vehicles
    s13 (sibling): which have previously completed a stop
    s14 (sibling): or are within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s2: atoms ['dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['kin.speed', 'st.stop_line', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'st.region_geometry', 'prim.region_offset_along', 'st.crosswalk', 'rel.occupies', 'st.intersection'], derived ['drv.motion.halted']

  How each is written.
    s3: the binder x, of class ru_aggregate x "DEF-NRS-484A-320::vehicle".
    s1, s2 (`approach i c`): x enters intersection i (drv_motion_entering_region x i) through a
      region c of kind travel_region that x occupies (rel_occupies x c) and that enters i
      (st_lane_enters c i), and some traffic_signal d governing i or c (dev_governs) is
      dev_inoperative, all at the entry observation. c is a region other than i itself
      (`same c i` false): an intersection is the region an approach carrier runs into, never its
      own approach, and st_lane_enters, read on an intersection, carries no record to decide that.
    s4 (`haltMade i c`), the place in the words' order:
      (1) some stop_line s with st_entrance_of s c: a halt (drv_motion_halted, p.speed_resolution)
          with st_region_geometry_distance x s ≤ p.stop_point_tolerance and
          prim_region_offset_along x s c ≥ 0;
      (2) no stop_line marks c and some crosswalk w with st_entrance_of w c: a halt with
          rel_occupies x w false, distance to w ≤ p.stop_point_tolerance and offset along c > 0;
      (3) neither marks c: a halt with rel_occupies x i false and either distance to i
          ≤ p.stop_point_tolerance or (s8) the crossing way in view: some highway h with
          st_on_way i h, not st_on_way c h, and st_sight_along_way x h ≥ p.intersection_sight_distance.
      The search (`haltOnApproach`): `since (not boundary) halt` at the entry, the boundary being
      the approach start (x on c, not occupying the place, short of it along c by
      prim_region_offset_along > 0, and farther from it than p.stop_point_tolerance; for (3) the
      place is i) or x's exit from i after a previous entry (rel_occupies x i rising to false).
      The trace start before either boundary leaves `since` unknown (truncated).
    The carriers: where x enters i through several carriers, the duty is decided where every
      carrier gives the same verdict (`everyApproach` / `someApproach`) and undefined (unknown)
      where they differ, so no carrier that favours x is picked.

  Choices the text left open (declared in `narrowings`):
    s4: x's previous entry into i bounds the search at x's exit from i after it (the observation
      at which its footprint stops overlapping i); a halt made while x still overlaps i after a
      previous entry does not count for this entry.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_250_4_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantified variables: the intersection entered, the approach carrier, the signal, the stop
    line, the crosswalk and the crossing way. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vD : Arg := .var "d"
def vS : Arg := .var "s"
def vW : Arg := .var "w"
def vH : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pIntersectionSightDistance : Term := .param "p.intersection_sight_distance"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- x's footprint overlaps region `r`. -/
def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []
/-- Ground distance from x's body to region `r`. -/
def distanceTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vX, r]
/-- Signed distance from x's reference point to region `r` along carrier c's direction. -/
def offsetAlong (r : Arg) : Term := .quantity "prim_region_offset_along" [vX, r, vC] []
/-- x at a standstill. -/
def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: some traffic signal governing i or c is inoperative. -/
def inoperativeSignal : Formula :=
  .existsDevice (.lit "traffic_signal") "d"
    (.and (.or (.atom "dev_governs" [vD, vI] []) (.atom "dev_governs" [vD, vC] []))
          (.atom "dev_inoperative" [vD] []))

/-- s1, s2: x enters i at this observation through carrier c (occupied, entering i), and a signal
    governing i or c is inoperative. -/
def approach : Formula :=
  .and (.derived "drv_motion_entering_region" [vX, vI] [])
    (.and (occupies vC)
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.and (.not (.same vC vI)) inoperativeSignal)))

/-- Applicability: s1 (trigger): When a vehicle enters an intersection; s2 (condition): controlled by a traffic-control signal which is installed and has its vehicular signals uncovered, but is inoperative at the time the vehicle enters the intersection, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" approach)

/-- x, on c, is outside the stopping zone of place `p` upstream: not on it, short of it along c,
    and farther from it than the stop-point tolerance (the approach start). -/
def outsideZone (p : Arg) : Formula :=
  .and (occupies vC)
    (.and (.not (occupies p))
      (.and (.cmp (offsetAlong p) .gt zeroMetres)
            (.cmp (distanceTo p) .gt pStopPointTolerance)))

/-- x leaves i: its footprint stops overlapping i (the end of a previous entry). -/
def leftIntersection : Formula := .rises (.not (occupies vI))

/-- A halt at place `p` since the later of the approach start and x's previous stay in i. -/
def haltOnApproach (p : Arg) (halt : Formula) : Formula :=
  .since (.not (.or (outsideZone p) leftIntersection)) halt

/-- (1) at the stop line s: halted within tolerance of s, s not behind x along c. -/
def atStopLine : Formula :=
  .and halted
    (.and (.cmp (distanceTo vS) .le pStopPointTolerance)
          (.cmp (offsetAlong vS) .ge zeroMetres))

/-- (2) before entering the crosswalk w: halted off w, within tolerance of it, w ahead along c. -/
def beforeCrosswalk : Formula :=
  .and halted
    (.and (.not (occupies vW))
      (.and (.cmp (distanceTo vW) .le pStopPointTolerance)
            (.cmp (offsetAlong vW) .gt zeroMetres)))

/-- s8: a highway on which i lies and c does not is in view from x for the sight distance. -/
def crossingWayInView : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vI, vH] [])
      (.and (.not (.atom "st_on_way" [vC, vH] []))
            (.cmp (.measure "st_sight_along_way" [vX, vH]) .ge pIntersectionSightDistance)))

/-- (3) at the point nearest the intersection: halted outside i, within tolerance of it or where
    the crossing way is in view. -/
def nearIntersection : Formula :=
  .and halted
    (.and (.not (occupies vI))
          (.or (.cmp (distanceTo vI) .le pStopPointTolerance) crossingWayInView))

/-- Some stop line is recorded as marking c's entrance. -/
def stopLineMarks : Formula :=
  .existsRegion (.lit "stop_line") "s" (.atom "st_entrance_of" [vS, vC] [])
/-- Some crosswalk is recorded as marking c's entrance. -/
def crosswalkMarks : Formula :=
  .existsRegion (.lit "crosswalk") "w" (.atom "st_entrance_of" [vW, vC] [])

def placeStopLine : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (.atom "st_entrance_of" [vS, vC] []) (haltOnApproach vS atStopLine))

def placeCrosswalk : Formula :=
  .and (.not stopLineMarks)
    (.existsRegion (.lit "crosswalk") "w"
      (.and (.atom "st_entrance_of" [vW, vC] []) (haltOnApproach vW beforeCrosswalk)))

def placeIntersection : Formula :=
  .and (.not stopLineMarks)
    (.and (.not crosswalkMarks) (haltOnApproach vI nearIntersection))

/-- s4: the halt at the place the words name, in their order, on the approach through c. -/
def haltMade : Formula := .or placeStopLine (.or placeCrosswalk placeIntersection)

/-- The halt made through every carrier of the entry into i. -/
def everyApproach : Formula :=
  .forallRegion (.lit "travel_region") "c" (.implies approach haltMade)
/-- The halt made through some carrier of the entry into i. -/
def someApproach : Formula :=
  .existsRegion (.lit "travel_region") "c" (.and approach haltMade)

/-- Obligation: s4 (obligation): shall proceed as if a stop sign had been erected at each entrance to the intersection and shall stop at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, at the point nearest the intersection; s8 (standard): where the driver has a view of approaching traffic on the through highway.
    Decided where the carriers of the entry agree; unknown where they differ. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.definedWhen (.or everyApproach (.not someApproach)) everyApproach)

def rule : Rule :=
  { id := "NRS_484B_250_4_o1"
    laws := ["NRS-484B-250-4"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "a view of approaching traffic on the through highway: how much of the crossing way must be in view"
          concepts := ["st.highway", "st.on_way", "st.sight_along_way"]
          params := ["p.intersection_sight_distance"]
          convention := "Intersection sight distance for a stop-controlled approach (AASHTO Green Book case B): from the halt, the crossing way (a st.highway on which the intersection lies, st.on_way, and the approach carrier does not) is in view for at least p.intersection_sight_distance in the smaller of its two directions (st.sight_along_way 'the distance along a way ... within which another vehicle on that way could be seen from the road user's eye ... the smaller of the two directions'). st.sight_along_way is not a stand-in for whether an actual road user is seen: the view of approaching traffic is the view along the way whether or not traffic is present."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s4"
          why := "The history bound's 'previous entry into i' is read at x's exit from i after that entry (the observation at which rel.occupies x i turns false): a halt x makes while its footprint still overlaps i after a previous entry does not count for this entry."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_250_4_o1
