---
number: 10
title: Drift is reported and updates are proposed as pull requests
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Drift is reported and updates are proposed as pull requests

## Context and Problem Statement

The founder wants not to return to this repository for years. No
infrastructure as code needs no upkeep at all: providers change, actions are
retired, tokens end, and someone changes a resource by hand. How does the
repository stay current, and how does the maintainer learn that reality has
moved?

## Decision Drivers

- Upkeep must arrive as something safe to approve, not as a task to
  remember.
- The repositories of the organization should work the same way.
- Every commit on `main` is signed
  ([ADR-0002](0002-authorship-and-signed-commits.md)).
- As little code of our own as possible.

## Considered Options

- Renovate as the application hosted by its vendor, and a scheduled drift
  check
- Renovate in our own Actions
- Dependabot
- An orchestrator for drift
- No automation: update by hand

## Decision Outcome

Chosen option: "Renovate as the application hosted by its vendor, and a
scheduled drift check", because it turns upkeep into pull requests with
nothing to run, works from the first day, and is how `anima` does it.

1. **Drift is reported.** A scheduled workflow plans every unit; when a plan
   is not empty it opens an issue with the summary of
   [ADR-0008](0008-plan-visibility.md). It uses the same action and the
   same command as a pull request.
2. **Updates are proposed, not applied.** Renovate opens a pull request for
   each new version of a tool, a provider, a module or an action. A pull
   request whose plan is empty is safe to merge.
3. **Renovate is the application hosted by its vendor**, installed on the
   organization and configured by `.github/renovate.json`, as in `anima`.
   It pins actions by commit and images by digest.
4. **Renovate holds no cloud credential and no secret of ours.** Its pull
   requests come from a branch of this repository and are planned like any
   other, with the `plan` identity
   ([ADR-0006](0006-pipeline-identity-and-access.md)); nothing it proposes
   is applied without the maintainer's merge and approval.
5. **The drift check stays alive by activity.** GitHub disables scheduled
   workflows of a public repository after 60 days without activity (GitHub
   documentation, read on 2026-11-27); Renovate's merged pull requests are
   that activity. When GitHub disables one it says so, and the workflow is
   enabled again by hand ([upkeep](../runbooks/upkeep.md)).
6. **Incompatible changes are taken when the founder chooses.** Versions are
   exact, so a new major version of a provider arrives as a pull request
   that can wait.
7. **Policy as code** (Open Policy Agent) is deferred: `trivy` is enough to
   begin.

### Consequences

- Good, because the repository asks for attention through issues and pull
  requests, not through a calendar.
- Good, because an update is one pull request, one plan, one approval.
- Bad, because a third party has write access to the repositories of the
  organization.
- Bad, because the drift workflow is ours to keep current.

### Confirmation

Requirements R29 and R30 state what must hold; their tests are not written.
The drift workflow is not built. `.github/renovate.json` exists and the application was installed on every
repository of the organization on 2026-11-27. What ages and how it shows is in the runbook
[upkeep](../runbooks/upkeep.md).

## Pros and Cons of the Options

### Renovate as the application hosted by its vendor, and a scheduled drift check

- Good, because there is nothing to run and nothing to wait for.
- Good, because the drift check is the pattern other tools document too,
  and is a few lines of workflow.
- Bad, because it is a third party on the organization.

### Renovate in our own Actions

- Good, because no third party is given access.
- Bad, because it needs an App and its key, which is a secret of
  [ADR-0005](0005-secrets-in-the-repository.md), so it could not start
  before the bootstrap ([ADR-0009](0009-bootstrap.md)).
- Bad, because it is one more workflow of ours, and unlike `anima`.

### Dependabot

- Good, because it is native to GitHub, with no application to run.
- Bad, because from memory it does not cover mise and Terragrunt; not
  verified.

### An orchestrator for drift

- Bad, because it brings back what
  [ADR-0007](0007-pipeline-without-an-orchestrator.md) rejected, for ten
  lines of workflow.

### No automation: update by hand

- Bad, because it is a task to remember for years.
