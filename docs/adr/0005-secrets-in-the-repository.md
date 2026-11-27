---
number: 5
title: Secrets as encrypted files in the repository, two keys, none in GitHub
status: proposed
date: 2026-11-27
decision-makers:
  - founder
---

# Secrets as encrypted files in the repository, two keys, none in GitHub

## Context and Problem Statement

The providers need credentials that cannot be federated: a Cloudflare API
token and the private keys of GitHub Apps (the token GitHub gives a workflow
cannot manage an organization). The repository is public, so every encrypted
file and its whole history are public for ever. Where are the secrets kept,
and who can read which?

## Decision Drivers

- The founder wants secrets versioned with the code.
- The founder does not want to pay for a secret manager.
- A pull request must never reach a credential that can change something.
- Nothing to keep by hand for years: no key file, no offline copy.

## Considered Options

- SOPS files encrypted with a key service, two keys by what the credential
  can do
- A secret manager
- GitHub Environment secrets alone
- SOPS with an age key kept only in a GitHub Environment secret
- SOPS with an age key in an organization secret

## Decision Outcome

Chosen option: "SOPS files encrypted with a key service, two keys by what the
credential can do", because it versions the secrets, separates reading from
changing, and leaves no key to guard.

1. Secrets are **SOPS files in this repository**, encrypted with keys in
   **Google Cloud KMS**. Terragrunt reads them with `sops_decrypt_file()`.
2. **Two files, two keys**: the `plan` file holds credentials that only
   read, and can be decrypted by the identity of pull requests and by the
   maintainer; the `apply` file holds credentials that can change, and can
   be decrypted only by the identity that applies from `main`
   ([ADR-0006](0006-pipeline-identity-and-access.md)) and by the maintainer.
   `.sops.yaml` chooses the key by path.
3. **GitHub stores no secret.** It holds only variables that are not secret.
4. The maintainer edits a secret with their own sign-in to Google Cloud. No
   key file exists on any machine.
5. **Static credentials are kept to three**: the Cloudflare token and the
   private keys of **two GitHub Apps**, one that can only read (in the
   `plan` file) and one that can change (in the `apply` file). One App would
   not do: its key grants everything the App may do, whoever holds it. No
   personal access token is used, because it expires and belongs to a
   person.
6. A secret that is replaced is also **revoked at its source**: the old
   ciphertext stays in the public history.
7. Changes to the secret files and to `.sops.yaml` have the maintainer as
   code owner and are never taken from a fork.

### Consequences

- Good, because a pull request, even a malicious one from a branch of this
  repository, never reaches a credential that can change something.
- Good, because a person's access is removed with one change of IAM, and
  every use of a key is logged.
- Bad, because SOPS encrypts values, not key names: the names of the
  secrets are public.
- Bad, because anyone with write access to the repository can obtain the
  `plan` identity by changing a workflow in a branch; who has write access
  is trusted at that level.
- Bad, because a value pasted wrongly is found only when a plan fails
  (requirement R33 makes that failure clear).

### Confirmation

Requirements R13, R14, R16 and R33 state what must hold; their tests are not
written. `mise run secrets:check` searches the history for secrets in clear.
Nothing is built yet.

## Pros and Cons of the Options

### SOPS files encrypted with a key service, two keys by what the credential can do

- Good, because the key never leaves the service.
- Bad, because it costs a few cents a month and depends on Google Cloud.

### A secret manager

- Good, because it is made for the purpose.
- Bad, because the founder ruled out its cost.
- Bad, because secrets would not be versioned with the code.

### GitHub Environment secrets alone

- Good, because nothing else is needed.
- Bad, because there is no versioning and no review of a change.
- Bad, because each credential is one more secret to keep in step by hand.

### SOPS with an age key kept only in a GitHub Environment secret

Examined in detail: GitHub secrets cannot be read back, encryption needs only
the public key, and with one file per secret anyone can replace a secret
while only the pipeline can read one.

- Good, because it needs no key service and no key on any laptop.
- Bad, because if the secret holding the key is deleted or replaced, a lost
  state key loses the state, so an offline copy must be kept.
- Bad, because if the key leaks, every ciphertext in the public history is
  readable for ever and nothing can be revoked but the secrets themselves.
- Bad, because nobody can read a value in review, so a file replaced with
  someone else's value passes unseen.
- Bad, because if GitHub is unreachable or the organization locked, nobody
  can operate without the offline copy.

### SOPS with an age key in an organization secret

- Bad, because it is the same as the option above with a wider reach.

## More Information

The difference between the key service and age is not large: in both, who
can run a job in the `apply` Environment gets the secrets. What the key
service removes is the key itself as an object to keep, copy, lose and rotate
by hand.
