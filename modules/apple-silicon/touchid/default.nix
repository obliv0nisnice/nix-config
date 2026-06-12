# Touch ID / Secure Enclave (SEP) bring-up — Apple t6020 (MacBook Pro 14" M2 Pro).
# Reverse-engineering-Vorhaben, ausführliche Doku/Logbuch: ~/Projects/MacFingerprint
# (dort PROGRESS.md). Dieser Ordner bündelt alle Touch-ID-bezogenen Configs.
#
# Die fprintd/PAM-Option (options.fingerprint.enable) kommt aus modules/core/fingerprint.nix
# und wird hier NICHT erneut definiert; touchid liefert nur den SEP-Kernel-Patch.
{ ... }:
{
  imports = [
    ./sep-enable.nix # DTS-Patch: sep-Node okay + sep-Alias (triggert m1n1 dt_set_sep)
  ];
}
