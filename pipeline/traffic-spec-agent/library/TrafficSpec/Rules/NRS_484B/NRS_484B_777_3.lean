/-
  NRS_484B_777_3 — NRS-484B-777-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Persons riding bicycles, electric bicycles or electric scooters
    s2 (condition): upon a roadway
    s3 (obligation): shall not ride more than two abreast
    s4 (exception): except on paths or parts of roadways set aside for the exclusive use of bicycles, electric bicycles and electric scooters.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s2: atoms ['rel.occupies', 'st.roadway'], derived []
    s3: atoms ['rel.longitudinal_overlap', 'rel.same_direction', 'rel.surface_gap'], derived ['drv.motion.complete_halt']
    s4: atoms ['rel.occupies', 'st.bicycle_lane_or_path'], derived []

  How each span is written.
    s1: `isRider x` is the disjunction of the three `ru_aggregate` atoms, each with its admitted
        aggregate id as the literal; it is the subject's class and the class of the two other
        riders the obligation counts. "Riding" is the record's agency reading: the device moves,
        `not drv_motion_complete_halt x [p.halt_speed_tolerance]`; the record's applicability
        states it for the subject, its obligation for the two others.
    s2: some region of kind `roadway` the subject occupies (`rel_occupies`).
    s4: no region of kind `bicycle_lane_or_path` the subject occupies (`rel_occupies`), conjoined
        into the applicability as the record states it.
    s3: there are no road users b and c, distinct from each other and from the subject, both
        riders (s1) and moving, such that each of the three pairs (subject,b), (subject,c), (b,c)
        is side by side (`rel_longitudinal_overlap` ≥ 0, read on the first member's heading) with
        headings aligned (`rel_same_direction` with p.side_by_side_same_direction_cos), and at
        least two of the three pairs have a body gap (`rel_surface_gap`, the distance) at most
        p.abreast_gap_max.
        "At least two of three" is written `gap(s,b) ∧ (gap(s,c) ∨ gap(b,c))`: the quantifiers
        range over ordered pairs (b, c), and the record's third case, gap(s,c) ∧ gap(b,c), is
        this formula with b and c exchanged (the body gap is symmetric), so the formula is the
        record's condition exactly, without repeating a disjunct.

  No choice beyond the record's own narrowings was needed: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_777_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pAbreastGapMax : Term := .param "p.abreast_gap_max"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pSideBySideSameDirectionCos : Term := .param "p.side_by_side_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1: a member of the bicycle, electric bicycle or electric scooter aggregate. -/
def isRider (x : Arg) : Formula :=
  .or (.atom "ru_aggregate" [x, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [x, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
         (.atom "ru_aggregate" [x, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- s1/s3 (agency reading): riding is moving, not at rest at the observation. -/
def moving (x : Arg) : Formula :=
  .not (.derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance])

/-- s3: the pair side by side, travelling the same way. -/
def sideBySide (x y : Arg) : Formula :=
  .and (.cmp (.measure "rel_longitudinal_overlap" [x, y]) .ge zeroMetres)
       (.atom "rel_same_direction" [x, y] [pSideBySideSameDirectionCos])

/-- s3: the pair's body gap within the spacing of riders in one row. -/
def inRow (x y : Arg) : Formula :=
  .cmp (.measure "rel_surface_gap" [x, y]) .le pAbreastGapMax

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula := isRider vSubject

/-- Applicability: s2 (condition): upon a roadway; s4 (exception): except on paths or parts of roadways set aside for the exclusive use of bicycles, electric bicycles and electric scooters. -/
def applicability : Formula :=
  .and (moving vSubject)
    (.and (.existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, .var "rw"] []))
          (.not (.existsRegion (.lit "bicycle_lane_or_path") "bl"
                  (.atom "rel_occupies" [vSubject, .var "bl"] []))))

/-- Obligation: s3 (obligation): shall not ride more than two abreast -/
def obligation : Formula :=
  let b : Arg := .var "b"
  let c : Arg := .var "c"
  .not (.existsUser "b" (.existsUser "c"
    (.and (.not (.same b vSubject))
    (.and (.not (.same c vSubject))
    (.and (.not (.same b c))
    (.and (isRider b)
    (.and (isRider c)
    (.and (moving b)
    (.and (moving c)
    (.and (sideBySide vSubject b)
    (.and (sideBySide vSubject c)
    (.and (sideBySide b c)
          (.and (inRow vSubject b) (.or (inRow vSubject c) (inRow b c)))))))))))))))

def rule : Rule :=
  { id := "NRS_484B_777_3"
    laws := ["NRS-484B-777-3"]
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

end TrafficSpec.Rules.NRS_484B_777_3
