local Consul = import "../main.jsonnet";

local name = 'consul-test';
local gossip_key = "test-key-don't-use-me";

{
    consul: Consul.ConsulInstance(name, std.extVar('namespace'), gossip_key)
}
