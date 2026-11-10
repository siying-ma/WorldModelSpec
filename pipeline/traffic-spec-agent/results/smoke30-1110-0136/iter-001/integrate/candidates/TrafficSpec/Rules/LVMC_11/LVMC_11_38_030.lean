/-
  LVMC_11_38_030 — LVMC-11-38-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): No motorcycle
    s2 (subject): or motor scooter
    s3 (obligation): shall be ridden upon any sidewalk
    s4 (condition): of the City

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle'], derived []
    s2: atoms ['ru.moped', 'ru.electric_scooter'], derived []
    s3: atoms ['st.sidewalk', 'rel.occupies'], derived ['drv.motion.moving']

  How each span is written:
    s1, s2: the class of `x` is the disjunction of the aggregate membership
      `ru_aggregate x "DEF-NRS-484A-135::motorcycle"` (the id, not the classes it covers),
      `ru_moped x` and `ru_electric_scooter x`.
    s4: the assumption `asm.within_city_limits` is the applicability.
    s3: the duty's negation ("No … shall be ridden upon any sidewalk") is
      `not (moving x ∧ ∃ sidewalk s. st_sidewalk s ∧ rel_occupies x s)`: at the observation,
      x is not in motion (drv.motion.moving with p.motion_speed_tolerance) while its footprint
      overlaps any sidewalk region. The region is anchored to x by rel_occupies; the kind is
      written as named, with no exclusion the record does not state. 'ridden' read through
      motion is the record's own observable reading and is not restated as a narrowing.

  No choice beyond the record's was made: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_38_030

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1: a member of the motorcycle aggregate of DEF-NRS-484A-135. -/
def isMotorcycle : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-135::motorcycle"] []

/-- s2: a motor scooter, read as a moped or an electric scooter. -/
def isMotorScooter : Formula :=
  .or (.atom "ru_moped" [vX] []) (.atom "ru_electric_scooter" [vX] [])

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.moped, ru.electric_scooter -/
def clsX : Formula := .or isMotorcycle isMotorScooter

/-- Applicability: s4 (condition): of the City -/
def applicability : Formula := .asm "asm.within_city_limits"

/-- s3 'ridden': x in motion beyond the speed resolution. -/
def ridden : Formula := .derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]

/-- s3 'upon any sidewalk': x's footprint overlaps some sidewalk region of the scene. -/
def uponSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "s"
    (.and (.atom "st_sidewalk" [.var "s"] []) (.atom "rel_occupies" [vX, .var "s"] []))

/-- Obligation: s3 (obligation): shall be ridden upon any sidewalk -/
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
