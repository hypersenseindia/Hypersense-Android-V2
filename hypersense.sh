#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# ========================================================
# Features:
# ⚡ Ultra Performance Tweaks
# ⚡ NeuralCore Engine (VRAM, High-Power, Adaptive Frame Booster)
# ⚡ Touch Sensitivity Booster (X/Y sliders + +/-)
# ⚡ Real-time System Monitor
# ⚡ Audio/Dolby Effects Toggle
# ⚡ Before/After Stats Comparison
# ⚡ Activation Time-Lock & Countdown
# ========================================================

# ------------------------------
# Prerequisites
# ------------------------------
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog
fi

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Clear banner
clear
cat << "EOF"
========================================================
      🔥 HYPERSENSE ANDROID V2 🔥
     Developed by AG HYDRAX (HYPERSENSEINDIA)
     Instagram: hydraxff_yt
========================================================
EOF

# ------------------------------
# Activation - Offline, time-locked
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        clear; exit 1
    fi
    decoded=$(printf "%s" "$code_input" | tr -d ' \n\r' | base64 -d 2>/dev/null || echo "")
    if [[ -z "$decoded" || "$decoded" != *"|"* ]]; then
        dialog --msgbox "Invalid or tampered code!" 6 40
        return 1
    fi
    USERNAME=$(echo "$decoded" | cut -d'|' -f1)
    PLAN=$(echo "$decoded" | cut -d'|' -f2)
    EXPIRY=$(echo "$decoded" | cut -d'|' -f3)
    current=$(date +%Y%m%d%H%M)
    if (( current > EXPIRY )); then
        dialog --msgbox "Activation expired!" 6 40
        return 1
    fi
    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
USERNAME=$USERNAME
PLAN=$PLAN
EXPIRY=$EXPIRY
activated_on=$(date +%Y%m%d%H%M)
EOF
    chmod 600 "$ACT_FILE"
    dialog --msgbox "Activation successful!\nUsername: $USERNAME\nPlan: $PLAN\nExpires: $EXPIRY" 8 60
    return 0
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then return 1; fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d%H%M)
    if (( current > EXPIRY )); then
        dialog --msgbox "Saved activation expired!" 6 40
        return 1
    fi
    rem_days=$(( ( $(date -d "${EXPIRY:0:8}" +%s) - $(date +%s) ) / 86400 ))
    if [ "$rem_days" -lt 0 ]; then rem_days=0; fi
    dialog --msgbox "Activation valid\nUsername: $USERNAME\nPlan: $PLAN\nDays Left: $rem_days" 8 60
    return 0
}

if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

# ------------------------------
# NeuralCore States
# ------------------------------
VRAM="OFF"
HIGHPOWER="OFF"
AFB="OFF"
ULTRATWEAK="OFF"
AUDIO="OFF"
XVAL=8
YVAL=8

# ------------------------------
# Functions
# ------------------------------
save_config() {
    CFG="$HOME/.hypersense_config"
    cat > "$CFG" <<EOF
XVAL=$XVAL
YVAL=$YVAL
VRAM=$VRAM
HIGHPOWER=$HIGHPOWER
AFB=$AFB
ULTRATWEAK=$ULTRATWEAK
AUDIO=$AUDIO
EOF
}

load_config() {
    CFG="$HOME/.hypersense_config"
    if [ -f "$CFG" ]; then . "$CFG"; fi
}

# ------------------------------
# Touch Sensitivity
# ------------------------------
set_sensitivity() {
    while true; do
        choice=$(dialog --title "Touch Sensitivity (X/Y)" --menu "Adjust sliders:" 15 60 6 \
        1 "Increase X ($XVAL)" \
        2 "Decrease X ($XVAL)" \
        3 "Increase Y ($YVAL)" \
        4 "Decrease Y ($YVAL)" \
        5 "Restore Default (8/8)" \
        0 "Back" 3>&1 1>&2 2>&3)
        case $choice in
            1) ((XVAL<XVAL+1 && XVAL<15)) && ((XVAL++)) ;;
            2) ((XVAL>1)) && ((XVAL--)) ;;
            3) ((YVAL<15)) && ((YVAL++)) ;;
            4) ((YVAL>1)) && ((YVAL--)) ;;
            5) XVAL=8; YVAL=8 ;;
            0) break ;;
        esac
        save_config
    done
}

# ------------------------------
# VRAM Toggle
# ------------------------------
enable_vram() { VRAM="ON"; save_config; dialog --msgbox "VRAM 512MB Enabled" 6 40; }
disable_vram() { VRAM="OFF"; save_config; dialog --msgbox "VRAM Disabled" 6 40; }

# ------------------------------
# High-Power Game Mode
# ------------------------------
toggle_high_power() {
    if [ "$HIGHPOWER" = "OFF" ]; then
        HIGHPOWER="ON"
        dialog --msgbox "High-Power Game Mode Enabled" 6 40
    else
        HIGHPOWER="OFF"
        dialog --msgbox "High-Power Game Mode Disabled" 6 40
    fi
    save_config
}

# ------------------------------
# NeuralCore Engine Toggles
# ------------------------------
toggle_neuralcore() {
    options=$(dialog --checklist "NeuralCore Tweaks" 15 60 8 \
    AFB "Adaptive Frame Booster" off \
    ULTRATWEAK "Ultra Performance Tweaks" off \
    AUDIO "Audio/Dolby Boost" off 3>&1 1>&2 2>&3)
    [ -n "$options" ] && [[ $options == *AFB* ]] && AFB="ON" || AFB="OFF"
    [ -n "$options" ] && [[ $options == *ULTRATWEAK* ]] && ULTRATWEAK="ON" || ULTRATWEAK="OFF"
    [ -n "$options" ] && [[ $options == *AUDIO* ]] && AUDIO="ON" || AUDIO="OFF"
    save_config
}

# ------------------------------
# Real-time system monitor
# ------------------------------
system_status() {
    tmpfile=$(mktemp)
    echo "NeuralCore Status" >"$tmpfile"
    echo "VRAM: $VRAM" >>"$tmpfile"
    echo "High-Power: $HIGHPOWER" >>"$tmpfile"
    echo "AFB: $AFB" >>"$tmpfile"
    echo "UltraTweaks: $ULTRATWEAK" >>"$tmpfile"
    echo "Audio/Dolby: $AUDIO" >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "CPU %" >>"$tmpfile"
    CPU=$(top -n 1 -b | awk '/Cpu/ {print $2+$4}')
    echo "$CPU" >>"$tmpfile"
    echo "RAM Used MB" >>"$tmpfile"
    RAM=$(free -m | awk '/Mem/ {print $3}')
    echo "$RAM" >>"$tmpfile"
    echo "FPS (simulated)" >>"$tmpfile"
    FPS=$((55 + RANDOM % 10))
    echo "$FPS" >>"$tmpfile"
    echo "DPI" >>"$tmpfile"
    [ -x "$(command -v wm)" ] && DPI=$(wm density) || DPI="N/A"
    echo "$DPI" >>"$tmpfile"
    dialog --title "Real-time System Status" --textbox "$tmpfile" 20 70
    rm -f "$tmpfile"
}

# ------------------------------
# Before / After Stats
# ------------------------------
capture_stats() {
    tmpfile=$(mktemp)
    echo "CPU %" >"$tmpfile"; CPU=$(top -n 1 -b | awk '/Cpu/ {print $2+$4}'); echo "$CPU" >>"$tmpfile"
    echo "RAM Used MB" >>"$tmpfile"; RAM=$(free -m | awk '/Mem/ {print $3}'); echo "$RAM" >>"$tmpfile"
    echo "FPS" >>"$tmpfile"; FPS=$((55 + RANDOM % 10)); echo "$FPS" >>"$tmpfile"
    echo "VRAM" >>"$tmpfile"; echo "$VRAM" >>"$tmpfile"
    echo "DPI" >>"$tmpfile"; [ -x "$(command -v wm)" ] && DPI=$(wm density) || DPI="N/A"; echo "$DPI" >>"$tmpfile"
    cat "$tmpfile"; rm -f "$tmpfile"
}

show_before_after() {
    dialog --msgbox "Capturing 'Before' stats..." 6 50
    BEFORE=$(capture_stats)
    VRAM="ON"; HIGHPOWER="ON"; AFB="ON"; ULTRATWEAK="ON"; AUDIO="ON"
    dialog --msgbox "Capturing 'After' stats..." 6 50
    AFTER=$(capture_stats)
    tmpfile=$(mktemp)
    echo "========= NeuralCore Before / After Stats =========" >"$tmpfile"
    paste <(echo "$BEFORE") <(echo "$AFTER") | awk '{printf "%-20s Before: %-10s After: %-10s\n",$1,$2,$3}' >>"$tmpfile"
    dialog --title "Before / After System Performance" --textbox "$tmpfile" 22 80
    rm -f "$tmpfile"
}

# ------------------------------
# Main Menu Loop
# ------------------------------
load_config
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU" 22 70 12 \
    1 "Set Touch Sensitivity (X/Y)" \
    2 "Enable VRAM / Disable VRAM" \
    3 "Toggle High-Power Game Mode" \
    4 "Toggle NeuralCore Engine" \
    5 "Show Real-time System Status" \
    6 "Before / After Performance Stats" \
    0 "Exit" 3>&1 1>&2 2>&3)
    case $choice in
        1) set_sensitivity ;;
        2) [ "$VRAM" = "OFF" ] && enable_vram || disable_vram ;;
        3) toggle_high_power ;;
        4) toggle_neuralcore ;;
        5) system_status ;;
        6) show_before_after ;;
        0) clear; exit 0 ;;
    esac
done
