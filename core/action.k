# Action (ADR-0001, plugin extension point): the declarative
# projection of imperative work — the user fills typed fields, the
# plugin's executor turns them into real operations at runtime.
#
# PUBLISHED CONTRACT — pure schemas + mixins (the language construct
# built for exactly this: a mixin reads its host schema's attributes):
#
#   schema PushOutputs(core.Outputs):
#       digest: core.RuntimeRef        # the whole contract, no plumbing
#
#   mixin PushOutputsMixin for core.ActionProtocol:
#       outputs: PushOutputs = PushOutputs {
#           digest = core.RuntimeRef { expr = "actions.${name}.outputs.digest" }
#       }
#
#   schema Push(core.Action):
#       mixin [PushOutputsMixin]
#       outputs?: PushOutputs
#
# Users navigate `push.outputs.digest` — real schema fields, jump
# works, a typo is an eval error. The mixin builds addresses from the
# host's `name` directly; no owner concept exists. Mixins are the
# designated wiring slot — the codegen milestone generates them from
# the pure schemas.

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
    """Marker base of plugin-declared outputs schemas. Fields are
    RuntimeRef; addresses are wired by the plugin's outputs mixin from
    the host action's name. The schema is pure — it is also the
    codegen target for the struct the executor fills at runtime."""

schema Artifacts:
    """Marker base of plugin-declared artifacts schemas; fields are
    ArtifactRef, wired by the plugin's artifacts mixin."""

protocol ActionProtocol:
    """Host type for plugin output/artifact mixins: gives a mixin
    access to the action instance's name and contract slots."""
    name: str
    outputs?: Outputs
    artifacts?: Artifacts

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

