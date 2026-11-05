/-
  drv.interaction.following_vehicle_ahead — At this observation the first road user travels behind the second in the same line of travel: the second is ahead of the first in the same lane along that lane's direction, the cosine of the angle between their two headings is above the alignment tolerance, and the first road user is in motion, its speed above the motion tolerance. The alignment tolerance is the cosine at or below which two headings are no longer read as travel in one and the same direction, and the motion tolerance is the speed at or below which a reading counts as no travel; both are the concept's own magnitudes, since headings and speeds are observed over sampled measurements only within bounds the caller sets. Each bound is one-sided and strict: the more nearly the headings agree, and the faster the first road user travels, the more plainly it follows, while a reading exactly at either bound lies outside it, on the side of headings not read as one direction and of no travel. The concept denotes the spatial relation of travelling behind only: it is not the size of the gap between the two bodies, not the adequacy of that gap, not a pass, not a tailgating judgement, and not the lawfulness of either road user's conduct.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the second is ahead of the first in the same lane along that lane's direction: atoms ['rel.ahead_behind_in_lane'], concepts []
      written `.atom "rel_ahead_behind_in_lane" [aV, aU] []`: the atom is exactly "a is ahead of /
      behind b in the same lane, along the lane direction", so the words "the second is ahead of
      the first" are the atom read with the second road user in the first argument position and the
      first in the second. The lane is the atom's own — it reads the lane the two share — so the
      concept quantifies over no region and takes none. No bearing (rel.bearing) and no centre
      distance stand in for it: a bearing in one body's frame is not membership of one lane, and
      the distance between centres is no order of arrival; neither is claimed.
    the cosine of the angle between their two headings is above the alignment tolerance: atoms ['rel.same_direction'], concepts []
      written `.atom "rel_same_direction" [aU, aV] [pAlignmentTolerance]`: the atom is "headings
      aligned: the cosine of the angle between the headings is above its tolerance, which is the
      cosine of the largest angle allowed, a ratio between -1 and 1" — it carries the comparison
      and its own tolerance parameter, and the comparison it fixes is strictly above, which is the
      one-sided strict bound the contract states (a reading exactly at the tolerance lies outside
      it). The concept's formal parameter `alignment_tolerance` is passed through unchanged, so the
      figure stays the caller's. rel.oncoming, the opposite relation, is not read.
    the first road user is in motion, its speed above the motion tolerance: atoms ['kin.speed'], concepts []
      written `.cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedTolerance`: kin.speed is the
      "magnitude of velocity" in m/s, read of the first road user alone — the contract bounds the
      travel of the first and says nothing of the second's speed — and compared strictly above the
      motion tolerance, so a standing road user behind another is not read as following. The
      comparison is `.gt`, not `.ge`: the contract states the bound as the speed "at or below which
      a reading counts as no travel". kin.gear is not read; its contract excludes it as a stand-in
      for the direction of motion.

  Narrowings (choices the contract did not dictate):
    "the second is ahead of the first in the same lane along that lane's direction" — written with
      the canonical atom name and the arguments in the order the atom's own contract fixes
      (`[v, u]`: v ahead of u), not with the directional alias read the other way about: the two
      denote the same relation, and the canonical name is the atom the record claims.
    "the cosine of the angle between their two headings is above the alignment tolerance" — read as
      the single atom with the formal parameter passed through, with no heading read and no cosine
      recomputed in this file: the atom already states this comparison, and the pair is written
      `[u, v]` (the cosine of the angle between two headings is symmetric in the two, so the order
      of the two road users does not change what the leaf decides).
    the three spans are conjoined, in the order the contract states them, and nothing else is
      required: no gap between the bodies, no adequacy of a gap, no pass, no tailgating judgement
      and no rule is read, each of which the contract excludes by name.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.following_vehicle_ahead

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aV : Arg := .var "v"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignmentTolerance : Term := .param "alignment_tolerance"
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- The second road user is ahead of the first in the same lane, along that lane's direction:
    rel.ahead_behind_in_lane read of the second against the first. Unknown where the source does
    not observe the order in the lane, or what either body occupies. -/
def secondIsAhead : Formula := .atom "rel_ahead_behind_in_lane" [aV, aU] []

/-- The cosine of the angle between the two headings is above the alignment tolerance: the atom
    carries the comparison, strictly above, and takes the tolerance the caller sets. Unknown where
    either heading is unobserved. -/
def headingsAligned : Formula := .atom "rel_same_direction" [aU, aV] [pAlignmentTolerance]

/-- The first road user is in motion: its speed stands strictly above the motion tolerance.
    Unknown where its speed is unobserved. -/
def firstInMotion : Formula :=
  .cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedTolerance

/-- The first road user travels behind the second in the same line of travel: the second is ahead
    of it in the same lane along that lane's direction, their headings are aligned within the
    alignment tolerance, and the first is in motion above the motion tolerance. -/
def body : Formula := .and secondIsAhead (.and headingsAligned firstInMotion)

def concept : Concept :=
  { id := "drv.interaction.following_vehicle_ahead"
    contract := "At this observation the first road user travels behind the second in the same line of travel: the second is ahead of the first in the same lane along that lane's direction, the cosine of the angle between their two headings is above the alignment tolerance, and the first road user is in motion, its speed above the motion tolerance. The alignment tolerance is the cosine at or below which two headings are no longer read as travel in one and the same direction, and the motion tolerance is the speed at or below which a reading counts as no travel; both are the concept's own magnitudes, since headings and speeds are observed over sampled measurements only within bounds the caller sets. Each bound is one-sided and strict: the more nearly the headings agree, and the faster the first road user travels, the more plainly it follows, while a reading exactly at either bound lies outside it, on the side of headings not read as one direction and of no travel. The concept denotes the spatial relation of travelling behind only: it is not the size of the gap between the two bodies, not the adequacy of that gap, not a pass, not a tailgating judgement, and not the lawfulness of either road user's conduct."
    definition := none
    args := [("u", .track), ("v", .track)]
    params := [⟨"alignment_tolerance", .ratio⟩, ⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the second is ahead of the first in the same lane along that lane's direction"
          why := "Written `.atom \"rel_ahead_behind_in_lane\" [aV, aU] []`: the atom's own contract is \"a is ahead of / behind b in the same lane, along the lane direction\", so the second road user takes the first argument position and the first road user the second, and the canonical atom name is used rather than the directional alias read the other way about (the two denote one relation, and the canonical name is the one the record claims). The lane is the atom's own, so the concept quantifies over no region and takes none; neither a bearing in one body's frame nor the distance between centres stands in for the order in the lane."
          kind := "reading" }
      , { span := "the cosine of the angle between their two headings is above the alignment tolerance"
          why := "Written as the single atom `.atom \"rel_same_direction\" [aU, aV] [pAlignmentTolerance]`, with no heading read and no cosine recomputed here: the atom already is \"headings aligned: the cosine of the angle between the headings is above its tolerance\", it fixes the comparison as strictly above (the one-sided strict bound the contract states), and the concept's formal parameter is passed through unchanged so the figure stays the caller's. The pair is written `[u, v]`; the cosine of the angle between two headings is symmetric in the two, so the order does not change what the leaf decides."
          kind := "reading" }
      , { span := "the first road user is in motion, its speed above the motion tolerance"
          why := "Written `.cmp (.measure \"kin_speed\" [aU]) .gt pMotionSpeedTolerance`: the speed read is the first road user's alone, since the contract bounds the travel of the first and says nothing of the second's, and the comparison is strict (`.gt`, not `.ge`), the tolerance being \"the speed at or below which a reading counts as no travel\". The three spans are conjoined in the order the contract states them and nothing further is required: no gap between the bodies, no adequacy of a gap, no pass and no tailgating judgement is read."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.following_vehicle_ahead
