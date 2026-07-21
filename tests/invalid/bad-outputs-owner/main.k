# Publication discipline: outputs.owner must equal the action name —
# a plugin schema that binds owner wrongly is caught at eval.
import core
import tests.support as testkit

schema BrokenAction(testkit.TestAction):
    outputs: testkit.ClusterStartOutputs = testkit.ClusterStartOutputs { owner = "someone-else" }

res = core.Ephemeral { name = "res", provider = testkit.TestProvider { provides = ["bash"] } }
h = core.Host { name = "h", backedBy = res }
j = core.Job { name = "j", runsOn = h, actions = [BrokenAction { name = "p", requires = ["bash"] }] }
wf = core.Workflow { name = "bad", resources = [res], hosts = [h], jobs = [j] }
