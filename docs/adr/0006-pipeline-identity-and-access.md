---
number: 6
title: The pipeline's identity is federated, reads on pull requests and writes only from main
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# The pipeline's identity is federated, reads on pull requests and writes only from main

## Context and Problem Statement

In a public repository anyone can open a pull request and anyone can comment.
The real risk of infrastructure in the open is not where the state lives but
what a workflow can be made to do. There is one maintainer, so approval by a
second person is not possible. With which identity does the pipeline act, and
when may it change something?

## Decision Drivers

- No stored credential for the platform that holds state and keys.
- Code that is not on `main` must never reach a credential that can change
  a resource.
- A change from outside the repository must obtain nothing.
- One maintainer: the rules must work without a second reviewer.

## Considered Options

- Federated identity, with separate identities to plan and to apply, and
  apply only from `main` after approval
- One federated identity for everything
- A stored service account key
- Apply from a comment on the pull request

## Decision Outcome

Chosen option: "Federated identity, with separate identities to plan and to
apply, and apply only from `main` after approval", because it is the only
option in which unmerged code cannot change anything.

1. **Workload Identity Federation** between GitHub Actions and Google Cloud.
   The pipeline exchanges the token of the run for credentials that last
   minutes.
2. **Two service accounts, two GitHub Environments.** `plan` is used by pull
   requests and by the drift check: it reads the state, decrypts the `plan`
   secrets and reads resources. `apply` is used only by the apply job on
   `main`: it writes the state, decrypts the `apply` secrets
   ([ADR-0005](0005-secrets-in-the-repository.md)) and changes resources.
   The federation accepts a token only from this repository and only with
   the matching Environment.
3. **The `apply` Environment requires the maintainer's approval.** With one
   person this is not a second pair of eyes; it is a deliberate pause: read
   the plan, then approve.
4. **What is applied is what was approved**
   ([ADR-0007](0007-pipeline-without-an-orchestrator.md)).
5. **A pull request from a fork gets nothing**: no secret, no federated
   token, no plan. Workflows use the `pull_request` trigger, never
   `pull_request_target`, and never run on a comment. Workflows of outside
   contributors need the maintainer's approval to run at all.
6. **Rules on `main`**: changes only through a pull request with passing
   checks, squashed; no force push, no deletion; signed commits
   ([ADR-0002](0002-authorship-and-signed-commits.md)); zero required
   approvals, because the only maintainer cannot approve their own pull
   request; the maintainer is code owner of everything.
7. **Actions** come only from GitHub, Google and the makers of the tools
   adopted, pinned by commit, with the least `permissions` each job needs.

### Consequences

- Good, because no credential that can change a resource is reachable from
  code that is not on `main`.
- Bad, because a contributor from outside sees no plan until the maintainer
  brings the change into a branch of the repository.
- Bad, because a person with write access can read at the `plan` level.
- Bad, because of the accepted risk below.

**Accepted risk: one owner.** If the founder loses access to their account,
nobody can operate the Google Cloud organization or the GitHub organization.
A second owner (a trusted person, or an emergency account with a hardware key
kept in a safe) was proposed and declined for now. The founder accepted the
risk on 2026-11-27; it is to be reconsidered when a second person joins.

### Confirmation

Requirements R15, R16, R17, R18, R20 and R21 state what must hold; their
tests are not written. The rules on `main` are in
`.github/rulesets/main.json` and are applied after the first push.
`mise run workflows:check` (actionlint and zizmor) checks pinning and
permissions of every workflow.

## Pros and Cons of the Options

### Federated identity, with separate identities to plan and to apply, and apply only from `main` after approval

- Good, because nothing is stored and nothing expires.
- Bad, because two identities and two Environments must be set up and kept
  apart.

### One federated identity for everything

- Good, because it is simpler.
- Bad, because a pull request could then decrypt the credentials that
  change resources.

### A stored service account key

- Bad, because it is a long-lived credential that can be copied and must be
  rotated by hand.

### Apply from a comment on the pull request

- Good, because the change is applied before it is merged, so `main` always
  reflects reality.
- Bad, because write credentials must be reachable from unmerged code.
- Bad, because anyone can comment on a public repository.
