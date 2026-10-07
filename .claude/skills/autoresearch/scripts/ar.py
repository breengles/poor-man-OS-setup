#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Bookkeeping helper for /autoresearch campaigns.

Owns the ledger, the campaign lock, and the campaign config. Agents never write the ledger; every status change goes
through this script. Run from the project root:

    uv run --script ~/.claude/skills/autoresearch/scripts/ar.py <command> ...
"""

import argparse
import fcntl
import json
import math
import re
import sqlite3
import subprocess
import sys
import time
import tomllib
from collections.abc import Callable, Iterator
from contextlib import contextmanager
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path

LOCK_TIMEOUT_SECONDS = 60
LOCK_POLL_SECONDS = 0.5
# The name becomes a directory and a git ref component, so keep it to safe characters.
CAMPAIGN_NAME = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")


class ArError(Exception):
    """An error that ar.py reports to the user and exits on."""


@dataclass
class Config:
    goal: str
    metric: str
    direction: str
    aggregate: str
    min_delta: float
    scope: list[str]
    reference_sbatch: str
    smoke_hint: str
    mlflow_db: str
    max_parallel: int
    build_timeout_hours: float
    max_experiments: int | None = None
    plateau: int | None = None


@dataclass
class Job:
    kind: str
    job_id: str
    resubmitted: bool
    state: str | None


@dataclass
class Experiment:
    id: str
    hypothesis: str
    parent: str
    branch: str
    commit: str | None
    status: str
    verdict: str | None
    metric: float | None
    run_id: str | None
    reason: str | None
    jobs: list[Job]
    created_at: str
    finished_at: str | None


@dataclass
class Champion:
    exp: str | None
    commit: str
    metric: float | None
    since: str


@dataclass
class Ledger:
    campaign: str
    state: str
    champion: Champion
    history: list[Champion] = field(default_factory=list)
    next_id: int = 1
    experiments: list[Experiment] = field(default_factory=list)

    @classmethod
    def load(cls, path: Path) -> "Ledger":
        """Read the ledger. A ledger that does not parse is left untouched for the user to repair."""
        try:
            data = json.loads(path.read_text())
            return cls(
                campaign=data["campaign"],
                state=data["state"],
                champion=Champion(**data["champion"]),
                history=[Champion(**c) for c in data["history"]],
                next_id=data["next_id"],
                experiments=[Experiment(**{**e, "jobs": [Job(**j) for j in e["jobs"]]}) for e in data["experiments"]],
            )
        except FileNotFoundError:
            raise ArError(f"no ledger at {path}") from None
        except (json.JSONDecodeError, KeyError, TypeError) as exc:
            raise ArError(f"{path} is corrupt ({exc}); repair it by hand") from None

    def save(self, path: Path) -> None:
        """Write the ledger atomically, so a reader never sees a half-written file."""
        tmp = path.with_name(f"{path.name}.tmp")
        tmp.write_text(json.dumps(asdict(self), indent=2) + "\n")
        tmp.replace(path)


def _check_str(data: dict, key: str, errors: list[str]) -> None:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        errors.append(f"{key}: must be a non-empty string")


def _check_choice(data: dict, key: str, choices: tuple[str, ...], errors: list[str]) -> None:
    if data.get(key) not in choices:
        errors.append(f"{key}: must be one of {', '.join(repr(c) for c in choices)}")


def _check_number(data: dict, key: str, minimum: float, strict: bool, errors: list[str]) -> None:
    value = data.get(key)
    is_number = isinstance(value, int | float) and not isinstance(value, bool)
    if not is_number or value < minimum or (strict and value == minimum):
        errors.append(f"{key}: must be a number {'>' if strict else '>='} {minimum}")


def _check_count(data: dict, key: str, errors: list[str]) -> None:
    value = data.get(key)
    if not isinstance(value, int) or isinstance(value, bool) or value < 1:
        errors.append(f"{key}: must be an integer >= 1")


def load_config(path: Path) -> Config:
    """Read and validate campaign.toml.

    Raises:
        ArError: with every missing, invalid, or unknown key in one message.
    """
    try:
        data = tomllib.loads(path.read_text())
    except FileNotFoundError:
        raise ArError(f"no config at {path}") from None
    except tomllib.TOMLDecodeError as exc:
        raise ArError(f"{path} is not valid TOML: {exc}") from None

    errors: list[str] = []
    for key in ("goal", "metric", "reference_sbatch", "smoke_hint", "mlflow_db"):
        _check_str(data, key, errors)
    _check_choice(data, "direction", ("min", "max"), errors)
    _check_choice(data, "aggregate", ("last", "min", "max"), errors)
    _check_number(data, "min_delta", 0, False, errors)
    _check_number(data, "build_timeout_hours", 0, True, errors)
    _check_count(data, "max_parallel", errors)
    for key in ("max_experiments", "plateau"):
        if key in data:
            _check_count(data, key, errors)
    scope = data.get("scope")
    if not isinstance(scope, list) or not scope or not all(isinstance(g, str) and g for g in scope):
        errors.append("scope: must be a non-empty list of glob strings")
    known = Config.__dataclass_fields__.keys()
    errors.extend(f"{key}: unknown key" for key in data if key not in known)

    if errors:
        raise ArError(f"{path} is invalid:\n" + "\n".join(f"  {e}" for e in errors))
    return Config(**data)


def repo_root() -> Path:
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True).stdout
    except subprocess.CalledProcessError:
        raise ArError("not inside a git repository") from None
    return Path(out.strip())


def campaign_dir(name: str) -> Path:
    if not CAMPAIGN_NAME.fullmatch(name):
        raise ArError(f"invalid campaign name {name!r}: use letters, digits, '.', '_', '-'")
    return repo_root() / ".autoresearch" / name


def existing_campaign(name: str) -> Path:
    path = campaign_dir(name)
    if not (path / "campaign.toml").is_file():
        raise ArError(f"no campaign {name!r} at {path}")
    return path


@contextmanager
def campaign_lock(path: Path) -> Iterator[None]:
    """Hold an exclusive flock on the campaign, waiting up to LOCK_TIMEOUT_SECONDS for another holder."""
    with open(path / "lock", "a") as handle:
        deadline = time.monotonic() + LOCK_TIMEOUT_SECONDS
        while True:
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise ArError(
                        f"{path / 'lock'} is held by another ar.py call for over {LOCK_TIMEOUT_SECONDS}s"
                    ) from None
                time.sleep(LOCK_POLL_SECONDS)
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def git(*args: str) -> str:
    """Run git in the repository root and return its stripped stdout."""
    proc = subprocess.run(["git", *args], cwd=repo_root(), capture_output=True, text=True)
    if proc.returncode != 0:
        raise ArError(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout.strip()


class SlurmError(ArError):
    """sbatch or sacct failed. The message is the first line of its stderr."""


# Terminal SLURM states outside these sets are the change's fault. Any state not listed here is still in progress.
OK_STATES = {"COMPLETED"}
CLUSTER_FAILURE_STATES = {"NODE_FAIL", "PREEMPTED", "BOOT_FAIL"}
FAILURE_STATES = {"FAILED", "TIMEOUT", "OUT_OF_MEMORY", "CANCELLED", "DEADLINE", "REVOKED", "SPECIAL_EXIT"}


def slurm(*args: str) -> str:
    """Run a SLURM command and return its stdout.

    Raises:
        SlurmError: if the command is missing or exits non-zero.
    """
    try:
        proc = subprocess.run(args, capture_output=True, text=True)
    except FileNotFoundError:
        raise SlurmError(f"{args[0]}: command not found") from None
    if proc.returncode != 0:
        lines = proc.stderr.strip().splitlines()
        raise SlurmError(lines[0] if lines else f"{args[0]} exited with code {proc.returncode}")
    return proc.stdout


def submit(script: Path, worktree: Path, out_dir: Path) -> str:
    """Submit a job that runs in the worktree and writes its output to out_dir. Returns the job ID."""
    # SLURM resolves a relative --output against --chdir, so the output path must be absolute.
    output = out_dir.resolve() / "slurm-%j.out"
    out = slurm("sbatch", "--parsable", f"--chdir={worktree.resolve()}", f"--output={output}", str(script.resolve()))
    # --parsable prints "jobid;cluster" on multi-cluster setups.
    return out.strip().split(";")[0]


def states(job_ids: list[str]) -> dict[str, str]:
    """Read the SLURM state of every job in one sacct call.

    A job that sacct does not list yet was just submitted, so it counts as PENDING.
    """
    if not job_ids:
        return {}
    out = slurm("sacct", "-n", "-P", "-X", "-j", ",".join(job_ids), "-o", "JobID,State")
    found = {}
    for line in out.splitlines():
        job_id, state = line.split("|", 1)
        # "CANCELLED by 123" -> "CANCELLED"
        found[job_id] = state.split()[0]
    return {job_id: found.get(job_id, "PENDING") for job_id in job_ids}


def classify(state: str) -> str:
    """Map a SLURM state to pending, ok, cluster-failure, or failure."""
    if state in OK_STATES:
        return "ok"
    if state in CLUSTER_FAILURE_STATES:
        return "cluster-failure"
    if state in FAILURE_STATES:
        return "failure"
    return "pending"


class MlflowError(ArError):
    """The MLflow database could not be opened or queried."""


MLFLOW_BUSY_TIMEOUT_SECONDS = 30
# MLflow's SQL store saves +-inf as +-sys.float_info.max, so that value means an infinite metric.
MLFLOW_INF = sys.float_info.max


class Mlflow:
    """Read-only access to an MLflow SQLite tracking database."""

    def __init__(self, db: str) -> None:
        # mode=ro makes SQLite refuse every write, and as_uri() escapes '?' and '#' in the path.
        uri = f"{Path(db).resolve().as_uri()}?mode=ro"
        try:
            self.conn = sqlite3.connect(uri, uri=True, timeout=MLFLOW_BUSY_TIMEOUT_SECONDS)
        except sqlite3.Error as exc:
            raise MlflowError(f"cannot open MLflow database {db}: {exc}") from None
        self.db = db

    def _query(self, sql: str, params: tuple) -> list[tuple]:
        try:
            return self.conn.execute(sql, params).fetchall()
        except sqlite3.Error as exc:
            raise MlflowError(f"cannot read MLflow database {self.db}: {exc}") from None

    def find_run(self, campaign: str, exp: str, kind: str) -> str | None:
        """Return the newest live run tagged with this campaign, experiment, and kind."""
        rows = self._query(
            """
            SELECT r.run_uuid FROM runs r
            JOIN tags c ON c.run_uuid = r.run_uuid AND c.key = 'autoresearch.campaign' AND c.value = ?
            JOIN tags e ON e.run_uuid = r.run_uuid AND e.key = 'autoresearch.exp' AND e.value = ?
            JOIN tags k ON k.run_uuid = r.run_uuid AND k.key = 'autoresearch.kind' AND k.value = ?
            WHERE r.lifecycle_stage != 'deleted'
            ORDER BY r.start_time DESC
            LIMIT 1
            """,
            (campaign, exp, kind),
        )
        return rows[0][0] if rows else None

    def metric(self, run_id: str, key: str, aggregate: str) -> float | None:
        """Aggregate the finite values of a metric as last, min, or max. Returns None if there is none."""
        rows = self._query(
            "SELECT value FROM metrics WHERE run_uuid = ? AND key = ? AND is_nan = 0 ORDER BY step, timestamp",
            (run_id, key),
        )
        values = [v for (v,) in rows if math.isfinite(v) and abs(v) < MLFLOW_INF]
        if not values:
            return None
        if aggregate == "last":
            return values[-1]
        return min(values) if aggregate == "min" else max(values)


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def champion_branch(campaign: str) -> str:
    return f"autoresearch/{campaign}/champion"


def exclude_autoresearch() -> None:
    """Add .autoresearch/ to the exclude file once. --git-path finds the shared file also from a linked worktree."""
    exclude = repo_root() / git("rev-parse", "--git-path", "info/exclude")
    lines = exclude.read_text().splitlines() if exclude.exists() else []
    if ".autoresearch/" in lines:
        return
    exclude.parent.mkdir(parents=True, exist_ok=True)
    exclude.write_text("".join(f"{line}\n" for line in [*lines, ".autoresearch/"]))


def cmd_init(args: argparse.Namespace) -> dict:
    path = campaign_dir(args.campaign)
    branch = champion_branch(args.campaign)
    if path.exists():
        raise ArError(f"campaign directory {path} already exists")
    if git("branch", "--list", branch):
        raise ArError(f"branch {branch} already exists")
    config = load_config(args.config)
    baseline_metric = None
    if args.baseline:
        baseline_metric = Mlflow(config.mlflow_db).metric(args.baseline, config.metric, config.aggregate)
        if baseline_metric is None:
            raise ArError(f"baseline run {args.baseline} has no finite value of {config.metric}")

    commit = git("rev-parse", "HEAD")
    git("branch", branch, commit)
    path.mkdir(parents=True)
    exclude_autoresearch()
    with campaign_lock(path):
        (path / "campaign.toml").write_text(args.config.read_text())
        ledger = Ledger(
            campaign=args.campaign,
            state="active",
            champion=Champion(exp=None, commit=commit, metric=baseline_metric, since=now()),
        )
        ledger.save(path / "ledger.json")
    return {"campaign": args.campaign, "dir": str(path), "branch": branch, "champion": asdict(ledger.champion)}


def cmd_stop(args: argparse.Namespace) -> dict:
    ledger_path = campaign_dir(args.campaign) / "ledger.json"
    ledger = Ledger.load(ledger_path)
    ledger.state = "draining"
    ledger.save(ledger_path)
    return {"campaign": args.campaign, "state": ledger.state}


def cmd_status(args: argparse.Namespace) -> dict:
    ledger = Ledger.load(existing_campaign(args.campaign) / "ledger.json")
    champion = ledger.champion
    return {
        "campaign": ledger.campaign,
        "state": ledger.state,
        "champion": {"exp": champion.exp, "commit": champion.commit, "metric": champion.metric},
        "experiments": [
            {"id": e.id, "status": e.status, "verdict": e.verdict, "metric": e.metric, "hypothesis": e.hypothesis}
            for e in ledger.experiments
        ],
    }


def _not_implemented(args: argparse.Namespace) -> dict:
    raise ArError(f"'{args.command}' is not implemented yet")


cmd_collect = cmd_new = cmd_smoke = cmd_note = _not_implemented

# Commands that change campaign files run under the campaign lock. init takes the lock itself, because the campaign
# directory does not exist before it runs.
LOCKED_COMMANDS = {"collect", "new", "smoke", "note", "stop"}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ar.py", description="Bookkeeping helper for /autoresearch campaigns.")
    parser.add_argument("--json", action="store_true", help="print JSON instead of text")
    # SUPPRESS keeps the subcommand's default from overwriting a --json given before the subcommand.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--json", action="store_true", default=argparse.SUPPRESS, help="print JSON instead of text")
    sub = parser.add_subparsers(dest="command", required=True)

    def add(name: str, handler: Callable[[argparse.Namespace], dict], help_text: str) -> argparse.ArgumentParser:
        cmd = sub.add_parser(name, parents=[common], help=help_text)
        cmd.add_argument("campaign")
        cmd.set_defaults(handler=handler)
        return cmd

    init = add("init", cmd_init, "create a campaign from a config")
    init.add_argument("--config", required=True, type=Path, help="campaign.toml to validate and copy")
    init.add_argument("--baseline", help="MLflow run ID whose metric becomes the champion metric")
    add("collect", cmd_collect, "update jobs, verdicts, and submissions")
    add("new", cmd_new, "start an experiment from the champion").add_argument("--hypothesis", required=True)
    add("smoke", cmd_smoke, "check scope and submit the smoke job").add_argument("exp")
    note = add("note", cmd_note, "append a fact to notes.md")
    note.add_argument("--kind", required=True, choices=("env", "dead-end"))
    note.add_argument("--text", required=True)
    add("stop", cmd_stop, "let running jobs finish, start nothing new")
    add("status", cmd_status, "print the campaign state and every experiment")
    return parser


def _text(value: object) -> str:
    if isinstance(value, dict):
        return " ".join(f"{k}={v}" for k, v in value.items())
    return str(value)


def emit(result: dict, as_json: bool) -> None:
    if as_json:
        print(json.dumps(result, indent=2))
    else:
        for key, value in result.items():
            if isinstance(value, list):
                print(f"{key}:")
                for item in value:
                    print(f"  {_text(item)}")
            else:
                print(f"{key}: {_text(value)}")


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command in LOCKED_COMMANDS:
            with campaign_lock(existing_campaign(args.campaign)):
                result = args.handler(args)
        else:
            result = args.handler(args)
    except ArError as exc:
        if args.json:
            print(json.dumps({"error": str(exc)}))
        else:
            print(f"ar.py: {exc}", file=sys.stderr)
        return 1
    emit(result, args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
