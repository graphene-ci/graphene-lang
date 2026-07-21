# Invariant 1 (closed topology): job runs at an undeclared host.
import core
import tests.support as testkit

res = core.Ephemeral { name = "res", provider = testkit.TestProvider { provides = ["bash"] } }
declared = core.Host { name = "declared", backedBy = res }
stray = core.Host { name = "stray", backedBy = res }
j = core.Job {
    name = "j"
    runsOn = stray
    actions = [testkit.TestAction { name = "a", requires = ["bash"] }]
}
wf = core.Workflow { name = "bad", resources = [res], hosts = [declared], jobs = [j] }
