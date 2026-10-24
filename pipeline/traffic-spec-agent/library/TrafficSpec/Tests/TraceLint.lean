import TrafficSpec.Core.Evidence.TraceLint
namespace TrafficSpec.Tests.TraceLint
open TrafficSpec Units TrafficSpec.TraceLint

def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1

def rect (x0 y0 x1 y1 : Int) : List Vec :=
  [(metres x0, metres y0), (metres x1, metres y0), (metres x1, metres y1), (metres x0, metres y1)]

-- A lane, and a car (half-extents 2 m × 1 m) driving along it at 10 m/s, sampled each second.
def lane7 : Structure := { id := 7, kind := .lane, boundary := some (rect 0 (-2) 100 2) }
def car (x path : Int) (h : Vec := (Q.ofInt 1, Q.ofInt 0)) (yaw : Q := Q.zero) : RoadUser :=
  { track := 1, classes := some [.motorVehicle]
    kin := { position := some (metres x, metres 0), heading := some h, extent := some (metres 2, metres 1, metres 1)
             speed := some (metres 10), pathLength := some (metres path), yawRate := some yaw } }
def signal (ind : SignalIndication) (gov : List RegionId := [7]) : Device :=
  { id := 9, kind := .trafficSignal, position := some (metres 50, metres 3), governs := gov, indications := some [ind] }
def scene (t : Int) (u : RoadUser) (structures : List Structure := [lane7]) (devs : List Device := [signal .circularGreen])
    (occ : List (TrackId × RegionId) := [(1, 7)]) : Scene :=
  { t := t, users := [u], structures := structures, devices := devs, occupancyObserved := [1], occupies := occ }

def clean : Trace := [scene 0 (car 10 0), scene 1000 (car 20 10) (devs := [signal .circularYellow])]
#guard checkTrace clean = []

-- identity and references
#guard has (checkTrace [{ scene 0 (car 10 0) with users := [car 10 0, car 30 0] }]) "track 1 appears more than once"
#guard has (checkTrace [scene 0 (car 10 0) (occ := [(1, 7), (1, 99)])]) "occupies names region 99"
#guard has (checkTrace [{ scene 0 (car 10 0) with relations := [{ a := 1, b := 1 }, { a := 1, b := 1 }] }]) "more than one relation"
#guard has (checkTrace [{ scene 0 (car 10 0) with users := [{ car 10 0 with sightAlongWay := some [(7, metres 100)] }] }]) "which is not a highway"
#guard has (checkTrace [{ scene 0 (car 10 0) with links := [(1, 5)] }]) "links names track 5"

-- the map is static; a device's state may change, its other fields may not
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10) (structures := [{ lane7 with boundary := some (rect 0 (-3) 100 2) }])]) "structure 7 differs"
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10) (structures := [lane7, { id := 8, kind := .crosswalk, boundary := some (rect 60 (-2) 62 2) }])]) "structure 8 is not in the first scene"
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10) (devs := [signal .circularGreen []])]) "device 9 differs"
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10) (devs := [])]) "device 9 is missing"

-- geometry
#guard has (checkTrace [scene 0 (car 10 0) (structures := [{ lane7 with boundary := some [(metres 0, metres 0), (metres 1, metres 0)] }])]) "fewer than three vertices"
#guard has (checkTrace [scene 0 (car 10 0) (structures := [{ lane7 with boundary := some [(metres 0, metres 0), (metres 5, metres 0), (metres 10, metres 0)] }])]) "has zero area"
#guard has (checkTrace [scene 0 (car 10 0) (structures := [{ lane7 with boundary := some (rect 0 (-2) 100 2 ++ [(metres 0, metres (-2))]) }])]) "repeats a vertex"
#guard has (checkTrace [scene 0 (car 10 0) (structures := [{ lane7 with boundary := some [(metres 0, metres (-2)), (metres 100, metres 4), (metres 100, metres (-2)), (metres 0, metres 2)] }])]) "intersects itself"
#guard has (checkTrace [scene 0 { car 10 0 with kin := { (car 10 0).kin with extent := some (metres 2, metres 0, metres 1) } }]) "half-width must be positive"
#guard has (checkTrace [scene 0 (car 10 0 (h := (Q.zero, Q.zero)))]) "heading is the zero vector"

-- occupancy of an observed track is derived from the geometry, over closed sets; a pair left out is
-- read as not occupied, so every structure needs a boundary where occupancy is observed
def strip : Structure := { id := 8, kind := .crosswalk, boundary := some (rect 9 (-5) 11 5) }
def touching : Structure := { id := 8, kind := .crosswalk, boundary := some (rect 12 (-5) 14 5) }
def occOf (τ : Trace) : List (TrackId × RegionId) := (completeOccupancy τ).head!.occupies
#guard occOf [scene 0 (car 10 0) (structures := [lane7, strip]) (occ := [])] = [(1, 7), (1, 8)]
#guard occOf [scene 0 (car 10 0) (structures := [lane7, touching]) (occ := [])] = [(1, 7), (1, 8)]   -- touching counts
#guard occOf [scene 0 (car 10 0) (occ := [(1, 99)])] = [(1, 7)]                                      -- a listed pair is replaced
#guard occOf [{ scene 0 (car 10 0) (occ := [(1, 99)]) with occupancyObserved := [] }] = [(1, 99)]    -- an unobserved track keeps its pairs
#guard checkTrace (completeOccupancy [scene 0 (car 10 0) (structures := [lane7, strip]) (occ := [])]) = []
#guard checkTrace [scene 0 (car 10 0) (structures := [lane7, strip]) (occ := [(1, 7), (1, 8)])] = []
#guard has (checkTrace [scene 0 (car 10 0) (structures := [lane7, { id := 8, kind := .fireHydrant, position := some (metres 50, metres 5) }])]) "structure 8 has no boundary"
#guard has (checkTrace [scene 0 { car 10 0 with kin := { (car 10 0).kin with extent := none } }]) "footprint is undefined"

-- path length: never decreasing, and never shorter than the chord
#guard has (checkTrace [scene 0 (car 10 10), scene 1000 (car 20 5)]) "it never decreases"
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 5)]) "less than the straight-line distance"

-- heading against yaw rate: the same direction (whatever the vector's length) with a turn that is
-- not a whole number of turns is a contradiction; a full turn is not
#guard has (checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10 (h := (Q.ofInt 2, Q.zero)) (yaw := Q.ofInt 10))]) "turns it 10°"
#guard checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10 (h := (Q.ofInt 2, Q.zero)) (yaw := Q.ofInt 360))] = []
#guard checkTrace [scene 0 (car 10 0), scene 1000 (car 20 10 (h := (Q.ofInt 1, Q.ofInt 1)) (yaw := Q.ofInt 10))] = []

-- the references alone: a witness is held to them, not to the kinematic checks
#guard has (checkReferences [{ scene 0 (car 10 0) with users := [{ car 10 0 with sightAlongWay := some [(7, metres 100)] }] }]) "which is not a highway"
#guard has (checkReferences [scene 0 (car 10 0) (occ := [(1, 7), (1, 99)])]) "occupies names region 99"
#guard checkReferences [scene 0 (car 10 10), scene 1000 (car 20 5)] = []

-- the witness instant
#guard has (checkWitness clean [("v", 1)] [] 500) "at 500 is not the timestamp"
#guard checkWitness clean [("v", 1)] [("lane", .region 7), ("light", .device 9)] 1000 = []
#guard has (checkWitness clean [("v", 2)] [] 0) "binder v is grounded to track 2"
#guard has (checkWitness clean [("v", 1)] [("light", .region 9)] 0) "entity light is region 9"

end TrafficSpec.Tests.TraceLint
