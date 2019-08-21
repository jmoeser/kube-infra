local base = import '../../lib/base.libsonnet';

{
    ConcourseWeb(name, instance): {

        local webInstance = self,

        webMetadata:: instance.commonMetadata {
            labels+: {
                component: 'web',
            },
        },
        webSecrets: base.Secret(name + '-web', self.webMetadata) {
            data_: {
                'host-key': instance.instanceConfig.host_key,
                'session-signing-key': instance.instanceConfig.session_signing_key,
                'worker-key-pub': instance.instanceConfig.worker_key_pub,
                'local-users': 'test:test',
                'database-password': instance.instanceConfig.databasePassword,
            },
        },
        webService: base.Service(name + '-web', self.webMetadata) {
            target_pod:: webInstance.deployment.spec.template,
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
                    app: name,
                    component: 'web'
                },
            },
        },
        webServiceAccount: base.ServiceAccount(name + '-web', self.webMetadata),
        webClusterRole: base.ClusterRole(name + '-web', self.webMetadata) {
            rules: [{ apiGroups: [''], resources: ['secrets'], verbs: ['get'] }],
        },
        webRoleBinding: base.RoleBinding(name + '-web', self.webMetadata) {
            subjects_: [webInstance.webServiceAccount],
            roleRef_: webInstance.webClusterRole,
        },
        deployment: base.Deployment(name + '-web', self.webMetadata) {
            spec+: {
                replicas: 1,
                template+: {
                    spec+: {
                        containers_: {
                            concourse: base.Container('concourse-web') {
                                image: '%(container)s:%(version)s' % { container: instance.instanceConfig.container, version: instance.instanceConfig.version },
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
                                    CONCOURSE_POSTGRES_USER: instance.instanceConfig.databaseUser,
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
                                    CONCOURSE_POSTGRES_PASSWORD: base.SecretKeyRef(webInstance.webSecrets, 'database-password'),
                                    CONCOURSE_POSTGRES_DATABASE: instance.instanceConfig.databaseName,
                                    CONCOURSE_ADD_LOCAL_USER: base.SecretKeyRef(webInstance.webSecrets, 'local-users'),
                                    CONCOURSE_MAIN_TEAM_LOCAL_USER: 'test',
                                    CONCOURSE_BIND_PORT: '8080',
                                    CONCOURSE_EXTERNAL_URL: instance.instanceConfig.externalURL,
                                    CONCOURSE_PROMETHEUS_BIND_IP: '0.0.0.0',
                                    CONCOURSE_PROMETHEUS_BIND_PORT: '9391',
                                    // Order of these is important
                                    POD_IP: base.FieldRef('status.podIP'),
                                    CONCOURSE_PEER_ADDRESS: base.FieldRef('status.podIP'),
                                    CONCOURSE_TSA_BIND_PORT: '2222',
                                    CONCOURSE_TSA_DEBUG_BIND_PORT: '8079',
                                    CONCOURSE_SESSION_SIGNING_KEY: '/concourse-keys/session_signing_key',
                                    CONCOURSE_TSA_HOST_KEY: '/concourse-keys/host_key',
                                    CONCOURSE_TSA_AUTHORIZED_KEYS: '/concourse-keys/worker_key.pub',
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
                                    secretName: webInstance.webSecrets.metadata.name,
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
    },
}
