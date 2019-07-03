local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/5115edf704db52e4ef8174ea985843f1ca1194eb/kube.libsonnet";
#local kube = import "./kube.libsonnet";

{
    ConfigMap(name, commonLabels): kube.ConfigMap(name) {
        metadata+: {
            labels+: commonLabels,
        },
    },
    Container(name): kube.Container(name),
    Deployment(name, commonLabels): kube.Deployment(name) {
        metadata+: {
            labels+: commonLabels,
        },
    },
    Namespace(name, commonLabels): kube.Namespace(name) {
        metadata+: {
            labels+: commonLabels,
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
        local this = self,
        target_pod:: error "target_pod required",

        kind: 'PodDisruptionBudget',
        apiVersion: 'policy/v1beta1',
        metadata+: {
            labels+: {
                "app.kubernetes.io/managed-by": "kubecfg",
                "app.kubernetes.io/name": name
            }
        },
        spec: {
          selector: {
            matchLabels: this.target_pod.metadata.labels,
          },
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
