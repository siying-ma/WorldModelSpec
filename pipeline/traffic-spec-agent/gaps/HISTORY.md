# Gap history — prose, NOT the ledger

Everything here was transcribed BY HAND from the `PLAN.md` files of an earlier
run, before the rule that only a planning session may file a ledger entry. It is
kept because the analysis is real and some of it took a constraint the agent
does not know (that `carla_sgg/` is frozen byte-wise) to reach.

**Nothing here is a ledger entry and nothing here blocks a clause.** A planning
session that meets one of these again files it itself, through
`iter_NNN/gaps.jsonl`, and the harness allocates the id. Until then the loop
does not know about them. Where an entry below carries a disposition, that
disposition is an operator's opinion waiting for a proposal to attach to — not
a decision already made.

| what is missing | suggested owner | disposition |
|---|---|---|
| governance from the approach side | `vocab` | open |
| counting the lanes of a carriageway | `vocab` | open |
| a heading reversal across frames | `core` | open |
| a non-ego actor's stoppedness | `core` | open |
| an unbound threshold test on a landmark's stated magnitude | `vocab` | open |
| telling parked map scenery from a road user | `vocab` | open |
| which off-roadway surface an actor is on | `capture` | re-routed |
| a stop-line association | `capture` | re-routed |
| an unbound landmark-applies predicate taking a code list | `vocab` | open |
| lift `landmark_orientation` | `adapter` | open |
| weather and road-surface state | `manifest` | open |

## Why each one

- **governance from the approach side** (`vocab`) — `governs`/`facingRedSignal` read the `controls` edge, which for a traffic light is the lanes the signal acts ON, not the lane a driver waits in. `travelsTo` is lifted and reaches from one to the other.
- **counting the lanes of a carriageway** (`vocab`) — Nothing answers "how many lanes beside mine"; expressing it by binding two lanes blows the grounding budget. Wants a predicate walking the same-direction chain internally.
- **a heading reversal across frames** (`core`) — An `SFProp` atom is a `Scene → Bool`, so no predicate compares one entity's heading at two frames. Needs a two-frame atom — a Core change.
- **a non-ego actor's stoppedness** (`core`) — `speed`/`vel_*` are ego-only; `pos_*` is lifted for every actor, so stoppedness is derivable across frames — the same single-scene-atom limit.
- **an unbound threshold test on a landmark's stated magnitude** (`vocab`) — Comparing a sign's stated value against a figure a rule names currently needs a landmark binder, which multiplies the grounding count several-fold.
- **telling parked map scenery from a road user** (`vocab`) — Scenery arrives with the same base classes and proximity edges as traffic. `carla_id` is lifted and absent on scenery, but no predicate distinguishes an absent attribute from a false one.
- **which off-roadway surface an actor is on** (`capture`) — Proposed as a generator extension; `carla_sgg/` is frozen byte-wise, so that route is closed. The waypoint's lane_type is on the base graph and reachable by a collector of our own.
- **a stop-line association** (`capture`) — Proposed as a generator extension; same freeze. `TrafficLight.get_stop_waypoints()` is a public API call a collector of ours can make at capture time.
- **an unbound landmark-applies predicate taking a code list** (`vocab`) — The existing predicate takes one catalogue code, so a rule covering two must disjoin. A list-taking variant is a small addition.
- **lift `landmark_orientation`** (`adapter`) — The generator writes it; the adapter drops it with the landmark geometry bundle. It is an enum saying which direction of travel a signal applies to and needs no coordinates.
- **weather and road-surface state** (`manifest`) — `carla.WeatherParameters` sets it and the capture script already writes it beside every capture; none of it reaches Lean, so clauses conditioned on conditions are applied unconditionally.

## The two marked `re-routed`

Both were proposed as changes to `carla_sgg/`, which this project holds frozen
byte-wise: the whole provenance argument rests on the generator being
unmodified, so a gap owned by it can never be scheduled. Neither is therefore
impossible — both are reachable by a collector of our own running against the
same simulation — but an agent cannot make that call, because it does not know
the freeze is a constraint rather than an inconvenience. When either is filed
again, that is the operator decision to make.
