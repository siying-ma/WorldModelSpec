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

  Literals the text states (each written through its Units constructor):
    s6: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s2: the binder class and the applicability are the disjunction of the three aggregates.
    s3: for every lane L (forallRegion over "lane", anchored by rel_occupies of the subject) and
        every road user v other than the subject of the vehicle aggregate occupying L with
        rel_longitudinal_overlap(subject, v) >= 0 m, the pair must be excused; judged at every
        observation (the evaluator judges each instant).
    s4: subject and v each of the motorcycle or the moped aggregate.
    s5: rel_same_direction(subject, v) with p.side_by_side_same_direction_cos.
    s6: the count of road users w that are the subject, or are of the vehicle aggregate, occupy L
        and overlap the subject longitudinally at or above zero, is at most the literal two — the
        record's "no third road user beside the pair" stated with the text's figure.
    s1: residue (the node's).
  No reading of mine beyond the record's: `narrowings` stays empty.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_486_351_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSideBySideSameDirectionCos : Term := .param "p.side_by_side_same_direction_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- s6: the text's figure "two" (count). -/
def twoAbreast : Term := .lit (Q.ofInt 2) .count

def vV : Arg := .var "v"
def vW : Arg := .var "w"
def vL : Arg := .var "L"

def agg (x : Arg) (id : String) : Formula := .atom "ru_aggregate" [x, .lit id] []

def isMotorcycle (x : Arg) : Formula := agg x "DEF-NRS-486-041::motorcycle"
def isMoped (x : Arg) : Formula := agg x "DEF-NRS-486-038::moped"
def isTrimobile (x : Arg) : Formula := agg x "DEF-NRS-486-057::trimobile"
def isVehicle (x : Arg) : Formula := agg x "DEF-NRS-484A-320::vehicle"

def occupies (x : Arg) : Formula := .atom "rel_occupies" [x, vL] []

/-- Side by side with the subject: rel.longitudinal_overlap at or above zero. -/
def abreastOfSubject (x : Arg) : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [vSubject, x]) .ge zeroMetres

/-- Class of `subject` (s2): ru.aggregate=DEF-NRS-486-041::motorcycle, ru.aggregate=DEF-NRS-486-038::moped, ru.aggregate=DEF-NRS-486-057::trimobile -/
def clsSubject : Formula :=
  .or (isMotorcycle vSubject) (.or (isMoped vSubject) (isTrimobile vSubject))

/-- Applicability: the record's — the subject is of the motorcycle, moped or trimobile aggregate.
    The exceptions s4-s6 excuse a pair, so they are written in the obligation, per pair. -/
def applicability : Formula := clsSubject

/-- s4: the subject and v are each a motorcycle or a moped. -/
def motorcycleOrMoped (x : Arg) : Formula := .or (isMotorcycle x) (isMoped x)

/-- s6: the road users of lane L side by side with the subject, the subject itself counted, number
    no more than two (each one beside it is of the vehicle aggregate and occupies L). -/
def noMoreThanTwoAbreast : Formula :=
  .cmp
    (.aggregate .count "w"
      (.or (.same vW vSubject)
        (.and (isVehicle vW) (.and (occupies vW) (abreastOfSubject vW))))
      (.lit Q.zero .count))
    .le twoAbreast

/-- s4-s6: the pair is excused. -/
def excused : Formula :=
  .and (motorcycleOrMoped vSubject)
    (.and (motorcycleOrMoped vV)
      (.and (.atom "rel_same_direction" [vSubject, vV] [pSideBySideSameDirectionCos])
        noMoreThanTwoAbreast))

/-- Obligation (s3): at every observation, for every lane L and every other vehicle v, both in L
    and abreast of the subject, the pair is excused (s4-s6). -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "L"
    (.forallUser "v"
      (.implies
        (.and (.not (.same vV vSubject))
          (.and (isVehicle vV)
            (.and (occupies vSubject)
              (.and (occupies vV) (abreastOfSubject vV)))))
        excused))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_486_351_2
