#!/usr/bin/env bash
# Waybar-Modul für die NVIDIA-GPU (Gegenstück zu cpuinfo.sh).
# Wird in waybar.nix per writeShellApplication gebaut, nvidia-smi und jq
# kommen dort über runtimeInputs – keine PATH-Abhängigkeit vom Waybar-Service.
#
# Gibt immer gültiges JSON aus: Ist die GPU/der Treiber nicht erreichbar,
# erscheint "N/A" statt dass das Modul stillschweigend verschwindet.

emit() {
  # $1 = text, $2 = tooltip, $3 = class, $4 = percentage
  jq -cn --arg text "$1" --arg tooltip "$2" --arg class "$3" --argjson percentage "${4:-0}" \
    '{text: $text, tooltip: $tooltip, class: $class, percentage: $percentage}'
}

if ! INFO=$(nvidia-smi \
  --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,power.limit,clocks.gr,fan.speed \
  --format=csv,noheader,nounits 2>&1); then
  emit "󰢮  N/A" "nvidia-smi fehlgeschlagen:"$'\n'"${INFO}" "error"
  exit 0
fi

# Bei mehreren GPUs nur die erste anzeigen.
INFO=${INFO%%$'\n'*}
IFS=',' read -r NAME USAGE TEMP MEM_USED MEM_TOTAL POWER POWER_LIMIT CLOCK FAN <<<"$INFO"

# nvidia-smi setzt hinter jedes Komma ein Leerzeichen; nicht unterstützte
# Werte kommen als "[N/A]" bzw. "[Not Supported]".
clean() {
  local v="${1#"${1%%[![:space:]]*}"}"
  [[ "$v" == \[* ]] && v="–"
  printf '%s' "$v"
}
NAME=$(clean "$NAME")
USAGE=$(clean "$USAGE")
TEMP=$(clean "$TEMP")
MEM_USED=$(clean "$MEM_USED")
MEM_TOTAL=$(clean "$MEM_TOTAL")
POWER=$(clean "$POWER")
POWER_LIMIT=$(clean "$POWER_LIMIT")
CLOCK=$(clean "$CLOCK")
FAN=$(clean "$FAN")

[[ "$USAGE" =~ ^[0-9]+$ ]] || USAGE=0

MEM_PCT=0
if [[ "$MEM_USED" =~ ^[0-9]+$ && "$MEM_TOTAL" =~ ^[0-9]+$ ]] && ((MEM_TOTAL > 0)); then
  MEM_PCT=$((100 * MEM_USED / MEM_TOTAL))
fi

# Watt ohne Nachkommastellen anzeigen (z.B. "85.43" -> "85").
POWER=${POWER%%.*}
POWER_LIMIT=${POWER_LIMIT%%.*}

CLASS="normal"
((USAGE >= 60)) && CLASS="medium"
((USAGE >= 90)) && CLASS="high"

TOOLTIP="${NAME}
Auslastung: ${USAGE}%
Temperatur: ${TEMP}°C
VRAM: ${MEM_USED} / ${MEM_TOTAL} MiB (${MEM_PCT}%)
Leistung: ${POWER} / ${POWER_LIMIT} W
Takt: ${CLOCK} MHz
Lüfter: ${FAN}%"

emit "󰢮  ${USAGE}%" "$TOOLTIP" "$CLASS" "$USAGE"
