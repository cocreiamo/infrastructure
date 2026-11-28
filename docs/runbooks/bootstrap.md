# Bootstrap: what the pipeline stands on

The unit `bootstrap/` describes everything the pipeline needs in order to
run ([ADR-0009](../adr/0009-bootstrap.md)): the project, the keys, the state
store, the two identities and their federation, the two Environments of the
repository, the budget and the contacts. The maintainer applies it by hand,
with their own sign-in. The pipeline never applies it.

## Before

- Signed in with `gcloud auth login` as an owner of the project, and with
  `gh auth login` as an owner of the organization.
- The sign-in holds the role Deny Admin on the Google Cloud organization:
  owning the project is not enough to write a deny policy.
- `bootstrap/inputs.enc.yaml` holds the id of the organization, the id of the
  billing account and the contacts: the maintainer first, then every other
  person. Today there is only the maintainer; requirement R9 asks for a
  second person and stays unverified until one is added.

No credential file is written: each command takes the sign-in from `gcloud`
and `gh` for its own length.

## Any change after the first time

```sh
mise run bootstrap -- plan
mise run bootstrap -- apply
```

`apply` applies the plan that `plan` just wrote, nothing else. A plan made on
a bootstrapped system with no change in the code reports no difference (R7).

## The first time, from nothing

The state store does not exist yet, so the first state stays on the machine,
already encrypted with the `state` key, and is moved afterwards.

1. By hand, once: the project, the key ring `infrastructure` and its keys
   exist already and are adopted, not created
   ([ADR-0009](../adr/0009-bootstrap.md)). Starting again from nothing, create
   the project and the `state` key first: the state of this very unit is
   encrypted with it.
2. Plan and apply with the state on the machine:

   ```sh
   BOOTSTRAP_LOCAL_STATE=1 mise run bootstrap -- plan
   BOOTSTRAP_LOCAL_STATE=1 mise run bootstrap -- apply
   ```

   Read the plan before applying: it must import what exists and destroy
   nothing.

3. Move the state into the state store, then check that nothing differs:

   ```sh
   mise run bootstrap -- init -migrate-state
   mise run bootstrap -- plan
   ```

   The copy left in `.cache/state/` is deleted once the plan is empty.

4. Move the write credentials to the key no person can use. In `.sops.yaml`,
   point the rule of `secrets/apply/` at the key `secrets-apply` of the key
   ring `infrastructure-apply`, then for each file run
   `sops updatekeys --yes <file>`. This is the last time a person's sign-in
   reads them: it works only while the old key still answers.
5. Check the denial: `sops decrypt` of a file of `secrets/apply/` must now be
   refused to the maintainer.
6. Replace each write credential at its source. The old ciphertexts stay in
   the public history, readable with the superseded key, until the
   credential they hold is no longer valid.
7. In the Admin console of the workspace, delegate domain-wide authority to
   the two new identities (`configured-by-hand.yaml`).

## What cannot be undone by a change

The state store, every key and the project carry `prevent_destroy`, and the
project a lien: a plan that would remove one of them fails. To remove one on
purpose, the protection is removed in a first change and the resource in a
second.
