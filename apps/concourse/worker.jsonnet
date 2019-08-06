local base = import '../../lib/base.libsonnet';

{
    ConcourseWorker(name, instance): {

        local workerInstance = self,

        workerMetadata:: instance.commonMetadata {
            labels+: {
                component: 'worker',
            },
        },
        workerService: base.Service(name + '-worker', self.workerMetadata) {
            spec: {
                type: 'ClusterIP',
                clusterIP: 'None',
                selector: {
                    component: 'worker',
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
                'host-key-pub': instance.instanceConfig.host_key_pub,
                'worker-key': instance.instanceConfig.worker_key,
                'worker-key-pub': instance.instanceConfig.worker_key_pub,
            },
        },
        statefulset: base.StatefulSet(name + '-worker', self.workerMetadata) {
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
                                image: '%(container)s:%(version)s' % { container: instance.instanceConfig.container, version: instance.instanceConfig.version },
                                command: ['/bin/sh'],
                                args: ['-ce', 'rm -rf /concourse-work-dir/*'],
                                volumeMounts_: if instance.instanceConfig.devel then {} else {
                                    'concourse-work-dir': {
                                        mountPath: '/concourse-work-dir',
                                    },
                                },
                            },
                        },
                        containers_: {
                            concourse: base.Container('concourse-worker') {
                                image: '%(container)s:%(version)s' % { container: instance.instanceConfig.container, version: instance.instanceConfig.version },
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
                                    CONCOURSE_TSA_HOST: instance.web.webService.metadata.name + ':2222',
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
                                        mountPath: '/concourse-keys',
                                        readOnly: true,
                                    },
                                    pre_stop_hook: {
                                        mountPath: '/pre-stop-hook.sh',
                                        subPath: 'pre-stop-hook.sh',
                                    },
                                } + if instance.instanceConfig.devel then {} else {
                                    work_dir: {
                                        mountPath: '/concourse-work-dir',
                                    },
                                },
                            },
                        },
                        volumes_: {
                            pre_stop_hook: {
                                configMap: {
                                    name: workerInstance.workerConfigMap.metadata.name,
                                },
                            },
                            concourse_keys: {
                                secret: {
                                    secretName: workerInstance.workerSecrets.metadata.name,
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
                volumeClaimTemplates_:: if instance.instanceConfig.devel then {} else {
                    'work-dir': {
                        storage: '20Gi',
                        metadata+: {
                            name: 'concourse-work-dir',
                        },
                    },
                },
            },
        },
        workerServiceAccount: base.ServiceAccount(name + '-worker', self.workerMetadata),
        workerRole: base.Role(name + '-worker', self.workerMetadata) {
            rules: [{ apiGroups: ['extensions'], resources: ['podsecuritypolicies'], resourceNames: ['privileged'], verbs: ['use'] }],
        },
        workerRoleBinding: base.RoleBinding(name + '-worker', self.workerMetadata) {
            subjects_: [workerInstance.workerServiceAccount],
            roleRef_: workerInstance.workerRole,
        },
        poddistruptionbudget: if instance.instanceConfig.devel then {} else base.PodDisruptionBudget(name, self.workerMetadata) {
            target_pod:: workerInstance.statefulset.spec.template,
            spec+: {
                minAvailable: 1,
            },
        },
    },

}
