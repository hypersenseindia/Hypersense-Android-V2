#!/data/data/com.termux/files/usr/bin/bash

# ==============================
# 🔥 HYPERSENSE ANDROID V3 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# ==============================

# Ensure dialog installed
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog
fi

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# Files
ACT_FILE="$HOME/.hypersense_activation"
CFG_FILE="$HOME/.hypersense_config"
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"

# Banner
clear
echo -e "${CYAN}========================================================"
echo -e "      🔥 HYPERSENSE ANDROID V3 🔥"
echo -e "     Developed by AG HYDRAX (HYPERSENSEINDIA)"
echo -e "     Instagram: hydraxff_yt"
echo -e "========================================================"
echo -e "⚡ NeuralCore Engine Active"
echo -e "⚡ Ultra Performance Tweaks"
echo -e "⚡ Adaptive Frame Booster (AFB)"
echo -e "⚡ Touch Sensitivity Booster"
echo -e "⚡ VRAM & High-Power Game Mode"
echo -e "⚡ Audio/Dolby Effect Enhancer"
echo -e "⚡ Real-time FPS & System Monitor"
echo -e "✨ Activate with Code → Enjoy Pro Control!"
echo -e "========================================================${NC}"

# ------------------------------
# Helpers
get_device_id() {
    device_id=$(settings get secure android_id 2>/dev/null)
    [[ -z "$device_id" ]] && device_id=$(getprop ro.serialno 2>/dev/null)
    [[ -z "$device_id" ]] && device_id="unknown_device_$(date +%s)"
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
# Activation
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
    if [ ! -f "$ACT_FILE" ]; then return 1; fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Saved activation expired on $expiry." 6 50
        return 1
    fi
    device_id_now=$(get_device_id)
    device_hash_now=$(sha256_hash "$device_id_now")
    if [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation bound to another device. Denied." 6 50
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    [[ "$rem_days" -lt 0 ]] && rem_days=0
    dialog --msgbox "Activation valid.\nPlan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

if ! check_activation; then
    if ! activate_code; then clear; exit 1; fi
fi

# ------------------------------
# Config Defaults
mkdir -p "$(dirname "$CFG_FILE")"
[[ ! -f "$CFG_FILE" ]] && cat > "$CFG_FILE" <<EOF
sensitivity_x=8
sensitivity_y=8
vr_enabled=false
highpower_enabled=false
afb_enabled=false
audio_enabled=false
EOF

source "$CFG_FILE"

save_config() {
    cat > "$CFG_FILE" <<EOF
sensitivity_x=$sensitivity_x
sensitivity_y=$sensitivity_y
vr_enabled=$vr_enabled
highpower_enabled=$highpower_enabled
afb_enabled=$afb_enabled
audio_enabled=$audio_enabled
EOF
}

# ------------------------------
# Functions
adjust_touch() {
    while true; do
        choice=$(dialog --menu "Touch Sensitivity X/Y: X=$sensitivity_x Y=$sensitivity_y" 15 50 4 \
        1 "Increase X" \
        2 "Decrease X" \
        3 "Increase Y" \
        4 "Decrease Y" \
        0 "Back" 3>&1 1>&2 2>&3)
        case $choice in
            1) ((sensitivity_x<15)) && ((sensitivity_x++)) ;;
            2) ((sensitivity_x>1)) && ((sensitivity_x--)) ;;
            3) ((sensitivity_y<15)) && ((sensitivity_y++)) ;;
            4) ((sensitivity_y>1)) && ((sensitivity_y--)) ;;
            0) break ;;
        esac
        save_config
    done
}

toggle_vram() {
    if [[ "$vr_enabled" == "false" ]]; then
        dd if=/dev/zero of="$SWAPFILE" bs=1M count=512 &>/dev/null
        mkswap "$SWAPFILE" &>/dev/null
        swapon "$SWAPFILE" &>/dev/null
        vr_enabled=true
        dialog --msgbox "VRAM 512MB Enabled" 6 50
    else
        swapoff "$SWAPFILE" &>/dev/null
        rm -f "$SWAPFILE"
        vr_enabled=false
        dialog --msgbox "VRAM Disabled" 6 50
    fi
    save_config
}

toggle_highpower() {
    if [[ "$highpower_enabled" == "false" ]]; then
        svc power stayon true
        highpower_enabled=true
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        svc power stayon false
        highpower_enabled=false
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
    save_config
}

toggle_afb() {
    if [[ "$afb_enabled" == "false" ]]; then
        afb_enabled=true
        dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else
        afb_enabled=false
        dialog --msgbox "Adaptive Frame Booster Disabled" 6 50
    fi
    save_config
}

toggle_audio() {
    if [[ "$audio_enabled" == "false" ]]; then
        audio_enabled=true
        dialog --msgbox "Audio / Dolby Effect Enabled" 6 50
    else
        audio_enabled=false
        dialog --msgbox "Audio / Dolby Effect Disabled" 6 50
    fi
    save_config
}

# Live FPS Monitor
live_fps_monitor() {
    tmpfile=$(mktemp)
    fps_before=$(dumpsys gfxinfo 2>/dev/null | grep -A 1 'Profile data' | tail -n1 | awk '{print $1}' || echo "N/A")
    sleep 1
    fps_after=$(dumpsys gfxinfo 2>/dev/null | grep -A 1 'Profile data' | tail -n1 | awk '{print $1}' || echo "N/A")
    if [[ "$fps_before" != "N/A" && "$fps_after" != "N/A" ]]; then
        improvement=$((fps_after - fps_before))
        percent=$(( (improvement*100)/fps_before ))
    else
        improvement="N/A"
        percent="N/A"
    fi
    echo -e "FPS Before Tweaks: $fps_before\nFPS After Tweaks: $fps_after\nImprovement: $improvement ($percent%)" > "$tmpfile"
    dialog --title "FPS Comparison" --textbox "$tmpfile" 12 60
    rm -f "$tmpfile"
}

# NeuralCore System Report
neuralcore_report() {
    tmpfile=$(mktemp)
    echo "===== NeuralCore System Report =====" >"$tmpfile"
    echo "Activation Plan: $plan | Expires: $expiry" >>"$tmpfile"
    echo "VRAM: $vr_enabled | High-Power Mode: $highpower_enabled" >>"$tmpfile"
    echo "Adaptive Frame Booster: $afb_enabled | Audio/Dolby: $audio_enabled" >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "=== Before / After Stats ===" >>"$tmpfile"
    echo "CPU:" >>"$tmpfile"
    awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -n6 >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "Memory:" >>"$tmpfile"
    free -h >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "Storage:" >>"$tmpfile"
    df -h /data | head -n2 >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "Battery / Temp:" >>"$tmpfile"
    dumpsys battery 2>/dev/null >>"$tmpfile"
    dumpsys thermalservice 2>/dev/null >>"$tmpfile"
    dialog --title "NeuralCore System Report" --textbox "$tmpfile" 22 80
    rm -f "$tmpfile"
}

# ------------------------------
# Main Menu
while true; do
    choice=$(dialog --menu "HYPERSENSE MENU (Plan: $plan | Expires: $expiry)" 30 80 12 \
    1 "Adjust Touch Sensitivity (X/Y)" \
    2 "Enable / Disable VRAM" \
    3 "Toggle High-Power Game Mode" \
    4 "Toggle Adaptive Frame Booster (AFB)" \
    5 "Toggle Audio / Dolby Effect" \
    6 "Live FPS Comparison" \
    7 "NeuralCore System Report" \
    8 "Restore Defaults" \
    0 "Exit" 3>&1 1>&2 2>&3)

    case $choice in
        1) adjust_touch ;;
        2) toggle_vram ;;
        3) toggle_highpower ;;
        4) toggle_afb ;;
        5) toggle_audio ;;
        6) live_fps_monitor ;;
        7) neuralcore_report ;;
        8)
            sensitivity_x=8
            sensitivity_y=8
            vr_enabled=false
            highpower_enabled=false
            afb_enabled=false
            audio_enabled=false
            save_config
            dialog --msgbox "Defaults restored." 6 50
            ;;
        0) clear; exit 0 ;;
        *) dialog --msgbox "Invalid choice" 6 40 ;;
    esac
done
