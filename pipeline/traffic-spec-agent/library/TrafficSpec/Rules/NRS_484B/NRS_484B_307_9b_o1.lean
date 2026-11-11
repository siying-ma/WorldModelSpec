/-
  NRS_484B_307_9b_o1 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): Where the signal is a steady red with a green turn arrow:
    c2 (subject): A person driving a motorcycle, moped or
    c3 (subject): trimobile
    c4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    c5 (trigger): facing the signal
    c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow
    c7 (boilerplate): if:
    c8 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;
    c9 (sibling): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    c11 (sibling): (3) No other device at the place prohibits the turn, if applicable;
    c12 (boilerplate): and
    c13 (sibling): (4) The person yields the right-of-way
    c15 (sibling): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    c1: atoms ['dev.traffic_signal'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped'], derived []
    c4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    c5: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    c6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region', 'drv.motion.heading_change_since_entry']
    c8: atoms ['kin.speed', 'prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.stop_line', 'st.entrance_of', 'st.lane_enters', 'st.region_geometry', 'st.intersection', 'st.travel_region'], derived ['drv.motion.halted']

  How each span is written:
    c2, c4 (subject): the class of x is the disjunction of the five admitted aggregates, each
      `ru_aggregate x <id>`; c3 is the node's residue (a trimobile is a member of the motorcycle
      aggregate).
    c1, c5, c6 (applicability), judged at the observation at which x leaves an intersection i
      (`drv_motion_leaving_region`): read back with `since`, x has stayed on i (`inside`: no entry
      into i, and i occupied or just left) since an observation at which x entered i
      (`drv_motion_entering_region`) while occupying a travel region c (`rel_occupies`) that
      enters i (`st_lane_enters c i`), with a traffic signal s that governs c or i (`dev_governs`)
      showing circular_red together with green_arrow(d). The arrow's direction d is a literal, so the
      passage is written once per direction: under green_arrow(left), straight (|change| below
      p.turn_recognition_angle) or a turn to the right (change at most minus the angle); under
      green_arrow(right), straight or a turn to the left (change at least the angle). The change is
      `drv_motion_heading_change_since_entry x i` with the run profile's step parameter.
      `.not (.same c i)` keeps the intersection itself out of the carriers: an intersection is no
      approach carrier and the source records no entrance on it (st.lane_enters), so without it
      the intersection x occupies at its entry would leave every carrier selection unknown.
    c8 (obligation), judged at the same leaving: the entry is selected again exactly as above
      (leaving, `since` over `inside`, the entry, and every carrier c with the same `approach`
      relations, the signal showing circular_red and a green arrow of either direction). At that
      entry, for each such c, the place is chosen in the record's order:
        - a stop line l recorded as marking c (`st_entrance_of l c`);
        - else, where c's marks are observed and include no stop line, a crosswalk w marking c;
        - else, where c has neither, the intersection i itself: its outline is the entrance end of
          c at i, the distance and the offset along c are read to it.
      The search is `since (¬start ∧ ¬leaving) act`, run from the entry: `act` is x halted
      (`drv_motion_halted`, p.speed_resolution) while occupying c, its body within
      p.stop_point_tolerance of the place (`st_region_geometry_distance`), the place not behind x
      along c (`prim_region_offset_along` ≥ 0), x not overlapping i, and for a crosswalk not
      overlapping it; `start` (the approach start) is x on c, off the place, short of it (offset
      > 0) and farther from it than the tolerance. The search's other end, x's previous entry into
      i, is written as the leaving of i that followed that entry: between the two x overlaps i, so
      no act can lie there, and the verdict is the same as ending at the entry. A search that
      reaches the recording's start is unknown (the `since` truncation).
      Several carriers: the duty holds where every selected carrier's search finds the act, fails
      where none does, and is unknown (`definedWhen … ff`) where the verdict differs between them.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- The quantified variables: the intersection, the approach carrier, the signal, the marks. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vL : Arg := .var "l"
def vW : Arg := .var "w"

def member (aggregate : String) : Formula := .atom "ru_aggregate" [vX, .lit aggregate] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (member "DEF-NRS-484A-135::motorcycle")
    (.or (member "DEF-NRS-484A-125::moped")
      (.or (member "DEF-NRS-484A-025::bicycle")
        (.or (member "DEF-NRS-484B-017::electric_bicycle")
          (member "DEF-NRS-484B-018::electric_scooter"))))

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []
def entering : Formula := .derived "drv_motion_entering_region" [vX, vI] []
def leaving : Formula := .derived "drv_motion_leaving_region" [vX, vI] []
def shows (indication : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit indication] []

/-- x on i since its latest entry: no entry here, and i occupied here or left here (c6). -/
def inside : Formula := .and (.not entering) (.or (occupies vI) leaving)

/-- c1, c5: carrier c, which x occupies, enters i, and a signal governing c or i shows a steady red
    with the given green arrow. -/
def approach (arrow : Formula) : Formula :=
  .and (.not (.same vC vI))
    (.and (occupies vC)
      (.and (.atom "st_lane_enters" [vC, vI] [])
        (.existsDevice (.lit "traffic_signal") "s"
          (.and (.or (.atom "dev_governs" [vS, vC] []) (.atom "dev_governs" [vS, vI] []))
            (.and (shows "circular_red") arrow)))))

/-- c6: the heading change since the entry, read at the leaving. -/
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

def straightThrough : Formula := .cmp (.abs headingChange) .lt pTurnRecognitionAngle

/-- The passage under green_arrow(dir): entered through an approach under it, and straight through
    or turned opposite the arrow. -/
def passage (dir : String) (opposite : Formula) : Formula :=
  .and (.since inside (.and entering (.existsRegion (.lit "travel_region") "c" (approach (shows s!"green_arrow({dir})")))))
    (.or straightThrough opposite)

/-- Applicability: c1 (trigger): Where the signal is a steady red with a green turn arrow:; c5 (trigger): facing the signal; c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and leaving
      (.or (passage "left" (.cmp headingChange .le (.neg pTurnRecognitionAngle)))
        (passage "right" (.cmp headingChange .ge pTurnRecognitionAngle))))

/-- c8: the place p ahead of x along c, as a signed distance, and its distance from x's body. -/
def offsetTo (p : Arg) : Term := .quantity "prim_region_offset_along" [vX, p, vC] []
def distanceTo (p : Arg) : Term := .measure "st_region_geometry_distance" [vX, p]

/-- c8: the approach start: x on c, off the place, short of it and outside its stopping zone. -/
def approachStart (p : Arg) : Formula :=
  .and (occupies vC)
    (.and (.not (occupies p))
      (.and (.cmp (offsetTo p) .gt zeroMetres) (.cmp (distanceTo p) .gt pStopPointTolerance)))

/-- c8: the stop: x halted on c, within the tolerance of the place, not past it, not in i. -/
def haltAt (p : Arg) : Formula :=
  .and (.derived "drv_motion_halted" [vX] [pSpeedResolution])
    (.and (occupies vC)
      (.and (.cmp (distanceTo p) .le pStopPointTolerance)
        (.and (.cmp (offsetTo p) .ge zeroMetres) (.not (occupies vI)))))

/-- c8: the search back from the entry, ended by the approach start or by x's previous visit to i. -/
def searchBack (p : Arg) (act : Formula) : Formula :=
  .since (.and (.not (approachStart p)) (.not leaving)) act

def marksC (kind : String) (v : String) : Formula :=
  .existsRegion (.lit kind) v (.atom "st_entrance_of" [.var v, vC] [])

/-- c8: the halt before the place, the place taken in the record's order. -/
def haltedBefore : Formula :=
  .or (.existsRegion (.lit "stop_line") "l"
        (.and (.atom "st_entrance_of" [vL, vC] []) (searchBack vL (haltAt vL))))
    (.or (.and (.not (marksC "stop_line" "l"))
          (.existsRegion (.lit "crosswalk") "w"
            (.and (.atom "st_entrance_of" [vW, vC] [])
              (searchBack vW (.and (haltAt vW) (.not (occupies vW)))))))
      (.and (.not (marksC "stop_line" "l"))
        (.and (.not (marksC "crosswalk" "w")) (searchBack vI (haltAt vI)))))

def anyArrow : Formula := .or (shows "green_arrow(left)") (shows "green_arrow(right)")

/-- At the leaving, the entry the applicability names, every carrier of it complied. -/
def everyApproachHalted : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies leaving
      (.since inside (.and entering
        (.forallRegion (.lit "travel_region") "c" (.implies (approach anyArrow) haltedBefore)))))

/-- At the leaving, the entry the applicability names, some carrier of it complied. -/
def someApproachHalted : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.and leaving
      (.since inside (.and entering
        (.existsRegion (.lit "travel_region") "c" (.and (approach anyArrow) haltedBefore)))))

/-- Obligation: c8 (obligation): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection; -/
def obligation : Formula :=
  .or everyApproachHalted (.definedWhen (.not someApproachHalted) .ff)

def rule : Rule :=
  { id := "NRS_484B_307_9b_o1"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2, whose definition takes \"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\": the duty is the same whether or not the word is read."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "c8"
          why := "Where no stop line or crosswalk marks the approach, 'before entering the intersection' is read against the intersection region's own outline: the distance from x's body and the offset along the approach carrier are taken to the intersection region, whose edge is the carrier's entrance end."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o1
