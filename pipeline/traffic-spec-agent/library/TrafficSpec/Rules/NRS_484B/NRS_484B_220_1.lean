/-
  NRS_484B_220_1 — NRS-484B-220-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon a highway designated and signposted for one-way traffic
    s2 (subject): a vehicle
    s3 (obligation): shall be driven only in the direction designated.

  Elements (span → atoms, derived):
    s1: atoms ['st.highway', 'st.one_way_roadway', 'st.on_way', 'rel.occupies', 'dev.regulatory_sign', 'dev.governs', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.lane_direction', 'st.one_way_roadway', 'rel.occupies'], derived ['drv.lane.travels_with_region_direction']

  How each span is written:

    s2 — the subject's class is the single aggregate atom `ru_aggregate` under the admitted id
    DEF-NRS-484A-320::vehicle; the classes the definition covers are the reading's, never this
    file's.

    s1 — `selectsRoad` is the whole selection of the structure the duty speaks of: the subject
    `rel_occupies` a region the quantifier draws from the scene's `one_way_roadway` regions (the
    region's kind is the “designated … for one-way traffic” restriction, read from the region as the
    record's narrowing states); that region `st_on_way` some region of kind `highway` (“upon a
    highway”); and some device of kind `regulatory_sign` both `dev_governs` that region and carries
    `dev_regulatory_sign_code` one_way (“signposted”) — the restriction is the region's and the
    posting the sign's, as the element requires, so the two are separate conjuncts and the sign's
    governed region is the very region the subject occupies, not the sign's position. “one-way
    traffic” is the admitted aggregate DEF-NRS-484A-285::traffic: the only track the rule binds is
    the subject, so the aggregate atom is read of the subject — the traffic whose direction the
    signposted restriction governs here is the subject itself. (Choice, on a trigger span, so
    recorded here and not as a narrowing: the aggregate has no other carrier in this rule, and for
    every class the vehicle aggregate includes the traffic aggregate includes it too, so the
    conjunct adds no exclusion to the duty's reach.)

    s3 — the duty is the claimed concept `drv.lane.travels_with_region_direction`, called on the
    subject and on that same one-way roadway with p.motion_speed_tolerance: the component of the
    subject's velocity along the region's designated direction is above the negative of the
    tolerance, so travel against the designated direction by more than the tolerance is the
    violation and standing still is compliance. `st.lane_direction` and the velocity are the
    concept's own reads. Because the applicability's region variable is not in scope in the
    obligation, the whole selection is written again there (`selectsRoad`), so the region denoted is
    the same one.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_220_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The region the trigger selects: the one-way roadway the subject travels in. -/
def vRoad : Arg := .var "road"

/-- The public way that roadway lies on. -/
def vWay : Arg := .var "way"

/-- The regulatory sign that posts the one-way restriction. -/
def vSign : Arg := .var "sign"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- “Upon a highway”: the region lies on a public way. -/
def onHighway (road : Arg) : Formula :=
  .existsRegion (.lit "highway") "way"
    (.atom "st_on_way" [road, vWay] [])

/-- “signposted for one-way traffic”: a regulatory sign of catalogue code one_way governs the
    region the subject travels in. -/
def signposted (road : Arg) : Formula :=
  .existsDevice (.lit "regulatory_sign") "sign"
    (.and (.atom "dev_governs" [vSign, road] [])
          (.atom "dev_regulatory_sign_code" [vSign, .lit "one_way"] []))

/-- The whole selection of the one-way roadway the trigger binds: the subject occupies it, it lies
    on a highway, a one_way regulatory sign governs it, and the subject is traffic. -/
def selectsRoad (road : Arg) : Formula :=
  .and (.atom "rel_occupies" [vSubject, road] [])
    (.and (onHighway road)
      (.and (signposted road)
        (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (trigger): Upon a highway designated and signposted for one-way traffic -/
def applicability : Formula :=
  .existsRegion (.lit "one_way_roadway") "road" (selectsRoad vRoad)

/-- Obligation: s3 (obligation): shall be driven only in the direction designated. -/
def obligation : Formula :=
  .forallRegion (.lit "one_way_roadway") "road"
    (.implies (selectsRoad vRoad)
      (.derived "drv_lane_travels_with_region_direction" [vSubject, vRoad]
        [pMotionSpeedTolerance]))

def rule : Rule :=
  { id := "NRS_484B_220_1"
    laws := ["NRS-484B-220-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3",
          why := "The record binds the duty to “that one-way roadway”, the region the trigger " ++
                 "selects, and the applicability selects it existentially; where the subject " ++
                 "occupies more than one such signposted one-way roadway at once, the obligation " ++
                 "is written for every region the selection admits, not for one of them, so the " ++
                 "duty states travel with the designated direction of each.",
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_220_1
