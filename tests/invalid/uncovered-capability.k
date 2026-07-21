# Invariant 4: requires "docker", nothing provides or grants it.
import core
import tests.support as testkit

res = core.Ephemeral { name = "res", provider = testkit.TestProvider { provides = ["bash"] } }
h = core.Host { name = "h", backedBy = res }
j = core.Job {
    name = "j"
    runsOn = h
    actions = [testkit.TestAction { name = "a", requires = ["docker"] }]
}
wf = core.Workflow { name = "bad", resources = [res], hosts = [h], jobs = [j] }
