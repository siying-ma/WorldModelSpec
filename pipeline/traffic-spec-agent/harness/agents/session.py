"""One agent session with the run's options: effort, budget, and a relaunch when the session never ran.

A session that the account or the API refused (a usage limit, an API error, a crash, a transport
failure, a timeout with no answer) is not the agent's failure and is never counted as an attempt
against a law. Each task (its directory and label, which belong to one attempt) may launch at most
`session_retries + 1` times per loop launch: the first launch and `session_retries` relaunches.
Every launch is recorded in the task's directory before it starts, with the loop launch's generation
(the owner's nonce), and the count of failed launches of the current generation is tested before
launching, so a resume of the same loop launch continues the count, a process ended during a call
still counts its launch, and a new loop launch (the operator's relaunch) grants a new allowance. A
relaunch comes after `retry_wait` seconds and after the caller's `relaunch` (a coding task restores
its files to its baseline, a plan removes what the launch wrote). When the allowance is spent the
phase reports `SessionUnavailable`: the task is held and reported, never charged. A deterministic
bad request (400, 404, 422) is the harness's input to fix: it is reported at once (`BadRequest`) and
the digest of the effective request is recorded, so the same request is never sent again, in any
generation; a changed request (another prompt, model, effort, output cap or tool schema) may be. A session cut off by
its turn cap, budget cap or timeout ran: with `relaunch_cut_off` (a coding task) it is relaunched
under the same budget, and once those relaunches are spent its record is returned with `cut_off`
set, so the caller's own gate judges what it left; without, its record's `cut_off` tells the caller. No launch or relaunch starts once the owner's stop event is set. The
OpenAI client does not retry: the session's relaunch is the one retry.

`run` launches a Claude session, or one tool-less call of the second vendor (a reader, a judge).
`run_tools` drives a reviewer's session with the second vendor, whose only tools are the harness's
checks and its submission: one budget reservation per request, one deadline per session.
"""
from __future__ import annotations
import json
import time
from pathlib import Path
from typing import Callable, Optional
from . import runner
from ..store import budget, owner, paths
from ..store.state import Options


class SessionUnavailable(RuntimeError):
    pass


class BadRequest(SessionUnavailable):
    """The API rejected the request itself (400, 404, 422): a harness defect in the input, reported, never retried."""


#: Trees under the pipeline root no agent session may write: the frozen artifacts, the harness,
#: the corpus, the readings, the gap ledger, the registries and the build files.
PROTECTED = ["harness", "prompts", "ontology", "laws", "scripts", "config", "library/TrafficSpec/Readings", "library/TrafficSpec/Gaps",
             "library/TrafficSpec/Core", "library/splits", "library/TrafficSpec/Tests",
             "library/TrafficSpec/Index.lean", "library/TrafficSpecWitness.lean", "library/TrafficSpec.lean",
             "library/lakefile.lean", "library/lakefile.toml", "library/lake-manifest.json", "library/lean-toolchain",
             "library/.run.lock", *(f"library/{n}" for n in owner.HARNESS_FILES), *(f"library/.{n}.tmp-*" for n in owner.HARNESS_FILES),
             "README.md", "setup.sh", "pyproject.toml", "uv.lock"]
#: The run's records under `results/<run>/`, by name: a session's own outputs live in that tree
#: too (a plan directory's `blueprint.jsonl`, a task directory's `task_result.md`), so a suffix
#: pattern over the whole tree would deny the session what it exists to write.
RUN_RECORDS = ["results/*/ledger.jsonl", "results/*/concept_ledger.jsonl", "results/*/accepted_nodes.jsonl",
               "results/*/accepted_concepts.jsonl", "results/*/state.json", "results/*/mapping.json",
               "results/*/options.json", "results/*/reading.json", "results/*/summary.json", "results/*/AUTO_NOTES.md", "results/*/TO_USER.md",
               "results/*/iter-*/validate/**", "results/*/iter-*/integrate/**",
               "results/*/library_snapshot/**"]
#: What a kind of session may not touch of the other phases' output.
OTHER_PHASES = {"plan": ["results/*/iter-*/code/**"], "code": ["results/*/iter-*/plan/**", "results/*/iter-*/repair/**"]}
#: Trees under the repository root (above the pipeline) no agent session may write.
PROTECTED_REPO = ["CLAUDE.md", ".claude", "pipeline/DesignFile", "pipeline/ontology_provenance",
                  "pipeline/carla_scene_graphs", "pipeline/datasets"]
WRITE_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
#: The whole tool set of each kind of session (`--tools`): no search, no web, no subagent, whatever the
#: CLI adds. A reader or a judge answers from its prompt with no tool at all.
PLAN_TOOLS = ["Read", "Write", "Edit", "MultiEdit", "Bash"]       # the plan session runs its validator
REPAIR_TOOLS = ["Read", "Write", "Edit", "MultiEdit"]
CODE_TOOLS = ["Read", "Write", "Edit", "MultiEdit", "Bash"]       # the coding session runs its gate


def _abs(p: Path) -> str:
    """An absolute path in the form a permission rule takes (`//` then the path without its root)."""
    return "//" + str(Path(p).resolve()).lstrip("/")


def plan_allow(plan_dir: Path, validate_cmd: str) -> list[str]:
    """What a plan session may do: read and write its own directory, and run the validator once
    per call, exactly as the prompt gives the command."""
    return [f"{t}({_abs(plan_dir)}/**)" for t in ("Read",) + WRITE_TOOLS] + [f"Bash({validate_cmd})"]


def code_allow(own_files: list[Path], task_dir: Path, gate_cmd: str) -> list[str]:
    """What a coding session may do: read Core, read and edit its own two files, read and write
    its task directory (its result note), and run the gate, exactly as the prompt gives the
    command. Everything else — the harness, the corpus, the readings, other nodes, the run's
    records — is out of reach."""
    rules = [f"Read({_abs(paths.CORE)}/**)"]
    for f in own_files:
        rules += [f"{t}({_abs(f)})" for t in ("Read",) + WRITE_TOOLS]
    rules += [f"{t}({_abs(task_dir)}/**)" for t in ("Read",) + WRITE_TOOLS]
    rules.append(f"Bash({gate_cmd})")
    return rules


def harness_env(shell_timeout: float | None = None) -> dict[str, str]:
    """`python -m harness` resolves from any working directory. With `shell_timeout` (seconds), a
    shell command may run that long in the foreground: a gate waits for the library lock behind
    other sessions' gates and then runs, and only the session's own limit bounds both."""
    env = {"PYTHONPATH": str(paths.REPO.resolve())}
    if shell_timeout:
        ms = str(int(shell_timeout * 1000))
        env.update({"BASH_DEFAULT_TIMEOUT_MS": ms, "BASH_MAX_TIMEOUT_MS": ms})
    return env


def config_dirs() -> list[Path]:
    """Claude Code's own configuration and memory directories: what a session could otherwise read
    or write regardless of the allow-list, since the tool treats its memory as its own. Both the
    directory the environment names (`CLAUDE_CONFIG_DIR`, the account the run uses) and the
    default one (`~/.claude`) are denied to every session, for reading and for writing, so that
    neither account's memory reaches a session; a directory the pipeline itself lives under is
    not denied."""
    import os
    repo = paths.REPO.resolve()
    named = [Path(os.environ["CLAUDE_CONFIG_DIR"])] if os.environ.get("CLAUDE_CONFIG_DIR") else []
    out: set[Path] = set()
    for d in named + [Path.home() / ".claude"]:
        if repo.is_relative_to(d.resolve()):
            continue
        # both spellings: the path as named and the path with its links resolved, since a rule
        # matches the spelling the tool uses
        out |= {d, d.resolve()}
    return sorted(out, key=str)


def deny_rules(kind: str) -> list[str]:
    """Permission rules that hold whatever the allow-list says, for a session of `kind` (`plan`,
    `code`): every protected tree is denied to every write tool, Claude Code's configuration and
    memory directories are denied to reading and writing alike, and `git` is denied to the shell.
    A plan session may also not touch the library. The allow-list is the first wall; these rules
    are the second; the gate's repository digest is the third."""
    repo = paths.REPO.resolve()
    top = repo.parents[1]
    trees = list(PROTECTED) + (["library"] if kind == "plan" else [])
    paths_ = [f"//{str(repo).lstrip('/')}/{t}" for t in trees] + [f"//{str(top).lstrip('/')}/{t}" for t in PROTECTED_REPO]
    rules = []
    for p in paths_:
        pat = p if ("*" in p or p.endswith((".md", ".lean", ".toml", ".json", ".sh", ".lock", "toolchain"))) else p + "/**"
        rules += [f"{tool}({pat})" for tool in WRITE_TOOLS]
    for p in RUN_RECORDS + OTHER_PHASES.get(kind, []):
        rules += [f"{tool}(//{str(repo).lstrip('/')}/{p})" for tool in WRITE_TOOLS]
    for d in config_dirs():
        rules += [f"{tool}(//{str(d).lstrip('/')}/**)" for tool in ("Read",) + WRITE_TOOLS]
    rules += ["Bash(git *)", "Bash(sudo *)", "Bash(chmod *)"]
    return rules


def vendor_of(model: Optional[str]) -> str:
    """`openai` for a GPT or o-series model name (or an `openai:` prefix), else `anthropic`."""
    m = (model or "").lower()
    return "openai" if m.startswith(("openai:", "gpt-", "o1", "o3", "o4")) else "anthropic"


def _place(out_dir: Path, opts: Options, label: str) -> str:
    """Where a session ran, as its usage row names it: its directory under the run (the iteration,
    the phase and the subject: `iter-003/code/NRS_484B_600_1a`) and its label."""
    try:
        where = out_dir.resolve().relative_to(paths.run_dir(opts.run_id).resolve()).as_posix()
    except ValueError:
        where = out_dir.name
    return f"{where}/{label}"


def _launches(out_dir: Path, label: str) -> tuple[int, int, set[str]]:
    """(launch records of this task, those of the current generation that count against its
    allowance, the digests of the requests the API rejected in any generation)."""
    recs = []
    for f in out_dir.glob(f"{label}_result*.json"):
        try:
            recs.append(json.loads(f.read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError):
            recs.append({})
    gen = owner.generation()
    spent = sum(1 for r in recs if r.get("generation") == gen and (r.get("failure") or r.get("cut_off")))
    return len(recs), spent, {r["rejected_request"] for r in recs if r.get("rejected_request")}


def _started(out_dir: Path, label: str, suffix: str, launched: int) -> None:
    """A launch's record before its call: a process that ends during the call leaves it, and the
    launch counts as one that did not run."""
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(
        {"attempt": launched, "generation": owner.generation(), "started": True, "result": None,
         "failure": "the launch did not finish: the process ended during it", "cut_off": None, "stopped": False},
        ensure_ascii=False, indent=1), encoding="utf-8")


def _spent(label: str, spent: int, opts: Options, why: str = "") -> None:
    """Before a launch: raise when the task's allowance for this loop launch is spent."""
    if spent > opts.session_retries:
        raise SessionUnavailable(why or f"{label}: its {opts.session_retries + 1} launch(es) of this loop launch are spent")


def _stopping(label: str) -> None:
    if owner.STOP.is_set():
        raise SessionUnavailable(f"{label}: the run is stopping")


def _retry(label: str, why: str, spent: int, opts: Options, relaunch: Optional[Callable[[], None]]) -> None:
    """After a launch that did not do its work: raise when the task's allowance is spent, else wait and prepare the relaunch."""
    _spent(label, spent, opts, why)
    print(f"[session] relaunching {label} in {opts.retry_wait:.0f}s ({spent}/{opts.session_retries})")
    time.sleep(opts.retry_wait)
    _stopping(label)
    if relaunch is not None:
        relaunch()


def run(prompt: str, cwd: Path, out_dir: Path, opts: Options, *, max_turns: int, effort: Optional[str],
        label: str = "session", timeout: Optional[float] = None, allow: Optional[list[str]] = None,
        deny: Optional[list[str]] = None, tools: Optional[list[str]] = None,
        env: Optional[dict[str, str]] = None, model: Optional[str] = None, usage_label: Optional[str] = None,
        relaunch: Optional[Callable[[], None]] = None, relaunch_cut_off: bool = False) -> dict:
    """Launch, record `<label>.jsonl` and `<label>_result.json` (`.retryN` for later launches), relaunch
    a session that did not run (and, with `relaunch_cut_off`, one cut off), calling `relaunch` before
    each relaunch. Returns the record of the launch that ran, its `cut_off` set when it was cut off. `usage_label` (default: the
    session's directory under the run and its label) names its row in `usage.jsonl`, with the launch. `cwd` is the session's jail: it may read anything under it, so it
    holds only the session's own files; `allow` names everything else it may do."""
    chosen = model or opts.model
    if vendor_of(chosen) == "openai" and tools:
        raise RuntimeError(f"{label}: an OpenAI model ({chosen}) runs here only tool-less sessions (readers, judges); a reviewer's "
                           "tool session goes through `run_tools`")
    launched, spent, rejected = _launches(out_dir, label)
    while True:
        _stopping(label)
        _spent(label, spent, opts)
        suffix = "" if launched == 0 else f".retry{launched}"
        launched += 1
        ledger = budget.for_run(opts, paths.run_dir(opts.run_id))
        stream = out_dir / f"{label}{suffix}.jsonl"
        row_label = f"{usage_label or _place(out_dir, opts, label)}:L{launched}"   # phase, subject, iteration and launch; the model is its own field
        failure = None
        if vendor_of(chosen) == "openai":
            from . import openai_runner
            name = chosen.split(":", 1)[1] if chosen.startswith("openai:") else chosen
            cap = opts.reviewer_max_output_tokens
            digest = openai_runner.call_digest(prompt, model=chosen, effort=effort, max_output_tokens=cap)
            if digest in rejected:
                raise BadRequest(f"{label}: the API rejected this very request before; it is not sent again until it changes")
            token = ledger.reserve(name, len(prompt), cap or 0, row_label)    # raises BudgetPaused when the call does not fit
            _started(out_dir, label, suffix, launched)
            try:
                code, result, timed_out = openai_runner.run_openai(
                    prompt, model=chosen, stream_path=stream, effort=effort,
                    timeout_seconds=timeout if timeout is not None else opts.session_timeout, max_output_tokens=cap)
            except budget.BudgetPaused:                    # the quota answered: nothing was executed
                ledger.settle(token, budget.usage_row(row_label, "openai", name, effort, {}, 0.0)); raise
            except BaseException:                          # the call may have run: its cost is not known
                ledger.unknown(token, budget.usage_row(row_label, "openai", name, effort, {}, None)); raise
            _account(ledger, token, row_label, name, effort, code, timed_out, result, openai_runner)
            if result is None:
                failure = openai_runner.last_error(stream) or ("timed out with no answer" if timed_out else "no answer")
                if code == openai_runner.BAD_REQUEST:
                    record = {"code": code, "timed_out": timed_out, "attempt": launched, "generation": owner.generation(),
                              "result": None, "failure": failure, "rejected_request": digest}
                    (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
                    raise BadRequest(f"{label}: the API rejected the request — a harness input to fix: {failure}")
            cut = None
        else:
            _started(out_dir, label, suffix, launched)
            code, result, timed_out = runner.run_claude(
                prompt, cwd=cwd, stream_path=stream, max_turns=max_turns,
                model=chosen, effort=effort, max_budget_usd=opts.session_budget_usd,
                timeout_seconds=timeout if timeout is not None else opts.session_timeout,
                env_overrides=env, allow=allow, deny=deny, tools=tools)
            ledger.settle(None, budget.usage_row(row_label, "anthropic", chosen or "", effort, (result or {}).get("usage") or {},
                                                 (result or {}).get("total_cost_usd")))
            failure = runner.session_failure(code, result, timed_out, stream)
            cut = None if failure else runner.cut_off(result, timed_out)
        stopped = owner.STOP.is_set()
        record = {"code": code, "timed_out": timed_out, "attempt": launched, "generation": owner.generation(), "result": result,
                  "failure": None if stopped else failure, "cut_off": None if stopped else cut, "stopped": stopped}
        (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
        _stopping(label)
        if failure is None and (cut is None or not relaunch_cut_off):
            return record
        why = failure or cut
        spent += 1
        if failure is None and spent > opts.session_retries:
            # a session that ran and was cut off is no outage: once its relaunches are spent, the
            # caller's own gate judges what the last launch left
            print(f"[session] {label} was cut off: {why}; its {opts.session_retries + 1} launch(es) are spent, "
                  "the task is judged on what the last one left")
            return record
        hint = runner.reset_hint(why)
        print(f"[session] {label} {'did not run' if failure else 'was cut off'}: {why}" + (f" (resets {hint})" if hint else ""))
        _retry(label, why, spent, opts, relaunch)


def _account(ledger, token: str, row_label: str, name: str, effort, code: int, timed_out: bool, response: Optional[dict],
             openai_runner) -> None:
    """Settle one request of the second vendor by what is known of it: a response with usage at its
    cost; a request refused before execution (`BAD_REQUEST`, 1, and not timed out) at zero; a lost
    answer (`LOST`, a timeout) or a response without usage as unknown, kept at its reservation."""
    usage = (response or {}).get("usage") or {}
    row = budget.usage_row(row_label, "openai", name, effort, usage, ledger.cost(name, usage) if usage else 0.0)
    if usage:
        ledger.settle(token, row)
    elif code in (openai_runner.BAD_REQUEST, 1) and not timed_out:
        ledger.settle(token, row)
    else:
        ledger.unknown(token, {**row, "cost_usd": None})


def last_launch(out_dir: Path, label: str = "session") -> Optional[dict]:
    """The record of a task's last launch, or None."""
    recs = sorted(out_dir.glob(f"{label}_result*.json"), key=lambda f: (len(f.name), f.name))
    try:
        return json.loads(recs[-1].read_text(encoding="utf-8")) if recs else None
    except (OSError, json.JSONDecodeError):
        return None


def finished(out_dir: Path, label: str = "session") -> bool:
    """Whether a task's last launch ran to its end (a cut-off counts: its caller decides)."""
    r = last_launch(out_dir, label)
    return r is not None and not r.get("failure") and not r.get("stopped")


def cut_off_of(out_dir: Path, label: str = "session") -> Optional[str]:
    """Why the last launch of a task was cut off, from its record, or None."""
    return (last_launch(out_dir, label) or {}).get("cut_off")


#: The longest any one request of a tool session may run; the session's own deadline bounds it further.
REQUEST_TIMEOUT = 900.0


def run_tools(prompt: str, out_dir: Path, opts: Options, tools, *, label: str, effort: Optional[str],
              model: Optional[str] = None, subject: str = "") -> dict:
    """A reviewer's tool session with the second vendor, request by request. `tools` is the
    review's tool state: `specs` (its function tools), `reset()` (called at the start of every
    launch), `call(name, arguments) -> str` (a tool's result; it may raise, and the exception ends
    the session), `choice()` (the next request's `tool_choice`), `done` and `max_requests`.

    Each request is reserved on its own, at its whole input and the output-token limit, and
    settled to its usage as it returns, so a review of several requests holds no more than one
    reservation at a time and a failure leaves the usage of the requests before it recorded.
    `BudgetPaused` propagates. The whole session has one deadline, `session_timeout`; each
    request's timeout is what remains, at most `REQUEST_TIMEOUT`. A refused, failed or overdue
    request is a session that did not run: it is relaunched from the start after `retry_wait`, within
    the task's launches of this loop launch, and then `SessionUnavailable`; a rejected request raises
    `BadRequest` and its digest is recorded, so the same request is never sent again; the API's
    reason, sanitized, is written to the session's stream. Each request's usage row is
    `<label>:<subject>:L<launch>.r<n>`. Returns the record: `result` with the request count and
    whether a submission ended it."""
    from . import openai_runner
    chosen = model or opts.model
    if vendor_of(chosen) != "openai":
        raise RuntimeError(f"{label}: a tool session runs on the second vendor's API, not {chosen}")
    name = chosen.split(":", 1)[1] if chosen.startswith("openai:") else chosen
    cap = opts.reviewer_max_output_tokens
    launched, spent, rejected = _launches(out_dir, label)
    while True:
        _stopping(label)
        _spent(label, spent, opts)
        suffix = "" if launched == 0 else f".retry{launched}"
        launched += 1
        attempts = launched
        _started(out_dir, label, suffix, launched)
        ledger = budget.for_run(opts, paths.run_dir(opts.run_id))
        stream = out_dir / f"{label}{suffix}.jsonl"
        stream.parent.mkdir(parents=True, exist_ok=True)
        stream.write_text(json.dumps({"type": "request", "model": name, "effort": effort, "prompt_chars": len(prompt)}) + "\n", encoding="utf-8")
        tools.reset()
        items: list = [{"role": "user", "content": prompt}]
        deadline = time.time() + float(opts.session_timeout or REQUEST_TIMEOUT)
        why, n = None, 0
        while not tools.done and n < tools.max_requests:
            n += 1
            remaining = deadline - time.time()
            if remaining <= 0:
                why = f"the session passed its deadline of {opts.session_timeout:.0f}s"; break
            row_label = f"{label}:{subject}:L{attempts}.r{n}" if subject else f"{label}:L{attempts}.r{n}"
            choice = tools.choice()
            digest = openai_runner.request_digest(items, model=chosen, tools=tools.specs, tool_choice=choice, effort=effort,
                                                  max_output_tokens=cap)
            if digest in rejected:
                raise BadRequest(f"{label}: the API rejected this very request before; it is not sent again until it changes")
            token = ledger.reserve(name, len(json.dumps(items, ensure_ascii=False)), cap or 0, row_label)   # raises BudgetPaused
            try:
                code, resp, timed_out = openai_runner.request(items, model=chosen, tools=tools.specs, tool_choice=choice,
                                                              effort=effort, timeout_seconds=min(REQUEST_TIMEOUT, remaining),
                                                              max_output_tokens=cap)
            except budget.BudgetPaused:                    # the quota answered: nothing was executed
                ledger.settle(token, budget.usage_row(row_label, "openai", name, effort, {}, 0.0)); raise
            except BaseException:                          # the request may have run: its cost is not known
                ledger.unknown(token, budget.usage_row(row_label, "openai", name, effort, {}, None)); raise
            usage = (resp or {}).get("usage") or {}
            _account(ledger, token, row_label, name, effort, code, timed_out, resp, openai_runner)
            if code != 0:
                reason = (resp or {}).get("error") or ""
                with open(stream, "a", encoding="utf-8") as f:
                    f.write(json.dumps({"type": "error", "n": n, "timed_out": timed_out, "error": reason}, ensure_ascii=False) + "\n")
                why = ("the request timed out" if timed_out else "the API refused or failed the request") + (f": {reason}" if reason else "")
                if code == openai_runner.BAD_REQUEST:
                    record = {"code": code, "timed_out": False, "attempt": attempts, "generation": owner.generation(),
                              "result": {"requests": n, "submitted": False}, "failure": why, "rejected_request": digest}
                    (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
                    raise BadRequest(f"{label}: the API rejected the request — a harness input to fix: {reason}")
                break
            output = resp.get("output") or []
            items += output
            with open(stream, "a", encoding="utf-8") as f:
                f.write(json.dumps({"type": "response", "n": n, "status": resp.get("status"), "usage": usage, "output": output},
                                   ensure_ascii=False, default=str) + "\n")
            calls = [o for o in output if o.get("type") == "function_call"]
            if not calls:
                items.append({"role": "user", "content": "Answer through the tools: a check, or `submit_review` with your answer."})
                continue
            for c in calls:
                try:
                    args = json.loads(c.get("arguments") or "{}")
                except json.JSONDecodeError as e:
                    out = json.dumps({"error": f"the arguments are not JSON: {e}"})
                else:
                    out = tools.call(c.get("name", ""), args if isinstance(args, dict) else {})
                items.append({"type": "function_call_output", "call_id": c.get("call_id"), "output": out})
                with open(stream, "a", encoding="utf-8") as f:
                    f.write(json.dumps({"type": "tool", "n": n, "name": c.get("name"), "output": out}, ensure_ascii=False) + "\n")
                if tools.done:
                    break
        stopped = owner.STOP.is_set()
        record = {"code": 0 if why is None else 1, "timed_out": why is not None and ("deadline" in why or why == "the request timed out"),
                  "attempt": attempts, "generation": owner.generation(), "result": {"requests": n, "submitted": tools.done},
                  "failure": None if stopped else why, "stopped": stopped}
        (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
        _stopping(label)
        if why is None:
            return record
        spent += 1
        print(f"[session] {label} did not run: {why}")
        _retry(label, why, spent, opts, None)
