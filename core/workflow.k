# Workflow (ADR-0001): the root entity — the complete, closed set of
# hosts, resources, and jobs of one run, plus the input schema. The
# check blocks implement the eval-time invariants: closed topology,
# name uniqueness, capability coverage, computable demand.

import regex

_NAME_RE = r"^[a-z][a-z0-9-]*$"

type EdgeCondition = "success" | "failure" | "always"

schema Dependency:
    """A dependency edge with an explicit start condition (failure
    semantics live on the edge, ADR-0001): `success` (default),
    `failure` (error handlers), `always` (cleanup/reports)."""
    job: Job
    on: EdgeCondition = "success"

schema Job:
    """The unit of scheduling: binds to exactly one host, depends on
    other jobs (the DAG), carries an ordered non-empty sequence of
    actions executed at that host by its resource's agent. Job
    outcomes: success / failed / skipped / canceled."""
    name: str
    runsOn: Host
    needs: [Dependency] = []
    actions: [Action]

    # capability coverage (invariant 4): for action i the available
    # set is the host baseline (inherited from its backing resource)
    # + grants of needs-jobs on the same host + grants of earlier
    # actions of this job. Per-host ledger — deliberately conservative
    # for shared resources.
    _needsGrants: [str] = [g for d in needs if d.job.runsOn.name == runsOn.name for a in d.job.actions for g in a.grants]
    _available: [str] = runsOn.backedBy.allProvides + _needsGrants
    _covered: bool = all_true([
        all_true([
            r in _available + [g for a in actions[:i] for g in a.grants]
            for r in actions[i].requires
        ])
        for i in range(len(actions))
    ])

    check:
        regex.match(name, _NAME_RE), "invalid job name ${name}"
        len(actions) > 0, "job ${name}: actions must be non-empty"
        isunique([d.job.name for d in needs]), "job ${name}: duplicate dependency edges"
        _covered, "job ${name}: unsatisfied capability requirement at host ${runsOn.name}"

schema InputSpec:
    """One parameter of the workflow's input schema — the workflow's
    public contract: triggers validate against it, interfaces render
    it, the artifact carries it. No ad-hoc undeclared input reads."""
    type: "string" | "int" | "boolean" = "string"
    description?: str
    default?: str
    required: bool = default == None

schema Workflow:
    """One workflow per user module; a run instantiates it with bound
    inputs under pinned versions. The workflow knows nothing about
    triggers."""
    name: str
    inputs: {str:InputSpec} = {}
    resources: [Resource]
    hosts: [Host]
    jobs: [Job]
    observability?: Observability

    # computable demand (invariant 7): the run's total capacity need,
    # derived statically and carried as artifact metadata.
    _ephemerals: [Ephemeral] = [r as Ephemeral for r in resources if typeof(r) == "Ephemeral"]
    demand: Demand = Demand {
        instances = len(_ephemerals)
        cpu = sum([e.hardware.cpu for e in _ephemerals])
        ramMib = sum([e.hardware.ramMib for e in _ephemerals])
        diskMib = sum([e.hardware.diskMib for e in _ephemerals])
        attach = [(r as PersistentClaim).registryRef for r in resources if typeof(r) == "PersistentClaim"]
    }

    check:
        regex.match(name, _NAME_RE), "invalid workflow name ${name}"
        len(resources) > 0, "workflow must declare resources"
        len(hosts) > 0, "workflow must declare hosts"
        len(jobs) > 0, "workflow must declare jobs"
        isunique([r.name for r in resources]), "duplicate resource names"
        isunique([h.name for h in hosts]), "duplicate host names"
        isunique([j.name for j in jobs]), "duplicate job names"
        isunique([a.name for j in jobs for a in j.actions]), "duplicate action names (workflow-wide; canonical addressing)"
        all h in hosts { h.backedBy.name in [r.name for r in resources] }, "host backed by undeclared resource (closed topology)"
        all j in jobs { j.runsOn.name in [h.name for h in hosts] }, "job runs on undeclared host (closed topology)"
        all j in jobs { all d in j.needs { d.job.name in [jj.name for jj in jobs] } }, "dependency on undeclared job (closed topology)"

schema Demand:
    instances: int
    cpu: int
    ramMib: int
    diskMib: int
    attach: [str]
