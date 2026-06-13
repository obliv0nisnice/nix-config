# Bridge: feeds the per-host feature toggles defined as plain data in
# hosts/<host>/variables.nix into the machineProfiles / customConf option trees.
# This lets every toggle live next to browser/keyboardLayout etc. in variables.nix
# while the rest of the config keeps consuming them through the option system.
{ host, ... }:
let
  vars = import ../../hosts/${host}/variables.nix;
in
{
  machineProfiles = vars.profiles or { };
  customConf = vars.customConf or { };
}
