/-
  drv.interaction.follows_in_line_of_travel — The road user f travels behind the road user l in f's own line of travel at the observation: f's speed stands clear of the travel-speed tolerance the caller sets, so that f's velocity fixes a direction of travel; the offset of l's reference point from f's, taken along that direction of travel, is at least the ahead offset the caller sets and at most the reach the caller sets; the magnitude of that offset taken across that direction is at most the line offset the caller sets; and l goes the same way as f - the cosine of the angle between the two velocities is at least the alignment tolerance the caller sets, or l's own speed does not stand clear of the travel-speed tolerance, a body at rest being no bar to being travelled behind. The tolerances are the observer's: the travel-speed tolerance names the speed below which a measured velocity does not fix a direction of travel; the alignment tolerance, stated as a cosine, absorbs the bend of the way and the sampling noise of a trajectory without admitting a body that goes across f's course; the ahead offset names the offset below which l's reference point does not stand clear of f's along that course; the reach names the distance within which the body ahead is the one being travelled behind; the line offset names the distance across the course within which the one body is in the other's line rather than beside it. None of the five says how much space is enough. The concept is a relation at an instant, read from the two bodies' positions, velocities and speeds. It is read of the direction each body travels and never of the direction either body points: a body that reverses along a road travels behind the body its own course runs towards, not behind the body it faces, and two bodies going the same way stand in the relation whichever way either of them points. It says nothing about how long the one has gone behind the other, nothing about the space left between the two bodies - the offset it bounds is between reference points, not between body outlines - nothing about whether any space is reasonable, prudent or safe, and nothing about any lane, marking, device or way, so it decides the relation on a roadway a scene carries without lanes exactly as within a lane. It is not an overtaking, not a collision course, not a contact, and not a verdict of following too closely.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    f's speed stands clear of the travel-speed tolerance the caller sets: atoms ['kin.speed'], concepts []
    the offset of l's reference point from f's, taken along that direction of travel: atoms ['kin.position', 'kin.velocity', 'kin.speed'], concepts []
    the magnitude of that offset taken across that direction: atoms ['kin.position', 'kin.velocity', 'kin.speed'], concepts []
    the cosine of the angle between the two velocities: atoms ['kin.velocity', 'kin.speed'], concepts []

  How each element is written:

    "f's speed stands clear of the travel-speed tolerance the caller sets" — one comparison,
    `kin_speed f .ge travel_speed_tolerance`, read of f's own measured speed, the "magnitude of
    velocity". Nothing else guards the body: no class, no region, no device, and nothing that
    looks before or after the observation, so the concept is the relation at the instant. The
    same comparison, read of l and negated, is the second disjunct of the last element, so that a
    body at rest is no bar to being travelled behind.

    "the offset of l's reference point from f's, taken along that direction of travel" — the
    offset is the vector from f's reference point to l's, written component by component over the
    two positions, `kin_position l <axis> - kin_position f <axis>`. The direction of travel is
    f's velocity divided by its magnitude, f's speed; so the offset along that direction is the
    inner product of the offset with f's velocity divided by `kin_speed f`. That division is
    never written: `kin_speed` is a measurement and can be zero, and a division by zero is
    unknown rather than a verdict. Both bounds are therefore multiplied through by f's speed, a
    non-negative quantity, which leaves the comparisons the contract's wherever f's speed stands
    clear of zero — which the element above is what makes the caller responsible for:
      offset · velocity(f)  ≥  ahead_offset · speed(f)      (at least the ahead offset)
      offset · velocity(f)  ≤  following_reach · speed(f)   (at most the reach)
    Both sides are m²/s, so the two bounds keep the metres the record gives them. `kin_heading`
    is nowhere in the file, and neither is `rel_bearing` or `rel_surface_gap`: the offset is
    resolved on the direction f travels, in the world frame the positions and the velocity are
    measured in, never on the direction either body points. Hence a pair that reverses is read by
    the course it runs, as the contract requires.

    "the magnitude of that offset taken across that direction" — the same offset and the same
    velocity, taken across instead of along: the cross term
    `offset.x · velocity(f).y - offset.y · velocity(f).x`, whose magnitude `.abs` is the
    across-course offset times f's speed. Neither hand is privileged, the magnitude being taken,
    and the bound is again multiplied through by f's speed:
      |offset × velocity(f)|  ≤  line_offset · speed(f).
    No lane, marking, way or region is read, so the comparison decides the relation on a roadway
    a scene carries without lanes exactly as within a lane.

    "the cosine of the angle between the two velocities" — the inner product of the two velocity
    vectors against the product of the two speeds and the caller's cosine:
      velocity(f) · velocity(l)  ≥  travel_alignment_cosine · speed(f) · speed(l),
    the quotient form `(v_f · v_l) / (speed(f) · speed(l)) ≥ cosine` multiplied through by the
    two speeds, which are non-negative, so the sense of the comparison is kept and no division by
    a measurement is written. `rel_same_direction` is not read: its contract is of the two
    headings, and this element is of the two courses. The comparison is the first disjunct of
    "l goes the same way as f"; its second is `.not` of l's own speed standing clear of the
    travel-speed tolerance.

  The unknowns are the atoms': where f's velocity is unobserved the three offset comparisons and
  the alignment are all unknown, where a position is unobserved the two offset comparisons are
  unknown, and where l's speed is unobserved the last disjunct is unknown unless the alignment
  decides it true. An unobserved atom never reads as false.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.follows_in_line_of_travel

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTravelSpeedTolerance : Term := .param "travel_speed_tolerance"
def pTravelAlignmentCosine : Term := .param "travel_alignment_cosine"
def pAheadOffset : Term := .param "ahead_offset"
def pFollowingReach : Term := .param "following_reach"
def pLineOffset : Term := .param "line_offset"

/-- A body's measured speed, the magnitude of its velocity, in m/s. -/
def speedOf (a : Arg) : Term := .measure "kin_speed" [a]

/-- A component of a body's measured velocity vector, in m/s, in the world frame. -/
def velocityComponent (a : Arg) (axis : String) : Term := .measure "kin_velocity" [a, .lit axis]

/-- A component of a body's reference point, in m, in the world frame. -/
def positionComponent (a : Arg) (axis : String) : Term := .measure "kin_position" [a, .lit axis]

/-- A component of the offset of l's reference point from f's, in m. -/
def offsetComponent (axis : String) : Term :=
  .sub (positionComponent aL axis) (positionComponent aF axis)

/-- The inner product of that offset with f's velocity, in m²/s: the offset taken along f's
    direction of travel, times f's speed — the quotient by the speed is never written. -/
def offsetAlongTimesSpeed : Term :=
  .add (.mul (offsetComponent "x") (velocityComponent aF "x"))
       (.mul (offsetComponent "y") (velocityComponent aF "y"))

/-- The magnitude of the cross term of that offset with f's velocity, in m²/s: the magnitude of
    the offset taken across f's direction of travel, times f's speed. -/
def offsetAcrossTimesSpeed : Term :=
  .abs (.sub (.mul (offsetComponent "x") (velocityComponent aF "y"))
             (.mul (offsetComponent "y") (velocityComponent aF "x")))

/-- The inner product of the two velocity vectors, in m²/s²: the cosine of the angle between the
    two directions of travel, times the product of the two speeds. -/
def velocitiesInnerProduct : Term :=
  .add (.mul (velocityComponent aF "x") (velocityComponent aL "x"))
       (.mul (velocityComponent aF "y") (velocityComponent aL "y"))

/-- The body's speed stands clear of the travel-speed tolerance the caller sets, so that its
    velocity fixes a direction of travel. -/
def standsClearOfRest (a : Arg) : Formula := .cmp (speedOf a) .ge pTravelSpeedTolerance

/-- f's velocity fixes a direction of travel. -/
def fFixesDirectionOfTravel : Formula := standsClearOfRest aF

/-- The offset along f's course is at least the ahead offset the caller sets (both sides times
    f's speed). -/
def leaderStandsAhead : Formula :=
  .cmp offsetAlongTimesSpeed .ge (.mul pAheadOffset (speedOf aF))

/-- That offset is at most the reach the caller sets (both sides times f's speed). -/
def leaderWithinReach : Formula :=
  .cmp offsetAlongTimesSpeed .le (.mul pFollowingReach (speedOf aF))

/-- The magnitude of the offset across f's course is at most the line offset the caller sets
    (both sides times f's speed). -/
def leaderInLine : Formula :=
  .cmp offsetAcrossTimesSpeed .le (.mul pLineOffset (speedOf aF))

/-- The cosine of the angle between the two courses is at least the alignment tolerance the
    caller sets (both sides times the product of the two speeds). -/
def coursesAlign : Formula :=
  .cmp velocitiesInnerProduct .ge
    (.mul pTravelAlignmentCosine (.mul (speedOf aF) (speedOf aL)))

/-- l goes the same way as f: the two courses align, or l's own speed does not stand clear of the
    travel-speed tolerance, a body at rest being no bar to being travelled behind. -/
def leaderGoesSameWay : Formula := .or coursesAlign (.not (standsClearOfRest aL))

/-- f travels behind l in f's own line of travel at the observation. -/
def body : Formula :=
  .and fFixesDirectionOfTravel
    (.and leaderStandsAhead
      (.and leaderWithinReach
        (.and leaderInLine leaderGoesSameWay)))

def concept : Concept :=
  { id := "drv.interaction.follows_in_line_of_travel"
    contract := "The road user f travels behind the road user l in f's own line of travel at the observation: f's speed stands clear of the travel-speed tolerance the caller sets, so that f's velocity fixes a direction of travel; the offset of l's reference point from f's, taken along that direction of travel, is at least the ahead offset the caller sets and at most the reach the caller sets; the magnitude of that offset taken across that direction is at most the line offset the caller sets; and l goes the same way as f - the cosine of the angle between the two velocities is at least the alignment tolerance the caller sets, or l's own speed does not stand clear of the travel-speed tolerance, a body at rest being no bar to being travelled behind. The tolerances are the observer's: the travel-speed tolerance names the speed below which a measured velocity does not fix a direction of travel; the alignment tolerance, stated as a cosine, absorbs the bend of the way and the sampling noise of a trajectory without admitting a body that goes across f's course; the ahead offset names the offset below which l's reference point does not stand clear of f's along that course; the reach names the distance within which the body ahead is the one being travelled behind; the line offset names the distance across the course within which the one body is in the other's line rather than beside it. None of the five says how much space is enough. The concept is a relation at an instant, read from the two bodies' positions, velocities and speeds. It is read of the direction each body travels and never of the direction either body points: a body that reverses along a road travels behind the body its own course runs towards, not behind the body it faces, and two bodies going the same way stand in the relation whichever way either of them points. It says nothing about how long the one has gone behind the other, nothing about the space left between the two bodies - the offset it bounds is between reference points, not between body outlines - nothing about whether any space is reasonable, prudent or safe, and nothing about any lane, marking, device or way, so it decides the relation on a roadway a scene carries without lanes exactly as within a lane. It is not an overtaking, not a collision course, not a contact, and not a verdict of following too closely."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"travel_speed_tolerance", .metrePerSecond⟩, ⟨"travel_alignment_cosine", .ratio⟩, ⟨"ahead_offset", .metre⟩, ⟨"following_reach", .metre⟩, ⟨"line_offset", .metre⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "f's speed stands clear of the travel-speed tolerance the caller sets"
          why := "Read inclusively, `.ge`: the sentence that follows calls the travel-speed tolerance 'the speed below which a measured velocity does not fix a direction of travel', so a speed at the tolerance is not below it and fixes a direction. The same inclusive comparison is used of l inside the last element, and negated there, so the two bodies are measured against the tolerance alike. No magnitude of the choice is this file's: a caller that wants the strict reading sets a tolerance above the speed it means to exclude."
          kind := "reading" }
      , { span := "the offset of l's reference point from f's, taken along that direction of travel"
          why := "Two readings the contract leaves open are chosen. First, the sense of the offset: it is the vector FROM f's reference point TO l's, `kin_position l - kin_position f`, so that an offset along f's course is positive where l lies ahead of f on that course; that is what makes 'the offset below which l's reference point does not stand clear of f's' a lower bound on a signed quantity, and what makes the contract's reversing pair fail. Second, the resolution on the direction of travel: the direction is f's velocity divided by f's speed, and that quotient is NOT written. `kin_speed` is a measurement and can be zero, and a division by zero is unknown rather than a verdict, so both bounds of this element and the one across the course are multiplied through by f's speed, a non-negative quantity, which preserves the sense of each comparison. The written comparisons are therefore exactly the contract's wherever f's speed stands clear of zero, which is what the element before this one requires of the caller's tolerance; a caller that sets a travel-speed tolerance of zero gets, for a body at rest, a zero offset along a direction of travel that its own velocity does not fix, and the contract's first conjunct is what it has forgone."
          kind := "reading" }
      , { span := "is at least the ahead offset the caller sets and at most the reach the caller sets"
          why := "Both bounds read inclusively, `.ge` and `.le`, as the words 'at least' and 'at most' state; an offset exactly at the ahead offset or exactly at the reach satisfies the concept. The two are one conjunction of two comparisons over the same offset term rather than a band written any other way, so neither bound is read of a different quantity than the other."
          kind := "reading" }
      , { span := "the magnitude of that offset taken across that direction is at most the line offset the caller sets"
          why := "Written as the magnitude of the cross term of the offset with f's velocity, `.abs (offset.x · v.y - offset.y · v.x)`, compared inclusively `.le` against the line offset times f's speed. Taking the magnitude is the contract's own word and privileges neither hand, so a body in f's line to the left and one to the right are read alike; the bound is multiplied through by f's speed for the reason given above. No body outline and no extent is read: the offset bounded is between reference points, as the contract says."
          kind := "reading" }
      , { span := "the cosine of the angle between the two velocities is at least the alignment tolerance the caller sets"
          why := "Read inclusively, `.ge`, and written as the inner product of the two velocities against the caller's cosine times the product of the two speeds, rather than as a quotient: dividing by either measured speed could divide by zero and leave the verdict unknown, and both speeds being non-negative the multiplication preserves the sense of the comparison. Where l's speed is zero the comparison degenerates to the inner product being at least zero; that case is immaterial, because the disjunct beside it already admits a body whose speed does not stand clear of the tolerance, and the contract says a body at rest is no bar to being travelled behind."
          kind := "reading" }
      , { span := "or l's own speed does not stand clear of the travel-speed tolerance"
          why := "Written as `.not` of the very comparison the first element writes of f, read of l, so 'does not stand clear' is the strict complement of the inclusive reading chosen above. Kept three-valued deliberately: where l's speed is unobserved this disjunct is unknown, and the whole disjunction is unknown unless the alignment of the two courses decides it true — an unobserved speed never reads as a body at rest."
          kind := "reading" }
      , { span := "The road user f travels behind the road user l in f's own line of travel at the observation"
          why := "The five conjuncts are joined by plain `.and`, with no guard that the two tracks are distinct and no ordering of the evaluation that would make one conjunct decide before another: the contract names no such condition, and a caller that passes the same track twice gets a zero offset judged against its own ahead offset. Nothing of the body looks before or after the observation — no window, no edge, no `since` — so the concept says nothing about how long the one has gone behind the other, and it is no overtaking, collision course, contact or verdict of following too closely."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.follows_in_line_of_travel
