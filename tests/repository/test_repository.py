"""Verifications that need only the repository, not a cloud.

Each test is named after the verification it implements in
model/infrastructure.sysml.
"""

import json
import re
import subprocess
import tomllib
from datetime import date
from pathlib import Path

import yaml

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

    # Providers, modules and OpenTofu itself: exact versions in every unit,
    # and a lock file with the checksums of its providers.
    units = {p.parent for p in unit_files()}
    assert units, "no unit found"
    for path in unit_files():
        for version in re.findall(
            r'^\s*(?:required_)?version\s*=\s*"([^"]*)"', path.read_text(), re.MULTILINE
        ):
            assert EXACT_VERSION.fullmatch(version), (
                f"{path.relative_to(ROOT)}: {version}"
            )
    for unit in units:
        sources = {
            source
            for path in unit.glob("*.tf")
            for source in re.findall(
                r'source\s*=\s*"([\w-]+/[\w-]+)"\n\s*version', path.read_text()
            )
        }
        if not sources:
            continue
        lock = unit / ".terraform.lock.hcl"
        assert lock.exists(), f"{unit.relative_to(ROOT)}: no lock file"
        locked = lock.read_text()
        for source in sources:
            assert f'/{source}"' in locked, (
                f"{unit.relative_to(ROOT)}: {source} not locked"
            )
        assert locked.count("hashes = [") == locked.count("provider "), lock


def unit_files():
    """The OpenTofu files of the units, outside the cache."""
    return sorted(
        p for p in ROOT.rglob("*.tf") if ".cache" not in p.relative_to(ROOT).parts
    )


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


CODENAME = re.compile(r"[a-z]+-[a-z]+")
# The one name that cannot be hidden: it is in the address of the repository (ADR-0011).
ORGANIZATION = "cocreiamo"


def leaves(value):
    if isinstance(value, dict):
        for item in value.values():
            yield from leaves(item)
    elif isinstance(value, list):
        for item in value:
            yield from leaves(item)
    else:
        yield value


def tenant_map():
    return yaml.safe_load((ROOT / "tenants.enc.yaml").read_text())


def test_R34_no_client_name_in_clear():
    # Keys are in the key service only: a rule with another kind of key would
    # let a file be read with a key kept somewhere else.
    rules = yaml.safe_load((ROOT / ".sops.yaml").read_text())["creation_rules"]
    for rule in rules:
        assert set(rule) == {"path_regex", "gcp_kms"}, rule

    # The map: codenames in clear, every value encrypted.
    tenants = tenant_map()
    metadata = tenants.pop("sops")
    assert metadata["gcp_kms"], "the map is encrypted with the key service"
    assert set(metadata) & {"age", "pgp", "kms", "azure_kv", "hc_vault"} <= {
        k for k in metadata if not metadata[k]
    }, "the map is encrypted with the key service only"
    assert tenants, "no tenant in the map"
    for codename, values in tenants.items():
        assert CODENAME.fullmatch(codename), codename
        for leaf in leaves(values):
            assert str(leaf).startswith("ENC["), f"{codename}: a value in clear"

    # Where the map can be decrypted (the maintainer's machine; the pipeline
    # once its plan identity exists), no real name appears in any other file.
    decrypted = subprocess.run(
        ["sops", "decrypt", str(ROOT / "tenants.enc.yaml")],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if decrypted.returncode != 0:
        return
    names = {
        str(leaf).lower()
        for leaf in leaves(yaml.safe_load(decrypted.stdout))
        if ORGANIZATION not in str(leaf).lower()
    }
    found = {}
    for name, path in repository_files():
        try:
            text = path.read_text().lower()
        except UnicodeDecodeError:
            continue
        hits = sorted(n for n in names if n in text)
        if hits:
            found[name] = len(hits)
    assert not found, f"real names of tenants in clear (file: how many): {found}"


def test_deadlines_register_well_formed():
    """The register of R36 can be read: R36 itself is verified by the pipeline."""
    codenames = set(tenant_map()) - {"sops"}
    entries = yaml.safe_load((ROOT / "deadlines.yaml").read_text())
    assert entries, "no deadline"
    for entry in entries:
        assert (
            {"what", "expires", "renew"}
            <= set(entry)
            <= {
                "what",
                "expires",
                "renew",
                "tenant",
            }
        ), entry
        assert isinstance(entry["expires"], date), entry
        if "tenant" in entry:
            assert entry["tenant"] in codenames, entry
    dates = [entry["expires"] for entry in entries]
    assert dates == sorted(dates), "deadlines are listed by date"


def encrypted_files():
    return sorted(
        (name, path) for name, path in repository_files() if name.endswith(".enc.yaml")
    )


def test_R13_no_secret_in_clear_in_repository():
    rules = yaml.safe_load((ROOT / ".sops.yaml").read_text())["creation_rules"]
    files = encrypted_files()
    assert files, "no encrypted file found"
    for name, path in files:
        content = yaml.safe_load(path.read_text())
        metadata = content.pop("sops")
        # Encrypted with the key the rules give this path, and with nothing else.
        matching = [r for r in rules if re.search(r["path_regex"], name)]
        assert matching, f"{name}: no rule in .sops.yaml"
        keys = {k["resource_id"] for k in metadata["gcp_kms"]}
        assert keys == {matching[0]["gcp_kms"]}, f"{name}: {keys}"
        for other in ("age", "pgp", "kms", "azure_kv", "hc_vault"):
            assert not metadata.get(other), f"{name}: also encrypted with {other}"
        for leaf in leaves(content):
            assert str(leaf).startswith("ENC["), f"{name}: a value in clear"

    # Nothing that looks like a secret in any commit.
    result = subprocess.run(
        ["gitleaks", "git", "--no-banner", "--redact"],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_by_hand_register_well_formed():
    """The register of R35 can be read: every entry says what and why."""
    register = yaml.safe_load((ROOT / "configured-by-hand.yaml").read_text())
    assert register, "the register is empty"
    for section, entries in register.items():
        assert entries, section
        for entry in entries:
            assert set(entry) == {"what", "why"}, f"{section}: {entry}"
            assert entry["what"] and entry["why"], f"{section}: {entry}"


def test_R12_state_store_and_keys_not_removable():
    """No change can remove the state store, a key or the project that holds them.

    OpenTofu refuses a plan that destroys a resource marked `prevent_destroy`,
    and the mark cannot be read from a plan: it is read from the code. The
    project also carries a lien, which the platform itself enforces.
    """
    protected = {"google_storage_bucket", "google_kms_crypto_key", "google_project"}
    block = re.compile(
        r'^resource "(\w+)" "(\w+)" \{\n(.*?)^\}', re.MULTILINE | re.DOTALL
    )
    found = set()
    for path in ROOT.rglob("*.tf"):
        if ".cache" in path.relative_to(ROOT).parts:
            continue
        for kind, name, body in block.findall(path.read_text()):
            if kind in protected:
                found.add(kind)
                assert re.search(
                    r"^\s*prevent_destroy\s*=\s*true$", body, re.MULTILINE
                ), f"{path.relative_to(ROOT)}: {kind}.{name} can be destroyed"
    assert found == protected, f"not described by any unit: {sorted(protected - found)}"
    liens = [
        body
        for path in ROOT.rglob("*.tf")
        if ".cache" not in path.relative_to(ROOT).parts
        for kind, _, body in block.findall(path.read_text())
        if kind == "google_resource_manager_lien"
    ]
    assert any("resourcemanager.projects.delete" in body for body in liens), (
        "no lien forbids deleting the project"
    )
