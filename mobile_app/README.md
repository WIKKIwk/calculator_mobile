# calculator_app — Hisoblagich (online)

**Description:** Flutter client for product accounting; talks to the backend (`mobile_server`) over **GraphQL**. When offline, some operations may be deferred via a local queue.

**Main repository:** [README.md](../README.md) — abstract, architecture, CI/CD, and run instructions.

## Quick start

```bash
flutter pub get
flutter run
```

Backend (separate process):

```bash
cd ../mobile_server && go run .
```

Set the GraphQL URL and related options under `lib/graphql/` and project configuration.

## Platforms

Android, iOS, Web, and others supported by Flutter for this project.
