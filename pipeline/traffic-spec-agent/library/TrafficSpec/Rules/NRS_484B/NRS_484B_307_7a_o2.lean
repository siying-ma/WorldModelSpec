/-
  NRS_484B_307_7a_o2 — NRS-484B-307-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a flashing yellow turn arrow, displayed alone or in combination with another signal:
    s2 (subject): Vehicular traffic facing the signal
    s3 (sibling): is permitted to cautiously
    s4 (sibling): enter the intersection only to make the movement indicated by the arrow signal,
    s5 (sibling): or other such movement as is permitted by other signal indications displayed at the same time.
    s6 (subject): Such vehicular traffic
    s7 (obligation): must yield
    s8 (standard): the right-of-way
    s9 (condition): to pedestrians lawfully within the intersection or an adjacent crosswalk
    s10 (sibling): and yield
    s11 (sibling): the right-of-way
    s12 (sibling): to other traffic lawfully within the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s7: atoms ['kin.speed', 'rel.contact'], derived []
    s9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []

  How each is written:
    s2/s6 (class): the subject is a member of both admitted aggregates, traffic and vehicle
      ('vehicular traffic'), each through `ru_aggregate` with the aggregate id.
    s1 + s2 (applicability): for some intersection i (quantifier kind `intersection`) and some
      head s (device kind `traffic_signal`), `facing i s` held at some observation — the subject
      occupies a travel region c (kind `travel_region`) with `st_lane_enters c i` and
      `dev_governs s c`, and s shows flashing_yellow_arrow(left | right | u_turn) — and the
      subject has occupied i at every observation after it up to the judged one (`since`).
      The record's two limbs ("occupies c now with the arrow now", or "occupies i, has done so
      since it entered i from such a c with the arrow then") are exactly `since (occupies i)
      facing`: `since φ ψ` holds where ψ holds now (the first limb) or ψ held earlier and φ held
      at every observation since (the second). Writing the first limb again beside it would be a
      duplicate leaf, so it is written once.
    s9 (condition, in the obligation): for every road user p not the subject (`same`), of the
      aggregate pedestrian, whose footprint overlaps i, or overlaps a crosswalk w (kind
      `crosswalk`) recorded as marking the entrance (`st_entrance_of w c2`) of a travel region c2
      that enters i (`st_lane_enters c2 i`). The intersection is selected again in the obligation
      by the applicability's whole selection (rule 3c) and the duty is written for every such i.
      The carrier c2 is written `not (same c2 i)`: a region that enters i is never i itself (an
      intersection is no approach carrier of itself, st.lane_enters), so this states nothing the
      record does not; it keeps i, which carries no lane record and so leaves `st_lane_enters i i`
      unobserved, from making the adjacent-crosswalk test unknown for a reason other than the
      crosswalk's recorded entrances.
    s7 + s8 (duty): not (subject speed > p.halt_speed_tolerance, and the centres' closest approach
      lies within p.conflict_horizon (`prim_closest_approach_within`) at a centre distance below
      p.conflict_centre_clearance (`prim_closest_approach_distance`)), and not `rel_contact`.
    No choice beyond the record: no narrowing of this session's own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_7a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- `x` occupies region `r` (rel.occupies). -/
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []

/-- s1: head `s` displays a flashing yellow turn arrow (left, right or u-turn), with or without
    other states. -/
def flashingYellowTurnArrow (s : String) : Formula :=
  .or (.atom "dev_traffic_signal_shows" [.var s, .lit "flashing_yellow_arrow(left)"] [])
    (.or (.atom "dev_traffic_signal_shows" [.var s, .lit "flashing_yellow_arrow(right)"] [])
         (.atom "dev_traffic_signal_shows" [.var s, .lit "flashing_yellow_arrow(u_turn)"] []))

/-- s1 + s2 at one observation: the subject occupies a travel region c entering intersection `i`,
    which head `s` governs, and `s` shows a flashing yellow turn arrow. -/
def facingAt (i s : String) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occ "subject" "c")
      (.and (.atom "st_lane_enters" [.var "c", .var i] [])
        (.and (.atom "dev_governs" [.var s, .var "c"] [])
          (flashingYellowTurnArrow s))))

/-- The applicability's whole selection of intersection `i`: some traffic signal head s such that
    the subject faces it now, or occupies `i` and has done so at every observation since it faced
    s from an approach of `i` while s showed the arrow. -/
def facesArrowAt (i : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.since (occ "subject" i) (facingAt i "s"))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger) and s2 (subject facing the signal). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (facesArrowAt "i")

/-- s9: road user `p`, other than the subject, is a pedestrian within intersection `i` or within a
    crosswalk recorded as marking the entrance of a travel region that enters `i`. -/
def pedestrianWithin (p i : String) : Formula :=
  .and (.not (.same (.var p) vSubject))
    (.and (.atom "ru_aggregate" [.var p, .lit "DEF-NRS-484A-165::pedestrian"] [])
      (.or (occ p i)
        (.existsRegion (.lit "crosswalk") "w"
          (.and (occ p "w")
            (.existsRegion (.lit "travel_region") "c2"
              (.and (.not (.same (.var "c2") (.var i)))
                (.and (.atom "st_entrance_of" [.var "w", .var "c2"] [])
                      (.atom "st_lane_enters" [.var "c2", .var i] []))))))))

/-- s7 + s8: the subject yields to `p`: no constant-velocity closest approach within the horizon
    below the conflict clearance while it moves, and no contact. -/
def yieldsTo (p : String) : Formula :=
  .and
    (.not
      (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
        (.and (.derived "prim_closest_approach_within" [vSubject, .var p] [pConflictHorizon])
              (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var p] [pConflictHorizon])
                    .lt pConflictCentreClearance))))
    (.not (.atom "rel_contact" [vSubject, .var p] []))

/-- Obligation: s7 (obligation): must yield; s8 (standard): the right-of-way; to every pedestrian of
    s9, at every intersection the applicability selects. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (facesArrowAt "i")
      (.forallUser "p" (.implies (pedestrianWithin "p" "i") (yieldsTo "p"))))

def rule : Rule :=
  { id := "NRS_484B_307_7a_o2"
    laws := ["NRS-484B-307-7a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the subject grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the pedestrian arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_7a_o2
