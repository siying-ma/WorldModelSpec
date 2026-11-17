/-
  LVMC_11_12_070_B — LVMC-11-12-070-B

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): Said driver
    s2 (condition): having so yielded
    s3 (condition): may proceed
    s4 (boilerplate): and
    s5 (subject): the drivers of all other vehicles
    s6 (trigger): approaching the intersection
    s7 (condition): on the through highway
    s8 (obligation): shall yield
    s9 (standard): right-of-way
    s10 (condition): to the vehicle about to enter or cross the through highway

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'dev.stop_sign', 'dev.yield_sign', 'dev.traffic_signal', 'dev.governs'], derived []
    s2: atoms ['kin.speed', 'rel.contact', 'prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.occupies', 'st.intersection'], derived ['drv.motion.complete_halt']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s7: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.traffic_signal', 'dev.governs', 'st.lane_enters', 'rel.occupies', 'st.travel_region'], derived []
    s8: atoms ['kin.speed', 'rel.contact'], derived []
    s10: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []

  How each span is written:
    s5 (class): the subject carries ru_aggregate DEF-NRS-484A-320::vehicle; "all other": the
      entering vehicle `o` is never the subject (`.not (.same o subject)`).
    s6: the subject occupies a region `c` of kind travel_region with st_lane_enters(c, j), `j` of
      kind intersection (`throughApproach`).
    s7: the subject's carrier `c` is governed by no stop sign, no yield sign and no traffic signal
      showing flashing_red (`.not (entranceDevice c)`); the entering vehicle's carrier `c2` into the
      same `j` is governed by one of them (`entranceDevice c2`).
    s1 / s10: `o` is a vehicle (same aggregate), `c2` enters `j` with an entrance device, and `o`
      occupies `j`, or occupies `c2` and occupies `j` at some observation within p.conflict_horizon
      ahead (`.within .time`); "having occupied c2 or j at every observation since it last occupied
      c2" is the `since` chain of `onApproach` in s2.
    s2: `soYielded o c2 j`: (ii) `.since onApproach (.rises (occupies o c2) ∧ onApproach)` — from
      the last rise of o's occupancy of c2 to now, o occupied c2 or j, and at every observation at
      which it did not yet occupy j it was in no danger of a crash (`throughConflict`) with a vehicle
      v ≠ o in j or on a carrier entering j with no entrance device: not (o's speed above
      p.halt_speed_tolerance with closest approach within p.conflict_horizon below
      p.conflict_centre_clearance), and no rel_contact with such a v. A rise before the recording
      leaves the `since` search unknown (its unobserved past), as the record states. (i) where c2
      is governed by a stop sign or a flashing-red signal (`haltDevice c2`),
      `.since (.not (.rises (occupies o c2))) (complete_halt o ∧ occupies o c2 ∧ ¬ occupies o j)`:
      a halt on c2 short of j at some observation after which o's occupancy of c2 did not rise
      again, i.e. since its last rise.
    s8 / s9: for every such `o` (the whole selection re-bound in the obligation, with the subject's
      `c` and `j`), not (subject's kin_speed > p.halt_speed_tolerance ∧
      prim_closest_approach_within(subject, o; p.conflict_horizon) ∧
      prim_closest_approach_distance(subject, o; p.conflict_horizon) < p.conflict_centre_clearance),
      and not rel_contact(subject, o).
    s3: residue (the record's).

    The carrier c2 is written distinct from j (`.not (.same c2 j)`): the intersection is a
      travel region but no approach carrier into itself, and st_lane_enters is not recorded on it
      (unknown), so without the guard a source that hides dev.governs would leave the selection
      unknown for the intersection standing in as its own approach. This is entry topology, not a
      narrowing of any span.

  Choices the record left open: none beyond the writing above — the `.within` window is measured
  in time (its track argument is `o`, which a time window does not read); `throughConflict` puts
  the speed comparison and the contact inside one existential over v, which is the record's
  "speed above tolerance while some v is in danger, and contact with no such v" (the speed does not
  depend on v). No narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_12_070_B

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vehicleAggregate : String := "DEF-NRS-484A-320::vehicle"

/-- ru.aggregate: x is a vehicle (DEF-NRS-484A-320). -/
def isVehicle (x : String) : Formula := .atom "ru_aggregate" [.var x, .lit vehicleAggregate] []

/-- rel.occupies. -/
def occupies (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- st.lane_enters: carrier c is an approach to intersection j. -/
def entersJ (c j : String) : Formula := .atom "st_lane_enters" [.var c, .var j] []

/-- dev.governs. -/
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []

/-- A stop sign governs r. -/
def stopSignOn (r d : String) : Formula := .existsDevice (.lit "stop_sign") d (governs d r)

/-- A yield sign governs r. -/
def yieldSignOn (r d : String) : Formula := .existsDevice (.lit "yield_sign") d (governs d r)

/-- A traffic signal showing flashing_red governs r. -/
def flashingRedOn (r d : String) : Formula :=
  .existsDevice (.lit "traffic_signal") d
    (.and (governs d r) (.atom "dev_traffic_signal_shows" [.var d, .lit "flashing_red"] []))

/-- s7: r is an entrance to a through highway — governed by a stop sign, a yield sign or a
    flashing-red signal. `sfx` keeps the device variables of each call apart. -/
def entranceDevice (r sfx : String) : Formula :=
  .or (stopSignOn r ("dS" ++ sfx)) (.or (yieldSignOn r ("dY" ++ sfx)) (flashingRedOn r ("dR" ++ sfx)))

/-- s2 (i): the devices requiring a full halt — a stop sign or a flashing-red signal. -/
def haltDevice (r sfx : String) : Formula :=
  .or (stopSignOn r ("dHS" ++ sfx)) (flashingRedOn r ("dHR" ++ sfx))

/-- kin.speed above the halt tolerance: the road user proceeds. -/
def proceeds (x : String) : Formula := .cmp (.measure "kin_speed" [.var x]) .gt pHaltSpeedTolerance

/-- s9: a danger of a crash between a and b — constant-velocity closest approach of the centres
    within the horizon, below the centre clearance. -/
def closeApproach (a b : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [.var a, .var b] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [.var a, .var b] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- rel.contact. -/
def contact (a b : String) : Formula := .atom "rel_contact" [.var a, .var b] []

/-- s2 (ii): o proceeds in danger of a crash with, or touches, some vehicle v ≠ o that occupies j
    or a carrier entering j governed by no entrance device. -/
def throughConflict (o j : String) : Formula :=
  .existsUser "v"
    (.and (.not (.same (.var "v") (.var o)))
      (.and (isVehicle "v")
        (.and
          (.or (occupies "v" j)
            (.existsRegion (.lit "travel_region") "c3"
              (.and (occupies "v" "c3") (.and (entersJ "c3" j) (.not (entranceDevice "c3" "3"))))))
          (.or (.and (proceeds o) (closeApproach o "v")) (contact o "v")))))

/-- s2 (ii), at one observation: o occupies c2 or j, and before entering j it is in no conflict. -/
def onApproach (o c2 j : String) : Formula :=
  .and (.or (occupies o c2) (occupies o j)) (.or (occupies o j) (.not (throughConflict o j)))

/-- s2: o has so yielded since its occupancy of c2 last rose. -/
def soYielded (o c2 j : String) : Formula :=
  .and (.since (onApproach o c2 j) (.and (.rises (occupies o c2)) (onApproach o c2 j)))
    (.implies (haltDevice c2 "2")
      (.since (.not (.rises (occupies o c2)))
        (.and (.derived "drv_motion_complete_halt" [.var o] [pHaltSpeedTolerance])
          (.and (occupies o c2) (.not (occupies o j))))))

/-- s1, s2, s10: o is a vehicle other than the subject, coming from a carrier c2 entering j with an
    entrance device, in j or entering it within the horizon, having so yielded. -/
def enteringVehicle (o j : String) : Formula :=
  .and (.not (.same (.var o) vSubject))
    (.and (isVehicle o)
      (.existsRegion (.lit "travel_region") "c2"
        (.and (.not (.same (.var "c2") (.var j))) (.and (entersJ "c2" j)
          (.and (entranceDevice "c2" "2")
            (.and
              (.or (occupies o j)
                (.and (occupies o "c2") (.within .time pConflictHorizon o (occupies o j))))
              (soYielded o "c2" j)))))))

/-- s6, s7: the subject approaches j through a carrier c with no entrance device. -/
def throughApproach (c j : String) : Formula :=
  .and (occupies "subject" c) (.and (entersJ c j) (.not (entranceDevice c "1")))

/-- s8, s9: the subject grants precedence to o. -/
def yieldsTo (o : String) : Formula :=
  .and (.not (.and (proceeds "subject") (closeApproach "subject" o))) (.not (contact "subject" o))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle "subject"

/-- Applicability: s1 (condition): Said driver; s2 (condition): having so yielded; s3 (condition): may proceed; s6 (trigger): approaching the intersection; s7 (condition): on the through highway; s10 (condition): to the vehicle about to enter or cross the through highway -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.existsRegion (.lit "travel_region") "c"
      (.and (throughApproach "c" "j") (.existsUser "o" (enteringVehicle "o" "j"))))

/-- Obligation: s8 (obligation): shall yield; s9 (standard): right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.forallRegion (.lit "travel_region") "c"
      (.implies (throughApproach "c" "j")
        (.forallUser "o" (.implies (enteringVehicle "o" "j") (yieldsTo "o")))))

def rule : Rule :=
  { id := "LVMC_11_12_070_B"
    laws := ["LVMC-11-12-070-B"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "right-of-way: DEF-NRS-484A-210 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a danger of a crash exists where, under constant velocities, the centres of the two road users come within a centre clearance comparable to their half-extents inside a time-to-collision horizon; a road user whose speed is at or below the source's speed resolution has granted precedence"
          surrogate := false } ]
    residues := ["a permission granted to the entering driver; it imposes no condition on the through-highway drivers beyond the entering vehicle's movement, which s10 carries, so the duty is the same whether or not the permission is read"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_12_070_B
