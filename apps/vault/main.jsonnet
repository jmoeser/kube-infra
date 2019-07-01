local base = import "../lib/base.libsonnet";

local vault_config = import "vault-config.jsonnet";

local default_version = '1.1.3';

{
    VaultInstance(name, namespace, version = default_version, devel = false): {

        local instance = self,

        serviceaccount: base.ServiceAccount(name) {
            metadata+: {
                namespace: namespace,
                labels+: {
                    "app.kubernetes.io/name": "vault"
                }
            }
        },
        poddistruptionbudget: if devel then {} else base.PodDisruptionBudget("vault") {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.deployment.spec.template,
            spec+: {
                maxUnavailable: 1
            },
        },
        service: base.Service(name) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.deployment.spec.template,
        },
        config: base.ConfigMap(name) {
            metadata+: {
                namespace: namespace
            },
            data+: {
                "config.json": std.toString(vault_config.config(devel)),
            }
        },
        deployment: base.Deployment(name) {
            metadata+: {
                namespace: namespace
            },
            spec+: {
                replicas: if devel then 1 else 3,
                strategy+: {
                    type: "RollingUpdate",
                    rollingUpdate: {
                        maxUnavailable: 1
                    }
                },
                template+: {
                    spec+: {
                        containers_: {
                            vault: base.Container("vault") {
                                image: "vault:" + version,
                                # command: ["vault", "server", "-dev", "-dev-listen-address", "[::]:8200"],
                                command: ["vault", "server", "-config", "/vault/config"],
                                resources: {
                                    requests: {
                                        cpu: "100m",
                                        memory: "100Mi"
                                    }
                                },
                                ports_: {
                                    api: {
                                        containerPort: 8200
                                    },
                                    cluster_address: {
                                        containerPort: 8201
                                    },
                                },
                                env_: {
                                    VAULT_CLUSTER_ADDR: "https://$(POD_IP):8201",
                                    VAULT_LOG_LEVEL: "info",
                                    POD_IP: {
                                        fieldRef: {
                                            fieldPath: "status.podIp"
                                        }
                                    }
                                },
                                affinity: {
                                    podAntiAffinity: {
                                        preferredDuringSchedulingIgnoredDuringExecution: [{
                                            podAffinityTerm: {
                                                labelSelector: {
                                                    matchLabels: {
                                                        app: "vault"
                                                    }
                                                },
                                                topologyKey: "kubernetes.io/hostname",
                                            },
                                            weight: 100
                                        }]
                                    }
                                },
                                livenessProbe: {
                                    httpGet: {
                                        path: "/v1/sys/health?standbyok=true&uninitcode=204&sealedcode=204&",
                                        port: 8200,
                                        scheme: "HTTP"
                                    },
                                    initialDelaySeconds: 30,
                                    periodSeconds: 10,
                                },
                                readinessProbe: self.livenessProbe {
                                    httpGet+: {
                                        path: "/v1/sys/health?standbycode=204&uninitcode=204&",
                                    },
                                    initialDelaySeconds: 10,
                                },
                                securityContext: {
                                    readOnlyRootFilesystem: true,
                                    capabilities: {
                                        add: ["IPC_LOCK"]
                                    }
                                },
                                volumeMounts_: {
                                    vault_config: {
                                        mountPath: "/vault/config"
                                    },
                                    [if devel then "vault_root"]: {
                                        mountPath: "/vault/data"
                                    }
                                }
                            },
                        },
                        volumes_: {
                            vault_config: {
                                configMap: {
                                    name: instance.config.metadata.name
                                }
                            },
                            [if devel then "vault_root"]: {
                                emptyDir: {}
                            }
                        },
                        securityContext: {
                            runAsNonRoot: true
                        }
                    },
                },
            },
        },
    }
}
