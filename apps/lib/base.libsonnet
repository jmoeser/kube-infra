local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/5115edf704db52e4ef8174ea985843f1ca1194eb/kube.libsonnet";
#local kube = import "./kube.libsonnet";

{
    ConfigMap(name): kube.ConfigMap(name) {
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
    },
    Container(name): kube.Container(name),
    Deployment(name): kube.Deployment(name) {
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
    },
    Service(name): kube.Service(name) {
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
    },
    ServiceAccount(name): kube.ServiceAccount(name) {
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            },
        },
    },
    PodDisruptionBudget(name): kube.PodDisruptionBudget(name) {
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
    },
    PodSecurityPolicy(name): {
        kind: 'PodSecurityPolicy',
        apiVersion: 'extensions/v1beta1',
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
        spec: {
            privileged: false,
            allowPrivilegeEscalation: false,
            hostNetwork: false,
            hostIPC: false,
            hostPID: false,
            readOnlyRootFilesystem: false,
            requiredDropCapabilities: [
                'ALL'
            ],
            seLinux: {
                rule: 'RunAsAny'
            },
            supplementalGroups: {
                rule: 'MustRunAs',
                ranges: [
                    {min: 1, max: 65535}
                ]
            },
            runAsUser: {
                rule: 'MustRunAsNonRoot'
            },
            fsGroup: {
                rule: 'MustRunAs',
                ranges: [
                    {min: 1, max: 65535}
                ]
            },
            volumes: [
                'configMap',
                'emptyDir',
                'projected',
                'secret',
                'downwardAPI',
                'persistentVolumeClaim'
            ]
        }
    }

}
