# kernel_app (app-ui)

Flutter app shell for Kernel. Owner: `ui-dev`. Read `docs/guardrails.md` and
`docs/design-tokens.md` first.

## Layout
- `lib/app/providers.dart`: one riverpod provider per `kernel_contracts`
  interface. They are unbound by default and throw until they are overridden
  in `lib/bootstrap.dart` (lead-owned wiring).
- `lib/app/data_providers.dart`: reactive read models over the repositories.
  Every on-screen count comes from these.
- `lib/app/platform_providers.dart`: connectivity (informational), runtime
  permissions (mic, notifications, camera), file sharing, offline voice
  prompts (system TTS, installed voices only), inspection photo storage
  (`<app documents>/inspection_photos/`), the QR scanner view and app version.
- `lib/app/rules.dart`: pure rules (QR payload `kernel:item:<id>`, research
  label rule, live level hints, household review interval, device-log row).
- `lib/app/router.dart` / `routes.dart`: go_router with the onboarding and
  role-gated redirect and the bottom-nav shell.
- `lib/brand/`: mark, logo and listening-rings motif (`kernel_brand.dart`)
  and inline SVG illustrations (`illustrations.dart`).
- `lib/theme/`: tokens (colour, spacing, radii, shadows, motion) and the
  Manrope type scale.
- `lib/l10n/`: `app_en.arb` (source of all user-facing copy) and the
  generated `AppLocalizations`. Use `context.l10n`.
- `lib/features/**`: screens. `lib/widgets/**`: shared components.

## Brand assets
- `assets/brand/*.svg`: mark, logo, mono and reversed variants, generated
  from one geometry. `assets/brand/png/` holds rasterised sources for the
  launcher icon and splash only (not bundled in the app).
- `assets/fonts/`: Manrope variable font (OFL, see `OFL.txt`). No runtime
  font fetching; Indic scripts fall back to the system Noto fonts.
- Regenerate Android resources after changing the PNGs:
  `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

## Localisation
Edit `lib/l10n/app_en.arb` (every key has a description and typed
placeholders), then `flutter gen-l10n`. New languages are added as
`app_<tag>.arb`; the language picker lists `AppLocalizations.supportedLocales`.

## Tests
Test doubles (in-memory repositories, a scripted scan engine with a level
stream, permissions, voice, photos and QR) live only in `test/support/`.

```bash
flutter analyze
flutter test
```
