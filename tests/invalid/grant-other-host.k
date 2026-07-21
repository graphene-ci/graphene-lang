# Per-host ledger: a grant on another host does not cover here.
import core
import tests.support as testkit

resA = core.Ephemeral { name = "res-a", provider = testkit.TestProvider { provides = ["bash"] } }
resB = core.Ephemeral { name = "res-b", provider = testkit.TestProvider { provides = ["bash"] } }
hostA = core.Host { name = "host-a", backedBy = resA }
hostB = core.Host { name = "host-b", backedBy = resB }
prepare = core.Job {
    name = "prepare"
    runsOn = hostA
    actions = [testkit.TestAction { name = "install", requires = ["bash"], grants = ["docker"] }]
}
use = core.Job {
    name = "use"
    runsOn = hostB
    needs = [core.Dependency { job = prepare }]
    actions = [testkit.TestAction { name = "run", requires = ["docker"] }]
}
wf = core.Workflow { name = "bad", resources = [resA, resB], hosts = [hostA, hostB], jobs = [prepare, use] }
