#!/usr/bin/env bash

# Freeze-Frame Visual Screenshot script for Hyprland & Caelestia Shell
#
# Freezes the screen VISUALLY by projecting the exact screen capture into an
# Overlay surface while slurp performs selection. Even if the user drags or
# clicks around, notifications, quick toggles, tooltips, and animations remain
# completely frozen in place.

MODE="${1:-save}"
SAVE_DIR="${HOME}/Pictures/Screenshots"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
TMP_SCREEN="/tmp/screen_freeze.png"
OVERLAY_QML="${SCRIPT_DIR}/freeze-overlay/overlay.qml"

cleanup() {
  if [ -n "${OVERLAY_PID}" ]; then
    kill "${OVERLAY_PID}" 2>/dev/null
    wait "${OVERLAY_PID}" 2>/dev/null
  fi
  rm -f "${TMP_SCREEN}"
}
trap cleanup EXIT

# 1. Capture the exact screen state at this instant
grim "${TMP_SCREEN}"
GRIM_STATUS=$?

if [ ${GRIM_STATUS} -ne 0 ] || [ ! -f "${TMP_SCREEN}" ]; then
  # Fallback directly to grim if initial capture failed
  TMP_SCREEN=""
else
  # 2. Present visual freeze overlay on Layer 3 (Overlay)
  quickshell -p "${OVERLAY_QML}" >/dev/null 2>&1 &
  OVERLAY_PID=$!
  sleep 0.08
fi

# 3. Get smart snapping boxes (windows, monitors, and open Caelestia drawers)
BOXES="$(python3 "${SCRIPT_DIR}/get-windows-boxes.py" 2>/dev/null)"

if [ -n "${BOXES}" ]; then
  GEOM="$(echo "${BOXES}" | slurp -d -b "#00000044" -c "#58a6ffcc" -B "#00000022" -w 2)"
else
  GEOM="$(slurp -d -b "#00000044" -c "#58a6ffcc" -w 2)"
fi

# Exit if selection was cancelled
if [ -z "${GEOM}" ]; then
  exit 0
fi

# 4. Crop selection from the frozen frame
crop_geometry() {
  local target_file="$1"
  if [ -n "${TMP_SCREEN}" ] && [ -f "${TMP_SCREEN}" ]; then
    python3 -c "
from PIL import Image
import sys

geom = '${GEOM}'
pos, size = geom.split(' ')
x, y = map(int, pos.split(','))
w, h = map(int, size.split('x'))

im = Image.open('${TMP_SCREEN}')
cropped = im.crop((x, y, x + w, y + h))
if '${target_file}' == '-':
    cropped.save(sys.stdout.buffer, format='PNG')
else:
    cropped.save('${target_file}', format='PNG')
"
  else
    if [ "${target_file}" = "-" ]; then
      grim -g "${GEOM}" -
    else
      grim -g "${GEOM}" "${target_file}"
    fi
  fi
}

if [ "${MODE}" = "copy" ]; then
  # Clipboard only
  crop_geometry "-" | wl-copy --type image/png
  notify-send -a "Screenshot" "Screenshot Copied" "Captured to clipboard only"
else
  # Save to file AND clipboard
  mkdir -p "${SAVE_DIR}"
  TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
  FILE="${SAVE_DIR}/screenshot_${TIMESTAMP}.png"

  crop_geometry "${FILE}"
  wl-copy --type image/png < "${FILE}"
  notify-send -a "Screenshot" -i "${FILE}" "Screenshot Saved & Copied" "Saved to ${FILE} and copied to clipboard"
fi
