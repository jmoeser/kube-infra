local base = import '../../lib/base.libsonnet';

local Postgres = import '../postgres/main.jsonnet';
local web = import 'web.jsonnet';
local worker = import 'worker.jsonnet';

local concourse_container = 'concourse/concourse';
local default_version = '5.4.1';
local app_desc = 'concourse';

{
    ConcourseInstance(name, namespace, version=default_version, devel=false): {

        local instance = self,

        instanceConfig:: {
            databaseName: 'concourse',
            databaseUser: 'concourse',
            databasePassword: error 'databasePassword required',
            concourseBuildNamespacePrefix: 'ci-concourse',
            externalURL: 'http://localhost:8080',
            host_key: error 'host_key required',
            host_key_pub: error 'host_key_pub required',
            session_signing_key: error 'session_signing_key required',
            worker_key: error 'worker_key required',
            worker_key_pub: error 'worker_key_pub required',
            namespace: namespace,
            container: concourse_container,
            version: version,
            worker_count: 2,
            devel: devel,
        },

        commonLabels:: {
            app: name,
            version: version,
            'part-of': app_desc,
        },
        commonAnnotations:: {},
        commonMetadata:: {
            labels+: instance.commonLabels,
            namespace: namespace,
            annotations+: instance.commonAnnotations,
        },

        namespace: base.Namespace(name, self.commonMetadata),

        web: web.ConcourseWeb(name, self),
        worker: if instance.instanceConfig.worker_count > 0 then worker.ConcourseWorker(name, self) else {},

        database: Postgres.PostgresInstance('postgres', namespace, instance.web.deployment, devel=devel) {
            databaseDetails+: {
                user: instance.instanceConfig.databaseUser,
                database: instance.instanceConfig.databaseName,
                password: instance.instanceConfig.databasePassword,
            },
            commonLabels+: {
                'part-of': app_desc,
            },
        },

    },

}
