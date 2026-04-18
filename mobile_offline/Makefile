.PHONY: run run-per get clean devices open

# make run        — Android yoki minimal emulyator (oynasiz -no-window, audio yo'q).
#                   AVD yo'q bo'lsa birinchi emulyator SDK orqali yengil parametrlar bilan.
#                   Standart RAM: 4096 MB. O'zgartirish: EMULATOR_RAM=2048 make run
# make run-per    — Chrome (bo'lsa) yoki Linux + DevicePreview.
#
# make run DEVICE=emulator-5554  — aniq ID

DEVICE ?=

run:
	flutter pub get
	@export DEVICE_PREVIEW=false; \
	if [ -n "$(strip $(DEVICE))" ]; then export DEVICE="$(DEVICE)"; fi; \
	bash tool/run_android.sh

run-per:
	flutter pub get
	@P=$$(flutter devices --machine | python3 -c "import json,sys;d=json.load(sys.stdin);\
ids=[x['id'] for x in d if x.get('isSupported')];\
print('chrome' if 'chrome' in ids else ('linux' if 'linux' in ids else (ids[0] if ids else '')))"); \
	if [ -z "$$P" ]; then echo "Hech qanday qurilma topilmadi."; exit 1; fi; \
	echo "DevicePreview rejimi: $$P"; \
	flutter run -d "$$P" --dart-define=DEVICE_PREVIEW=true

get:
	flutter pub get

clean:
	flutter clean

devices:
	flutter devices
	@echo ""
	@echo "Mavjud emulyatorlar:"
	@flutter emulators || true

open:
	studio .
