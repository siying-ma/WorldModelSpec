"""What a run's sessions cost, and the run-wide limits on that spend.

Every session of either vendor appends rows to `results/<run>/usage.jsonl`: its label, vendor,
model, effort, input, cached-input, output and reasoning tokens, and its cost in USD — a Claude
session's as its CLI reports it, an OpenAI call's from the operator's price table
(`config/model_prices.json`: USD per million input, cached-input and output tokens; reasoning tokens
are billed as output). The table is keyed by the model name the run requests (the run's options), and
that name alone prices a call, at its reservation and at its settlement; the dated model id the API
reports is never looked up. A requested name without a price launches no call.

Every request is reserved before it is sent, under one lock shared by every worker of the run, and
written to `usage.jsonl` as a `pending` row naming its vendor and its reservation:
- an OpenAI call reserves its worst case: the prompt's tokens at the input price plus the call's
  output-token limit at the output price (the input part is an estimate, three characters a token);
- a Claude session reserves its own cap, which its role sets (`session_budget_usd` for a plan or
  coding session, `repair_budget_usd` for a repair, `judge_budget_usd` for a tool-less answer) and
  which the CLI checks after each turn, so a session may pass its reservation by up to one turn.
What became of the request is written as one more row naming it, before the spend is counted:
- `settled`, with its actual cost: an answer with its cost, or a request known not to have been
  executed (refused before execution: zero);
- `unknown`: the request may have run and its cost was lost (a timeout after sending, a dropped
  connection, an ambiguous server error, an answer without its cost, the process stopping during the
  call). It stays counted at its reservation; a missing cost is never counted as zero.
A request's rows fold into one state, the same way live and on reload: `pending` and `unknown` count
the reservation once, and a `settled` row replaces any earlier state with its cost. The first
settlement of a request is final; a later one changes nothing. A pending request with no later row
(the process ended during the call) counts at its reservation, never as zero.

The limits: one per vendor (`openai_budget_usd`, `claude_budget_usd`), one over both
(`total_budget_usd`), and one per role whose requests a label names (`aggregate_verifier_budget_usd`
over the aggregate verifier's, labels containing `ROLE_AGGREGATE`; `behaviour_review_budget_usd` over
the behaviour reviewer's, labels containing `ROLE_BEHAVIOUR_REVIEW`; this run's spend only), each over this run's spend plus that of the runs named in `budget_peers`, whose
usage files are read again at every reservation (their pending rows count as spent: this process
cannot wait on them). Runs that share a limit name the same group (`budget_peers`, the run itself
counted or not), and every reservation of the group takes one file lock
(`results/.budget-<group>.lock`) across the check and the pending row it writes, so two runs, in one
process or several, never both reserve the same remainder. A request that does not fit waits while requests of this process are in flight
whose settlement may free room, up to `max_wait` seconds; it raises `BudgetPaused` when none is in
flight or the wait ends, as does an API answer of exhausted quota: the run pauses, resumable once the
operator raises the limit. It is never a law's failure, a deferral or a spent attempt.

The run-wide send gate. A `stop` row (`STOP_REASONS`: an answer from another model or channel than
the run fixed, a settled cost beyond its reservation, a kept answer lost or changed) stops every real
send of the run, of every role: every reservation reads the run's usage file under the run's lock
(`results/<run>/.usage.lock`, which every writer of the file takes, in any process) and is refused
(`RunStopped`, a pause) while a stop has no `acknowledged` row. A settlement and the stop it causes
are written in one hold of that lock, so no reservation in between sees the one without the other. A
reserved request reads the gate again when its transport is about to start (`start`): a stop written in
between refuses it, and it is settled at zero as never started; once started it is settled by what is
known of it, whatever stop follows, never as not executed. An acknowledgement confirms one stop, bound
to the operator's record by its digest; it changes no other row: no spend, no reservation, no other
stop, no limit. Stop and acknowledgement rows carry no spend.
"""
from __future__ import annotations

import contextlib
import fcntl
import hashlib
import json
import threading
import time
import uuid
from pathlib import Path

from . import jsonl, paths

CHARS_PER_TOKEN = 3
#: The label part that names the aggregate verifier's requests.
ROLE_AGGREGATE = "/aggregates/verify_"
#: The label part that names the behaviour reviewer's requests.
ROLE_BEHAVIOUR_REVIEW = "/review/bp_"
VENDORS = ("openai", "anthropic")
#: Why a run's sends are stopped until the operator acknowledges it.
STOP_REASONS = ("wrong_model", "wrong_channel", "bound_violated", "response_missing")
#: The usage rows that record the send gate, not a request: they carry no spend.
GATE_STATES = ("stop", "acknowledged")


class RunPaused(RuntimeError):
    """A request refused before anything was sent: the run pauses. Never a law's failure, a deferral
    or a spent attempt."""


class BudgetPaused(RunPaused):
    """A limit does not admit another request: the run pauses until the operator raises it."""


class RunStopped(RunPaused):
    """A stop row without its acknowledgement: no request of the run is sent, of any role, until the
    operator acknowledges that stop. Not a limit: raising a limit never lifts it."""


class AcknowledgeRefused(ValueError):
    """An acknowledgement that may not be written: nothing was written."""


def lock_file(usage_file: Path) -> Path:
    return Path(usage_file).with_name(".usage.lock")


@contextlib.contextmanager
def run_lock(usage_file: Path):
    """The run's usage lock, across processes: held by every writer of the usage file and by every
    reservation across its stop check and its pending row."""
    f = lock_file(usage_file)
    f.parent.mkdir(parents=True, exist_ok=True)
    with open(f, "a") as fh:
        fcntl.flock(fh, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(fh, fcntl.LOCK_UN)


def gate_rows(rows: list[dict]) -> tuple[dict[str, dict], dict[str, dict]]:
    """(stop id → its stop row, stop id → its first acknowledgement row) of a run's usage rows."""
    stops, acks = {}, {}
    for r in rows:
        if r.get("state") == "stop" and r.get("stop"):
            stops.setdefault(r["stop"], r)
        elif r.get("state") == "acknowledged" and r.get("stop"):
            acks.setdefault(r["stop"], r)
    return stops, acks


def open_stops(rows: list[dict]) -> list[dict]:
    """The stop rows no acknowledgement confirms, in the order they were written."""
    stops, acks = gate_rows(rows)
    return [r for k, r in stops.items() if k not in acks]


def stop_row(reason: str, why: str, **fields) -> dict:
    if reason not in STOP_REASONS:
        raise ValueError(f"unknown stop reason {reason!r}")
    return {"state": "stop", "stop": "stop-" + uuid.uuid4().hex[:16], "reason": reason, "why": why, **fields,
            "at": time.strftime("%Y-%m-%dT%H:%M:%S")}


def write_stop(usage_file: Path, reason: str, why: str, **fields) -> dict:
    """Write one stop row under the run's lock; returns it."""
    row = stop_row(reason, why, **fields)
    with run_lock(usage_file):
        jsonl.append_atomic(Path(usage_file), row)
    return row


def acknowledge(usage_file: Path, stop_id: str, record_sha: str, record: dict, refusal=None) -> tuple[dict, bool]:
    """Confirm one stop: an `acknowledged` row naming it and the operator's record (its digest), under
    the run's lock. The same record again is a no-op (returns the row written before, True); another
    record for a stop already acknowledged, or a stop the file does not hold, is refused. `refusal`,
    called under the lock with the usage rows, may refuse it (`AcknowledgeRefused`) before anything is
    written. Nothing else is written or changed."""
    with run_lock(usage_file):
        rows = jsonl.read_strict(Path(usage_file))
        stops, acks = gate_rows(rows)
        if stop_id not in stops:
            raise AcknowledgeRefused(f"the run's usage file holds no stop `{stop_id}`")
        if stop_id in acks:
            if acks[stop_id].get("record_sha") == record_sha:
                return acks[stop_id], True
            raise AcknowledgeRefused(f"stop `{stop_id}` was acknowledged with another record ({acks[stop_id].get('record_sha')})")
        why = refusal(rows, stops[stop_id]) if refusal else None
        if why:
            raise AcknowledgeRefused(why)
        row = {"state": "acknowledged", "stop": stop_id, "reason": stops[stop_id].get("reason"), "record_sha": record_sha,
               "record": record, "at": time.strftime("%Y-%m-%dT%H:%M:%S")}
        jsonl.append_atomic(Path(usage_file), row)
        return row, False


def _stopped_why(stopped: list[dict]) -> str:
    """Why the run's sends are refused: every open stop, by id and reason."""
    return (f"the run's sends are stopped until the operator acknowledges each open stop: "
            + "; ".join(f"`{x['stop']}` ({x.get('reason')}: {str(x.get('why', ''))[:200]})" for x in stopped))


def fold(rows: list[dict]) -> tuple[dict[str, float], dict[str, float], set[str], dict[str, str]]:
    """The spend over `usage.jsonl` rows: (spent by vendor, the requests whose cost is unknown with
    their reservations, the requests settled, the vendor of each unresolved request). Each request's
    rows fold into one state: its first `settled` row counts its cost; otherwise (`pending`,
    `unknown`) its reservation counts once. A settled row naming no request (written before requests
    were named) counts its own cost, a missing cost as zero, since nothing reserved it."""
    reservation: dict[str, float] = {}
    vendor_of: dict[str, str] = {}
    settled: dict[str, tuple[str, float]] = {}
    spent = {v: 0.0 for v in VENDORS}
    for r in rows:
        req, state, vendor = r.get("request"), r.get("state"), r.get("vendor") or "openai"
        if state in GATE_STATES:
            continue
        if state in ("pending", "unknown") and req:
            reservation.setdefault(req, float(r.get("reserved_usd") or 0))
            vendor_of.setdefault(req, vendor)
        elif req:
            if req not in settled:
                settled[req] = (vendor, float(r.get("cost_usd") or 0))
        else:
            spent[vendor] = spent.get(vendor, 0.0) + float(r.get("cost_usd") or 0)
    for vendor, cost in settled.values():
        spent[vendor] = spent.get(vendor, 0.0) + cost
    unresolved = {q: v for q, v in reservation.items() if q not in settled}
    for q, v in unresolved.items():
        spent[vendor_of[q]] = spent.get(vendor_of[q], 0.0) + v
    return spent, unresolved, set(settled), {q: vendor_of[q] for q in unresolved}


class Budget:
    def __init__(self, usage_file: Path, limit_usd: float | None, prices: dict, *, claude_limit_usd: float | None = None,
                 total_limit_usd: float | None = None, peers: tuple[Path, ...] = (), max_wait: float = 0.0,
                 group_lock: Path | None = None, role_limits: dict[str, float] | None = None):
        self.file, self.prices, self.peers, self.max_wait = usage_file, prices, tuple(peers), float(max_wait)
        self.group_lock = group_lock
        self.limits = {"openai": limit_usd, "anthropic": claude_limit_usd}
        self.total_limit = total_limit_usd
        #: a label part → the limit over the requests whose label contains it
        self.role_limits = {k: v for k, v in (role_limits or {}).items() if v is not None}
        self.labels: dict[str, str] = {}     # requests in flight in this process → their label
        self.lock = threading.Condition()
        #: requests in flight in this process: (vendor, reservation), held, not yet spent
        self.reserved: dict[str, tuple[str, float]] = {}
        self.by_vendor, self.unresolved, self.settled, self.unresolved_vendor = fold(jsonl.read_strict(usage_file))

    @property
    def limit(self) -> float | None:
        """The second vendor's limit."""
        return self.limits["openai"]

    @property
    def spent(self) -> float:
        """This run's spend over both vendors, unknown requests at their reservation."""
        return sum(self.by_vendor.values())

    def price(self, model: str) -> dict:
        p = self.prices.get(model)
        if p is None:
            raise BudgetPaused(f"no price for `{model}` in the price table: no OpenAI call is launched without one")
        return p

    def cost(self, model: str, usage: dict) -> float:
        p = self.price(model)
        inp = int(usage.get("input_tokens") or 0)
        cached = int((usage.get("input_tokens_details") or {}).get("cached_tokens") or 0)
        out = int(usage.get("output_tokens") or 0)
        return ((inp - cached) * p["input_usd_per_million"] + cached * p["cached_input_usd_per_million"]
                + out * p["output_usd_per_million"]) / 1e6

    def _peer_spend(self) -> dict[str, float]:
        out = {v: 0.0 for v in VENDORS}
        for f in self.peers:
            if f.exists():
                for v, x in fold(jsonl.read_strict(f))[0].items():
                    out[v] = out.get(v, 0.0) + x
        return out

    def _role_spend(self, role: str) -> float:
        """This run's spend on the requests whose label contains `role`, in flight included."""
        rows = [r for r in jsonl.read_strict(self.file) if role in (r.get("label") or "")]
        names = {r.get("request") for r in rows if r.get("request")}
        rows += [r for r in jsonl.read_strict(self.file) if r.get("request") in names and role not in (r.get("label") or "")]
        done = sum(fold(rows)[0].values())
        return done + sum(a for tok, (_w, a) in self.reserved.items() if role in self.labels.get(tok, "") and tok not in names)

    def _short(self, vendor: str, amount: float, label: str = "") -> str | None:
        """Why `amount` more of `vendor` does not fit, or None. Called under the lock."""
        for role, lim in self.role_limits.items():
            if role in label:
                held = self._role_spend(role)
                if held + amount > lim:
                    return (f"the budget of ${lim:.2f} on requests labelled `{role}` does not admit another request: "
                            f"held ${held:.2f}, this request's reservation ${amount:.2f}")
        peer = self._peer_spend()
        flight = {v: sum(a for (w, a) in self.reserved.values() if w == v) for v in VENDORS}
        held = {v: self.by_vendor.get(v, 0.0) + peer.get(v, 0.0) + flight.get(v, 0.0) for v in VENDORS}
        lim = self.limits.get(vendor)
        if lim is not None and held[vendor] + amount > lim:
            return (f"the {vendor} budget of ${lim:.2f} does not admit another request: spent ${self.by_vendor.get(vendor, 0.0) + peer[vendor]:.2f}, "
                    f"in flight ${flight[vendor]:.2f}, this request's reservation ${amount:.2f}")
        if self.total_limit is not None and sum(held.values()) + amount > self.total_limit:
            return (f"the budget of ${self.total_limit:.2f} over both vendors does not admit another request: spent "
                    f"${self.spent + sum(peer.values()):.2f}, in flight ${sum(flight.values()):.2f}, this request's reservation ${amount:.2f}")
        return None

    @contextlib.contextmanager
    def _group(self):
        """The group's file lock, held across a check and the pending row it writes."""
        if self.group_lock is None:
            yield
            return
        self.group_lock.parent.mkdir(parents=True, exist_ok=True)
        with open(self.group_lock, "a") as fh:
            fcntl.flock(fh, fcntl.LOCK_EX)
            try:
                yield
            finally:
                fcntl.flock(fh, fcntl.LOCK_UN)

    def stops(self) -> list[dict]:
        """The run's stops no acknowledgement confirms, read from its usage file now."""
        with run_lock(self.file):
            return open_stops(jsonl.read_strict(self.file))

    def _reserve(self, vendor: str, model: str, amount: float, label: str) -> str:
        deadline = time.monotonic() + self.max_wait
        with self.lock:
            while True:
                with self._group(), run_lock(self.file):
                    stopped = open_stops(jsonl.read_strict(self.file))
                    if stopped:                              # the send gate: no request of any role while a stop stands
                        raise RunStopped(_stopped_why(stopped))
                    why = self._short(vendor, amount, label)
                    if why is None:
                        token = uuid.uuid4().hex
                        jsonl.append_atomic(self.file, {"request": token, "state": "pending", "label": label, "vendor": vendor,
                                                        "model": model, "reserved_usd": amount})
                        self.reserved[token] = (vendor, amount)
                        self.labels[token] = label
                        return token
                left = deadline - time.monotonic()
                if not self.reserved or left <= 0:
                    raise BudgetPaused(why)
                self.lock.wait(timeout=min(left, 30.0))      # a settlement in flight may free room

    def reserve(self, model: str, prompt_chars: int, max_output_tokens: int, label: str = "") -> str:
        """Reserve an OpenAI call's worst case and record it as pending; raises `BudgetPaused` when it does not fit."""
        p = self.price(model)
        worst = (prompt_chars / CHARS_PER_TOKEN * p["input_usd_per_million"] + max_output_tokens * p["output_usd_per_million"]) / 1e6
        return self._reserve("openai", model, worst, label)

    def reserve_session(self, model: str, cap_usd: float | None, label: str = "") -> str:
        """Reserve a Claude session at its own cap (zero when uncapped) and record it as pending; raises
        `BudgetPaused` when it does not fit. A limit on Claude's spend needs a capped session."""
        if cap_usd is None and (self.limits["anthropic"] is not None or self.total_limit is not None):
            raise BudgetPaused("a limit on Claude's spend needs a capped session: an uncapped session cannot be reserved")
        return self._reserve("anthropic", model, float(cap_usd or 0.0), label)

    def start(self, token: str, row: dict) -> None:
        """The reserved request's transport is about to start: the gate is read again, under the
        budget's lock and the run's lock. While a stop stands the request is refused: settled at zero
        (`row`, with `not_started` naming the stop: it never started) and `RunStopped` is raised.
        Otherwise it is started, and a stop written later leaves it to be settled by what is known of it."""
        with self.lock, run_lock(self.file):
            stopped = open_stops(jsonl.read_strict(self.file))
            if not stopped:
                return
            self._settle_locked(token, {**row, "cost_usd": 0.0, "not_started": f"stop `{stopped[0]['stop']}`"}, None)
        raise RunStopped(_stopped_why(stopped))

    def settle(self, token: str | None, row: dict, stop: dict | None = None) -> None:
        """Record the request's actual cost (zero for a request known not to have been executed), then
        release its reservation and count the cost, replacing an `unknown` state. A request already
        settled is not settled again. The check, the durable row and the count are one step under
        the budget's lock, so two settlements of one request count it once. `stop` (a `stop_row`) is
        the stop this settlement causes, written in the same hold of the run's lock."""
        with self.lock, run_lock(self.file):
            self._settle_locked(token, row, stop)

    def _settle_locked(self, token: str | None, row: dict, stop: dict | None) -> None:
        """`settle`'s step, with the budget's lock and the run's lock held."""
        vendor = row.get("vendor") or "openai"
        if token is not None and token in self.settled:
            if stop is not None:
                jsonl.append_atomic(self.file, stop)
            return
        jsonl.append_atomic(self.file, {**row, "state": "settled", **({"request": token} if token else {})})
        if stop is not None:
            jsonl.append_atomic(self.file, stop)
        if token is not None:
            self.reserved.pop(token, None)
            self.labels.pop(token, None)
            if token in self.unresolved:
                v = self.unresolved_vendor.pop(token, vendor)
                self.by_vendor[v] = self.by_vendor.get(v, 0.0) - self.unresolved.pop(token)
            self.settled.add(token)
        self.by_vendor[vendor] = self.by_vendor.get(vendor, 0.0) + float(row.get("cost_usd") or 0)
        self.lock.notify_all()

    def unknown(self, token: str, row: dict) -> None:
        """Record that the request may have run and its cost was lost: it stays spent at its
        reservation until a settlement of the same request replaces it. Like `settle`, one step under
        the budget's lock."""
        with self.lock, run_lock(self.file):
            if token in self.settled or token in self.unresolved:
                return
            vendor, worst = self.reserved.get(token, (row.get("vendor") or "openai", 0.0))
            jsonl.append_atomic(self.file, {**row, "state": "unknown", "request": token, "reserved_usd": worst, "cost_usd": None})
            self.reserved.pop(token, None)
            self.labels.pop(token, None)
            self.unresolved[token], self.unresolved_vendor[token] = worst, vendor
            self.by_vendor[vendor] = self.by_vendor.get(vendor, 0.0) + worst
            self.lock.notify_all()


_BUDGETS: dict[str, Budget] = {}
_REGISTRY_LOCK = threading.Lock()


def for_run(opts, run_dir: Path) -> Budget:
    """The one budget of a run, shared by every worker."""
    with _REGISTRY_LOCK:
        b = _BUDGETS.get(opts.run_id)
        if b is None:
            prices_path = Path(opts.model_prices or Path(__file__).resolve().parents[2] / "config" / "model_prices.json")
            prices = {k: v for k, v in json.loads(prices_path.read_text(encoding="utf-8")).items() if not k.startswith("_")} \
                if prices_path.exists() else {}
            peers = tuple(paths.run_dir(r) / "usage.jsonl" for r in (opts.budget_peers or []) if r != opts.run_id)
            group = sorted(set(opts.budget_peers or []) | {opts.run_id}) if opts.budget_peers else None
            lock = paths.RESULTS / f".budget-{hashlib.sha256(json.dumps(group).encode()).hexdigest()[:16]}.lock" if group else None
            b = Budget(run_dir / "usage.jsonl", opts.openai_budget_usd, prices, claude_limit_usd=opts.claude_budget_usd,
                       total_limit_usd=opts.total_budget_usd, peers=peers, max_wait=float(opts.session_timeout or 0),
                       group_lock=lock, role_limits={ROLE_AGGREGATE: getattr(opts, "aggregate_verifier_budget_usd", None),
                                                     ROLE_BEHAVIOUR_REVIEW: getattr(opts, "behaviour_review_budget_usd", None)})
            _BUDGETS[opts.run_id] = b
        return b


def spent_limits(usage_file: Path, opts) -> list[str]:
    """The run's limits (`opts`: the vendors', the total, the aggregate verifier's and the behaviour
    reviewer's) its recorded spend has reached, unknown requests at their reservation: each admits no
    further request until the operator raises it."""
    b = Budget(Path(usage_file), opts.openai_budget_usd, {}, claude_limit_usd=opts.claude_budget_usd, total_limit_usd=opts.total_budget_usd,
               role_limits={ROLE_AGGREGATE: getattr(opts, "aggregate_verifier_budget_usd", None),
                            ROLE_BEHAVIOUR_REVIEW: getattr(opts, "behaviour_review_budget_usd", None)})
    spent = {v: b.by_vendor.get(v, 0.0) for v in VENDORS}
    limits = [(f"the {v} limit", lim, spent[v]) for v, lim in b.limits.items()] + [("the total limit", opts.total_budget_usd, sum(spent.values()))] \
        + [(f"the limit on `{r}`", lim, b._role_spend(r)) for r, lim in b.role_limits.items()]
    return [f"{name} of ${lim:.2f} is spent (${x:.2f})" for name, lim, x in limits if lim is not None and x >= lim]


def usage_row(label: str, vendor: str, model: str, effort, usage: dict, cost_usd) -> dict:
    return {"label": label, "vendor": vendor, "model": model, "effort": effort,
            "input_tokens": usage.get("input_tokens"), "cached_input_tokens": (usage.get("input_tokens_details") or {}).get("cached_tokens")
            if vendor == "openai" else usage.get("cache_read_input_tokens"),
            "output_tokens": usage.get("output_tokens"),
            "reasoning_tokens": (usage.get("output_tokens_details") or {}).get("reasoning_tokens") if vendor == "openai" else None,
            "cost_usd": cost_usd}
