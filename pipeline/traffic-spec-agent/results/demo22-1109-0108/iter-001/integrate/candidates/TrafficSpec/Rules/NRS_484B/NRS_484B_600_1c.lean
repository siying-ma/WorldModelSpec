/-
  NRS_484B_600_1c — NRS-484B-600-1c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (obligation): A rate of speed greater than that posted by a public authority for the particular portion of highway being traversed.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.standstill']
    s2: atoms ['dev.governs', 'dev.speed_limit_sign', 'kin.speed', 'rel.occupies', 'st.highway', 'st.on_way', 'st.travel_region'], derived []

  How each span is written.

    s1 — the subject. "a vehicle of any kind or character" is the defined term the table resolves
    to DEF-NRS-484A-320, written as the binder's class `ru_aggregate v "DEF-NRS-484A-320::vehicle"`:
    the aggregate id, never the classes the reading puts under it. "to drive or operate" is the
    vehicle's controlled motion, `drv.motion.standstill` read negated (the record's observable
    reading of agency): the duty binds a vehicle in motion at the observation, whoever controls it.

    s2 — the duty. `kin.speed` of `v` is the "rate of speed". The posted maximum is the stated value
    of a `dev.speed_limit_sign` whose kind is maximum, structure_maximum or zone — a sign of kind
    minimum is not read, the words forbidding only a speed greater than the posted one. The sign is
    tied to "the particular portion of highway being traversed" by `dev.governs`: a travel region
    (`st.travel_region`, the kind `dev.governs` ranges over, so a lane, a roadway, a shoulder, an
    intersection and the kinds refining them) that `v`'s footprint overlaps (`rel.occupies`), that
    region lying on a public way (`st.on_way` into a region of kind `st.highway`, carried by the
    quantifier's kind). No distance to the sign head is read, so `dev.position` is not used.

    Applicability: `v` is in motion and some such sign governs a travel region `v` occupies on a
    highway; where no such sign governs a region `v` occupies, the duty does not arise.
    Obligation: for EVERY such sign, `kin.speed` does not exceed its stated value — so the lowest
    posted maximum binds, as the record reads it. The whole selection of the region (the sign's
    kind, `dev.governs`, `rel.occupies`, `st.on_way` into a highway) is written again in the
    obligation, since the region bound in the applicability is not in its scope.

  Narrowings: none of my own. Every reading on a carried span here — the agency reading of
  "drive or operate", the presence of the sign as the evidence of its official posting, and the
  portion traversed as a governed travel region on a highway with the lowest posted maximum
  binding — is the blueprint's own narrowing, already on its record, and is not restated.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1c

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pStandstillSpeedTolerance : Term := .param "p.standstill_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: "to drive or operate" — the vehicle is in controlled motion at the observation, i.e. it is
    not at a standstill within the reading's speed tolerance. -/
def inMotion : Formula :=
  .not (.derived "drv_motion_standstill" [vV] [pStandstillSpeedTolerance])

/-- s2: the sign `d` states a posted maximum — its kind is maximum, structure_maximum or zone. -/
def postsMaximum (d : Arg) : Formula :=
  .or (.atom "dev_speed_limit_sign_kind" [d, .lit "maximum"] [])
    (.or (.atom "dev_speed_limit_sign_kind" [d, .lit "structure_maximum"] [])
      (.atom "dev_speed_limit_sign_kind" [d, .lit "zone"] []))

/-- s2: `d` governs "the particular portion of highway being traversed" — a travel region whose
    traffic `d` controls and which `v`'s footprint overlaps, that region lying on a highway. -/
def governsPortionTraversed (d : Arg) : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.and (.atom "dev_governs" [d, .var "r"] [])
      (.and (.atom "rel_occupies" [vV, .var "r"] [])
        (.existsRegion (.lit "highway") "w" (.atom "st_on_way" [.var "r", .var "w"] []))))

/-- s2: `d` is a posted maximum for the portion `v` traverses. -/
def postedMaximumHere (d : Arg) : Formula :=
  .and (postsMaximum d) (governsPortionTraversed d)

/-- Applicability: s1's driving or operating, and some posted maximum for the portion traversed. -/
def applicability : Formula :=
  .and inMotion
    (.existsDevice (.lit "speed_limit_sign") "d" (postedMaximumHere (.var "d")))

/-- Obligation: s2 (obligation): A rate of speed greater than that posted by a public authority for the particular portion of highway being traversed. -/
def obligation : Formula :=
  .forallDevice (.lit "speed_limit_sign") "d"
    (.implies (postedMaximumHere (.var "d"))
      (.cmp (.measure "kin_speed" [vV]) .le (.measure "dev_speed_limit_sign_value" [.var "d"])))

def rule : Rule :=
  { id := "NRS_484B_600_1c"
    laws := ["NRS-484B-600-1c"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- every reading on a carried span here is the blueprint's own; none is mine
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1c
