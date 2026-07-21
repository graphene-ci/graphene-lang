# graphene-lang

The Pkl ecosystem of Graphene CI — the foundation everything else builds on.

## Why this repository exists

Graphene CI workflows are declared in [Pkl](https://pkl-lang.org). Pkl is
**declaration only**: it evaluates to a typed artifact and executes nothing.
This repository owns everything that makes that model work as the system's
"protobuf":

- **Core schemas** — `workflow`, `machine`, `job`, `action`, `provider`,
  `capability`, `values`: the typed model users and plugins build upon.
- **Codegen toolchain** — generates typed bindings in target languages from
  Pkl schemas; schemas and their generated types ship together as one
  versioned artifact.
- **Service IDL** — a closed set of system-owned RPC contracts described in
  Pkl and generated into client/server stubs. Plugins implement these
  contracts; they never define new ones.
- **Version glue** — compatibility rules between the Pkl evaluator, schema
  packages, generated bindings, and the toolchain itself.
- **Eval artifact format** — the serialized form of an evaluated workflow
  that the runtime consumes.

## Status

Bootstrap skeleton. No schemas or tooling yet.

## Getting started

```sh
make configure   # set up a working environment from scratch
make help        # list all targets
```

All tools and generated binaries live in `bin/` — nothing is installed
system-wide.
