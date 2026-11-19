#!/usr/bin/env bash

# Check if real NetworkManager is active; if so, pass through to /usr/bin/nmcli
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    exec /usr/bin/nmcli "$@"
fi

# Fallback: Emulate nmcli output using iwd (iwctl) and systemd-networkd / sysfs / ip
ARGS=("$@")

# 1. Device status
# nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status
if [[ "$*" =~ "device" && "$*" =~ "status" ]]; then
    # Query wlan0 via iwctl
    WLAN_STATE="disconnected"
    WLAN_CONN=""
    if command -v iwctl >/dev/null 2>&1; then
        ST_OUT="$(iwctl station wlan0 show 2>/dev/null)"
        if echo "$ST_OUT" | grep -q "State\s*connected"; then
            WLAN_STATE="connected"
            WLAN_CONN="$(echo "$ST_OUT" | awk -F'Connected network' '/Connected network/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
        elif echo "$ST_OUT" | grep -q "State\s*connecting"; then
            WLAN_STATE="connecting"
            WLAN_CONN="$(echo "$ST_OUT" | awk -F'Connected network' '/Connected network/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
        fi
    fi

    # Check ethernet
    ETH_STATE="unavailable"
    ETH_CONN=""
    if [ -f /sys/class/net/eno1/carrier ] && [ "$(cat /sys/class/net/eno1/carrier 2>/dev/null)" = "1" ]; then
        ETH_STATE="connected"
        ETH_CONN="Wired connection 1"
    fi

    if [[ "$*" =~ "-t" ]]; then
        echo "eno1:ethernet:${ETH_STATE}:${ETH_CONN}"
        echo "wlan0:wifi:${WLAN_STATE}:${WLAN_CONN}"
        echo "lo:loopback:unmanaged:"
    else
        echo "DEVICE  TYPE      STATE        CONNECTION"
        echo "eno1    ethernet  ${ETH_STATE}  ${ETH_CONN}"
        echo "wlan0   wifi      ${WLAN_STATE}    ${WLAN_CONN}"
        echo "lo      loopback  unmanaged    --"
    fi
    exit 0
fi

# 2. Radio status
# nmcli radio wifi
if [[ "$*" =~ "radio" && "$*" =~ "wifi" ]]; then
    echo "enabled"
    exit 0
fi

# 3. Wi-Fi networks detail list
# nmcli -g ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY d w
if [[ "$*" =~ "d" && "$*" =~ "w" ]] || [[ "$*" =~ "device" && "$*" =~ "wifi" ]]; then
    if command -v iwctl >/dev/null 2>&1; then
        ST_OUT="$(iwctl station wlan0 show 2>/dev/null)"
        CURR_SSID=""
        CURR_BSSID=""
        CURR_FREQ="2432"
        CURR_RSSI="-50"

        if echo "$ST_OUT" | grep -q "State\s*connected"; then
            CURR_SSID="$(echo "$ST_OUT" | awk -F'Connected network' '/Connected network/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
            CURR_BSSID="$(echo "$ST_OUT" | awk -F'ConnectedBss' '/ConnectedBss/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
            CURR_FREQ="$(echo "$ST_OUT" | awk -F'Frequency' '/Frequency/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')"
            CURR_RSSI="$(echo "$ST_OUT" | awk -F'RSSI' '/RSSI/ {gsub(/^[ \t]+|[ \t]+|dBm$/, "", $2); print $2}')"
        fi

        # Convert RSSI to signal (0-100)
        RSSI_NUM="${CURR_RSSI:- -50}"
        if [ "$RSSI_NUM" -ge -50 ] 2>/dev/null; then
            SIG=100
        elif [ "$RSSI_NUM" -le -100 ] 2>/dev/null; then
            SIG=0
        else
            SIG=$(( 2 * (RSSI_NUM + 100) ))
        fi

        if [ -n "$CURR_SSID" ]; then
            echo "yes:${SIG}:${CURR_FREQ:-2412}:${CURR_SSID}:${CURR_BSSID:-6a:f9:c4:70:b4:e6}:WPA2"
        fi

        # List other networks from iwctl
        iwctl station wlan0 get-networks 2>/dev/null | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g" | awk '
            NR > 4 {
                line = $0
                if (line ~ /^\s*$/) next
                gsub(/^[\s>]+/, "", line)
                split(line, parts, /[ ]{2,}/)
                name = parts[1]
                sec = parts[2]
                sig = parts[3]
                if (name != "" && name != "Network name") {
                    bars = 50
                    if (sig ~ /\*\*\*\*/) bars = 90
                    else if (sig ~ /\*\*\*/) bars = 70
                    else if (sig ~ /\*\*/) bars = 50
                    else if (sig ~ /\*/) bars = 25
                    print "no:" bars ":2412:" name "::" (sec ? sec : "WPA2")
                }
            }
        '
    fi
    exit 0
fi

# 4. Monitor loop
# nmcli monitor
if [[ "$*" =~ "monitor" ]]; then
    while true; do
        sleep 5
    done
    exit 0
fi

# 5. Fallback to real nmcli
exec /usr/bin/nmcli "$@"
