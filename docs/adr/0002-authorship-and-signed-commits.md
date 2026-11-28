---
number: 2
title: Authorship, AI assistance and signed commits
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Authorship, AI assistance and signed commits

## Context and Problem Statement

Part of the work is written with an AI assistant. The copyright holder must be
able to stand behind every change, and readers must be able to see how a
change was produced. How is authorship recorded and guaranteed? The same rule
is in force in the `anima` repository and is adopted here unchanged.

## Decision Drivers

- Every change on `main` must be attributable to someone who answers for it.
- The use of an AI assistant must be visible, not hidden.
- The rule must also hold for commits made by automation.

## Considered Options

- Signed commits, with the assistant named in a trailer
- Unsigned commits

## Decision Outcome

Chosen option: "Signed commits, with the assistant named in a trailer",
because it is the only option that makes authorship verifiable.

1. Every commit is reviewed by the founder and signed with the founder's GPG
   key (fingerprint `4898A14E659F7175D2EDCE7F9B54A8DF5D99575C`).
2. Commits made with AI assistance keep the `Co-Authored-By` trailer naming
   the assistant.
3. Nothing is committed or pushed without the founder's approval.
4. Commits made through GitHub's interface (the squashed commit of a merged
   pull request, and the commits of version updates,
   [ADR-0010](0010-updates-and-drift.md)) are signed by GitHub.

### Consequences

- Good, because an unsigned commit on `main` is a defect that the ruleset
  refuses.
- Good, because the history shows which changes had AI assistance.
- Bad, because automation must commit through GitHub's interface to be
  signed, which limits how it can be set up.

### Confirmation

The ruleset of `main` requires signatures (`source-control/rules.tf`,
requirement R20). The ruleset is applied after the first push.

## Pros and Cons of the Options

### Signed commits, with the assistant named in a trailer

- Good, because a signature cannot be claimed after the fact.
- Good, because the trailer costs nothing and tells the truth.

### Unsigned commits

- Good, because nothing has to be set up.
- Bad, because anyone who can push could commit under any name.
