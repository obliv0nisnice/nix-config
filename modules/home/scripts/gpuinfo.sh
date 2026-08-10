#!/run/current-system/sw/bin/bash

INFO=$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null) || exit 0

IFS=',' read -r NAME USAGE TEMP MEM_USED MEM_TOTAL <<< "$INFO"

# nvidia-smi setzt hinter jedes Komma ein Leerzeichen
USAGE=${USAGE# }
TEMP=${TEMP# }
MEM_USED=${MEM_USED# }
MEM_TOTAL=${MEM_TOTAL# }

TOOLTIP="${NAME}\nAuslastung: ${USAGE}%\nTemperatur: ${TEMP}°C\nVRAM: ${MEM_USED} / ${MEM_TOTAL} MiB"

echo "{\"text\": \"󰢮  ${USAGE}%\", \"tooltip\": \"${TOOLTIP}\"}"
