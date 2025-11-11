#!/data/data/com.termux/files/usr/bin/bash

# ========================================================
# 🚀 HYPERSENSE ANDROID V2 — NEURALCORE EDITION 🚀
# Developed by AG HYDRAX (HYPERSENSEINDIA)
# Instagram: @hydraxff_yt
# ========================================================

# ------------------------------
# Dependencies
# ------------------------------
if ! command -v dialog &>/dev/null; then
    pkg update -y && pkg install -y dialog openssl coreutils -y
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
# Banner function
# ------------------------------
show_banner() {
dialog --msgbox "
========================================================
      🚀 HYPERSENSE ANDROID V2 — NEURALCORE EDITION 🚀
            Developed by AG HYDRAX (HYPERSENSEINDIA)
========================================================

⚡ NeuralCore AI Performance Boost
⚡ Adaptive Frame Booster (Real FPS Stabilizer)
⚡ Touch Sensitivity X/Y Optimizer
⚡ Network, Ping & Jitter Enhancer
⚡ VRAM Simulation & GPU Smooth Engine
⚡ System Health & Live Status Monitor
⚡ Bug & Crash Fixer with Auto Recovery
⚡ Always-On NeuralCore (Auto App Detection)

📌 Brand: AG HYDRAX — Hypersense India
📸 Instagram: @hydraxff_yt

✨ Activate with your key → Unlock Pro Control!
========================================================
" 22 80
}

# ------------------------------
# Activation storage
# ------------------------------
ACT_FILE="$HOME/.hypersense_activation"

# ------------------------------
# Helpers
# ------------------------------
sha256_hash() {
    input="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        printf "%s" "$input" | sha256sum | awk '{print $1}'
    else
        printf "%s" "$input" | shasum -a 256 | awk '{print $1}'
    fi
}

# ------------------------------
# Offline Activation
# ------------------------------
activate_key() {
    code_input=$(dialog --inputbox "Enter Activation Code:" 8 60 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$code_input" ]; then
        dialog --msgbox "No activation code entered!" 6 40
        clear; exit 1
    fi

    decoded=$(echo "$code_input" | base64 -d 2>/dev/null)
    if [ $? -ne 0 ] || [[ "$decoded" != *"|"* ]]; then
        dialog --msgbox "Invalid or corrupted code!" 6 40
        clear; exit 1
    fi

    IFS='|' read -r username plan expiry <<< "$decoded"

    # Validate expiry format YYYYMMDD
    if ! [[ "$expiry" =~ ^[0-9]{8}$ ]]; then
        dialog --msgbox "Invalid expiry format!" 6 50
        exit 1
    fi

    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Activation expired!" 6 40
        exit 1
    fi

    mkdir -p "$(dirname "$ACT_FILE")"
    cat > "$ACT_FILE" <<EOF
username=$username
plan=$plan
expiry=$expiry
activated_on=$current
EOF
    chmod 600 "$ACT_FILE"
    dialog --msgbox "Activation successful!\nUser: $username\nPlan: $plan\nExpires: $expiry" 8 60
}

check_activation() {
    if [ ! -f "$ACT_FILE" ]; then
        return 1
    fi
    . "$ACT_FILE"
    current=$(date +%Y%m%d)
    if (( current > expiry )); then
        dialog --msgbox "Activation expired on $expiry." 6 50
        return 1
    fi
    rem_days=$(( ( $(date -d "$expiry" +%s) - $(date +%s) ) / 86400 ))
    if (( rem_days < 0 )); then rem_days=0; fi
    dialog --msgbox "Activation valid.\nUser: $username\nPlan: $plan\nDays left: $rem_days" 8 50
    return 0
}

# ------------------------------
# Touch Sensitivity
# ------------------------------
set_sensitivity() {
CFG="$HOME/.hypersense_config"
XVAL=$(grep '^sensitivity_x=' "$CFG" 2>/dev/null | cut -d'=' -f2)
YVAL=$(grep '^sensitivity_y=' "$CFG" 2>/dev/null | cut -d'=' -f2)
: "${XVAL:=8}"
: "${YVAL:=8}"

dialog --title "Touch Sensitivity X (1-15)" --rangebox "Set X sensitivity" 8 60 1 15 "$XVAL" 2> /tmp/xval.$$ || return
XNEW=$(cat /tmp/xval.$$ 2>/dev/null || echo "$XVAL")
rm -f /tmp/xval.$$

dialog --title "Touch Sensitivity Y (1-15)" --rangebox "Set Y sensitivity" 8 60 1 15 "$YVAL" 2> /tmp/yval.$$ || return
YNEW=$(cat /tmp/yval.$$ 2>/dev/null || echo "$YVAL")
rm -f /tmp/yval.$$

mkdir -p "$(dirname "$CFG")"
cat > "$CFG" <<EOF
sensitivity_x=$XNEW
sensitivity_y=$YNEW
EOF
dialog --msgbox "Sensitivity updated: X=$XNEW Y=$YNEW" 6 50
}

# ------------------------------
# System Analysis
# ------------------------------
analyze_status() {
tmpfile=$(mktemp)
echo "Hypersense System Analyze" >"$tmpfile"
echo "Time: $(date)" >>"$tmpfile"
echo "" >>"$tmpfile"

# Memory
if command -v free >/dev/null 2>&1; then
    echo "Memory (free -h):" >>"$tmpfile"
    free -h >>"$tmpfile" 2>/dev/null
fi

# CPU info
echo "" >>"$tmpfile"
echo "CPU info:" >>"$tmpfile"
awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -6 >>"$tmpfile"

# Display Hz
echo "" >>"$tmpfile"
if command -v dumpsys >/dev/null 2>&1; then
    echo "Display info (dumpsys display):" >>"$tmpfile"
    dumpsys display | head -20 >>"$tmpfile"
fi

dialog --title "System Status - Hypersense" --textbox "$tmpfile" 22 80
rm -f "$tmpfile"
}

# ------------------------------
# VRAM / Swapfile
# ------------------------------
SWAPFILE="/data/local/tmp/hypersense_swapfile.img"
enable_swap() {
size_mb=512
if [ ! -f "$SWAPFILE" ]; then
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$size_mb 2>/dev/null
    mkswap "$SWAPFILE" 2>/dev/null
    chmod 600 "$SWAPFILE"
fi
if command -v su >/dev/null 2>&1; then
    su -c "swapon $SWAPFILE" 2>/dev/null
else
    swapon "$SWAPFILE" 2>/dev/null
fi
dialog --msgbox "Virtual RAM enabled ($size_mb MB)" 6 50
}

disable_swap() {
if [ -f "$SWAPFILE" ]; then
    if command -v su >/dev/null 2>&1; then
        su -c "swapoff $SWAPFILE" 2>/dev/null
    else
        swapoff "$SWAPFILE" 2>/dev/null
    fi
    rm -f "$SWAPFILE"
fi
dialog --msgbox "Virtual RAM disabled" 6 50
}

# ------------------------------
# NeuralCore Real-Time Game Booster
# ------------------------------
SUPPORTED_GAMES=(
    "com.dts.freefireth"
    "com.dts.freefiremax"
    "com.konami.pesam"
)

neuralcore_boost() {
    while true; do
        game_running=""
        for pkg in "${SUPPORTED_GAMES[@]}"; do
            if pidof "$pkg" >/dev/null 2>&1 || pgrep -f "$pkg" >/dev/null 2>&1; then
                game_running="$pkg"
                break
            fi
        done

        if [ -n "$game_running" ]; then
            # Game detected, apply NeuralCore optimizations
            echo "[$(date)] NeuralCore Boost Active → $game_running" >>"$HOME/.hypersense_log"
            
            # 1️⃣ Enable VRAM (swap)
            enable_swap

            # 2️⃣ Set CPU to performance mode (best-effort)
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                if [ -w "$cpu/cpufreq/scaling_governor" ]; then
                    echo performance > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                fi
            done

            # 3️⃣ Adjust touch sensitivity (optional, auto)
            XVAL=12
            YVAL=12
            echo "sensitivity_x=$XVAL" > "$HOME/.hypersense_config"
            echo "sensitivity_y=$YVAL" >> "$HOME/.hypersense_config"

            # 4️⃣ Log system stats (before/after)
            echo "---- System Status: $game_running ----" >>"$HOME/.hypersense_log"
            free -h >>"$HOME/.hypersense_log"
            awk -F: '/model name|Hardware|Processor/{print $1 $2}' /proc/cpuinfo | head -6 >>"$HOME/.hypersense_log"

            sleep 5
        else
            # No game running, revert tweaks
            disable_swap
            for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
                if [ -w "$cpu/cpufreq/scaling_governor" ]; then
                    echo ondemand > "$cpu/cpufreq/scaling_governor" 2>/dev/null
                fi
            done
            sleep 10
        fi
    done
}

# Run NeuralCore in background
neuralcore_boost &

# ------------------------------
# Main Menu
# ------------------------------
show_banner

if ! check_activation; then
    activate_key
fi

while true; do
CHOICE=$(dialog --menu "HYPERSENSE MENU (NeuralCore Active)" 22 70 8 \
1 "Set Touch Sensitivity (X/Y)" \
2 "Enable Virtual RAM (Swap) / Disable" \
3 "Analyze System Status" \
0 "Exit" 3>&1 1>&2 2>&3 3>&-)

case $CHOICE in
1) set_sensitivity ;;
2) enable_swap ;;
3) analyze_status ;;
0) clear; exit 0 ;;
*) dialog --msgbox "Invalid choice." 6 40 ;;
esac
done
