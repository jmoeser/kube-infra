local base = import '../../../lib/base.libsonnet';
local Consul = import '../main.jsonnet';

local name = 'consul-test';
// consul keygen
local gossip_key = 'uWDt8KBRh8R2acHcPFX0MQ==';

{
    commonLabels:: {
        'app.kubernetes.io/managed-by': 'kubecfg',
        'app.kubernetes.io/instance': name,
    },
    namespace: base.Namespace(std.extVar('namespace'), self.commonLabels),
    consul: Consul.ConsulInstance(name, std.extVar('namespace'), gossip_key),
}
