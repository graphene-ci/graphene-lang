# graphene-lang

The Pkl ecosystem of Graphene CI — the foundation everything else builds on.

## Why this repository exists

Graphene CI workflows are declared in [Pkl](https://pkl-lang.org). Pkl is
**declaration only**: it evaluates to a typed artifact and executes nothing.
This repository owns everything that makes that model work as the system's
"protobuf":

- **Core schemas** (`core/`) — the typed model users and plugins build
  upon, implementing core model v0
  ([ADR-0001](https://github.com/graphene-ci/graphene-docs/blob/main/adr/0001-core-model-v0.md)).
- **Codegen toolchain** (planned) — generates typed bindings in target
  languages from Pkl schemas; schemas and their generated types ship
  together as one versioned artifact.
- **Service IDL** (planned) — a closed set of system-owned RPC contracts
  described in Pkl and generated into client/server stubs. Plugins
  implement these contracts; they never define new ones.
- **Version glue** (planned) — compatibility rules between the Pkl
  evaluator, schema packages, generated bindings, and the toolchain.

## Core schemas (`core/`)

| Module | Owns |
|---|---|
| `workflow.pkl` | `Workflow` root: input schema, resources, hosts, jobs, observability; the eval-time invariants (closed topology, uniqueness, capability coverage, computable demand) |
| `host.pkl` | `Host` — a pure role: name + backing resource; no machine parameters |
| `resource.pkl` | `Resource` — the executor of a role: `EphemeralResource` (provider + hardware, run-scoped) and `PersistentClaim` (registry entry claim) |
| `provider.pkl` | `Provider` base (plugin point): `kind` discriminator, `create`/`connect` modes, capability baseline |
| `job.pkl` | `Job`: host binding, dependency edges with start conditions (`success`/`failure`/`always`), per-host capability accounting |
| `action.pkl` | `Action` base (plugin point): timeout/retry, requires/grants; published contract: pure schema classes (`PushOutputs` with `digest: RuntimeRef`, referenced as `outputsSchema = PushOutputs` — no instantiation); the base builds `push.outputs.digest` refs from the schema by reflection; wire names are the schema field names — nothing to wire, nothing to drift |
| `values.pkl` | Value binding: `SecretRef`, `RuntimeRef`, `ArtifactRef` — deferred references rendered as placeholders |
| `capability.pkl` | Capability names (definitions are capability plugins) |
| `observability.pkl` | Sinks (plugin point) and routing declaration surface |
| `template.pkl` | User-module entry point: `extends` target, declared-inputs reading (`module.input(...)`), artifact rendering with flattened references and demand metadata |

A user workflow `extends "core/template.pkl"`, declares resources, hosts,
and jobs as named top-level properties, and fills `wf`. The rendered
artifact contains only the workflow: object references flattened to names,
deferred values as placeholders, computed capacity demand as metadata.

## Getting started

```sh
make configure   # fetch the pinned pkl into bin/
make test        # valid fixtures must eval, invalid must fail
make eval FILE=tests/valid/cluster.pkl
```

All tools live in `bin/` and are version-pinned in the Makefile — nothing
is installed system-wide.

## Tests

`tests/valid/` — workflows that must evaluate (minimal; a cluster-shaped
one exercising host iteration, persistent claims, edge conditions, grants,
inputs, outputs, artifacts, secrets).
`tests/invalid/` — one fixture per invariant; each must fail eval with a
precise error (`scripts/test.sh` enforces both directions).
`tests/support/testkit.pkl` — test-only concrete providers/actions (real
ones live in `graphene-plugins`).

## Status

Core schemas v0 implemented and tested. Not yet here: package publishing
pipeline, codegen toolchain, service IDL (tracked in the
[roadmap](https://github.com/orgs/graphene-ci/projects/1)).
