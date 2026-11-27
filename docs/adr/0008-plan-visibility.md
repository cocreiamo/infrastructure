---
number: 8
title: Plans are summarised in public and their detail is encrypted
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Plans are summarised in public and their detail is encrypted

## Context and Problem Statement

The usual practice is to post the plan as a comment on the pull request. In a
public repository comments and job logs are readable by anyone, are indexed,
and cannot be taken back. OpenTofu hides only the attributes marked as
sensitive. What of a plan may appear in a public place?

Much of what a plan shows is already in the public code. What a plan adds is:

- values the code does not contain: those read from the encrypted secret
  files but not marked sensitive, and those computed by the provider;
- the state before the change: the present values of what is modified or
  destroyed, including things made by hand over the years and just imported;
- origin addresses behind Cloudflare, which let an attacker go around the
  proxy;
- who has access to what: members' addresses, roles, access rules, names of
  private repositories;
- a provider's mistake: a secret not marked as sensitive has happened.

## Decision Drivers

- What is published cannot be taken back.
- The maintainer must still be able to read the whole plan before
  approving.
- As little code of our own as possible.

## Considered Options

- A summary in public, the detail encrypted
- Plans in clear, as most do
- The comment of the official Terragrunt action
- The encryption of the `tf-via-pr` action

## Decision Outcome

Chosen option: "A summary in public, the detail encrypted", because it is the
cautious side of a one-way door: a repository that starts with summaries can
open its plans later, and one that has published them cannot take them back.

1. **No plan in clear in any public place**: not in a comment, not in a job
   log, not in a job summary. The output of the plan goes to a file.
2. **The public comment is a summary**: for each unit, how many resources
   are created, changed and destroyed, and the address of each with its
   action, for example `cloudflare_record.www: update`. Addresses are
   already in the public code; values are not shown.
3. **The detail is the plan file**, encrypted by OpenTofu with the same key
   as the state ([ADR-0004](0004-state-storage-and-encryption.md)) and
   uploaded as an artifact of the run.
4. **The maintainer reads the detail locally**, with a mise task that
   downloads the artifact and shows it, using their own sign-in to Google
   Cloud.
5. The same rule holds for people and assistants: no value of a resource is
   written in an issue, a pull request or a commit message.

### Consequences

- Good, because nothing of a resource is published by the pipeline.
- Good, because for many changes the list of addresses is enough to review.
- Bad, because reading the detail takes one command instead of reading the
  pull request.
- Bad, because a contributor without access to the key sees addresses and
  actions only.
- Bad, because an error message of a provider can still carry a value: the
  plan step must capture its output, and what is printed on failure must be
  designed with care.
- Neutral, because artifacts of a public repository can be downloaded by
  any signed-in user, so the artifact must be the encrypted file and
  nothing else.

### Confirmation

Requirement R19 states what must hold. Its test is not written: it will plan
a resource carrying a known marker value and fail if the marker appears in
any comment, log or summary. Nothing is built yet.

## Pros and Cons of the Options

### A summary in public, the detail encrypted

- Good, because the encryption is a feature of OpenTofu.
- Bad, because the summary and the task that shows the detail are ours
  ([ADR-0007](0007-pipeline-without-an-orchestrator.md)).

### Plans in clear, as most do

- Good, because it is the common practice and needs no code of ours.
- Good, because many public repositories do it without harm.
- Bad, because the risk, though moderate, is irreversible.

### The comment of the official Terragrunt action

- Bad, because it posts the whole output (GAP-002).

### The encryption of the `tf-via-pr` action

- Bad, because it uses a passphrase of its own and does not support
  Terragrunt.
