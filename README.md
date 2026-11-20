<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/icon-dark.png">
    <img src="docs/assets/icon-light.png" width="128" height="128" alt="Dužy app icon">
  </picture>
</p>

<h1 align="center">Dužy</h1>

<p align="center">
  A minimalist offline strength-training tracker for iPhone.<br>
  No accounts, no server, no subscriptions — just your program, your sets and your progress.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26%2B-111111?logo=apple&logoColor=white" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/UI-SwiftUI-1F5FBF" alt="SwiftUI">
  <img src="https://img.shields.io/badge/storage-SQLite%20%2F%20GRDB-1E8A4C" alt="SQLite / GRDB">
  <a href="LICENSE.md"><img src="https://img.shields.io/badge/license-PolyForm%20Noncommercial-F2C200" alt="License: PolyForm Noncommercial 1.0.0"></a>
</p>

---

## Why

*Dužy* is Belarusian (Łacinka) for «дужы» — strong; in English it sounds like *doozy*.

Most workout apps grow into social feeds, calorie counters and subscription funnels. Dužy does three things and tries to do them well in a gym: hold your training program, record sets fast with one hand between sets, and show how you are progressing. Everything else stays out.

## Features

- **Programs** — program → days → exercises, with target sets, a rep range and rest per exercise.
- **Exercise library and "My gym"** — barbells, dumbbells, plate-loaded and selectorized machines with their own bar weight and weight step; exercises and equipment are archived, never deleted, so history stays intact.
- **Active workout** — planned sets prefilled from last time, the previous result right next to each set, steppers by the equipment's step, "same as previous", warm-up sets, a stopwatch for timed sets, a workout note. The workout survives relaunch.
- **Plate loading** — the exact per-side plate stack for the bar, drawn in the colors of your own plates (IWF by default).
- **Rest timer** — starts after every set, ±15 s, skip, a local notification when rest is over; shown above the tab bar at any navigation depth.
- **Live Activity and Dynamic Island** — the current exercise and set for the whole workout, with the rest countdown.
- **Records and charts** — max weight and estimated 1RM (Epley), bodyweight and timed records, a "Record" badge the moment you beat one, a progress chart per exercise.
- **Progression hint** — when last time's plan was fully done, a one-line suggestion to add the equipment's step.
- **History** — a GitHub-style heatmap of working sets over 15 weeks, workouts by month, workout details.
- **Backup** — export and import of all data as a versioned JSON file; import validates the file before replacing anything.
- **Light and dark** appearance, Dynamic Type, VoiceOver labels.

The interface is in Russian for now; an English localization is planned before a public release.

## Tech stack

| | |
|---|---|
| Language | Swift 6 (strict concurrency, MainActor by default in the app target) |
| UI | SwiftUI, Observation, Swift Charts |
| Storage | SQLite via [GRDB 7](https://github.com/groue/GRDB.swift) — the only third-party dependency |
| System | ActivityKit + Widget Extension, UserNotifications |
| Tests | Swift Testing |
| Platform | iPhone, portrait, iOS 26+ |

## Architecture

Layers with a strict dependency direction **presentation → domain → data**.

- **`Packages/SportplanKit`** — a local Swift package:
  - `Domain` — models, repository protocols, use cases and pure calculations (1RM, records, plate loading, progression, heatmap levels). `Sendable` value types, no SwiftUI or GRDB, tested with `swift test` on the Mac.
  - `DesignSystem` — color, type, spacing and corner radius tokens plus base components, shared by the app and the widget.
  - `WorkoutActivity` — Live Activity types shared by the app and the extension.
- **`sportplan/`** — the app:
  - `data/` — GRDB database, migrations, records and repository implementations;
  - `presentation/` — feature folders with a `Route` (owns an `@Observable` ViewModel), a pure `Screen` and UI state;
  - `di/AppDIContainer.swift` — the single composition root, no DI framework.
- **`sportplanLiveActivity/`** — the Live Activity and Dynamic Island.

Reactive reads use GRDB's `ValueObservation` as `AsyncSequence`; there is no Combine. Each tab has its own `NavigationStack`, so the rest timer above the tab bar stays visible at any depth.

## Build and run

Requires Xcode 27 (the project uses the new text project format) and an iOS 26+ simulator or device.

```bash
# Build the app for the simulator
xcodebuild -project sportplan.xcodeproj -scheme sportplan \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build

# App tests
xcodebuild test -project sportplan.xcodeproj -scheme sportplan \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro'

# Package tests (Domain, DesignSystem) on the Mac
cd Packages/SportplanKit && swift test
```

To run on your own iPhone, set your team in Signing & Capabilities. The app uses no capabilities beyond a free Apple ID (no iCloud, push or App Groups).

## Documentation

- [`docs/code-brief.md`](docs/code-brief.md) — scope, architecture and data model.
- [`.design/design-brief.md`](.design/design-brief.md) — design brief and decisions.
- [`docs/decisions.md`](docs/decisions.md) — the decision log (early entries are in Russian).
- [`docs/roadmap.md`](docs/roadmap.md) — what is done and what is next.
- [`CLAUDE.md`](CLAUDE.md) — code conventions.

## License

Dužy is source-available under the [PolyForm Noncommercial License 1.0.0](LICENSE.md): you can read, build, modify and use it for any noncommercial purpose. Selling it or publishing it to an app store is not allowed. For other uses, open an issue.

Bundled third-party parts keep their own licenses: the Sofia Sans Condensed and Onest fonts are under the SIL Open Font License (see `Packages/SportplanKit/Sources/DesignSystem/Resources/Fonts`), and GRDB is under the MIT License.
