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
- No third party with access to the organization.
- Every commit on `main` is signed
  ([ADR-0002](0002-authorship-and-signed-commits.md)).
- As little code of our own as possible.

## Considered Options

- Renovate in our own Actions, and a scheduled drift check
- Renovate as the application hosted by its vendor
- Dependabot
- An orchestrator for drift
- No automation: update by hand

## Decision Outcome

Chosen option: "Renovate in our own Actions, and a scheduled drift check",
because it turns upkeep into pull requests without giving a third party
access to the organization.

1. **Drift is reported.** A scheduled workflow plans every unit; when a plan
   is not empty it opens an issue with the summary of
   [ADR-0008](0008-plan-visibility.md). It uses the same action and the
   same command as a pull request.
2. **Updates are proposed, not applied.** Renovate opens a pull request for
   each new version of a tool, a provider, a module or an action. A pull
   request whose plan is empty is safe to merge.
3. **Renovate runs inside our own Actions**, with the token of a GitHub App
   of our own, and makes its commits through GitHub's interface so that
   GitHub signs them.
4. **Renovate comes after the bootstrap**: its App key is a secret of
   [ADR-0005](0005-secrets-in-the-repository.md), which needs the keys and
   the federation to exist ([ADR-0009](0009-bootstrap.md)).
5. **Incompatible changes are taken when the founder chooses.** Versions are
   exact, so a new major version of a provider arrives as a pull request
   that can wait.
6. **Policy as code** (Open Policy Agent) is deferred: `trivy` is enough to
   begin.

### Consequences

- Good, because the repository asks for attention through issues and pull
  requests, not through a calendar.
- Good, because an update is one pull request, one plan, one approval.
- Bad, because the two workflows are ours to keep current.
- Bad, because until the bootstrap exists nothing proposes updates.

### Confirmation

Requirements R29 and R30 state what must hold; their tests are not written.
Neither workflow is built. What ages and how it shows is in the runbook
[upkeep](../runbooks/upkeep.md).

## Pros and Cons of the Options

### Renovate in our own Actions, and a scheduled drift check

- Good, because the drift check is the pattern other tools document too,
  and is a few lines of workflow.
- Bad, because Renovate needs an App and its key.

### Renovate as the application hosted by its vendor

- Good, because there is less to run.
- Bad, because it is a third party on the organization.

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
