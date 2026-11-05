/-
  drv.interaction.passing_vehicle_ahead — At this observation the first road user is going by the second: their headings are aligned within the alignment tolerance, the first road user's speed exceeds the second's by more than the closing tolerance, their bodies overlap along the first road user's heading (the length their projections on that axis share is positive), and at the last observation in the window behind at which the two were in one line of travel the second was ahead of the first. The window is the time within which one body draws level with another it was behind; the alignment tolerance is the cosine of the largest angle between the headings still read as travel in one direction, and the closing tolerance is the speed difference below which a reading counts as no gain; all three are the concept's own magnitudes, since headings, speeds and overlaps are observed over sampled measurements only within bounds the caller sets. The concept denotes the act of going by only: it is not the lane or the side used, not a return to the lane, not a signal, not the completion of the manoeuvre, and not its lawfulness.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    at the last observation in the window behind at which the two were in one line of travel the second was ahead of the first: atoms ['rel.ahead_behind_in_lane'], concepts []
      written `.atLast .time pass_window "u" inOneLineOfTravel secondAhead`: `atLast` is the
      operator for 'at the last observation in the window behind at which ψ held, φ', so ψ is
      'the two were in one line of travel' and φ 'the second was ahead of the first'. Both are
      read with the one atom the element claims, rel.ahead_behind_in_lane, which is 'a is ahead
      of / behind b in the same lane, along the lane direction': φ is that atom of the second
      over the first (`[v, u]`, the second ahead of the first), and ψ is the disjunction of its
      two directions (`[u, v]` or `[v, u]`) — one of the two is ahead of the other in the same
      lane, which is what the atom says of a pair in one line of travel. The window is measured
      in time, `pass_window` being a time (s). No lane and no side is read as a region: the
      contract excludes the lane used.
    their bodies overlap along the first road user's heading (the length their projections on that axis share is positive): atoms ['rel.longitudinal_overlap'], concepts []
      written `.cmp (rel_longitudinal_overlap u v) .gt 0 m`: the atom is 'the length the two
      footprints' projections on that axis share, negative for the gap between the projections',
      so the contract's parenthesis — that shared length being positive — is the atom read at
      this observation above zero. Zero is the only literal here, and the contract names it ('is
      positive'). The subject of the axis is the first road user, so the atom is read `[u, v]`.
    their headings are aligned within the alignment tolerance: atoms ['rel.same_direction'], concepts []
      written `.atom "rel_same_direction" [u, v] [alignment_tolerance]`: the atom is 'headings
      aligned: the cosine of the angle between the headings is above its tolerance', and that
      tolerance is the atom's own parameter, filled with the concept's `alignment_tolerance`;
      nothing further is compared.
    the first road user's speed exceeds the second's by more than the closing tolerance: atoms ['kin.speed'], concepts []
      written `.cmp (kin_speed u - kin_speed v) .gt closing_speed_tolerance`: kin.speed is the
      'magnitude of velocity' of each body, their difference compared with the closing tolerance.

  Narrowings (choices the contract left open):
    "at which the two were in one line of travel" — read as the disjunction of the two directions
      of rel.ahead_behind_in_lane: one of the pair is ahead of the other in the same lane. The
      atom carries lane membership along the lane direction, so this is its reading of being in
      one line of travel; the window behind includes this observation, which `atLast` reads, so a
      pair still in one line of travel here is read here.
    "exceeds … by more than the closing tolerance" — read strictly (`.gt`) on the difference of
      the two speeds: the tolerance is 'the speed difference below which a reading counts as no
      gain', so a difference exactly at it stays on the side of no gain.
    "the length their projections on that axis share is positive" — read strictly above zero
      (`.gt`), as 'positive' says; a shared length of zero is bodies exactly meeting end to end,
      not drawing level.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.passing_vehicle_ahead

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aV : Arg := .var "v"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pPassWindow : Term := .param "pass_window"
def pAlignmentTolerance : Term := .param "alignment_tolerance"
def pClosingSpeedTolerance : Term := .param "closing_speed_tolerance"

/-- The headings are aligned within the alignment tolerance: the cosine of the angle between them
    is above the tolerance, which the atom takes as its own parameter. -/
def headingsAligned : Formula := .atom "rel_same_direction" [aU, aV] [pAlignmentTolerance]

/-- The first road user is gaining: its speed exceeds the second's by more than the closing
    tolerance. -/
def gainingOnTheSecond : Formula :=
  .cmp (.sub (.measure "kin_speed" [aU]) (.measure "kin_speed" [aV])) .gt pClosingSpeedTolerance

/-- The bodies overlap along the first road user's heading: the length their footprints'
    projections on that axis share is positive. -/
def bodiesDrawLevel : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aU, aV]) .gt (.lit Q.zero .metre)

/-- The two are in one line of travel: one of them is ahead of the other in the same lane, along
    the lane direction. -/
def inOneLineOfTravel : Formula :=
  .or (.atom "rel_ahead_behind_in_lane" [aU, aV] [])
      (.atom "rel_ahead_behind_in_lane" [aV, aU] [])

/-- The second road user is ahead of the first in the same lane, along the lane direction. -/
def secondAheadOfFirst : Formula := .atom "rel_ahead_behind_in_lane" [aV, aU] []

/-- At the last observation in the window behind at which the two were in one line of travel, the
    second was ahead of the first: the first came from behind. -/
def cameFromBehind : Formula :=
  .atLast .time pPassWindow "u" inOneLineOfTravel secondAheadOfFirst

/-- The first road user is going by the second here: their headings are aligned, the first is
    gaining on the second by more than the closing tolerance, their bodies overlap along the
    first's heading, and at the last observation of the window behind at which the two were in one
    line of travel the second was ahead of the first. -/
def body : Formula :=
  .and (.and headingsAligned gainingOnTheSecond) (.and bodiesDrawLevel cameFromBehind)

def concept : Concept :=
  { id := "drv.interaction.passing_vehicle_ahead"
    contract := "At this observation the first road user is going by the second: their headings are aligned within the alignment tolerance, the first road user's speed exceeds the second's by more than the closing tolerance, their bodies overlap along the first road user's heading (the length their projections on that axis share is positive), and at the last observation in the window behind at which the two were in one line of travel the second was ahead of the first. The window is the time within which one body draws level with another it was behind; the alignment tolerance is the cosine of the largest angle between the headings still read as travel in one direction, and the closing tolerance is the speed difference below which a reading counts as no gain; all three are the concept's own magnitudes, since headings, speeds and overlaps are observed over sampled measurements only within bounds the caller sets. The concept denotes the act of going by only: it is not the lane or the side used, not a return to the lane, not a signal, not the completion of the manoeuvre, and not its lawfulness."
    definition := none
    args := [("u", .track), ("v", .track)]
    params := [⟨"pass_window", .second⟩, ⟨"alignment_tolerance", .ratio⟩, ⟨"closing_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "at the last observation in the window behind at which the two were in one line of travel"
          why := "'In one line of travel' is read with the one atom the element claims, rel.ahead_behind_in_lane ('a is ahead of / behind b in the same lane, along the lane direction'), taken in both directions and disjoined: the two are in one line of travel at an observation when one of them is ahead of the other in the same lane. The window behind is measured in time, `pass_window` being a time, and includes this observation, which is what `atLast` reads over the window behind: a pair still in one line of travel here is read here, and a pair that has parted lanes is read at the last observation at which it was not."
          kind := "reading" }
      , { span := "the first road user's speed exceeds the second's by more than the closing tolerance"
          why := "Read strictly (`.gt`) on the difference of the two speeds. The parameter is 'the speed difference below which the first road user is not read as gaining on the second', so a difference exactly at the tolerance stays on the side of no gain; only a difference strictly above it is read as gaining."
          kind := "reading" }
      , { span := "the length their projections on that axis share is positive"
          why := "Read strictly above zero (`.gt (.lit Q.zero .metre)`), as 'positive' says. The atom is negative for the gap between the projections, so zero is the bodies exactly meeting end to end along the axis, which shares no length and is not drawing level."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.passing_vehicle_ahead
