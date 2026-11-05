"""One owner writes the shared library at a time. The owner holds an exclusive `flock` on
`library/.run.lock` for its whole life; that file's inode never changes and its content is not the
record. The owner's record (its pid, its run, its nonce and the process groups of its live children)
is `library/.run.owner.json`, replaced whole by an atomic write, so a process ended during an update
never leaves it torn. The owner puts its nonce (`TRAFFIC_SPEC_OWNER`) and its library's path
(`TRAFFIC_SPEC_LIBRARY`) in its environment, so every process it starts, and every process those
start, carries both.

A later owner refuses to take over while a process of an earlier owner of the same library may
still write it: a process whose own environment carries the earlier nonce or this library's path.
The process groups the record names are hints only, since a group number can be reused by an
unrelated process: a group is never ended as such, and its members count only by their own
environment. Where the record cannot be read (missing, empty or damaged, in a library that had a
lock), or a recorded group holds a process carrying an owner nonce and no library path, it also
refuses, naming them, since their library cannot be told. `force` ends the processes of this
library and waits until they have ended; it never ends one whose library cannot be told, and never
passes a live flock. A record of the earlier
format, kept in the lock file itself, is read once and moved.

A stop request (SIGTERM, or the owner's own decision) sets `STOP`, which every session launch and
relaunch checks. A gate a coding session of the active run invokes does not take the lock: it
carries the live owner's nonce, which `check_delegated` verifies. A gate run with no owner variable
takes the lock like any mutating command."""
from __future__ import annotations
import json
import os
import signal
import threading
import uuid
from pathlib import Path
from . import paths

STOP = threading.Event()
ENV = "TRAFFIC_SPEC_OWNER"
LIB_ENV = "TRAFFIC_SPEC_LIBRARY"
#: The harness's own files in the library besides the lock: rewritten while sessions run (the
#: owner's record), between registry builds (the inactive records) or at a candidate's commit (its
#: pointer to the journal), never by a session.
HARNESS_FILES = (".run.owner.json", ".inactive.json", ".candidate_pending.json")
#: The library's pointer to a committed candidate transaction not yet applied: completed by the next owner.
PENDING_FILE = ".candidate_pending.json"
_FD = None
_RECORD: dict = {}
_LOCK = threading.Lock()


def lock_path() -> Path:
    return paths.LIBRARY / ".run.lock"


def record_path() -> Path:
    return paths.LIBRARY / ".run.owner.json"


def library_id() -> str:
    """The library as the processes of its owners carry it: its resolved path."""
    return str(paths.LIBRARY.resolve())


def generation() -> str:
    """The loop launch the current work belongs to: the owner's nonce (empty outside an owner)."""
    return _RECORD.get("nonce") or os.environ.get(ENV, "")


def _pids() -> list[int]:
    """Every process but this one."""
    return [int(d.name) for d in Path("/proc").iterdir() if d.name.isdigit() and int(d.name) != os.getpid()]


def _environ(pid: int) -> dict[bytes, bytes] | None:
    try:
        raw = Path(f"/proc/{pid}/environ").read_bytes()
    except OSError:
        return None
    return dict(e.split(b"=", 1) for e in raw.split(b"\0") if b"=" in e)


def _carrying(var: str, value: str) -> list[int]:
    """The pids (other than this process) whose environment holds `var=value`."""
    out = []
    for pid in _pids():
        env = _environ(pid)
        if env is not None and env.get(var.encode()) == value.encode():
            out.append(pid)
    return out


def _stat(pid: int) -> tuple[str, int] | None:
    """A process's state letter and process group, or None when it is gone."""
    try:
        s = Path(f"/proc/{pid}/stat").read_text()
    except OSError:
        return None
    f = s[s.rfind(")") + 2:].split()
    return f[0], int(f[2])


def _members(pgid: int) -> list[int]:
    """The running (not defunct) processes of a process group."""
    return [pid for pid in _pids() if (st := _stat(pid)) is not None and st[1] == pgid and st[0] != "Z"]


def _ended(pids: list[int], wait: float = 5.0) -> list[int]:
    """Wait until the given processes have ended (gone or defunct); the ones still running."""
    import time
    deadline = time.monotonic() + wait
    while True:
        left = [pid for pid in pids if (st := _stat(pid)) is not None and st[0] != "Z"]
        if not left or time.monotonic() > deadline:
            return left
        time.sleep(0.05)


def _untold() -> list[int]:
    """The pids carrying an owner's nonce and no library path: processes whose library cannot be told."""
    out = []
    for pid in _pids():
        env = _environ(pid)
        if env is not None and env.get(ENV.encode()) and not env.get(LIB_ENV.encode()):
            out.append(pid)
    return out


def kill_marked(var: str, value: str) -> None:
    """End every process whose environment holds `var=value`."""
    for pid in _carrying(var, value):
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass


def kill_group(pgid: int) -> None:
    try:
        os.killpg(pgid, signal.SIGKILL)
    except OSError:
        pass


def _write() -> None:
    from . import jsonl
    jsonl.write_atomic(record_path(), json.dumps(_RECORD))


def _read(text: str | None) -> dict | None:
    """A record, or None when it is missing, empty or damaged."""
    if not text or not text.strip():
        return None
    try:
        d = json.loads(text)
    except json.JSONDecodeError:
        return None
    return d if isinstance(d, dict) and d.get("nonce") else None


def _previous(fd) -> tuple[dict | None, bool]:
    """(the earlier owner's record or None, whether it was in the earlier format, in the lock file)."""
    try:
        return _read(record_path().read_text(encoding="utf-8")), False
    except FileNotFoundError:
        fd.seek(0)
        old = _read(fd.read())
        return old, old is not None
    except OSError:
        return None, False


def acquire(run_id: str, force: bool = False) -> str:
    """Take the library for this process, or stop. The processes of an earlier owner of this library
    that are still alive (by their own environment: its nonce, or this library's path) block the
    takeover, since they may still write the library, unless `force`, which ends them and waits
    for them to end. Processes whose library cannot be told (with the record unreadable, or in a
    group the record names) also block it, and `force` does not end them. Returns the owner's nonce."""
    global _FD, _RECORD
    import fcntl
    if os.environ.get(ENV) and os.environ.get(ENV) != _RECORD.get("nonce"):
        raise SystemExit("this command runs inside a session of an active run; it may not take the library")
    p = lock_path(); p.parent.mkdir(parents=True, exist_ok=True)
    fresh = not p.exists() and not record_path().exists()
    fd = open(p, "a+", encoding="utf-8")
    try:
        fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        fd.close()
        raise SystemExit(f"another process owns the library ({p}); wait for it, or stop it")
    prev, legacy = (None, False) if fresh else _previous(fd)
    # a process is the earlier owner's by its own environment (its nonce, or this library's path);
    # a recorded group id is only a hint, since the number may now name another process's group
    ours = sorted(set(_carrying(ENV, prev["nonce"]) if prev else []) | set(_carrying(LIB_ENV, library_id())))
    untold = [] if (fresh or prev is not None) else _untold()
    for g in (prev or {}).get("pgids", []):           # a recorded group's member whose library cannot be told
        for pid in _members(int(g)):
            env = _environ(pid) or {}
            if pid not in ours and env.get(ENV.encode()) and not env.get(LIB_ENV.encode()):
                untold.append(pid)
    if untold:
        fd.close()
        why = "the owner's record of {lib} cannot be read" if prev is None else "a process group the record of {lib} names holds them"
        raise SystemExit(why.format(lib=paths.LIBRARY) + f", and processes {sorted(set(untold))} carry an owner's nonce with no library "
                         "path, so whether they write this library cannot be told: end them yourself (--force_takeover does not)")
    if ours and not force:
        fd.close()
        who = f"the previous owner ({prev.get('run_id')}, pid {prev.get('pid')})" if prev else "an earlier owner (its record cannot be read)"
        raise SystemExit(f"{who} left live processes (pids {ours}) that may still write the library; end them, or pass "
                         "--force_takeover")
    for pid in ours:
        try:
            os.kill(pid, signal.SIGKILL)
        except OSError:
            pass
    left = _ended(ours)
    if left:
        fd.close()
        raise SystemExit(f"processes {left} of the earlier owner did not end; the library is not taken")
    _FD = fd
    _RECORD = {"pid": os.getpid(), "run_id": run_id, "nonce": uuid.uuid4().hex, "pgids": [], "library": library_id()}
    _write()
    if legacy:                                       # the earlier format's record, now moved: the lock file holds no record
        os.ftruncate(fd.fileno(), 0)
    os.environ[ENV] = _RECORD["nonce"]
    os.environ[LIB_ENV] = library_id()
    from ..phases.candidate import recover_pending        # a transaction a stopped owner committed is completed before any use
    done = recover_pending()
    if done:
        print(f"[owner] {done}")
    return _RECORD["nonce"]


def acquire_for_command(name: str) -> None:
    """A mutating command (init, split, reopen, verify, index, a gate run on its own) takes the
    library like a run does."""
    acquire(f"command:{name}")


def register(pgid: int) -> None:
    with _LOCK:
        if _FD is not None and pgid not in _RECORD["pgids"]:
            _RECORD["pgids"].append(pgid); _write()


def unregister(pgid: int) -> None:
    with _LOCK:
        if _FD is not None and pgid in _RECORD["pgids"]:
            _RECORD["pgids"].remove(pgid); _write()


def holds() -> bool:
    """Whether this process owns the library."""
    return _FD is not None


def children() -> list[int]:
    """The process groups this owner has started and not yet seen end (sessions and toolchain runs)."""
    with _LOCK:
        return list(_RECORD.get("pgids", [])) if _FD is not None else []


def check_delegated() -> None:
    """A command run from inside a session (the gate) passes only while the owner that started the
    session holds this library: a session left over from an earlier owner, or one of another
    library, may not write. A command with no owner variable is not delegated: it takes the lock
    itself (`acquire_for_command`)."""
    mine = os.environ.get(ENV)
    if not mine:
        raise SystemExit("this command is not run from a session of an active run: it takes the library itself")
    if os.environ.get(LIB_ENV) and os.environ.get(LIB_ENV) != library_id():
        raise SystemExit("the run that started this session owns another library")
    try:
        held = (_read(record_path().read_text(encoding="utf-8")) or {}).get("nonce")
    except OSError:
        held = None
    if held != mine:
        raise SystemExit("the run that started this session no longer owns the library")


def kill_children() -> None:
    """End every child of this owner: its recorded process groups and every process carrying its
    nonce (a stop, or the process ending)."""
    for g in list(_RECORD.get("pgids", [])):
        kill_group(int(g))
        unregister(int(g))
    if _RECORD.get("nonce"):
        kill_marked(ENV, _RECORD["nonce"])
