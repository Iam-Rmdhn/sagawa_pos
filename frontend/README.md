# Sagawa POS

Flutter-based POS platform structured with a feature-first, layered architecture.

## Folder Structure

```text
lib/
├── app/                    # App shell (MaterialApp, routing)
├── config/                 # Env, routing, and runtime configuration contracts
├── core/                   # Constants, networking, theming, shared widgets
├── data/                   # DTOs, repositories, remote/local data sources
├── domain/                 # Business entities, repository contracts, use cases
├── features/
│   └── onboarding/         # Example feature with presentation/data/domain spaces
├── shared/                 # Cross-feature helpers, extensions, widgets
└── main.dart               # Entry point bootstrapping SagawaPosApp
```

Each top-level directory also contains a short README that documents its responsibilities.

## Key Dependencies

- **Networking & storage:** `dio`, `supabase_flutter`, `shared_preferences`
- **State management:** `bloc`, `flutter_bloc`, `provider`
- **UX helpers:** `google_fonts`, `flutter_screenutil`, `cached_network_image`, `flutter_svg`
- **Utilities:** `flutter_dotenv`, `intl`, `uuid`, `fluttertoast`, `form_field_validator`

Refer to `pubspec.yaml` for the complete list, including tooling such as `flutter_launcher_icons`.

## Development

```bash
flutter pub get
flutter test
```

Use `flutter pub run flutter_launcher_icons` whenever the launcher assets change.
