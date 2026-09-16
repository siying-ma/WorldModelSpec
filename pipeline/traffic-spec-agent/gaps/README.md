# The gap ledger

`ledger.jsonl` — one JSON object per line — is the list of things this pipeline
cannot express yet, who can fix each one, and whether the question is still
open. It is tracked in git because a gap outlives the run that found it: the
same ten gaps were re-derived by two separate runs before this file existed.

The schema, the closed sets of `owner` and `state`, and the invariants between
them live in [`scripts/gaps.py`](../scripts/gaps.py). This file says what the two
fields *mean* and how a gap moves.

## `owner` — which layer must change

Ordered by cost, and the last two are verdicts rather than costs.

| owner | what retiring it takes |
|---|---|
| `vocab` | one addition to `Core/Vocab.lean`, over keys the adapter already lifts. No new information enters Lean. |
| `adapter` | a key the scene graph already carries and `carla/adapter.py` does not lift. Needs a `carla/schema.json` entry and a `perception/portability.json` class with it. |
| `manifest` | a capture-level setting already recorded beside the frames. Enters Lean as a declared constant, never as a measurement. |
| `capture` | a datum the simulator has and the scene graph does not. Needs a collector of our own and a re-record; it cannot be recovered from captures already on disk. |
| `core` | the specification language itself — an operator, a `Trace` field, anything an `AtomicPred` cannot see because it is a `Scene → Bool`. Core is frozen, so this owner is a request for an explicit unfreeze. |
| `generator` | would require editing `carla_sgg/`, which is frozen **byte-wise**. Closed by construction: the resolution must re-route to `capture` or to `absent`. |
| `absent` | the simulator does not have it in any form. The clause it blocks is `unsupported`, and that verdict is now citable and disputable rather than inherited. |

`owner` is the same partition the perception ledger uses for where a datum stops
being available, so "what is missing" and "who can supply it" are answered in one
vocabulary.

## `state` — whether the question is open

```
proposed ──accept──> accepted ──the change lands──> retired
    │                    │
    ├──not a gap────────>├─> rejected              (closed, carries `resolution`)
    └──unreachable here─>└─> permanently_blocked   (closed, carries `resolution`)
```

- **`proposed`** — a planning session named it. No decision has been made. This
  is the only state an agent can create.
- **`accepted`** — the operator agrees it is real. Clauses may keep depending on
  it; planning them is still refused until it retires.
- **`retired`** — the change landed. Requires `retired_at` and `retired_by`.
  **This is the only automatic re-formalization trigger in the pipeline**: every
  clause whose row says `blocked_on_gap` on this gap is flipped back to
  `pending` by the harness, once per retirement, and the next iteration plans
  it. Nothing else is re-planned, so a capability change costs exactly the
  sessions it invalidates.
- **`rejected`** — not a gap; the reading behind it was wrong. Requires
  `resolution`.
- **`permanently_blocked`** — real, and unreachable at this owner. Requires
  `resolution`, which must say where it re-routes.

`rejected` and `permanently_blocked` are *answers*. A planning session that
re-proposes one is shown the `resolution` instead, and a clause blocked on one is
reported as a defect until its row moves to a terminal status. That is the
mechanism against the failure this ledger was written for: a run that spends its
later iterations reversing its own earlier verdicts with weaker readings, raising
cost while lowering quality, because the reasons were in prose nothing could act
on.

## Who may write what

| actor | may |
|---|---|
| planning session | append **proposals** to its own `iter_NNN/gaps.jsonl`, and append to an existing gap's `disputes`. Nothing else — it cannot choose an owner it likes, accept its own proposal, or retire anything. |
| harness | allocate ids, merge proposals as `proposed`, flip reopened coverage rows, refuse re-proposals of closed gaps |
| operator | change `state`, correct `owner`, write `resolution` — **on entries a planning session filed**. Never author an entry. |

**Only a planning session files a gap.** Every entry carries `proposed_in`, the
iteration that filed it, and `scripts/gaps.py::load` reports an entry whose
`proposed_in` is not of the form `<run>/iter_NNN`. The reason is not ceremony: a
hand-written entry turns this file from *a record of what the pipeline found*
into *a list somebody maintains*, and the two diverge the moment the library is
re-formalized — the hand-written version goes on asserting a gap no session
would file again. Analysis that predates this rule lives in
[`HISTORY.md`](HISTORY.md) as prose, blocks nothing, and must be re-filed by a
session before it can block anything.

A gap is retired by the change that retires it. Editing `state` to `retired`
without that change having landed is the one way to make this ledger lie.

## Filing a dispute

A closed gap cannot be re-proposed, but it can be argued with. Append a sentence
to its `disputes` array saying what evidence contradicts the resolution. A
dispute is one line and queues an operator decision; it does **not** authorise a
node. This is deliberately much cheaper than the alternative it replaces — a
coding session spent formalizing a weaker reading of the clause the gap blocks.
