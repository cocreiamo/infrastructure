---
number: 9
title: The bootstrap is one unit, applied by hand and never by the pipeline
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# The bootstrap is one unit, applied by hand and never by the pipeline

## Context and Problem Statement

The pipeline needs a bucket, keys, a federation and service accounts before
it can run, and those are themselves infrastructure. Something must exist
first. How does what the pipeline stands on come to exist, and who changes it?

A previous repository had a state bucket on Cloudflare R2 and a federated
identity in a project named by a generator. That is an accident of history,
not a design: neither is kept.

## Decision Drivers

- The repository must describe everything the pipeline needs, so that it
  could be rebuilt from nothing.
- A pull request must not be able to widen the pipeline's own permissions.
- Adopt a known pattern rather than invent one.
- Losing the project that holds state and keys loses everything.

## Considered Options

- One bootstrap unit, applied by hand
- Leave what already exists outside the code
- Let the pipeline apply the bootstrap

## Decision Outcome

Chosen option: "One bootstrap unit, applied by hand", because it is the
well-known pattern (the `0-bootstrap` stage of Google's example foundation)
and the only option that both describes everything and keeps the pipeline
from changing its own permissions.

1. A unit **`bootstrap/`** describes everything the pipeline needs:
   - the project `cocreiamo-infrastructure`, which holds state and keys,
     with a lien against deletion;
   - the state bucket and the keys
     ([ADR-0004](0004-state-storage-and-encryption.md),
     [ADR-0005](0005-secrets-in-the-repository.md));
   - the federation pool and provider, and the `plan` and `apply` service
     accounts with their permissions
     ([ADR-0006](0006-pipeline-identity-and-access.md));
   - the GitHub Environments, their rules and the repository variables;
   - a budget with an alert, and a second billing contact.
2. **What already exists is imported, not recreated**, by the method of the
   skill
   [`infrastructure-adopting-existing-resources`](../../skills/infrastructure-adopting-existing-resources.md).
   What does not exist is created. Either way the unit ends up describing
   the whole.
3. The founder applies it **by hand, with their own credentials**. It starts
   with a local state, which is then migrated into the state bucket. From
   then on its state is kept like any other, but its changes are still
   applied by hand, never by the pipeline.
4. It is built from published modules where they fit. The federation with
   GitHub is the module `gh-oidc` of
   `terraform-google-modules/github-actions-runners`, pinned by version. The
   project, the keys and the state store are plain resources: each is
   adopted or protected with `prevent_destroy`, which a module cannot
   declare for its caller, and each is one resource.
5. **Three things were created by hand, once, on 2026-11-27**, and are
   imported like any existing resource: the repository, with `gh`; the
   project `cocreiamo-infrastructure`; and its key ring `infrastructure` in
   `europe` with the keys `state`, `secrets-plan`, `secrets-apply` and
   `recovery`, with `gcloud`. The keys came first because the secrets of the previous
   repository had to be re-encrypted before anything else.
6. **The federation and the service accounts are created new** in that
   project: they cannot be moved from the old one, which is closed once
   nothing depends on it.
7. **Billing is a first-class risk.** Over years, the most likely way to
   lose everything is a payment card that expires and a project that is
   suspended and then removed with state and keys. Hence the budget alert
   and the second contact.

### Consequences

- Good, because after the bootstrap a second apply of it changes nothing.
- Good, because the whole could be rebuilt from the repository.
- Bad, because the bootstrap is a place where a person applies from a
  laptop.
- Bad, because whoever can change the bootstrap can give the pipeline any
  permission; its files have the maintainer as code owner.

### Confirmation

Requirements R7, R8, R9 and R12 state what must hold. R12 has its test.
R9 is half met: the budget and the contacts are written, but the founder is
alone and there is no second contact yet. R7 and R8 are verified by a plan
after the apply and have no automated test yet. The steps
are in [the runbook](../runbooks/bootstrap.md). The unit is written and
applied since 2026-11-28, with its state in the state store; only the
deny policy of [ADR-0005](0005-secrets-in-the-repository.md) is still to
apply.

## Pros and Cons of the Options

### One bootstrap unit, applied by hand

- Good, because it is a pattern others have proved.
- Bad, because it cannot be applied by the pipeline it creates.

### Leave what already exists outside the code

- Good, because it works today with nothing to do.
- Bad, because what the pipeline stands on would be the one thing not
  described, and could not be rebuilt.

### Let the pipeline apply the bootstrap

- Good, because every change would go the same way.
- Bad, because a pull request could then widen the pipeline's own
  permissions.
