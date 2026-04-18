#!/usr/bin/env bash
# make run — Android qurilma yoki minimal (headless) emulyator.
#
# Emulyator oynasi va audio yo'q (-no-window); RAM standart 4096 MB — adb + ilova uchun.
# Boshqa RAM: EMULATOR_RAM=2048 make run
set -euo pipefail

export DEVICE_PREVIEW="${DEVICE_PREVIEW:-false}"
EMULATOR_RAM="${EMULATOR_RAM:-4096}"

_pick_android() {
  flutter devices --machine 2>/dev/null | python3 -c "import json,sys
d=json.load(sys.stdin)
a=[x['id'] for x in d if x.get('isSupported') and 'android' in str(x.get('targetPlatform','')).lower()]
print(a[0] if a else '')" || true
}

_first_emulator_id() {
  flutter emulators 2>/dev/null | python3 -c "import sys
out=sys.stdin.read()
for line in out.splitlines():
    s=line.strip()
    if '•' not in s:
        continue
    left=s.split('•')[0].strip()
    if left=='Id' or not left:
        continue
    print(left)
    break" || true
}

_emu_bin() {
  if [[ -n "${ANDROID_HOME:-}" && -x "${ANDROID_HOME}/emulator/emulator" ]]; then
    echo "${ANDROID_HOME}/emulator/emulator"
  elif [[ -n "${ANDROID_SDK_ROOT:-}" && -x "${ANDROID_SDK_ROOT}/emulator/emulator" ]]; then
    echo "${ANDROID_SDK_ROOT}/emulator/emulator"
  elif command -v emulator >/dev/null 2>&1; then
    command -v emulator
  else
    return 1
  fi
}

_avd_exists() {
  local want="$1" bin avd
  bin="$(_emu_bin)" || return 1
  while IFS= read -r avd; do
    [[ "$avd" == "$want" ]] && return 0
  done < <("$bin" -list-avds 2>/dev/null || true)
  return 1
}

_launch_minimal_emulator() {
  local avd="$1"
  local bin logf
  logf="${TMPDIR:-/tmp}/flutter_minimal_emu_${avd}.log"
  if bin="$(_emu_bin)" && _avd_exists "$avd"; then
    echo "Minimal emulyator (oynasiz, audio yo'q, RAM=${EMULATOR_RAM}MB): $avd"
    echo "  log: $logf"
    nohup "$bin" -avd "$avd" \
      -no-window \
      -no-audio \
      -no-boot-anim \
      -gpu swiftshader_indirect \
      -memory "$EMULATOR_RAM" \
      -cores 1 \
      >>"$logf" 2>&1 &
    return 0
  fi
  echo "SDK emulator topilmadi yoki AVD nomi mos kelmaydi — flutter emulators --launch"
  flutter emulators --launch "$avd" &
  return 0
}

D=""
if [[ -n "${DEVICE:-}" ]]; then
  D="$DEVICE"
  echo "Android (DEVICE): $D"
else
  D="$(_pick_android)"
fi

if [[ -n "$D" ]]; then
  exec flutter run -d "$D" --dart-define="DEVICE_PREVIEW=${DEVICE_PREVIEW}"
fi

EMU="$(_first_emulator_id)"
if [[ -z "$EMU" ]]; then
  echo ""
  echo "Android telefon/emulyator yo'q va AVD ham topilmadi."
  echo "  Android Studio > Device Manager — Virtual Device yarating."
  echo "  Yoki: make run-per"
  exit 1
fi

echo "Telefon topilmadi — minimal emulyator ishga tushirilmoqda: $EMU"
_launch_minimal_emulator "$EMU"
sleep 4

for i in $(seq 1 90); do
  D="$(_pick_android)"
  if [[ -n "$D" ]]; then
    echo "Android tayyor: $D"
    exec flutter run -d "$D" --dart-define="DEVICE_PREVIEW=${DEVICE_PREVIEW}"
  fi
  if (( i % 5 == 0 )); then
    printf '\r  Kutilmoqda... %2d/90' "$i"
  fi
  sleep 2
done
echo ""
echo "Emulyator uzoq vaqtda adb ga chiqmadi. Log: ${TMPDIR:-/tmp}/flutter_minimal_emu_${EMU}.log"
exit 1
