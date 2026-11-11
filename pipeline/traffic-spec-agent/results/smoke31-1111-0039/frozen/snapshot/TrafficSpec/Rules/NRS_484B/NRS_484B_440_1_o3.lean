/-
  NRS_484B_440_1_o3 — NRS-484B-440-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (trigger): Upon any highway
    g2 (condition): outside of a business or residence district
    g3 (sibling): no person shall stop, park or leave standing
    g4 (subject): any vehicle, whether attended or unattended,
    g5 (trigger): upon the paved or main-traveled part of the highway
    g6 (sibling): when it is practicable to stop, park or so leave such vehicle off such part of the highway,
    g7 (boilerplate): but in every event
    g8 (sibling): an unobstructed width of the highway
    g9 (sibling): opposite a standing vehicle
    g10 (sibling): shall be left for the free passage of other vehicles
    g11 (boilerplate): and
    g12 (obligation): a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway.
    g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position.

  Elements (span → atoms, derived):
    g1: atoms ['rel.occupies', 'st.highway'], derived []
    g4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    g5: atoms ['rel.occupies', 'st.roadway'], derived []
    g12: atoms ['st.sight_distance', 'kin.speed'], derived ['drv.motion.halted']
    g13: atoms ['kin.engine_running', 'sig.hazard', 'rel.occupies', 'st.roadway'], derived []

  How each is written:
    g4: the class of x, `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    g1: some region of kind `highway` that x occupies (`existsRegion "highway"`, `rel_occupies`).
    g5: some region of kind `roadway` that x occupies (`existsRegion "roadway"`, `rel_occupies`).
    g2: the declared assumption does not hold (`not (asm …)`).
    g12 (stopped vehicle): x halted, `drv_motion_halted x p.speed_resolution` (kin.speed through the
      concept), in the applicability, as the record's applicability states.
    g13: not (engine not running, hazard lamps on, and x occupying some roadway).
    g12 (obligation): at every roadway x occupies on a highway it occupies (the applicability's
      selection written again), the roadway's st.sight_distance is at least 200 ft.

  Choices the record left open:
    g12: "the sight distance at x's place" is read off the roadway regions x occupies (the place
      the applicability selects), and is required at each of them where x straddles several.

  Literals the text states (each written through its Units constructor):
    g12: 200 ft — 200 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_440_1_o3

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- g12: the text's 200 feet. -/
def clearViewDistance : Term := .lit (Units.feet 200) .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- g1: x is upon a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vX, .var "h"] [])

/-- g5: x is upon the roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vX, .var "r"] [])

/-- g12: x is stopped. -/
def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]

/-- g13: x disabled on the roadway, read through engine off and hazard lamps on. -/
def disabledOnRoadway : Formula :=
  .and (.not (.atom "kin_engine_running" [vX] []))
    (.and (.atom "sig_hazard" [vX] [])
      (.existsRegion (.lit "roadway") "rd" (.atom "rel_occupies" [vX, .var "rd"] [])))

/-- Applicability: g1 (trigger): Upon any highway; g2 (condition): outside of a business or residence district; g5 (trigger): upon the paved or main-traveled part of the highway; g13 (exception): This section shall not apply to the driver of any vehicle which is disabled while on the paved or main-traveled portion of a highway in such manner and to such extent that it is impossible to avoid stopping and temporarily leaving such disabled vehicle in such position. -/
def applicability : Formula :=
  .and halted
    (.and onHighway
      (.and onRoadway
        (.and (.not (.asm "asm.within_business_or_residence_district"))
          (.not disabledOnRoadway))))

/-- Obligation: g12 (obligation): a clear view of such stopped vehicles shall be available from a distance of 200 feet in each direction upon such highway. -/
def obligation : Formula :=
  .forallRegion (.lit "roadway") "r"
    (.implies (.and (.atom "rel_occupies" [vX, .var "r"] []) onHighway)
      (.cmp (.measure "st_sight_distance" [.var "r"]) .ge clearViewDistance))

def rule : Rule :=
  { id := "NRS_484B_440_1_o3"
    laws := ["NRS-484B-440-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_business_or_residence_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "g12"
          why := "The sight distance at x's place is read off the roadway regions x occupies, and is required at each of them where x straddles several."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_440_1_o3
