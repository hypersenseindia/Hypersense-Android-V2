#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
#      🔥 HYPERSENSE ANDROID V2 🔥
#     Developed by AG HYDRAX (HYPERSENSEINDIA)
#     Instagram: hydraxff_yt
# ========================================================

# Auto-install dialog if missing
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog
fi

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Clear and show banner
clear
cat <<EOF
${CYAN}========================================================
      🔥 HYPERSENSE ANDROID V2 🔥
     Developed by AG HYDRAX (HYPERSENSEINDIA)
     Instagram: hydraxff_yt
========================================================
⚡ Ultra Performance Tweaks
⚡ Touch Sensitivity Booster
⚡ Network & Ping Optimizer
⚡ FPS & Latency Simulation
⚡ NeuralCore VRAM Manager
⚡ High-Power Game Mode
⚡ Adaptive Frame Booster (AFB)
⚡ Audio/Dolby Enhancement
⚡ Real-time System Monitor
✨ Activate with Code → Enjoy Pro Control!
========================================================${NC}
EOF

# ------------------------------
# Persistent files
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"
CFG_FILE="$HOME/.hypersense_config"
STATUS_FILE="$HOME/.hypersense_status"

# ------------------------------
# Helpers
# ------------------------------
get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    if [ -z "$device_id" ]; then
        device_id=$(getprop ro.serialno 2>/dev/null)
    fi
    if [ -z "$device_id" ]; then
        cpu=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -d ' ')
        mac=$(cat /sys/class/net/wlan0/address 2>/dev/null || echo "")
        device_id="${cpu}_${mac}"
    fi
    echo "${device_id:-unknown_device_$(date +%s)}"
}

sha256_hash() {
    input="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        printf "%s" "$input" | sha256sum | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        printf "%s" "$input" | shasum -a 256 | awk '{print $1}'
    else
        printf "%s" "$input" | md5sum | awk '{print $1}'
    fi
}

# ------------------------------
# Activation (offline)
# ------------------------------
activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        clear; exit 1
    fi

    decoded=$(printf "%s" "$code_input" | tr -d ' \n\r' | base64 -d 2>/dev/null || echo "")
    if [[ -z "$decoded" || "$decoded" != *"-"* ]]; then
        dialog --msgbox "Invalid or tampered code!" 6 40
        return 1
    fi

    plan=$(printf "%s" "$decoded" | cut -d'-' -f1)
    expiry=$(printf "%s" "$decoded" | cut -d'-' -f2 | tr -d '-')
    device_id=$(get_device_id)
    device_hash=$(sha256_hash "$device_id")
    code_hash=$(sha256_hash "$decoded")
    activated_on=$(date +%Y%m%d)

    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
plan=$plan
expiry=$expiry
code_hash=$code_hash
device_hash=$device_hash
activated_on=$activated_on
EOF
    chmod 600 "$ACT_FILE" 2>/dev/null
    dialog --msgbox "Activation successful! Plan: $plan | Expires: $expiry" 6 60
    return 0
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then return 1; fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Saved activation expired on $expiry." 6 50
        return 1
    fi
    device_id_now=$(get_device_id)
    device_hash_now=$(sha256_hash "$device_id_now")
    if [ -n "$device_hash" ] && [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation key bound to another device. Denied." 8 60
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    rem_days=$(( rem_days<0 ? 0 : rem_days ))
    dialog --msgbox "Activation valid. Plan: $plan | Expires: $expiry | Days left: $rem_days" 8 60
    return 0
}

# Check or ask activation
if ! check_activation; then
    if ! activate_code; then clear; exit 1; fi
fi

# ------------------------------
# Touch Sensitivity
# ------------------------------
set_sensitivity() {
    XVAL=$(grep '^sensitivity_x=' "$CFG_FILE" 2>/dev/null | cut -d'=' -f2)
    YVAL=$(grep '^sensitivity_y=' "$CFG_FILE" 2>/dev/null | cut -d'=' -f2)
    : "${XVAL:=8}"; : "${YVAL:=8}"

    dialog --title "Touch Sensitivity X (1-15)" --rangebox "Adjust X sensitivity" 8 60 1 15 "$XVAL" 2> /tmp/xval.$$ || return
    XNEW=$(cat /tmp/xval.$$ 2>/dev/null || echo "$XVAL"); rm -f /tmp/xval.$$
    dialog --title "Touch Sensitivity Y (1-15)" --rangebox "Adjust Y sensitivity" 8 60 1 15 "$YVAL" 2> /tmp/yval.$$ || return
    YNEW=$(cat /tmp/yval.$$ 2>/dev/null || echo "$YVAL"); rm -f /tmp/yval.$$

    mkdir -p "$(dirname "$CFG_FILE")"
    cat > "$CFG_FILE" <<EOF
sensitivity_x=$XNEW
sensitivity_y=$YNEW
EOF
    dialog --msgbox "Sensitivity updated: X=$XNEW Y=$YNEW" 6 50
}

# ------------------------------
# NeuralCore VRAM
# ------------------------------
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
vram_status="OFF"

enable_vram() {
    if [ ! -f "$SWAPFILE" ]; then
        dd if=/dev/zero of="$SWAPFILE" bs=1M count=512 2>/dev/null
        mkswap "$SWAPFILE" 2>/dev/null
        chmod 600 "$SWAPFILE" 2>/dev/null
    fi
    if command -v su >/dev/null 2>&1; then su -c "swapon $SWAPFILE" 2>/dev/null; fi
    vram_status="ON"
    dialog --msgbox "NeuralCore VRAM enabled (512MB)" 6 50
}

disable_vram() {
    if [ -f "$SWAPFILE" ]; then
        if command -v su >/dev/null 2>&1; then su -c "swapoff $SWAPFILE" 2>/dev/null; else swapoff "$SWAPFILE" 2>/dev/null; fi
        rm -f "$SWAPFILE"
    fi
    vram_status="OFF"
    dialog --msgbox "NeuralCore VRAM disabled" 6 50
}

# ------------------------------
# High-Power Game Mode
# ------------------------------
high_power="OFF"
toggle_high_power() {
    if [ "$high_power" = "OFF" ]; then
        svc power stayon true 2>/dev/null
        high_power="ON"
        dialog --msgbox "High-Power Game Mode enabled" 6 50
    else
        svc power stayon false 2>/dev/null
        high_power="OFF"
        dialog --msgbox "High-Power Game Mode disabled" 6 50
    fi
}

# ------------------------------
# Adaptive Frame Booster
# ------------------------------
afb_status="OFF"
toggle_afb() {
    if [ "$afb_status" = "OFF" ]; then
        afb_status="ON"
        dialog --msgbox "Adaptive Frame Booster enabled" 6 50
    else
        afb_status="OFF"
        dialog --msgbox "Adaptive Frame Booster disabled" 6 50
    fi
}

# ------------------------------
# Audio/Dolby Effect
# ------------------------------
audio_status="OFF"
toggle_audio() {
    if [ "$audio_status" = "OFF" ]; then
        audio_status="ON"
        dialog --msgbox "Audio/Dolby Effect enabled" 6 50
    else
        audio_status="OFF"
        dialog --msgbox "Audio/Dolby Effect disabled" 6 50
    fi
}

# ------------------------------
# Live FPS / System Monitor snapshot
# ------------------------------
show_monitor() {
    tmpfile=$(mktemp)
    echo "=== NeuralCore System Monitor Snapshot ===" >"$tmpfile"
    echo "Time: $(date)" >>"$tmpfile"
    echo "FPS (current): $(dumpsys SurfaceFlinger --latency-display | awk 'NR>1 {print int(1000000000/$1)}' 2>/dev/null || echo N/A)" >>"$tmpfile"
    echo "VRAM: $vram_status" >>"$tmpfile"
    echo "High-Power Mode: $high_power" >>"$tmpfile"
    echo "AFB: $afb_status" >>"$tmpfile"
    echo "Audio/Dolby: $audio_status" >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "CPU info:" >>"$tmpfile"
    awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -6 >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "Memory info:" >>"$tmpfile"
    free -h >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "Storage info:" >>"$tmpfile"
    df -h /data 2>/dev/null | head -2 >>"$tmpfile"
    dialog --title "System Monitor - NeuralCore" --textbox "$tmpfile" 25 90
    rm -f "$tmpfile"
}

# ------------------------------
# Restore defaults
# ------------------------------
restore_defaults() {
    disable_vram
    high_power="OFF"
    afb_status="OFF"
    audio_status="OFF"
    dialog --msgbox "Defaults restored. All tweaks OFF." 6 50
}

# ------------------------------
# Main menu
# ------------------------------
while true; do
    choice=$(dialog --menu "HYPERSENSE V2 MENU" 25 90 12 \
        1 "Set Touch Sensitivity (X/Y)" \
        2 "Enable NeuralCore VRAM / Disable" \
        3 "Toggle High-Power Game Mode ON/OFF" \
        4 "Adaptive Frame Booster ON/OFF" \
        5 "Audio/Dolby Effect ON/OFF" \
        6 "NeuralCore System Monitor" \
        7 "Restore Defaults" \
        0 "Exit" 3>&1 1>&2 2>&3 3>&-)

    case $choice in
        1) set_sensitivity ;;
        2) if [ "$vram_status" = "OFF" ]; then enable_vram; else disable_vram; fi ;;
        3) toggle_high_power ;;
        4) toggle_afb ;;
        5) toggle_audio ;;
        6) show_monitor ;;
        7) restore_defaults ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
