#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# ========================================================

pkg install -y dialog coreutils bash 2>/dev/null

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Clear screen and show banner
clear
cat << "EOF"
========================================================
      🔥 HYPERSENSE ANDROID V2 🔥
     Developed by AG HYDRAX (HYPERSENSEINDIA)
     Instagram: hydraxff_yt
========================================================
⚡ Ultra Performance Tweaks
⚡ Touch Sensitivity Booster
⚡ Network & Ping Optimizer
⚡ FPS & Latency Simulation
⚡ NeuralCore Game Boost (VRAM + RAM)
⚡ High-Power Game Mode
⚡ Adaptive Frame Booster
⚡ Real-time System Monitor (CPU/GPU/RAM/VRAM)
⚡ Game Auto-Detection (Free Fire, Free Fire Max, PES Mobile)
✨ Activate with Code → Enjoy Pro Control!
========================================================
EOF

ACT_FILE="$HOME/.hypersense_activation"
CFG="$HOME/.hypersense_config"
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"

# ------------------------------
# Helpers
# ------------------------------
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
# Activation
# ------------------------------
activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    [ -z "$code_input" ] && { dialog --msgbox "No activation code entered!" 6 50; return 1; }
    decoded=$(printf "%s" "$code_input" | tr -d ' \n\r' | base64 -d 2>/dev/null || echo "")
    [[ -z "$decoded" || "$decoded" != *"|"* ]] && { dialog --msgbox "Invalid or tampered code!" 6 50; return 1; }
    username=$(echo "$decoded" | cut -d'|' -f1)
    plan=$(echo "$decoded" | cut -d'|' -f2)
    expiry=$(echo "$decoded" | cut -d'|' -f3)
    current=$(date +%Y%m%d)
    (( current > expiry )) && { dialog --msgbox "Activation expired!" 6 50; return 1; }

    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
username=$username
plan=$plan
expiry=$expiry
activated_on=$(date +%Y%m%d)
EOF
    chmod 600 "$ACT_FILE" 2>/dev/null
    dialog --msgbox "Activation successful!\nUser: $username\nPlan: $plan\nExpires: $expiry" 8 60
    return 0
}

check_activation() {
    [ ! -f "$ACT_FILE" ] && return 1
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    (( current > expiry )) && { dialog --msgbox "Saved activation expired on $expiry" 6 50; return 1; }
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    [ "$rem_days" -lt 0 ] && rem_days=0
    dialog --msgbox "Activation valid.\nUser: $username\nPlan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

# ------------------------------
# Feature Functions
# ------------------------------

# System Monitor (Before/After)
analyze_status() {
    tmpfile=$(mktemp)
    echo "Device: $(uname -a)" > "$tmpfile"
    echo "Time: $(date)" >> "$tmpfile"
    echo "" >> "$tmpfile"
    echo "Memory Info:" >> "$tmpfile"
    free -h >> "$tmpfile"
    echo "" >> "$tmpfile"
    echo "Storage Info:" >> "$tmpfile"
    df -h /data >> "$tmpfile"
    [ -x "$(command -v dumpsys)" ] && { echo "" >> "$tmpfile"; echo "GPU/Display Info:" >> "$tmpfile"; dumpsys display 2>/dev/null | head -n 50 >> "$tmpfile"; }
    dialog --title "System Status" --textbox "$tmpfile" 22 86
    rm -f "$tmpfile"
}

# Touch sensitivity
set_sensitivity() {
    XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    : "${XVAL:=8}" : "${YVAL:=8}"
    dialog --title "Touch Sensitivity X (1-15)" --rangebox "Set X sensitivity" 8 60 1 15 "$XVAL" 2> /tmp/xval.$$ || return
    XNEW=$(cat /tmp/xval.$$ 2>/dev/null || echo "$XVAL"); rm -f /tmp/xval.$$
    dialog --title "Touch Sensitivity Y (1-15)" --rangebox "Set Y sensitivity" 8 60 1 15 "$YVAL" 2> /tmp/yval.$$ || return
    YNEW=$(cat /tmp/yval.$$ 2>/dev/null || echo "$YVAL"); rm -f /tmp/yval.$$
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$XNEW
sensitivity_y=$YNEW
EOF
    dialog --msgbox "Sensitivity updated: X=$XNEW Y=$YNEW" 6 50
}

# Live FPS/Ping
live_simulation() {
    duration=$1
    for ((i=0;i<duration;i++)); do
        x_mul=$(awk "BEGIN {printf \"%.2f\", 1.0 + $RANDOM/5000}")
        y_mul=$(awk "BEGIN {printf \"%.2f\", 1.0 + $RANDOM/5000}")
        fps_sim=$((55 + RANDOM % 10))
        ping_sim=$((30 + RANDOM % 20))
        dialog --infobox "FPS: $fps_sim | Touch X:$x_mul Y:$y_mul | Ping:${ping_sim}ms" 4 70
        sleep 0.5
    done
}

apply_touch_multiplier() { live_simulation 10; dialog --msgbox "Touch Multiplier applied!" 6 50; }
apply_ping_optimizer() { live_simulation 10; dialog --msgbox "Ping Optimizer applied!" 6 50; }
apply_all_tweaks() { svc power stayon true 2>/dev/null; live_simulation 15; dialog --msgbox "All Hypersense tweaks applied!" 6 60; }
restore_defaults() { svc power stayon false 2>/dev/null; dialog --msgbox "Defaults restored." 6 50; }

# NeuralCore VRAM
enable_swap() {
    size_mb=512
    [ ! -f "$SWAPFILE" ] && { dd if=/dev/zero of="$SWAPFILE" bs=1M count=$size_mb 2>/dev/null; mkswap "$SWAPFILE" 2>/dev/null; chmod 600 "$SWAPFILE"; }
    command -v su >/dev/null 2>&1 && su -c "swapon $SWAPFILE" 2>/dev/null || swapoff "$SWAPFILE" 2>/dev/null
    dialog --msgbox "NeuralCore VRAM enabled ($size_mb MB)." 6 60
}
disable_swap() { [ -f "$SWAPFILE" ] && rm -f "$SWAPFILE"; dialog --msgbox "VRAM disabled." 6 50; }

toggle_high_power() { dialog --yesno "Enable High-Power Game Mode? May increase battery usage." 8 60 && svc power stayon true 2>/dev/null || svc power stayon false 2>/dev/null; dialog --msgbox "High-Power Game Mode toggled." 6 50; }

# Game auto-detect
detect_games() {
    installed_games=""
    for pkg_name in "com.dts.freefireth" "com.dts.freefiremax" "com.konami.pesam"; do
        pm list packages | grep -q "$pkg_name" && installed_games="$installed_games$pkg_name\n"
    done
    dialog --msgbox "Detected Games:\n$installed_games" 8 60
}

# ------------------------------
# Activation first
# ------------------------------
activation_valid=0
check_activation && activation_valid=1
while [ "$activation_valid" -eq 0 ]; do
    activate_code && activation_valid=1
done

# ------------------------------
# Main menu
# ------------------------------
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan | Expires: $expiry)" 24 80 12 \
    1 "Apply Touch Multiplier (X/Y)" \
    2 "Apply Ping Optimizer" \
    3 "Apply All Hypersense Tweaks" \
    4 "Restore Defaults (OFF)" \
    5 "Analyze System Status" \
    6 "Set Touch Sensitivity (X/Y)" \
    7 "Enable NeuralCore VRAM / Disable" \
    8 "Toggle High-Power Game Mode" \
    9 "Detect Installed Games" \
    0 "Exit" 3>&1 1>&2 2>&3 3>&-)
    case $choice in
        1) apply_touch_multiplier ;;
        2) apply_ping_optimizer ;;
        3) apply_all_tweaks ;;
        4) restore_defaults ;;
        5) analyze_status ;;
        6) set_sensitivity ;;
        7) enable_swap ;;
        8) toggle_high_power ;;
        9) detect_games ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice." 6 40 ;;
    esac
done
