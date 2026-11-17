# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Sportplan — a minimalist offline strength-training tracker for iPhone (SwiftUI). No accounts, no server, no subscriptions. iOS 26+, iPhone only, portrait only. The Xcode project does not exist yet; it is created at stage 1 (skeleton). Update the "Build & run" section once it does.

Source documents:
- `docs/code-brief.md` — approved scope, architecture, data model.
- `.design/design-brief.md` — design brief and status; `.design/` also holds the design canvas snapshot (`system/Color`, `system/Type` define the token names to use in `DesignSystem`).
- `.claude/decisions.ru.md` — log of decisions and the reasoning behind them.

When the briefs and the code disagree, raise it instead of silently picking one.

## Team Conventions

### Way of working
The app is built in stages, one block at a time. Discuss a stage before planning it, and plan it before implementing it. Do not jump ahead to later stages or add features outside the approved scope; anything not in `docs/code-brief.md` is discussed first.

### Files
Save all Claude-generated documents (plans, decisions, review summaries, task lists) in the `.claude/` folder at the repo root, written in Russian, as `.ru.md` files (e.g. `.claude/<topic>-plan.ru.md`). Design documents live in `.design/`.

### Commit Messages
Every commit message follows this structure:

```
Short summary of the feature(s) in general terms

- First feature in one sentence
- Second feature in one sentence
```

Omit the bullet list only when the commit truly contains a single change already covered by the summary line.

Never mention Claude, Anthropic, or any AI assistant in a commit message — no `Co-Authored-By: Claude`, no "Generated with Claude Code", no trailers or footers of any kind referencing them.

### Mindset
Do not be a yes-man. If a proposed approach has problems, say so and explain the trade-off before implementing. State your position first; implement what the user decides after the discussion.

### Swift Code Rules

**One type per file:** Every `class`, `struct`, `enum`, `protocol`, and `actor` lives in its own file named after the type. The only exceptions are small private helper types used exclusively by one other type in the same file.

**No comments:** Do not write any comments in Swift source files — no `//`, no `/* */`, no doc comments (`///`, `/** */`). Self-documenting names are the only acceptable form of documentation.

**Named constants:** All numeric limits and domain values (default rest, 1RM rep cap, heatmap thresholds, plate weight bounds, timer adjustments, etc.) must be a `private static let` (or a `private` constant in the owning type). Never write a raw number inline where the value carries meaning.

**Explicit `return`:** Always write `return` in non-`Void` functions and closures, even when Swift allows single-expression implicit returns. Applies to computed properties, single-statement function bodies, and trailing closures alike.

**Localization:** Never hardcode user-facing strings. Every string shown in the UI goes through the String Catalog (`Localizable.xcstrings`) via `String(localized:)` / SwiftUI's automatic `Text` localization. Base language is Russian.

## Architecture (target)

Layers with a strict dependency direction `presentation → domain → data`.

- **Local Swift Package**
  - `Domain` — models, repository protocols, use cases, pure calculations (1RM, records, plate loading, progression, heatmap levels). Types are `Sendable` value types, logic is `nonisolated`, no dependency on SwiftUI or GRDB. Tested with `swift test`.
  - `DesignSystem` — tokens (`Palette`, `Typography`, `Spacing`, `CornerRadius`) and base components; shared by the app and the widget extension.
- **App target**
  - `data/` — GRDB: `AppDatabase`, records, `XRepositoryImpl` implementing `Domain` protocols directly on top of the database. Records expose `toDomainModel()` mappers. No DataSource layer; separate classes only for external systems (notifications, ActivityKit, export files).
  - `domain` wiring lives in the package; use cases take repositories via init and expose a single `execute`-style entry point.
  - `presentation/` — feature folders, each with `ui/`, `viewmodel/`, `models/`, `states/`.
  - `di/AppDIContainer.swift` — the single composition root; every repository and use case is a `private lazy var`, `buildXViewModel()` factories in an extension. No DI framework.
- **Widget Extension** — Live Activity only. `ActivityAttributes` is compiled into both targets; no App Groups.

### Presentation pattern
- ViewModels are `@Observable final class`, hold collaborators as `@ObservationIgnored private let`, and expose a single `private(set) var xUiState` enum (`.loading` / `.success(data:)` / `.error(error:)`) plus a `XUiData` struct.
- ViewModels talk to use cases only, never to repositories, even for simple pass-through reads.
- Reactive reads use `ValueObservation.values(in:)` (`AsyncSequence`), consumed in a task started from `.task {}` on the Route so it is cancelled automatically. Do not use Combine.
- Each screen has two views: `XRoute` owns the ViewModel and switches on the UI state; `XScreen` is a pure view taking plain data + closures (and carries `#Preview`). Screens take no ViewModel.
- UI events travel up as closures or a `UserAction` enum, never by calling the router from a screen.

### Navigation
`TabView` with three tabs (Workout, Programs, History). Each tab has its own `NavigationStack(path:)` and its own `Router` (wrapping `NavigationPath`), so pushed screens never cover the tab bar and the rest timer in `tabViewBottomAccessory` stays visible at any depth. Destinations are `Hashable` structs registered once per stack. Never hide the tab bar with `.toolbar(.hidden, for: .tabBar)`.

### Workout state
The active workout is the `workout` row with `finished_at IS NULL` (at most one, enforced by a partial unique index) and survives app relaunch. The rest timer persists only its end date and never ticks on its own; the UI renders it with `Text(timerInterval:)` / `TimelineView`. One long-lived owner of this state lives in `AppDIContainer` and is read by the Workout tab, the bottom accessory and the Live Activity.

### Persistence
GRDB (SQLite) is the only third-party dependency. Schema v1 is described in `docs/code-brief.md`. Conventions: UUID primary keys, weights in integer grams (`Weight` in the domain), ordering via `position`, dates in UTC, foreign keys on with explicit indexes. Schema changes go in the migrator as a **new** `registerMigration` block — never edit an existing one once real data exists. Exercises and equipment are archived, never deleted.

## Conventions

- Theming: never hardcode colors, fonts, spacing or corner radii; use the `DesignSystem` tokens. Plate colors are user data used only for the plate stack graphic; state colors (record, success, warm-up, destructive) are separate tokens. Both light and dark appearance are supported; `preferredColorScheme` is not set.
- Icons: SF Symbols only, unless the design provides a custom asset.
- Accessibility: Dynamic Type, VoiceOver labels, tap targets of at least 44pt, Reduce Motion.
- Naming: no `XxxDefaults` constant holders (use `private static let`, or a file-private `enum XMetrics` when sibling types need it); no SCREAMING_SNAKE constants; no `get`-prefixed accessors.
- Distribution uses a free Apple ID (personal team): do not add capabilities it does not support (iCloud/CloudKit, push notifications, App Groups).
- Tests use Swift Testing (`@Test`). Domain logic is covered by unit tests in the package; repositories are tested against an in-memory GRDB database.

## Build & run

Not available yet — the Xcode project is created at stage 1. Do not invent commands until then.
