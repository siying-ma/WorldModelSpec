/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle:
    s2 (obligation): Shall not back
    s3 (condition): into an intersection,
    s4 (condition): on or over a crosswalk,
    s5 (condition): or around a
    s6 (condition): street
    s7 (condition): corner.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.velocity'], derived []
    s2: atoms ['kin.velocity', 'kin.heading'], derived ['drv.motion.rearward_motion']
    s3: atoms ['st.intersection', 'rel.occupies'], derived ['drv.lane.enters_region']
    s4: atoms ['st.crosswalk', 'rel.occupies'], derived []
    s5: atoms ['kin.yaw_rate'], derived ['drv.motion.turning']
    s7: atoms ['st.intersection', 'st.region_geometry', 'rel.occupies'], derived []

  How each span is written:

    s1 — `clsSubject`: the atom `ru_aggregate` of the binder with the admitted aggregate id
      DEF-NRS-484A-320::vehicle as its literal argument, never the classes it covers. The record's
      observable reading of ‘the driver of’ (its own narrowing, not restated here) carries the duty
      through the vehicle's controlled motion, which `obligation` reads with kin.velocity through
      drv.motion.rearward_motion.

    s2 — `rearward`: drv.motion.rearward_motion of the subject, bounded by
      p.reverse_speed_tolerance; the concept reads kin.velocity along kin.heading.

    s3 — `entersIntersection`: a region of kind st.intersection the subject's footprint overlaps
      (rel_occupies, the anchor the record names) and enters at this observation
      (drv.lane.enters_region): ‘into’ is the entry, not the stay that follows it.

    s4 — `onCrosswalk`: a region of kind st.crosswalk the subject's footprint overlaps
      (rel_occupies). The whole extent of the definition is kept: marked and unmarked crossings
      alike, so st_crosswalk_marked is not read.

    s5 + s6 + s7 — `aroundStreetCorner`: the subject is turning (drv.motion.turning of the subject,
      bounded by p.yaw_rate_tolerance, magnitude only, so neither hand is preferred), the trace
      declares asm.way_within_city_limits for the way (s6, the record's assumption), and the
      subject's body lies within p.corner_reach of a region of kind st.intersection, the ground
      distance st.region_geometry gives (st_region_geometry_distance). That distance is zero where
      the footprint overlaps the junction, so the clause already covers the subject at the corner it
      has reached as well as the one it has not; rel.occupies carries the overlap in s3 and s4.

    Obligation — the record's: at no observation does the subject travel rearward while any of the
      three places holds of it. Applicability is the binder's class alone: the record states that
      nothing further restricts where the section applies, and the three places are the
      obligation's, since backing anywhere else complies rather than falls outside the duty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCornerReach : Term := .param "p.corner_reach"
def pReverseSpeedTolerance : Term := .param "p.reverse_speed_tolerance"
def pYawRateTolerance : Term := .param "p.yaw_rate_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: the subject is a vehicle present in the scene; the record states that nothing
    further restricts where the section applies — s3, s4, s5–s7 are places the duty forbids backing
    at, and they are written in the obligation. -/
def applicability : Formula := .tt

/-- s2: the subject travels rearward. -/
def rearward : Formula :=
  .derived "drv_motion_rearward_motion" [vSubject] [pReverseSpeedTolerance]

/-- s5: the subject is turning, either hand. -/
def turning : Formula :=
  .derived "drv_motion_turning" [vSubject] [pYawRateTolerance]

/-- s3: the observation at which the subject's footprint begins to overlap a junction region. -/
def entersIntersection : Formula :=
  .existsRegion (.lit "intersection") "junction"
    (.and (.atom "rel_occupies" [vSubject, .var "junction"] [])
          (.derived "drv_lane_enters_region" [vSubject, .var "junction"] []))

/-- s4: the subject's footprint overlaps a crosswalk. -/
def onCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "crossing"
    (.atom "rel_occupies" [vSubject, .var "crossing"] [])

/-- s5 + s6 + s7: the subject turns within reach of a junction on a way inside city limits. -/
def aroundStreetCorner : Formula :=
  .and turning
    (.and (.asm "asm.way_within_city_limits")
      (.existsRegion (.lit "intersection") "corner"
        (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "corner"])
              .le pCornerReach)))

/-- Obligation: s2 (obligation): Shall not back -/
def obligation : Formula :=
  .not (.and rearward
    (.or entersIntersection (.or onCrosswalk aroundStreetCorner)))

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.way_within_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2
