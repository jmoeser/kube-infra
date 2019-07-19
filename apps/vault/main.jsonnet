local base = import "../../lib/base.libsonnet";

local vault_config = import "vault-config.jsonnet";

local vault_container = 'vault';
local default_version = '1.1.3';
local app_desc = "vault";

{
    VaultInstance(name, namespace, version = default_version, devel = false): {

        local instance = self,

        commonLabels:: {
            "app.kubernetes.io/managed-by": "kubecfg",
            "app.kubernetes.io/instance": name,
            "app.kubernetes.io/name": app_desc
        },
        namespace: base.Namespace(name, self.commonLabels),
        serviceaccount: base.ServiceAccount(name) {
            metadata+: {
                namespace: namespace,
                labels+: {
                    "app.kubernetes.io/name": "vault"
                }
            }
        },
        poddistruptionbudget: if devel then {} else base.PodDisruptionBudget(name) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.deployment.spec.template,
            spec+: {
                maxUnavailable: 1
            },
        },
        service: base.Service(name, self.commonLabels) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.deployment.spec.template,
        },
        config: base.ConfigMap(name, self.commonLabels) {
            metadata+: {
                namespace: namespace
            },
            data+: {
                "config.json": std.toString(vault_config.config(devel)),
            }
        },
        deployment: base.Deployment(name, self.commonLabels) {
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
                        containers_: {
                            vault: base.Container("vault") {
                                image: vault_container + ":" + version,
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
                                    //VAULT_CLUSTER_ADDR: "https://$(POD_IP):8201",
                                    VAULT_API_ADDR: "https://$(POD_IP):8201",
                                    VAULT_LOG_LEVEL: "info",
                                    SKIP_SETCAP: "true",
                                    POD_IP: {
                                        fieldRef: {
                                            fieldPath: "status.podIP"
                                        }
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
