# kernel_app (app-ui)

Flutter app shell for Kernel. Owner: `ui-dev`. Read `docs/guardrails.md` and
`docs/design-tokens.md` first.

## Layout
- `lib/app/providers.dart`: one riverpod provider per `kernel_contracts`
  interface. They are unbound by default and throw until they are overridden.
- `lib/bootstrap.dart`: `bootstrapOverrides()` is where the lead binds
  `NativeScanEngine` and `DataOperations`.
- `lib/app/data_providers.dart`: reactive read models (stream/future
  providers) over the repositories. Every on-screen count comes from these.
- `lib/app/platform_providers.dart`: connectivity (informational), runtime
  permissions, report sharing, and scan haptics, each behind a small interface.
- `lib/app/router.dart`: go_router with the role-gated redirect and the
  bottom-nav shell.
- `lib/features/**`: screens. `lib/widgets/**`: shared components.
  `lib/theme/**`: design tokens and the Material 3 theme.

## Tests
Test doubles (in-memory repositories, a scripted scan engine and permissions)
live only in `test/support/`.

```bash
flutter analyze
flutter test
```
