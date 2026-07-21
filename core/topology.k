# Execution topology (ADR-0001): job -> host -> resource -> pool.
# Pools are not a workflow entity (system side); providers and
# resources declare the workflow-visible part.

import regex

_NAME_RE = r"^[a-z][a-z0-9-]*$"
_CAP_RE = r"^[a-z][a-z0-9._-]*$"

type ProviderMode = "create" | "connect"

schema Provider:
    """How a resource becomes usable for a run (plugin extension
    point). One plugin kind, two modes: `create` (draw capacity from
    the pool, create the resource, install the agent; destroy at
    release) and `connect` (attach to an existing resource via its
    registry entry; detach at release). `provides` is an obligation:
    the provider is accountable for the baseline, probes may verify
    it. Concrete providers are plugin schemas inheriting this."""
    kind: str
    modes: [ProviderMode]
    provides: [str] = []
    labels: {str:str} = {}

    check:
        len(kind) > 0, "provider kind must be non-empty"
        len(modes) > 0, "provider must declare at least one mode"
        isunique(modes), "provider modes must be unique"
        all c in provides { regex.match(c, _CAP_RE) }, "invalid capability name in provides"

schema Hardware:
    """Hardware spec of an ephemeral resource. Typed so the run's
    total capacity demand is statically computable (invariant 7)."""
    cpu: int = 1
    ramMib: int = 1024
    diskMib: int = 10240

    check:
        cpu > 0
        ramMib > 0
        diskMib > 0

schema Resource:
    """The executor of a host role: the real thing (VM, host,
    container) with identity and lifecycle
    (reserve -> acquire -> use -> release). Hardware and connection
    parameters live here, never on the host. `provides` is the
    author's assertion on top of provider defaults; `allProvides` is
    the declared baseline a bound host inherits."""
    name: str
    provides: [str] = []
    allProvides: [str] = provides

    check:
        regex.match(name, _NAME_RE), "invalid resource name ${name}"
        all c in provides { regex.match(c, _CAP_RE) }, "invalid capability name in resource provides"

schema Ephemeral(Resource):
    """Born at acquire from a provider's pool, run-scoped, dies at
    release. Declared as a full specification."""
    provider: Provider
    hardware: Hardware = Hardware {}
    allProvides: [str] = provider.provides + provides

    check:
        "create" in provider.modes, "resource ${name}: provider ${provider.kind} does not support mode create"

schema PersistentClaim(Resource):
    """A typed claim on a persistent resource — an entry of the system
    resource registry that exists independently of runs. Acquire means
    attach, release means detach. `provides` mirrors the registry
    declaration (hermetic eval cannot query the registry); it is
    validated against the entry at run start and probed at attach."""
    registryRef: str
    providerKind: str

    check:
        len(registryRef) > 0, "claim ${name}: registryRef must be non-empty"
        len(providerKind) > 0, "claim ${name}: providerKind must be non-empty"

schema Host:
    """A pure role: a named execution place jobs bind to. Carries NO
    machine parameters — hardware, image, and connection details are
    the backing resource's responsibility. The host->resource
    indirection keeps roles stable while executors are swappable."""
    name: str
    backedBy: Resource

    check:
        regex.match(name, _NAME_RE), "invalid host name ${name}"
