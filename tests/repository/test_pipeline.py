"""Verifications of the pipeline that need only the repository.

They read the workflows and the tasks as they are written, and run the
filter of the public summary on a real plan. What only a run on GitHub can
show (the federation, the approval) is not verified here.
"""

import json
import re
import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
TASKS = ROOT / "mise-tasks" / "pipeline"
MARKER = "marker-7f3a9c-never-public"


def workflow(name):
    loaded = yaml.safe_load((WORKFLOWS / name).read_text())
    # YAML reads the key "on" as the boolean true.
    loaded["on"] = loaded.pop(True)
    return loaded


def commands(job):
    return [step["run"] for step in job["steps"] if "run" in step]


def actions(job):
    return [step["uses"].split("@")[0] for step in job["steps"] if "uses" in step]


def tofu(directory, *arguments):
    return subprocess.run(
        ["tofu", *arguments],
        cwd=directory,
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def test_R19_no_resource_value_in_public(tmp_path):
    # A real plan whose values, identifiers and sensitive values carry a marker.
    (tmp_path / "main.tf").write_text(
        f"""
        resource "terraform_data" "created" {{
          input = "{MARKER}"
        }}
        output "shown" {{
          value = "{MARKER}"
        }}
        output "hidden" {{
          value     = "{MARKER}"
          sensitive = true
        }}
        """
    )
    tofu(tmp_path, "init", "-input=false")
    tofu(tmp_path, "plan", "-input=false", "-out=plan")
    plan = json.loads(tofu(tmp_path, "show", "-json", "plan"))
    assert MARKER in json.dumps(plan), "the plan does not carry the marker"
    # An adopted resource: the identifier it is adopted by is not public either.
    adopted = json.loads(json.dumps(plan["resource_changes"][0]))
    adopted["address"] = "terraform_data.adopted"
    adopted["change"]["actions"] = ["no-op"]
    adopted["change"]["importing"] = {"id": MARKER}
    plan["resource_changes"].append(adopted)
    (tmp_path / "plan.json").write_text(json.dumps(plan))

    summary = subprocess.run(
        [
            "jq",
            "-r",
            "--arg",
            "unit",
            "example",
            "-f",
            TASKS / "summary.jq",
            "plan.json",
        ],
        cwd=tmp_path,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    assert MARKER not in summary
    assert "- `terraform_data.created`: create" in summary
    assert "- `terraform_data.adopted`: import" in summary
    assert "- `output.hidden`: create" in summary
    assert summary.startswith("**example**: 3 to create, 1 to import")

    # Whatever OpenTofu prints goes to a file, never to the log of a job.
    for name in ("plan", "apply"):
        task = (TASKS / name).read_text()
        runs = re.findall(
            r"^terragrunt run .*?(?:\n\n|\Z)", task, re.DOTALL | re.MULTILINE
        )
        assert runs, f"{name}: no Terragrunt command"
        for run in runs:
            assert '>"$out/log/' in run and "2>&1" in run, f"{name}: {run}"

    # A workflow reaches OpenTofu only through those tasks, and publishes the
    # summary and nothing else.
    for path in WORKFLOWS.glob("*.yml"):
        text = path.read_text()
        for line in text.splitlines():
            if re.match(r"\s*(- )?run:", line) or re.match(
                r"\s+(gh|mise|cat|printf) ", line
            ):
                assert not re.search(r"\b(tofu|terragrunt)\b", line), (
                    f"{path.name}: {line}"
                )
        for file in re.findall(r"(?:--body-file|cat) (\S+)", text):
            assert file == ".cache/pipeline/summary.md", f"{path.name}: {file}"
        assert "tg_comment" not in text  # GAP-002


def test_R25_every_change_planned():
    plan = workflow("plan.yml")
    assert "pull_request" in plan["on"]
    job = plan["jobs"]["plan"]
    assert job["environment"] == "plan"
    assert "mise run pipeline:plan --affected" in commands(job)
    assert any(
        "gh pr comment" in command and ".cache/pipeline/summary.md" in command
        for command in commands(job)
    )
    # Never the trigger that gives a fork the secrets of the repository.
    for path in WORKFLOWS.glob("*.yml"):
        assert "pull_request_target" not in path.read_text(), path.name


def test_R26_applied_plan_is_approved_plan():
    jobs = workflow("apply.yml")["jobs"]
    apply = jobs["apply"]
    assert apply["needs"] == "plan"
    assert apply["environment"] == "apply"
    assert jobs["plan"]["environment"] == "plan"
    # The plans come from the artifact of this same run: no other run is named.
    downloads = [
        step
        for step in apply["steps"]
        if step.get("uses", "").startswith("actions/download-artifact@")
    ]
    assert len(downloads) == 1
    assert set(downloads[0]["with"]) == {"name", "path"}
    uploads = [
        step["with"]["name"]
        for step in jobs["plan"]["steps"]
        if step.get("uses", "").startswith("actions/upload-artifact@")
    ]
    assert uploads == [downloads[0]["with"]["name"]]
    assert commands(apply) == ["mise run pipeline:apply"]
    # The task applies saved plans and has no command that plans.
    task = (TASKS / "apply").read_text()
    assert "-- plan" not in task
    assert '--out-dir "$out/artifact/plans"' in task
    assert "-- apply -input=false" in task


def test_R28_no_overlapping_apply():
    concurrency = workflow("apply.yml")["concurrency"]
    assert concurrency == {"group": "apply", "cancel-in-progress": False}
    # No other workflow enters the Environment that can change resources.
    for path in WORKFLOWS.glob("*.yml"):
        if path.name == "apply.yml":
            continue
        for name, job in workflow(path.name)["jobs"].items():
            assert job.get("environment") != "apply", f"{path.name}: {name}"


def test_R29_drift_reported():
    drift = workflow("drift.yml")
    crons = [entry["cron"].split() for entry in drift["on"]["schedule"]]
    # At least once a day: every day of the month, every month, every weekday.
    assert any(cron[2:] == ["*", "*", "*"] for cron in crons), crons
    job = drift["jobs"]["drift"]
    assert job["environment"] == "plan"
    assert "mise run pipeline:plan" in commands(job)
    report = [command for command in commands(job) if "gh issue create" in command]
    assert len(report) == 1
    assert "--body-file .cache/pipeline/summary.md" in report[0]
    assert "google-github-actions/auth" in actions(job)
