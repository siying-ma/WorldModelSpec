/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle:
    s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a
    s3 (condition): street
    s4 (condition): corner.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.intersection', 'st.crosswalk', 'rel.occupies'], derived ['drv.motion.reverse_travel']
    s4: atoms ['st.intersection', 'st.highway', 'st.on_way', 'rel.occupies'], derived ['drv.motion.turning']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s1 (the subject, `v`): the class of `v` is the admitted aggregate of DEF-NRS-484A-320, written
  as the atom `ru_aggregate` with the aggregate id as its literal argument. "The driver of a
  vehicle" is the vehicle whose motion is controlled, the record's own observable reading of
  agency; nothing of it is written beyond the class.

  The duty. The record's `applicability` states that the prohibition "has no further trigger: it
  bites at any observation at which the vehicle is travelling rearward", so the applicability is
  `.tt`: the rule engages wherever a vehicle of the aggregate is observed, and the whole of the
  prohibition — the rearward motion included, as the record's `obligation` writes it ("while
  travelling rearward … (a) … (b) … (c)") — is the obligation. The obligation is therefore
  `.not (reversing ∧ (a ∨ b ∨ c))`: at no observation may the vehicle be travelling rearward and
  meet one of the three limbs. The limbs are joined by `.or`, as the record directs, so a decided
  limb decides the duty even where another is unknown for want of the city-limits declaration.

  s2 (backing, and the first two limbs): "back" is `drv.motion.reverse_travel` on `v` with
  `p.reverse_speed_tolerance` — the component of the velocity along the body's heading rearward
  beyond the tolerance, which is how the ontology reads the word; no gear and no lamp enters it.
  Limb (a), "back into an intersection", is the entry event: a region of kind `intersection`
  (`st_intersection`) whose overlap by the vehicle's footprint rises here, `.rises` of
  `rel_occupies`, which is the record's own reading of "into". Limb (b), "on or over a
  crosswalk", is the overlap itself: a region of kind `crosswalk` (`st_crosswalk`) the
  vehicle's footprint overlaps (`rel_occupies`). Both regions are bound by their own quantifier
  and anchored to `v` by `rel_occupies`; the crosswalk is read by its kind alone, which carries
  both limbs of DEF-NRS-484A-065 (marked crossing, and the unmarked prolongation at an
  intersection), and no marked attribute is required of it.

  s3 and s4 (limb (c), "around a street corner"): the record's `obligation` places this limb in
  the duty, conditioned on nothing else: the vehicle is turning (`drv.motion.turning` on `v`
  with `p.turn_recognition_window` and `p.heading_change_noise_floor` — the heading change over
  the window behind standing clear of the source's resolution, the turn read by its presence and
  by no angle) while its footprint overlaps (`rel_occupies`) a region of kind `intersection`
  that lies (`st_on_way`) on two regions of kind `highway` (`st_highway`), and
  `asm.inside_city_limits` holds. "Two highways meet" is written as two highway variables held
  apart by `.not (.same h1 h2)`: that the ways are two is what the words say, and `st_on_way`
  is what makes the junction a junction of ways rather than a bare region. The assumption is the
  flat `.asm`, which is right because the declared assumption's own words are already
  region-relative ("the highway the road user occupies at the observation lies inside the
  territorial limits of a city"): the trace declares it of the observation. `h1` and `h2` are
  anchored through `st_on_way` to the junction `j`, which `rel_occupies` anchors to `v`.

  The duty binds every region the limbs can pick out, so each limb is an existential over its own
  regions: one intersection backed into, one crosswalk overlapped, one junction of two ways
  turned in — the prohibition is met as soon as one such region is found, which is what the
  disjunctive words state. No span is read more narrowly than its words, so `narrowings` is empty:
  the readings of agency on s1 and of "into" on s2 are the record's own and are not restated here.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The regions the formulas quantify over: the intersection backed into, the crosswalk
    overlapped, the junction turned in and the two ways that meet there. -/
def iV : Arg := .var "i"
def cwV : Arg := .var "cw"
def jV : Arg := .var "j"
def h1V : Arg := .var "h1"
def h2V : Arg := .var "h2"

/-- The admitted aggregate of the node's class element, by its id. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingChangeNoiseFloor : Term := .param "p.heading_change_noise_floor"
def pReverseSpeedTolerance : Term := .param "p.reverse_speed_tolerance"
def pTurnRecognitionWindow : Term := .param "p.turn_recognition_window"

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, aggVehicle] []

/-- s2: "back" — the vehicle is travelling rearward along its own heading. -/
def reversing : Formula :=
  .derived "drv_motion_reverse_travel" [vV] [pReverseSpeedTolerance]

/-- s4: "around" — the vehicle's heading is changing over the window behind. -/
def turning : Formula :=
  .derived "drv_motion_turning" [vV] [pTurnRecognitionWindow, pHeadingChangeNoiseFloor]

/-- s2, limb (a): "into an intersection" — the vehicle's footprint comes to overlap a junction
    region here, the rise of that overlap. -/
def backsIntoIntersection : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and (.atom "st_intersection" [iV] [])
          (.rises (.atom "rel_occupies" [vV, iV] [])))

/-- s2, limb (b): "on or over a crosswalk" — the vehicle's footprint overlaps a crossing. -/
def onOrOverCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "cw"
    (.and (.atom "st_crosswalk" [cwV] [])
          (.atom "rel_occupies" [vV, cwV] []))

/-- s4: the junction `j` the vehicle's footprint overlaps is the region where two highways
    meet. -/
def junctionOfTwoWays : Formula :=
  .and (.atom "st_intersection" [jV] [])
    (.and (.atom "rel_occupies" [vV, jV] [])
      (.existsRegion (.lit "highway") "h1"
        (.and (.atom "st_highway" [h1V] [])
          (.and (.atom "st_on_way" [jV, h1V] [])
            (.existsRegion (.lit "highway") "h2"
              (.and (.atom "st_highway" [h2V] [])
                (.and (.not (.same h1V h2V))
                      (.atom "st_on_way" [jV, h2V] []))))))))

/-- s3, s4, limb (c): "around a street corner" — turning in the corner of a junction of two
    highways, the trace declaring the junction inside the territorial limits of a city. -/
def aroundStreetCorner : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and junctionOfTwoWays
      (.and (.asm "asm.inside_city_limits") turning))

/-- Applicability: s3 (condition): street; s4 (condition): corner. -/
def applicability : Formula := .tt

/-- Obligation: s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a -/
def obligation : Formula :=
  .not
    (.and reversing
      (.or backsIntoIntersection
        (.or onOrOverCrosswalk aroundStreetCorner)))

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.inside_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2
