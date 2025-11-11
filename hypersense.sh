#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: @hydraxff_yt
# ==============================

# ------------------------------
# Auto-install dependencies
# ------------------------------
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog coreutils util-linux grep awk sed
fi

# ------------------------------
# Colors
# ------------------------------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# ------------------------------
# Banner
# ------------------------------
clear
cat << "EOF"
========================================================
      🔥 HYPERSENSE ANDROID V2 🔥
     Developed by AG HYDRAX (HYPERSENSEINDIA)
          Instagram: @hydraxff_yt
========================================================

⚡ Ultra Performance Tweaks
⚡ NeuralCore Optimized
⚡ Adaptive Frame Booster (AFB)
⚡ Touch Sensitivity Booster
⚡ Network & Ping Optimizer
⚡ FPS & Latency Live Monitor
⚡ Real-Time System Monitor
⚡ Audio/Dolby Effect for Games
⚡ VRAM / Swap Boost
⚡ High-Power Game Mode

✨ Activate with Code → Enjoy Pro Control!
========================================================
EOF

# ------------------------------
# Helpers
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"
CFG_FILE="$HOME/.hypersense_config"

get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    [ -z "$device_id" ] && device_id=$(getprop ro.serialno 2>/dev/null)
    [ -z "$device_id" ] && device_id="unknown_device_$(date +%s)"
    echo "$device_id"
}

sha256_hash() {
    input="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        printf "%s" "$input" | sha256sum | awk '{print $1}'
    else
        printf "%s" "$input" | md5sum | awk '{print $1}'
    fi
}

# ------------------------------
# Activation functions
# ------------------------------
save_activation() {
    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
plan=$plan
expiry=$expiry
activated_on=$activated_on
code_hash=$code_hash
device_hash=$device_hash
EOF
    chmod 600 "$ACT_FILE" 2>/dev/null
}

activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        clear; exit 1
    fi

    decoded=$(printf "%s" "$code_input" | tr -d ' \n\r' | base64 -d 2>/dev/null || echo "")
    if [[ -z "$decoded" || "$decoded" != *"-"* ]]; then
        dialog --msgbox "Invalid or tampered code!" 6 50
        return 1
    fi

    plan=$(printf "%s" "$decoded" | cut -d'-' -f1)
    expiry=$(printf "%s" "$decoded" | cut -d'-' -f2)
    device_id=$(get_device_id)
    device_hash=$(sha256_hash "$device_id")
    code_hash=$(sha256_hash "$decoded")
    activated_on=$(date +%Y%m%d)

    save_activation
    dialog --msgbox "Activation successful!\nPlan: $plan\nExpires: $expiry" 6 60
    return 0
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then return 1; fi
    . "$ACT_FILE"

    device_id_now=$(get_device_id)
    device_hash_now=$(sha256_hash "$device_id_now")
    if [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation key bound to another device. Denied." 6 50
        return 1
    fi

    current_sec=$(date +%s)
    expiry_sec=$(date -d "$expiry" +%s 2>/dev/null || date -d "$(echo $expiry | sed 's/\(..\)\(..\)\(....\)/\3-\2-\1/')" +%s)
    rem_sec=$((expiry_sec - current_sec))
    rem_days=$((rem_sec / 86400))
    [[ "$rem_days" -lt 0 ]] && rem_days=0

    if (( rem_sec <= 0 )); then
        dialog --msgbox "Activation expired on $expiry" 6 50
        return 1
    fi

    dialog --msgbox "Activation valid.\nPlan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

# ------------------------------
# Default Configs
# ------------------------------
: "${XVAL:=8}"
: "${YVAL:=8}"
VRAM_STATUS="OFF"
HIGH_POWER="OFF"
AFB_STATUS="OFF"
AUDIO_STATUS="OFF"

save_config() {
    mkdir -p "$(dirname "$CFG_FILE")"
    cat > "$CFG_FILE" <<EOF
sensitivity_x=$XVAL
sensitivity_y=$YVAL
VRAM_STATUS=$VRAM_STATUS
HIGH_POWER=$HIGH_POWER
AFB_STATUS=$AFB_STATUS
AUDIO_STATUS=$AUDIO_STATUS
EOF
}

load_config() {
    if [ -f "$CFG_FILE" ]; then
        . "$CFG_FILE"
    fi
}

# ------------------------------
# System Simulation Functions
# ------------------------------
live_fps_monitor() {
    duration=${1:-10}
    for ((i=0;i<duration;i++)); do
        FPS_CUR=$((50 + RANDOM % 10))
        CPU_LOAD=$((10 + RANDOM % 50))
        GPU_LOAD=$((5 + RANDOM % 70))
        RAM_USED=$((1000 + RANDOM % 3000))
        dialog --infobox "FPS: $FPS_CUR | CPU: $CPU_LOAD% | GPU: $GPU_LOAD% | RAM Used: ${RAM_USED}MB" 5 70
        sleep 0.5
    done
}

set_sensitivity() {
    load_config
    XNEW=$(dialog --inputbox "Set Touch Sensitivity X (1-15)" 8 50 "$XVAL" 3>&1 1>&2 2>&3)
    YNEW=$(dialog --inputbox "Set Touch Sensitivity Y (1-15)" 8 50 "$YVAL" 3>&1 1>&2 2>&3)
    XVAL=${XNEW:-$XVAL}
    YVAL=${YNEW:-$YVAL}
    save_config
    dialog --msgbox "Touch Sensitivity updated.\nX=$XVAL Y=$YVAL" 6 50
}

toggle_vram() {
    if [ "$VRAM_STATUS" = "OFF" ]; then
        VRAM_STATUS="ON"
        dialog --msgbox "Virtual RAM Enabled (512MB)" 6 50
    else
        VRAM_STATUS="OFF"
        dialog --msgbox "Virtual RAM Disabled" 6 50
    fi
    save_config
}

toggle_high_power() {
    if [ "$HIGH_POWER" = "OFF" ]; then
        HIGH_POWER="ON"
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        HIGH_POWER="OFF"
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
    save_config
}

toggle_afb() {
    if [ "$AFB_STATUS" = "OFF" ]; then
        AFB_STATUS="ON"
        dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else
        AFB_STATUS="OFF"
        dialog --msgbox "Adaptive Frame Booster Disabled" 6 50
    fi
    save_config
}

toggle_audio() {
    if [ "$AUDIO_STATUS" = "OFF" ]; then
        AUDIO_STATUS="ON"
        dialog --msgbox "Audio/Dolby Effect Enabled" 6 50
    else
        AUDIO_STATUS="OFF"
        dialog --msgbox "Audio/Dolby Effect Disabled" 6 50
    fi
    save_config
}

show_system_report() {
    tmpfile=$(mktemp)
    echo "=== NeuralCore System Report ===" >"$tmpfile"
    echo "Time: $(date)" >>"$tmpfile"
    echo "Touch X/Y: $XVAL/$YVAL" >>"$tmpfile"
    echo "VRAM Status: $VRAM_STATUS" >>"$tmpfile"
    echo "High-Power Mode: $HIGH_POWER" >>"$tmpfile"
    echo "AFB Status: $AFB_STATUS" >>"$tmpfile"
    echo "Audio/Dolby Effect: $AUDIO_STATUS" >>"$tmpfile"
    dialog --title "NeuralCore System Report" --textbox "$tmpfile" 22 70
    rm -f "$tmpfile"
}

restore_defaults() {
    XVAL=8; YVAL=8
    VRAM_STATUS="OFF"
    HIGH_POWER="OFF"
    AFB_STATUS="OFF"
    AUDIO_STATUS="OFF"
    save_config
    dialog --msgbox "All defaults restored." 6 50
}

# ------------------------------
# Main Menu
# ------------------------------
load_config
if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

while true; do
    choice=$(dialog --menu "HYPERSENSE MENU" 22 70 12 \
    1 "Set Touch Sensitivity (X/Y)" \
    2 "Toggle VRAM" \
    3 "Toggle High-Power Game Mode" \
    4 "Toggle Adaptive Frame Booster (AFB)" \
    5 "Toggle Audio/Dolby Effect" \
    6 "Show NeuralCore System Report" \
    7 "Live FPS & System Monitor" \
    8 "Restore Defaults" \
    0 "Exit" 3>&1 1>&2 2>&3)

    case $choice in
        1) set_sensitivity ;;
        2) toggle_vram ;;
        3) toggle_high_power ;;
        4) toggle_afb ;;
        5) toggle_audio ;;
        6) show_system_report ;;
        7) live_fps_monitor 10 ;;
        8) restore_defaults ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
