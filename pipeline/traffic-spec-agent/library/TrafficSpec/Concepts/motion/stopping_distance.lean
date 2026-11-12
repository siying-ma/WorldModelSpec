/-
  drv.motion.stopping_distance — The distance road user a would travel before coming to rest if it began to brake after a reaction time, at the observation: its speed (kin.speed, m/s) times the reaction time, plus the square of its speed divided by twice the deceleration (m). Computed from the current speed only, under a constant deceleration on a level road. Not a stand-in for a sight distance or a gap to another road user, which a caller compares it with, nor for a braking manoeuvre actually made.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed (kin.speed, m/s): atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — the factor of the braking distance: the square of the speed divided by twice the deceleration

  No magnitude below is this file's own: parameters are formals the caller fills.

  Written: kin_speed(a) · reaction_time + kin_speed(a)² / (2 · deceleration). The contract
  dictates every term; no reading was chosen, so there are no narrowings.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopping_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReactionTime : Term := .param "reaction_time"
def pDeceleration : Term := .param "deceleration"

/-- "its speed (kin.speed, m/s)": the magnitude of a's velocity at the observation. -/
def speed : Term := .measure "kin_speed" [aA]

/-- The declared factor 2 of the braking distance. -/
def two : Term := .lit (Units.ratio 2 1) .count

/-- Speed times the reaction time, plus the square of the speed over twice the deceleration. The
    divisor is the deceleration parameter only, never a measured atom. -/
def body : Term :=
  .add (.mul speed pReactionTime)
       (.div (.mul speed speed) (.mul two pDeceleration))

def concept : Concept :=
  { id := "drv.motion.stopping_distance"
    contract := "The distance road user a would travel before coming to rest if it began to brake after a reaction time, at the observation: its speed (kin.speed, m/s) times the reaction time, plus the square of its speed divided by twice the deceleration (m). Computed from the current speed only, under a constant deceleration on a level road. Not a stand-in for a sight distance or a gap to another road user, which a caller compares it with, nor for a braking manoeuvre actually made."
    definition := none
    args := [("a", .track)]
    params := [⟨"reaction_time", .second⟩, ⟨"deceleration", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.stopping_distance
