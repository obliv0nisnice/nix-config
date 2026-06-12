{ config, lib, pkgs, ... }: {
  # Steam-Starter Script
  home.file.".local/bin/steam-nvidia.sh" = {
    text = ''
      #!/usr/bin/env bash

      flatpak info org.freedesktop.Platform.GL.nvidia-570-153-02 &>/dev/null || {
        notify-send "Steam (NVIDIA)" "GL Runtime fehlt!"
        exit 1
      }
      flatpak info org.freedesktop.Platform.GL32.nvidia-570-153-02 &>/dev/null || {
        notify-send "Steam (NVIDIA)" "GL32 Runtime fehlt!"
        exit 1
      }

      flatpak override --user com.valvesoftware.Steam \
        --env=__NV_PRIME_RENDER_OFFLOAD=1 \
        --env=__GLX_VENDOR_LIBRARY_NAME=nvidia \
        --env=__VK_LAYER_NV_optimus=NVIDIA_only

      export WLR_NO_HARDWARE_CURSORS=1

      flatpak run \
        --nofilesystem=~/.themes \
        com.valvesoftware.Steam
    '';
    executable = true;
  };

  # Desktop-Eintrag
  home.file.".local/share/applications/steam-nvidia.desktop".text = ''
    [Desktop Entry]
    Name=Steam (NVIDIA)
    Exec=${"$HOME"}/.local/bin/steam-nvidia.sh
    Terminal=false
    Type=Application
    Icon=steam
    Categories=Game;
  '';

  # Flatpak Overrides & Theme-Fix & Steam Auto-Install
  home.activation.setSteamFlatpakOverrides = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "🛠️ [Steam] Setting Flatpak overrides..."

    # Flatpak Steam installieren falls nötig
    if ! ${pkgs.flatpak}/bin/flatpak info com.valvesoftware.Steam &>/dev/null; then
      echo "📦 [Steam] Installing Flatpak Steam..."
      ${pkgs.flatpak}/bin/flatpak install -y flathub com.valvesoftware.Steam
    fi

    # NVIDIA-Umgebungsvariablen setzen
    ${pkgs.flatpak}/bin/flatpak override --user com.valvesoftware.Steam \
      --env=__NV_PRIME_RENDER_OFFLOAD=1 \
      --env=__GLX_VENDOR_LIBRARY_NAME=nvidia \
      --env=__VK_LAYER_NV_optimus=NVIDIA_only

    # Theme vom Nix-Store entkoppeln (kopieren + Berechtigungen setzen)
    THEME_SOURCE=$(readlink -f "$HOME/.themes/adw-gtk3" || true)
    THEME_TARGET="$HOME/.themes/adw-gtk3"

    if [ -n "$THEME_SOURCE" ] && [[ "$THEME_SOURCE" == /nix/store/* ]]; then
      echo "🎨 [Steam] Kopiere Theme aus dem Nix Store nach ~/.themes/adw-gtk3..."
      rm -rf "$THEME_TARGET"
      mkdir -p "$HOME/.themes"
      cp -rT "$THEME_SOURCE" "$THEME_TARGET"
    fi

    # Schreibrechte setzen
    if [ -d "$HOME/.themes/adw-gtk3" ]; then
      echo "🔧 [Steam] Setze Berechtigungen für ~/.themes/adw-gtk3..."
      chmod -R u+rw "$HOME/.themes/adw-gtk3"
    fi
  '';
}
