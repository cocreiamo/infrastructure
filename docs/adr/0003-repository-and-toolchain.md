---
number: 3
title: One repository with OpenTofu, Terragrunt and mise, every version exact
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# One repository with OpenTofu, Terragrunt and mise, every version exact

## Context and Problem Statement

The infrastructure spans three providers (Google Cloud, GitHub, Cloudflare)
and is maintained by one person. With which tools is it described, and how is
the repository organised so that it still works, unchanged, years from now?

## Decision Drivers

- An open licence for the tool that holds the state.
- Encryption of state and plans without a separate tool
  ([ADR-0004](0004-state-storage-and-encryption.md)).
- One command that behaves the same on a laptop and in CI.
- Nothing that changes by itself: no version range, no "latest".
- The criteria of
  [`infrastructure-principles`](../../skills/infrastructure-principles.md).

## Considered Options

- OpenTofu composed by Terragrunt, tools installed by mise
- Plain OpenTofu, without Terragrunt
- Terraform

## Decision Outcome

Chosen option: "OpenTofu composed by Terragrunt, tools installed by mise",
because it is the founder's choice of tools and the only option that meets
every driver.

1. **One public repository**, `cocreiamo/infrastructure`.
2. **OpenTofu** describes the resources.
3. **Terragrunt** composes the units: it generates the backend and the
   encryption configuration once for all of them, reads the encrypted secret
   files ([ADR-0005](0005-secrets-in-the-repository.md)), and works out
   which units a change affects and in which order they run
   ([ADR-0007](0007-pipeline-without-an-orchestrator.md)).
4. **mise** installs every tool and is the only entry point, for the
   maintainer and for CI: `mise run <task>`.
5. **Every version is exact**: tools in `mise.toml` with checksums in
   `mise.lock`, providers in each unit's lock file, modules by version,
   actions by commit.
6. **Layout by provider, not by environment**, because there is one
   environment: `bootstrap/`, `gcp/`, `github/`, `cloudflare/`, and
   `modules/` only where no published module fits. It follows Gruntwork's
   reference structure for Terragrunt.
7. **Requirements live in a SysML v2 model**, `model/infrastructure.sysml`,
   and decisions in MADR records checked by the `adrs` tool, as in `anima`.

The conventions that follow from this decision are in the skill
[`infrastructure-repository-conventions`](../../skills/infrastructure-repository-conventions.md).

### Consequences

- Good, because a person or a runner with mise and nothing else can run
  every check.
- Good, because a tool is updated by a pull request that changes one line
  and the lock.
- Bad, because Terragrunt is one more layer to keep current.
- Bad, because `adrs` is version 0.x with one maintainer; it is pinned.

### Confirmation

`test_R1_every_dependency_pinned` verifies that tools, actions and the
development container are pinned. `mise run check` is the command CI runs
(requirement R2, whose test is not written). The directories of the code do
not exist yet.

## Pros and Cons of the Options

### OpenTofu composed by Terragrunt, tools installed by mise

- Good, because the backend and the encryption are written once.
- Good, because only the affected units are planned.
- Bad, because of the extra layer.

### Plain OpenTofu, without Terragrunt

- Good, because there is one layer fewer to keep current.
- Bad, because the backend, the encryption block and the reading of secrets
  would be repeated in every unit.
- Bad, because working out the affected units would be code of our own.

### Terraform

- Good, because it is the most widely used.
- Bad, because its licence is no longer open.
- Bad, because it does not encrypt state and plan files itself.

## More Information

Tools adopted, each pinned in `mise.toml`: OpenTofu, Terragrunt, SOPS,
cf-terraforming, tflint, trivy, actionlint, zizmor, gitleaks, REUSE, adrs,
the SysML v2 Pilot Implementation, gcloud and gh for the maintainer's
sign-in, and Prettier, taplo, ruff, shellcheck, typos and committed for
formatting, spelling and commit messages.
