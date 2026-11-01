/-
  drv.motion.travels_with_region_direction — The road user's direction of travel agrees with the direction of travel designated for a given region at this observation: the region carries a designated direction, the road user is in motion, its ground speed greater than speed_tolerance, the bound within which a sampled speed reading counts as no movement, and the component of its velocity along that designated direction is greater than direction_cosine multiplied by its ground speed, so that its course lies within the angle off the designated direction whose cosine is direction_cosine. The region is the caller's: the concept takes it as an argument and never looks for a region of its own, and it does not read whether the road user is on that region - whether the body overlaps it, lies beside it or travels elsewhere on the way is the caller's to state. The concept denotes the agreement of the body's own motion with a designated direction and nothing else. It is not the negation of travelling against that direction: a course across the designated direction, whose component along it is neither positive nor negative beyond the tolerances, satisfies neither these words nor those, so a caller that must forbid every direction but the designated one states it with these words and not with their negation. It is not the direction the body points: a body that backs along a way travels in the direction its velocity gives and not in the one its nose gives, and a body whose nose is turned while its course holds is denoted all the same. It is not a judgement of which side of a centre line, of a roadway or of a way the body is on, not a turn, a reversing manoeuvre or a lane change, and it says nothing about the kind of the region - a region that carries a direction need not be a one-way roadway. A body at rest is travelling in no direction and is not denoted; how long the body has held its course, and whether holding it is lawful or safe, are the caller's to state. Where the region carries no designated direction, or the direction reads as a zero vector, the concept is unknown, as that atom's contract requires.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the region carries a designated direction: atoms ['st.lane_direction'], concepts []
    the road user is in motion, its ground speed greater than speed_tolerance: atoms ['kin.speed'], concepts []
    the component of its velocity along that designated direction is greater than direction_cosine multiplied by its ground speed: atoms ['kin.velocity', 'kin.speed', 'st.lane_direction'], concepts []

  How the first element is written. The designation is read of the region the caller names, the
  formal `r`, by `st.lane_direction` - no region quantifier, no region of the concept's own - and it
  is read where the contract uses it, in the component along that direction, rather than as a
  conjunct of its own. The atom carries the designation's absence itself: "a place no carrier covers
  has none (unknown)" and "a zero vector reads unknown", so a region that carries no designated
  direction leaves every term that reads the atom unknown and with it the comparison that reads
  them, which is what the contract's closing words require. A separate conjunct asserting that the
  direction exists would be true at every observation at which the atom reads at all and so would
  decide nothing the component does not already decide (narrowing 1).

  How the second element is written. Motion is `kin.speed`, the body's own ground speed, strictly
  above the formal parameter `speed_tolerance`: the contract's "in motion, its ground speed greater
  than speed_tolerance". The comparison is strict, as the words are, so a reading at the tolerance
  is no movement. The atom is the magnitude of the body's velocity and not a control input, so a
  body at rest fails this conjunct whatever its gear, nose or throttle.

  How the third element is written. The component of the velocity along the designated direction is
  the dot product of `kin.velocity` with `st.lane_direction`, written out over the two world-frame
  components (`x` and `y`, the component literal every vector atom takes): vx·dx + vy·dy. The
  direction is read normalised, as that atom's row prescribes, so the dot product is the signed
  length of the velocity's projection on the designated direction, in m/s, carrying the atom's
  disclosed rounding of at most 2·10⁻⁶ of the unit vector (narrowing 2). The comparison is that
  component strictly greater than `direction_cosine` times `kin.speed`: both sides are m/s, the
  parameter being a ratio, and dividing the component by the speed - which is zero for a body at
  rest - is never written, the comparison being stated as a product instead. Because the comparison
  is strict and the course across the designated direction gives a component of zero, these words
  and the words for travelling against the direction are satisfied by disjoint courses, as the
  contract says. Nothing here reads the body's heading, its occupancy of the region, the kind of the
  region, or any history.

  Where the direction is unobserved and the body is at rest, the three-valued conjunction is false
  rather than unknown: a body at rest is travelling in no direction and is not denoted, which the
  contract states in those words (narrowing 3).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.travels_with_region_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pDirectionCosine : Term := .param "direction_cosine"
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The road user's ground speed, the magnitude of its velocity. -/
def speed : Term := .measure "kin_speed" [aU]

/-- A component of the road user's velocity in the world frame, in m/s. -/
def velocityComponent (axis : String) : Term := .measure "kin_velocity" [aU, .lit axis]

/-- A component of the direction of travel designated for the region the caller names, read
    normalised as that atom's contract prescribes. -/
def designatedComponent (axis : String) : Term := .measure "st_lane_direction" [aR, .lit axis]

/-- The component of the road user's velocity along the region's designated direction: the dot
    product of its velocity with that normalised direction, in m/s. Unknown wherever the region
    carries no designated direction. -/
def componentAlongDesignated : Term :=
  .add (.mul (velocityComponent "x") (designatedComponent "x"))
       (.mul (velocityComponent "y") (designatedComponent "y"))

/-- The road user is in motion: its ground speed is greater than `speed_tolerance`. -/
def inMotion : Formula := .cmp speed .gt pSpeedTolerance

/-- The course agrees with the designated direction: the component of the velocity along it is
    greater than `direction_cosine` times the ground speed, so the course lies within the angle off
    the designated direction whose cosine is `direction_cosine`. -/
def courseAgreesWithDesignated : Formula :=
  .cmp componentAlongDesignated .gt (.mul pDirectionCosine speed)

/-- The road user's direction of travel agrees with the direction designated for the region: it is
    in motion and the component of its velocity along that designated direction is above
    `direction_cosine` times its ground speed. -/
def body : Formula := .and inMotion courseAgreesWithDesignated

def concept : Concept :=
  { id := "drv.motion.travels_with_region_direction"
    contract := "The road user's direction of travel agrees with the direction of travel designated for a given region at this observation: the region carries a designated direction, the road user is in motion, its ground speed greater than speed_tolerance, the bound within which a sampled speed reading counts as no movement, and the component of its velocity along that designated direction is greater than direction_cosine multiplied by its ground speed, so that its course lies within the angle off the designated direction whose cosine is direction_cosine. The region is the caller's: the concept takes it as an argument and never looks for a region of its own, and it does not read whether the road user is on that region - whether the body overlaps it, lies beside it or travels elsewhere on the way is the caller's to state. The concept denotes the agreement of the body's own motion with a designated direction and nothing else. It is not the negation of travelling against that direction: a course across the designated direction, whose component along it is neither positive nor negative beyond the tolerances, satisfies neither these words nor those, so a caller that must forbid every direction but the designated one states it with these words and not with their negation. It is not the direction the body points: a body that backs along a way travels in the direction its velocity gives and not in the one its nose gives, and a body whose nose is turned while its course holds is denoted all the same. It is not a judgement of which side of a centre line, of a roadway or of a way the body is on, not a turn, a reversing manoeuvre or a lane change, and it says nothing about the kind of the region - a region that carries a direction need not be a one-way roadway. A body at rest is travelling in no direction and is not denoted; how long the body has held its course, and whether holding it is lawful or safe, are the caller's to state. Where the region carries no designated direction, or the direction reads as a zero vector, the concept is unknown, as that atom's contract requires."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"direction_cosine", .ratio⟩, ⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the region carries a designated direction"
          why := "read of the region the caller names, by st.lane_direction, where the contract uses the direction - in the component along it - and not as a conjunct of its own: that atom is unknown where no carrier covers the region and where the vector reads zero, so every term reading it, and the comparison over them, is unknown exactly in the cases the contract's closing words name, and a separate conjunct asserting the designation exists would be true at every observation at which the atom reads at all and would decide nothing further"
          kind := "reading" }
      , { span := "the component of its velocity along that designated direction"
          why := "written as the dot product of kin.velocity with st.lane_direction over the two world-frame components, vx·dx + vy·dy, the direction being read normalised as that atom's row prescribes, so the value is the signed length of the velocity's projection on the designated direction in m/s and carries that atom's disclosed rounding (the vector read is the unit vector times a factor below 1 + 2·10⁻⁶); the comparison with direction_cosine times kin.speed is written as that product and never as the component divided by the speed, a speed that is zero for a body at rest"
          kind := "reading" }
      , { span := "Where the region carries no designated direction, or the direction reads as a zero vector, the concept is unknown"
          why := "read as unknown wherever the motion of the body does not already settle the words false: the designation is read inside one conjunct of a three-valued conjunction, so an unobserved direction leaves the concept unknown where the body is in motion, while a body at rest with the direction unobserved reads false, which is what the contract's 'A body at rest is travelling in no direction and is not denoted' requires of it"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.travels_with_region_direction
