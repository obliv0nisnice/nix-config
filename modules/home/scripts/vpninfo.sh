#!/usr/bin/env bash
# Waybar-Modul: zeigt an, ob (und welche) VPNs aktiv sind.
# Wird in waybar.nix per writeShellApplication gebaut (ip, jq, nmcli, timeout
# über runtimeInputs). `mullvad status` wird nur genutzt, falls installiert
# (`netbird status` bräuchte Root für den Daemon-Socket, daher nicht).
#
# Erkennung über die Netzwerk-Interfaces, damit auch "vergessene" VPNs
# auffallen: WireGuard (wg-quick, Mullvad, NetBird, Tailscale) und tun/tap
# (OpenVPN, OpenConnect). Namen von NetworkManager-Verbindungen werden, wenn
# vorhanden, dazugeschrieben.

ICON_ON="󰦝"
ICON_OFF="󰦞"

emit() {
  # $1 = text, $2 = tooltip, $3 = class
  # Tooltips sind Pango-Markup -> &, <, > escapen.
  jq -cn --arg text "$1" --arg tooltip "$2" --arg class "$3" \
    '{text: $text, class: $class,
      tooltip: ($tooltip | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;"))}'
}

# Aktive VPN-artige Interfaces: "name kind" pro Zeile.
IFACES=$(ip -j -d link show up 2>/dev/null | jq -r '
  .[] | select(.linkinfo.info_kind == "wireguard" or .linkinfo.info_kind == "tun")
      | "\(.ifname) \(.linkinfo.info_kind)"') || IFACES=""

if [[ -z "$IFACES" ]]; then
  emit "$ICON_OFF" "Kein VPN aktiv" "inactive"
  exit 0
fi

# NetworkManager: Gerät -> Verbindungsname (z.B. importierte OpenVPN-Profile).
declare -A NM_NAME=()
while IFS=: read -r name device; do
  [[ -n "$device" ]] && NM_NAME[$device]=$name
done < <(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null || true)

# Interface, über das die Default-Route läuft.
DEFAULT_DEV=$(ip -j route get 1.1.1.1 2>/dev/null | jq -r '.[0].dev // empty') || DEFAULT_DEV=""

TOOLTIP=""
while read -r ifname kind; do
  case "$ifname" in
    wg*-mullvad) label="Mullvad" ;;
    wt*|nb-*) label="NetBird" ;;
    tailscale*) label="Tailscale" ;;
    *) if [[ "$kind" == "wireguard" ]]; then label="WireGuard"; else label="OpenVPN/OpenConnect"; fi ;;
  esac

  line="${label}: ${ifname}"
  [[ -n "${NM_NAME[$ifname]:-}" ]] && line+=" (${NM_NAME[$ifname]})"

  addr=$(ip -j -4 addr show dev "$ifname" 2>/dev/null | jq -r '.[0].addr_info[0].local // empty') || addr=""
  [[ -n "$addr" ]] && line+="\n    IP: ${addr}"
  [[ "$ifname" == "$DEFAULT_DEV" ]] && line+="\n    gesamter Traffic läuft hierüber"

  if [[ "$label" == "Mullvad" ]] && command -v mullvad >/dev/null; then
    while IFS= read -r l; do
      l="${l#"${l%%[![:space:]]*}"}"
      [[ -n "$l" ]] && line+="\n    ${l}"
    done < <(timeout 2 mullvad status 2>/dev/null | grep -E '^(Connected|Connecting)|Relay:|Visible location:' | tr -s ' ' || true)
  fi

  TOOLTIP+="${line}\n"
done <<<"$IFACES"

# \n in echte Zeilenumbrüche wandeln, letzten Umbruch entfernen.
TOOLTIP=$(printf '%b' "$TOOLTIP")
emit "$ICON_ON" "$TOOLTIP" "active"
