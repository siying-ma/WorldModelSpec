/-
  drv.motion.decelerating — Road user a is decelerating at an observation: its forward speed is falling. Measured as its acceleration along its heading (kin.accel_longitudinal, m/s², signed) at or below the negative of the deceleration tolerance, the magnitude below which a sampled acceleration counts as none, while a is not backing (drv.motion.backing with the speed tolerance does not hold), since for a backing road user a negative value is a gain of speed. Not a stand-in for its speed or for the brake lamp: a lit lamp without a deceleration is no deceleration.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its acceleration along its heading (kin.accel_longitudinal, m/s², signed): atoms ['kin.accel_longitudinal'], concepts []
    while a is not backing (drv.motion.backing with the speed tolerance does not hold): atoms [], concepts ['drv.motion.backing']

  Written as: kin_accel_longitudinal a ≤ −decel_tolerance ∧ ¬ drv_motion_backing a speed_tolerance.
  "At or below" is a non-strict comparison, as the words say; the speed tolerance fills backing's
  motion tolerance. No reading was left open, so no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.decelerating

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pDecelTolerance : Term := .param "decel_tolerance"
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- `a`'s acceleration along its heading (m/s², signed). -/
def accelAlongHeading : Term := .measure "kin_accel_longitudinal" [aA]

/-- Decelerating: that acceleration at or below the negative of the deceleration tolerance, while
    `a` is not backing at the speed tolerance. The brake lamp and the speed are not read. -/
def body : Formula :=
  .and (.cmp accelAlongHeading .le (.neg pDecelTolerance))
       (.not (.derived "drv_motion_backing" [aA] [pSpeedTolerance]))

def concept : Concept :=
  { id := "drv.motion.decelerating"
    contract := "Road user a is decelerating at an observation: its forward speed is falling. Measured as its acceleration along its heading (kin.accel_longitudinal, m/s², signed) at or below the negative of the deceleration tolerance, the magnitude below which a sampled acceleration counts as none, while a is not backing (drv.motion.backing with the speed tolerance does not hold), since for a backing road user a negative value is a gain of speed. Not a stand-in for its speed or for the brake lamp: a lit lamp without a deceleration is no deceleration."
    definition := none
    args := [("a", .track)]
    params := [⟨"decel_tolerance", .metrePerSecondSq⟩, ⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.decelerating
