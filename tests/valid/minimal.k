# Smallest valid workflow: one ephemeral resource, one host, one job.

import core
import tests.support as testkit

buildRes = core.Ephemeral {
    name = "build-res"
    provider = testkit.TestProvider { provides = ["bash"] }
    hardware = core.Hardware { cpu = 2, ramMib = 4096 }
}

build = core.Host { name = "build", backedBy = buildRes }

buildJob = core.Job {
    name = "build"
    runsOn = build
    actions = [
        testkit.TestAction { name = "compile", cmd = "make", requires = ["bash"] }
    ]
}

wf = core.Workflow {
    name = "minimal"
    resources = [buildRes]
    hosts = [build]
    jobs = [buildJob]
}
