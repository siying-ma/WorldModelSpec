/-
  NRS_484D_100_1 — NRS-484D-100-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): Every vehicle
    f2 (condition): upon a highway of this State,
    f3 (exception): subject to exceptions with respect to parked vehicles as stated in chapters 484A to 484E, inclusive, of NRS,
    f4 (obligation): must display lighted lamps and illuminating devices as respectively required in this chapter for different classes of vehicles:
    f5 (condition): (a) At any time from one-half hour after sunset to one-half hour before sunrise;
    f6 (condition): (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;
    f7 (condition): and (c) When directed by an official traffic control device.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['rel.occupies', 'st.highway'], derived []
    f3: atoms ['kin.engine_running'], derived ['drv.motion.stopped']
    f4: atoms ['sig.headlamp', 'sig.position_lamp'], derived []
    f5: atoms ['env.darkness'], derived []
    f6: atoms ['env.visibility'], derived []
    f7: atoms ['dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  Literals the text states (each written through its Units constructor):
    f5: 0.5 h — one-half hour
    f6: 1000 ft — 1,000 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    f1: the binder class, ru_aggregate x "DEF-NRS-484A-320::vehicle".
    f2: some region of kind highway that x occupies (rel_occupies).
    f3: the exception: not (drv_motion_stopped x tol ∧ ¬ kin_engine_running x), tol the reading's
        p.motion_speed_tolerance (the plan's observable reading of 'parked').
    f5: env_darkness; the one-half hour of the text is the atom's boundary, set by the reading, so
        the f5 literal enters no formula.
    f6: env_visibility < 1,000 ft (Units.feet 1000).
    f5/f6/f7 are alternatives ('at any time … ; at any other time … ; and when …'): a disjunction.
    f7: declared no_atom. The record maps it to dev.regulatory_sign, dev.governs, rel.occupies and
        st.travel_region and itself carries a gap: no code of dev.regulatory_sign (nor any kind of
        dev.zone_sign) is a direction to display lamps, so these atoms carry only the presence and
        reach of a device, not the direction the words name. The limb is left out of the formula
        and the plan's gap (dev.lamp_use_sign) is filed.
    f4: the obligation: sig_headlamp x low_beam ∨ sig_headlamp x high_beam, and sig_position_lamp x
        (the plan's reading on f4).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484D_100_1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- f6: the text's 1,000 feet, the distance at which persons and vehicles must be discernible. -/
def discernibleDistance : Term := .lit (Units.feet 1000) .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- f2: x's footprint overlaps a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vX, .var "h"] [])

/-- f5: darkness, its boundary at the f5 literal set by the reading on the atom. -/
def darkTime : Formula := .atom "env_darkness" [] []

/-- f6: visibility distance below 1,000 feet. -/
def poorVisibility : Formula :=
  .cmp (.measure "env_visibility" []) .lt discernibleDistance

/-- f3: parked, read as halted with the engine not running. -/
def parked : Formula :=
  .and (.derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance])
       (.not (.atom "kin_engine_running" [vX] []))

/-- Applicability: f2 (condition): upon a highway of this State,; f3 (exception): subject to exceptions with respect to parked vehicles as stated in chapters 484A to 484E, inclusive, of NRS,; f5 (condition): (a) At any time from one-half hour after sunset to one-half hour before sunrise;; f6 (condition): (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;; f7 (condition): and (c) When directed by an official traffic control device.
    f7 is declared `no_atom` (see the header) and is not a disjunct. -/
def applicability : Formula :=
  .and onHighway (.and (.or darkTime poorVisibility) (.not parked))

/-- Obligation: f4 (obligation): must display lighted lamps and illuminating devices as respectively required in this chapter for different classes of vehicles: -/
def obligation : Formula :=
  .and (.or (.atom "sig_headlamp" [vX, .lit "low_beam"] [])
            (.atom "sig_headlamp" [vX, .lit "high_beam"] []))
       (.atom "sig_position_lamp" [vX] [])

def rule : Rule :=
  { id := "NRS_484D_100_1"
    laws := ["NRS-484D-100-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "f7"
          why := "'When directed by an official traffic control device' to display lighted lamps: no atom of the surface denotes such a direction. dev.regulatory_sign carries no code that directs lamps to be displayed (its codes are no_left_turn … no_trucks), dev.zone_sign no such kind, and dev.governs / rel.occupies / st.travel_region only locate a device; written with them the limb would be a device's presence, not its direction. The plan's gap (dev.lamp_use_sign) is the atom needed."
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484D_100_1
