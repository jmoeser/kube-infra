local base = import "../../../lib/base.libsonnet";
local Postgres = import "../main.jsonnet";

local name = 'postgres-test';
local password = 'super-secure';

local commonLabels = {
    "app.kubernetes.io/managed-by": "kubecfg",
    "app.kubernetes.io/instance": name,
    "app.kubernetes.io/name": "test"
};

local app_deployment = base.Deployment("fake", commonLabels) {
    metadata+: {
        namespace: std.extVar('namespace')
    },
    spec+: {
        template+: {
            spec+: {
                containers_: {
                    fake: base.Container("fake") {
                        image: '%(container)s:%(version)s' % { container: "fake_deployment", version: "1.0"},
                    },
                },

            },
        },
    },
};

{
    postgres: Postgres.PostgresInstance(name, std.extVar('namespace'), password, app_deployment)
}
