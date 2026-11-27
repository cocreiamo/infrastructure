---
number: 11
title: Tenants are named by codename in the code and their real names are encrypted
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Tenants are named by codename in the code and their real names are encrypted

## Context and Problem Statement

The infrastructure serves several tenants: Cocreiamo itself, the founder's
own ventures, and clients. Each has resources of its own: a project, a zone, repositories. The
repository is public. A client's domain is public in the DNS, but a public
repository that lists it among Cocreiamo's resources publishes something the
DNS does not: that this person or company is a client. How are tenants named
in the code?

## Decision Drivers

- The repository is public and its history cannot be taken back.
- The link between a client and Cocreiamo is the client's to disclose.
- No personal data in this repository, not even encrypted.
- The code must stay reviewable without access to any key.

## Considered Options

- Codenames in the code, real names in an encrypted map
- Real names in the code
- Tenants in a separate private repository

## Decision Outcome

Chosen option: "Codenames in the code, real names in an encrypted map",
because it leaves the whole infrastructure in one public repository without
publishing who the clients are.

1. A client is named in the code only by a **generated codename**, an
   adjective and a noun. The codename is the
   key of every resource of that tenant and the name of its directory.
2. The real values the code needs (domain, project identifier, repository
   name) are in **one encrypted map**, a SOPS file in this repository keyed
   by codename and encrypted with the key of the `plan` secrets
   ([ADR-0005](0005-secrets-in-the-repository.md)). SOPS leaves the keys in
   clear, so the map can be compared with the directories without any key.
3. **No tenant is named in clear, the company included.** Cocreiamo's own
   domain and resources are a tenant with a codename like any other, and so
   are the founder's own ventures: one rule with no exception, proved on our
   own tenants before a client arrives.
4. **No data about a person is kept here**: contacts, contracts and dates are
   not infrastructure and are kept out of this repository. Where they live
   is decided when the first real client exists.
5. The documents on the processing of personal data (the record of
   processing activities, the erasure procedure) speak of categories, never
   of a single client, and are public in this repository.

### Consequences

- Good, because a reader learns how the infrastructure is built without
  learning whose it is.
- Good, because the public summary of a plan
  ([ADR-0008](0008-plan-visibility.md)) shows codenames only.
- Bad, because the code is harder to read: a reviewer sees `swift-lagoon`,
  not a name.
- Bad, because the name of the organization cannot be hidden: it is in the
  address of this repository, in the licence and in the contact addresses.
  What a codename protects is which domains, projects and repositories
  belong to which tenant.
- Bad, because a codename hides the link, not the domain: whoever already
  knows the domain learns nothing new, and whoever compares the ciphertext
  over time can count the tenants.
- Neutral, because the state holds the real values, encrypted
  ([ADR-0004](0004-state-storage-and-encryption.md)).

### Confirmation

Requirement R34 states what must hold; its test is not written. Nothing is
built yet.

## Pros and Cons of the Options

### Codenames in the code, real names in an encrypted map

- Good, because one repository describes everything.
- Bad, because of the indirection.

### Real names in the code

- Good, because the code reads plainly.
- Bad, because the list of clients is published for ever.

### Tenants in a separate private repository

- Good, because nothing about a client is public, not even a count.
- Bad, because the infrastructure would be split in two, with two pipelines
  and two sets of guardrails to keep.
