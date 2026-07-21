# graphene-lang

The KCL ecosystem of Graphene CI — the foundation everything else builds on.

## Why this repository exists

Graphene CI workflows are declared in [KCL](https://kcl-lang.io)
([ADR-0002](https://github.com/graphene-ci/graphene-docs/blob/main/adr/0002-workflow-language-kcl.md)).
KCL is **declaration only**: it evaluates hermetically to a typed
artifact and executes nothing. This repository owns everything that
makes that model work as the system's "protobuf":

- **Core schemas** (`core/`) — the typed model users and plugins build
  upon, implementing core model v0
  ([ADR-0001](https://github.com/graphene-ci/graphene-docs/blob/main/adr/0001-core-model-v0.md)).
- **Codegen toolchain** (planned) — generates typed bindings in target
  languages from KCL schemas; schemas and their generated types ship
  together as one versioned artifact.
- **Service IDL** (planned) — a closed set of system-owned RPC contracts
  described over KCL schemas and generated into client/server stubs.
  Plugins implement these contracts; they never define new ones.
- **Version glue** (planned) — compatibility rules between the KCL
  toolchain, schema packages, and generated bindings.

## Core schemas (`core/`)

One KCL package (files share the `core` namespace):

| File | Owns |
|---|---|
| `workflow.k` | `Workflow` root (input schema, resources, hosts, jobs, observability, computed `Demand`), `Job` with dependency edges (`Dependency`, `success`/`failure`/`always`) and per-host capability coverage; the eval-time invariants as `check` blocks |
| `topology.k` | `Provider` (plugin point; `create`/`connect` modes, capability baseline), `Hardware`, `Resource` / `Ephemeral` / `PersistentClaim`, `Host` (pure role — no machine parameters) |
| `action.k` | `Action` base (plugin point; timeout/retry, requires/grants), `Outputs`/`Artifacts` bases for published contracts |
| `values.k` | Value binding: `SecretRef`, `RuntimeRef`, `ArtifactRef` — deferred references carrying their canonical address; `Value` union; `renderValue` |
| `observability.k` | `Sink` (plugin point), `Route`, `Observability` declaration surface |

### Published contract convention

Outputs/artifacts are pure schemas; addresses are wired by a mixin —
the language construct built for exactly this (a mixin reads its host
schema's attributes):

```kcl
schema PushOutputs(core.Outputs):
    digest: core.RuntimeRef            # the whole contract, no plumbing

mixin PushOutputsMixin for core.ActionProtocol:
    outputs: PushOutputs = PushOutputs {
        digest = core.RuntimeRef { expr = "actions.${name}.outputs.digest" }
    }

schema Push(core.Action):
    mixin [PushOutputsMixin]
    outputs?: PushOutputs

push = Push { name = "push-1" }
push.outputs.digest   # -> actions.push-1.outputs.digest, IDE-navigable
```

No owner concept exists; the mixin sees the host's `name` directly.
Mixins are the designated wiring slot — the codegen milestone
generates them from the pure schemas.

## Getting started

```sh
make configure   # fetch pinned kcl + kcl-language-server into bin/
make test        # valid fixtures must eval, invalid must fail
make eval FILE=tests/valid/cluster/main.k
```

All tools live in `bin/` and are version-pinned in the Makefile —
nothing is installed system-wide. For IDE support point your KCL
plugin at `bin/kcl` and `bin/kcl-language-server` (or put them on
PATH).

## Tests

`tests/valid/<name>/main.k` — workflows that must evaluate (minimal; a
cluster-shaped one exercising host iteration, persistent claims, edge
conditions, cross-job grants, inputs, typed outputs, artifacts,
secrets). `tests/invalid/<name>/main.k` — one fixture per invariant; each must fail
eval with a precise named error (`scripts/test.sh` enforces both
directions). `tests/support/testkit.k` — test-only concrete
providers/actions (real ones live in `graphene-plugins`).

## Status

Core schemas v0 implemented and tested on KCL. Known gaps: input reads
use `option()` without declared-only enforcement (moves to CLI
tooling); artifact projection (flattened references) is not yet a
dedicated render step; package publishing, codegen, and the service
IDL are tracked in the [roadmap](https://github.com/orgs/graphene-ci/projects/1).
