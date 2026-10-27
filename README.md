# Hypersense Android V2 &mdash; NeuralCore

An offline performance console for Android, run from Termux. It watches for a supported game, applies a tuning profile sized to the device, and shows you the before/after numbers rather than asking you to trust a slider.

**No root. No server. No in-game overlay.**

## Features

| | |
| --- | --- |
| **Auto game detection** | Free Fire (`com.dts.freefireth`), Free Fire Max (`com.dts.freefiremax`), PES Mobile (`com.konami.pesam`) |
| **Adaptive frame booster** | Targets the panel's real refresh rate (60 / 90 / 120 Hz) |
| **Touch X/Y control** | Separate horizontal and vertical response |
| **VRAM and swapfile** | Builds a swap file on internal storage to absorb spikes |
| **CPU mode** | Governor hints for sustained load |
| **System analyser** | Memory, CPU, GPU, display Hz and touch rate, before and after |
| **Offline activation** | Time-locked per device, validated locally |
| **Logs** | Every tuning event recorded for later review |

## Run

```bash
pkg update -y
pkg install -y git
git clone https://github.com/hypersenseindia/Hypersense-Android-V2
cd Hypersense-Android-V2
chmod +x hypersense.sh
./hypersense.sh
```

## Files

```
hypersense.sh                    the tool
~/.hypersense_config             saved settings
~/.hypersense_activation         activation state
/data/local/tmp/hypersense_swapfile.img   swap file, when enabled
```

## Notes

- Everything is local. No telemetry, no network calls, no account.
- The swap file is disabled by default; enabling it costs storage and some battery.
- Delete `~/.hypersense_config` and `~/.hypersense_activation` to reset.
---

<p align="center">
  <sub>Built by <b>AG HYDRAXFF</b> &mdash; HYPERSENSEGLOBAL &middot;
  <a href="https://www.instagram.com/hydraxff_yt/">@hydraxff_yt</a></sub>
</p>