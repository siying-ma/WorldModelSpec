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
- a Claude session reserves the session's own cap (`session_budget_usd`), which the CLI checks after
  each turn, so a session may pass its reservation by up to one turn.
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

The limits: one per vendor (`openai_budget_usd`, `claude_budget_usd`) and one over both
(`total_budget_usd`), each over this run's spend plus that of the runs named in `budget_peers`, whose
usage files are read again at every reservation (their pending rows count as spent: this process
cannot wait on them). Runs that share a limit name the same group (`budget_peers`, the run itself
counted or not), and every reservation of the group takes one file lock
(`results/.budget-<group>.lock`) across the check and the pending row it writes, so two runs, in one
process or several, never both reserve the same remainder. A request that does not fit waits while requests of this process are in flight
whose settlement may free room, up to `max_wait` seconds; it raises `BudgetPaused` when none is in
flight or the wait ends, as does an API answer of exhausted quota: the run pauses, resumable once the
operator raises the limit. It is never a law's failure, a deferral or a spent attempt.
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
VENDORS = ("openai", "anthropic")


class BudgetPaused(RuntimeError):
    """A limit does not admit another request: the run pauses."""


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
                 group_lock: Path | None = None):
        self.file, self.prices, self.peers, self.max_wait = usage_file, prices, tuple(peers), float(max_wait)
        self.group_lock = group_lock
        self.limits = {"openai": limit_usd, "anthropic": claude_limit_usd}
        self.total_limit = total_limit_usd
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

    def _short(self, vendor: str, amount: float) -> str | None:
        """Why `amount` more of `vendor` does not fit, or None. Called under the lock."""
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

    def _reserve(self, vendor: str, model: str, amount: float, label: str) -> str:
        deadline = time.monotonic() + self.max_wait
        with self.lock:
            while True:
                with self._group():
                    why = self._short(vendor, amount)
                    if why is None:
                        token = uuid.uuid4().hex
                        jsonl.append_atomic(self.file, {"request": token, "state": "pending", "label": label, "vendor": vendor,
                                                        "model": model, "reserved_usd": amount})
                        self.reserved[token] = (vendor, amount)
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
            raise BudgetPaused("a limit on Claude's spend needs `session_budget_usd`: an uncapped session cannot be reserved")
        return self._reserve("anthropic", model, float(cap_usd or 0.0), label)

    def settle(self, token: str | None, row: dict) -> None:
        """Record the request's actual cost (zero for a request known not to have been executed), then
        release its reservation and count the cost, replacing an `unknown` state. A request already
        settled is not settled again. The check, the durable row and the count are one step under
        the budget's lock, so two settlements of one request count it once."""
        vendor = row.get("vendor") or "openai"
        with self.lock:
            if token is not None and token in self.settled:
                return
            jsonl.append_atomic(self.file, {**row, "state": "settled", **({"request": token} if token else {})})
            if token is not None:
                self.reserved.pop(token, None)
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
        with self.lock:
            if token in self.settled or token in self.unresolved:
                return
            vendor, worst = self.reserved.get(token, (row.get("vendor") or "openai", 0.0))
            jsonl.append_atomic(self.file, {**row, "state": "unknown", "request": token, "reserved_usd": worst, "cost_usd": None})
            self.reserved.pop(token, None)
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
                       group_lock=lock)
            _BUDGETS[opts.run_id] = b
        return b


def usage_row(label: str, vendor: str, model: str, effort, usage: dict, cost_usd) -> dict:
    return {"label": label, "vendor": vendor, "model": model, "effort": effort,
            "input_tokens": usage.get("input_tokens"), "cached_input_tokens": (usage.get("input_tokens_details") or {}).get("cached_tokens")
            if vendor == "openai" else usage.get("cache_read_input_tokens"),
            "output_tokens": usage.get("output_tokens"),
            "reasoning_tokens": (usage.get("output_tokens_details") or {}).get("reasoning_tokens") if vendor == "openai" else None,
            "cost_usd": cost_usd}
