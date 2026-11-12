# Concept recheck — what does the contract decide on these facts?

## Role

A concept's contract states what the concept denotes. You are shown its current contract, what the
names its words use denote, the parameters it names with their values, and the facts of one
situation as the harness executed them. Decide what the contract's words decide on those facts at
the observation judged. You are shown no code and no earlier decision; you do not judge code,
propose a fix, or look for further situations.

## Inputs (injected below)

- **The contract** — the concept's meaning, and the definition it quotes when it has one.
- **The contracts** — what each atom and concept the contract's words use denotes.
- **The parameters** — each parameter the concept names: its unit, its meaning and its value here.
- **The executed facts** — the scenes in time order as the harness ran them, the grounding, the
  regions, the instant judged and the instance, in Core units, with the fields the concept reads
  that a scene leaves unobserved.
- **The question** — whether the concept is a formula or a quantity, and so what to answer.

### Contract

`drv.motion.right_turn_from_onset`: Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle: at the beginning itself where the heading change there, which is zero, already reaches it, and otherwise at the first later observation of the same stretch at which it does. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, a heading change accumulated over an earlier stretch included, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle.


### The contracts of the names the contract's words use

| id | contract |
|---|---|
| `drv.motion.turning_right` | Road user a is turning to the right at an observation: it moves and its heading turns to the right. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or below the negative of the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the right. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `kin.time` | instant of observation of a scene |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |


### Parameters

- `turn_angle` (deg): the heading change below which turning counts as no change of course; its value here: 0 deg
- `yaw_tolerance` (deg/s): the yaw rate magnitude below which a change of heading counts as none; its value here: 1 deg/s
- `speed_tolerance` (m/s): the speed at or below which the road user counts as at rest; its value here: 0.1 m/s
- `step` (ms): the step bound of the heading integration, the largest interval between consecutive observations integrated across; its value here: 500 ms


### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second).

- grounding: `a` = track 1
- the observation judged: t = 750 ms
- parameters: `turn_angle` = 0 deg, `yaw_tolerance` = 1 deg/s, `speed_tolerance` = 0.1 m/s, `step` = 500 ms

Scene t = 0 ms:
- track 1: kin.speed 5; kin.yaw_rate 0
- occupancy derived from the geometry before running: none
Scene t = 250 ms:
- track 1: kin.speed 5; kin.yaw_rate -20
- occupancy derived from the geometry before running: none
Scene t = 500 ms:
- track 1: kin.speed 5; kin.yaw_rate 0
- occupancy derived from the geometry before running: none
Scene t = 750 ms (the observation judged):
- track 1: kin.speed 5; kin.yaw_rate -20
- occupancy derived from the geometry before running: none


### The question

The concept is a formula. Answer whether the contract's words, read on these facts at the observation judged, hold, fail, or leave it undecided.


## How to decide

1. **Read the contract's words on the facts.** Apply them to the grounding, the regions and the
   instance named, at the observation judged, using what the contracts above say each name denotes
   and the parameter values given.
2. **A formula.** Answer `holds` when the contract's words, under every reasonable reading of them,
   say the concept is true of these facts; `fails` when, under every reasonable reading, they say it
   is false.
3. **A quantity.** Answer the interval the contract's words put the value in on these facts: `lo`
   and `hi`, each `[value, unit]` in a unit of the value's dimension, both ends included, `lo` at
   most `hi`; a value the words fix exactly is an interval whose ends are equal. The interval spans
   every value a reasonable reading of the words allows.
4. **undecided** — the words decide nothing here: reasonable readings of them give different
   answers on these facts, or the answer turns on a fact the facts leave unobserved. Never guess an
   answer the words do not give. Say which in `undecided_by`: `facts` when the answer turns on a
   fact the facts leave unobserved, `contract` when the facts are complete and the readings of the
   words still differ.
5. **Facts only.** Decide on the executed facts. Keys listed as unverified annotations are no fact
   of the situation.
6. Quote, verbatim, the words of the contract that decide your answer (for `undecided`, the words
   that leave it open). Do not use knowledge of any law or jurisdiction.

## Output

JSON, this schema and nothing more. For a formula:

```
{"verdict": "holds | fails", "reason": "<one or two sentences>", "quote": "<the contract's deciding words, verbatim>"}
{"verdict": "undecided", "undecided_by": "facts | contract", "reason": "<one or two sentences>", "quote": "<the contract's words that leave it open, verbatim>"}
```

For a quantity, an interval, or `undecided`:

```
{"interval": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}, "reason": "<one or two sentences>", "quote": "<the contract's deciding words, verbatim>"}
{"verdict": "undecided", "undecided_by": "facts | contract", "reason": "<one or two sentences>", "quote": "<the contract's words that leave it open, verbatim>"}
```

## Finish

Finish when the JSON is written. No commentary outside it.
