# Record of processing activities (GDPR Article 30)

This is the record of the processing that the infrastructure described in this
repository carries out or makes possible. It is public on purpose. It speaks
of categories of people and of data, never of a single person or client
([ADR-0011](../adr/0011-tenant-codenames.md)).

It is written by the maintainer, not by a lawyer, and describes the
infrastructure as it is: it does not cover what an application hosted for a
tenant does with its own users' data, which belongs to the record of that
application.

## Scope and roles

- **Controller**: Cocreiamo di Bilotta Francesco, for the processing below.
- **Contact**: privacy requests go to the address in the
  [security policy](../../SECURITY.md) until a dedicated address is
  published.
- **Not in scope today**: there is no cluster, no hosted application, no
  log, metric or trace store, no analytics and no backup of personal data.
  The record of the previous platform listed fourteen activities; ten of
  them described stores that no longer exist.

## Processing activities

| #   | Activity                     | Data subjects               | Categories of personal data              | Purpose                                 | Legal basis         | Retention                                   |
| --- | ---------------------------- | --------------------------- | ---------------------------------------- | --------------------------------------- | ------------------- | ------------------------------------------- |
| 1   | Source code and its history  | maintainer and contributors | name, email address, GitHub account      | to develop and review the code          | legitimate interest | as long as the repository exists            |
| 2   | Pipeline runs                | maintainer and contributors | GitHub account, in the logs of each run  | to check and apply changes              | legitimate interest | as long as GitHub keeps logs and artifacts  |
| 3   | Contributor agreement        | contributors                | GitHub account, date of signature        | to record the licence of a contribution | contract            | as long as the contribution is distributed  |
| 4   | Staff mailbox and directory  | staff                       | name, email address, mail and calendar   | to work                                 | contract            | until the account is deleted                |
| 5   | Transactional email          | recipients of mail we send  | email address, message                   | to deliver the message                  | contract            | as long as the sending service keeps logs   |
| 6   | Mail authentication reports  | none identifiable           | sending servers and counts, no addresses | to protect the domains from forgery     | legitimate interest | as long as the receiving service keeps them |
| 7   | Network protection           | visitors of the sites       | IP address, request metadata             | to protect the sites                    | legitimate interest | as long as the provider keeps logs          |
| 8   | Heartbeat of the drift check | none                        | none                                     | to know the check ran                   | not personal data   | not applicable                              |

No special category of data and no data about criminal convictions is
processed. No decision is taken by automated means about a person.

## Processors and recipients

| Processor                 | Service                                         | Data                                         |
| ------------------------- | ----------------------------------------------- | -------------------------------------------- |
| GitHub, Inc.              | repositories, pipeline, contributor identities  | activities 1, 2                              |
| CLA Assistant (SAP)       | signature of the contributor agreement          | activity 3                                   |
| Google (Workspace, Cloud) | mail, directory, keys and state of the pipeline | activity 4; the state holds no personal data |
| Amazon Web Services (SES) | sending mail                                    | activity 5                                   |
| Mailtrap (Railsware)      | sending mail for one tenant                     | activity 5                                   |
| Cloudflare, Inc.          | DNS, protection of the sites, mail routing      | activities 6, 7                              |
| Healthchecks.io           | heartbeat                                       | none                                         |
| Domain registrars         | registration of the domains                     | registrant data of the owner of each domain  |

## Transfers outside the European Union

GitHub, Google, Amazon Web Services and Cloudflare are companies of the
United States. State and keys are kept in the European Union
([ADR-0004](../adr/0004-state-storage-and-encryption.md)). The mechanism of
each transfer is the one each processor declares in its own data processing
terms.

## Security measures (Article 32)

- Nothing that changes a resource is reachable from code that is not on
  `main` ([ADR-0006](../adr/0006-pipeline-identity-and-access.md)).
- State and secrets are encrypted before they leave the machine that
  produces them, with keys nobody holds
  ([ADR-0004](../adr/0004-state-storage-and-encryption.md),
  [ADR-0005](../adr/0005-secrets-in-the-repository.md)).
- Nothing of a resource is published by the pipeline
  ([ADR-0008](../adr/0008-plan-visibility.md)).
- No data about a person is kept in this repository
  ([ADR-0011](../adr/0011-tenant-codenames.md)).

## To review with a lawyer

- The legal basis and the retention of each activity, written here by the
  maintainer.
- Where each processor keeps the data and the mechanism of each transfer,
  not verified against the current terms of each processor.
- Whether a dedicated address for privacy requests is needed.
- This record is rewritten when the first application is hosted for a
  tenant.
