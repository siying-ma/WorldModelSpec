"""One agent session with the run's options: effort, budget, and a relaunch when the session never ran.

A session that the account or the API refused (a usage limit, an API error, a crash before the
first turn) is not the agent's failure and is never counted as an attempt against a law: it is
relaunched after `retry_wait` seconds, `session_retries` times, and if it still does not run the
phase reports `SessionUnavailable` so the loop can stop cleanly instead of burning the ledger.
"""
from __future__ import annotations
import json
import time
from pathlib import Path
from typing import Optional
from . import runner
from ..store import paths
from ..store.state import Options


class SessionUnavailable(RuntimeError):
    pass


#: Trees under the pipeline root no agent session may write: the frozen artifacts, the harness,
#: the corpus, the readings, the gap ledger, the registries and the build files.
PROTECTED = ["harness", "prompts", "ontology", "laws", "scripts", "library/TrafficSpec/Readings", "library/TrafficSpec/Gaps",
             "library/TrafficSpec/Core", "library/splits", "library/TrafficSpec/Tests",
             "library/TrafficSpec/Index.lean", "library/TrafficSpecWitness.lean", "library/TrafficSpec.lean",
             "library/lakefile.lean", "library/lakefile.toml", "library/lake-manifest.json", "library/lean-toolchain",
             "README.md", "setup.sh", "pyproject.toml", "uv.lock"]
#: The run's records under `results/<run>/`, by name: a session's own outputs live in that tree
#: too (a plan directory's `blueprint.jsonl`, a task directory's `task_result.md`), so a suffix
#: pattern over the whole tree would deny the session what it exists to write.
RUN_RECORDS = ["results/*/ledger.jsonl", "results/*/concept_ledger.jsonl", "results/*/accepted_nodes.jsonl",
               "results/*/accepted_concepts.jsonl", "results/*/deferred_nodes.jsonl", "results/*/mapping.json",
               "results/*/options.json", "results/*/reading.json", "results/*/summary.json", "results/*/AUTO_NOTES.md", "results/*/TO_USER.md",
               "results/*/iter-*/progress.json", "results/*/iter-*/validate/**", "results/*/iter-*/integrate/**",
               "results/*/library_snapshot/**"]
#: What a kind of session may not touch of the other phases' output.
OTHER_PHASES = {"plan": ["results/*/iter-*/code/**"], "code": ["results/*/iter-*/plan/**", "results/*/iter-*/repair/**"]}
#: Trees under the repository root (above the pipeline) no agent session may write.
PROTECTED_REPO = ["CLAUDE.md", ".claude", "pipeline/DesignFile", "pipeline/ontology_provenance",
                  "pipeline/carla_scene_graphs", "pipeline/datasets"]
WRITE_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
#: A reader or a judge answers from its prompt and touches nothing: no tool at all.
NO_TOOLS = ["Read", "Glob", "Grep", "Edit", "Write", "MultiEdit", "NotebookEdit", "Bash", "Task", "WebFetch", "WebSearch"]
#: Tools no plan or coding session gets: a search ranges over whatever it can reach.
NO_SEARCH = ["Glob", "Grep", "Task", "WebFetch", "WebSearch"]


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


def rule_matches(rule: str, tool: str, path: Path) -> bool:
    """Whether a permission rule `Tool(//abs/pattern)` covers `path` for `tool`: `**` spans
    directories, `*` one path segment, a pattern without a wildcard is exact."""
    import re
    if not rule.startswith(tool + "(//") or not rule.endswith(")"):
        return False
    pat = rule[len(tool) + 3:-1]
    rx = re.escape(pat).replace(r"\*\*", "\x00").replace(r"\*", "[^/]*").replace("\x00", ".*")
    return re.fullmatch(rx, str(Path(path).resolve()).lstrip("/")) is not None


def permitted(allow: list[str], deny: list[str], tool: str, path: Path) -> bool:
    """The allow-list model: a deny rule that matches refuses; else an allow rule must match."""
    if any(rule_matches(r, tool, path) for r in deny):
        return False
    return any(rule_matches(r, tool, path) for r in allow)


def harness_env() -> dict[str, str]:
    """`python -m harness` resolves from any working directory."""
    return {"PYTHONPATH": str(paths.REPO.resolve())}


def config_dirs() -> list[Path]:
    """Claude Code's own configuration and memory directories: what a session could otherwise read
    or write regardless of the allow-list, since the tool treats its memory as its own. Denied to
    every session, for reading and for writing, unless the pipeline itself lives under one."""
    import os
    d = Path(os.environ.get("CLAUDE_CONFIG_DIR") or (Path.home() / ".claude"))
    repo = paths.REPO.resolve()
    if repo.is_relative_to(d.resolve()):
        return []
    # both spellings: the path as the environment names it and the path with its links resolved,
    # since a rule matches the spelling the tool uses
    return sorted({d, d.resolve()}, key=str)


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


def run(prompt: str, cwd: Path, out_dir: Path, opts: Options, *, max_turns: int, effort: Optional[str],
        label: str = "session", timeout: Optional[float] = None, allow: Optional[list[str]] = None,
        deny: Optional[list[str]] = None, disallowed_tools: Optional[list[str]] = None,
        env: Optional[dict[str, str]] = None, model: Optional[str] = None) -> dict:
    """Launch, record `<label>.jsonl` and `<label>_result.json`, relaunch on a refusal. Returns the
    result record. `cwd` is the session's jail: it may read anything under it, so it holds only
    the session's own files; `allow` names everything else it may do."""
    chosen = model or opts.model
    if vendor_of(chosen) == "openai" and disallowed_tools != NO_TOOLS:
        raise RuntimeError(f"{label}: an OpenAI model ({chosen}) runs only tool-less sessions (readers, judges, reviewers)")
    attempts = 0
    while True:
        attempts += 1
        suffix = "" if attempts == 1 else f".retry{attempts - 1}"
        if vendor_of(chosen) == "openai":
            from . import openai_runner
            code, result, timed_out = openai_runner.run_openai(
                prompt, model=chosen, stream_path=out_dir / f"{label}{suffix}.jsonl", effort=effort,
                timeout_seconds=timeout if timeout is not None else opts.session_timeout)
        else:
            code, result, timed_out = runner.run_claude(
                prompt, cwd=cwd, stream_path=out_dir / f"{label}{suffix}.jsonl", max_turns=max_turns,
                model=chosen, effort=effort, max_budget_usd=opts.session_budget_usd,
                timeout_seconds=timeout if timeout is not None else opts.session_timeout,
                env_overrides=env, allow=allow, deny=deny, disallowed_tools=disallowed_tools)
        record = {"code": code, "timed_out": timed_out, "attempt": attempts, "result": result}
        (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
        why = runner.session_failure(code, result, timed_out)
        if why is None:
            return record
        hint = runner.reset_hint(why)
        print(f"[session] {label} did not run: {why}" + (f" (resets {hint})" if hint else ""))
        if attempts > opts.session_retries:
            raise SessionUnavailable(why)
        print(f"[session] relaunching in {opts.retry_wait:.0f}s ({attempts}/{opts.session_retries})")
        time.sleep(opts.retry_wait)
