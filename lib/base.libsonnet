local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/5115edf704db52e4ef8174ea985843f1ca1194eb/kube.libsonnet";
#local kube = import "./kube.libsonnet";

# Maybe could use std.map to apply labels after the fact?
# https://jsonnet.org/ref/stdlib.html
# https://github.com/google/jsonnet/issues/269
# https://stackoverflow.com/questions/51255389/update-an-existing-array-element-with-jsonnet

{
    globalMetadata:: {
        annotations+: {
            "managed-by": "kubecfg"
        },
    },
    ConfigMap(name, commonMetadata): kube.ConfigMap(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    Container(name): kube.Container(name),
    Deployment(name, commonMetadata): kube.Deployment(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    Namespace(name, commonMetadata): kube.Namespace(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    NetworkPolicy(name, commonMetadata): kube.NetworkPolicy(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    Secret(name, commonMetadata): kube.Secret(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    Service(name, commonMetadata): kube.Service(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    ServiceAccount(name, commonMetadata): kube.ServiceAccount(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    StatefulSet(name, commonMetadata): kube.StatefulSet(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    PersistentVolumeClaim(name, commonMetadata): kube.PersistentVolumeClaim(name) {
        metadata+: commonMetadata + $.globalMetadata
    },
    PodDisruptionBudget(name, commonMetadata): kube.PodDisruptionBudget(name) {
        local this = self,
        target_pod:: error "target_pod required",

        kind: 'PodDisruptionBudget',
        apiVersion: 'policy/v1beta1',
        metadata+: commonMetadata + $.globalMetadata,
        spec: {
          selector: {
            matchLabels: this.target_pod.metadata.labels,
          },
        },
    },
    PodSecurityPolicy(name, commonMetadata): {
        kind: 'PodSecurityPolicy',
        apiVersion: 'extensions/v1beta1',
        metadata+: commonMetadata + $.globalMetadata,
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
    },
    podLabelsSelector(obj, filter=null): kube.podLabelsSelector(obj, filter=null),
    podsPorts(obj_list): kube.podsPorts(obj_list)
}
