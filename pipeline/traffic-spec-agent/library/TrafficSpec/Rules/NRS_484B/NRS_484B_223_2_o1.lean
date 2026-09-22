/-
  NRS 484B.223(2), first obligation — upon a highway which has been divided into three clearly
  marked lanes, a vehicle must not be driven in the extreme left lane at any time.

  THE READING (the blueprint's, not this file's):
  - s2 subject    — the binder `a`: the subject track, of one of the classes the node lists for
                    the corpus's word "vehicle". This node binds no second party.
  - s1 trigger    — the applicability: a is upon a roadway, and the carriageway a is on has been
                    divided into the stated number of clearly marked lanes.
  - s3 obligation — a's footprint does not overlap the extreme left lane of that carriageway.
  - s4            — boilerplate ("at any time"); it carries no element and appears nowhere below.
  - s5 … s17      — the siblings of subsection 2 (the centre lane and its three exceptions) and
                    their boilerplate; they are another node's, and nothing here reads them.

  CHOICES THE TEXT DID NOT DICTATE (each one is a reading of a span, not an invention):

  1. "a highway which has been divided into three clearly marked lanes" (s1) is read on the lane
     the subject occupies, through the census `st.lane_adjacency` records on it: its count equals
     the statute's three. The claimed set offers no other way to say it — the formula language
     cannot count regions, and no atom of this node relates one lane to the others of its
     carriageway. CONSEQUENCE, stated plainly: ATOMS.md gives `st.lane_adjacency`'s count as the
     count of lanes IN THAT DIRECTION, while the statute's "divided into three lanes" is a census
     of the carriageway; on the classic three-lane two-directional highway (one lane each way and
     a shared centre lane) a source that records a per-direction count of two engages nothing
     here. The rule takes the recorded count at face value. See task_result.md.
  2. "upon a highway" (s1) is `st.roadway` with `rel.occupies`: the subject is on a roadway of the
     scene. `st.highway` is claimed by no element of this node, and `st.roadway` is the atom the
     node names on s1 for the place the duty is owed.
  3. "clearly marked" (s1) is a recorded marking on each side of that lane whose type is not
     `none`. `st.lane_marking` reports a type and a colour per side; the statute asks for marking,
     not for a particular legend, so no type and no colour is required and the test is the
     negation of `none`. Both sides are read, because a lane "clearly marked" off from the rest of
     the carriageway is bounded on both.
  4. "the extreme left lane" (s3) is `drv.extreme_lane` on the left: the concept ranks the lanes
     the subject occupies by the ordinal `st.lane_adjacency` records from the left, and holds when
     one of them is the leftmost. Because it reads every lane `rel.occupies` gives, it speaks of
     the FOOTPRINT the node's obligation names, not of a reference point: a body lying across the
     extreme left lane and its neighbour engages it. The `left` of the ordinal is the left of the
     carriageway as the source recorded it, and this rule adopts that convention rather than
     deriving a side of its own; `kin.heading` is claimed on no span.
  5. `st.lane` is written beside `rel.occupies` in the applicability although `existsRegion .lane`
     already ranges over lanes: the node claims the atom on s1 and on s3, and `Formula.atoms` does
     not see inside a bounded quantifier, so the claim would otherwise be unused. The conjunct also
     states that the region bound is one the source reports AS a lane.
  6. s4 ("at any time") carries no `always`. The obligation is written for an instant and
     `Grounding` applies it at every instant of the episode; an `always` would additionally make
     the unobserved future unknown, which the span does not say.

  The only magnitude in this file is the statute's own "three", declared on s1 and written once.
  No parameter of the reading is named: the node declares none.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec.Rules.NRS_484B_223_2_o1

/-- The binder, as an argument. -/
private def subj : Arg := .var "a"

/-- s1's figure: the statute's "three", a dimensionless count. -/
private def threeLanes : Term := .lit (Q.ofInt 3) .count

/-- The classes the node's s2 element lists for the corpus's word "vehicle". -/
private def vehicleClasses : List String :=
  ["ru_motor_vehicle", "ru_motorcycle", "ru_moped", "ru_bus", "ru_transit_bus", "ru_taxicab",
   "ru_tour_bus_or_limousine", "ru_truck", "ru_commercial_motor_vehicle",
   "ru_trailer_or_combination", "ru_bicycle", "ru_animal_or_animal_drawn",
   "ru_emergency_vehicle", "ru_official_vehicle", "ru_procession_vehicle"]

/-- One of the classes the word "vehicle" covers. -/
private def isVehicle (x : Arg) : Formula :=
  vehicleClasses.foldr (fun n acc => .or (.atom n [x] []) acc) .ff

-- ---------------------------------------------------------------------------------------------
-- s1: the trigger — a roadway divided into three clearly marked lanes
-- ---------------------------------------------------------------------------------------------

/-- The census `st.lane_adjacency` records on a lane: how many lanes the division has. -/
private def laneCount (l : String) : Term := .measure "st_lane_adjacency" [.var l, .lit "count"]

/-- Marked off on both sides: a recorded marking whose type is not `none`. -/
private def clearlyMarked (l : String) : Formula :=
  .and (.not (.atom "st_lane_marking" [.var l, .lit "left", .lit "none"] []))
       (.not (.atom "st_lane_marking" [.var l, .lit "right", .lit "none"] []))

/-- s1: a is upon a roadway. -/
private def uponRoadway : Formula :=
  .existsRegion .roadway "r"
    (.and (.atom "st_roadway" [.var "r"] [])
          (.atom "rel_occupies" [subj, .var "r"] []))

/-- s1: the division a is driving in has the stated number of clearly marked lanes. -/
private def dividedIntoThree : Formula :=
  .existsRegion .lane "l"
    (.and (.atom "st_lane" [.var "l"] [])
      (.and (.atom "rel_occupies" [subj, .var "l"] [])
        (.and (.cmp (laneCount "l") .eq threeLanes) (clearlyMarked "l"))))

-- ---------------------------------------------------------------------------------------------
-- s3: the obligation — never the extreme left lane
-- ---------------------------------------------------------------------------------------------

/-- s3: some lane a's footprint lies in is the leftmost of the division. -/
private def inExtremeLeftLane : Formula := .derived "drv_extreme_lane" [subj, .lit "left"] []

-- ---------------------------------------------------------------------------------------------

def rule : Rule :=
  { id := "NRS_484B_223_2_o1"
    laws := ["NRS-484B-223-2"]
    binders :=
      [ { name := "a", cls := .and (.atom "ru_subject" [subj] []) (isVehicle subj) } ]
    applicability := .and uponRoadway dividedIntoThree
    obligation := .not inExtremeLeftLane
    assumptions := []
    operationalizations := []
    residues := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_2_o1
