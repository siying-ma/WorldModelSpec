/-
  drv.motion.travels_against_region_direction — The road user is travelling against the direction of travel designated for the region named by the region formal: it is in motion — its speed exceeds the motion floor — and the cosine of the angle between its velocity and the region's designated direction, both read in the world frame, is below the negative of the opposition tolerance, a ratio between minus one and one. The concept denotes the state at one observation. Not a stand-in for: occupancy of the region, which the caller reads separately; a reversing manoeuvre, which is read from the gear and is a vehicle backing while pointed along the designated direction; or motion across the region at an angle within the tolerance band, which the concept does not call opposed.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed exceeds the motion floor: atoms ['kin.speed'], concepts []
      `kin_speed u` strictly above the formal `motion_speed_floor`: "exceeds" is strict.
    the cosine of the angle between its velocity and the region's designated direction: atoms ['kin.velocity', 'st.lane_direction'], concepts []
      The velocity is read component-wise in the world frame (`kin_velocity u "x"`, `… "y"`); the
      designated direction of the region formal is read component-wise too
      (`st_lane_direction r "x"`, `… "y"`), and the accessor normalises it, so the dot product of
      the two is the speed times the cosine sought.

  The one reading this file chooses (declared as a narrowing below): the comparison is written in
  product form, `v · d < -(opposition_tolerance) * speed`, rather than by dividing the dot product
  by the speed. The two agree wherever the speed is positive — which the first conjunct requires —
  and the product form stays decided where a division by a measured speed (zero at rest) would not.
  Nothing is read of the user's heading: the contract compares the direction the body moves in.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.travels_against_region_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMotionSpeedFloor : Term := .param "motion_speed_floor"
def pDirectionOppositionCosine : Term := .param "direction_opposition_cosine"

/-- The road user's speed: the magnitude of its velocity, in m/s. -/
def speed : Term := .measure "kin_speed" [aU]

/-- The road user's velocity, read component-wise in the world frame. -/
def velX : Term := .measure "kin_velocity" [aU, .lit "x"]
def velY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The direction of travel designated for the region formal, read component-wise in the world
    frame; the accessor returns it normalised. -/
def dirX : Term := .measure "st_lane_direction" [aR, .lit "x"]
def dirY : Term := .measure "st_lane_direction" [aR, .lit "y"]

/-- The velocity projected on the designated direction: the speed times the cosine of the angle
    between them, since the designated direction is read as a unit vector. -/
def alongDirection : Term := .add (.mul velX dirX) (.mul velY dirY)

/-- In motion, and the cosine of the angle between velocity and designated direction below the
    negative of the tolerance — the latter in product form, never dividing by the measured speed. -/
def body : Formula :=
  .and
    (.cmp speed .gt pMotionSpeedFloor)
    (.cmp alongDirection .lt (.neg (.mul pDirectionOppositionCosine speed)))

def concept : Concept :=
  { id := "drv.motion.travels_against_region_direction"
    contract := "The road user is travelling against the direction of travel designated for the region named by the region formal: it is in motion — its speed exceeds the motion floor — and the cosine of the angle between its velocity and the region's designated direction, both read in the world frame, is below the negative of the opposition tolerance, a ratio between minus one and one. The concept denotes the state at one observation. Not a stand-in for: occupancy of the region, which the caller reads separately; a reversing manoeuvre, which is read from the gear and is a vehicle backing while pointed along the designated direction; or motion across the region at an angle within the tolerance band, which the concept does not call opposed."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"motion_speed_floor", .metrePerSecond⟩, ⟨"direction_opposition_cosine", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the cosine of the angle between its velocity and the region's designated direction, both read in the world frame, is below the negative of the opposition tolerance"
          why := "Written in product form: the velocity's projection on the designated direction (a unit vector, as the atom returns it) is compared with the negative tolerance times the speed, instead of dividing that projection by the speed. The two readings agree wherever the speed is positive, which the motion-floor conjunct requires, and the product form stays decided where a division by a measured speed would be undefined at rest."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.travels_against_region_direction
