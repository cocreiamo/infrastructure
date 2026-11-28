---
number: 12
title: The directory of users and groups stays configured by hand
status: proposed
date: 2026-11-28
decision-makers:
  - founder
---

# The directory of users and groups stays configured by hand

## Context and Problem Statement

The company's directory holds one user, the founder, with the addresses
that are aliases of that mailbox, the role of super administrator, two
domains and two groups for the addresses that a mail domain must answer.
The previous repository described all of it as code. The provider it used
was archived by its maker in November 2026: its last release is of June
2022, and its issues are no longer read. Is the directory described as
code in this repository?

## Decision Drivers

- Adopt what is maintained and widely used; nothing here should need
  attention for years
  ([principles](../../skills/infrastructure-principles.md)).
- Every credential and every delegation is one more thing that can be
  misused.
- What is configured by hand is declared, never forgotten (requirement
  R35).
- The directory changes when a person joins or an address is added: a few
  times a year at most.

## Considered Options

- Leave the directory configured by hand, and declare it
- The archived provider
- A fork of the archived provider
- The groups alone, with the provider of the cloud platform

## Decision Outcome

Chosen option: "Leave the directory configured by hand, and declare it",
because no maintained provider describes it, and what it holds is small
and changes rarely.

1. Users, their aliases, roles of administration, domains, groups and
   their settings are changed in the Admin console by the founder.
2. Each is declared in `configured-by-hand.yaml`, by what it is and without
   any address of a person.
3. The domain-wide delegation given on 2026-11-28 to the two identities of
   the pipeline has no use and is removed.
4. The decision is taken again when a maintained provider exists, or when
   the directory grows beyond what one person keeps in order by hand.

### Consequences

- Good, because the pipeline holds no power over the accounts of the
  company: a mistake in a pull request cannot remove an address or a role
  of administration.
- Good, because nothing unmaintained is adopted.
- Bad, because a change made by hand in the directory is not seen by the
  drift check.
- Bad, because the directory cannot be created again from the repository:
  it would be configured again by hand from the list in
  `configured-by-hand.yaml`.

### Confirmation

It was read on 2026-11-28 in the provider's repository that it is archived
and that its last release is version 0.7.0 of June 2022; no fork of it has
users or a history. The entries of `configured-by-hand.yaml` are written.
The delegation is not removed yet.

## Pros and Cons of the Options

### Leave the directory configured by hand, and declare it

- Good, because it adds no provider, no credential and no delegation.
- Bad, because drift is not detected.

### The archived provider

- Good, because the previous repository used it and its code exists.
- Bad, because nobody will fix it: a change of the platform's interface
  breaks every plan of the unit, with no remedy but removing the unit.
- Bad, because it needs a delegation that lets an identity of the pipeline
  act as the super administrator.
- Bad, because the identity that plans would hold one scope that writes:
  the settings of a group have no read-only scope.

### A fork of the archived provider

- Bad, because the forks found have no users and one author each: it is
  the same risk with an unknown party added.

### The groups alone, with the provider of the cloud platform

- Good, because that provider is maintained and already adopted.
- Bad, because it describes two groups and not their settings, which are
  the part that matters (who may write to them), nor users, domains and
  roles.
- Bad, because it needs a role of administration of the directory given by
  hand to the identities of the pipeline, for two resources.

## More Information

The organization of the cloud platform, which is a different thing from
the directory, is described as code in `organization/`.
