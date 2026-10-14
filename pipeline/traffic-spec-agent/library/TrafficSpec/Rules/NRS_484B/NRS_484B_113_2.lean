/-
  NRS_484B_113_2 — NRS-484B-113-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a street corner.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=vehicle'], derived []
    s2: atoms ['st.intersection', 'st.crosswalk', 'rel.occupies', 'st.region_geometry', 'prim.heading_change'], derived ['drv.motion.backing']

  How each span is written.

  s1 — "The driver of a vehicle". The class of the binder `v` is the aggregate atom with the
  corpus word as its literal argument: `ru_aggregate v "vehicle"`. "The driver" adds nothing; the
  node reads the span through the vehicle's conduct (its own narrowing, category agency), so the
  duty binds the vehicle whose motion is controlled on the road. Nothing is declared here for it:
  the subject span decides when the rule applies and is carried as the node maps it.

  Occasion — the act is `drv.motion.backing v` over the window `p.backing_window` with the floor
  `p.speed_zero_tolerance`, and it is the whole applicability: the rule speaks only while the
  subject is travelling rearward at every observation of the window behind. The node assigns no
  span to the occasion (`spans` is empty), so every limb of s2 is read where the act is
  recognized, and `kin.velocity`/`kin.heading` of the `under_way` element are read inside the
  concept's body, which is expanded into this rule before evaluation.

  s2 — "Shall not back into an intersection, on or over a crosswalk, or around a street corner"
  is one prohibition with three limbs, written as the negation of their disjunction so that any
  one of them breaks the duty:

    * "back into an intersection" — `existsRegion intersection j, rises (rel_occupies v j)`. The
      footprint comes to overlap a junction region it did not overlap a moment before, while the
      act is under way; a vehicle already standing in the junction when it begins to reverse never
      raises that edge. (Narrowing 1: "when the backing began" is anchored at the previous
      observation.)
    * "on or over a crosswalk" — `existsRegion crosswalk c, rel_occupies v c`. A place occupied,
      not an entry: no rising edge, and the marked attribute is not required, so both limbs of the
      definition (a marked crossing and the unmarked prolongation at an intersection) count.
    * "around a street corner" — `existsRegion intersection jc,
      st_region_geometry_distance v jc ≤ p.corner_reach ∧ |prim_heading_change v p.backing_window|
      > p.corner_heading_change`. The ontology carries no corner; what is observed is the junction
      whose corner it is, together with the heading swing that going round it requires, integrated
      over the same window the act is recognized over.

  Narrowings declared below, all on s2 (the duty span), all of kind `reading`:
    1. the entry of the first limb is read against the previous observation;
    2. the second limb is read as occupancy at any observation of the act, not as an entry;
    3. the third limb is read as a swing over the backing window near a junction region.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_113_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBackingWindow : Term := .param "p.backing_window"
def pCornerHeadingChange : Term := .param "p.corner_heading_change"
def pCornerReach : Term := .param "p.corner_reach"
def pSpeedZeroTolerance : Term := .param "p.speed_zero_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "vehicle"] []

/-- The act of the occasion: the subject travels rearward at every observation of the window
    behind, its velocity's component along its own heading negative and at or above the floor. -/
def backing : Formula :=
  .derived "drv_motion_backing" [vV] [pBackingWindow, pSpeedZeroTolerance]

/-- Applicability: the act is under way (the node's occasion; no separate trigger span). -/
def applicability : Formula := backing

/-- The subject's footprint overlaps the region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vV, .var r] []

/-- "back into an intersection": the footprint comes to overlap a junction region it did not
    overlap at the observation before, the act being under way at both. -/
def backsIntoIntersection : Formula :=
  .existsRegion (.lit "intersection") "j" (.rises (occupies "j"))

/-- "on or over a crosswalk": the footprint overlaps a crosswalk region, however the overlap began. -/
def onOrOverCrosswalk : Formula :=
  .existsRegion (.lit "crosswalk") "c" (occupies "c")

/-- "around a street corner": the heading swings, over the backing window, through more than the
    corner angle while the body is within the corner reach of a junction region. -/
def aroundStreetCorner : Formula :=
  .existsRegion (.lit "intersection") "jc"
    (.and
      (.cmp (.measure "st_region_geometry_distance" [vV, .var "jc"]) .le pCornerReach)
      (.cmp (.abs (.quantity "prim_heading_change" [vV] [pBackingWindow])) .gt pCornerHeadingChange))

/-- Obligation: s2 (obligation): Shall not back into an intersection, on or over a crosswalk, or around a street corner. -/
def obligation : Formula :=
  .not (.or backsIntoIntersection (.or onOrOverCrosswalk aroundStreetCorner))

def rule : Rule :=
  { id := "NRS_484B_113_2"
    laws := ["NRS-484B-113-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s2"
          why := "\"back into an intersection\" is read as an entry, and the entry is anchored at the previous observation: the footprint overlaps a junction region here and did not overlap it at the observation before, the act being under way throughout the window behind. The words say \"not overlapping when the backing began\", and the act may have begun before the recording; the observation before is the latest instant at which the overlap can be seen to start while the subject is already backing. A vehicle already standing in the junction when it begins to reverse therefore never raises that edge."
          kind := "reading" }
      , { span := "s2"
          why := "\"on or over a crosswalk\" is read without the entry restriction: the footprint overlapping a crosswalk region at any observation while the act is under way is enough, whether the overlap began during the act or before it, since \"on or over\" names a place occupied. The marked attribute is not required, so a marked crossing and the unmarked prolongation of sidewalks at an intersection both count."
          kind := "reading" }
      , { span := "s2"
          why := "\"around a street corner\" is read as a turn through more than the corner angle, integrated over the backing window, while the body is within the corner reach of an intersection region. The ontology carries no atom for a corner; what is observed is the junction region whose corner it is together with the heading swing that going round it requires. A reversing vehicle whose heading holds steady does not turn a corner, and one that swings its heading far from any junction is not at a street corner."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_113_2
