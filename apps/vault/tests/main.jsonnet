local Vault = import "../main.jsonnet";

local name = 'vault-test';
local namespace = 'vault';
local devel = true;

{
    dev_vault: Vault.VaultInstance(name, namespace, devel = true),
    prod_vault: Vault.VaultInstance(name, namespace)
}
