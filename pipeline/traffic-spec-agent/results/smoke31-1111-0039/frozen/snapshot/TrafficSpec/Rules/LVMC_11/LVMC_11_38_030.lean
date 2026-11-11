/-
  LVMC_11_38_030 — LVMC-11-38-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): No motorcycle or motor scooter
    s2 (obligation): shall be ridden upon any sidewalk
    s3 (condition): of the City

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.moped', 'ru.electric_scooter'], derived []
    s2: atoms ['st.sidewalk', 'rel.occupies'], derived ['drv.motion.moving']

  How each span is written:
    s1: the class of x is the disjunction of the aggregate atom (ru_aggregate with the id
        DEF-NRS-484A-135::motorcycle as its literal), ru_moped and ru_electric_scooter.
    s3: the applicability is the declared assumption asm.within_city_limits.
    s2: the obligation forbids, at the observation, x being both in motion
        (drv_motion_moving with speed_floor p.speed_resolution — the record's agency reading of
        'be ridden') and occupying some region of kind sidewalk (st_sidewalk ∧ rel_occupies); 'any'
        is the existential over every sidewalk region of the scene, anchored to x by rel_occupies.
  No choice beyond the record's was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_38_030

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.moped, ru.electric_scooter -/
def clsX : Formula :=
  .or (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-135::motorcycle"] [])
    (.or (.atom "ru_moped" [vX] []) (.atom "ru_electric_scooter" [vX] []))

/-- Applicability: s3 (condition): of the City -/
def applicability : Formula := .asm "asm.within_city_limits"

/-- s2, 'ridden': x in motion above the source's speed resolution (the record's agency reading). -/
def ridden : Formula := .derived "drv_motion_moving" [vX] [pSpeedResolution]

/-- s2, 'upon any sidewalk': x's footprint overlaps some sidewalk region. -/
def uponSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "w"
    (.and (.atom "st_sidewalk" [.var "w"] []) (.atom "rel_occupies" [vX, .var "w"] []))

/-- Obligation: s2 (obligation): shall be ridden upon any sidewalk -/
def obligation : Formula := .not (.and ridden uponSidewalk)

def rule : Rule :=
  { id := "LVMC_11_38_030"
    laws := ["LVMC-11-38-030"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_city_limits"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_38_030
