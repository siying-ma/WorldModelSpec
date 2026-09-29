import TrafficSpec.Core.Language.Export
import TrafficSpec.Tests.Decode
/-!
The concepts that needed a language extension or a primitive, written as concepts over the
extended language, and their values compared with the Core-defined bodies they replace on the
guards state the values the rewrites give and stay.
-/
namespace TrafficSpec.Tests.Rewrites
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Tests.Semantics

private def sec (n : Int) : Term := .lit (seconds n) .second
private def mps (n : Int) : Term := .lit (metresPerSecond n) .metrePerSecond
private def m (n : Int) : Term := .lit (metres n) .metre
private def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []
private def speed (x : Arg) : Term := .measure "kin_speed" [x]
private def x : Arg := .var "x"
private def y : Arg := .var "y"
private def vs (c : SemCtx) (φ : Formula) : List Tri := (evalAll c φ).toList.map (·.v)
private def okEq (e : QR) (q : Q) : Bool := match e with | .ok v => Q.eq v q | .error _ => false
private def isErr (e : QR) (w : UnknownReason) : Bool := match e with | .error r => r == w | .ok _ => false

-- E1 `rises`: moving off is the speed rising above the bound
def movingOff : Concept :=
  { id := "drv.motion.moving_off", contract := "the speed exceeds a bound now and did not at the previous observation"
    args := [("x", .track)], params := [⟨"eps", .metrePerSecond⟩]
    body := .formula (.rises (.cmp (speed x) .gt (.param "eps"))) }
-- E1: a lane is entered whose neighbour was occupied at the previous observation
private def prevOcc (x r : Arg) : Formula :=
  .or (.and (occ x r) (.not (.rises (occ x r)))) (.rises (.not (occ x r)))
def laneChange : Concept :=
  { id := "drv.lane.change", contract := "a lane adjacent to a lane occupied at the previous observation is entered"
    args := [("x", .track)], params := []
    body := .formula (.existsRegion (.lit "lane") "l" (.and (.rises (occ x (.var "l")))
      (.existsRegion (.lit "lane") "m" (.and (prevOcc x (.var "m"))
        (.or (.atom "st_lane_adjacency_left" [.var "l", .var "m"] []) (.atom "st_lane_adjacency_right" [.var "l", .var "m"] [])))))) }
-- E5: a region kind as a literal formal
def entering : Concept :=
  { id := "drv.position.entering", contract := "a region of the given kind is occupied now and was not at the previous observation"
    args := [("x", .track), ("k", .literal ["intersection", "crosswalk", "stop_line"])], params := []
    body := .formula (.rises (.existsRegion (.var "k") "r" (occ x (.var "r")))) }
def inside : Concept :=
  { id := "drv.position.inside", contract := "a region of the given kind is occupied"
    args := [("x", .track), ("k", .literal ["intersection", "crosswalk", "safety_zone"])], params := []
    body := .formula (.existsRegion (.var "k") "r" (occ x (.var "r"))) }
-- E2 `sinceRise`: arrival order
private def once (φ : Formula) : Formula := .since .tt φ
def arrivedBefore : Concept :=
  { id := "drv.position.arrived_before", contract := "a reached a region of the given kind more than tau before b"
    args := [("a", .track), ("b", .track), ("k", .literal ["intersection"])], params := [⟨"tau", .second⟩]
    body := .formula
      (let ina := .existsRegion (.var "k") "r" (occ (.var "a") (.var "r"))
       let inb := .existsRegion (.var "k") "r" (occ (.var "b") (.var "r"))
       .or (.and (once inb) (.cmp (.sub (.sinceRise ina) (.sinceRise inb)) .gt (.param "tau")))
           (.and (.not (once inb)) (.cmp (.sinceRise ina) .gt (.param "tau")))) }
-- E3 `aggregate`: below the median speed of same-direction traffic in range
def belowTraffic : Concept :=
  { id := "drv.motion.below_traffic", contract := "the speed is below the median speed of the same-direction road users within range r by at least margin"
    args := [("x", .track)], params := [⟨"r", .metre⟩, ⟨"margin", .metrePerSecond⟩, ⟨"cos_tol", .ratio⟩]
    body := .formula (.cmp (speed x) .le (.sub
      (.aggregate .median "y" (.and (.not (.same x y)) (.and (.cmp (.measure "rel_centre_distance" [x, y]) .le (.param "r"))
                                    (.atom "rel_same_direction" [x, y] [.param "cos_tol"]))) (speed y))
      (.param "margin"))) }
-- E4 `definedWhen`: a lane change is feasible only while one lane is occupied
private def adjacent (l n : Arg) : Formula :=
  .or (.atom "st_lane_adjacency_left" [l, n] []) (.atom "st_lane_adjacency_right" [l, n] [])
private def straddling (x : Arg) : Formula :=
  .existsRegion (.lit "lane") "l" (.and (occ x (.var "l")) (.existsRegion (.lit "lane") "m" (.and (adjacent (.var "l") (.var "m")) (occ x (.var "m")))))
def changeFeasible : Concept :=
  { id := "drv.lane.feasible_change", contract := "the neighbouring lane on the given side exists and no other road user occupies it within longitudinal gap g; undefined while the body occupies two lanes"
    args := [("x", .track), ("s", .literal ["left", "right"])], params := [⟨"g", .metre⟩]
    body := .formula (.definedWhen (.not (straddling x))
      (.existsRegion (.lit "lane") "l" (.and (occ x (.var "l"))
        (.existsRegion (.lit "lane") "n" (.and (.atom "st_lane_adjacency" [.var "l", .var "s", .var "n"] [])
          (.not (.existsUser "o" (.and (.not (.same x (.var "o"))) (.and (occ (.var "o") (.var "n"))
            (.cmp (.measure "rel_surface_gap" [x, .var "o", .lit "longitudinal"]) .le (.param "g"))))))))))) }
-- P1: turning and a U-turn from the heading change primitive
def turningLeft : Concept :=
  { id := "drv.motion.turning_left", contract := "the heading changed to the left by at least theta over the last w"
    args := [("x", .track)], params := [⟨"theta", .degree⟩, ⟨"w", .second⟩]
    body := .formula (.cmp (.quantity "prim_heading_change" [x] [.param "w"]) .ge (.param "theta")) }
def uTurn : Concept :=
  { id := "drv.motion.u_turn", contract := "the heading reversed over the last w: its change is within tol of a half turn"
    args := [("x", .track)], params := [⟨"w", .second⟩, ⟨"tol", .degree⟩]
    body := .formula (.cmp (.abs (.sub (.abs (.quantity "prim_heading_change" [x] [.param "w"])) (.lit (degrees 180) .degree))) .le (.param "tol")) }
-- P2: time to conflict from the closest-approach primitives
def conflictSoon : Concept :=
  { id := "drv.interaction.conflict_within", contract := "the centres approach within the horizon, come within a clearance of each other, and do so sooner than the bound"
    args := [("a", .track), ("b", .track)], params := [⟨"horizon", .second⟩, ⟨"clearance", .metre⟩, ⟨"bound", .second⟩]
    body := .formula (.and (.derived "prim_closest_approach_within" [.var "a", .var "b"] [.param "horizon"])
      (.and (.cmp (.quantity "prim_closest_approach_distance" [.var "a", .var "b"] [.param "horizon"]) .le (.param "clearance"))
            (.cmp (.quantity "prim_closest_approach_time" [.var "a", .var "b"] [.param "horizon"]) .lt (.param "bound")))) }
-- P3: conditions of a device
def conditionsHold : Concept :=
  { id := "drv.control.conditions_hold", contract := "the device's legend conditions hold now for the road user"
    args := [("d", .track), ("x", .track)], params := []
    body := .formula (.derived "prim_conditions_hold" [.var "d", x] []) }

def cs : List Concept := [movingOff, laneChange, entering, inside, arrivedBefore, belowTraffic, changeFeasible, turningLeft, uTurn, conflictSoon]
#guard cs.all fun c => Concept.check cs c = []
private def call (c : SemCtx) (n : String) (args : List Arg) (ps : List Term) : List Tri :=
  vs c (Concept.expand cs (.derived n args ps))

-- moving off: never on the braking trace; on its reverse it is the edge where the speed exceeds the bound
#guard call c "drv_motion_moving_off" [x] [.param "p.stop_speed"] = [.u, .f, .f, .f, .f, .f, .f, .f, .f]
def τrev : Trace := ((List.range 9).map fun k => { sceneAt (8 - k) with t := Int.ofNat (k * 500) })
def crev : SemCtx := SemCtx.mk' τrev ρ β
#guard call crev "drv_motion_moving_off" [x] [.param "p.stop_speed"] = [.u, .f, .f, .f, .t, .f, .f, .f, .f]

-- lane change: the edge into the straddle
#guard call clane "drv_lane_change" [x] [] = [.u, .t, .f]

-- entering and inside a region of a kind chosen by the caller
#guard call carr "drv_position_entering" [x, .lit "intersection"] [] = [.u, .f, .f, .f, .t, .f, .f, .f, .f]
#guard call carr "drv_position_inside" [x, .lit "crosswalk"] [] = List.replicate 9 .f
#guard (evalAll carr (.existsRegion (.var "k") "r" (occ x (.var "r"))))[0]!.why = [.malformed "region kind `k` is a variable"]

-- arrival order: y's arrival precedes the trace, so its time is unknown; x arrives at 2 s
#guard call carr "drv_position_arrived_before" [x, y, .lit "intersection"] [sec 1] = List.replicate 9 .u
#guard (evalAll carr (Concept.expand cs (.derived "drv_position_arrived_before" [x, y, .lit "intersection"] [sec 1])))[8]!.why = [.windowTruncated "since_rise"]
-- the old body decided this from an upper bound on y's arrival; the rewrite reports the truncation (contract change, recorded)
private def arr2Occ (k : Nat) : List (TrackId × RegionId) :=
  (if k ≥ 2 then [(1, 7), (2, 7), (2, 9)] else [(1, 7), (2, 7)]) ++ (if k ≥ 6 then [(1, 9)] else [])
private def arr2Scene (k : Nat) : Scene := { sceneAt k with structures := [lane7, junction], occupies := arr2Occ k }
def τarr2 : Trace := (List.range 9).map arr2Scene
def carr2 : SemCtx := SemCtx.mk' τarr2 ρ β
-- y in at 1 s, x at 3 s: decided once both arrivals are observed (before that the unobserved past may hold x's)
#guard call carr2 "drv_position_arrived_before" [y, x, .lit "intersection"] [sec 1] = List.replicate 6 .u ++ [.t, .t, .t]
#guard call carr2 "drv_position_arrived_before" [x, y, .lit "intersection"] [sec 1] = List.replicate 6 .u ++ [.f, .f, .f]

-- below the traffic's median speed: y stands 30 m ahead, same direction; the median is its speed
#guard call c "drv_motion_below_traffic" [x] [m 40, mps 1, .lit (Q.mk' 9 10) .ratio] = List.replicate 9 .f
#guard (evalAll c (Concept.expand cs (.derived "drv_motion_below_traffic" [x] [m 10, mps 1, .lit (Q.mk' 9 10) .ratio])))[0]!.why = [.undefined "aggregate"]   -- nobody in range

-- feasibility: undefined while straddling; unknown, not false, when a neighbour is unobserved
#guard call clane "drv_lane_feasible_change" [x, .lit "left"] [m 5] = [.u, .u, .u]
#guard (evalAll clane (Concept.expand cs (.derived "drv_lane_feasible_change" [x, .lit "left"] [m 5])))[1]!.why = [.undefined "defined_when"]

-- turning: a trace with a yaw rate of 30°/s for 2 s, sampled at 500 ms
def yawScene (k : Nat) : Scene := { sceneAt 0 with t := Int.ofNat (k * 500), users := [{ mover 5 (5 * k) with kin := { (mover 5 (5 * k)).kin with yawRate := some (degrees 30) } }, blocker] }
def cyaw : SemCtx := SemCtx.mk' ((List.range 9).map yawScene) ρ β
#guard call cyaw "drv_motion_turning_left" [x] [.lit (degrees 45) .degree, sec 2] = [.u, .u, .u, .u, .t, .t, .t, .t, .t]
#guard call cyaw "drv_motion_u_turn" [x] [sec 2, .lit (degrees 10) .degree] = List.replicate 4 .u ++ List.replicate 5 .f

-- conflict: x closes on the standing y from 30 m at 10 m/s: closest approach at 3 s, distance 0
#guard okEq (evalTAll c (.quantity "prim_closest_approach_time" [x, y] [sec 5]))[0]! (seconds 3)
#guard okEq (evalTAll c (.quantity "prim_closest_approach_distance" [x, y] [sec 5]))[0]! Q.zero
#guard isErr (evalTAll c (.quantity "prim_closest_approach_time" [x, y] [sec 5]))[8]! (.undefined "prim_closest_approach_time")   -- both stand
#guard call c "drv_interaction_conflict_within" [x, y] [sec 5, m 1, sec 4] = [.t, .t, .t, .f, .f, .f, .f, .f, .f]   -- 3, 3.125, 3.5, then 4.5 s and beyond the horizon
#guard call c "drv_interaction_conflict_within" [x, y] [sec 5, m 1, sec 2] = List.replicate 9 .f

-- new constructors on their own
#guard vs c (.rises (.cmp (speed x) .le (mps 4))) = [.u, .f, .f, .t, .f, .f, .f, .f, .f]
#guard (evalAll c (.rises (.atom "sig_brake_lamp" [x] [])))[3]!.why = [.absentAtom "sig_brake_lamp"]
#guard vs c (.definedWhen (.cmp (speed x) .gt (mps 0)) .tt) = [.t, .t, .t, .t, .t, .u, .u, .u, .u]
#guard okEq (evalTAll c (.sinceRise (.cmp (speed x) .le (mps 4))))[8]! (Q.mk' 5 2)   -- speed ≤ 4 since 1500 ms
#guard okEq (evalTAll c (.aggregate .count "u" (.atom "ru_motor_vehicle" [.var "u"] []) (speed (.var "u"))))[0]! (Q.ofInt 2)
#guard okEq (evalTAll c (.aggregate .count "u" (.not (.same x (.var "u"))) (speed (.var "u"))))[0]! (Q.ofInt 1)   -- the subject excluded
#guard okEq (evalTAll c (.aggregate .max "u" .tt (speed (.var "u"))))[0]! (metresPerSecond 10)
#guard okEq (evalTAll c (.aggregate .min "u" .tt (speed (.var "u"))))[0]! Q.zero
#guard isErr (evalTAll c (.aggregate .median "u" (.atom "sig_brake_lamp" [.var "u"] []) (speed (.var "u"))))[0]! (.absentAtom "sig_brake_lamp")   -- membership unknown
#guard vs c (.same x x) = List.replicate 9 .t
#guard vs c (.same x y) = List.replicate 9 .f
#guard Rule.check [] { Tests.Grounding.rule with obligation := .same x (.lit "y") } = ["test/gap obligation: `same` compares two bound variables"]
#guard Rule.check [] { Tests.Grounding.rule with obligation := .existsRegion (.var "k") "r" (occ x (.var "r")) } = ["test/gap obligation: region kind `k` is a variable; spell the kind, or fill it from a literal formal"]
#guard Rule.check [] { Tests.Grounding.rule with obligation := .existsRegion (.lit "unicorn") "r" (occ x (.var "r")) } = ["test/gap obligation: region kind `unicorn` names no kind"]
#guard ((Term.toJson (.aggregate .median "u" .tt (speed (.var "u")))).compress.splitOn "median").length = 2
end TrafficSpec.Tests.Rewrites
