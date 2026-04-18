.PHONY: run run-server clean get

# Mobil ilovani ishga tushiradi (Chrome brauzerida)
run:
	cd mobile_app && flutter pub get && flutter run -d chrome

# Backend serverni ishga tushiradi
run-server:
	cd mobile_server && go run main.go

# Barcha paketlar va kutubxonalarni yuklab oladi
get:
	cd mobile_app && flutter pub get
	cd mobile_server && go mod tidy

# Keshlarni tozalaydi
clean:
	cd mobile_app && flutter clean
