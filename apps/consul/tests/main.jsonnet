local Consul = import "../main.jsonnet";

local name = 'consul-test';

{
    consul: Consul.ConsulInstance(name, std.extVar('namespace'), std.extVar('gossip-key'))
}
