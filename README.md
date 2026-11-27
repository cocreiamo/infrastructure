# infrastructure

The infrastructure of Cocreiamo as code, in the open: the Google Cloud, GitHub
and Cloudflare resources of the company, described with
[OpenTofu](https://opentofu.org) and
[Terragrunt](https://terragrunt.gruntwork.io) and changed only through pull
requests.

## Status

Design and guardrails only. The repository holds the decisions
([docs/adr/](docs/adr/README.md)), the criteria ([skills/](skills/README.md)),
the requirements ([model/infrastructure.sysml](model/infrastructure.sysml)),
the pinned tools ([mise.toml](mise.toml)) and the checks that guard them. No
resource is managed yet, and no workflow plans or applies. Most verifications
of the model have no test yet: they are listed in
[tests/pending.toml](tests/pending.toml).

## The design in one page

| Subject                 | Decision                                                                                | Record                                                         |
| ----------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Criteria                | Adopt before building, ordinary before niche, little upkeep for years, secure by design | [principles](skills/infrastructure-principles.md)              |
| Tools                   | OpenTofu, Terragrunt and mise, every version exact                                      | [0003](docs/adr/0003-repository-and-toolchain.md)              |
| State                   | A private bucket; state and plans encrypted before they leave the machine               | [0004](docs/adr/0004-state-storage-and-encryption.md)          |
| Secrets                 | Encrypted files in this repository; no secret stored in GitHub                          | [0005](docs/adr/0005-secrets-in-the-repository.md)             |
| Access of the pipeline  | Federated, short-lived; read on pull requests, write only from `main` after approval    | [0006](docs/adr/0006-pipeline-identity-and-access.md)          |
| Pipeline                | GitHub Actions and Terragrunt, no orchestrator                                          | [0007](docs/adr/0007-pipeline-without-an-orchestrator.md)      |
| Plans in a public place | A summary in public, the detail encrypted                                               | [0008](docs/adr/0008-plan-visibility.md)                       |
| Day 0                   | One bootstrap unit, applied by hand once                                                | [0009](docs/adr/0009-bootstrap.md)                             |
| Day 1                   | Existing resources imported until every plan is empty                                   | [method](skills/infrastructure-adopting-existing-resources.md) |
| Day 2                   | Drift reported, updates proposed, `main` protected                                      | [0010](docs/adr/0010-updates-and-drift.md)                     |

## Working on it

Install [mise](https://mise.jdx.dev), then:

```sh
mise trust && mise install
mise run hooks:install
mise run check
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

Copyright 2026 Cocreiamo di Bilotta Francesco.

Licensed under the Apache License, Version 2.0: see [LICENSE](LICENSE).
COCREIAMO is a trademark of Cocreiamo di Bilotta Francesco; the licence does
not grant rights to use it.
