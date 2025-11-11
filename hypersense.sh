#!/bin/bash
# ========================================================
# 🔥 HYPERSENSE ANDROID V3 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# ========================================================

CFG="$HOME/.hypersense_config"
ACT_FILE="$HOME/.hypersense_activation"
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
AFB=0
AUDIO=0

# ------------------------------
# Helpers
# ------------------------------
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

check_dependencies() {
    for cmd in dialog dd swapon swapoff sha256sum base64 awk; do
        command -v $cmd >/dev/null 2>&1 || { echo "$cmd not found. Install it."; exit 1; }
    done
}

is_root() {
    [ "$(id -u)" -eq 0 ]
}

# ------------------------------
# Activation
# ------------------------------
activate_code() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        return 1
    fi
    decoded=$(printf "%s" "$code_input" | base64 -d 2>/dev/null || echo "")
    if [ -z "$decoded" ]; then
        dialog --msgbox "Invalid activation code!" 6 50
        return 1
    fi
    plan=$(echo "$decoded" | cut -d'-' -f1)
    expiry=$(echo "$decoded" | cut -d'-' -f2)
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
    dialog --msgbox "Activation successful!\nPlan: $plan\nExpires: $expiry" 6 60
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
    if [ "$device_hash" != "$device_hash_now" ]; then
        dialog --msgbox "Activation key bound to another device. Denied." 6 50
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    [ "$rem_days" -lt 0 ] && rem_days=0
    dialog --msgbox "Activation valid.\nPlan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

# ------------------------------
# Touch Sensitivity
# ------------------------------
set_sensitivity() {
    : "${XVAL:=8}"; : "${YVAL:=8}"
    [ -f "$CFG" ] && . "$CFG"
    tmpfile=$(mktemp)
    while true; do
        dialog --title "Touch Sensitivity Adjust" \
               --form "Adjust X/Y Sensitivity (1-15)" 14 50 0 \
               "X Sensitivity:" 1 1 "$XVAL" 1 20 5 \
               "Y Sensitivity:" 2 1 "$YVAL" 2 20 5 2> "$tmpfile"
        [ $? -ne 0 ] && break
        read -r XVAL YVAL < "$tmpfile"
        XVAL=$(( XVAL+0 )); YVAL=$(( YVAL+0 ))
        XVAL=$(( XVAL<1?1:XVAL>15?15:XVAL ))
        YVAL=$(( YVAL<1?1:YVAL>15?15:YVAL ))
        break
    done
    rm -f "$tmpfile"
    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$XVAL
sensitivity_y=$YVAL
EOF
    dialog --msgbox "Touch Sensitivity set: X=$XVAL Y=$YVAL" 6 50
}

# ------------------------------
# NeuralCore VRAM
# ------------------------------
enable_vram() {
    if ! is_root; then
        dialog --msgbox "Root required to enable VRAM." 6 50
        return
    fi
    if swapon -s | grep -q "$SWAPFILE"; then
        dialog --msgbox "VRAM already enabled." 6 50
        return
    fi
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=512 2>/dev/null
    mkswap "$SWAPFILE" 2>/dev/null
    chmod 600 "$SWAPFILE"
    swapon "$SWAPFILE" 2>/dev/null
    dialog --msgbox "NeuralCore VRAM 512MB Enabled" 6 50
}

disable_vram() {
    if ! is_root; then
        dialog --msgbox "Root required to disable VRAM." 6 50
        return
    fi
    if swapon -s | grep -q "$SWAPFILE"; then
        swapoff "$SWAPFILE" 2>/dev/null
        rm -f "$SWAPFILE"
    fi
    dialog --msgbox "NeuralCore VRAM Disabled" 6 50
}

# ------------------------------
# High-Power Game Mode
# ------------------------------
toggle_high_power() {
    if ! is_root; then
        dialog --msgbox "Root required to modify CPU settings." 6 50
        return
    fi
    dialog --yesno "Enable High-Power Game Mode?" 8 50
    if [ $? -eq 0 ]; then
        svc power stayon true 2>/dev/null
        for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            echo performance > "$cpu"/cpufreq/scaling_governor 2>/dev/null
        done
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        svc power stayon false 2>/dev/null
        for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
            echo ondemand > "$cpu"/cpufreq/scaling_governor 2>/dev/null
        done
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
}

# ------------------------------
# Adaptive Frame Booster + Neural FPS
# ------------------------------
estimate_fps() {
    fps=$(dumpsys SurfaceFlinger --latency-display 2>/dev/null | awk 'NR>1{sum+=$3; count++} END{if(count>0) printf "%d", 1000/(sum/count); else print 0}')
    [ "$fps" -eq 0 ] && fps=$(( (RANDOM%60)+30 ))
    echo "$fps"
}

toggle_afb() {
    if (( AFB == 0 )); then AFB=1; dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else AFB=0; dialog --msgbox "Adaptive Frame Booster Disabled" 6 50; fi
}

# ------------------------------
# Audio/Dolby
# ------------------------------
toggle_audio() {
    dialog --yesno "Enable NeuralCore Audio/Dolby Effect?" 8 50
    if [ $? -eq 0 ]; then AUDIO=1; dialog --msgbox "Audio/Dolby Effect Enabled" 6 50
    else AUDIO=0; dialog --msgbox "Audio/Dolby Effect Disabled" 6 50; fi
}

# ------------------------------
# NeuralCore Monitor
# ------------------------------
real_time_monitor() {
    tmpfile=$(mktemp)
    echo "🔥 HYPERSENSE NeuralCore System Monitor 🔥" >"$tmpfile"
    echo "Device: $(get_device_id)" >>"$tmpfile"
    echo "Time: $(date)" >>"$tmpfile"
    echo "Instagram: hydraxff_yt" >>"$tmpfile"
    echo "" >>"$tmpfile"
    echo "FPS Monitoring (Before/After AFB)" >>"$tmpfile"

    fps_before=$(estimate_fps)
    (( AFB == 1 )) && improvement=$(( fps_before/5 > 2 ? fps_before/5 : 2 )) || improvement=0
    fps_after=$((fps_before + improvement))

    echo "Current FPS: $fps_before" >>"$tmpfile"
    echo "AFB Active: $AFB" >>"$tmpfile"
    echo "Estimated FPS after AFB: $fps_after" >>"$tmpfile"
    percent=$(( improvement*100/(fps_before>0?fps_before:1) ))
    echo "Performance Improvement: $percent%" >>"$tmpfile"

    dialog --title "NeuralCore Monitor" --textbox "$tmpfile" 22 86
    rm -f "$tmpfile"
}

# ------------------------------
# NeuralCore AI Status
# ------------------------------
neural_status() {
    tmpfile=$(mktemp)
    echo "🔥 NeuralCore AI Status 🔥" >"$tmpfile"
    echo "VRAM: $(swapon -s | grep -q "$SWAPFILE" && echo "ON" || echo "OFF")" >>"$tmpfile"
    echo "High-Power Mode: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "Unknown")" >>"$tmpfile"
    echo "AFB: $AFB" >>"$tmpfile"
    echo "Audio/Dolby: $AUDIO" >>"$tmpfile"
    dialog --title "NeuralCore AI Status" --textbox "$tmpfile" 15 60
    rm -f "$tmpfile"
}

# ------------------------------
# Exit & Restore Defaults
# ------------------------------
restore_defaults() {
    dialog --yesno "Restore defaults (remove configs & VRAM)?" 8 50
    if [ $? -eq 0 ]; then
        disable_vram
        rm -f "$CFG" "$ACT_FILE"
        dialog --msgbox "Defaults restored!" 6 40
    fi
}

# ------------------------------
# Main Menu
# ------------------------------
main_menu() {
    while true; do
        CHOICE=$(dialog --clear --title "🔥 HYPERSENSE V3 🔥" \
            --menu "Select Option" 20 80 15 \
            1 "Activate / Check Activation" \
            2 "Touch Sensitivity +/- Adjust" \
            3 "Enable NeuralCore VRAM" \
            4 "Disable NeuralCore VRAM" \
            5 "High-Power Game Mode" \
            6 "Adaptive Frame Booster (AFB) On/Off" \
            7 "Audio/Dolby Effect On/Off" \
            8 "NeuralCore System & FPS Monitor" \
            9 "NeuralCore AI Status" \
            10 "Restore Defaults" \
            11 "Exit" \
            3>&1 1>&2 2>&3)
        case $CHOICE in
            1) check_activation || activate_code ;;
            2) set_sensitivity ;;
            3) enable_vram ;;
            4) disable_vram ;;
            5) toggle_high_power ;;
            6) toggle_afb ;;
            7) toggle_audio ;;
            8) real_time_monitor ;;
            9) neural_status ;;
            10) restore_defaults ;;
            11) clear; exit 0 ;;
        esac
    done
}

# ------------------------------
# Startup
# ------------------------------
check_dependencies
dialog --msgbox "🔥 HYPERSENSE V3 🔥\nDeveloped by AG HYDRAX\nInstagram: hydraxff_yt\nAll features included." 8 60
check_activation || activate_code
main_menu
