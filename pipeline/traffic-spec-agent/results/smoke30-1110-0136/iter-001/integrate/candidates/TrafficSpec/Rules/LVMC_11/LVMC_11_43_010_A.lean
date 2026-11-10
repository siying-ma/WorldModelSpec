/-
  LVMC_11_43_010_A — LVMC-11-43-010-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): The following regulations pertain to the
    s2 (subject): operation of vehicles
    s3 (condition): within a roundabout
    s4 (trigger): All vehicular travel
    s5 (obligation): shall be in a counterclockwise direction

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.roundabout', 'rel.occupies'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.moving']
    s5: atoms [], derived ['drv.motion.clockwise_about_region']

  How each is written:
    s2, s4 ('vehicular'): the class of x, `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    s4 ('travel'): `drv_motion_moving x` at the speed resolution, in the applicability.
    s3: some region of kind `roundabout` (st.roundabout; the quantifier also covers any kind that
        refines it) whose area x's footprint overlaps (`rel_occupies x r`), in the applicability.
    s5: for every roundabout region x occupies — the applicability's whole selection written again,
        so each roundabout x is within is the one judged — x does not move clockwise about its
        reference point (`not drv_motion_clockwise_about_region x r` at the speed resolution).

  No choice beyond the record's: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_43_010_A

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The roundabout variable, bound in each formula by its own quantifier. -/
def vR : Arg := .var "r"

/-- s3: x's footprint overlaps the roundabout region `r`. -/
def withinRoundabout : Formula := .atom "rel_occupies" [vX, vR] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s3 (condition): within a roundabout; s4 (trigger): All vehicular travel -/
def applicability : Formula :=
  .and (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
    (.existsRegion (.lit "roundabout") "r" withinRoundabout)

/-- Obligation: s5 (obligation): shall be in a counterclockwise direction -/
def obligation : Formula :=
  .forallRegion (.lit "roundabout") "r"
    (.implies withinRoundabout
      (.not (.derived "drv_motion_clockwise_about_region" [vX, vR] [pMotionSpeedTolerance])))

def rule : Rule :=
  { id := "LVMC_11_43_010_A"
    laws := ["LVMC-11-43-010-A"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_43_010_A
