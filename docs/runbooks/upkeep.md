# Upkeep: what ages, how it shows, what to do

No infrastructure as code needs no upkeep at all. This repository asks for
attention through issues and pull requests, not through a calendar
([ADR 0010](../adr/0010-updates-and-drift.md)). Nothing described here is
built yet.

| What ages                         | How it shows                               | What to do                                             |
| --------------------------------- | ------------------------------------------ | ------------------------------------------------------ |
| The Cloudflare token              | The plan fails before planning (R33)       | Issue a new token, replace the secret, revoke the old  |
| Tools, providers, modules         | A pull request from Renovate               | Merge when the plan is empty                           |
| A provider's incompatible version | A pull request whose plan is not empty     | Leave it open until there is time to take it           |
| Actions retired by their makers   | A pull request from Renovate, or a warning | Merge when the checks pass                             |
| The payment method                | A budget or billing notice                 | Update it; the second contact receives the notice too  |
| The scheduled drift check         | GitHub disables it after 60 days idle      | Enable the workflow again in the Actions tab           |
| Reality drifting from the code    | An issue opened by the drift check         | Read the plan locally; change the code or the resource |

## Procedures still to write

Requirement R32 asks for a written procedure for each of these. Each is
written with the code it describes:

- the bootstrap, from nothing;
- adding or replacing a secret;
- restoring an earlier version of a state;
- answering a leaked credential.
