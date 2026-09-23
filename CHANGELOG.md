# Changelog

## [0.0.6] - 2026-09-23

### Security

- Persisted calls (`persistent: true`) are now redacted using `sensitiveHeaders`
  before being written to `shared_preferences`, regardless of the UI redaction
  toggle. Previously, disk storage always contained plaintext headers/cookies.
- Captured request/response bodies are now truncated at 200 KB before being
  stored, bounding per-call memory and persisted-storage usage independent of
  `maxCalls`.

### Fixes

- Fixed a bug where a request retried with a cloned `RequestOptions` (e.g. by
  an app-level retry interceptor) could get silently orphaned from its
  response, leaving its entry stuck showing "loading". Requests are now
  correlated with a stable id instead of `RequestOptions.hashCode`.
- `NetSpyStorage.dispose()` now also disposes its internal `ValueNotifier`.

### Changed

- The `shared_preferences` storage key changed from `dio_spy_calls` to
  `net_spy_calls` to match the package name. Existing persisted calls are
  migrated automatically on first load after upgrading.

## [0.0.5] - 2026-02-16

### Fixes

- Raised Dio lower bound from `>=5.0.0` to `>=5.2.0` (`DioException` was introduced in 5.2.0)

## [0.0.4] - 2026-02-16

### Features

- Added `NetSpyWrapper` widget — an overlay-based alternative to the `navigatorKey` approach for displaying the inspector UI

## [0.0.3] - 2026-02-13

### Docs

- Update Screenshots

## [0.0.2] - 2026-02-13

### Features

- Added JSON visualizer with interactive tree view

## [0.0.1] - 2026-02-12

### Initial Release

A lightweight HTTP inspector for Dio with a clean minimal UI.

#### Features

- Automatic HTTP request/response capture via Dio interceptor
- Shake gesture to open inspector
- Clean UI with request/response details viewer
- Copy as cURL command
- Collapsible JSON tree viewer
- Request timing and response size tracking
- Quick filter by URL, HTTP method and status code
- In-memory circular buffer storage (configurable, default: 1000 calls)

#### Requirements

- Dart SDK: `^3.0.0`
- Flutter: `>=3.10.0`
- Dio: `>=5.2.0 <6.0.0`
