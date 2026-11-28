---
name: infrastructure-repository-conventions
description: "Use when adding or moving files in the infrastructure repository, deciding whether something is an ADR, a skill, a runbook, a requirement or an issue, or changing CI, mise tasks, git hooks, formatting, linting, REUSE annotations, commit or pull request rules."
---

# Repository conventions

How files, documents, checks and tasks are organised in this repository
(ADR 0002, 0003).

## Use this when

- Adding or moving files, or choosing where something is written down.
- Changing CI, mise tasks, hooks, formatting or linting.
- Preparing a commit or a pull request.

## Where a thing is written

| It is                                          | It goes in                              |
| ---------------------------------------------- | --------------------------------------- |
| A decision, with the alternatives that lost    | An ADR, `docs/adr/`                     |
| A criterion or a method to follow when working | A skill, `skills/`                      |
| A procedure a person carries out               | A runbook, `docs/runbooks/`             |
| Something the system must do                   | A requirement, `model/`                 |
| A defect or gap of something we adopt          | An entry of `gaps.toml`                 |
| Something still to decide, verify or do        | An issue of the repository              |
| An accepted risk                               | The ADR of the decision that carries it |

An ADR is not a place for principles, for steps to carry out or for open
questions. If a text would still be true whatever was decided, it is a skill;
if it will be closed one day, it is an issue.

## The format of an ADR

**An ADR is a MADR 4.0.0 record**, written with the `adrs` tool
(`adrs new`), with YAML front matter: `number`, `title`, `status`,
`date`, `decision-makers` (a role, `founder`, never a person's name).
Rejected alternatives go in "Considered Options" and "Pros and Cons of
the Options", each reason as "Bad, because …". What is decided but not
built goes in "Confirmation". References between ADRs are Markdown links
(`[ADR-0004](0004-….md)`), because `adrs doctor` checks links, not text.

## Rules

1. **`mise run <task>` is the only entry point**, locally and in CI. Tools
   come from `mise.toml` (exact versions, `mise.lock` with checksums) and
   nowhere on the host. Not: a workflow step that calls a tool directly.
2. **A script task is a mise file task** in `mise-tasks/`. Not: a `tools/`
   or `scripts/` directory.
3. **Hooks are generated** by `mise run hooks:install`: `pre-commit` (fast
   checks), `commit-msg` (`committed`), `pre-push` (every check).
4. **Generated files are generated, never edited by hand.** `mise run
generate` writes them and `mise run generate:check` fails when one is
   stale (R6). Today: `docs/adr/README.md`, `skills/README.md`,
   `.claude/skills/<name>/SKILL.md`, `tests/pending.toml`. To add one, add
   its generator to `mise-tasks/generate/generators.py`.
5. **One ignored directory, `.cache/`.**
6. **Layout by capability, not by provider** (ADR 0003): `bootstrap/`,
   `organization/`, `source-control/`, `dns/`, `email/`, `edge/`,
   `monitoring/`, `tenants/<codename>/`, and `modules/` only where no
   published module fits. A directory is named for what it does, never for a
   product. A client appears only as its codename (ADR 0011).
7. **Every version is exact** (R1): tools, providers, modules, and actions
   by commit.
8. **Formatting and linting tools, by what they cover.** `tofu fmt` and
   `terragrunt hcl fmt` (code), `tflint` and `trivy` (code), `actionlint`
   and `zizmor` (workflows), `ruff` (Python), `shellcheck` (shell), Prettier
   (Markdown, YAML, JSON), `taplo` (TOML), `typos` (spelling). `mise run
format` formats; `mise run check` checks everything.
9. **REUSE for every file** (R3). `REUSE.toml` has a catch-all annotation
   (Apache-2.0, Cocreiamo) and an `override` for each adopted text, naming
   its authors and licence.
10. **A requirement never names a product**, and each has a verification
    named like its test, `test_<id>_<what it checks>`. A verification
    without a test is listed in `tests/pending.toml`, which is generated.
11. **Conventional Commits** on commits and pull request titles. Example:
    `feat: add the DNS records of the new site`.
12. **Signed commits only**, and every change reaches `main` through a pull
    request (ADR 0002, 0006).
13. **Never commit, push or change a repository or cloud setting without the
    founder's explicit approval.**
14. **A workflow is pinned and least-privileged** (R21): actions by commit,
    minimal `permissions`, no untrusted input in a shell, `zizmor` clean.
15. **Nothing of a resource in public** (ADR 0008): no plan detail, token,
    origin address or attribute value in a file, a commit message, an issue
    or a pull request.
16. **A workaround names its `GAP-nnn` in a comment**, and a test checks
    that every id used is registered (R5).

17. **A unit is tested without credentials.** Its tests are in
    `<unit>/tests/*.tftest.hcl`, plan it against simulated providers and
    are run by `mise run code:test`. A run that implements a verification
    is named like it, `test_<id>_<what it checks>`.
18. **A unit includes `root.hcl`** and declares no backend and no
    encryption: both are generated from that one file (ADR 0004). Values
    that are not public come from an encrypted file next to the unit.

## Questions to answer before proposing

- Which task runs this, locally and in CI, with the same command?
- Does the change add an ignored directory, a script or a tool outside mise?
- Can the new file be derived from another? Then generate it.
- Is this text a decision, a criterion, a procedure or an open question?
- Does the change need a repository setting? Then ask the founder.

## Where the result goes

Layout and toolchain decisions amend ADR 0003. Rules for contributors go to
`CONTRIBUTING.md`. Tasks go to `mise.toml` or `mise-tasks/`; settings to
`.github/`.
