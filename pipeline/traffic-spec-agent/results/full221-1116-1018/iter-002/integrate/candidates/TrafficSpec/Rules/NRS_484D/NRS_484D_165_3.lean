/-
  NRS_484D_165_3 — NRS-484D-165-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    t1 (trigger): Whenever a vehicle is parked or stopped
    t2 (condition): upon the traveled portion of a highway or shoulder adjacent thereto,
    t3 (condition): whether attended or unattended
    t4 (condition): during the times mentioned
    t5 (reference): in NRS 484D.100 [NRS-484D-100-1],
    t6 (condition): and there is insufficient light to reveal any person or object within a distance of 1,000 feet upon such highway or roadway,
    t7 (obligation): such vehicle shall display lighted lamps
    t8 (reference): meeting the requirements of subsection 1 [(1) appended below].
    t9 (definitional): Every vehicle shall be equipped with one or more lamps which, when lighted, shall display a white or amber light visible from a distance of 500 feet to the front of the vehicle, and one or more lamps which, when lighted, shall display a red light visible from a distance of 500 feet to the rear of the vehicle.
    t10 (definitional): The location of such lamps shall be such that at least one such lamp is installed as near as practicable to the side of the vehicle which is closest to passing traffic.

  Elements (span → atoms, derived):
    t1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']
    t2: atoms ['rel.occupies', 'st.roadway', 'st.shoulder', 'st.highway', 'st.on_way'], derived []
    t4: atoms ['env.darkness', 'env.visibility'], derived [], borrowing ['t5']
    t6: atoms ['env.darkness', 'env.visibility'], derived []
    t7: atoms ['sig.position_lamp'], derived [], borrowing ['t8']

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    t5: NRS-484D-100-1: (a) At any time from one-half hour after sunset to one-half hour before sunrise; (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;
    t8: NRS-484D-165-3: one or more lamps which, when lighted, shall display a white or amber light visible from a distance of 500 feet to the front of the vehicle, and one or more lamps which, when lighted, shall display a red light visible from a distance of 500 feet to the rear of the vehicle

  Literals the text states (each written through its Units constructor):
    t6: 1000 ft — 1,000 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each element is written:
    class: ru_aggregate(subject, "DEF-NRS-484A-320::vehicle").
    t1: drv_motion_complete_halt(subject; p.halt_speed_tolerance).
    t2: some roadway the subject occupies (rel_occupies), or some shoulder the subject occupies
        that lies (st_on_way) on a highway on which some roadway also lies — the record's
        "a shoulder lying on the same highway as a roadway". The roadway limb adds no highway
        condition: a roadway is by its contract part of a highway.
    t4 + t6: env_darkness, or env_visibility < 1,000 ft (Units.feet 1000). Both spans map to the
        same atoms and the same figure; the formula is written once (conjoining it with itself
        would add nothing).
    t3: residue (attended or not, the same duty).
    t7 (+ t8): sig_position_lamp(subject) at the observation.
  No choice beyond the record's own: no narrowing declared.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484D_165_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- t6 literal: 1,000 feet, written through its Units constructor (304.8 m). -/
def thousandFeet : Term := .lit (Units.feet 1000) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- t1: parked or stopped — the vehicle at rest (drv.motion.complete_halt). -/
def atRest : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- t2: on the traveled portion of a highway (a roadway the subject occupies), or on a shoulder
    the subject occupies that lies on the same highway as a roadway ("shoulder adjacent thereto"). -/
def onRoadwayOrShoulder : Formula :=
  .or
    (.existsRegion (.lit "roadway") "rw"
      (.atom "rel_occupies" [vSubject, .var "rw"] []))
    (.existsRegion (.lit "shoulder") "sh"
      (.and (.atom "rel_occupies" [vSubject, .var "sh"] [])
        (.existsRegion (.lit "highway") "hw"
          (.and (.atom "st_on_way" [.var "sh", .var "hw"] [])
            (.existsRegion (.lit "roadway") "rw2"
              (.atom "st_on_way" [.var "rw2", .var "hw"] []))))))

/-- t4 (times of NRS-484D-100-1 (a)/(b), borrowed through t5) and t6 (insufficient light to reveal
    a person or object within 1,000 feet): both map to env.darkness, or env.visibility below the
    literal 1,000 ft. The two spans state the same condition and are written once; t6 entails t4. -/
def insufficientLight : Formula :=
  .or (.atom "env_darkness" [] [])
    (.cmp (.measure "env_visibility" []) .lt thousandFeet)

/-- Applicability: t1 (trigger): Whenever a vehicle is parked or stopped; t2 (condition): upon the traveled portion of a highway or shoulder adjacent thereto,; t3 (condition): whether attended or unattended; t4 (condition): during the times mentioned; t6 (condition): and there is insufficient light to reveal any person or object within a distance of 1,000 feet upon such highway or roadway, -/
def applicability : Formula :=
  .and atRest (.and onRoadwayOrShoulder insufficientLight)

/-- Obligation: t7 (obligation): such vehicle shall display lighted lamps (t8: the lamps of
    subsection 1, read as the position lamps — sig.position_lamp). -/
def obligation : Formula :=
  .atom "sig_position_lamp" [vSubject] []

def rule : Rule :=
  { id := "NRS_484D_165_3"
    laws := ["NRS-484D-165-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'whether attended or unattended' covers both states: the duty is the same whether or not anyone attends the vehicle.", "The equipment duty and the lamps' colour (white or amber to the front, red to the rear) and reach (visible from 500 feet) describe the lamps the obligation requires displayed; no atom carries a lamp's colour, reach or fitment, so the rule reads only that the position lamps are lit.", "The location of the lamps (one as near as practicable to the side closest to passing traffic) is a fitment requirement no atom carries; the rule does not read it."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484D_165_3
