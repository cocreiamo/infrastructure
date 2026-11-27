# Infrastructure: instructions for AI agents

This repository will hold the infrastructure of Cocreiamo as code, in the open: the Google Cloud, GitHub and Cloudflare resources of the company, described with OpenTofu and Terragrunt and changed only through pull requests. Today it holds the decisions and the requirements; no resource is managed yet.

## Start here

Read `docs/adr/` (index in `docs/adr/README.md`) before proposing anything. The records hold decisions already taken, each with the alternatives that were rejected and why: follow them rather than reopening them. the principles gives the criteria that decide between options.

## Working rules

- The founder leads: propose with one recommendation, get the decision, then build. No speculative work, and no code before the design is agreed.
- Adopt before building: say what is adopted and what would be written by us, and keep the second list short (`infrastructure-principles`).
- Verify before claiming; say what was run, what was read and what comes from memory; report failures and denials plainly.
- Never commit, push, create a repository or change a repository or cloud setting without explicit approval.
- Repository text is English; a requirement never names a product.
- The repository is public: no plan detail, token, origin address or other resource value in a file, a commit message, an issue or a pull request (ADR 0008).
- When a check blocks an action, do not work around it; report it.
- A generated file is never edited by hand: change its source and run `mise run generate`.

## Where facts live

| Kind of fact                            | Home                            |
| --------------------------------------- | ------------------------------- |
| Decisions and rejected alternatives     | `docs/adr/`                     |
| Criteria and methods                    | `skills/`                       |
| Procedures                              | `docs/runbooks/`                |
| Requirements and their verifications    | `model/infrastructure.sysml`    |
| Known gaps and defects of what we adopt | `gaps.toml`                     |
| Tool versions                           | `mise.toml` and `mise.lock`     |
| Generated files                         | written by `mise run generate`  |
| Tests not yet written                   | `tests/pending.toml`, generated |
| Cached and built files                  | `.cache/`                       |
| What is still to decide, verify or do   | issues of the repository        |
