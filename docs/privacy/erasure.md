# Erasure of personal data

How the personal data named in the
[record of processing activities](records-of-processing.md) is erased when a
person asks. It lists stores, never people.

Today the infrastructure keeps no store of its own that holds personal data:
no database, no log store, no backup. What exists is held by the providers
below.

## Per store

| Store                                      | How data about a person is erased                                                                                                                                                     |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GitHub: commits, issues, pull requests     | Name and email in commits are the developer's own choice; removing them means rewriting history, at their request. Issues and comments are deleted by the author or by the maintainer |
| GitHub: logs and artifacts of the pipeline | They expire by themselves; a run can be deleted before                                                                                                                                |
| Contributor agreement                      | The record of a signature is kept while the contribution is distributed; it is removed at the processor's                                                                             |
| Google Workspace                           | Delete the user in the Admin console; the user is also removed from the code                                                                                                          |
| Mail sending services                      | Delete the recipient's logs in the provider's console                                                                                                                                 |
| Cloudflare                                 | Logs follow the plan's retention; a person is removed from an access rule in the code                                                                                                 |
| The state of the pipeline                  | Holds resources, not people; a user removed from the code leaves the state at the next apply                                                                                          |
| This repository                            | Holds no data about a person ([ADR-0011](../adr/0011-tenant-codenames.md)); the map of tenants holds names of tenants and domains, encrypted, and an entry is removed with its tenant |

## What cannot be erased

- The history of a public repository, once copied by others.
- Ciphertext already published: removing a tenant from the map removes it
  from the current file, not from the history. This is why the map holds
  only what the code needs and nothing about a person.

## Checks that keep this honest

- Requirement R34 and its test: no real name of a tenant in clear in any
  file.
- This page is reviewed whenever a store is added: a new store without a
  row here is a defect.
