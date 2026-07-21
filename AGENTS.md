# AGENTS.md — graphene-lang

Read the organization-level `AGENTS.md` (one directory up, org root) first;
its rules apply here in full.

## Scope of this repository

KCL core schemas, the codegen toolchain, the service IDL, version glue,
and the eval artifact format. Nothing here executes workflows — this
repository defines the typed model and its generated bindings.
Language choice: ADR-0002; model: ADR-0001 (both in `graphene-docs`).

## Layout

- `core/` — the core schema package (see README for the file map).
  Normative source: ADR-0001. A schema change that moves an entity or
  invariant requires superseding the ADR first.
- `tests/valid`, `tests/invalid` — eval fixtures; every invariant has
  an invalid fixture that must fail with a precise named error. Adding
  an invariant without its invalid fixture is an incomplete change.
- `scripts/test.sh` — runs both directions; wired as `make test`.
- Tooling: `make configure` fetches pinned `kcl` and
  `kcl-language-server` into `bin/` (versions pinned in the Makefile;
  bumps are explicit commits).

## Working here

- TDD KCL-style: add/extend fixtures first, then schemas until green.
- Precise eval errors are part of the contract: `check` messages name
  the entity and what is missing ("job X: unsatisfied capability
  requirement at host Y").
- Published contract convention: outputs/artifacts are PURE schemas
  inheriting `core.Outputs`/`core.Artifacts` (fields only); addresses
  are wired by a `mixin ... for core.ActionProtocol` reading the host
  action's `name`. Never add plumbing attributes to contract schemas
  or parallel listings of output names.
- Schemas are pure descriptions: no instantiation logic beyond lazy
  attribute defaults.

## Known KCL quirks (extend as found)

- Quantifiers (`all x in <expr> {}`) reject call expressions as the
  iterable — hoist into a `_hidden` computed attribute and use
  `all_true` + comprehensions.
- Multiline comprehensions with `\` continuations break the language
  server (0.11.x) even when the CLI accepts them — keep comprehensions
  on one line or split via `_hidden` attributes.
- String interpolation `${...}` fires in every double-quoted string —
  build placeholder-like literals by concatenation ("$" + "{...}").
- Optional schema attributes are `Undefined`, not `None`, until set —
  guard `check` entries with trailing `if attr` instead of `== None`
  comparisons.
- All `.k` files in one directory form ONE package: top-level names
  collide across files (the CLI compiles single files and hides this;
  the language server compiles the directory and errors). Hence every
  fixture lives in its own directory (`tests/*/<name>/main.k`).
