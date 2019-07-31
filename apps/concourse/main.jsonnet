local base = import '../../lib/base.libsonnet';

local Postgres = import '../postgres/main.jsonnet';

local concourse_container = 'concourse/concourse';
local default_version = '5.4.0';
local app_desc = 'concourse';

{
    ConcourseInstance(name, namespace, version=default_version, devel=false): {

        local instance = self,

        instanceConfig:: {
            databasePassword: 'password',
            concourseBuildNamespacePrefix: 'ci-concourse',
            externalURL: 'http://localhost:8080',
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
        webMetadata:: self.commonMetadata {
            labels+: {
                role: 'web',
            },
        },
        webSecrets: base.Secret(name + '-web', self.webMetadata) {
            data_: {
                'host-key': 'asd',
                'session-signing-key': 'asd',
                'worker-key-pub': 'asd',
                'local-users': 'test:test',
                'database-password': instance.instanceConfig.databasePassword,
            },
        },
        webService: base.Service(name + '-web', self.webMetadata) {
            target_pod:: instance.deployment.spec.template,
            spec: {
                ports: [
                    {
                        name: 'atc',
                        port: 8080,
                        targetPort: 'atc',
                    },
                    {
                        name: 'tsa',
                        port: 2222,
                        targetPort: 'tsa',
                    },
                    {
                        name: 'prometheus',
                        port: 9391,
                        targetPort: 'prometheus',
                    },
                ],
                selector: {
                    'app.kubernetes.io/name': name,
                },
            },
        },
        webServiceAccount: base.ServiceAccount(name + '-web', self.webMetadata),
        deployment: base.Deployment(name, self.webMetadata) {
            spec+: {
                replicas: 1,
                template+: {
                    spec+: {
                        containers_: {
                            concourse: base.Container('concourse-web') {
                                image: '%(container)s:%(version)s' % { container: concourse_container, version: version },
                                args: ['web'],  // ['quickstart'],
                                resources: {
                                    requests: {
                                        cpu: '100m',
                                        memory: '128Mi',
                                    },
                                },
                                ports_: {
                                    atc: {
                                        containerPort: 8080,
                                    },
                                    tsa: {
                                        containerPort: 2222,
                                    },
                                    'atc-debug': {
                                        containerPort: 8079,
                                    },
                                    prometheus: {
                                        containerPort: 9391,
                                    },
                                },
                                env_: {
                                    CONCOURSE_CLUSTER_NAME: name,
                                    CONCOURSE_POSTGRES_USER: 'concourse',
                                    CONCOURSE_ENABLE_GLOBAL_RESOURCES: 'true',
                                    CONCOURSE_ENABLE_BUILD_AUDITING: 'true',
                                    CONCOURSE_ENABLE_CONTAINER_AUDITING: 'true',
                                    CONCOURSE_ENABLE_JOB_AUDITING: 'true',
                                    CONCOURSE_ENABLE_PIPELINE_AUDITING: 'true',
                                    CONCOURSE_ENABLE_RESOURCE_AUDITING: 'true',
                                    CONCOURSE_ENABLE_SYSTEM_AUDITING: 'true',
                                    CONCOURSE_ENABLE_TEAM_AUDITING: 'true',
                                    CONCOURSE_ENABLE_WORKER_AUDITING: 'true',
                                    CONCOURSE_ENABLE_VOLUME_AUDITING: 'true',
                                    CONCOURSE_KUBERNETES_IN_CLUSTER: 'true',
                                    CONCOURSE_KUBERNETES_NAMESPACE_PREFIX: instance.instanceConfig.concourseBuildNamespacePrefix,
                                    CONCOURSE_POSTGRES_HOST: instance.database.service.metadata.name,
                                    CONCOURSE_POSTGRES_PASSWORD: {
                                        secretKeyRef: {
                                            name: instance.webSecrets.metadata.name,
                                            key: 'database-password',
                                        },
                                    },
                                    CONCOURSE_POSTGRES_DATABASE: 'concourse',
                                    CONCOURSE_ADD_LOCAL_USER: {
                                        secretKeyRef: {
                                            name: instance.webSecrets.metadata.name,
                                            key: 'local-users',
                                        },
                                    },
                                    CONCOURSE_MAIN_TEAM_LOCAL_USER: 'test',
                                    CONCOURSE_BIND_PORT: '8080',
                                    CONCOURSE_EXTERNAL_URL: instance.instanceConfig.externalURL,
                                    CONCOURSE_PROMETHEUS_BIND_IP: '0.0.0.0',
                                    CONCOURSE_PROMETHEUS_BIND_PORT: '9391',
                                    CONCOURSE_PEER_ADDRESS: '$(POD_IP)',
                                    CONCOURSE_TSA_BIND_PORT: '2222',
                                    CONCOURSE_TSA_DEBUG_BIND_PORT: '8079',
                                    CONCOURSE_SESSION_SIGNING_KEY: '/concourse-keys/session_signing_key',
                                    CONCOURSE_TSA_HOST_KEY: '/concourse-keys/host_key',
                                    CONCOURSE_TSA_AUTHORIZED_KEYS: '/concourse-keys/worker_key.pub',
                                    POD_IP: {
                                        fieldRef: {
                                            fieldPath: 'status.podIP',
                                        },
                                    },
                                },
                                livenessProbe: {
                                    httpGet: {
                                        path: '/api/v1/info',
                                        port: 'atc',
                                        scheme: 'HTTP',
                                    },
                                    initialDelaySeconds: 10,
                                    periodSeconds: 15,
                                    timeoutSeconds: 3,
                                    failureThreshold: 5,
                                },
                                readinessProbe: self.livenessProbe {
                                    initialDelaySeconds: 30,
                                },
                                // securityContext: {
                                //     readOnlyRootFilesystem: true,
                                // },
                                volumeMounts_: {
                                    concourse_keys: {
                                        mountPath: '/concourse-keys',
                                    },
                                    //     [if devel then "vault_root"]: {
                                    //         mountPath: "/vault/data"
                                    //     }
                                },
                            },
                        },
                        volumes_: {
                            concourse_keys: {
                                secret: {
                                    secretName: instance.webSecrets.metadata.name,
                                    defaultMode: 256,
                                    items: [
                                        { key: 'host-key', path: 'host_key' },
                                        { key: 'session-signing-key', path: 'session_signing_key' },
                                        { key: 'worker-key-pub', path: 'worker_key.pub' },
                                    ],
                                },
                            },
                            //     [if devel then "vault_root"]: {
                            //         emptyDir: {}
                            //     }
                        },
                        // securityContext: {
                        //     runAsNonRoot: true
                        // }
                    },
                },
            },
        },
        database: Postgres.PostgresInstance('postgres', namespace, instance.deployment, devel=devel) {
            databaseDetails+: {
                user: 'concourse',
                database: 'concourse',
                password: instance.instanceConfig.databasePassword,
            },
            commonLabels+: {
                'part-of': app_desc,
            },
        },
        workerMetadata:: self.commonMetadata {
            labels+: {
                role: 'worker',
            },
        },
        workerService: base.Service(name + '-worker', self.workerMetadata) {
            spec: {
                type: 'ClusterIP',
                clusterIP: 'None',
                selector: {
                    role: 'worker',
                },
            },
        },
        workerConfigMap: base.ConfigMap(name + '-worker', self.workerMetadata) {
            data+: {
                'pre-stop-hook.sh': |||
                    #!/bin/bash
                    kill -s SIGUSR2 1
                    while [ -e /proc/1 ]; do sleep 1; done
                |||,
            },
        },
        workerSecrets: base.Secret(name + '-worker', self.workerMetadata) {
            data_: {
                'host-key-pub': 'asd',
                'worker-key': 'asd',
                'worker-key-pub': 'asd',
            },
        },
        statefulset: base.StatefulSet(name, self.workerMetadata) {
            spec+: {
                replicas: 2,
                podManagementPolicy: 'Parallel',
                template+: {
                    spec+: {
                        serviceAccountName: '',
                        terminationGracePeriodSeconds: 60,
                        affinity: {
                            podAntiAffinity: {
                                preferredDuringSchedulingIgnoredDuringExecution: [{
                                    podAffinityTerm: {
                                        labelSelector: {
                                            matchLabels: {
                                                'app.kubernetes.io/instance': name,
                                            },
                                        },
                                        topologyKey: 'kubernetes.io/hostname',
                                    },
                                    weight: 100,
                                }],
                            },
                        },
                        initContainers_: {
                            init_rm: base.Container('worker-init-rm') {
                                image: '%(container)s:%(version)s' % { container: concourse_container, version: version },
                                command: ['/bin/sh'],
                                args: ['-ce', 'rm -rf /concourse-work-dir/*'],
                                volumeMounts_: {
                                    'concourse-work-dir': {
                                        mountPath: '/concourse-work-dir',
                                    },
                                },
                            },
                        },
                        containers_: {
                            concourse: base.Container('concourse-worker') {
                                image: '%(container)s:%(version)s' % { container: concourse_container, version: version },
                                args: ['worker'],
                                lifecycle: {
                                    preStop: {
                                        exec: {
                                            command: ['/bin/bash', '/pre-stop-hook.sh'],
                                        },
                                    },
                                },
                                resources: {
                                    requests: {
                                        cpu: '100m',
                                        memory: '512Mi',
                                    },
                                },
                                securityContext: {
                                    privileged: true,
                                },
                                ports_: {
                                    'health-check': {
                                        containerPort: 8888,
                                    },
                                },
                                env_: {
                                    CONCOURSE_HEALTHCHECK_BIND_PORT: '8888',
                                    CONCOURSE_DEBUG_BIND_PORT: '7776',
                                    CONCOURSE_WORK_DIR: '/concourse-work-dir',
                                    CONCOURSE_BIND_PORT: '7777',
                                    CONCOURSE_TSA_HOST: instance.webService.metadata.name + ':2222',
                                    CONCOURSE_TSA_PUBLIC_KEY: '/concourse-keys/host_key.pub',
                                    CONCOURSE_TSA_WORKER_PRIVATE_KEY: '/concourse-keys/worker_key',
                                    CONCOURSE_BAGGAGECLAIM_BIND_PORT: '7788',
                                    CONCOURSE_BAGGAGECLAIM_DEBUG_BIND_PORT: '7787',
                                    CONCOURSE_BAGGAGECLAIM_DRIVER: 'naive',
                                    CONCOURSE_VOLUME_SWEEPER_MAX_IN_FLIGHT: '5',
                                    CONCOURSE_CONTAINER_SWEEPER_MAX_IN_FLIGHT: '5',
                                },
                                livenessProbe: {
                                    httpGet: {
                                        path: '/',
                                        port: 'health-check',
                                        scheme: 'HTTP',
                                    },
                                    initialDelaySeconds: 10,
                                    periodSeconds: 15,
                                    timeoutSeconds: 3,
                                    failureThreshold: 5,
                                },
                                volumeMounts_: {
                                    concourse_keys: {
                                        mountPath: '/concourse-key',
                                        readOnly: true,
                                    },
                                    work_dir: {
                                        mountPath: '/concourse-work-dir',
                                    },
                                    pre_stop_hook: {
                                        mountPath: '/pre-stop-hook.sh',
                                        subPath: 'pre-stop-hook.sh',
                                    },
                                },
                            },
                        },
                        volumes_: {
                            pre_stop_hook: {
                                configMap: {
                                    name: instance.workerConfigMap.metadata.name,
                                },
                            },
                            concourse_keys: {
                                secret: {
                                    secretName: instance.workerSecrets.metadata.name,
                                    defaultMode: 256,
                                    items: [
                                        { key: 'host-key-pub', path: 'host_key.pub' },
                                        { key: 'worker-key', path: 'worker_key' },
                                        { key: 'worker-key-pub', path: 'worker_key.pub' },
                                    ],
                                },
                            },
                        },
                    },
                },
                volumeClaimTemplates_:: if devel then {} else {
                    'work-dir': {
                        storage: '20Gi',
                        metadata+: {
                            name: 'concourse-work-dir',
                        },
                    },
                },
            },
        },
        workerServiceAccount: base.ServiceAccount(name + '-worker', self.commonMetadata),
        // pdb
        // service accounts and role bindings
        //cluster role
        // role
        // role binding x2

    },

}
