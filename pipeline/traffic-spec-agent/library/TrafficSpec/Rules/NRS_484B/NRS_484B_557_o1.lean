/-
  NRS_484B_557_o1 — NRS-484B-557

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): The Department of Transportation, and local authorities with the approval of the Department of Transportation, may designate dangerous highway grade crossings of railroads
    s2 (condition): and erect official traffic-control devices at such crossings directing a stop.
    s3 (condition): When such stop signs are erected
    s4 (subject): the driver of any vehicle
    s5 (obligation): shall stop within 50 feet but not less than 15 feet from the nearest track of such a grade crossing
    s7 (sibling): and afterward may proceed only
    s8 (sibling): upon exercising due care.

  Elements (span → atoms, derived):
    s1: atoms ['st.railway_crossing', 'st.on_way', 'st.highway'], derived []
    s2: atoms ['dev.stop_sign'], derived []
    s3: atoms ['dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['st.region_geometry', 'rel.occupies', 'st.railway_crossing'], derived ['drv.motion.complete_halt']

  Literals the text states (each written through its Units constructor):
    s5: 50 ft — 50 feet
    s5: 15 ft — 15 feet

  How each span is written.
    s4: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1–s3 (applicability, `entry x h r d`): some railway crossing `x` (st.railway_crossing, as the
      quantifier kind), highway `h` (st.highway, quantifier kind), travel region `r`
      (st.travel_region, quantifier kind) and stop sign `d` (dev.stop_sign, quantifier kind) such
      that the subject's footprint overlaps `x` here and did not at the previous observation
      (`rises (rel_occupies subject x)`), at that previous observation it occupied `r` and `d`
      governed `r` (`since (occupies x) (¬occupies x ∧ occupies r ∧ governs d r)`: with the rise,
      the only observation the `since` can find is the previous one), and `r` and `x` lie on `h`
      (`st_on_way`). Unknown overlap at the previous observation leaves the entry unknown (the rise
      is unknown); unobserved governance leaves `dev_governs` unknown.
    s5 (obligation): for every `x h r d` with `entry x h r d` (the whole selection re-bound, rule 3c),
      the search `since φ H` holds, where
        H (the act and place) = ¬occupies x ∧ distance(subject, x) ≤ 50 ft ∧ distance ≥ 15 ft ∧
                                drv_motion_complete_halt(subject, p.halt_speed_tolerance);
        φ (the observations the search passes through) = the entry itself (`rises (occupies x)`), or
          an observation of the stopping zone (¬occupies x ∧ distance ≤ 50 ft) that is not the
          subject's previous exit from x (`¬ rises (¬occupies x)`).
      The search therefore runs back from the observation before the entry through the stopping
      zone; it ends at the approach start (distance > 50 ft: φ and H false) or at the previous exit
      (φ false there, H still read); it reaches the trace start only inside the zone, where Core's
      `since` carries the unobserved past as unknown. A distance, overlap or speed unknown inside
      the search makes it unknown unless a halt nearer the entry was found (Kleene `or`).

  Choice the record left open (declared in `narrowings`):
    s5: the observation of the previous exit (the first one at which the subject no longer overlaps
      x) is itself searched for the halt; the search does not pass it.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_557_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5's literals. -/
def upperFigure : Term := .lit (Units.feet 50) .metre
def lowerFigure : Term := .lit (Units.feet 15) .metre

def vX : Arg := .var "x"
def vH : Arg := .var "h"
def vR : Arg := .var "r"
def vD : Arg := .var "d"

/-- The subject's footprint overlaps the crossing. -/
def onCrossing : Formula := .atom "rel_occupies" [vSubject, vX] []

/-- The ground distance from the subject's body to the crossing. -/
def distToCrossing : Term := .measure "st_region_geometry_distance" [vSubject, vX]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The entry of the subject into crossing `x` from a travel region `r` governed by stop sign `d`,
    `r` and `x` on the same highway `h`. -/
def entry : Formula :=
  .and (.rises onCrossing)
    (.and (.since onCrossing
            (.and (.not onCrossing)
              (.and (.atom "rel_occupies" [vSubject, vR] [])
                    (.atom "dev_governs" [vD, vR] []))))
      (.and (.atom "st_on_way" [vR, vH] [])
            (.atom "st_on_way" [vX, vH] [])))

/-- The selection of `x h r d` around a formula: some (applicability) or every (obligation). -/
def selectSome (φ : Formula) : Formula :=
  .existsRegion (.lit "railway_crossing") "x"
    (.existsRegion (.lit "highway") "h"
      (.existsRegion (.lit "travel_region") "r"
        (.existsDevice (.lit "stop_sign") "d" φ)))

def selectEvery (φ : Formula) : Formula :=
  .forallRegion (.lit "railway_crossing") "x"
    (.forallRegion (.lit "highway") "h"
      (.forallRegion (.lit "travel_region") "r"
        (.forallDevice (.lit "stop_sign") "d" φ)))

/-- Applicability: s1 (condition): The Department of Transportation, and local authorities with the approval of the Department of Transportation, may designate dangerous highway grade crossings of railroads; s2 (condition): and erect official traffic-control devices at such crossings directing a stop.; s3 (condition): When such stop signs are erected -/
def applicability : Formula := selectSome entry

/-- The stopping zone: not on the crossing, within the upper figure of it. -/
def inZone : Formula :=
  .and (.not onCrossing) (.cmp distToCrossing .le upperFigure)

/-- The act at its place: halted in the zone, at least the lower figure from the crossing. -/
def haltInZone : Formula :=
  .and inZone
    (.and (.cmp distToCrossing .ge lowerFigure)
          (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]))

/-- The observations the search passes through: the entry itself, or the stopping zone short of
    the subject's previous exit from the crossing. -/
def searchStep : Formula :=
  .or (.rises onCrossing)
      (.and inZone (.not (.rises (.not onCrossing))))

/-- Obligation: s5 (obligation): shall stop within 50 feet but not less than 15 feet from the nearest track of such a grade crossing -/
def obligation : Formula :=
  selectEvery (.implies entry (.since searchStep haltInZone))

def rule : Rule :=
  { id := "NRS_484B_557_o1"
    laws := ["NRS-484B-557"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s5"
          why := "The search's end at the subject's previous exit from the crossing is read as including the exit observation itself (the first observation at which it no longer overlaps the crossing): a halt there in the zone counts, and the search does not pass it."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_557_o1
