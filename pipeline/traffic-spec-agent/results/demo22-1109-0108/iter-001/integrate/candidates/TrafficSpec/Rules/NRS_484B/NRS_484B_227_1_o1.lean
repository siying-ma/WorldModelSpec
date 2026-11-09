/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle driven upon a divided highway
    s2 (obligation): must be driven only upon the right-hand roadway
    s3 (sibling): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn,
    s4 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.highway', 'st.roadway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived ['drv.motion.standstill']
    s2: atoms ['st.roadway', 'rel.occupies', 'st.lane_direction', 'st.median_or_divider', 'st.on_way', 'prim.region_lateral_offset'], derived ['drv.position.direction_component']
    s4: atoms ['st.median_or_divider', 'st.intersection', 'rel.occupies', 'st.on_way'], derived []

  How each span is written.

    s1 — the subject and the trigger. `clsV` is the aggregate atom with the admitted id
    DEF-NRS-484A-320::vehicle. "driven upon" is `moving`: the negation of drv.motion.standstill at
    the observation, bounded by p.standstill_speed_tolerance (the plan's observable reading of
    agency; not restated as a narrowing of mine). "a divided highway" is the way `w` the vehicle's
    footprint overlaps (st.highway with rel.occupies) on which `dividedWay` finds a dividing space,
    barrier or section (st.median_or_divider, tied to the way by st.on_way) and two separate
    roadways of that way (st.roadway twice, each tied by st.on_way, distinct by `same`), which is
    the definition's division of the way into two or more roadways by a physical barrier.

    s2 — the duty. `rightHandRoadway` states, of a roadway `rw` of that same way `w` whose
    footprint the vehicle overlaps, both hands of the plan's reading: its designated direction of
    travel agrees with the vehicle's travel — drv.position.direction_component of the vehicle along
    `rw` above the negative of p.wrong_way_speed_tolerance — and the dividing section of that way
    lies to the vehicle's left — prim.region_lateral_offset of that divider from the vehicle at
    least p.lateral_offset_resolution. The duty holds where such a roadway exists; a vehicle on the
    other roadway, on the shoulder or on the median overlaps none and violates it. The obligation
    re-states the whole selection of the way (occupancy, st.highway, `dividedWay`), so `w` denotes
    the way the applicability selected.

    s3 — the sibling span: no element maps it and this rule says nothing about it.

    s4 — the exception, conjoined into the applicability as `.not exceptionOn`: the vehicle's
    footprint overlaps either a dividing section of that way carrying the opening attribute (the
    opening or crossover, st.median_or_divider with st.on_way and rel.occupies) or an intersection
    of that way (st.intersection with st.on_way and rel.occupies). "established by a public
    authority" is the feature's presence (the plan's observable reading).

  Narrowing declared below (s2): "the dividing space, barrier or section" of the way whose side the
  duty reads is written as some dividing section of that way, not every one. A divided highway's
  barrier is mapped as a run of sections (a crossover interrupts it), and the words name the
  division of the way, so the section whose side is read is the one beside the vehicle.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The way, the roadways, the dividing sections and the junction the formulas quantify over. -/
def wR : Arg := .var "w"
def rw1R : Arg := .var "rw1"
def rw2R : Arg := .var "rw2"
def rwR : Arg := .var "rw"
def dR : Arg := .var "d"
def oR : Arg := .var "o"
def xR : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLateralOffsetResolution : Term := .param "p.lateral_offset_resolution"
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"
def pWrongWaySpeedTolerance : Term := .param "p.wrong_way_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the vehicle is driven upon the way — its motion is not a complete cessation. -/
def moving : Formula :=
  .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- s1: `w` is a divided highway — a dividing space, barrier or section on `w` and two separate
    roadways of `w`. -/
def dividedWay : Formula :=
  .and
    (.existsRegion (.lit "median_or_divider") "d"
      (.and (.atom "st_median_or_divider" [dR] [])
        (.atom "st_on_way" [dR, wR] [])))
    (.existsRegion (.lit "roadway") "rw1"
      (.and (.atom "st_roadway" [rw1R] [])
        (.and (.atom "st_on_way" [rw1R, wR] [])
          (.existsRegion (.lit "roadway") "rw2"
            (.and (.atom "st_roadway" [rw2R] [])
              (.and (.atom "st_on_way" [rw2R, wR] [])
                (.not (.same rw1R rw2R))))))))

/-- s4: the vehicle is within an opening, crossover or intersection of `w`. -/
def exceptionOn : Formula :=
  .or
    (.existsRegion (.lit "median_or_divider") "o"
      (.and (.atom "st_median_or_divider" [oR] [])
        (.and (.atom "st_median_or_divider_opening" [oR] [])
          (.and (.atom "st_on_way" [oR, wR] [])
            (.atom "rel_occupies" [vV, oR] [])))))
    (.existsRegion (.lit "intersection") "x"
      (.and (.atom "st_intersection" [xR] [])
        (.and (.atom "st_on_way" [xR, wR] [])
          (.atom "rel_occupies" [vV, xR] []))))

/-- s1: the vehicle's footprint overlaps the divided highway `w`. -/
def uponDividedHighway (rest : Formula) : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_highway" [wR] [])
      (.and (.atom "rel_occupies" [vV, wR] [])
        (.and dividedWay rest)))

/-- s2: `rw` is the vehicle's right-hand roadway of `w` — a roadway of that way its footprint
    overlaps, whose designated direction of travel agrees with its travel and which has a dividing
    section of that way to its left. -/
def rightHandRoadway : Formula :=
  .and (.atom "st_roadway" [rwR] [])
    (.and (.atom "st_on_way" [rwR, wR] [])
      (.and (.atom "rel_occupies" [vV, rwR] [])
        (.and
          (.cmp (.quantity "drv_position_direction_component" [vV, rwR] [])
            .gt (.neg pWrongWaySpeedTolerance))
          (.existsRegion (.lit "median_or_divider") "d"
            (.and (.atom "st_median_or_divider" [dR] [])
              (.and (.atom "st_on_way" [dR, wR] [])
                (.cmp (.quantity "prim_region_lateral_offset" [vV, dR] [])
                  .ge pLateralOffsetResolution)))))))

/-- Applicability: s1 (subject) with s4 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority. -/
def applicability : Formula :=
  .and moving (uponDividedHighway (.not exceptionOn))

/-- Obligation: s2 (obligation): must be driven only upon the right-hand roadway -/
def obligation : Formula :=
  uponDividedHighway (.existsRegion (.lit "roadway") "rw" rightHandRoadway)

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s2"
          why := "“the right-hand roadway” has “the dividing space, barrier or section” of the way to its left: the side is read of some dividing section of that way, not of every one. A divided highway's barrier is mapped as a run of sections — a crossover or a junction interrupts it — and the words name the division of the way, so the section whose side the duty reads is the one beside the vehicle."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o1
