#!/run/current-system/sw/bin/bash

# --- Erste Messung ---
read -r _ user1 nice1 sys1 idle1 iowait1 irq1 softirq1 steal1 _ _ < /proc/stat
declare -A OLD_TOTAL OLD_IDLE
while read -r line; do
  [[ "$line" =~ ^cpu([0-9]+)\ (.*) ]] || continue
  CORE=${BASH_REMATCH[1]}
  FIELDS=(${BASH_REMATCH[2]})
  total=0
  for i in {0..7}; do total=$((total + FIELDS[i])); done
  OLD_TOTAL[$CORE]=$total
  OLD_IDLE[$CORE]=${FIELDS[3]}
done < /proc/stat

sleep 0.5

# --- Zweite Messung ---
read -r _ user2 nice2 sys2 idle2 iowait2 irq2 softirq2 steal2 _ _ < /proc/stat

total1=$((user1 + nice1 + sys1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
total2=$((user2 + nice2 + sys2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
diff_total=$((total2 - total1))
diff_idle=$((idle2 - idle1))
total_usage=0
(( diff_total > 0 )) && total_usage=$(( (100 * (diff_total - diff_idle)) / diff_total ))

# --- Core-Auslastungen ---
TOOLTIP="CPU gesamt: ${total_usage}%\n"
while read -r line; do
  [[ "$line" =~ ^cpu([0-9]+)\ (.*) ]] || continue
  CORE=${BASH_REMATCH[1]}
  FIELDS=(${BASH_REMATCH[2]})
  total=0
  for i in {0..7}; do total=$((total + FIELDS[i])); done
  idle=${FIELDS[3]}
  diff_t=$((total - OLD_TOTAL[$CORE]))
  diff_i=$((idle - OLD_IDLE[$CORE]))
  usage=0
  (( diff_t > 0 )) && usage=$(( (100 * (diff_t - diff_i)) / diff_t ))
  TOOLTIP+="Core $CORE: ${usage}%\n"
done < /proc/stat

# --- Ausgabe ---
echo "{\"text\": \"  ${total_usage}%\", \"tooltip\": \"${TOOLTIP}\"}"
