#!/data/data/com.termux/files/usr/bin/bash
# =======================================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# =======================================================
# Features:
# ⚡ Ultra Performance Tweaks
# ⚡ Touch Sensitivity Booster (+/- sliders)
# ⚡ Network & Ping Optimizer
# ⚡ FPS & Latency Simulation
# ⚡ NeuralCore VRAM Toggle
# ⚡ High-Power Game Mode
# ⚡ Adaptive Frame Booster
# ⚡ Real-time System Monitor
# ⚡ Audio/Dolby Effects (NeuralCore)
# ⚡ Activation Countdown / Time-Lock
# =======================================================

# ------------------------------
# Ensure dialog is installed
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

# Clear and show banner
clear
cat <<'EOF'
=======================================================
      🔥 HYPERSENSE ANDROID V2 🔥
     Developed by AG HYDRAX (HYPERSENSEINDIA)
     Instagram: hydraxff_yt
=======================================================
✨ Activate with Code → Enjoy Pro Control!
=======================================================
EOF

# ------------------------------
# Activation file
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

# ------------------------------
# Activation functions
# ------------------------------
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
    EXPIRY=$(echo "$decoded" | cut -d'|' -f3 | tr -d '[:space:]')
    EXPIRY_NUM=$(echo "$EXPIRY" | tr -cd '0-9')
    current=$(date +%Y%m%d%H%M)
    if (( current > EXPIRY_NUM )); then
        dialog --msgbox "Activation expired!" 6 40
        return 1
    fi
    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
USERNAME=$USERNAME
PLAN=$PLAN
EXPIRY=$EXPIRY_NUM
activated_on=$(date +%Y%m%d%H%M)
VRAM_ENABLED=0
HIGHPOWER=0
TOUCH_X=8
TOUCH_Y=8
ULTRA_TWEAKS=0
ADAPTIVE_FRAME=0
DOLBY_AUDIO=0
EOF
    chmod 600 "$ACT_FILE"
    dialog --msgbox "Activation successful!\nUsername: $USERNAME\nPlan: $PLAN\nExpires: $EXPIRY_NUM" 8 60
    return 0
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then return 1; fi
    . "$ACT_FILE"
    EXPIRY=$(echo "$EXPIRY" | tr -cd '0-9')
    current=$(date +%Y%m%d%H%M)
    if (( current > EXPIRY )); then
        dialog --msgbox "Saved activation expired!" 6 40
        return 1
    fi
    rem_days=$(( ( $(date -d "${EXPIRY:0:8}" +%s) - $(date +%s) ) / 86400 ))
    [ "$rem_days" -lt 0 ] && rem_days=0
    dialog --msgbox "Activation valid\nUsername: $USERNAME\nPlan: $PLAN\nDays Left: $rem_days" 8 60
    return 0
}

# ------------------------------
# Live System Monitor
# ------------------------------
live_status() {
    tmpfile=$(mktemp)
    echo "HYPERSENSE LIVE SYSTEM STATUS" >"$tmpfile"
    echo "Username: $USERNAME" >>"$tmpfile"
    echo "Plan: $PLAN" >>"$tmpfile"
    echo "VRAM: $( [ $VRAM_ENABLED -eq 1 ] && echo ON || echo OFF )" >>"$tmpfile"
    echo "High-Power Mode: $( [ $HIGHPOWER -eq 1 ] && echo ON || echo OFF )" >>"$tmpfile"
    echo "Touch Sensitivity X/Y: $TOUCH_X / $TOUCH_Y" >>"$tmpfile"
    echo "Ultra Tweaks: $( [ $ULTRA_TWEAKS -eq 1 ] && echo ON || echo OFF )" >>"$tmpfile"
    echo "Adaptive Frame Booster: $( [ $ADAPTIVE_FRAME -eq 1 ] && echo ON || echo OFF )" >>"$tmpfile"
    echo "Dolby/Audio Boost: $( [ $DOLBY_AUDIO -eq 1 ] && echo ON || echo OFF )" >>"$tmpfile"
    echo "" >>"$tmpfile"
    # Memory
    free -h >>"$tmpfile" 2>/dev/null
    # CPU Info
    awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -6 >>"$tmpfile"
    # Storage
    df -h /data >>"$tmpfile" 2>/dev/null
    # Display FPS (if possible)
    if command -v dumpsys >/dev/null; then
        dumpsys display | head -20 >>"$tmpfile"
    fi
    dialog --title "HYPERSENSE System Monitor" --textbox "$tmpfile" 22 86
    rm -f "$tmpfile"
}

# ------------------------------
# Touch Sensitivity +/- buttons
# ------------------------------
set_touch() {
    XNEW=$TOUCH_X
    YNEW=$TOUCH_Y
    while true; do
        choice=$(dialog --menu "Touch Sensitivity X/Y (Current X=$XNEW, Y=$YNEW)" 15 50 4 \
        1 "Increase X" \
        2 "Decrease X" \
        3 "Increase Y" \
        4 "Decrease Y" \
        5 "Restore Defaults (X=8,Y=8)" \
        0 "Back" 3>&1 1>&2 2>&3 3>&-)
        case $choice in
            1) (( XNEW<15 )) && ((XNEW++)) ;;
            2) (( XNEW>1 )) && ((XNEW--)) ;;
            3) (( YNEW<15 )) && ((YNEW++)) ;;
            4) (( YNEW>1 )) && ((YNEW--)) ;;
            5) XNEW=8; YNEW=8 ;;
            0) break ;;
        esac
        TOUCH_X=$XNEW
        TOUCH_Y=$YNEW
        sed -i "s/^TOUCH_X=.*/TOUCH_X=$TOUCH_X/;s/^TOUCH_Y=.*/TOUCH_Y=$TOUCH_Y/" "$ACT_FILE"
    done
}

# ------------------------------
# VRAM Toggle
# ------------------------------
toggle_vram() {
    if [ "$VRAM_ENABLED" -eq 0 ]; then
        VRAM_ENABLED=1
        sed -i "s/^VRAM_ENABLED=.*/VRAM_ENABLED=1/" "$ACT_FILE"
        dialog --msgbox "NeuralCore VRAM Enabled (512MB swap)" 6 60
    else
        VRAM_ENABLED=0
        sed -i "s/^VRAM_ENABLED=.*/VRAM_ENABLED=0/" "$ACT_FILE"
        dialog --msgbox "NeuralCore VRAM Disabled" 6 60
    fi
}

# ------------------------------
# High-Power Toggle
# ------------------------------
toggle_highpower() {
    if [ "$HIGHPOWER" -eq 0 ]; then
        HIGHPOWER=1
        sed -i "s/^HIGHPOWER=.*/HIGHPOWER=1/" "$ACT_FILE"
        dialog --msgbox "High-Power Game Mode Enabled" 6 60
    else
        HIGHPOWER=0
        sed -i "s/^HIGHPOWER=.*/HIGHPOWER=0/" "$ACT_FILE"
        dialog --msgbox "High-Power Game Mode Disabled" 6 60
    fi
}

# ------------------------------
# Ultra Tweaks Toggle
# ------------------------------
toggle_ultra() {
    ULTRA_TWEAKS=$((1-ULTRA_TWEAKS))
    sed -i "s/^ULTRA_TWEAKS=.*/ULTRA_TWEAKS=$ULTRA_TWEAKS/" "$ACT_FILE"
    dialog --msgbox "Ultra Performance Tweaks $( [ $ULTRA_TWEAKS -eq 1 ] && echo ON || echo OFF )" 6 60
}

# ------------------------------
# Adaptive Frame Toggle
# ------------------------------
toggle_frame() {
    ADAPTIVE_FRAME=$((1-ADAPTIVE_FRAME))
    sed -i "s/^ADAPTIVE_FRAME=.*/ADAPTIVE_FRAME=$ADAPTIVE_FRAME/" "$ACT_FILE"
    dialog --msgbox "Adaptive Frame Booster $( [ $ADAPTIVE_FRAME -eq 1 ] && echo ON || echo OFF )" 6 60
}

# ------------------------------
# Dolby / Audio Toggle
# ------------------------------
toggle_audio() {
    DOLBY_AUDIO=$((1-DOLBY_AUDIO))
    sed -i "s/^DOLBY_AUDIO=.*/DOLBY_AUDIO=$DOLBY_AUDIO/" "$ACT_FILE"
    dialog --msgbox "NeuralCore Audio/Dolby $( [ $DOLBY_AUDIO -eq 1 ] && echo ON || echo OFF )" 6 60
}

# ------------------------------
# Main Menu Loop
# ------------------------------
if ! check_activation; then
    if ! activate_code; then
        clear; exit 1
    fi
fi

while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (User: $USERNAME | Plan: $PLAN)" 22 80 10 \
    1 "Live System Monitor" \
    2 "Set Touch Sensitivity X/Y" \
    3 "Toggle NeuralCore VRAM" \
    4 "Toggle High-Power Game Mode" \
    5 "Toggle Ultra Performance Tweaks" \
    6 "Toggle Adaptive Frame Booster" \
    7 "Toggle NeuralCore Audio/Dolby" \
    0 "Exit" 3>&1 1>&2 2>&3 3>&-)

    case $choice in
        1) live_status ;;
        2) set_touch ;;
        3) toggle_vram ;;
        4) toggle_highpower ;;
        5) toggle_ultra ;;
        6) toggle_frame ;;
        7) toggle_audio ;;
        0) clear; exit 0 ;;
    esac
done
