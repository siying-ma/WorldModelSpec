"""What a run's sessions cost, and the run-wide limit on the second vendor's calls.

Every session of either vendor appends rows to `results/<run>/usage.jsonl`: its label, vendor,
model, effort, input, cached-input, output and reasoning tokens, and its cost in USD — a Claude
session's as its CLI reports it, an OpenAI call's from the operator's price table
(`config/model_prices.json`: USD per million input, cached-input and output tokens; reasoning tokens
are billed as output). The table is keyed by the model name the run requests (the run's options), and
that name alone prices a call, at its reservation and at its settlement; the dated model id the API
reports is never looked up. A requested name without a price launches no call.

With a limit (`openai_budget_usd`), an OpenAI call is launched only after its worst case — the
prompt's tokens at the input price plus the call's output-token limit at the output price — is
reserved under one lock shared by every worker of the run. The input part is an estimate (three
characters a token), not a bound. The reservation is written to `usage.jsonl` as a `pending` row
before the call is sent. What became of the request is written as one more row naming it, before the
spend is counted:
- `settled`, with its actual cost: a response with usage, or a request known not to have been executed
  (refused before execution: zero);
- `unknown`: the request may have run and its answer was lost (a timeout after sending, a dropped
  connection, an ambiguous server error, a response without usage, the process stopping during the
  call). It stays counted at its reservation.
A request's rows fold into one state, the same way live and on reload: `pending` and `unknown` count
the reservation once, and a `settled` row replaces any earlier state with its cost. The first
settlement of a request is final; a later one changes nothing. A pending request with no later row
(the process ended during the call) counts at its reservation, never as zero. A reviewer's tool
session reserves each of its requests in turn, its input being the whole conversation sent. A call that does not fit raises `BudgetPaused`, as does an API answer of exhausted
quota: the run pauses, resumable once the operator raises the limit. It is never a law's failure, a
deferral or a spent attempt.
"""
from __future__ import annotations

import json
import threading
import uuid
from pathlib import Path

from . import jsonl

CHARS_PER_TOKEN = 3


class BudgetPaused(RuntimeError):
    """The second vendor's budget does not admit another call: the run pauses."""


def fold(rows: list[dict]) -> tuple[float, dict[str, float], set[str]]:
    """The second vendor's spend over `usage.jsonl` rows: (spent, the requests whose cost is unknown
    with their reservations, the requests settled). Each request's rows fold into one state: its
    first `settled` row counts its cost; otherwise (`pending`, `unknown`) its reservation counts once.
    A settled row naming no request (a Claude session's, or one written before requests were named)
    counts its own cost when it is the second vendor's."""
    reservation: dict[str, float] = {}
    settled: dict[str, float] = {}
    loose = 0.0
    for r in rows:
        req, state = r.get("request"), r.get("state")
        if state == "pending" and req:
            reservation.setdefault(req, float(r.get("reserved_usd") or 0))
        elif state == "unknown" and req:
            reservation.setdefault(req, float(r.get("reserved_usd") or 0))
        elif req:
            if req not in settled:
                settled[req] = float(r.get("cost_usd") or 0) if r.get("vendor") == "openai" else 0.0
        elif r.get("vendor") == "openai":
            loose += float(r.get("cost_usd") or 0)
    unresolved = {q: v for q, v in reservation.items() if q not in settled}
    return sum(settled.values()) + loose + sum(unresolved.values()), unresolved, set(settled)


class Budget:
    def __init__(self, usage_file: Path, limit_usd: float | None, prices: dict):
        self.file, self.limit, self.prices = usage_file, limit_usd, prices
        self.lock = threading.Lock()
        #: requests in flight in this process: their reservation is held, not yet spent
        self.reserved: dict[str, float] = {}
        #: requests whose cost is not known (`pending` with no later row, or `unknown`): spent at their reservation
        self.spent, self.unresolved, self.settled = fold(jsonl.read_strict(usage_file))

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

    def reserve(self, model: str, prompt_chars: int, max_output_tokens: int, label: str = "") -> str:
        """Reserve a call's worst case and record it as pending; raises `BudgetPaused` when it does not fit."""
        p = self.price(model)
        worst = (prompt_chars / CHARS_PER_TOKEN * p["input_usd_per_million"] + max_output_tokens * p["output_usd_per_million"]) / 1e6
        with self.lock:
            if self.limit is not None and self.spent + sum(self.reserved.values()) + worst > self.limit:
                raise BudgetPaused(f"the OpenAI budget of ${self.limit:.2f} does not admit another call: spent ${self.spent:.2f}, "
                                   f"reserved ${sum(self.reserved.values()):.2f}, this call's worst case ${worst:.2f}")
            token = uuid.uuid4().hex
            jsonl.append_atomic(self.file, {"request": token, "state": "pending", "label": label, "vendor": "openai",
                                            "model": model, "reserved_usd": worst})
            self.reserved[token] = worst
            return token

    def settle(self, token: str | None, row: dict) -> None:
        """Record the call's actual cost (zero for a request known not to have been executed), then
        release its reservation and count the cost, replacing an `unknown` state. A request already
        settled is not settled again. The check, the durable row and the count are one step under
        the budget's lock, so two settlements of one request count it once."""
        with self.lock:
            if token is not None and token in self.settled:
                return
            jsonl.append_atomic(self.file, {**row, "state": "settled", **({"request": token} if token else {})})
            if token is not None:
                self.reserved.pop(token, None)
                self.spent -= self.unresolved.pop(token, 0.0)
                self.settled.add(token)
            if row.get("vendor") == "openai":
                self.spent += float(row.get("cost_usd") or 0)

    def unknown(self, token: str, row: dict) -> None:
        """Record that the request may have run and its answer was lost: it stays spent at its
        reservation until a settlement of the same request replaces it. Like `settle`, one step under
        the budget's lock."""
        with self.lock:
            if token in self.settled or token in self.unresolved:
                return
            worst = self.reserved.get(token, 0.0)
            jsonl.append_atomic(self.file, {**row, "state": "unknown", "request": token, "reserved_usd": worst, "cost_usd": None})
            self.reserved.pop(token, None)
            self.unresolved[token] = worst
            self.spent += worst


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
            b = Budget(run_dir / "usage.jsonl", opts.openai_budget_usd, prices)
            _BUDGETS[opts.run_id] = b
        return b


def usage_row(label: str, vendor: str, model: str, effort, usage: dict, cost_usd) -> dict:
    return {"label": label, "vendor": vendor, "model": model, "effort": effort,
            "input_tokens": usage.get("input_tokens"), "cached_input_tokens": (usage.get("input_tokens_details") or {}).get("cached_tokens")
            if vendor == "openai" else usage.get("cache_read_input_tokens"),
            "output_tokens": usage.get("output_tokens"),
            "reasoning_tokens": (usage.get("output_tokens_details") or {}).get("reasoning_tokens") if vendor == "openai" else None,
            "cost_usd": cost_usd}
