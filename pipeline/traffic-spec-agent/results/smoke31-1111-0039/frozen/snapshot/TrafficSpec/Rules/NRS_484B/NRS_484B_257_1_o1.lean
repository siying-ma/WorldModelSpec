/-
  NRS_484B_257_1_o1 — NRS-484B-257-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:
    s2 (condition): When proper signs have been erected,
    s3 (subject): the driver of a vehicle
    s4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection
    s8 (standard): where the driver has a view of approaching traffic on the through highway.
    s9 (sibling): After having stopped or, in the event of a yield sign, slowed or stopped,
    s10 (sibling): the driver shall yield the right-of-way
    s11 (sibling): to other vehicles which have entered the intersection from such through highway
    s12 (sibling): or which are approaching so closely on such through highway as to constitute an immediate hazard during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.traffic_signal', 'dev.inoperative', 'dev.governs', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s2: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s4: atoms ['kin.speed', 'kin.velocity', 'kin.heading', 'kin.accel_longitudinal', 'st.stop_line', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'st.region_geometry', 'prim.region_offset_along', 'st.crosswalk', 'rel.occupies', 'st.intersection'], derived ['drv.motion.halted', 'drv.motion.slowing']

  How each is written:
    s3: the class of x is membership of DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    s2: the entry (`selection`): for an intersection i and a travel region c, x occupies c at the
        entry and at the observation before it (`rel_occupies` and not its rise: the record's
        "whether this is an entry through c is unknown where the observation before it does not
        show x on a mapped carrier"), c enters i (`st_lane_enters`), x enters i
        (`drv_motion_entering_region`), and a stop sign or a yield sign governs c or i
        (`dev_governs`, the device quantifiers over `stop_sign` and `yield_sign`).
    s1: the exception: x a member of DEF-NRS-484A-285::traffic and either a `human_direction`
        device whose role is police_officer, or a `traffic_signal` that is not `dev_inoperative`,
        governing c or i. The applicability excludes the pairs (i, c) it holds for. The
        obligation, read only where the applicability holds, does not repeat it: there it is
        decided false for the pair the applicability found, and a leaf the obligation could never
        move is vacuous at the gate (run 3).
    s4, s8: the obligation re-selects (i, c) with the entry and the signs above and, for every pair
        selected, asks the duty at the place the marks of c fix, in the words' order:
        (1) a stop line s with `st_entrance_of s c`: a halt (`drv_motion_halted`) with x's body
            within p.stop_point_tolerance of s (`st_region_geometry_distance`) and s not behind x
            along c (`prim_region_offset_along` ≥ 0);
        (2) no stop line marks c and a crosswalk w with `st_entrance_of w c`: a halt with x's
            footprint not on w, within the tolerance of w, and w ahead along c (offset > 0);
        (3) neither marks c: a halt with x's footprint outside i, within the tolerance of i, or
            with a through highway h (a `highway` with `st_on_way i h` and not `st_on_way c h`) in
            view for at least p.intersection_sight_distance (`st_sight_along_way`): the
            operationalization of s8.
        Where no stop sign governs c or i (only a yield sign does), a slowing
        (`drv_motion_slowing`) before passing the place also meets it: s (or w) not behind x
        along c, or, for place (3), x not yet in i.
    History bound: the act is searched with `since` from the entry back to the approach start —
        the last observation at which x, on c, is outside the place's stopping zone upstream
        (not on the place, offset along c > 0, farther than the tolerance) — or to x's previous
        stay in i (the observation at which x is seen to have left i), whichever is met first
        going back. An act at that bounding observation itself counts; an act before it does
        not. Reaching neither end within the recording leaves the search unknown.
    Several carriers: the obligation holds where the duty holds through every selected carrier,
        fails where it holds through none, and is undefined (unknown) where the carriers differ
        (`definedWhen`).
  No reading beyond the record's was chosen; `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantifier variables: the intersection entered, the approach carrier, the marks, the way. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vW : Arg := .var "w"
def vH : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDecelerationResolution : Term := .param "p.deceleration_resolution"
def pIntersectionSightDistance : Term := .param "p.intersection_sight_distance"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []

/-- Device `d` governs the approach carrier or the intersection. -/
def governsApproach (d : Arg) : Formula :=
  .or (.atom "dev_governs" [d, vC] []) (.atom "dev_governs" [d, vI] [])

/-- s2: a stop sign governs c or i. -/
def stopSignGoverns : Formula := .existsDevice (.lit "stop_sign") "d" (governsApproach (.var "d"))

/-- s2: a yield sign governs c or i. -/
def yieldSignGoverns : Formula := .existsDevice (.lit "yield_sign") "e" (governsApproach (.var "e"))

/-- s1: a police officer directing traffic governs c or i. -/
def policeControls : Formula :=
  .existsDevice (.lit "human_direction") "p"
    (.and (.atom "dev_human_direction_role" [.var "p", .lit "police_officer"] []) (governsApproach (.var "p")))

/-- s1: a traffic-control signal showing a valid indication governs c or i. -/
def signalControls : Formula :=
  .existsDevice (.lit "traffic_signal") "g"
    (.and (.not (.atom "dev_inoperative" [.var "g"] [])) (governsApproach (.var "g")))

/-- s1: x's traffic is being controlled by a police officer or a traffic-control signal. -/
def trafficControlled : Formula :=
  .and (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] []) (.or policeControls signalControls)

/-- s2: x enters i at this observation through c, on c here and at the observation before. -/
def entryThrough : Formula :=
  .and (occupies vC)
    (.and (.not (.rises (occupies vC)))
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.derived "drv_motion_entering_region" [vX, vI] [])))

/-- The selection of (i, c): the entry through c and a stop or yield sign governing c or i. -/
def selection : Formula :=
  .and entryThrough (.or stopSignGoverns yieldSignGoverns)

/-- Applicability: s1 (exception): Except when traffic is being controlled by a police officer or a traffic-control signal:; s2 (condition): When proper signs have been erected, -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c" (.and selection (.not trafficControlled)))

-- s4: the act and the places.

def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]
def slowing : Formula := .derived "drv_motion_slowing" [vX] [pSpeedResolution, pDecelerationResolution]

def distanceTo (r : Arg) : Term := .measure "st_region_geometry_distance" [vX, r]
def offsetTo (r : Arg) : Term := .quantity "prim_region_offset_along" [vX, r, vC] []

def withinTolerance (r : Arg) : Formula := .cmp (distanceTo r) .le pStopPointTolerance
def notBehind (r : Arg) : Formula := .cmp (offsetTo r) .ge zeroMetres
def ahead (r : Arg) : Formula := .cmp (offsetTo r) .gt zeroMetres

/-- x, on c, outside the stopping zone of place `r` upstream: the approach start. -/
def upstreamOfZone (r : Arg) : Formula :=
  .and (occupies vC)
    (.and (.not (occupies r))
      (.and (ahead r) (.cmp (distanceTo r) .gt pStopPointTolerance)))

/-- x is seen to have left i: the end of its previous stay there. -/
def leftIntersection : Formula := .rises (.not (occupies vI))

/-- The act at some observation from the approach start (or the previous stay in i) to now. -/
def searchBack (r : Arg) (act : Formula) : Formula :=
  .since (.not (.or (upstreamOfZone r) leftIntersection)) act

/-- A halt at the place; where no stop sign governs, a slowing before passing it also counts. -/
def placeDuty (r : Arg) (atPlace beforePlace : Formula) : Formula :=
  .or (searchBack r (.and halted atPlace))
    (.and (.not stopSignGoverns) (searchBack r (.and slowing beforePlace)))

def marks (l : Arg) : Formula := .atom "st_entrance_of" [l, vC] []

/-- (1) at a stop line marking c. -/
def stopLinePlace : Formula :=
  .existsRegion (.lit "stop_line") "s"
    (.and (marks vS) (placeDuty vS (.and (withinTolerance vS) (notBehind vS)) (notBehind vS)))

def noStopLine : Formula := .forallRegion (.lit "stop_line") "s" (.not (marks vS))

/-- (2) before the crosswalk marking c, where no stop line marks it. -/
def crosswalkPlace : Formula :=
  .and noStopLine
    (.existsRegion (.lit "crosswalk") "w"
      (.and (marks vW)
        (placeDuty vW (.and (.not (occupies vW)) (.and (withinTolerance vW) (ahead vW))) (notBehind vW))))

def noCrosswalk : Formula := .forallRegion (.lit "crosswalk") "w" (.not (marks vW))

/-- s8: a through highway — one i lies on and c does not — in view for the sight distance. -/
def throughHighwayInView : Formula :=
  .existsRegion (.lit "highway") "h"
    (.and (.atom "st_on_way" [vI, vH] [])
      (.and (.not (.atom "st_on_way" [vC, vH] []))
        (.cmp (.measure "st_sight_along_way" [vX, vH]) .ge pIntersectionSightDistance)))

/-- (3) at the point nearest the intersection, where neither a stop line nor a crosswalk marks c. -/
def intersectionPlace : Formula :=
  .and noStopLine
    (.and noCrosswalk
      (placeDuty vI (.and (.not (occupies vI)) (.or (withinTolerance vI) throughHighwayInView))
        (.not (occupies vI))))

def duty : Formula := .or stopLinePlace (.or crosswalkPlace intersectionPlace)

/-- The duty holds through every selected carrier. -/
def everySelectedComplies : Formula :=
  .forallRegion (.lit "intersection") "i" (.forallRegion (.lit "travel_region") "c" (.implies selection duty))

/-- The duty holds through some selected carrier. -/
def someSelectedComplies : Formula :=
  .existsRegion (.lit "intersection") "i" (.existsRegion (.lit "travel_region") "c" (.and selection duty))

/-- Obligation: s4 (obligation): shall stop or yield at a clearly marked stop line or, if there is none, before entering the crosswalk on the near side of the intersection or, if there is none, then at the point nearest the intersection; s8 (standard): where the driver has a view of approaching traffic on the through highway. -/
def obligation : Formula :=
  .definedWhen (.or everySelectedComplies (.not someSelectedComplies)) everySelectedComplies

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
      [ { standard := "a view of approaching traffic on the through highway: how much of the through highway must be in view"
          concepts := ["st.highway", "st.on_way", "st.sight_along_way"]
          params := ["p.intersection_sight_distance"]
          convention := "Intersection sight distance for a stop- or yield-controlled approach (AASHTO Green Book cases B and C): from the place of the act, the through highway (a st.highway on which the intersection lies, st.on_way, and the subject's approach carrier does not) is in view for at least p.intersection_sight_distance (st.sight_along_way, the smaller of its two directions); not a stand-in for whether an actual road user is seen."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_1_o1
