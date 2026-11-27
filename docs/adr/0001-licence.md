---
number: 1
title: Apache-2.0, the organization's contributor agreement, and licence information on every file
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Apache-2.0, the organization's contributor agreement, and licence information on every file

## Context and Problem Statement

The repository is published so that others can read and reuse it. It holds
configuration, not a product: there is nothing to sell under a second licence,
unlike the `anima` repository. Under which licence is it published, and how is
the licence of each file made known?

## Decision Drivers

- The licence should be the one readers of infrastructure code expect.
- The repositories of the organization should work the same way.
- Every file must be traceable to a licence and a copyright holder.

## Considered Options

- Apache-2.0, with the organization's contributor agreement
- Apache-2.0, without a contributor agreement
- AGPL-3.0 with a contributor agreement, as in `anima`

## Decision Outcome

Chosen option: "Apache-2.0, with the organization's contributor agreement",
because Apache-2.0 is the usual licence of infrastructure code and of the
tools it uses, and the agreement is already asked on every repository of the
organization: exempting this one would be more work than keeping it, and it
does no harm.

1. The repository is licensed under the Apache License 2.0.
2. Every file carries copyright and licence information, following the
   [REUSE](https://reuse.software) specification: `REUSE.toml` has one
   annotation for everything Cocreiamo writes and an `override` annotation
   for each adopted text.
3. Adopted texts keep their licence: the Contributor Covenant
   (CC-BY-SA-4.0), the pull request template adapted from Kubernetes and the
   issue form adapted from Keycloak (both Apache-2.0).
4. Contributions are accepted under the organization's contributor
   agreement, the same text as
   [`CLA.md` of `anima`](https://github.com/cocreiamo/anima/blob/main/CLA.md),
   signed on the first pull request with CLA Assistant, which is connected
   to the whole organization.
5. The licence does not grant rights to the COCREIAMO trademark. No separate
   trademark policy is kept here.

### Consequences

- Good, because every repository of the organization asks the same of a
  contributor.
- Bad, because a contributor signs an agreement this repository does not
  strictly need.
- Good, because anyone may reuse the code for their own infrastructure.
- Neutral, because the licence differs from that of `anima`.

### Confirmation

`mise run licenses:check` runs `reuse lint`; the test
`test_R3_every_file_licensed` verifies requirement R3. CLA Assistant reports
on each pull request as the check `license/cla`.

## Pros and Cons of the Options

### Apache-2.0, with the organization's contributor agreement

- Good, because it is what the ecosystem uses, with a patent grant.
- Good, because nothing has to be configured differently for this
  repository.

### Apache-2.0, without a contributor agreement

- Good, because section 5 of the licence already covers contributions.
- Bad, because CLA Assistant is connected to the whole organization, so this
  repository would have to be exempted and kept exempt.

### AGPL-3.0 with a contributor agreement, as in `anima`

- Good, because both repositories would have one licence.
- Bad, because the agreement exists there to allow commercial licences,
  which do not apply to configuration.
- Bad, because it asks every contributor to sign something for no benefit.
