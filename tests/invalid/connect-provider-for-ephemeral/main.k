# Provider modes: an ephemeral resource needs a create-mode provider.
import core
import tests.support as testkit

res = core.Ephemeral { name = "res", provider = testkit.TestConnectProvider { provides = ["bash"] } }
h = core.Host { name = "h", backedBy = res }
j = core.Job { name = "j", runsOn = h, actions = [testkit.TestAction { name = "a", requires = ["bash"] }] }
wf = core.Workflow { name = "bad", resources = [res], hosts = [h], jobs = [j] }
