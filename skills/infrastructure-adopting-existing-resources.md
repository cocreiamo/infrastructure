---
name: infrastructure-adopting-existing-resources
description: "Use when bringing a resource that already exists on Google Cloud, GitHub or Cloudflare under code in the infrastructure repository: generating the draft, writing import blocks, and knowing when the adoption is done."
---

# Adopting existing resources

How a resource made by hand comes under code without being recreated
(requirements R22, R23, R24).

## Use this when

- A provider, or part of one, is adopted for the first time.
- A resource was created by hand and must be described after the fact.
- The bootstrap meets something that already exists (ADR 0009).

## Rules

1. **Generate a draft, never the final code.**
   - Cloudflare: `cf-terraforming`, Cloudflare's own tool, generates the
     code and the import declarations from the account as it is.
   - GitHub and Google Cloud: OpenTofu generates the code from `import`
     blocks with the option `-generate-config-out`.
2. **Generate locally, with read-only credentials and a state that is thrown
   away.** The generation works only in a root module, not inside modules.
3. **Clean the draft by hand** before it is committed: remove computed
   attributes and defaults, name resources by what they are for.
4. **The import goes through the pipeline** (R23): the `import` blocks are
   code, reviewed in a pull request and applied like any change. Not:
   `tofu import` run by hand against the real state.
5. **Nothing is created or destroyed** (R24). A plan that proposes either is
   a mistake in the draft, not something to apply.
6. **Done means empty** (R22): the adoption is finished when the plan of
   each unit reports no difference.
7. **What is not worth keeping is left out on purpose** and removed by hand.
   Not: imported and then destroyed.
8. **The first plans show values made by hand.** The rule of ADR 0008
   matters most here: nothing of a plan in a public place.
9. **One provider at a time**, in the order agreed with the founder.

## Questions to answer before proposing

- Does the plan create or destroy anything? Then the draft is wrong.
- Which attributes in the draft are computed by the provider and must go?
- Is the import declared in code, or was a command run by hand?
- Is the plan of every unit empty after the import?

## Where the result goes

The code goes in the directory of its provider (`gcp/`, `github/`,
`cloudflare/`, or `bootstrap/`). A resource left out on purpose is named in
the pull request that adopts its neighbours.
