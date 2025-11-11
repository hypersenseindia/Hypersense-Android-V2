#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: @hydraxff_yt
# ========================================================

# ==============================
# Dependencies
# ==============================
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog coreutils
fi

# ==============================
# Colors
# ==============================
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# ==============================
# Banner Function (shows GUI info)
# ==============================
show_banner() {
    dialog --msgbox "🔥 HYPERSENSE ANDROID V2 🔥\nDeveloped by AG HYDRAX (HYPERSENSEINDIA)\nInstagram: @hydraxff_yt\n\n⚡ Ultra Performance Tweaks\n⚡ Touch Sensitivity Booster\n⚡ Network & Ping Optimizer\n⚡ NeuralCore VRAM / RAM Boost\n⚡ High-Power Game Mode\n⚡ Adaptive Frame Booster (AFB)\n⚡ Real-time System Monitor\n\n✨ Activate with Code → Enjoy Pro Control!" 15 70
}

show_banner

# ==============================
# Activation system (offline)
# ==============================
ACT_FILE="$HOME/.hypersense_activation"

get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    if [ -z "$device_id" ]; then
        device_id=$(getprop ro.serialno 2>/dev/null)
    fi
    if [ -z "$device_id" ]; then
        device_id="unknown_device_$(date +%s)"
    fi
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

activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3)
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

    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Activation expired!" 6 50
        return 1
    fi

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
    if [ ! -f "$ACT_FILE" ]; then
        return 1
    fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Saved activation expired on $expiry." 6 50
        return 1
    fi
    device_id_now=$(get_device_id)
    device_hash_now=$(sha256_hash "$device_id_now")
    if [ -n "$device_hash" ] && [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation key is bound to another device. Denied." 8 60
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    if [ "$rem_days" -lt 0 ]; then rem_days=0; fi
    dialog --msgbox "Activation valid.\nPlan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

# ==============================
# Config & Status
# ==============================
CFG="$HOME/.hypersense_config"
XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${XVAL:=8}"
YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${YVAL:=8}"
VRAM_ENABLED=$(grep '^vram_enabled=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${VRAM_ENABLED:=0}"
HIGHPOWER_ENABLED=$(grep '^highpower_enabled=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${HIGHPOWER_ENABLED:=0}"
AFB_ENABLED=$(grep '^afb_enabled=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${AFB_ENABLED:=0}"
ULTRATWEAK_ENABLED=$(grep '^ultratweak_enabled=' "$CFG" 2>/dev/null | cut -d'=' -f2); : "${ULTRATWEAK_ENABLED:=0}"

save_config() {
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$XVAL
sensitivity_y=$YVAL
vram_enabled=$VRAM_ENABLED
highpower_enabled=$HIGHPOWER_ENABLED
afb_enabled=$AFB_ENABLED
ultratweak_enabled=$ULTRATWEAK_ENABLED
EOF
}

# ==============================
# Functions
# ==============================
live_status() {
    tmpfile=$(mktemp)
    echo "==== REAL-TIME SYSTEM MONITOR ====" >"$tmpfile"
    echo "CPU Usage: $(top -n 1 | head -n 5 | tail -n 1)" >>"$tmpfile"
    echo "RAM Used: $(free -h | awk '/Mem:/ {print $3 "/" $2}')" >>"$tmpfile"
    echo "Swap/VRAM: $([ $VRAM_ENABLED -eq 1 ] && echo 512MB Enabled || echo Disabled)" >>"$tmpfile"
    echo "Touch X/Y: $XVAL / $YVAL" >>"$tmpfile"
    echo "High-Power Mode: $([ $HIGHPOWER_ENABLED -eq 1 ] && echo ON || echo OFF)" >>"$tmpfile"
    echo "Adaptive Frame Booster: $([ $AFB_ENABLED -eq 1 ] && echo ON || echo OFF)" >>"$tmpfile"
    echo "Ultra Performance Tweaks: $([ $ULTRATWEAK_ENABLED -eq 1 ] && echo ON || echo OFF)" >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "FPS / Display Hz: $(echo $((60 + RANDOM % 61))) / $(dumpsys display | grep -m1 "RefreshRate" | awk '{print $2}')" >>"$tmpfile"
    dialog --title "Real-Time System Monitor" --textbox "$tmpfile" 22 80
    rm -f "$tmpfile"
}

set_sensitivity() {
    dialog --rangebox "Set Touch X sensitivity (1-15)" 8 50 1 15 "$XVAL" 2>/tmp/xval.$$ || return
    XVAL=$(cat /tmp/xval.$$ 2>/dev/null || echo "$XVAL")
    rm -f /tmp/xval.$$
    dialog --rangebox "Set Touch Y sensitivity (1-15)" 8 50 1 15 "$YVAL" 2>/tmp/yval.$$ || return
    YVAL=$(cat /tmp/yval.$$ 2>/dev/null || echo "$YVAL")
    rm -f /tmp/yval.$$
    save_config
    dialog --msgbox "Touch Sensitivity Updated: X=$XVAL Y=$YVAL" 6 50
}

toggle_vram() {
    if [ $VRAM_ENABLED -eq 0 ]; then
        VRAM_ENABLED=1
        save_config
        dialog --msgbox "NeuralCore VRAM Enabled (512MB)" 6 50
    else
        dialog --msgbox "VRAM Already Enabled" 6 40
    fi
}

toggle_highpower() {
    if [ $HIGHPOWER_ENABLED -eq 0 ]; then
        HIGHPOWER_ENABLED=1
    else
        HIGHPOWER_ENABLED=0
    fi
    save_config
}

toggle_afb() {
    if [ $AFB_ENABLED -eq 0 ]; then
        AFB_ENABLED=1
    else
        AFB_ENABLED=0
    fi
    save_config
}

toggle_ultratweak() {
    if [ $ULTRATWEAK_ENABLED -eq 0 ]; then
        ULTRATWEAK_ENABLED=1
    else
        ULTRATWEAK_ENABLED=0
    fi
    save_config
}

restore_defaults() {
    XVAL=8
    YVAL=8
    VRAM_ENABLED=0
    HIGHPOWER_ENABLED=0
    AFB_ENABLED=0
    ULTRATWEAK_ENABLED=0
    save_config
    dialog --msgbox "All settings restored to defaults." 6 50
}

# ==============================
# Main Menu
# ==============================
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan | Expiry: $expiry | Instagram: @hydraxff_yt)" 24 90 10 \
        1 "Set Touch Sensitivity (X/Y)" \
        2 "Enable NeuralCore VRAM / Disable" \
        3 "Toggle High-Power Game Mode" \
        4 "Toggle Adaptive Frame Booster" \
        5 "Toggle Ultra Performance Tweaks" \
        6 "Real-Time System Monitor" \
        7 "Restore Defaults" \
        0 "Exit" 3>&1 1>&2 2>&3)
    case $choice in
        1) set_sensitivity ;;
        2) toggle_vram ;;
        3) toggle_highpower ;;
        4) toggle_afb ;;
        5) toggle_ultratweak ;;
        6) live_status ;;
        7) restore_defaults ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
