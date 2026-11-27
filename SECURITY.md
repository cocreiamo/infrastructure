# Security Policy

This repository describes live infrastructure. A weakness here can be a
weakness there.

## Reporting a vulnerability

Report vulnerabilities privately through GitHub:
[Report a vulnerability](https://github.com/cocreiamo/infrastructure/security/advisories/new).

Do not open a public issue or pull request for a suspected vulnerability, and
do not include a secret, a token or the detail of a plan in any public place.

You will receive an acknowledgement within 7 days. We will keep you informed
while we investigate, and we will credit you in the advisory unless you ask us
not to.

## What is worth reporting

- A way for a pull request, a fork or a workflow to obtain a credential that
  can change resources.
- A secret, or the plaintext of a state or plan file, readable in the
  repository, its history, a log, a comment or an artifact.
- A resource described here that is exposed more than its description says.

A vulnerability in a tool this repository adopts (OpenTofu, Terragrunt, SOPS,
a provider, an action) is best reported to that project first; tell us as well
if our use of it is affected.
