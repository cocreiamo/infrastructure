# The pipeline: read a plan, approve an apply, answer a drift issue

What the maintainer does around the three workflows
([ADR-0007](../adr/0007-pipeline-without-an-orchestrator.md),
[ADR-0008](../adr/0008-plan-visibility.md),
[ADR-0010](../adr/0010-updates-and-drift.md)).

## Read the detail of a plan

The comment on a pull request and the summary of a run show addresses and
actions only. The detail is in the artifact of the run, encrypted.

1. Take the id of the run from its address (`…/actions/runs/<id>`).
2. `mise run plan:show -- <id>` prints the plan of each unit and, after
   them, everything OpenTofu printed in that run. It uses your own sign-in
   to Google Cloud and to GitHub.
3. Nothing it prints is pasted in an issue, a pull request or a commit.

An artifact is kept for 7 days. After that, start the run again.

## Approve an apply

1. A merge to `main` starts the workflow Apply. Its first job plans every
   unit; when no plan has a change the run ends.
2. Otherwise the run waits. Read its summary and, when an action is not
   obvious, the detail as above.
3. Approve the run. The second job applies the plans of that same run.
4. To refuse, reject the run and revert the merge with a pull request.

Runs never overlap: a merge made while a run waits is planned only when
that run has ended. If OpenTofu refuses a plan as no longer current, start
the run again.

## When a job fails

The log of the job says which unit failed and nothing else. Read the rest
with `mise run plan:show -- <id>`.

## Answer a drift issue

Once a day every unit is compared with the real resources. A difference
opens the issue "Drift: the resources differ from the code", or adds a
comment to it while it is open.

1. Read the detail of the run named in the issue.
2. Either the change made by hand is wanted: describe it in the code with a
   pull request. Or it is not: merge nothing and start the workflow Apply
   again from its last run, which brings the resource back.
3. Close the issue when a run of the workflow Drift opens no new comment.

A merge that still waits for approval shows as drift: approve or refuse it.

## Run a plan on your own machine

`mise run pipeline:plan` plans every unit with your own sign-in and writes
the summary in `.cache/pipeline/summary.md`. Nothing is applied from a
machine: `pipeline:apply` is for the run that was approved.
