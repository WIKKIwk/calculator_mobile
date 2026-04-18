# calculator_app — Hisoblagich (onlayn)

**Tavsif:** mahsulot hisobi uchun Flutter-ilova; **GraphQL** orqali backend (`mobile_server`) bilan ishlaydi. Tarmoq uzilganda ayrim operatsiyalar mahalliy navbat orqali keyinga qoldirilishi mumkin.

**Asosiy repozitoriy:** [README.md](../README.md) — loyiha annotatsiyasi, arxitektura, CI/CD va ishga tushirish.

## Tezkor boshlash

```bash
flutter pub get
flutter run
```

Backend (alohida jarayon):

```bash
cd ../mobile_server && go run .
```

GraphQL URL va boshqa sozlamalar `lib/graphql/` va loyiha konfiguratsiyasida belgilanadi.

## Platformalar

Android, iOS, Web va boshqalar — Flutter qo‘llab-quvvatlash doirasida.
