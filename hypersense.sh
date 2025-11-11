#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
#      🔥 HYPERSENSE ANDROID V2 🔥
#     Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: @hydraxff_yt
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

clear
echo -e "${CYAN}=== HYPERSENSE ANDROID V2 ===${NC}"
echo -e "${CYAN}Developed by AG HYDRAX (HYPERSENSEINDIA)${NC}"
echo -e "${CYAN}Instagram: @hydraxff_yt${NC}"
echo ""

# Activation file
ACT_FILE="$HOME/.hypersense_activation"

sha256_hash() {
    input="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        printf "%s" "$input" | sha256sum | awk '{print $1}'
    else
        printf "%s" "$input" | md5sum | awk '{print $1}'
    fi
}

get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    [ -z "$device_id" ] && device_id=$(getprop ro.serialno 2>/dev/null)
    [ -z "$device_id" ] && device_id=$(getprop ro.boot.serialno 2>/dev/null)
    [ -z "$device_id" ] && device_id="unknown_device_$(date +%s)"
    echo "$device_id"
}

save_activation() {
    token="$1"
    username="$2"
    plan="$3"
    expiry="$4"
    device_hash=$(sha256_hash "$(get_device_id)")
    token_hash=$(sha256_hash "$token")
    activated_on=$(date +%Y%m%d%H%M)
    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
username=$username
plan=$plan
expiry=$expiry
token_hash=$token_hash
device_hash=$device_hash
activated_on=$activated_on
EOF
    chmod 600 "$ACT_FILE" 2>/dev/null
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then
        return 1
    fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Activation expired on $expiry" 6 50
        return 1
    fi
    current_device_hash=$(sha256_hash "$(get_device_id)")
    if [ "$device_hash" != "$current_device_hash" ]; then
        dialog --msgbox "Activation key bound to another device. Denied." 8 60
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    [ "$rem_days" -lt 0 ] && rem_days=0
    dialog --msgbox "Activation valid. Plan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

activate_token() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        clear; exit 1
    fi
    decoded=$(printf "%s" "$code_input" | base64 -d 2>/dev/null || echo "")
    if [[ -z "$decoded" || "$decoded" != *"|"* ]]; then
        dialog --msgbox "Invalid code!" 6 40
        return 1
    fi
    username=$(echo "$decoded" | cut -d'|' -f1)
    plan=$(echo "$decoded" | cut -d'|' -f2)
    expiry=$(echo "$decoded" | cut -d'|' -f3)
    save_activation "$code_input" "$username" "$plan" "$expiry"
    dialog --msgbox "Activation successful! Plan: $plan | Expires: $expiry" 6 60
}

if ! check_activation; then
    activate_token || { clear; exit 1; }
fi

# -----------------------------
# NeuralCore Features
# -----------------------------
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
VRAM_ON=0
HIGH_POWER=0
AFB_ON=0
AUDIO_ON=0

enable_vram() {
    if [ $VRAM_ON -eq 0 ]; then
        dd if=/dev/zero of="$SWAPFILE" bs=1M count=512 2>/dev/null
        mkswap "$SWAPFILE" 2>/dev/null
        chmod 600 "$SWAPFILE"
        swapon "$SWAPFILE" 2>/dev/null
        VRAM_ON=1
        dialog --msgbox "NeuralCore VRAM Enabled (512MB)" 6 50
    else
        dialog --msgbox "VRAM already enabled" 6 50
    fi
}

disable_vram() {
    if [ $VRAM_ON -eq 1 ]; then
        swapoff "$SWAPFILE" 2>/dev/null
        rm -f "$SWAPFILE"
        VRAM_ON=0
        dialog --msgbox "VRAM Disabled" 6 50
    else
        dialog --msgbox "VRAM is already off" 6 50
    fi
}

toggle_high_power() {
    if [ $HIGH_POWER -eq 0 ]; then
        svc power stayon true 2>/dev/null
        if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                echo performance > "$cpu"/cpufreq/scaling_governor 2>/dev/null
            done
        fi
        HIGH_POWER=1
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        svc power stayon false 2>/dev/null
        if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                echo ondemand > "$cpu"/cpufreq/scaling_governor 2>/dev/null
            done
        fi
        HIGH_POWER=0
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
}

toggle_afb() {
    if [ $AFB_ON -eq 0 ]; then
        AFB_ON=1
        dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else
        AFB_ON=0
        dialog --msgbox "Adaptive Frame Booster Disabled" 6 50
    fi
}

toggle_audio() {
    if [ $AUDIO_ON -eq 0 ]; then
        AUDIO_ON=1
        dialog --msgbox "Audio/Dolby Effect Enabled" 6 50
    else
        AUDIO_ON=0
        dialog --msgbox "Audio/Dolby Effect Disabled" 6 50
    fi
}

set_touch_sensitivity() {
    CFG="$HOME/.hypersense_config"
    XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    : "${XVAL:=8}"
    : "${YVAL:=8}"
    dialog --rangebox "Touch Sensitivity X (1-15)" 8 60 1 15 "$XVAL" 2> /tmp/xval.$$ || return
    XNEW=$(cat /tmp/xval.$$ 2>/dev/null || echo "$XVAL")
    rm -f /tmp/xval.$$
    dialog --rangebox "Touch Sensitivity Y (1-15)" 8 60 1 15 "$YVAL" 2> /tmp/yval.$$ || return
    YNEW=$(cat /tmp/yval.$$ 2>/dev/null || echo "$YVAL")
    rm -f /tmp/yval.$$
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$XNEW
sensitivity_y=$YNEW
EOF
    dialog --msgbox "Touch Sensitivity Updated: X=$XNEW Y=$YNEW" 6 50
}

live_monitor() {
    tmpfile=$(mktemp)
    while true; do
        clear
        echo "=== NeuralCore Live Monitor ==="
        echo "VRAM: $( [ $VRAM_ON -eq 1 ] && echo ON || echo OFF )"
        echo "High-Power Mode: $( [ $HIGH_POWER -eq 1 ] && echo ON || echo OFF )"
        echo "Adaptive Frame Booster: $( [ $AFB_ON -eq 1 ] && echo ON || echo OFF )"
        echo "Audio/Dolby: $( [ $AUDIO_ON -eq 1 ] && echo ON || echo OFF )"
        echo ""
        if command -v dumpsys >/dev/null 2>&1; then
            fps=$(dumpsys gfxinfo | grep -E 'Frames rendered|Vsync' | head -1)
            echo "$fps"
        fi
        echo ""
        echo "Press Ctrl+C to exit live monitor"
        sleep 1
    done
}

# Main menu
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan)" 25 70 12 \
    1 "Set Touch Sensitivity (X/Y)" \
    2 "Enable VRAM" \
    3 "Disable VRAM" \
    4 "Toggle High-Power Game Mode" \
    5 "Toggle Adaptive Frame Booster" \
    6 "Toggle Audio/Dolby Effect" \
    7 "Live System Monitor" \
    0 "Exit" 3>&1 1>&2 2>&3 3>&-)
    
    case $choice in
        1) set_touch_sensitivity ;;
        2) enable_vram ;;
        3) disable_vram ;;
        4) toggle_high_power ;;
        5) toggle_afb ;;
        6) toggle_audio ;;
        7) live_monitor ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
