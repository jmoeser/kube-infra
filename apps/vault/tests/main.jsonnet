local Vault = import "../main.jsonnet";

local name = 'vault-test';
local devel = true;

{
    prod_vault: Vault.VaultInstance(name, std.extVar('namespace'))
}
