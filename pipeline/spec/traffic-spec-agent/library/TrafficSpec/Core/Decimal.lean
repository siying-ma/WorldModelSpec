/-
  TrafficSpec.Core.Decimal
  Decimal-string comparison for CARLA numeric attributes.

  The adapter delivers numeric attributes as float-formatted strings, e.g.
  `("speed", "0.4003869891166687")`. Comparing those by string equality is a
  bug; parsing them into `Float` would drag non-computable reals into the
  kernel. Instead we parse into **milli-units** (thousandths) as an `Int`,
  truncating toward zero, which keeps every comparison exact and decidable.

  Accepted grammar:  `[+-]? digit+ ( '.' digit+ )?`
  Rejected (yields `none`, and predicates built on it are then `false`):
  exponent notation, a bare leading `.`, `inf`, `nan`, empty strings.
-/

namespace TrafficSpec.Decimal

/-- Read a maximal run of decimal digits. Returns the value, how many digits
    were consumed, and the remaining characters. -/
private def readDigits : List Char → Nat → Nat → Nat × Nat × List Char
  | [],      acc, n => (acc, n, [])
  | c :: cs, acc, n =>
      if c.isDigit then readDigits cs (acc * 10 + (c.toNat - '0'.toNat)) (n + 1)
      else (acc, n, c :: cs)

private def pow10 : Nat → Nat
  | 0     => 1
  | n + 1 => 10 * pow10 n

/-- Rescale a fractional part of `digits` digits to exactly three digits,
    truncating any excess precision. -/
private def fracToMilli (v : Nat) (digits : Nat) : Nat :=
  if digits ≤ 3 then v * pow10 (3 - digits) else v / pow10 (digits - 3)

private def signed (neg : Bool) (n : Nat) : Int :=
  if neg then -(Int.ofNat n) else Int.ofNat n

/-- Parse a decimal numeral into thousandths, truncating toward zero.
    `parseMilli "1.25" = some 1250`, `parseMilli "3" = some 3000`,
    `parseMilli "1e5" = none`. -/
def parseMilli (s : String) : Option Int :=
  let cs := s.trim.toList
  let (neg, body) :=
    match cs with
    | '-' :: rest => (true,  rest)
    | '+' :: rest => (false, rest)
    | _           => (false, cs)
  let (intPart, intDigits, rest) := readDigits body 0 0
  if intDigits == 0 then none
  else
    match rest with
    | []            => some (signed neg (intPart * 1000))
    | '.' :: fracCs =>
        let (fracVal, fracDigits, tail) := readDigits fracCs 0 0
        if fracDigits == 0 || !tail.isEmpty then none
        else some (signed neg (intPart * 1000 + fracToMilli fracVal fracDigits))
    | _             => none

/-- `s ≤ bound` in milli-units. An unparseable value compares `false`. -/
def leMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (v ≤ bound)
  | none   => false

/-- `s < bound` in milli-units. An unparseable value compares `false`. -/
def ltMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (v < bound)
  | none   => false

/-- `s ≥ bound` in milli-units. An unparseable value compares `false`. -/
def geMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (bound ≤ v)
  | none   => false

/-- `s > bound` in milli-units. An unparseable value compares `false`. -/
def gtMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (bound < v)
  | none   => false

/-- `|s| ≤ bound` in milli-units. Useful for `steer`, which is signed. -/
def absLeMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (v.natAbs ≤ bound.natAbs)
  | none   => false

/-- `|s| ≥ bound` in milli-units. The counterpart of `absLeMilli`, for saying
    that a signed channel (`steer`, `yaw_rate`) has moved off centre in either
    direction. -/
def absGeMilli (s : String) (bound : Int) : Bool :=
  match parseMilli s with
  | some v => decide (bound.natAbs ≤ v.natAbs)
  | none   => false

/-- Scale a parsed km/h value into milli-m/s, truncating toward zero: a posted
    limit arrives as a decimal string in km/h (`landmark_value`,
    `posted_limit_kph`) while `speed` is in m/s, so the two cannot be compared
    without this. `kphMilliToMps 50000 = 13888` (50 km/h ≈ 13.888 m/s).

    Division goes through `Nat` and the sign is reapplied, so the rounding
    direction does not depend on which `Int` division `/` denotes. -/
def kphMilliToMps (kphMilli : Int) : Int :=
  let m := Int.ofNat (kphMilli.natAbs * 1000 / 3600)
  if kphMilli < 0 then -m else m

/-- The milli-m/s value of a decimal km/h string, if it parses. -/
def kphStringToMps (s : String) : Option Int :=
  (parseMilli s).map kphMilliToMps

----------------------------------------------------------------------
-- Build-time tests. These fail the build if the parser regresses.
----------------------------------------------------------------------

-- integers, with and without sign
#guard parseMilli "0"    == some 0
#guard parseMilli "3"    == some 3000
#guard parseMilli "-2"   == some (-2000)
#guard parseMilli "+2"   == some 2000

-- fractional parts shorter than, equal to, and longer than three digits
#guard parseMilli "1.5"      == some 1500
#guard parseMilli "1.25"     == some 1250
#guard parseMilli "1.125"    == some 1125
#guard parseMilli "1.1259"   == some 1125   -- truncates, does not round
#guard parseMilli "-0.75"    == some (-750)

-- the exact shapes CARLA's `str(float)` produces
#guard parseMilli "0.0"                == some 0
#guard parseMilli "0.4003869891166687" == some 400
#guard parseMilli "7.799561977386475"  == some 7799
#guard parseMilli "17.021984100341797" == some 17021

-- surrounding whitespace is tolerated
#guard parseMilli " 2.5 " == some 2500

-- rejected shapes
#guard parseMilli ""      == none
#guard parseMilli "abc"   == none
#guard parseMilli "1e5"   == none
#guard parseMilli ".5"    == none
#guard parseMilli "1."    == none
#guard parseMilli "1.2.3" == none
#guard parseMilli "nan"   == none
#guard parseMilli "inf"   == none

-- comparisons, including the unparseable-is-false convention
#guard leMilli "0.4003869891166687" 500 == true
#guard leMilli "0.4003869891166687" 300 == false
#guard ltMilli "0.1" 100  == false          -- 100 milli is not < 100 milli
#guard leMilli "0.1" 100  == true
#guard geMilli "17.02" 17000 == true
#guard gtMilli "17.02" 17020 == false
#guard leMilli "nan" 1000 == false
#guard geMilli "nan" 0    == false
#guard absLeMilli "-0.25" 300 == true
#guard absLeMilli "-0.35" 300 == false
#guard absGeMilli "-0.35" 300 == true
#guard absGeMilli "-0.25" 300 == false

-- OpenDRIVE lane ids, as they appear inside a lane node name
#guard parseMilli "-1" == some (-1000)
#guard parseMilli "+2" == some 2000
#guard leMilli "-1" (-1000) == true        -- lane -1 is right of the reference line
#guard geMilli "+2" 1000    == true        -- lane +2 is left of it

-- km/h → milli-m/s, the conversion a posted-limit comparison needs
#guard kphMilliToMps 50000  == 13888
#guard kphMilliToMps 30000  == 8333
#guard kphMilliToMps 0      == 0
#guard kphStringToMps "50"   == some 13888
#guard kphStringToMps "50.0" == some 13888
#guard kphStringToMps "abc"  == none

end TrafficSpec.Decimal
