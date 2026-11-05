"""What each rule can decide under a recording's manifest, before any monitor run over the trace,
and the atoms the adapter would have to supply.

Reason: a law that must be unknown on a dataset should be known as such before hours of
monitoring, and the adapter's change list should come from the same comparison.

The support is Core's own (`Manifest.support`): the monitor is run on a one-scene probe trace with
the recording's manifest, and each rule's report line gives its support (`supported`, `partial`,
`unsupported`) and the atoms it reads that the manifest declares absent. A probe scene holds no
road user, so nothing is evaluated; only the support depends on the manifest, and it is computed by
the same code the monitor uses on the real trace.
"""
from __future__ import annotations

import json
import subprocess
import tempfile
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

PROBE_TRACE = {"scenes": [{"t": 0, "users": [], "structures": [], "devices": []}]}


@dataclass
class Support:
    rule: str
    support: str
    absent: list[str] = field(default_factory=list)


def rule_support(monitor: Path, manifest: Path, rules: Iterable[str] | None = None, timeout: float = 120) -> dict[str, Support]:
    """Each registered rule's support under `manifest` (all registered rules when `rules` is None)."""
    with tempfile.TemporaryDirectory() as t:
        probe = Path(t) / "probe.json"
        probe.write_text(json.dumps(PROBE_TRACE))
        cmd = [str(monitor), "--manifest", str(manifest), "--json"]
        if rules:
            cmd += ["--rules", ",".join(rules)]
        p = subprocess.run(cmd + [str(probe)], capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        raise RuntimeError(f"monitor failed on the probe trace: {p.stderr.strip()[-400:]}")
    out = {}
    for line in p.stdout.splitlines():
        if line.strip():
            d = json.loads(line)
            if d.get("kind") == "rule":
                out[d["rule"]] = Support(d["rule"], d["support"], list(d.get("absent", [])))
    return out


@dataclass
class Report:
    """Per recording and rule, the support; across recordings, the adapter's change list."""
    per_recording: dict[str, dict[str, Support]] = field(default_factory=dict)

    def add(self, recording_id: str, supports: dict[str, Support]) -> None:
        if recording_id in self.per_recording:
            raise ValueError(f"recording {recording_id} reported twice")
        self.per_recording[recording_id] = supports

    def must_be_unknown(self) -> dict[str, list[str]]:
        """Per rule, the recordings on which it is unsupported (unknown before any trace is read)."""
        out: dict[str, list[str]] = defaultdict(list)
        for rec, sups in self.per_recording.items():
            for r, s in sups.items():
                if s.support == "unsupported":
                    out[r].append(rec)
        return dict(out)

    def adapter_changes(self) -> list[tuple[str, int, list[str]]]:
        """Each atom some rule reads and some recording declares absent: (atom, number of recordings,
        rules that read it), most frequent first, then by atom id."""
        recs: Counter = Counter()
        rules_of: dict[str, set] = defaultdict(set)
        for sups in self.per_recording.values():
            seen = set()
            for r, s in sups.items():
                for a in s.absent:
                    rules_of[a].add(r)
                    seen.add(a)
            recs.update(seen)
        return [(a, n, sorted(rules_of[a])) for a, n in sorted(recs.items(), key=lambda x: (-x[1], x[0]))]

    def to_dict(self) -> dict:
        return {"per_recording": {k: {r: asdict(s) for r, s in v.items()} for k, v in self.per_recording.items()},
                "must_be_unknown": self.must_be_unknown(),
                "adapter_changes": [{"atom": a, "recordings": n, "rules": rs} for a, n, rs in self.adapter_changes()]}
