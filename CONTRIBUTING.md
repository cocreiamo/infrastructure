# Contributing

This repository describes the infrastructure of one company. It is public so
that it can be read, reused and corrected; it is maintained by one person.
Corrections and suggestions are welcome as issues or pull requests.

## Before you start

- Read the [Code of Conduct](CODE_OF_CONDUCT.md).
- Report security problems privately, as described in
  [SECURITY.md](SECURITY.md), not in an issue or a pull request.
- Contributions are accepted under the organization's
  [Contributor License Agreement](https://github.com/cocreiamo/anima/blob/main/CLA.md).
  CLA Assistant asks you to sign it on your first pull request
  ([ADR 0001](docs/adr/0001-licence.md)).

## What a pull request from a fork gets

A pull request from a fork receives no credential and no secret, so it gets no
plan ([ADR 0006](docs/adr/0006-pipeline-identity-and-access.md)). The
maintainer reads the change and, if it is to go on, brings it into a branch of
this repository.

## Setting up

Install [mise](https://mise.jdx.dev) or open the development container, then:

```sh
mise trust && mise install
mise run hooks:install
mise run check
```

`mise run check` runs everything CI will run, and `mise run format` formats
your changes.

## Making a change

- Every change reaches `main` through a pull request.
- The pull request title follows
  [Conventional Commits](https://www.conventionalcommits.org), for example
  `feat: add the DNS records of the new site`.
- Every commit is signed.
- A change in what the pipeline or the repository must do starts in the
  requirements model (`model/infrastructure.sysml`).
- A decision that shapes the design is recorded as an ADR in `docs/adr/`,
  with the alternatives that were rejected.
- Every tool, provider, module and action is pinned to an exact version.
- A known gap or defect of an adopted component is an entry in `gaps.toml`.
- Never write the detail of a plan or a value of a resource in public
  ([ADR 0008](docs/adr/0008-plan-visibility.md)).

## Layout

- `docs/adr/`: the architecture decision records.
- `model/`: the requirements model.
- `mise-tasks/`: the tasks that are scripts.
- `.github/` and `.devcontainer/`: repository settings and the development
  container.
- `LICENSES/`: the licence texts REUSE needs.

The directories of the code (`bootstrap/`, `gcp/`, `github/`, `cloudflare/`)
are described in [ADR 0003](docs/adr/0003-repository-and-toolchain.md) and do
not exist yet.
