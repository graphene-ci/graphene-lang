# Test-only concrete subclasses of the core extension points.
# Real providers/actions live in graphene-plugins; these exist so the
# core schemas can be exercised without any plugin.

import core

schema TestProvider(core.Provider):
    kind: str = "test"
    modes: [core.ProviderMode] = ["create"]

schema TestConnectProvider(core.Provider):
    kind: str = "test-ssh"
    modes: [core.ProviderMode] = ["connect"]

schema TestAction(core.Action):
    cmd: str = "true"
    env: {str:core.Value} = {}

# Published contract — pure schema with lazy address defaults:
# users navigate `startCluster.outputs.endpoint`.
schema ClusterStartOutputs(core.Outputs):
    endpoint: core.RuntimeRef = core.RuntimeRef { expr = "actions.${owner}.outputs.endpoint" }

schema ClusterStart(TestAction):
    outputs: ClusterStartOutputs = ClusterStartOutputs { owner = name }

schema SuiteRunArtifacts(core.Artifacts):
    report: core.ArtifactRef = core.ArtifactRef { expr = "actions.${owner}.artifacts.report" }

schema SuiteRun(TestAction):
    artifacts: SuiteRunArtifacts = SuiteRunArtifacts { owner = name }

schema LogCollectArtifacts(core.Artifacts):
    logs: core.ArtifactRef = core.ArtifactRef { expr = "actions.${owner}.artifacts.logs" }

schema LogCollect(TestAction):
    artifacts: LogCollectArtifacts = LogCollectArtifacts { owner = name }
