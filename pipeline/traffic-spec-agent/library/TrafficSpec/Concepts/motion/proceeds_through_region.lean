/-
  drv.motion.proceeds_through_region — The road user is travelling across the region named by the region formal on an unchanged course: at the observation its footprint overlaps that region, it is in motion — its speed exceeds the motion floor — and the magnitude of its signed heading change over the recognition window behind the observation, in degrees measured in the world frame, is below the course-change threshold. The concept denotes travel across the region without a change of course, read at each observation at which the road user is moving within the region and its course over the window behind has held; a road user whose accumulated change of direction within the window reaches the threshold is not denoted, to whichever side it turns, one whose speed does not exceed the motion floor is not denoted however long it overlaps the region, and one whose window reaches past the start of the trace is unknown. Not a stand-in for: occupancy of the region alone, since a road user standing in it or turning within it also overlaps it; rest within the region, which the motion floor excludes, so that a road user halted, waiting or parked there is not denoted even though its course has not changed; entry into or departure from the region, which are the observations at which the overlap begins and ends; the region the road user will leave by or the way beyond it, which the concept does not read; a change of direction to either side, which is the opposite reading of the same signed quantity; or a declared intention to proceed.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps that region: atoms ['rel.occupies'], concepts []
      `rel_occupies u r`, on the region the region formal names and on no other. Unobserved
      occupancy leaves the conjunct — and so the concept — unknown, never false.
    it is in motion — its speed exceeds the motion floor: atoms ['kin.speed'], concepts []
      `kin_speed u` strictly above the formal `motion_speed_floor`: the contract says "exceeds",
      and its "not a stand-in for" clause refuses rest within the region, so a road user at the
      floor is not denoted. The atom carries no direction; nothing of the sense of travel is read.
    the magnitude of its signed heading change over the recognition window behind the observation: atoms ['prim.heading_change'], concepts []
      `prim_heading_change u` with the formal `straight_window` as its window parameter, under
      `.abs`: the magnitude the contract names, so a change to either side counts alike. The
      comparison with `straight_heading_change` is strict (`.lt`), the contract's "is below" and
      its "whose accumulated change of direction within the window reaches the threshold is not
      denoted". Where the window reaches past the start of the trace, or the yaw rate is missing,
      the primitive is unknown and the concept with it, as the contract states.

  Readings this file chose that the contract left open: none. Both bounds are dictated by the
  contract's own words — "exceeds" the floor, "below" the threshold with "reaches" excluded — and
  the magnitude is the contract's, so `narrowings` is empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.proceeds_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStraightWindow : Term := .param "straight_window"
def pStraightHeadingChange : Term := .param "straight_heading_change"
def pMotionSpeedFloor : Term := .param "motion_speed_floor"

/-- Its footprint overlaps the region the formal names. -/
def within : Formula := .atom "rel_occupies" [aU, aR] []

/-- In motion: its speed exceeds the motion floor (strictly, as the contract's "exceeds" says). -/
def inMotion : Formula := .cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedFloor

/-- The signed heading change (degrees, left positive) over the recognition window behind the
    observation, integrated from the yaw rate: the primitive's own quantity, the window its
    parameter. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pStraightWindow]

/-- An unchanged course: the magnitude of that signed change is below the course-change
    threshold, so a change to either side alike is excluded, and the change that reaches the
    threshold is not. -/
def courseHeld : Formula := .cmp (.abs headingChange) .lt pStraightHeadingChange

/-- Travelling across the region on an unchanged course: overlapping it, in motion, and its
    course over the window behind held. -/
def body : Formula := .and (.and within inMotion) courseHeld

def concept : Concept :=
  { id := "drv.motion.proceeds_through_region"
    contract := "The road user is travelling across the region named by the region formal on an unchanged course: at the observation its footprint overlaps that region, it is in motion — its speed exceeds the motion floor — and the magnitude of its signed heading change over the recognition window behind the observation, in degrees measured in the world frame, is below the course-change threshold. The concept denotes travel across the region without a change of course, read at each observation at which the road user is moving within the region and its course over the window behind has held; a road user whose accumulated change of direction within the window reaches the threshold is not denoted, to whichever side it turns, one whose speed does not exceed the motion floor is not denoted however long it overlaps the region, and one whose window reaches past the start of the trace is unknown. Not a stand-in for: occupancy of the region alone, since a road user standing in it or turning within it also overlaps it; rest within the region, which the motion floor excludes, so that a road user halted, waiting or parked there is not denoted even though its course has not changed; entry into or departure from the region, which are the observations at which the overlap begins and ends; the region the road user will leave by or the way beyond it, which the concept does not read; a change of direction to either side, which is the opposite reading of the same signed quantity; or a declared intention to proceed."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"straight_window", .second⟩, ⟨"straight_heading_change", .degree⟩, ⟨"motion_speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.proceeds_through_region
