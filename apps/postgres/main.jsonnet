local base = import "../../lib/base.libsonnet";

local postgres_container = 'postgres';
local default_version = '11.4-alpine';
local app_desc = "postgres";

{
    PostgresInstance(name, namespace, postgres_password, app_deployment, version = default_version, devel = false): {

        local instance = self,

        commonLabels:: {
            "app": app_desc,
            "version": version
        },
        commonAnnotations:: { },
        commonMetadata:: {
            labels+: instance.commonLabels,
            namespace: namespace,
            annotations+: instance.commonAnnotations
        },

        secret: base.Secret(name, self.commonMetadata) {
            data_: {
                "postgres-password": postgres_password
            },
        },
        service: base.Service(app_desc, self.commonMetadata) {
            target_pod:: instance.deployment.spec.template,
        },
        persistentvolumeclaim: if devel then {} else base.PersistentVolumeClaim(name, self.commonMetadata) {
            storage: "8Gi",
        },
        networkpolicy: base.NetworkPolicy(name, self.commonMetadata) {
            spec+: base.podLabelsSelector(instance.deployment) {
                ingress_: {
                  from_app: {
                    from: [
                      base.podLabelsSelector(app_deployment),
                    ],
                    ports: base.podsPorts([instance.deployment]),
                  },
                },
            }
        },
        deployment: base.Deployment(name, self.commonMetadata) {
            spec+: {
                replicas: 1,
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
                            postgres: base.Container("postgres") {
                                image: '%(container)s:%(version)s' % { container: postgres_container, version: version},
                                resources: {
                                    requests: {
                                        cpu: "100m",
                                        memory: "256Mi"
                                    }
                                },
                                ports_: {
                                    postgresql: {
                                        containerPort: 5432
                                    },
                                },
                                env_: {
                                    POSTGRES_USER: "postgres",
                                    PGUSER: "postgres",
                                    POSTGRES_DB: "postgres",
                                    POSTGRES_INITDB_ARGS: "",
                                    PGDATA: "/var/lib/postgresql/data/pgdata",
                                    POSTGRES_PASSWORD: {
                                        secretKeyRef: {
                                            name: instance.secret.metadata.name,
                                            key: "postgres-password"
                                        }
                                    },
                                    POD_IP: {
                                        fieldRef: {
                                            fieldPath: "status.podIP"
                                        }
                                    }
                                },
                                livenessProbe: {
                                    exec: {
                                        command: ["sh", "-c", "exec pg_isready --host $POD_IP"]
                                    },
                                    initialDelaySeconds: 120,
                                    timeoutSeconds: 5,
                                    failureThreshold: 6,
                                },
                                readinessProbe: self.livenessProbe {
                                    initialDelaySeconds: 5,
                                    timeoutSeconds: 3,
                                    periodSeconds: 5,
                                },
                                # securityContext: {
                                #     readOnlyRootFilesystem: true,
                                # },
                                volumeMounts_: if devel then {} else {
                                    data: {
                                        mountPath: "/var/lib/postgresql/data/pgdata",
                                        subPath: "postgresql-db"
                                    },
                                }
                            },
                        },
                        volumes_: if devel then {} else {
                            data: {
                                persistentVolumeClaim: {
                                    claimName: instance.persistentvolumeclaim.metadata.name
                                }
                            },
                        },
                        # securityContext: {
                        #     runAsNonRoot: true
                        # }
                    },
                },
            },
        },
    }
}
