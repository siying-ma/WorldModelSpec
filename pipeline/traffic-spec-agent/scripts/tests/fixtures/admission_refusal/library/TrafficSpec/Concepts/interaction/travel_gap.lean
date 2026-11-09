/-
  drv.interaction.travel_gap — The road user l leaves the road user f at least a stated clear space along f's direction of travel at the observation: the space left between the two body outlines along f's course - the offset of l's reference point from f's taken along the direction of f's velocity, less half the length of each of the two bodies - is at least the travel gap the caller sets, and f's speed stands clear of the travel-speed tolerance the caller sets. The space so reckoned is zero where the two bodies have come together, negative where they overlap, and negative where l lies behind f along f's course, so a body to the rear leaves no space by this reckoning rather than a large one. The length each body contributes is its own, taken about its own reference point and not cast as a shadow along f's course: the reckoning is exact where a body lies along that course and understates the space a body leaves where that body is skew to it. It is read of the direction f travels and never of the direction f points, so the space ahead of a body that reverses along a road is measured the way that body is going. The two parameters are the observer's: the travel gap names the clear space the caller asks for and carries no judgement that such a space is reasonable, prudent or safe, how much space a road user owes being the business of the law that calls the concept; the travel-speed tolerance names the speed below which a measured velocity does not fix a direction of travel. The concept is a relation at an instant between two road users, read from the two bodies' positions, velocities, speeds and sizes: it says nothing about the speed of either body beyond the direction f's velocity fixes, nothing about how long the space has been so, nothing about how long either body has gone before or behind the other, and nothing about any lane, marking, device or way, so it decides the relation on a roadway a scene carries without lanes exactly as within a lane. It is not a bound on the distance between the two reference points, out of which the two bodies' lengths are taken; not a bound on the separation of the two bodies across f's course, so a body abreast of f elsewhere on the way is reckoned by its offset along f's course alone; not a time headway; not an overtaking; not a contact; and not a verdict of following too closely. Where f's speed does not stand clear of the travel-speed tolerance the concept is unknown: a body at rest fixes no direction of travel and the concept says nothing of it.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the offset of l's reference point from f's taken along the direction of f's velocity: atoms ['kin.position', 'kin.velocity', 'kin.speed'], concepts []
    less half the length of each of the two bodies: atoms ['kin.extent'], concepts []
    f's speed stands clear of the travel-speed tolerance the caller sets: atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — the body reaches half of its length either side of its reference point, and kin.extent is read by a formula as the full length, so each body's length is halved.

  How each element is written:

    "f's speed stands clear of the travel-speed tolerance the caller sets" — one comparison,
    `kin_speed f .ge travel_speed_tolerance`, of f's own measured speed, the "magnitude of
    velocity", against the caller's tolerance. It is not a conjunct of the body but the
    PRECONDITION of a `definedWhen`: the contract's last sentence says that where f's speed does
    not stand clear of the tolerance the concept is unknown, "a body at rest fixes no direction of
    travel and the concept says nothing of it", so a body at rest must not read as a body that
    fails to be left space. The comparison is also what makes f's speed positive wherever the body
    is defined, on which the writing of the first element depends.

    "the offset of l's reference point from f's taken along the direction of f's velocity" — the
    offset is the vector FROM f's reference point TO l's, written component by component over the
    two positions, `kin_position l <axis> - kin_position f <axis>`, so that it is positive along
    f's course where l lies ahead of f on that course and negative where l lies behind, which is
    the contract's own reckoning ("negative where l lies behind f along f's course"). The
    direction of travel is f's velocity divided by its magnitude, f's speed; so the offset along
    that direction is the inner product of the offset with `kin_velocity f` divided by
    `kin_speed f`. That division is never written: `kin_speed` is a measurement and can be zero,
    and a division by zero is unknown rather than a verdict. The comparison is therefore
    multiplied through by f's speed, a non-negative quantity, which leaves it the contract's
    wherever f's speed stands clear of zero — which the precondition above is what secures:

      offset · velocity(f)  ≥  (travel_gap + length(f)/2 + length(l)/2) · speed(f)

    both sides in m²/s. `kin_heading` is nowhere in the file, and neither is `rel_surface_gap` or
    `rel_bearing`: the offset is resolved on the direction f TRAVELS, in the world frame the
    positions and the velocity are measured in, never on the direction either body points, so the
    space ahead of a body that reverses along a road is measured the way that body is going.

    "less half the length of each of the two bodies" — `kin_extent` is read by a formula as the
    full length, so each body's half-length is `kin_extent <body> "length"` divided by the
    declared literal 2 (count), a constant divisor and no measurement. Each body contributes its
    OWN length, about its own reference point, with no projection on f's course: the reckoning is
    exact where a body lies along that course and understates the space a body leaves where that
    body is skew to it, exactly as the contract states. The two half-lengths are added to the
    travel gap on the right-hand side rather than subtracted on the left, which is the same
    inequality: the clear space along the course, `offset_along − length(f)/2 − length(l)/2`, is
    at least `travel_gap`.

  The unknowns are the atoms': where either position, f's velocity, f's speed or either body's
  extent is unobserved the comparison is unknown; where f's speed is observed and does not stand
  clear of the tolerance the body is undefined. An unobserved atom never reads as false.

  No magnitude below is this file's own: parameters are formals the caller fills, and the only
  literal is the declared 2.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.travel_gap

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aF : Arg := .var "f"
def aL : Arg := .var "l"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTravelGap : Term := .param "travel_gap"
def pTravelSpeedTolerance : Term := .param "travel_speed_tolerance"

/-- The declared literal 2 (count): a body reaches half of its length either side of its reference
    point, and a formula reads `kin_extent` as the full length. -/
def two : Term := .lit (Units.ratio 2 1) .count

/-- A body's measured speed, the magnitude of its velocity, in m/s. -/
def speedOf (a : Arg) : Term := .measure "kin_speed" [a]

/-- A component of a body's measured velocity vector, in m/s, in the world frame. -/
def velocityComponent (a : Arg) (axis : String) : Term := .measure "kin_velocity" [a, .lit axis]

/-- A component of a body's reference point, in m, in the world frame. -/
def positionComponent (a : Arg) (axis : String) : Term := .measure "kin_position" [a, .lit axis]

/-- The body's own length, in m: `kin_extent` read by a formula as the full extent along its axis. -/
def lengthOf (a : Arg) : Term := .measure "kin_extent" [a, .lit "length"]

/-- How far the body reaches from its own reference point to its own end, in m: half its length. -/
def halfLengthOf (a : Arg) : Term := .div (lengthOf a) two

/-- A component of the offset of l's reference point from f's, in m. -/
def offsetComponent (axis : String) : Term :=
  .sub (positionComponent aL axis) (positionComponent aF axis)

/-- The inner product of that offset with f's velocity, in m²/s: the offset taken along f's
    direction of travel, times f's speed — the quotient by the speed is never written. -/
def offsetAlongTimesSpeed : Term :=
  .add (.mul (offsetComponent "x") (velocityComponent aF "x"))
       (.mul (offsetComponent "y") (velocityComponent aF "y"))

/-- The offset along f's course the caller's travel gap asks for: the gap itself plus the reach of
    each body from its own reference point to its own end, in m. -/
def askedOffsetAlong : Term :=
  .add pTravelGap (.add (halfLengthOf aF) (halfLengthOf aL))

/-- That asked offset times f's speed, in m²/s: the right-hand side of the comparison, multiplied
    through by the same non-negative speed as the left. -/
def askedOffsetAlongTimesSpeed : Term := .mul askedOffsetAlong (speedOf aF)

/-- f's speed stands clear of the travel-speed tolerance the caller sets, so that f's velocity
    fixes a direction of travel: the precondition of the concept. -/
def fFixesDirectionOfTravel : Formula := .cmp (speedOf aF) .ge pTravelSpeedTolerance

/-- The space left between the two body outlines along f's course is at least the travel gap the
    caller sets (both sides times f's speed). -/
def leavesTravelGap : Formula :=
  .cmp offsetAlongTimesSpeed .ge askedOffsetAlongTimesSpeed

/-- l leaves f at least the stated clear space along f's direction of travel at the observation;
    undefined of an f whose speed does not stand clear of the travel-speed tolerance. -/
def body : Formula := .definedWhen fFixesDirectionOfTravel leavesTravelGap

def concept : Concept :=
  { id := "drv.interaction.travel_gap"
    contract := "The road user l leaves the road user f at least a stated clear space along f's direction of travel at the observation: the space left between the two body outlines along f's course - the offset of l's reference point from f's taken along the direction of f's velocity, less half the length of each of the two bodies - is at least the travel gap the caller sets, and f's speed stands clear of the travel-speed tolerance the caller sets. The space so reckoned is zero where the two bodies have come together, negative where they overlap, and negative where l lies behind f along f's course, so a body to the rear leaves no space by this reckoning rather than a large one. The length each body contributes is its own, taken about its own reference point and not cast as a shadow along f's course: the reckoning is exact where a body lies along that course and understates the space a body leaves where that body is skew to it. It is read of the direction f travels and never of the direction f points, so the space ahead of a body that reverses along a road is measured the way that body is going. The two parameters are the observer's: the travel gap names the clear space the caller asks for and carries no judgement that such a space is reasonable, prudent or safe, how much space a road user owes being the business of the law that calls the concept; the travel-speed tolerance names the speed below which a measured velocity does not fix a direction of travel. The concept is a relation at an instant between two road users, read from the two bodies' positions, velocities, speeds and sizes: it says nothing about the speed of either body beyond the direction f's velocity fixes, nothing about how long the space has been so, nothing about how long either body has gone before or behind the other, and nothing about any lane, marking, device or way, so it decides the relation on a roadway a scene carries without lanes exactly as within a lane. It is not a bound on the distance between the two reference points, out of which the two bodies' lengths are taken; not a bound on the separation of the two bodies across f's course, so a body abreast of f elsewhere on the way is reckoned by its offset along f's course alone; not a time headway; not an overtaking; not a contact; and not a verdict of following too closely. Where f's speed does not stand clear of the travel-speed tolerance the concept is unknown: a body at rest fixes no direction of travel and the concept says nothing of it."
    definition := none
    args := [("f", .track), ("l", .track)]
    params := [⟨"travel_gap", .metre⟩, ⟨"travel_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "and f's speed stands clear of the travel-speed tolerance the caller sets"
          why := "Written as the PRECONDITION of a `definedWhen`, not as a second conjunct of an `and`. The contract's first sentence joins the two by 'and', but its last sentence settles what the join means: 'Where f's speed does not stand clear of the travel-speed tolerance the concept is unknown: a body at rest fixes no direction of travel and the concept says nothing of it.' A conjunction would make a body at rest read as a body that fails to be left space — a verdict the contract expressly withholds — so the speed comparison guards the gap comparison instead, and the body is undefined (unknown) of an f whose observed speed is below the tolerance. Where f's speed is itself unobserved both the precondition and the gap comparison are unknown, as the atom is."
          kind := "reading" }
      , { span := "f's speed stands clear of the travel-speed tolerance the caller sets"
          why := "Read inclusively, `.ge`: the contract calls the travel-speed tolerance 'the speed below which a measured velocity does not fix a direction of travel', so a speed AT the tolerance is not below it and does fix a direction. No magnitude of the choice is this file's: a caller that wants the strict reading sets a tolerance above the speed it means to exclude."
          kind := "reading" }
      , { span := "the offset of l's reference point from f's taken along the direction of f's velocity"
          why := "Two readings the contract leaves open are chosen. First, the sense of the offset: it is the vector FROM f's reference point TO l's, `kin_position l - kin_position f`, so that its component along f's course is positive where l lies ahead of f on that course and negative where l lies behind — which is what makes the contract's own reckoning hold, that the space is 'negative where l lies behind f along f's course, so a body to the rear leaves no space by this reckoning rather than a large one'. Second, the resolution on the direction of travel: that direction is f's velocity divided by f's speed, and the quotient is NOT written. `kin_speed` is a measurement and can be zero, and a division by zero is unknown rather than a verdict, so the whole comparison is multiplied through by f's speed, a non-negative quantity, which preserves its sense. The written comparison is therefore exactly the contract's wherever f's speed stands clear of zero, which the precondition secures; a caller that sets a travel-speed tolerance of zero gets, for a body at rest, a comparison of two nil quantities against a direction of travel its own velocity does not fix, and the contract's guard is what it has forgone."
          kind := "reading" }
      , { span := "is at least the travel gap the caller sets"
          why := "Read inclusively, `.ge`, as the words 'at least' state: a space exactly equal to the travel gap satisfies the concept. It is one comparison over the whole reckoning rather than a chain, so the travel gap is read of the space between the outlines and of nothing else."
          kind := "reading" }
      , { span := "less half the length of each of the two bodies"
          why := "Written on the right-hand side of the one comparison rather than subtracted on the left: the two half-lengths are added to the travel gap the caller asks for, which is the same inequality as taking them out of the along-course offset, and it keeps the left-hand side the plain inner product of the offset with f's velocity. Each half-length is `kin_extent <body> \"length\"` divided by the declared literal 2 (count) — a constant divisor, never a measurement — because a formula reads `kin_extent` as the full length while a body reaches half of it either side of its reference point. Each body contributes its own length, with no projection on f's course and no width and no height read, so the reckoning understates the space a skew body leaves, as the contract says it does."
          kind := "reading" }
      , { span := "The road user l leaves the road user f at least a stated clear space along f's direction of travel at the observation"
          why := "Nothing of the body looks before or after the observation — no window, no edge, no `since`, no `always` — and nothing reads a class, a lane, a marking, a device or a way, so the concept is the relation at the instant and decides it on a roadway a scene carries without lanes exactly as within a lane. No guard that the two tracks are distinct is written, the contract naming none: a caller that passes the same track twice gets a nil offset judged against its own travel gap and that body's whole length. Neither body's speed is read beyond f's, whose velocity fixes the direction, so the concept is no time headway."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.travel_gap
