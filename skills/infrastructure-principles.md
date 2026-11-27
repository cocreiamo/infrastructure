---
name: infrastructure-principles
description: "Use when taking or proposing any design decision on the Cocreiamo infrastructure repository, reviewing a proposal or ADR, or choosing between tools or options: the criteria that decide, and the questions to answer before proposing."
---

# Infrastructure principles

The criteria behind every design decision in this repository. They are not
decisions themselves: a decision is an ADR, and each ADR says which of these
criteria settled it.

Cocreiamo is one person. Its infrastructure (Google Cloud, GitHub,
Cloudflare) is described as code in a public repository, and the founder
wants not to have to return to it for years.

## Use this when

- Taking or proposing any design decision.
- Reviewing a proposal, a pull request or an ADR.
- Choosing between options, including tools and scope.

## Rules

1. **Adopt before building.** A need is met first by a feature of a tool
   already adopted, then by a widely used tool, and only last by code of our
   own. Every proposal says which parts are adopted and which are ours, and
   the second list is kept short. Example: OpenTofu's own encryption of plan
   files instead of an action that encrypts them. What is ours today is
   listed in ADR 0007.
2. **Ordinary before niche.** Between two designs that work, the one most
   teams use is chosen, even when the other is more elegant. A project with
   few users, one maintainer or no stated support for our tools is not
   adopted for something the infrastructure depends on. Example: a bucket
   for the state. Not: state in a git branch (ADR 0004).
3. **Little upkeep for years.** A design that leaves something to remember
   (a key to keep offline, a credential that expires, a procedure done by
   hand) loses to one that does not. Upkeep that cannot be removed is turned
   into pull requests that are safe to approve (ADR 0010). Example: a key
   service that rotates keys. Not: a key held only in a GitHub secret with
   an offline copy (ADR 0005).
4. **Secure by design, in the open.** The repository is public and is
   designed as if every file, comment and log were read by an attacker. A
   choice that cannot be undone once something is public is made on the
   cautious side. Example: plan summaries in public, detail encrypted
   (ADR 0008).
5. **Production first.** There is one environment and it is production.
   Nothing is designed as a trial to be hardened later.
6. **Guardrails before code.** No OpenTofu code is written before the checks
   that guard it exist and run: the requirement, its verification, the task
   and the workflow come first.
7. **No extra party.** A service or application run by a third party is not
   given access to the organization when the same result is reached inside
   the platforms already used (GitHub and Google Cloud). Example: Renovate
   run in our own Actions. Not: an orchestrator's cloud (ADR 0007).
8. **The founder decides.** A proposal carries one recommendation; nothing
   is written, committed or applied before the decision.
9. **Facts have a date and a source.** A tool is judged on what its own
   documentation says, read on a stated day. What comes from memory is said
   to come from memory, and what could not be verified becomes an issue.

When two rules conflict, security (4) and little upkeep (3) come before
convenience, and "adopt" (1) does not justify adopting a third party (7).

## Questions to answer before proposing

- Which adopted tool already does this? If none, which widely used one?
- What would be written by us, in how many lines, and who keeps it current?
- What must someone remember or keep for this to go on working in five
  years?
- What becomes public, and can it be taken back?
- Which requirement in the model does it satisfy, and how is it verified?
- Does it give anyone outside GitHub and Google Cloud access to the
  organization?

## Where the result goes

A decision becomes an ADR in `docs/adr/`, with the alternatives rejected and
the rule that rejected them. What must hold becomes a requirement in
`model/infrastructure.sysml`. What is still to decide or to verify becomes an
issue of the repository, never a section of an ADR.
