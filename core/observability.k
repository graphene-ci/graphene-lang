# Observability (ADR-0001): first-class, declarative. Emission is
# fixed by the model (every run graph node emits logs / events /
# metrics by existing) — nothing to author. The declaration surface is
# sinks and routing; a system default sink always exists, user
# declarations extend or redirect and cannot create blind spots.

type Stream = "logs" | "events" | "metrics"

schema Sink:
    """Where telemetry is delivered (plugin extension point):
    concrete sinks are plugin schemas inheriting this."""
    kind: str
    name: str

    check:
        len(kind) > 0
        len(name) > 0

schema Route:
    """Which streams go to which sink. Scope narrows down the
    hierarchy via a canonical-address prefix (e.g. "jobs.load");
    empty scope = whole run."""
    sink: Sink
    streams: [Stream]
    scope?: str

    check:
        len(streams) > 0, "route must select at least one stream"
        isunique(streams), "route streams must be unique"

schema Observability:
    sinks: [Sink] = []
    routes: [Route] = []

    check:
        isunique([s.name for s in sinks]), "duplicate sink names"
