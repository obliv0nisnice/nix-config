# Steam auf Apple Silicon (aarch64/Asahi) via muvm + FEX.
#
# Steam und praktisch alle Spiele gibt es nur als x86_64. Der Asahi-Kernel läuft
# zudem mit 16K Speicherseiten, x86-Spiele erwarten aber 4K. muvm bootet darum
# eine winzige MicroVM mit 4K-Pages und reicht die GPU durch (virtio/venus);
# darin führt FEX die x86-Binaries aus. Das ist der offiziell von Asahi
# unterstützte Weg (gleicher Stack wie im Fedora Asahi Remix).
#
# Dieses Modul liefert nur die deklarativen System-Teile: fex, muvm, den
# host-seitigen x86-Steam-Bootstrap und einen `steam-asahi`-Launcher. Ein
# Schritt bleibt einmalig manuell, weil er ein großer, veränderlicher Download
# ist und nicht in den Nix-Store gehört:
#
#   FEXRootFSFetcher        # lädt ein x86-RootFS (Ubuntu) nach ~/.fex-emu
#
# Danach startet `steam-asahi`; Steam lädt seinen eigenen x86-Client selbst nach.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.machineProfiles.apple.steam;

  # muvm bootet die 4K-Page-VM und führt den x86-Steam-Bootstrap unter FEX mit
  # GPU-Passthrough (venus) aus. muvm findet das FEX-RootFS aus ~/.fex-emu
  # selbst; ein abweichender erofs-Pfad lässt sich über $FEX_ROOTFS erzwingen.
  steam-asahi = pkgs.writeShellScriptBin "steam-asahi" ''
    set -eu
    fex_rootfs_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/fex-emu/RootFS"
    if [ ! -d "$fex_rootfs_dir" ] || [ -z "$(ls -A "$fex_rootfs_dir" 2>/dev/null)" ]; then
      echo "Hinweis: kein FEX-RootFS in $fex_rootfs_dir — vermutlich zuerst 'FEXRootFSFetcher' ausführen." >&2
    fi
    rootfs_arg=""
    if [ -n "''${FEX_ROOTFS:-}" ]; then
      rootfs_arg="-f ''${FEX_ROOTFS}"
    fi
    # Der steamwebhelper läuft in einer pressure-vessel-Sandbox (bubblewrap).
    # Deren Default-Graphics-Provider ist das Host-`/`, wodurch bwrap das auf
    # NixOS nicht existierende /usr/lib binden will und crasht. Leerer Wert =
    # Container nutzt seinen eigenen Grafik-Stack (Sniper-Mesa mit venus).
    export PRESSURE_VESSEL_GRAPHICS_PROVIDER=
    exec ${lib.getExe pkgs.muvm} --gpu-mode venus $rootfs_arg -- \
      ${lib.getExe pkgs.steam-unwrapped} "$@"
  '';
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fex
      pkgs.muvm
      pkgs.steam-unwrapped
      steam-asahi

      # FEXRootFSFetcher braucht eines dieser Tools, um das heruntergeladene
      # RootFS-Image zu entpacken/mounten; erofs-utils zusätzlich, weil muvms
      # `-f` erofs-Images erwartet.
      pkgs.squashfsTools # unsquashfs
      pkgs.squashfuse
      pkgs.erofs-utils # mkfs.erofs (squashfs -> erofs für muvm)
    ];

    # muvm braucht Zugriff auf /dev/kvm (Apple-Hypervisor via KVM).
    users.users.${username}.extraGroups = [ "kvm" ];

    # Steam bringt seine eigene Linux-Runtime mit (ubuntu12_32/steam-runtime),
    # die alle benötigten x86-Libs (GTK2, libXtst, nss …) liefert. Deren
    # setup.sh/run.sh haben aber `#!/bin/bash`, das es auf NixOS nicht gibt –
    # ohne das scheitert das Runtime-Setup still und steamui.so findet seine
    # Libs nicht. envfs stellt /bin/bash & /usr/bin/* dynamisch bereit.
    services.envfs.enable = true;

    # Der steamwebhelper läuft in einer pressure-vessel/bubblewrap-Sandbox, die
    # beim Default-Graphics-Provider "/" Host-FHS-Pfade in den Container bindet.
    # Fehlen sie, bricht bwrap mit "Can't get type of source /usr/lib" ab und der
    # Webhelper crash-loopt. NixOS hat diese Pfade nicht – leere Verzeichnisse
    # genügen, damit der Bind klappt (der Container nutzt dann sein eigenes Mesa).
    # (/lib existiert bereits über die nix-ld-tmpfiles-Regel.)
    systemd.tmpfiles.rules = [
      "d /usr/lib 0755 root root -"
      "d /lib64 0755 root root -"
    ];
  };
}
