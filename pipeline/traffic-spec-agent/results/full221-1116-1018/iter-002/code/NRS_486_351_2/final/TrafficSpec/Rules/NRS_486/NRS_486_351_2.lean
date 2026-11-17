/-
  NRS_486_351_2 — NRS-486-351-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (exception): Except as provided in subsection 3,
    s2 (subject): a person shall not drive a motorcycle, moped or trimobile
    s3 (obligation): abreast of or overtake or pass another vehicle within the same traffic lane.
    s4 (exception): Motorcycles and mopeds may,
    s5 (exception): with the consent of the drivers,
    s6 (exception): be operated no more than two abreast in a single traffic lane.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-486-041::motorcycle', 'ru.aggregate=DEF-NRS-486-038::moped', 'ru.aggregate=DEF-NRS-486-057::trimobile'], derived []
    s3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane', 'rel.longitudinal_overlap'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-486-041::motorcycle', 'ru.aggregate=DEF-NRS-486-038::moped'], derived []
    s5: atoms ['rel.same_direction'], derived []
    s6: atoms ['rel.occupies', 'st.lane', 'rel.longitudinal_overlap'], derived []

  How each span is written:
    s2: the binder class and the applicability are the disjunction of the three admitted
        aggregates on the subject (the record's applicability, restated).
    s3: for every road user v (not the subject) of DEF-NRS-484A-320::vehicle and every region L of
        kind lane that both the subject and v occupy, with rel.longitudinal_overlap(subject, v) ≥ 0,
        the pair must be excused (s4-s6); the record's own reading judges overtake/pass at the
        observations at which the two are side by side in the lane.
    s4: the subject and v are each of the motorcycle or the moped aggregate.
    s5: rel.same_direction(subject, v) with tolerance p.side_by_side_same_direction_cos (the record's
        observable reading of consent).
    s6: "no more than two abreast": the count of road users w that are the subject, or are of the
        vehicle aggregate, occupy the same L and have rel.longitudinal_overlap(subject, w) ≥ 0, is at
        most two (the text's literal, a count). Counting the subject by `same` and v by the
        condition it already meets is the record's "no third road user w other than the subject
        and v", stated with the literal the text gives.
    s1: a residue (the node's).

  Literals the text states (each written through its Units constructor):
    s6: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_486_351_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
def vOther : Arg := .var "v"
def vThird : Arg := .var "w"
def vLane : Arg := .var "L"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSideBySideSameDirectionCos : Term := .param "p.side_by_side_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- s6: the text's "two", a count. -/
def twoAbreast : Term := .lit (Units.ratio 2 1) .count

def motorcycle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-486-041::motorcycle"] []
def moped (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-486-038::moped"] []
def trimobile (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-486-057::trimobile"] []
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
def occupies (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
def abreast (a b : Arg) : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [a, b]) .ge zeroMetres

/-- Class of `subject`: ru.aggregate=DEF-NRS-486-041::motorcycle, ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-057::trimobile -/
def clsSubject : Formula :=
  .or (motorcycle vSubject) (.or (moped vSubject) (trimobile vSubject))

/-- Applicability: the record's — the subject is of one of the three aggregates (s2). The
    exceptions s4-s6 excuse a pair inside the obligation; s1 is a residue. -/
def applicability : Formula :=
  .or (motorcycle vSubject) (.or (moped vSubject) (trimobile vSubject))

/-- s3: v is another vehicle in the lane L the subject occupies, side by side with it. -/
def abreastInLane : Formula :=
  .and (.not (.same vSubject vOther))
    (.and (vehicle vOther)
      (.and (occupies vSubject vLane)
        (.and (occupies vOther vLane) (abreast vSubject vOther))))

/-- s6: no more than two abreast in L (the subject, v, and no third). -/
def noMoreThanTwo : Formula :=
  .cmp
    (.aggregate .count "w"
      (.or (.same vSubject vThird)
        (.and (vehicle vThird) (.and (occupies vThird vLane) (abreast vSubject vThird))))
      (.lit Q.zero .count))
    .le twoAbreast

/-- s4-s6: the pair is excused. -/
def excused : Formula :=
  .and (.or (motorcycle vSubject) (moped vSubject))
    (.and (.or (motorcycle vOther) (moped vOther))
      (.and (.atom "rel_same_direction" [vSubject, vOther] [pSideBySideSameDirectionCos])
        noMoreThanTwo))

/-- Obligation: s3 (obligation): abreast of or overtake or pass another vehicle within the same traffic lane. -/
def obligation : Formula :=
  .forallUser "v"
    (.forallRegion (.lit "lane") "L"
      (.implies abreastInLane excused))

def rule : Rule :=
  { id := "NRS_486_351_2"
    laws := ["NRS-486-351-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["Points to subsection 3, whose words are this line's second sentence and are carried by s4-s6; the duty is the same whether the pointer is read or not."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_486_351_2
