"""A closed stage's snapshot: written once from the run's last handoff export, whole both ways
against that export, and restored byte for byte into a clean checkout of the stage's baseline.

- A run with stage machinery files (a second stage, `G1`) is restored with them, so the handoff
  check passes and a launch there is not refused; so is the first stage, and at a same-named root
  on "another machine" with the original root gone.
- The two-way check names a file missing or extra on either side, a tampered blob, and a control
  record that is not the export's.
- A write is refused, writing nothing, when a file differs from the export or the export was made
  in another stage; a second write of the same snapshot returns it, a different one is refused.
- A restore is refused, writing nothing, into a checkout that is not clean, already holds the run
  or one of its files, is at another commit, has other code, or from a snapshot that is not whole.
- Over three stages no snapshot holds itself or the store, and the store holds one blob per digest.

The run is `Pinning.repo()`'s synthetic repository, exported by the real `handoff.export`."""
import json
import shutil
import subprocess
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness.phases import label_check
from harness.store import paths, snapshot, stages
from harness.tools import handoff
from scripts.tests import s24_helpers, test_split_handoff as split_handoff

TOOL = "ontology_provenance/nrs_tools/atoms_train.py"     # the doctor's split tool, beside the agent directory
GIT = ("git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main")
RULE = "library/TrafficSpec/Rules/R1.lean"


def git(cwd: Path, *args: str) -> str:
    return subprocess.run([*GIT, "-C", str(cwd), *args], check=True, capture_output=True, text=True).stdout.strip()


def tree(root: Path) -> dict:
    """Every file under `root` but git's own, with its bytes."""
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in sorted(root.rglob("*"))
            if p.is_file() and ".git" not in p.relative_to(root).parts}


def beside(name: str) -> Path | None:
    """`paths.ontology_tool` as the real layout resolves it: the tool beside the agent directory."""
    f = paths.REPO.parent / "ontology_provenance" / "nrs_tools" / f"{name}.py"
    return f.resolve() if f.is_file() else None


def place_tool(agent_dir: Path, text: str = "# split tool\n") -> Path:
    f = agent_dir.parent / TOOL
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(text)
    return f


def open_row(sid, prev, tid):
    return s24_helpers.open_row(sid, prev=prev, transition=tid)


class World:
    """The synthetic run at three closed stages, its baseline commit, and each stage's export as written."""

    def __init__(self, root: Path, rd: Path):
        self.root, self.rd = root, rd
        self.template = root.parent / "template"
        shutil.copytree(root, self.template, ignore=shutil.ignore_patterns("results"))
        git(self.template, "init", "-q")
        git(self.template, "add", "-A")
        git(self.template, "commit", "-q", "-m", "baseline")
        self.commit = git(self.template, "rev-parse", "HEAD")
        self.exports = {}                                     # stage → {agent path: bytes} of its last export
        self.n = 0

    def checkout(self, at: Path | None = None, tool: str = "# split tool\n") -> Path:
        """A clean checkout of the baseline commit at `at`, the doctor's split tool beside it (outside
        the git checkout, as `handoff.DOCTOR_TOOL` places it)."""
        self.n += 1
        at = at or self.root.parent / f"clone-{self.n}" / "repo"
        at.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "clone", "-q", str(self.template), str(at)], check=True, capture_output=True)
        place_tool(at, tool)
        return at

    def close(self, sid: str, tid: str) -> dict:
        m = handoff.export("r", source_baseline=self.commit)
        listed = list(m["artifacts"]) + ["results/r/handoff/manifest.json", "results/r/handoff/files.txt"]
        self.exports[sid] = {f: (self.root / f).read_bytes() for f in listed}
        return snapshot.write("r", sid, tid)

    def rule(self, text: str):
        (self.root / RULE).parent.mkdir(parents=True, exist_ok=True)
        (self.root / RULE).write_text(text)
        label_check.freeze(self.rd)

    def transition(self, prev: str, nxt: str, tid: str):
        """What a transition leaves in the run's directory: the stage record and its state file."""
        rows = [json.loads(x) for x in (self.rd / stages.STAGES_FILE).read_text().splitlines()] \
            if (self.rd / stages.STAGES_FILE).exists() else [open_row(prev, None, "t0")]
        rows += [s24_helpers.close_row(prev, tid), open_row(nxt, prev, tid)]
        (self.rd / stages.STAGES_FILE).write_text("".join(json.dumps(r) + "\n" for r in rows))
        (self.rd / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": tid, "status": "done"}))
        stages.read_stages(self.rd)                           # the record is one the reader accepts


@contextmanager
def world():
    with split_handoff.Pinning("test_artifact_only_checkpoints_pass_and_code_changes_refuse").repo() as (root, rd):
        place_tool(root)
        stack = mock.patch.object(paths, "ontology_tool", beside)
        stack.start()
        w = World(root, rd)
        w.rule("-- rule v0\n")
        g0 = w.close("G0", "t1")
        w.transition("G0", "G1", "t1")
        w.rule("-- rule v1\n")                                # G1 changes one rule
        g1 = w.close("G1", "t2")
        w.transition("G1", "G2", "t2")
        w.rule("-- rule v2\n")
        g2 = w.close("G2", "t3")
        try:
            yield w, {"G0": g0, "G1": g1, "G2": g2}
        finally:
            stack.stop()


@contextmanager
def at(root: Path, foreign: list[str]):
    """The harness's paths pointed at `root`, saved paths under the `foreign` roots mapped to it."""
    lay = {**paths.library_layout(root / "library"), "REPO": root, "RESULTS": root / "results"}
    with mock.patch.multiple(paths, **lay), mock.patch.object(paths, "FOREIGN_ROOTS", list(foreign)):
        yield


class Restore(unittest.TestCase):

    def restored_as_exported(self, w: World, sid: str, into: Path):
        for f, b in w.exports[sid].items():
            self.assertEqual((into / f).read_bytes(), b, f)
        run = sorted(p.relative_to(into).as_posix() for p in (into / "results" / "r").rglob("*") if p.is_file())
        self.assertEqual(run, sorted(f for f in w.exports[sid] if f.startswith("results/r/")))   # nothing else, no imported.json
        self.assertEqual(handoff.verify("r"), ([], []))
        handoff.check_on_launch(mock.Mock(dir=into / "results" / "r", opts=mock.Mock(run_id="r")))  # not refused
        self.assertTrue((into / "results" / "r" / "handoff" / "imported.json").exists())

    def test_each_stage_restores_as_its_last_export_and_passes_the_handoff_check(self):
        with world() as (w, snaps):
            self.assertEqual(snaps["G0"]["history"], {})
            self.assertEqual(set(snaps["G1"]["history"]) >= {"results/r/stages.jsonl", "results/r/stage_transition.json",
                                                             "results/r/stages/G0/manifest.json"}, True)
            self.assertTrue(any(f.startswith("results/r/stages/blobs/") for f in snaps["G1"]["history"]))
            for sid in ("G1", "G0", "G2"):
                with self.subTest(stage=sid):
                    into = w.checkout()
                    snapshot.restore("r", sid, into)
                    with at(into, [str(w.root)]):
                        self.restored_as_exported(w, sid, into)
                        if sid != "G0":
                            self.assertEqual(stages.active_stage(into / "results" / "r")["stage_id"], sid)
                    self.assertEqual((into / RULE).read_bytes(), w.exports[sid][RULE])
            self.assertEqual((w.root / RULE).read_text(), "-- rule v2\n")           # the original run is untouched

    def test_a_same_named_root_on_another_machine_with_the_original_gone(self):
        with world() as (w, _s):
            source = w.root.parent / "source" / "repo"
            shutil.copytree(w.root, source)
            place_tool(source)
            shutil.rmtree(w.root)
            shutil.rmtree(w.root.parent / "ontology_provenance")
            with at(source, [str(w.root)]):
                into = w.checkout(w.root)                                            # the same path, a fresh checkout
                snapshot.restore("r", "G1", into)
            with at(into, []):
                self.restored_as_exported(w, "G1", into)

    def test_a_restore_is_refused_and_writes_nothing(self):
        with world() as (w, _s):
            cases = {}

            def dirty(c):
                (c / "stray.txt").write_text("x")
            cases["not clean"] = (dirty, "not clean")

            def has_run(c):
                (c / ".git" / "info" / "exclude").write_text("results/\n")
                (c / "results" / "r").mkdir(parents=True)
            cases["run present"] = (has_run, "already holds the run's directory")

            def has_file(c):
                (c / ".git" / "info" / "exclude").write_text(RULE + "\n")
                (c / RULE).parent.mkdir(parents=True, exist_ok=True)
                (c / RULE).write_text("-- another run's rule\n")
            cases["snapshot file present"] = (has_file, "already holds file")

            def other_commit(c):
                (c / "laws.jsonl").write_text("\n")
                git(c, "commit", "-qam", "later")
            cases["other commit"] = (other_commit, "not at the stage's baseline commit")

            def other_code(c):
                (c / ".git" / "info" / "exclude").write_text("harness/extra.py\n")
                (c / "harness" / "extra.py").write_text("# not the baseline's\n")
            cases["other code"] = (other_code, "differs from the stage's baseline.*harness/extra.py")

            def not_git(c):
                shutil.rmtree(c / ".git")
            cases["not a checkout"] = (not_git, "not a git checkout")

            for name, (make, words) in cases.items():
                with self.subTest(case=name):
                    c = w.checkout()
                    make(c)
                    before = tree(c)
                    with self.assertRaisesRegex(SystemExit, words):
                        snapshot.restore("r", "G1", c)
                    self.assertEqual(tree(c), before)

            blob = next(iter(json.loads((w.rd / "stages" / "G1" / "manifest.json").read_text())["files"].values()))
            bp = w.rd / "stages" / "blobs" / blob
            was = bp.read_bytes()
            bp.write_bytes(was + b"tampered")
            c = w.checkout()
            before = tree(c)
            with self.assertRaisesRegex(SystemExit, f"blob {blob} does not hash"):
                snapshot.restore("r", "G1", c)
            self.assertEqual(tree(c), before)
            bp.write_bytes(was)
            snapshot.restore("r", "G1", c)                    # the same target, once the snapshot is whole


    def test_another_split_tool_at_the_target_is_refused(self):
        """The doctor's split tool counts as code of the target checkout."""
        with world() as (w, _s):
            c = w.checkout(tool="# another split tool\n")
            before = tree(c)
            with self.assertRaisesRegex(SystemExit, "differs from the stage's baseline.*" + handoff.DOCTOR_TOOL.replace(".", r"\.")):
                snapshot.restore("r", "G1", c)
            self.assertEqual(tree(c), before)

    def test_the_split_tool_is_read_from_the_target_not_from_this_process(self):
        """The target's split tool equal to the baseline's restores, whatever copy this process would import."""
        with world() as (w, _s):
            c = w.checkout()
            other = place_tool(w.root.parent / "elsewhere" / "repo", "# this process's own copy\n")
            with mock.patch.object(paths, "ontology_tool", lambda name: other):
                snapshot.restore("r", "G1", c)
            with at(c, [str(w.root)]):
                self.restored_as_exported(w, "G1", c)


class TwoWay(unittest.TestCase):

    def test_the_two_way_check_names_each_difference(self):
        with world() as (w, snaps):
            self.assertEqual(snapshot.verify("r"), [])
            mf = w.rd / "stages" / "G1" / "manifest.json"
            orig = mf.read_text()
            s = json.loads(orig)
            f0 = next(f for f in s["files"] if f.endswith("state.json"))
            h0 = next(f for f in s["history"] if f.endswith("stages.jsonl"))

            def mutated(change, words):
                d = json.loads(orig)
                change(d)
                mf.write_text(json.dumps(d))
                got = snapshot.verify("r", "G1")
                self.assertTrue(any(all(x in p for x in words) for p in got), got)
                self.assertTrue(any(all(x in p for x in words) for p in snapshot.verify("r")), "the whole-run check too")
                mf.write_text(orig)
            mutated(lambda d: d["files"].pop(f0), (f0, "not in the snapshot"))
            mutated(lambda d: d["history"].pop(h0), (h0, "not in the snapshot"))
            mutated(lambda d: d["files"].__setitem__("results/r/extra.txt", d["files"][f0]), ("results/r/extra.txt", "not in the stored export"))
            mutated(lambda d: d["history"].__setitem__(f0, d["files"][f0]), (f0, "both `files` and `history`"))
            mutated(lambda d: d["history"].__setitem__("results/r/notes.txt", d["files"][f0]), ("results/r/notes.txt", "not a stage machinery"))
            mutated(lambda d: d["files"].__setitem__(f0, d["history"][h0]), (f0, "another digest"))

            # the export's artifacts name a file the snapshot lacks: a stored export other than the one taken
            ctl = s["control"]["handoff/manifest.json"]["sha256"]
            m = json.loads((w.rd / "stages" / "blobs" / ctl).read_text())
            m["artifacts"]["results/r/ghost.txt"] = "0" * 64
            b = json.dumps(m).encode()
            import hashlib
            h = hashlib.sha256(b).hexdigest()
            (w.rd / "stages" / "blobs" / h).write_bytes(b)
            mutated(lambda d: d["control"]["handoff/manifest.json"].__setitem__("sha256", h),
                    ("results/r/ghost.txt", "not in the snapshot"))
            mutated(lambda d: d["control"]["handoff/manifest.json"].__setitem__("sha256", h), ("files.txt", "missing: results/r/ghost.txt"))
            (w.rd / "stages" / "blobs" / h).unlink()

            # a control blob tampered with
            cp = w.rd / "stages" / "blobs" / ctl
            was = cp.read_bytes()
            cp.write_bytes(was + b" ")
            self.assertTrue(any(ctl in p and "does not hash" in p for p in snapshot.verify("r", "G1")))
            cp.write_bytes(was)
            self.assertEqual(snapshot.verify("r"), [])
            self.assertEqual(snapshot.verify("r", "G9"), ["G9: no snapshot"])


class Write(unittest.TestCase):

    def test_a_file_not_as_exported_is_refused_and_nothing_is_written(self):
        with split_handoff.Pinning("test_artifact_only_checkpoints_pass_and_code_changes_refuse").repo() as (root, rd):
            handoff.export("r", source_baseline="c0ffee")
            (rd / "summary.json").write_text("{}\n")             # a file the export did not see
            handoff.export("r")
            (rd / "summary.json").write_text("{\"changed\": 1}\n")
            with self.assertRaisesRegex(SystemExit, "summary.json"):
                snapshot.write("r", "G0", "t1")
            self.assertFalse((rd / "stages").exists())
            (rd / "summary.json").unlink()
            with self.assertRaisesRegex(SystemExit, "missing or not as its last export"):
                snapshot.write("r", "G0", "t1")
            self.assertFalse((rd / "stages").exists())

    def test_the_export_must_be_the_closing_stages_and_a_snapshot_is_written_once(self):
        with split_handoff.Pinning("test_artifact_only_checkpoints_pass_and_code_changes_refuse").repo() as (root, rd):
            handoff.export("r", source_baseline="c0ffee")
            mp = rd / "handoff" / "manifest.json"
            m = json.loads(mp.read_text())
            mp.write_text(json.dumps({**m, "stage_id": "G9"}))
            with self.assertRaisesRegex(SystemExit, "made in stage `G9`"):
                snapshot.write("r", "G0", "t1")
            self.assertFalse((rd / "stages").exists())
            mp.write_text(json.dumps({**m, "stage_id": "G0"}))
            first = snapshot.write("r", "G0", "t1")
            self.assertEqual(first["baseline"], m["baseline"])
            self.assertEqual(set(first["control"]), {"handoff/manifest.json", "handoff/files.txt"})
            self.assertEqual(set(first["files"]), set(m["artifacts"]))
            blobs = sorted(p.name for p in (rd / "stages" / "blobs").iterdir())
            self.assertEqual(snapshot.write("r", "G0", "t1"), first)               # written again: the same, returned
            with self.assertRaisesRegex(SystemExit, "already has another snapshot"):
                snapshot.write("r", "G0", "t-other")
            bp = rd / "stages" / "blobs" / first["files"]["results/r/state.json"]
            bp.write_bytes(b"not it")
            mf = rd / "stages" / "G0" / "manifest.json"
            mf.unlink()
            with self.assertRaisesRegex(SystemExit, "do not hash to their names"):
                snapshot.write("r", "G0", "t1")
            self.assertFalse(mf.exists())
            self.assertEqual(sorted(p.name for p in (rd / "stages" / "blobs").iterdir()), blobs)

    def test_no_snapshot_holds_itself_and_the_store_holds_one_blob_per_digest(self):
        with world() as (w, snaps):
            for sid, s in snaps.items():
                self.assertFalse([f for f in s["files"] if "/stages" in f or f.endswith(("stage_transition.json", "stage_journal.json"))])
                self.assertNotIn(f"results/r/stages/{sid}/manifest.json", s["history"])
            self.assertIn("results/r/stages/G1/manifest.json", snaps["G2"]["history"])
            digests = {h for s in snaps.values() for h in [*s["files"].values(), *s["history"].values(),
                                                           *(c["sha256"] for c in s["control"].values())]}
            store = {p.name for p in (w.rd / "stages" / "blobs").iterdir()}
            self.assertEqual(store, digests)


if __name__ == "__main__":
    unittest.main()
