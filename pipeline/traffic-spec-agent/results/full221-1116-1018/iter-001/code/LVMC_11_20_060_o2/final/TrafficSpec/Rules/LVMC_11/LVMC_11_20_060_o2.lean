/-
  LVMC_11_20_060_o2 — LVMC-11-20-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (subject): The driver of a vehicle
    e2 (condition): within a business or residence district
    e3 (condition): emerging or entering an alley, driveway or building
    e4 (sibling): shall stop such vehicle immediately prior to
    e5 (trigger): driving onto a sidewalk or onto the sidewalk area extending across any alleyway or driveway
    e6 (obligation): yielding
    e7 (standard): the right-of-way
    e8 (condition): to any pedestrian
    e9 (standard): as may be necessary to avoid collision
    e10 (boilerplate): and
    e11 (sibling): upon entering the roadway
    e12 (sibling): shall yield
    e13 (sibling): the right-of-way
    e14 (sibling): to all vehicles approaching on said roadway

  Elements (span → atoms, derived):
    e1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['st.driveway_or_alley_entrance', 'st.alley', 'rel.occupies'], derived []
    e5: atoms ['st.sidewalk', 'rel.occupies'], derived []
    e6: atoms ['kin.speed', 'rel.contact'], derived []
    e8: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []

  How each is written:
    e1: the binder class `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`; the driver is read
        through the vehicle's motion (the record's observable reading).
    e2: `asm asm.business_or_residence_district`, conjoined into the applicability.
    e3: some region of kind driveway_or_alley_entrance, or some region of kind alley, that the
        subject occupies (`rel_occupies`): the two kinds as two disjuncts, as the record names them.
    e5: some region of kind sidewalk that the subject occupies (`rel_occupies`).
    e8: in the obligation, every road user p other than the subject (`not (same p subject)`) that
        is a member of DEF-NRS-484A-165::pedestrian; the record places the quantifier there.
    e6/e7/e9: for each such p, not (kin_speed(subject) > p.halt_speed_tolerance while
        prim_closest_approach_within(subject, p; p.conflict_horizon) and
        prim_closest_approach_distance(subject, p; p.conflict_horizon) < p.conflict_centre_clearance),
        and not rel_contact(subject, p) — the record's obligation verbatim. The bound on speed is
        strict ("exceeds"), the bound on the distance strict ("below").
  No choice beyond the record's was needed: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_20_060_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The pedestrian quantified in the obligation. -/
def vPed : Arg := .var "p"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e3: the subject occupies a driveway-or-alley-entrance region or an alley region. -/
def inDrivewayOrAlley : Formula :=
  .or
    (.existsRegion (.lit "driveway_or_alley_entrance") "d" (.atom "rel_occupies" [vSubject, .var "d"] []))
    (.existsRegion (.lit "alley") "d" (.atom "rel_occupies" [vSubject, .var "d"] []))

/-- e5: the subject occupies a sidewalk region. -/
def onSidewalk : Formula :=
  .existsRegion (.lit "sidewalk") "s" (.atom "rel_occupies" [vSubject, .var "s"] [])

/-- Applicability: e2 (condition): within a business or residence district; e3 (condition): emerging or entering an alley, driveway or building; e5 (trigger): driving onto a sidewalk or onto the sidewalk area extending across any alleyway or driveway -/
def applicability : Formula :=
  .and (.asm "asm.business_or_residence_district") (.and inDrivewayOrAlley onSidewalk)

/-- e8: p is a pedestrian other than the subject. -/
def isOtherPedestrian : Formula :=
  .and (.not (.same vPed vSubject)) (.atom "ru_aggregate" [vPed, .lit "DEF-NRS-484A-165::pedestrian"] [])

/-- e7/e9: the danger of a crash — a constant-velocity closest approach within the horizon below
    the centre clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vPed] [pConflictHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vPed] [pConflictHorizon]) .lt
      pConflictCentreClearance)

/-- e6: still proceeding — speed above the halt tolerance. -/
def proceeding : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- Obligation: e6 (obligation): yielding; e7 (standard): the right-of-way; e8 (condition): to any pedestrian; e9 (standard): as may be necessary to avoid collision -/
def obligation : Formula :=
  .forallUser "p"
    (.implies isOtherPedestrian
      (.and (.not (.and proceeding conflict))
        (.not (.atom "rel_contact" [vSubject, vPed] []))))

def rule : Rule :=
  { id := "LVMC_11_20_060_o2"
    laws := ["LVMC-11-20-060"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.business_or_residence_district"]
    intentions := []
    operationalizations :=
      [ { standard := "right-of-way: DEF-NRS-484A-210 'approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: danger of a crash where the constant-velocity closest approach of centres is below a centre clearance within a time-to-collision horizon"
          surrogate := false }
      , { standard := "as may be necessary to avoid collision"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: yielding is necessary exactly where a collision would follow under constant velocities, a closest approach below the centre clearance within the horizon"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_20_060_o2
