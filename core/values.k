# Value binding (ADR-0001): a configuration value is either resolved
# at eval (literals, workflow inputs) or a typed deferred reference —
# a placeholder for a value that does not exist at eval time. The
# reference persists in the model; the value materializes only within
# a run. References carry their canonical address in content: copies
# are the only thing that survives eval, so provenance must live in
# the value itself.

schema SecretRef:
    """Resolved by the system from a secret backend, as late as
    possible. Forcibly ephemeral: delivered to the point of use, then
    destroyed; never present in artifacts, run state, telemetry, or
    logs. Whether a workflow may reference a given path is system-side
    authorization (secret scoping), not the model's concern."""
    path: str
    key?: str
    placeholder: str = "$" + "{secret:" + path + "}" if key == None else "$" + "{secret:" + path + "#" + key + "}"

    check:
        len(path) > 0, "secret path must be non-empty"

schema RuntimeRef:
    """Resolved from run state (an action output); the value does not
    exist until execution produces it. Lives in run state:
    addressable, observable, part of run history."""
    expr: str
    placeholder: str = "$" + "{runtime:" + expr + "}"

    check:
        len(expr) > 0, "runtime ref expr must be non-empty"

schema ArtifactRef:
    """Resolved by the runtime into a local path on the consuming
    host; the blob lives in system storage and is delivered by the
    system."""
    expr: str
    placeholder: str = "$" + "{artifact:" + expr + "}"

    check:
        len(expr) > 0, "artifact ref expr must be non-empty"

# A config value: literal or deferred reference.
type Value = str | SecretRef | RuntimeRef | ArtifactRef

# Render a Value into its artifact form.
renderValue = lambda v: Value -> str {
    v.placeholder if typeof(v) in ["SecretRef", "RuntimeRef", "ArtifactRef"] else v
}
