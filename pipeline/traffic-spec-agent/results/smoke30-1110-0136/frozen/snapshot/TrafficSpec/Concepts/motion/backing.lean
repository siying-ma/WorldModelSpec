/-
  drv.motion.backing — A road user moves backwards at the observation: the component of its velocity (kin.velocity) along the direction it points (kin.heading) is below minus `tol`, a tolerance that names only the source's speed resolution. Not denoted: the gear selected, since a vehicle in reverse gear standing still is not backing and one rolling backwards in a forward gear is; motion across the direction it points, such as a sideways slide; a road user standing still.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    the direction it points (kin.heading): atoms ['kin.heading'], concepts []

  Written: the component along the heading is the dot product vx·hx + vy·hy of `kin_velocity` with
  `kin_heading` (read normalised by Core, so a unit vector); the body is that component strictly
  below `-tol` (the contract's "below"). The gear, sideways motion and standing still need no clause:
  a sideways or zero velocity has a zero component along the heading, which is not below `-tol`.
  No narrowing: the contract dictates every choice.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.backing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- A component of a vector atom of `x`. -/
def comp (atom sel : String) : Term := .measure atom [aX, .lit sel]

/-- The component of the velocity along the heading: the dot product of `kin.velocity` with the
    unit vector `kin.heading` reads (m/s, positive forwards, negative backwards). -/
def along : Term :=
  .add (.mul (comp "kin_velocity" "x") (comp "kin_heading" "x"))
       (.mul (comp "kin_velocity" "y") (comp "kin_heading" "y"))

/-- Backing: that component strictly below minus the speed resolution. -/
def body : Formula := .cmp along .lt (.neg pTol)

def concept : Concept :=
  { id := "drv.motion.backing"
    contract := "A road user moves backwards at the observation: the component of its velocity (kin.velocity) along the direction it points (kin.heading) is below minus `tol`, a tolerance that names only the source's speed resolution. Not denoted: the gear selected, since a vehicle in reverse gear standing still is not backing and one rolling backwards in a forward gear is; motion across the direction it points, such as a sideways slide; a road user standing still."
    definition := none
    args := [("x", .track)]
    params := [⟨"tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.backing
