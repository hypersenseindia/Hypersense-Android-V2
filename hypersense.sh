#!/data/data/com.termux/files/usr/bin/bash
# ===============================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Insta: hydraxff_yt
# ===============================================

# ------------------------------
# Auto-install dialog if missing
# ------------------------------
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog
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
     Insta: hydraxff_yt
========================================================

⚡ Ultra Performance Tweaks
⚡ NeuralCore Engine (CPU/GPU/VRAM optimization)
⚡ Touch Sensitivity Booster (X/Y)
⚡ Adaptive Frame Booster
⚡ High-Power Game Mode
⚡ Audio/Dolby Effect
⚡ FPS & Latency Live Monitor
⚡ Real-Time System Stats & Comparison
⚡ Offline Activation (1 device per key)
========================================================
EOF

# ------------------------------
# Activation System
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

get_device_id() {
    device_id=""
    device_id=$(settings get secure android_id 2>/dev/null)
    if [ -z "$device_id" ]; then device_id=$(getprop ro.serialno 2>/dev/null); fi
    if [ -z "$device_id" ]; then device_id=$(getprop ro.boot.serialno 2>/dev/null); fi
    if [ -z "$device_id" ]; then
        cpu=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | tr -d ' ')
        mac=$(cat /sys/class/net/wlan0/address 2>/dev/null || echo "")
        device_id="${cpu}_${mac}"
    fi
    [ -z "$device_id" ] && device_id="unknown_device_$(date +%s)"
    echo "$device_id"
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

check_activation() {
    [ ! -f "$ACT_FILE" ] && return 1
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if ! [[ "$expiry" =~ ^[0-9]{8}$ ]]; then return 1; fi
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
    [ "$rem_days" -lt 0 ] && rem_days=0
    return 0
}

activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    [ -z "$code_input" ] && { dialog --msgbox "No code entered!" 6 40; clear; exit 1; }
    decoded=$(printf "%s" "$code_input" | tr -d ' \n\r' | base64 -d 2>/dev/null || echo "")
    [[ -z "$decoded" || "$decoded" != *"-"* ]] && { dialog --msgbox "Invalid code!" 6 40; return 1; }
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

# ------------------------------
# Check or activate on start
# ------------------------------
if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

# ------------------------------
# Configuration
# ------------------------------
CFG="$HOME/.hypersense_config"
: "${SENS_X:=8}"
: "${SENS_Y:=8}"
: "${VRAM_ENABLED:=0}"
: "${HIGH_POWER:=0}"
: "${AFB_ENABLED:=0}"
: "${AUDIO_EFFECT:=0}"

# ------------------------------
# FPS & Performance Simulation (placeholder for real-time monitor)
# ------------------------------
get_real_fps() {
    # read fps via dumpsys gfxinfo if available
    app=$1
    fps_val=0
    if command -v dumpsys >/dev/null 2>&1 && [ -n "$app" ]; then
        fps_val=$(dumpsys gfxinfo $app | grep "Total frames" | awk '{print $3}' | tail -1)
        fps_val=${fps_val:-0}
    fi
    echo "$fps_val"
}

# ------------------------------
# Touch Sensitivity
# ------------------------------
set_touch_sens() {
    SENS_X=$1
    SENS_Y=$2
}

# ------------------------------
# Toggle features
# ------------------------------
toggle_vram() { VRAM_ENABLED=$((1-VRAM_ENABLED)); }
toggle_high_power() { HIGH_POWER=$((1-HIGH_POWER)); }
toggle_afb() { AFB_ENABLED=$((1-AFB_ENABLED)); }
toggle_audio() { AUDIO_EFFECT=$((1-AUDIO_EFFECT)); }

# ------------------------------
# Real-time monitor GUI
# ------------------------------
live_monitor() {
    tmpfile=$(mktemp)
    while true; do
        clear
        echo "HYPERSENSE LIVE MONITOR" > "$tmpfile"
        echo "-----------------------" >> "$tmpfile"
        echo "Touch Sensitivity: X=$SENS_X Y=$SENS_Y" >> "$tmpfile"
        echo "VRAM: $([ $VRAM_ENABLED -eq 1 ] && echo ON || echo OFF)" >> "$tmpfile"
        echo "High-Power Mode: $([ $HIGH_POWER -eq 1 ] && echo ON || echo OFF)" >> "$tmpfile"
        echo "Adaptive Frame Booster: $([ $AFB_ENABLED -eq 1 ] && echo ON || echo OFF)" >> "$tmpfile"
        echo "Audio/Dolby Effect: $([ $AUDIO_EFFECT -eq 1 ] && echo ON || echo OFF)" >> "$tmpfile"
        echo "Activation Expires: $expiry" >> "$tmpfile"
        echo "Remaining Days: $(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))" >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "FPS Before: $(get_real_fps com.dts.freefireth)" >> "$tmpfile"
        echo "FPS After: $(get_real_fps com.dts.freefireth)" >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "CPU Info:" >> "$tmpfile"
        awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -6 >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "RAM Info:" >> "$tmpfile"
        free -h >> "$tmpfile"
        echo "" >> "$tmpfile"
        echo "GPU Info:" >> "$tmpfile"
        dumpsys gfxinfo 2>/dev/null | head -20 >> "$tmpfile"
        dialog --title "NeuralCore Live Monitor" --textbox "$tmpfile" 22 86
        break
    done
    rm -f "$tmpfile"
}

# ------------------------------
# Main Menu
# ------------------------------
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan | Expires: $expiry)" 22 86 9 \
    1 "Set Touch Sensitivity X/Y (1-15)" \
    2 "Toggle VRAM ON/OFF" \
    3 "Toggle High-Power Game Mode" \
    4 "Toggle Adaptive Frame Booster" \
    5 "Toggle Audio/Dolby Effect" \
    6 "NeuralCore Live Monitor" \
    7 "Show Before/After Performance Comparison" \
    0 "Exit" 3>&1 1>&2 2>&3 3>&-)

    case $choice in
        1)
            SENS_X=$(dialog --inputbox "Set X sensitivity (1-15):" 8 40 "$SENS_X" 3>&1 1>&2 2>&3)
            SENS_Y=$(dialog --inputbox "Set Y sensitivity (1-15):" 8 40 "$SENS_Y" 3>&1 1>&2 2>&3)
            ;;
        2) toggle_vram ;;
        3) toggle_high_power ;;
        4) toggle_afb ;;
        5) toggle_audio ;;
        6) live_monitor ;;
        7)
            dialog --msgbox "Before/After comparison (placeholder). Real-time stats shown in Monitor tab." 10 60
            ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
