# Action (ADR-0001, plugin extension point): the declarative
# projection of imperative work — the user fills typed fields, the
# plugin's executor turns them into real operations at runtime.
#
# PUBLISHED CONTRACT — plain schemas with lazy address defaults:
#
#   schema PushOutputs(core.Outputs):
#       digest: core.RuntimeRef = core.RuntimeRef {
#           expr = "actions.${owner}.outputs.digest"
#       }
#
#   schema Push(core.Action):
#       outputs: PushOutputs = PushOutputs { owner = name }
#
# Users navigate `push.outputs.digest` — real schema fields, jump
# works, a typo is an eval error. The address is built by the schema
# itself from `owner` (lazily bound to the final instance name) —
# nothing to wire, nothing to drift.

import regex

_NAME_RE = r"^[a-z][a-z0-9-]*$"
_CAP_RE = r"^[a-z][a-z0-9._-]*$"

schema RetryPolicy:
    """Retries are invisible to the DAG: dependency edges see only the
    final outcome; every attempt is an observation-plane event."""
    attempts: int = 1
    backoffSeconds: int = 10

    check:
        attempts > 0
        backoffSeconds >= 0

schema Outputs:
    """Base of plugin-declared outputs schemas. Fields are RuntimeRef
    with lazy address defaults over `owner` (the action instance
    name). The schema is also the codegen target for the struct the
    executor fills at runtime."""
    owner: str

schema Artifacts:
    """Base of plugin-declared artifacts schemas; fields are
    ArtifactRef with lazy address defaults over `owner`."""
    owner: str

schema Action:
    """Core of every action. Concrete actions are plugin schemas
    inheriting this; their config fields are opaque to the core.
    The model owns time limits at the action level only (ADR-0001)."""
    name: str
    description?: str
    timeoutSeconds: int = 300
    retry: RetryPolicy = RetryPolicy {}
    requires: [str] = []
    grants: [str] = []
    outputs?: Outputs
    artifacts?: Artifacts

    check:
        regex.match(name, _NAME_RE), "invalid action name ${name}"
        all c in requires { regex.match(c, _CAP_RE) }, "invalid capability name in requires of ${name}"
        all c in grants { regex.match(c, _CAP_RE) }, "invalid capability name in grants of ${name}"
        timeoutSeconds > 0
        outputs.owner == name if outputs, "action ${name}: outputs.owner must equal the action name"
        artifacts.owner == name if artifacts, "action ${name}: artifacts.owner must equal the action name"
