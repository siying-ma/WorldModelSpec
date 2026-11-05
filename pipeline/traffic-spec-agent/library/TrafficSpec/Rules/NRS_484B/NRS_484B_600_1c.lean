/-
  NRS_484B_600_1c — NRS-484B-600-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (obligation): A rate of speed greater than that posted by a public authority for the particular portion of highway being traversed.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.highway'], derived []
    s2: atoms ['dev.governs', 'dev.speed_limit_sign', 'kin.speed', 'rel.occupies', 'st.highway', 'st.on_way', 'st.travel_region'], derived []

  How each span is written.

  s1 — the subject and the conduct. "a vehicle of any kind or character" is the binder's class:
  `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, the aggregate id itself and never the classes
  the run's reading counts under it. "any person to drive or operate" is read, as the record's
  narrowing on this span directs, through the vehicle's own controlled motion on the way: its
  presence there (`rel_occupies` on a `highway` region, with `st_highway` naming the kind of that
  region) and its rate of travel (`kin.speed`, which the obligation reads as the quantity the
  subparagraph compares). So the applicability is: some highway region whose boundary the subject's
  footprint overlaps. No speed threshold enters the applicability — a standing vehicle cannot
  exceed a positive posted maximum, and the record imposes none.

  s2 — the duty. For every highway region the subject occupies, every travel region the subject
  occupies that lies on that highway (`st_travel_region`, `rel_occupies`, `st_on_way`), and every
  speed-limit sign (`dev_speed_limit_sign`) the source records as governing that travel region
  (`dev_governs`) whose kind is `maximum` or `structure_maximum`
  (`dev_speed_limit_sign_kind`), the subject's speed (`kin_speed`) is at most the value the sign
  states (`dev_speed_limit_sign_value`), both in m/s. The highway is re-selected here with the whole
  selection the applicability made (kind and the subject's occupancy), since the region bound there
  is out of scope in this formula; each quantifier is universal, as the record's obligation states —
  exceeding any one such posting violates the duty, and the rule never picks the posting that
  favours the subject. "by a public authority" is the sign face on the road, the record's
  observable reading of that status. The `zone` kind is left out, as the record's narrowing states.

  Choices this session made (nothing the record left open changes what the formulas say, so
  `narrowings` is empty): the quantified kinds are also asserted as the atoms the element claims
  (`st_highway`, `st_travel_region`, `dev_speed_limit_sign`) beside the quantifier's own kind, so
  each claimed name is read where it speaks; and the comparison is written as "speed at most the
  posted value", the contradictory of the text's "greater than".

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The way being driven upon: a `highway` region the subject's own footprint overlaps. -/
def onHighway (way : String) : Formula :=
  .and (.atom "st_highway" [.var way] [])
       (.atom "rel_occupies" [vSubject, .var way] [])

/-- The particular portion being traversed: a travel region the subject's footprint overlaps that
    lies on the highway `way`. -/
def portionTraversed (portion way : String) : Formula :=
  .and (.atom "st_travel_region" [.var portion] [])
    (.and (.atom "rel_occupies" [vSubject, .var portion] [])
          (.atom "st_on_way" [.var portion, .var way] []))

/-- A maximum posted for that portion: a speed-limit sign of kind `maximum` or
    `structure_maximum` that the source records as governing `portion`. -/
def postedMaximumFor (sign portion : String) : Formula :=
  .and (.atom "dev_speed_limit_sign" [.var sign] [])
    (.and (.atom "dev_governs" [.var sign, .var portion] [])
          (.or (.atom "dev_speed_limit_sign_kind" [.var sign, .lit "maximum"] [])
               (.atom "dev_speed_limit_sign_kind" [.var sign, .lit "structure_maximum"] [])))

/-- The subject's rate of speed is not greater than the value the sign states (both m/s). -/
def withinPosted (sign : String) : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le (.measure "dev_speed_limit_sign_value" [.var sign])

/-- Applicability: s1 — a vehicle driven upon a highway, read as its footprint overlapping a
    highway region. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "way" (onHighway "way")

/-- Obligation: s2 (obligation): A rate of speed greater than that posted by a public authority for the particular portion of highway being traversed. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "way"
    (.implies (onHighway "way")
      (.forallRegion (.lit "travel_region") "portion"
        (.implies (portionTraversed "portion" "way")
          (.forallDevice (.lit "speed_limit_sign") "sign"
            (.implies (postedMaximumFor "sign" "portion") (withinPosted "sign"))))))

def rule : Rule :=
  { id := "NRS_484B_600_1c"
    laws := ["NRS-484B-600-1c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- the record's own narrowings are the plan's; this session chose no further reading
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1c
