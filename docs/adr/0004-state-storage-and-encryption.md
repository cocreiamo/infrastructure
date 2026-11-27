---
number: 4
title: State in a private bucket, encrypted before it leaves the machine
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# State in a private bucket, encrypted before it leaves the machine

## Context and Problem Statement

The state of OpenTofu holds every attribute of every resource, secrets
included. The repository is public. Where does the state live, and what
protects it?

## Decision Drivers

- The state must never be readable by someone who only obtains the place
  where it is stored.
- Real locking: two applies must not write the same state.
- An earlier version must be restorable.
- Nothing to keep by hand for years: no key or passphrase to guard.
- Ordinary before niche
  ([`infrastructure-principles`](../../skills/infrastructure-principles.md)).

## Considered Options

- A private Google Cloud Storage bucket, with client-side encryption by a
  key service
- Cloudflare R2 through the S3 backend
- State committed to a git branch, encrypted
- A bucket with a passphrase kept in a GitHub secret
- A self-hosted state service

## Decision Outcome

Chosen option: "A private Google Cloud Storage bucket, with client-side
encryption by a key service", because it is the common design, locks
natively, and leaves no key to guard.

1. The state lives in **one private bucket** in the project
   `cocreiamo-infrastructure`, in the European Union, with
   object versioning, uniform bucket-level access and public access
   prevented by policy.
2. **OpenTofu encrypts state and plan files itself**, before they leave the
   machine that produces them, with a key in **Google Cloud KMS**. The
   bucket's own encryption at rest is a second layer.
3. The key rotates automatically once a year. Old versions are never
   destroyed: each costs a few cents a month, and destroying one would make
   unreadable whatever was last written with it. Nobody holds a copy of a
   key: access is granted and removed with IAM, and every use is logged.
4. The bucket and the keys cannot be removed by a change: `prevent_destroy`
   on both, and a lien on the project that holds them
   ([ADR-0009](0009-bootstrap.md)).
5. Each unit has its own state under its own prefix. Terragrunt generates
   the backend and the encryption block for all units from one place.

### Consequences

- Good, because a leaked bucket alone exposes nothing, and a leaked
  permission on the key alone exposes nothing: both are needed.
- Good, because the cost is that of one bucket and a few key versions.
- Bad, because losing the Google Cloud project loses state and keys
  together; the lien, the budget alert and the second billing contact of
  [ADR-0009](0009-bootstrap.md) exist for this.
- Neutral, because reading the state from a laptop needs the maintainer's
  own sign-in and the permission to use the key.

### Confirmation

Requirements R10, R11, R12, R28 and R31 state what must hold; their tests are
not written and are listed in `tests/pending.toml`. The project and the key
ring exist, created by hand ([ADR-0009](0009-bootstrap.md)); the bucket does
not.

## Pros and Cons of the Options

### A private Google Cloud Storage bucket, with client-side encryption by a key service

- Good, because the backend locks natively and keeps versions.
- Good, because Google Cloud is needed anyway for the federation
  ([ADR-0006](0006-pipeline-identity-and-access.md)).
- Bad, because it ties the pipeline to one cloud.

### Cloudflare R2 through the S3 backend

The design of the previous repository, with a passphrase.

- Good, because it would not depend on Google Cloud.
- Bad, because its keys are a secret needed before any secret can be read.
- Bad, because it needs a static token.
- Bad, because its locking was not verified.

### State committed to a git branch, encrypted

Examined on 2026-11-27. Two projects do it:
`plumber-cd/terraform-backend-git` (337 stars; a local process that speaks
the HTTP backend protocol, locks with a branch, encrypts with SOPS) and
`cnuss/actions-state` (state in the GitHub package registry, locks in the
Actions cache).

- Good, because nothing outside GitHub is needed.
- Bad, because no known project runs it in production.
- Bad, because the first does not mention OpenTofu or support Terragrunt,
  and the second has no users, cannot rotate its passphrase and loses the
  state when the repository is renamed.
- Bad, because an apply interrupted before its commit leaves the state
  behind reality.
- Bad, because on a public branch the key would be the only barrier to the
  whole history of the state.

### A bucket with a passphrase kept in a GitHub secret

- Good, because it removes the key service.
- Bad, because a passphrase lost is a state lost, so an offline copy must be
  kept by someone for years.

### Destroying key versions older than two years

- Good, because the cost of the keys stays fixed.
- Bad, because a workflow of ours would have to re-encrypt every state and
  every secret file each year, with write access to all of them.
- Bad, because if it failed unnoticed, the destruction of a version would
  lose a state for a saving of about two dollars a month after ten years.

### A self-hosted state service

- Bad, because it is one more service to run for something a bucket does.
