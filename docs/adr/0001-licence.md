---
number: 1
title: Apache-2.0, with licence information on every file
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Apache-2.0, with licence information on every file

## Context and Problem Statement

The repository is published so that others can read and reuse it. It holds
configuration, not a product: there is nothing to sell under a second licence,
unlike the `anima` repository. Under which licence is it published, and how is
the licence of each file made known?

## Decision Drivers

- The licence should be the one readers of infrastructure code expect.
- Nothing should be asked of a contributor that the repository does not need.
- Every file must be traceable to a licence and a copyright holder.

## Considered Options

- Apache-2.0, without a contributor agreement
- AGPL-3.0 with a contributor agreement, as in `anima`

## Decision Outcome

Chosen option: "Apache-2.0, without a contributor agreement", because it is
the usual licence of infrastructure code and of the tools it uses, and nothing
here needs a second licence.

1. The repository is licensed under the Apache License 2.0.
2. Every file carries copyright and licence information, following the
   [REUSE](https://reuse.software) specification: `REUSE.toml` has one
   annotation for everything Cocreiamo writes and an `override` annotation
   for each adopted text.
3. Adopted texts keep their licence: the Contributor Covenant
   (CC-BY-SA-4.0), the pull request template adapted from Kubernetes and the
   issue form adapted from Keycloak (both Apache-2.0).
4. The licence does not grant rights to the COCREIAMO trademark. No separate
   trademark policy is kept here.

### Consequences

- Good, because a contribution is licensed under Apache-2.0 by section 5 of
  the licence, with nothing to sign.
- Good, because anyone may reuse the code for their own infrastructure.
- Neutral, because the licence differs from that of `anima`.

### Confirmation

`mise run licenses:check` runs `reuse lint`; the test
`test_R3_every_file_licensed` verifies requirement R3.

## Pros and Cons of the Options

### Apache-2.0, without a contributor agreement

- Good, because it is what the ecosystem uses.
- Good, because it carries a patent grant and its own contribution clause.

### AGPL-3.0 with a contributor agreement, as in `anima`

- Good, because both repositories would have one licence.
- Bad, because the agreement exists there to allow commercial licences,
  which do not apply to configuration.
- Bad, because it asks every contributor to sign something for no benefit.
