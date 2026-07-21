# The dogfood shape: N uniform cluster hosts by eval-time iteration,
# a persistent claim, edge conditions (always-cleanup), grants
# accumulating across jobs on the same host, inputs, typed outputs,
# artifacts, secrets.

import core
import tests.support as testkit

_nodeCount = 3

nodeResources = [core.Ephemeral {
    name = "node-res-${i}"
    provider = testkit.TestProvider { provides = ["bash"] }
    hardware = core.Hardware { cpu = 4, ramMib = 8192, diskMib = 51200 }
} for i in range(_nodeCount)]

nodeHosts = [core.Host {
    name = "node-${i}"
    backedBy = nodeResources[i]
} for i in range(_nodeCount)]

appRes = core.PersistentClaim {
    name = "app-res"
    registryRef = "app-staging"
    providerKind = "test-ssh"
    provides = ["bash", "systemd"]
}

app = core.Host { name = "app", backedBy = appRes }

# Actions with published contracts as named values: consumers navigate
# typed schema fields (startCluster.outputs.endpoint).
startCluster = testkit.ClusterStart {
    name = "start-cluster"
    cmd = "docker compose up -d"
    requires = ["docker"]  # granted by prepare on the same host
    env = {
        TOKEN = core.SecretRef { path = "vault/cluster", key = "token" }
        VERSION = option("version") or "0.0.0-dev"
    }
}

runSuite = testkit.SuiteRun {
    name = "run-suite"
    cmd = "pytest"
    requires = ["bash"]
    env = {
        ENDPOINT = startCluster.outputs.endpoint
    }
}

collectLogs = testkit.LogCollect {
    name = "collect-logs"
    cmd = "tar czf logs.tgz /var/log"
    requires = ["bash"]
}

prepare = core.Job {
    name = "prepare"
    runsOn = nodeHosts[0]
    actions = [
        testkit.TestAction {
            name = "install-tools"
            cmd = "apt-get install -y docker.io"
            requires = ["bash"]
            grants = ["docker"]
        }
    ]
}

deploy = core.Job {
    name = "deploy"
    runsOn = nodeHosts[0]
    needs = [core.Dependency { job = prepare }]
    actions = [startCluster]
}

test = core.Job {
    name = "test"
    runsOn = app
    needs = [core.Dependency { job = deploy }]
    actions = [runSuite]
}

cleanup = core.Job {
    name = "cleanup"
    runsOn = nodeHosts[0]
    needs = [core.Dependency { job = test, on = "always" }]
    actions = [collectLogs]
}

wf = core.Workflow {
    name = "cluster-test"
    inputs = {
        version = core.InputSpec { description = "version under test", default = "0.0.0-dev" }
    }
    resources = nodeResources + [appRes]
    hosts = nodeHosts + [app]
    jobs = [prepare, deploy, test, cleanup]
}
