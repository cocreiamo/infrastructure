"""Verifications that need only the repository, not a cloud.

Each test is named after the verification it implements in
model/infrastructure.sysml.
"""

import json
import re
import subprocess
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMMIT = re.compile(r"[0-9a-f]{40}")
DIGEST = re.compile(r"sha256:[0-9a-f]{64}")
EXACT_VERSION = re.compile(r"\d+\.\d+\.\d+")


def load_toml(name):
    return tomllib.loads((ROOT / name).read_text())


def repository_files():
    """Files of the repository, tracked or not ignored."""
    out = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    for name in filter(None, out.split("\0")):
        path = ROOT / name
        if path.is_file() and not path.is_symlink():
            yield name, path


def test_R1_every_dependency_pinned():
    # Tools: exact versions only, each recorded in the lock file.
    tools = load_toml("mise.toml")["tools"]
    for tool, version in tools.items():
        assert EXACT_VERSION.search(version), f"{tool} = {version}"
    locked = load_toml("mise.lock")["tools"]
    for tool, version in tools.items():
        entries = locked.get(tool)
        assert entries, f"{tool} is not in mise.lock"
        assert any(e["version"] == version for e in entries), f"{tool} {version}"

    # GitHub Actions: pinned by commit.
    for workflow in (ROOT / ".github" / "workflows").glob("*.yml"):
        for ref in re.findall(r"uses:\s*\S+@(\S+)", workflow.read_text()):
            assert COMMIT.fullmatch(ref), f"{workflow.name}: {ref}"

    # Development container: image and features pinned by digest.
    devcontainer = json.loads(
        (ROOT / ".devcontainer" / "devcontainer.json").read_text()
    )
    assert DIGEST.search(devcontainer["image"]), devcontainer["image"]
    for feature, options in devcontainer["features"].items():
        assert DIGEST.search(feature), feature
        assert EXACT_VERSION.search(options["version"]), feature

    # Providers and modules are checked here when the first unit exists.


def test_R3_every_file_licensed():
    result = subprocess.run(
        ["reuse", "lint"], cwd=ROOT, check=False, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_R5_every_gap_registered():
    gaps = load_toml("gaps.toml")["gap"]
    fields = {
        "id",
        "component",
        "version",
        "summary",
        "impact",
        "workaround",
        "upstream",
        "resolved_when",
        "status",
    }
    ids = [g["id"] for g in gaps]
    assert ids == [f"GAP-{n:03d}" for n in range(1, len(ids) + 1)], (
        "ids are unique and sequential"
    )
    for g in gaps:
        assert set(g) == fields, g["id"]
        assert all(g[f] for f in fields), g["id"]
        assert g["status"] in {"open", "closed"}, g["id"]

    # Every GAP-nnn written in a file is a registered entry.
    pattern = re.compile(r"GAP-\d{3}")
    mentions = {}
    for name, path in repository_files():
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        mentions[name] = set(pattern.findall(text))
    unknown = {
        name: found - set(ids) for name, found in mentions.items() if found - set(ids)
    }
    assert not unknown, f"gap ids that are not in gaps.toml: {unknown}"

    # A workaround that is a repository path names its entry.
    for g in gaps:
        workaround = g["workaround"]
        if workaround == "none" or " " in workaround:
            continue
        assert (ROOT / workaround).is_file(), f"{g['id']}: {workaround}"
        assert g["id"] in mentions[workaround], f"{workaround} does not name {g['id']}"


def test_R6_generated_files_current():
    result = subprocess.run(
        [str(ROOT / "mise-tasks" / "generate" / "check")],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
