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

# Published contract — pure schemas + mixins: users navigate
# `startCluster.outputs.endpoint`; the mixin wires addresses from the
# host action's name.
schema ClusterStartOutputs(core.Outputs):
    endpoint: core.RuntimeRef

mixin ClusterStartOutputsMixin for core.ActionProtocol:
    outputs: ClusterStartOutputs = ClusterStartOutputs {
        endpoint = core.RuntimeRef { expr = "actions.${name}.outputs.endpoint" }
    }

schema ClusterStart(TestAction):
    mixin [ClusterStartOutputsMixin]
    outputs?: ClusterStartOutputs

schema SuiteRunArtifacts(core.Artifacts):
    report: core.ArtifactRef

mixin SuiteRunArtifactsMixin for core.ActionProtocol:
    artifacts: SuiteRunArtifacts = SuiteRunArtifacts {
        report = core.ArtifactRef { expr = "actions.${name}.artifacts.report" }
    }

schema SuiteRun(TestAction):
    mixin [SuiteRunArtifactsMixin]
    artifacts?: SuiteRunArtifacts

schema LogCollectArtifacts(core.Artifacts):
    logs: core.ArtifactRef

mixin LogCollectArtifactsMixin for core.ActionProtocol:
    artifacts: LogCollectArtifacts = LogCollectArtifacts {
        logs = core.ArtifactRef { expr = "actions.${name}.artifacts.logs" }
    }

schema LogCollect(TestAction):
    mixin [LogCollectArtifactsMixin]
    artifacts?: LogCollectArtifacts
