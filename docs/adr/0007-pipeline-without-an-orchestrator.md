---
number: 7
title: The pipeline is GitHub Actions and Terragrunt, with no orchestrator
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# The pipeline is GitHub Actions and Terragrunt, with no orchestrator

## Context and Problem Statement

Something must plan on a pull request and apply after a merge. Tools exist
that orchestrate this. What runs the pipeline, and how much of it is ours?

## Decision Drivers

- No server to run for years.
- Nothing of a third party's cloud with access to the organization.
- As little code of our own as possible.
- Write credentials never reachable from unmerged code
  ([ADR-0006](0006-pipeline-identity-and-access.md)).
- Support for Terragrunt.

## Considered Options

- GitHub Actions running Terragrunt
- OpenTaco with its orchestrator
- OpenTaco without a backend
- Atlantis
- Terrateam
- Terramate
- The `tf-via-pr` action

## Decision Outcome

Chosen option: "GitHub Actions running Terragrunt", because it is the only
option with no server, no third party and support for Terragrunt, and what it
leaves to us is small.

1. The pipeline is **GitHub Actions workflows that run Terragrunt**, on
   GitHub-hosted runners, which are free of charge for a public repository.
2. **Terragrunt is the orchestrator**: it works out the units a change
   affects, their dependencies and their order.
3. Tools are installed by mise; Terragrunt is run by the official
   `gruntwork-io/terragrunt-action`, which reads the versions from
   `mise.toml`. Its pull request comment stays off (GAP-002).
4. **Three workflows**: on a pull request, the checks, the plan of the
   affected units and a summary comment
   ([ADR-0008](0008-plan-visibility.md)); on a merge to `main`, plan, wait
   for approval, apply; on a schedule, the drift check
   ([ADR-0010](0010-updates-and-drift.md)).
5. **The plan reaches the apply inside one run.** The workflow started by a
   merge has two jobs: `plan` makes the plan of each affected unit and
   uploads the encrypted files as an artifact; `apply` needs `plan`, waits
   for the approval of the `apply` Environment, downloads the artifact of
   the same run and applies those files.
6. **When `main` moves in the meantime**, nothing special is built: OpenTofu
   itself refuses a saved plan that is no longer current, and the run is
   started again. The workflow has a `concurrency` group that never cancels
   a run in progress, so applies queue and never overlap; the maintainer
   approves the newest run and cancels the ones before it. The state backend
   locks each unit besides.
7. **The public summary is made from the plan as data, never from its
   text**: `tofu show -json` writes to a file, and a `jq` filter keeps the
   address and the actions of each resource and nothing else.

What is ours is three small pieces around adopted tools: the summary comment
and the issue opened on drift, both written with the `gh` command already on
the runner, and the upload of the encrypted plan with GitHub's own artifact
action.

### Consequences

- Good, because there is no server and no third-party application on the
  organization.
- Good, because an orchestrator can be added on top later without redoing
  anything.
- Bad, because there are no locks at the level of the pull request and no
  apply from a comment.
- Bad, because the workflows are ours to keep current
  ([ADR-0010](0010-updates-and-drift.md) proposes their updates).

### Confirmation

Requirements R25, R26, R27 and R28 state what must hold; their tests are not
written. Only the workflow that runs the checks exists; the three workflows
above are not built.

## Pros and Cons of the Options

Facts read from each project's documentation on 2026-11-27.

### GitHub Actions running Terragrunt

- Good, because every part is a feature of OpenTofu, Terragrunt, GitHub or
  Google Cloud.
- Bad, because three small pieces are ours.

### OpenTaco with its orchestrator

Called Digger until 7 November 2025. A command-line tool runs in our Actions;
an orchestrator service receives the webhooks of a GitHub App, starts the
workflows and holds locks and comments.

- Good, because it gives locks at the level of the pull request and applies
  from a comment.
- Bad, because self-hosted it is a service and a database to run for years.
- Bad, because in their cloud a third party can start the workflows that
  apply our infrastructure.
- Bad, because it is still version 0.x with one vendor.

### OpenTaco without a backend

Documented and not deprecated: `no-backend: true`, no server, locks in a
bucket of ours.

- Good, because nothing is hosted.
- Bad, because apply starts from a comment on the pull request, before the
  merge, so write credentials must be reachable from unmerged code; the
  documentation says nothing about forks.
- Bad, because it gives up what an orchestrator is chosen for: no
  concurrency, clashing applies fail rather than queue, no policies.
- Bad, because a user's report of April 2026 (version 0.6.143) says it
  crashes unless locking is also disabled, and lists some fifteen pitfalls.
- Bad, because the generation of projects from Terragrunt "happens in the
  backend" according to the documentation; not confirmed without one.

### Atlantis

- Good, because it is active (0.42, April 2026) and well known.
- Bad, because it is a server to run, and delicate on a public repository.

### Terrateam

- Bad, because it is open core and a server to run.

### Terramate

- Good, because it has no server.
- Bad, because it repeats what Terragrunt already does here.

### The `tf-via-pr` action

Now `noise-rest/tf-via-pr`, formerly under `OP5dev`.

- Good, because it plans, comments and encrypts the plan in one action.
- Bad, because it does not support Terragrunt and works on one directory
  per step.
- Bad, because its encryption is its own, with a passphrase.
- Bad, because the reuse of the plan between plan and apply is listed by
  the project as unsolved.

## More Information

The community has not converged on one successor to Digger; none was found.
