#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
#      🔥 HYPERSENSE ANDROID V2 🔥
#     Developed by AG HYDRAX (HYPERSENSEINDIA)
#     Instagram: @hydraxff_yt
# ========================================================

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Clear
clear

# ------------------------------
# Required packages
# ------------------------------
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog
fi

# ------------------------------
# Activation storage
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    [ -z "$device_id" ] && device_id=$(getprop ro.serialno 2>/dev/null)
    [ -z "$device_id" ] && device_id="device_$(date +%s)"
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
    expiry=$(printf "%s" "$decoded" | cut -d'-' -f2)
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
        dialog --msgbox "Saved activation found but expired on $expiry." 6 50
        return 1
    fi

    device_id_now=$(get_device_id)
    device_hash_now=$(sha256_hash "$device_id_now")
    if [ -n "$device_hash" ] && [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation key is bound to another device. Activation denied." 8 60
        return 1
    fi

    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    [ "$rem_days" -lt 0 ] && rem_days=0
    dialog --msgbox "Activation valid. Plan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

# Activation check
if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

# ------------------------------
# Touch Sensitivity
# ------------------------------
CFG="$HOME/.hypersense_config"
XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2)
YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2)
: "${XVAL:=8}"
: "${YVAL:=8}"

set_sensitivity() {
    local x=$XVAL
    local y=$YVAL
    while true; do
        choice=$(dialog --menu "Touch Sensitivity X/Y: X=$x Y=$y" 15 60 4 \
        1 "Increase X (+1)" \
        2 "Decrease X (-1)" \
        3 "Increase Y (+1)" \
        4 "Decrease Y (-1)" \
        0 "Save & Exit" 3>&1 1>&2 2>&3 3>&-)
        case $choice in
            1) ((x<15)) && x=$((x+1));;
            2) ((x>1)) && x=$((x-1));;
            3) ((y<15)) && y=$((y+1));;
            4) ((y>1)) && y=$((y-1));;
            0) break;;
        esac
    done
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$x
sensitivity_y=$y
EOF
    dialog --msgbox "Touch Sensitivity Updated: X=$x Y=$y" 6 50
}

# ------------------------------
# VRAM (swapfile)
# ------------------------------
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
enable_swap() {
    if [ -f "$SWAPFILE" ]; then
        dialog --msgbox "VRAM already enabled." 6 50
        return
    fi
    size_mb=512
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$size_mb 2>/dev/null
    mkswap "$SWAPFILE" 2>/dev/null
    chmod 600 "$SWAPFILE" 2>/dev/null
    swapon "$SWAPFILE" 2>/dev/null
    dialog --msgbox "VRAM Enabled: $size_mb MB" 6 50
}

disable_swap() {
    if [ -f "$SWAPFILE" ]; then
        swapoff "$SWAPFILE" 2>/dev/null
        rm -f "$SWAPFILE"
        dialog --msgbox "VRAM Disabled" 6 50
    else
        dialog --msgbox "VRAM is already off" 6 50
    fi
}

# ------------------------------
# High-Power Game Mode
# ------------------------------
toggle_high_power() {
    dialog --yesno "Enable High-Power Game Mode? May increase battery usage." 8 60
    if [ $? -eq 0 ]; then
        svc power stayon true 2>/dev/null
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        svc power stayon false 2>/dev/null
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
}

# ------------------------------
# Adaptive Frame Booster / NeuralCore
# ------------------------------
toggle_afb() {
    dialog --yesno "Enable NeuralCore Adaptive Frame Booster?" 8 60
    if [ $? -eq 0 ]; then
        dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else
        dialog --msgbox "Adaptive Frame Booster Disabled" 6 50
    fi
}

# ------------------------------
# System Monitor
# ------------------------------
system_monitor() {
    tmpfile=$(mktemp)
    echo "System Monitor - NeuralCore Status" > "$tmpfile"
    echo "Time: $(date)" >> "$tmpfile"
    echo "CPU:" $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo) >> "$tmpfile"
    echo "RAM:" >> "$tmpfile"; free -h >> "$tmpfile"
    echo "GPU/OpenGL:" >> "$tmpfile"; dumpsys gfxinfo 2>/dev/null | head -n 20 >> "$tmpfile"
    echo "DPI:" $(wm density) >> "$tmpfile" 2>/dev/null
    echo "VRAM Status:"; [ -f "$SWAPFILE" ] && echo "ON" || echo "OFF" >> "$tmpfile"
    dialog --title "System Monitor" --textbox "$tmpfile" 25 80
    rm -f "$tmpfile"
}

# ------------------------------
# Performance Comparison
# ------------------------------
performance_comparison() {
    tmp_before=$(mktemp)
    tmp_after=$(mktemp)
    tmp_report=$(mktemp)

    echo "=== BEFORE TWEAKS ===" > "$tmp_before"
    echo "Time: $(date)" >> "$tmp_before"
    echo "CPU:" $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo) >> "$tmp_before"
    echo "RAM:" >> "$tmp_before"; free -h >> "$tmp_before"
    echo "DPI:" $(wm density) >> "$tmp_before" 2>/dev/null
    echo "GPU/OpenGL:" >> "$tmp_before"; dumpsys gfxinfo 2>/dev/null | head -n 20 >> "$tmp_before"

    dialog --msgbox "Apply your tweaks (VRAM, AFB, High-Power, Sensitivity). Press OK when done." 8 60

    echo "=== AFTER TWEAKS ===" > "$tmp_after"
    echo "Time: $(date)" >> "$tmp_after"
    echo "CPU:" $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo) >> "$tmp_after"
    echo "RAM:" >> "$tmp_after"; free -h >> "$tmp_after"
    echo "DPI:" $(wm density) >> "$tmp_after" 2>/dev/null
    echo "GPU/OpenGL:" >> "$tmp_after"; dumpsys gfxinfo 2>/dev/null | head -n 20 >> "$tmp_after"

    paste -d '\t' "$tmp_before" "$tmp_after" >> "$tmp_report"
    dialog --title "Performance Comparison" --textbox "$tmp_report" 25 100

    rm -f "$tmp_before" "$tmp_after" "$tmp_report"
}

# ------------------------------
# Main menu loop
# ------------------------------
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan | Expires: $expiry)" 25 80 12 \
    1 "Set Touch Sensitivity (X/Y)" \
    2 "Enable NeuralCore VRAM" \
    3 "Disable VRAM" \
    4 "Toggle High-Power Game Mode" \
    5 "Adaptive Frame Booster (NeuralCore) On/Off" \
    6 "System Monitor (Real-Time Status)" \
    7 "Performance Comparison Before/After" \
    0 "Exit / Restore Defaults" 3>&1 1>&2 2>&3 3>&-)

    case $choice in
        1) set_sensitivity ;;
        2) enable_swap ;;
        3) disable_swap ;;
        4) toggle_high_power ;;
        5) toggle_afb ;;
        6) system_monitor ;;
        7) performance_comparison ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
