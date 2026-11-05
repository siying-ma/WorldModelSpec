/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): It is unlawful for any person to drive or operate
    s2 (subject): a vehicle of any kind or character
    s3 (boilerplate): at:
    s4 (condition): In any event,
    s5 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    s1: atoms ['kin.velocity'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s5: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s5: 80 mph — 80 miles per hour

  How each span is written:
    s2 (subject) → `clsSubject`: the atom `ru_aggregate` of the binder with the aggregate id
      `DEF-NRS-484A-320::vehicle` as its literal argument, never the classes the definition covers.
    s1 (trigger) → `applicability` = `inMotion`: the record reads ‘to drive or operate’ through the
      vehicle's controlled motion (its own `observable_reading` narrowing on s1, not restated here),
      and maps the span to kin.velocity alone. The velocity vector is read by its two components and
      the span holds where the vector is non-zero — the subject is moving — which is decided only
      where both components are observed, so an unobserved velocity leaves the rule unengaged rather
      than engaged. The sum of the magnitudes of the components is one comparison, so the span is one
      leaf: no component is tested on its own. Nothing of ‘on the road’ is added: s1 claims no
      structure or occupancy atom, and no atom the node does not claim enters a formula.
    s4 (condition) → nothing: the node carries it as a residue (declared below, verbatim).
    s5 (obligation) → `obligation`: kin.speed at or below the figure the text itself states,
      80 miles per hour, carried as a literal through `Units.mph`. The duty is judged at every
      observation — the episode is violated where any instant is — which is the record's
      ‘At no observation does the subject's rate of speed exceed 80 miles per hour.’

  No narrowing is declared: s1, s2 and s4 decide when the rule applies and are carried as the node
  maps them, and s5 is written with the atom and the figure the node states.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- Zero, in the unit of a velocity component and of a speed. -/
def zeroSpeed : Term := .lit Q.zero .metrePerSecond

/-- The east component of the subject's velocity (kin.velocity). -/
def velocityX : Term := .measure "kin_velocity" [vSubject, .lit "x"]

/-- The north component of the subject's velocity (kin.velocity). -/
def velocityY : Term := .measure "kin_velocity" [vSubject, .lit "y"]

/-- The subject's rate of speed (kin.speed). -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- 80 miles per hour, the figure s5 states. -/
def eightyMilesPerHour : Term := .lit (Units.mph 80) .metrePerSecond

/-- s1: the subject's velocity is non-zero — the vehicle is in controlled motion, so it is being
    driven or operated. -/
def inMotion : Formula :=
  .cmp (.add (.abs velocityX) (.abs velocityY)) .gt zeroSpeed

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: s1 (trigger): It is unlawful for any person to drive or operate; s4 (condition): In any event, -/
def applicability : Formula := inMotion

/-- Obligation: s5 (obligation): a rate of speed greater than 80 miles per hour. -/
def obligation : Formula :=
  .cmp speed .le eightyMilesPerHour

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["‘In any event’ says that this bound holds whatever the circumstances the other paragraphs of subsection 1 speak of; it states no observable condition of its own and removes none, so the duty is the same whether or not these words are read."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
