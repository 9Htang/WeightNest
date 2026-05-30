/// App version — single source of truth.
/// Set via `--dart-define=APP_VERSION=x.y.z` at build time;
/// falls back to pubspec version.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.7.19');
