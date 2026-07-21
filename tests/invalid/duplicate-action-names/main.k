# Invariant 3: action names unique workflow-wide.
import core
import tests.support as testkit

res = core.Ephemeral { name = "res", provider = testkit.TestProvider { provides = ["bash"] } }
h = core.Host { name = "h", backedBy = res }
j1 = core.Job { name = "j1", runsOn = h, actions = [testkit.TestAction { name = "step", requires = ["bash"] }] }
j2 = core.Job { name = "j2", runsOn = h, actions = [testkit.TestAction { name = "step", requires = ["bash"] }] }
wf = core.Workflow { name = "bad", resources = [res], hosts = [h], jobs = [j1, j2] }
