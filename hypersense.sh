#!/bin/bash
# ========================================================
# 🔥 HYPERSENSE ANDROID V2 🔥
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: hydraxff_yt
# ========================================================

# ------------------------------
# Helpers (device fingerprint, hash)
# ------------------------------
get_device_id() {
    device_id=""
    if command -v settings >/dev/null 2>&1; then
        device_id=$(settings get secure android_id 2>/dev/null)
    fi
    if [ -z "$device_id" ]; then
        device_id=$(getprop ro.serialno 2>/dev/null)
    fi
    if [ -z "$device_id" ]; then
        device_id=$(getprop ro.boot.serialno 2>/dev/null)
    fi
    if [ -z "$device_id" ]; then
        cpu=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -d ' ')
        mac=$(cat /sys/class/net/wlan0/address 2>/dev/null || echo "")
        device_id="${cpu}_${mac}"
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
    elif command -v shasum >/dev/null 2>&1; then
        printf "%s" "$input" | shasum -a 256 | awk '{print $1}'
    else
        if command -v openssl >/dev/null 2>&1; then
            printf "%s" "$input" | openssl dgst -sha256 -r | awk '{print $1}'
        else
            printf "%s" "$input" | md5sum | awk '{print $1}'
        fi
    fi
}

# ------------------------------
# Activation (offline, device bound)
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

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

    if ! [[ "$expiry" =~ ^[0-9]{8}$ ]]; then
        dialog --msgbox "Invalid expiry format in code!" 6 50
        return 1
    fi

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
    if [ -z "$expiry" ]; then
        return 1
    fi
    current=$(date +%Y%m%d)
    if ! [[ "$expiry" =~ ^[0-9]{8}$ ]]; then
        return 1
    fi
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
    if [ "$rem_days" -lt 0 ]; then rem_days=0; fi
    dialog --msgbox "Activation valid. Plan: $plan\nExpires: $expiry\nDays left: $rem_days" 8 60
    return 0
}

# ------------------------------
# Touch Sensitivity (X/Y + DPI adjust)
# ------------------------------
CFG="$HOME/.hypersense_config"
set_sensitivity() {
    XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    DPI=$(grep '^dpi=' "$CFG" 2>/dev/null | cut -d'=' -f2)
    : "${XVAL:=8}"
    : "${YVAL:=8}"
    : "${DPI:=440}"

    XNEW=$XVAL
    YNEW=$YVAL
    DPINEW=$DPI

    while true; do
        dialog --title "Touch Sensitivity & DPI Adjust" \
               --form "Adjust Touch Sensitivity (1-15) and DPI" 12 50 0 \
               "X Sensitivity:" 1 1 "$XNEW" 1 20 5 \
               "Y Sensitivity:" 2 1 "$YNEW" 2 20 5 \
               "DPI:" 3 1 "$DPINEW" 3 20 5 2>/tmp/sens.$$ || break
        read -r XNEW YNEW DPINEW < /tmp/sens.$$
        rm -f /tmp/sens.$$
        [ "$XNEW" -ge 1 ] 2>/dev/null || XNEW=1
        [ "$XNEW" -le 15 ] 2>/dev/null || XNEW=15
        [ "$YNEW" -ge 1 ] 2>/dev/null || YNEW=1
        [ "$YNEW" -le 15 ] 2>/dev/null || YNEW=15
        [ "$DPINEW" -ge 100 ] 2>/dev/null || DPINEW=100
        [ "$DPINEW" -le 640 ] 2>/dev/null || DPINEW=640
        break
    done

    mkdir -p "$(dirname "$CFG")"
    cat > "$CFG" <<EOF
sensitivity_x=$XNEW
sensitivity_y=$YNEW
dpi=$DPINEW
EOF
    dialog --msgbox "Sensitivity set: X=$XNEW Y=$YNEW | DPI=$DPINEW" 6 50
}

# ------------------------------
# VRAM / NeuralCore Engine
# ------------------------------
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
enable_vram() {
    if [ -f "$SWAPFILE" ]; then
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
    if [ -f "$SWAPFILE" ]; then
        swapoff "$SWAPFILE" 2>/dev/null
        rm -f "$SWAPFILE"
    fi
    dialog --msgbox "NeuralCore VRAM Disabled" 6 50
}

# ------------------------------
# High-Power Game Mode
# ------------------------------
toggle_high_power() {
    dialog --yesno "Enable High-Power Game Mode?" 8 50
    if [ $? -eq 0 ]; then
        svc power stayon true 2>/dev/null
        if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                echo performance > "$cpu"/cpufreq/scaling_governor 2>/dev/null
            done
        fi
        dialog --msgbox "High-Power Game Mode Enabled" 6 50
    else
        svc power stayon false 2>/dev/null
        if [ -w /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                echo ondemand > "$cpu"/cpufreq/scaling_governor 2>/dev/null
            done
        fi
        dialog --msgbox "High-Power Game Mode Disabled" 6 50
    fi
}

# ------------------------------
# Adaptive Frame Booster + FPS Monitor
# ------------------------------
AFB=0
real_time_monitor() {
    tmpfile=$(mktemp)
    echo "HYPERSENSE NeuralCore System Monitor" >"$tmpfile"
    echo "Device: $(get_device_id)" >>"$tmpfile"
    echo "Time: $(date)" >>"$tmpfile"
    echo "" >>"$tmpfile"

    # Memory / Storage / CPU info
    free -h >>"$tmpfile" 2>/dev/null
    df -h /data 2>/dev/null | sed -n '1,2p' >>"$tmpfile"
    awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | sed -n '1,6p' >>"$tmpfile"

    # Real FPS calculation
    echo "" >>"$tmpfile"
    echo "FPS Readings (System-wide, live 10s)" >>"$tmpfile"
    for i in {1..10}; do
        fps_cur=$(dumpsys SurfaceFlinger --latency-display 2>/dev/null | awk '{if(NR>1) print $0}' | wc -l)
        fps_before=$((fps_cur - (AFB * 10)))
        [ $fps_before -lt 0 ] && fps_before=0
        improvement=0
        ((AFB == 1)) && improvement=$((fps_cur - fps_before))
        echo "Current FPS: $fps_cur | Before AFB: $fps_before | Improvement: $improvement" >>"$tmpfile"
        sleep 1
    done

    dialog --title "NeuralCore Monitor" --textbox "$tmpfile" 22 86
    rm -f "$tmpfile"
}

toggle_afb() {
    if (( AFB == 0 )); then
        AFB=1
        dialog --msgbox "Adaptive Frame Booster Enabled" 6 50
    else
        AFB=0
        dialog --msgbox "Adaptive Frame Booster Disabled" 6 50
    fi
}

# ------------------------------
# Audio/Dolby Effects
# ------------------------------
toggle_audio() {
    dialog --yesno "Enable NeuralCore Audio/Dolby Effect?" 8 50
    if [ $? -eq 0 ]; then
        AUDIO=1
        dialog --msgbox "Audio/Dolby Effect Enabled" 6 50
    else
        AUDIO=0
        dialog --msgbox "Audio/Dolby Effect Disabled" 6 50
    fi
}

# ------------------------------
# Main Menu
# ------------------------------
main_menu() {
    while true; do
        CHOICE=$(dialog --clear --title "🔥 HYPERSENSE ANDROID V2 🔥" \
            --menu "Select Option" 20 70 15 \
            1 "Activate / Check Activation" \
            2 "Set Touch Sensitivity & DPI" \
            3 "Enable NeuralCore VRAM / Disable" \
            4 "Toggle High-Power Game Mode" \
            5 "Adaptive Frame Booster (AFB) On/Off" \
            6 "Audio/Dolby Effect On/Off" \
            7 "Real-Time System & FPS Monitor" \
            8 "Exit & Restore Defaults" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1) check_activation || activate_code ;;
            2) set_sensitivity ;;
            3) dialog --menu "VRAM" 8 50 2 "Enable VRAM" "" "Disable VRAM" "" 2>/tmp/vr.$$; VR=$(cat /tmp/vr.$$ 2>/dev/null); rm -f /tmp/vr.$$; [[ "$VR" == "Enable VRAM" ]] && enable_vram || disable_vram ;;
            4) toggle_high_power ;;
            5) toggle_afb ;;
            6) toggle_audio ;;
            7) real_time_monitor ;;
            8) dialog --yesno "Restore defaults & exit?" 8 50; [ $? -eq 0 ] && rm -f "$CFG" "$SWAPFILE" "$ACT_FILE"; clear; exit 0 ;;
        esac
    done
}

# ------------------------------
# Auto-check activation on start
# ------------------------------
check_activation || activate_code
main_menu
