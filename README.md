# Hisoblagich: mahsulot hisobi uchun mobil ilovalar

**Loyiha turi:** dasturiy ta’minot — ishlab chiqarish yoki savdoda mahsulot miqdori va narx bo‘yicha hisob-kitoblarni yuritishga mo‘ljallangan ko‘pplatformali mijoz ilovalari.

**Asosiy muammo:** ishchilar bo‘yicha kalkulyatsiya, mahsulotlar ro‘yxati, yozuvlar (data) jurnalini yuritish; tarmoq mavjudligida server bilan sinxronlash; tarmoq yo‘qligida mahalliy saqlash.

---

## Annotatsiya

Ushbu repozitoriyda ikki ajralmas Flutter-ilova taklifi jamlangan: **onlayn** (`mobile_app`) — GraphQL orqali server bilan ishlaydi; **oflayn** (`mobile_offline`) — server talab qilmaydi, ma’lumotlar qurilmada mahalliy saqlanadi. Backend uchun **Go** tilida yozilgan `mobile_server` moduli mavjud. Loyiha **GitHub Actions** orqali iOS (imzosiz `.ipa` tuzilmasi) va Windows (yagona yuklab olinadigan SFX `.exe`) artefaktlarini avtomatik yig‘ishni qo‘llab-quvvatlaydi.

**Kalit so‘zlar:** Flutter, GraphQL, Hive, mahalliy saqlash, Excel eksport, CI/CD.

---

## 1. Maqsadlar va funksional talablar

| Bo‘lim | Tavsif |
|--------|--------|
| Kalkulyatsiya | Ishchi tanlanadi, mahsulotlar va miqdorlar kiritiladi, yozuvlar shakllantiriladi |
| Mahsulotlar | Mahsulot nomi va narxi; qo‘shish / yangilash |
| Ishchilar | Foydalanuvchilar ro‘yxati |
| Data | Ishchilar bo‘yicha guruhlangan yozuvlar; Excelga eksport; (oflayn) zaxira va xavfsizlik |

---

## 2. Arxitektura qisqacha

```
┌─────────────────┐     GraphQL      ┌─────────────────┐
│   mobile_app    │ ◄──────────────► │  mobile_server  │
│  (Flutter)      │                  │     (Go)        │
└────────┬────────┘                  └─────────────────┘
         │
         │ tarmoq yo‘q / lokal
         ▼
┌─────────────────┐
│ mobile_offline  │  Hive + mahalliy xotira
│   (Flutter)     │
└─────────────────┘
```

**Oflayn ilova** server va tashqi ma’lumotlar bazasini talab qilmaydi; **onlayn ilova** server bilan ishlash uchun GraphQL mijozidan foydalanadi, zarurat bo‘lsa kutilayotgan yozuvlar mahalliy navbatda saqlanadi.

---

## 3. Repozitoriy tuzilishi

| Katalog | Mazmun |
|---------|--------|
| `mobile_app/` | Onlayn Flutter-ilova (`calculator_app`) |
| `mobile_offline/` | Oflayn Flutter-ilova (`calculator_offline`) |
| `mobile_server/` | GraphQL backend (Go) |
| `.github/workflows/` | iOS va Windows uchun CI konfiguratsiyasi |
| `Makefile` | Tezkor buyruqlar (masalan, `make run`) |

---

## 4. Texnologik stek

| Komponent | Texnologiya |
|-----------|---------------|
| UI | Flutter (Dart SDK ^3.11) |
| Mahalliy saqlash | Hive CE, `flutter_secure_storage`, kriptografiya kutubxonalari |
| Tarmoq (onlayn) | `graphql_flutter` |
| Jadval eksport | `excel` (.xlsx) |
| Fayl tanlash / ulashish | `file_picker`, `share_plus` |
| Backend | Go (`mobile_server`) |

---

## 5. Talablar

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (barqaror kanal tavsiya etiladi)
- Onlayn rejim va server: [Go](https://go.dev/dl/) (1.18+ tavsiya)
- iOS qurilmada ishga tushirish: Xcode / Apple muhiti
- Android: Android Studio yoki `adb` orqali ulangan qurilma

---

## 6. Mahalliy ishga tushirish

### 6.1. Oflayn ilova

```bash
cd mobile_offline
flutter pub get
flutter run
```

### 6.2. Onlayn ilova va server

Server (alohida terminal):

```bash
cd mobile_server
go mod tidy
go run .
```

Ilova:

```bash
cd mobile_app
flutter pub get
flutter run
```

GraphQL endpoint va sozlamalar loyihadagi `mobile_app` konfiguratsiyasiga mos qilinadi (masalan, `lib/graphql/`).

### 6.3. Makefile (ixtiyoriy)

```bash
make get        # paketlarni yangilash
make run        # hozirgi Makefile bo‘yicha (masalan, Chrome)
make run-server # Go server
```

---

## 7. Platformalar va yig‘ish

| Platforma | Buyruq (namuna) |
|-----------|-------------------|
| Android | `flutter build apk --release` |
| iOS | `flutter build ios --release` (imzo — lokal/CI siyosatiga ko‘ra) |
| Windows | `flutter build windows --release` |
| Linux | `flutter build linux --release` |
| Web | `flutter build web` |

Keng ekranlarda ilovada **NavigationRail**; tor ekranda **NavigationBar** ishlatiladi (breakpoint taxminan 720 px).

---

## 8. Uzluksiz integratsiya (GitHub Actions)

Repozitoriyda **mobil oflayn** loyiha uchun quyidagi ish oqimlari mavjud:

- **iOS:** `flutter build ios --release --no-codesign` — Payload tuzilishi `.ipa` sifatida artefakt sifatida saqlanadi (sertifikat talab qilinmaydi; qurilmaga o‘rnatish uchun keyinchalik imzolash talab qilinishi mumkin).
- **Windows:** `flutter build windows` — chiqish `Release` papkasidan 7-Zip SFX yordamida **bitta** `hisoblagich-offline.exe` artefakti sifatida beriladi.

Workflow fayllari: `.github/workflows/build-mobile-offline-ios.yml`, `.github/workflows/build-mobile-offline-windows.yml`.

---

## 9. Ma’lumotlar va maxfiylik

Mahalliy ma’lumotlar Hive va xavfsiz saqlash modullari orqali boshqariladi. Tarmoqdan mustaqil ishlash uchun oflayn ilova tanlanadi. Foydalanuvchi ma’lumotlarining to‘liq saqlanishi va uzatilishi loyiha siyosati va server konfiguratsiyasiga bog‘liq.

---

## 10. Hujjatlashtirish va keyingi qadamlar

- Har bir ilova ostida `README.md` — qisqa yo‘riqnoma.
- Kod uslubi va struktura `lib/` ichida modullar bo‘yicha ajratilgan.

---

## 11. Mualliflik va litsenziya

Loyiha manbasi: repozitoriy egasi va hissadorlar. Litsenziya uchun repozitoriy ildizidagi `LICENSE` faylini (agar mavjud bo‘lsa) tekshiring.

---

*Hujjat oxirgi marta loyiha tuzilishi va CI konfiguratsiyasiga mos ravishda yangilangan.*
