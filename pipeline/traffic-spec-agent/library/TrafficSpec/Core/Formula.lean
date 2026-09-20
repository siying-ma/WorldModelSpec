/-
  TrafficSpec.Core.Formula
  The specification language, as data.

  A rule is an AST, not a Lean proposition, for three downstream reasons: the gate inspects it
  (which atoms, which operators, which parameters, any bare literal), the export serializes it for
  program synthesis, and the review phase mutates it. Variables are strings bound by the grounding
  to tracks, and by the bounded quantifiers below to regions and devices of a kind.

  Atoms and derived concepts are referenced BY NAME (the Lean definition names of Atoms.lean and
  Derived.lean, `family_name`), with arguments that are variables, enumeration values spelled as in
  ATOMS.md, or naturals. Semantics.lean dispatches the names; the doctor checks every name resolves.

  Deliberately absent: `next` (frame-relative and meaningless under irregular sampling), any
  numeric literal without a unit, any way to call an arbitrary Lean function.
-/
import TrafficSpec.Core.Params
import TrafficSpec.Core.Time
import TrafficSpec.Core.World

namespace TrafficSpec

/-- A value a formula variable can denote. -/
inductive Val
  | track (t : TrackId)
  | region (r : RegionId)
  | device (d : DeviceId)
  deriving Repr, DecidableEq, Inhabited

/-- Variable bindings (the grounding's output; `Env` is the world's environment record). -/
structure Binding where
  binds : List (String × Val) := []
  deriving Repr, Inhabited

namespace Binding
def lookup (e : Binding) (n : String) : Option Val := (e.binds.find? (·.1 == n)).map (·.2)
def bind (e : Binding) (n : String) (v : Val) : Binding := ⟨(n, v) :: e.binds.filter (·.1 != n)⟩
def track (e : Binding) (n : String) : Option TrackId :=
  match e.lookup n with | some (.track t) => some t | _ => none
def region (e : Binding) (n : String) : Option RegionId :=
  match e.lookup n with | some (.region r) => some r | _ => none
def device (e : Binding) (n : String) : Option DeviceId :=
  match e.lookup n with | some (.device d) => some d | _ => none
end Binding

/-- An argument to an atom or a derived concept. -/
inductive Arg
  | var (name : String)      -- a bound variable
  | lit (value : String)     -- an enumeration value, spelled as in the ontology
  | nat (n : Nat)
  deriving Repr, DecidableEq, Inhabited

inductive CmpOp
  | lt | le | eq | ge | gt
  deriving Repr, DecidableEq, Inhabited

def CmpOp.apply : CmpOp → Q → Q → Bool
  | .lt, a, b => Q.lt a b
  | .le, a, b => Q.le a b
  | .eq, a, b => Q.eq a b
  | .ge, a, b => Q.ge a b
  | .gt, a, b => Q.gt a b

mutual
  /-- A quantity. -/
  inductive Term
    | lit (q : Q) (unit : PUnit')                            -- written through a Units constructor
    | param (name : ParamName)                               -- a reading parameter
    | measure (atom : String) (args : List Arg)              -- a measured atom (Option Q or Option Nat)
    | quantity (concept : String) (args : List Arg) (params : List Term)   -- a Q-valued derived concept
    | distanceWhile (subject : String) (φ : Formula)         -- drv.distance_while: path length over which φ has held
    | add (a b : Term)
    | sub (a b : Term)
    | mul (a b : Term)
    | div (a b : Term)
    | neg (a : Term)
    | abs (a : Term)
  /-- A three-valued statement about the trace at an instant. -/
  inductive Formula
    | tt
    | ff
    | atom (name : String) (args : List Arg) (params : List Term)   -- a Boolean atom; params for tolerances
    | cmp (lhs : Term) (op : CmpOp) (rhs : Term)
    | asm (id : AsmId)
    | not (φ : Formula)
    | and (φ ψ : Formula)
    | or (φ ψ : Formula)
    | implies (φ ψ : Formula)
    | always (φ : Formula)                                    -- from now to the end of the trace
    | eventually (φ : Formula)
    | until (φ ψ : Formula)                                   -- strong until, future
    | since (φ ψ : Formula)                                   -- past mirror of until
    | holdsFor (m : Measure) (d : Term) (subject : String) (φ : Formula)   -- φ at every observation in the window behind
    | within (m : Measure) (d : Term) (subject : String) (φ : Formula)     -- φ at some observation in the window ahead
    | untilWithin (m : Measure) (d : Term) (subject : String) (φ ψ : Formula)
    | count (edge : Formula) (sinceφ : Formula) (op : CmpOp) (n : Nat)   -- rising edges of `edge` since `sinceφ` became true (start of its latest run)
    | derived (concept : String) (args : List Arg) (params : List Term)   -- a Boolean derived concept
    | rule (id : String) (map : List (String × String))       -- another rule's obligation verdict
    | existsRegion (kind : StructureKind) (var : String) (φ : Formula)
    | forallRegion (kind : StructureKind) (var : String) (φ : Formula)
    | existsDevice (kind : DeviceKind) (var : String) (φ : Formula)
    | forallDevice (kind : DeviceKind) (var : String) (φ : Formula)
end

deriving instance Repr for Term
deriving instance Repr for Formula
instance : Inhabited Formula := ⟨.tt⟩
instance : Inhabited Term := ⟨.lit Q.zero .count⟩

namespace Formula
-- The atom names a formula reads (for the gate, the manifest and the export).
mutual
  partial def termAtoms : Term → List String
    | .measure a _ => [a]
    | .quantity c _ ps => c :: (ps.flatMap termAtoms)
    | .distanceWhile _ φ => "drv_distance_while" :: atoms φ
    | .add a b | .sub a b | .mul a b | .div a b => termAtoms a ++ termAtoms b
    | .neg a | .abs a => termAtoms a
    | _ => []
  partial def atoms : Formula → List String
    | .atom n _ ps => n :: ps.flatMap termAtoms
    | .cmp l _ r => termAtoms l ++ termAtoms r
    | .not φ | .always φ | .eventually φ => atoms φ
    | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ => atoms φ ++ atoms ψ
    | .holdsFor _ d _ φ | .within _ d _ φ => termAtoms d ++ atoms φ
    | .untilWithin _ d _ φ ψ => termAtoms d ++ atoms φ ++ atoms ψ
    | .count e s _ _ => atoms e ++ atoms s
    | .derived c _ ps => c :: ps.flatMap termAtoms
    | .existsRegion _ _ φ | .forallRegion _ _ φ | .existsDevice _ _ φ | .forallDevice _ _ φ => atoms φ
    | _ => []
end

-- The reading parameters a formula names.
mutual
  partial def termParams : Term → List ParamName
    | .param n => [n]
    | .quantity _ _ ps => ps.flatMap termParams
    | .distanceWhile _ φ => params φ
    | .add a b | .sub a b | .mul a b | .div a b => termParams a ++ termParams b
    | .neg a | .abs a => termParams a
    | _ => []
  partial def params : Formula → List ParamName
    | .atom _ _ ps => ps.flatMap termParams
    | .cmp l _ r => termParams l ++ termParams r
    | .not φ | .always φ | .eventually φ => params φ
    | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ => params φ ++ params ψ
    | .holdsFor _ d _ φ | .within _ d _ φ => termParams d ++ params φ
    | .untilWithin _ d _ φ ψ => termParams d ++ params φ ++ params ψ
    | .count e s _ _ => params e ++ params s
    | .derived _ _ ps => ps.flatMap termParams
    | .existsRegion _ _ φ | .forallRegion _ _ φ | .existsDevice _ _ φ | .forallDevice _ _ φ => params φ
    | _ => []
end

/-- The rules a formula composes. -/
partial def composed : Formula → List String
  | .rule id _ => [id]
  | .not φ | .always φ | .eventually φ => composed φ
  | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ => composed φ ++ composed ψ
  | .holdsFor _ _ _ φ | .within _ _ _ φ => composed φ
  | .untilWithin _ _ _ φ ψ => composed φ ++ composed ψ
  | .count e s _ _ => composed e ++ composed s
  | .existsRegion _ _ φ | .forallRegion _ _ φ | .existsDevice _ _ φ | .forallDevice _ _ φ => composed φ
  | _ => []

/-- The assumptions a formula reads. -/
partial def assumptions : Formula → List AsmId
  | .asm id => [id]
  | .not φ | .always φ | .eventually φ => assumptions φ
  | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ => assumptions φ ++ assumptions ψ
  | .holdsFor _ _ _ φ | .within _ _ _ φ => assumptions φ
  | .untilWithin _ _ _ φ ψ => assumptions φ ++ assumptions ψ
  | .count e s _ _ => assumptions e ++ assumptions s
  | .existsRegion _ _ φ | .forallRegion _ _ φ | .existsDevice _ _ φ | .forallDevice _ _ φ => assumptions φ
  | _ => []
end Formula

end TrafficSpec
