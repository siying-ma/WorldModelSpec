"""What a run's sessions cost, and the run-wide limit on the second vendor's calls.

Every session of either vendor appends one row to `results/<run>/usage.jsonl`: its label, vendor,
model, effort, input, cached-input, output and reasoning tokens, and its cost in USD — a Claude
session's as its CLI reports it, an OpenAI call's from the operator's price table (USD per million
input, cached-input and output tokens, per model; reasoning tokens are billed as output).

With a limit (`openai_budget_usd`), an OpenAI call is launched only after its worst case — the
prompt's tokens (estimated from its length, three characters a token) at the input price plus the
call's output-token limit at the output price — is reserved under one lock shared by every worker
of the run; the reservation is settled to the call's actual cost when it returns. A reviewer's tool
session reserves each of its requests in turn, its input being the whole conversation sent. A call that does
not fit raises `BudgetPaused`, as does an API answer of exhausted quota: the run pauses, resumable
once the operator raises the limit. It is never a law's failure, a deferral or a spent attempt.
"""
from __future__ import annotations

import json
import threading
from pathlib import Path

from . import jsonl

CHARS_PER_TOKEN = 3


class BudgetPaused(RuntimeError):
    """The second vendor's budget does not admit another call: the run pauses."""


class Budget:
    def __init__(self, usage_file: Path, limit_usd: float | None, prices: dict):
        self.file, self.limit, self.prices = usage_file, limit_usd, prices
        self.lock = threading.Lock()
        self.reserved: dict[int, float] = {}
        self.next_token = 0
        self.spent = sum(float(r.get("cost_usd") or 0) for r in jsonl.read_strict(usage_file) if r.get("vendor") == "openai")

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

    def reserve(self, model: str, prompt_chars: int, max_output_tokens: int) -> int:
        """Reserve a call's worst case; raises `BudgetPaused` when it does not fit."""
        p = self.price(model)
        worst = (prompt_chars / CHARS_PER_TOKEN * p["input_usd_per_million"] + max_output_tokens * p["output_usd_per_million"]) / 1e6
        with self.lock:
            if self.limit is not None and self.spent + sum(self.reserved.values()) + worst > self.limit:
                raise BudgetPaused(f"the OpenAI budget of ${self.limit:.2f} does not admit another call: spent ${self.spent:.2f}, "
                                   f"reserved ${sum(self.reserved.values()):.2f}, this call's worst case ${worst:.2f}")
            self.next_token += 1
            self.reserved[self.next_token] = worst
            return self.next_token

    def settle(self, token: int | None, row: dict) -> None:
        """Release a reservation and record the call's actual cost."""
        with self.lock:
            if token is not None:
                self.reserved.pop(token, None)
            if row.get("vendor") == "openai":
                self.spent += float(row.get("cost_usd") or 0)
        jsonl.append_atomic(self.file, row)


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
