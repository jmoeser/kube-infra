local base = import "../../lib/base.libsonnet";

local consul_container = 'consul';
local default_version = '1.5.2';
local app_desc = "consul";

{
    ConsulInstance(name, namespace, gossip_key, version = default_version, devel = false): {

        local instance = self,

        commonLabels:: {
            "app.kubernetes.io/managed-by": "kubecfg",
            "app.kubernetes.io/instance": name,
            "app.kubernetes.io/name": app_desc
        },
        namespace: base.Namespace(name, self.commonLabels),
        poddistruptionbudget: if devel then {} else base.PodDisruptionBudget(name) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.statefulset.spec.template,
            spec+: {
                maxUnavailable: 1
            },
        },
        secret: base.Secret(name, self.commonLabels) {
            data_: {
                "gossip-key": gossip_key
            }
        },
        web_ui_service: base.Service(name + "-web-ui", self.commonLabels) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.statefulset.spec.template,
            spec: {
                ports: [
                    {
                        name: "http",
                        port: 8500
                    }
                ],
                selector: {
                    "app.kubernetes.io/name": app_desc
                }
            }
        },
        service: base.Service(name, self.commonLabels) {
            metadata+: {
                namespace: namespace
            },
            target_pod:: instance.statefulset.spec.template,
            spec: {
                ports: [
                    {
                        name: "rpc",
                        port: 8400
                    },
                    {
                        name: "serflan-tcp",
                        port: 8301
                    },
                    {
                        name: "serflan-udp",
                        port: 8301,
                        protocol: "UDP"
                    },
                    {
                        name: "serfwan-tcp",
                        port: 8302
                    },
                    {
                        name: "serfwan-udp",
                        port: 8302,
                        protocol: "UDP"
                    },
                    {
                        name: "server",
                        port: 8300
                    },
                    {
                        name: "consuldns-tcp",
                        port: 8600
                    },
                    {
                        name: "consuldns-udp",
                        port: 8600,
                        protocol: "UDP"
                    },
                ],
                selector: {
                    "app.kubernetes.io/name": app_desc
                }
            }
        },
        statefulset: base.StatefulSet(name, self.commonLabels) {
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
                                                "app.kubernetes.io/instance": name
                                            }
                                        },
                                        topologyKey: "kubernetes.io/hostname",
                                    },
                                    weight: 100
                                }]
                            }
                        },
                        containers_: {
                            consul: base.Container("consul") {
                                image: '%(container)s:%(version)s' % { container: consul_container, version: version},
                                command: ["/bin/sh", "-ec", importstr 'consul-command.txt',],
                                resources: {
                                    requests: {
                                        cpu: "100m",
                                        memory: "100Mi"
                                    }
                                },
                                ports_: {
                                    http: {
                                        containerPort: 8800
                                    },
                                    rpc: {
                                        containerPort: 8400
                                    },
                                    serflan_tcp: {
                                        containerPort: 8301
                                    },
                                    serflan_udp: {
                                        containerPort: 8301,
                                        protocol: "UDP"
                                    },
                                    serfwan_tcp: {
                                        containerPort: 8302
                                    },
                                    serfwan_udp: {
                                        containerPort: 8302,
                                        protocol: "UDP"
                                    },
                                    server: {
                                        containerPort: 8300
                                    },
                                    consuldns_tcp: {
                                        containerPort: 8600
                                    },
                                    consuldns_udp: {
                                        containerPort: 8600,
                                        protocol: "UDP"
                                    }
                                },
                                env_: {
                                    INITIAL_CLUSTER_SIZE: "3",
                                    STATEFULSET_NAME: name,
                                    DNSPORT: "8800",
                                    POD_IP: {
                                        fieldRef: {
                                            fieldPath: "status.podIP"
                                        }
                                    },
                                    STATEFULSET_NAMESPACE: {
                                        fieldRef: {
                                            fieldPath: "metadata.namespace"
                                        }
                                    },
                                },
                                livenessProbe: {
                                    exec: {
                                        command: ["consul", "members", "-http-addr=http://127.0.0.1:8500"]
                                    },
                                    initialDelaySeconds: 30,
                                    periodSeconds: 10,
                                },
                                volumeMounts_: {
                                    gossip_key: {
                                        mountPath: "/etc/consul/secrets",
                                        readOnly: true
                                    },
                                    [if devel then "consul_root"]: {
                                        mountPath: "/var/lib/consul"
                                    }
                                }
                            },
                        },
                        volumes_: {
                            gossip_key: {
                                secret: {
                                    secretName: instance.secret.metadata.name
                                }
                            },
                            [if devel then "consul_root"]: {
                                emptyDir: {}
                            }
                        },
                        securityContext: {
                            runAsNonRoot: true,
                            fsGroup: 1000
                        }
                    },
                },
            },
        }
    }
}
