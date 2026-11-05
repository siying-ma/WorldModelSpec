/-
  NRS_484B_227_1_o1 — NRS-484B-227-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (trigger): driven upon a divided highway
    s3 (obligation): must be driven only upon the right-hand roadway
    s4 (sibling): and must not be driven over, across or within any dividing space, barrier or section or make any left turn, semicircular turn or U-turn,
    s5 (exception): except through an opening in the barrier or dividing section or space or at a crossover or intersection established by a public authority.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.highway', 'st.roadway', 'st.median_or_divider', 'st.on_way', 'rel.occupies'], derived []
    s3: atoms ['st.roadway', 'st.lane_direction', 'rel.occupies'], derived ['drv.lane.travels_with_region_direction']
    s5: atoms ['st.median_or_divider', 'st.intersection', 'st.roadway', 'rel.occupies'], derived []

  How each span is written.

    s1 — the binder's class is the admitted aggregate under its own id: `ru_aggregate` of the
    subject with the literal `DEF-NRS-484A-320::vehicle`, never the classes the definition covers.
    That “driven” is read through the vehicle's controlled motion is the record's own narrowing.

    s2 — the trigger is one nested selection, so that every region it speaks of is the subject's
    own: a roadway (`st_roadway`) the subject's footprint overlaps (`rel_occupies`), which lies
    (`st_on_way`) on a highway (`st_highway`) on which there also lies a physical barrier or
    dividing section (`st_median_or_divider`, `st_on_way`) — the configuration DEF-NRS-484A-070
    states for a divided highway. The nesting is what makes the way the subject's way and the
    divider a divider of that way.

    s5 — the exception is read inside that same way: the subject's footprint overlaps a divider of
    the way that carries an opening (`st_median_or_divider_opening`, the atom's own attribute, read
    for “an opening in the barrier or dividing section or space or … a crossover”), or an
    intersection lying on the way (`st_intersection`, `st_on_way`). It is conjoined negated into the
    applicability, so the duty does not arise there. That the feature's presence is the evidence of
    its establishment by a public authority is the record's own narrowing.

    s3 — the duty is the operational reading the record states: at every roadway the trigger
    selects, the subject travels with that roadway's designated direction,
    `drv.lane.travels_with_region_direction` of the subject on that roadway with
    `p.motion_speed_tolerance`. Because a region bound in the applicability is not in scope in the
    obligation, the obligation re-states the trigger's whole selection of the roadway (roadway kind,
    the subject's occupancy, the way, the divider on that way) as the antecedent, over every such
    roadway: where the subject's footprint overlaps two roadways of the divided highway it must
    travel with the designation of each. The concept reads `st.lane_direction`, so a roadway with no
    designated direction leaves the duty unknown rather than satisfied.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_227_1_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: a physical barrier or dividing section lies on the way `way` — the way is divided. -/
def dividerOn (way : String) : Formula :=
  .existsRegion (.lit "median_or_divider") "divider"
    (.and (.atom "st_median_or_divider" [.var "divider"] [])
          (.atom "st_on_way" [.var "divider", .var way] []))

/-- s5: the subject is within an opening or crossover of a divider of `way`, or within an
    intersection on `way`. -/
def exceptionOn (way : String) : Formula :=
  .or
    (.existsRegion (.lit "median_or_divider") "opening"
      (.and (.atom "st_median_or_divider" [.var "opening"] [])
      (.and (.atom "st_on_way" [.var "opening", .var way] [])
      (.and (.atom "st_median_or_divider_opening" [.var "opening"] [])
            (.atom "rel_occupies" [vSubject, .var "opening"] [])))))
    (.existsRegion (.lit "intersection") "junction"
      (.and (.atom "st_intersection" [.var "junction"] [])
      (.and (.atom "st_on_way" [.var "junction", .var way] [])
            (.atom "rel_occupies" [vSubject, .var "junction"] []))))

/-- s2 and s5: the subject occupies a roadway of a divided highway, and is not then within an
    opening, a crossover or an intersection of that way. -/
def applicability : Formula :=
  .existsRegion (.lit "roadway") "rdwy"
    (.and (.atom "st_roadway" [.var "rdwy"] [])
    (.and (.atom "rel_occupies" [vSubject, .var "rdwy"] [])
      (.existsRegion (.lit "highway") "way"
        (.and (.atom "st_highway" [.var "way"] [])
        (.and (.atom "st_on_way" [.var "rdwy", .var "way"] [])
        (.and (dividerOn "way")
              (.not (exceptionOn "way"))))))))

/-- s3: at every roadway of the divided highway the subject occupies, its travel is with that
    roadway's designated direction. -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "rdwy"
    (.implies
      (.and (.atom "st_roadway" [.var "rdwy"] [])
      (.and (.atom "rel_occupies" [vSubject, .var "rdwy"] [])
        (.existsRegion (.lit "highway") "way"
          (.and (.atom "st_highway" [.var "way"] [])
          (.and (.atom "st_on_way" [.var "rdwy", .var "way"] [])
                (dividerOn "way"))))))
      (.derived "drv_lane_travels_with_region_direction"
        [vSubject, .var "rdwy"] [pMotionSpeedTolerance]))

def rule : Rule :=
  { id := "NRS_484B_227_1_o1"
    laws := ["NRS-484B-227-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_227_1_o1
