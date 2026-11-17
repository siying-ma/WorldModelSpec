/-
  NRS_484B_633_2 — NRS-484B-633-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    y1 (subject): It is unlawful for any person to drive a vehicle
    y2 (trigger): over any bridge or other elevated structure constituting a part of a highway
    y3 (obligation): at a speed which is greater than the maximum speed which can be maintained with safety to the bridge or structure,
    y4 (condition): when such structure is signposted as provided in this section
    y5 (boilerplate): [(3) appended below].
    y6 (definitional): The Department of Transportation upon request from any local authority shall, or upon its own initiative may, conduct an investigation of any bridge or other elevated structure constituting a part of a highway constructed and maintained under the authority granted by chapter 408 of NRS,
    y7 (definitional): and if it thereupon finds that such structure cannot with safety to itself withstand vehicles traveling at the speed otherwise permissible under chapters 484A to 484E, inclusive, of NRS,
    y8 (definitional): the Department shall determine and declare the maximum speed of vehicles which such structure can safely withstand,
    y9 (definitional): and shall cause or permit suitable signs stating such maximum speed to be erected and maintained
    y10 (definitional): at a distance of 100 feet before each end of such structure.

  Elements (span → atoms, derived):
    y1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    y2: atoms ['rel.occupies', 'st.elevated_structure', 'st.highway', 'st.on_way'], derived []
    y3: atoms ['kin.speed', 'dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    y4: atoms ['dev.speed_limit_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    y9: atoms ['dev.speed_limit_sign', 'dev.governs'], derived []

  How each is written.
    y1: the subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    y2: `onStructure` — some elevated_structure region `e` the subject occupies, lying on
        (`st_on_way`) some highway region `h`.
    y4/y9: `signposted d` — speed limit sign `d` of kind structure_maximum governing a travel
        region `r` the subject occupies; the applicability asks for some such sign at the same
        observation as `onStructure` ("while on the structure").
    y3: re-binding every speed limit sign `d` and travel region `r` with the applicability's whole
        selection (kind structure_maximum, `r` occupied by the subject and governed by `d`, the
        subject on an elevated structure on a highway), the subject's speed is at or below the
        sign's stated value (`kin_speed ≤ dev_speed_limit_sign_value d`): "greater than" violates.
  No choice beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_633_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- y2: the subject occupies an elevated structure lying on a highway. -/
def onStructure : Formula :=
  .existsRegion (.lit "elevated_structure") "e"
    (.and (.atom "rel_occupies" [vSubject, .var "e"] [])
      (.existsRegion (.lit "highway") "h"
        (.atom "st_on_way" [.var "e", .var "h"] [])))

/-- Sign `d` is of kind structure_maximum. -/
def structureMaximum : Formula :=
  .atom "dev_speed_limit_sign_kind" [.var "d", .lit "structure_maximum"] []

/-- y4/y9: sign `d` governs travel region `r`, which the subject occupies. -/
def governsOccupied : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var "r"] [])
    (.atom "dev_governs" [.var "d", .var "r"] [])

/-- Applicability: y2 (trigger): over any bridge or other elevated structure constituting a part of a highway; y4 (condition): when such structure is signposted as provided in this section -/
def applicability : Formula :=
  .and onStructure
    (.existsDevice (.lit "speed_limit_sign") "d"
      (.and structureMaximum
        (.existsRegion (.lit "travel_region") "r" governsOccupied)))

/-- Obligation: y3 (obligation): at a speed which is greater than the maximum speed which can be maintained with safety to the bridge or structure, -/
def obligation : Formula :=
  .forallDevice (.lit "speed_limit_sign") "d"
    (.forallRegion (.lit "travel_region") "r"
      (.implies (.and onStructure (.and structureMaximum governsOccupied))
        (.cmp (.measure "kin_speed" [vSubject]) .le
          (.measure "dev_speed_limit_sign_value" [.var "d"]))))

def rule : Rule :=
  { id := "NRS_484B_633_2"
    laws := ["NRS-484B-633-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["The authority's investigation, on request or on its own initiative, of structures built under chapter 408 of NRS (outside the corpus) is the process behind the posting; the rule reads the posted sign as the evidence of it.", "The authority's finding that the structure cannot withstand the otherwise permissible speeds (chapters 484A to 484E, no node of the corpus) is the reason for the posting; the rule reads the posted maximum, not the finding.", "The authority's determination and declaration of the maximum speed is read through the value the posted sign states; the act of declaring is not observable.", "The sign's placement before each end of the structure is the authority's duty; the rule reads the sign's governance of the structure's travel regions, not its distance from the ends, so the placement is not checked."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_633_2
