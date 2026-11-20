# Development brief: workout tracker (iOS)

## Context

A personal pet project: a minimalist strength-training tracker for iPhone. No ads, subscriptions, calories or accounts. It is built for myself first; publishing to the App Store as a one-time purchase (not a subscription) is possible later.

Main principle: **don't overload it**. New features are added only by agreement. Anything not listed below is discussed separately. The goal of v1 is a live working app.

Design is done separately (`.design/design-brief.md`). The code must easily take the design system tokens: colors, fonts and spacing live in one place.

Development goes in stages, one block at a time; each stage is discussed before it starts. The full decision log is `docs/decisions.md`, progress is in `docs/roadmap.md`.

---

## Features (approved scope)

### 1. Equipment and exercises
- **Equipment** is all the gym hardware: bars, dumbbells, machines. Kinds:
  - free weights: `barbell` (bar, including EZ and Smith), `dumbbell`;
  - machines: `plateLoadedMachine` (with plates), `selectorizedMachine` (weight stack).
- Equipment has a name, a bar or platform weight (`baseWeight`, 0 for selectorized machines and dumbbells) and a weight step (`weightStep`).
- There is one gym: equipment and plates are not tied to any gym.
- **Exercise**: name, optional description (text), equipment (if not set — bodyweight), metric (`weightReps` — weight × reps, `duration` — time), default rest (`restSec`, 90 s).
- The library is shared by all programs; it is empty on first launch, and adding is quick.
- Exercises and equipment are **archived, not deleted**: they disappear from the library and pickers, while history, records and charts stay. When archived, an exercise is removed from program days, with the confirmation "will be removed from N days".
- The "Archive" section in the library and in "My gym" restores archived items (an exercise does not return to program days). Done once there is a design.
- If an exercise already has sets, its metric cannot change, and its equipment can only change to equipment of the same kind (otherwise old records would be read differently).
- If equipment is used in at least one exercise, its kind cannot change: otherwise history would be reinterpreted (a barbell weight would become the weight of one dumbbell). Name, bar weight and step change freely.
- Adding an exercise takes 2 steps: "What do you use?" (kind) → details (name, equipment of that kind from "My gym" or new, metric, rest, description). In an empty library there are chips with common exercises (bench press, squat, deadlift, pull-ups, dips, leg press, plank): a chip opens step 2 with the name, kind and metric filled in.
- The "Time" metric is only for bodyweight exercises; exercises with equipment always use "Reps". Duplicate names are allowed. Equipment in step 2 is picked automatically only if there is exactly one suitable item in the gym.
- Search by name in the library.
- Editing an exercise — once there is a design.

### 2. Program plan
- Program → days ("Day A — chest/triceps") → exercises in a day.
- For an exercise in a day: order, target number of sets, **target rep range** (min–max; a single number = min == max), rest time (taken from the exercise by default).

### 3. Active workout and set history
- A workout starts from a program day or empty (off-plan). There is one active workout; it survives closing the app.
- Targets (sets, reps, rest) are copied into the workout at start: later program edits do not change history.
- **Planned sets**: starting from a day creates as many rows as there are target sets. Values come from the working sets of the previous workout with this exercise, by number; if there were fewer, the last one repeats. Warm-ups you add yourself. An off-plan workout has the same structure as last time.
- A set row is either "planned" or "done". On "Finish", rows that are not done are deleted.
- How a set is recorded depends on the exercise; there is a "warm-up" flag:
  - barbell and plate-loaded machine — weight × reps, plate stack;
  - selectorized machine — weight × reps;
  - dumbbells — weight of one dumbbell × reps;
  - bodyweight — reps, optional added weight (weight = additional weight, 0 by default);
  - timed — a **stopwatch**: a button starts counting up, the user stops it, the actual duration is recorded.
- **Previous result right in the input field**: this exercise's sets from the last workout are shown next to it.
- **Repeat a set in one tap**: a "same as previous" button, weight steppers (± the equipment step; 2.5 kg for bodyweight added weight) and reps steppers (±1).
- Add or delete a set, add an exercise during a workout.
- **Workout note** (text).

### 4. Rest timer
- **Starts automatically** after any completed set (including a warm-up). The duration is the exercise's rest in this workout.
- Can be skipped, and 15 s can be added or removed.
- The timer stores only its end time and does not tick by itself: it survives backgrounding and relaunch.
- A local notification at the end of rest (`UNUserNotificationCenter`), cancelled on skip. Permission is requested the first time the timer starts; without permission the timer works in the app and in the Live Activity.
- In the app the timer is shown in `tabViewBottomAccessory` above the tab bar, only during rest.

### 5. Live Activity / Dynamic Island
- One Live Activity **for the whole workout**: it starts with the workout and ends on "Finish".
- Shows the current exercise and set; during rest — a countdown via `Text(timerInterval:)`, without updates from the app.
- `staleDate` = end of rest → the "Rest is over" state when the app is in the background.
- No buttons in the Live Activity in v1.

### 6. Plates
- The plate set of your gym: each plate has a weight and a color (hex). The default is the IWF standard: 25 (red), 20 (blue), 15 (yellow), 10 (green), 5 (white), 2.5 (red), 1.25 (steel).
- Add, edit, delete a plate; "Reset to IWF standard" with confirmation. Two plates of the same weight are not allowed; weight is from 0.25 to 50 kg.
- Per-side loading for a barbell and a plate-loaded machine: `(weight − bar/platform weight) / 2`. **Exact match**: any number of plates of each weight; pick the option with the fewest plates, on a tie — the one with heavier plates. If the weight is below the bar or cannot be made exactly, no stack is shown; if the weight equals the bar — an empty bar.
- The plate color is used only in the stack graphic. State colors (record, success, warm-up, destructive) are separate design system tokens.
- There is no music in the app: the system player on the lock screen covers it.

### 7. Personal records and exercise chart
Only completed working sets count. **Warm-up sets do not take part** in records, charts, the heatmap or the progression hint.

| Exercise | Records | Chart (point = workout) |
|---|---|---|
| With equipment, weight × reps | Max weight; max estimated 1RM by Epley `w × (1 + reps / 30)`, w when reps == 1; 1RM only from sets with reps ≤ 12 | Best estimated 1RM or max weight (toggle) |
| Bodyweight | A set is a record if there was no earlier set where both added weight and reps were not lower. On the card: "max reps", "max added weight × reps" | Max reps |
| Timed | Max duration | Max duration |

- A "new record" badge when recording a set that beat a record. The comparison is with everything before this set, including the current workout. Matching a record is not a record. If the exercise has no history yet, there is no badge.
- Charts use Swift Charts.

### 8. Progression hint
- Only for exercises with equipment and the weight × reps metric.
- Condition: the previous workout with this exercise had targets, at least the target number of working sets, and each had reps at or above the top of the range.
- Suggestion: the max working weight of the previous workout + the equipment step.
- The hint is unobtrusive: one line; a tap fills the weight into all of the exercise's working sets that are not done. No automation without the user.

### 9. Calendar (heatmap)
- A GitHub-style day grid on the "History" tab.
- Intensity is the number of completed working sets per local day, 5 levels: 0 / 1–6 / 7–12 / 13–18 / 19+ (to be tuned on real data).
- Tapping a day opens that day's workout(s).

### 10. Offline and data
- Works fully offline, there is no server.
- Local storage in SQLite via GRDB.
- Export and import of all data as JSON (`fileExporter` / `fileImporter` and ShareLink) for backup and transfer. The JSON has `schemaVersion`; in v1 import **replaces all data** after confirmation.

---

## UI structure

`TabView`, three tabs, each with its own navigation stack (the timer in the accessory is visible at any depth):
1. **Workout**: start and the active workout.
2. **Programs**: programs, days, exercises.
3. **History**: heatmap, workout list, details, exercise card (chart, records, history).

Plus settings: **"My gym"** (equipment and plates), export and import.

iPhone only, portrait only.

---

## Stack

- Swift, SwiftUI, Observation (`@Observable`), async/await.
- GRDB 7 (SQLite) — the only third-party dependency, via SwiftPM ("up to next major"), in the app target only. The app uses `DatabasePool` (WAL) with a file in Application Support; tests use an in-memory `DatabaseQueue`.
- Swift Charts for charts.
- ActivityKit and a Widget Extension for the Live Activity.
- UserNotifications for the end of rest.
- Swift Testing for tests.
- Minimum version: **iOS 26**.
- No other third-party dependencies until they are really needed.

## Architecture

- Layers `presentation → domain → data`, with a strict dependency direction.
- **Local Swift Package**:
  - `Domain` — models, repository protocols, use cases, pure calculations (1RM, records, plate loading, progression, heatmap). Types are `Sendable`, logic is `nonisolated`. Tested with `swift test` without a simulator.
  - `DesignSystem` — tokens (colors, fonts, spacing, corner radii) and base components; shared by the app and the widget.
- **App**: `presentation/` (features: `ui/`, `viewmodel/`, `models/`, `states/`), `data/` (GRDB: `AppDatabase`, records, repositories), `di/` (`AppDIContainer` — the single composition root).
- **Data**: `XRepository` (protocol in Domain) / `XRepositoryImpl` directly on top of `AppDatabase`, without a DataSource. Separate classes only for external systems: notifications, ActivityKit, export files.
- **Use cases**: a ViewModel talks only to use cases, even for simple pass-throughs.
- **Presentation**: a ViewModel is an `@Observable final class` with a `UiState` (`loading` / `success` / `error`); a screen is `XRoute` (owns the ViewModel, subscribes in `.task {}`) + `XScreen` (a pure View with data and closures, `#Preview`).
- **Reactivity**: `ValueObservation.values(in:)` → `AsyncSequence`; Combine is not used.
- **Navigation**: a `Router` over `NavigationPath`, its own `NavigationStack` and `Router` in each tab.
- **Workout state**: the active workout is a `workout` row without `finishedAt` in the DB; the rest timer is a stored end time; one long-lived owner of this state in `AppDIContainer`, read by the "Workout" tab, the accessory and the Live Activity.
- Code rules are in `CLAUDE.md` at the repo root.

## Data model (v1)

Conventions:
- Keys are UUIDs stored as text (stable across export and import, readable when debugging).
- Weight is integer **grams** (`INTEGER`); in the domain it is the `Weight` type with formatting. A switch to lb, if it appears, will not need a migration.
- Order is `position INTEGER`.
- Dates are UTC; days for the heatmap are grouped in Swift by the local calendar.
- Migrations via `registerMigration`; once real data exists, existing migrations are not edited, only new ones are added.
- Foreign keys are on, every FK has an explicit index.

```
equipment          id, name, kind, base_weight_g (0), weight_step_g, is_archived, created_at
                   kind: barbell | dumbbell | plate_loaded_machine | selectorized_machine
exercise           id, name, description?, equipment_id? → equipment RESTRICT,
                   metric (weight_reps | duration), rest_sec (90), is_archived, created_at
program            id, name, position, created_at
program_day        id, program_id → program CASCADE, name, label?, position
planned_exercise   id, program_day_id → program_day CASCADE, exercise_id → exercise RESTRICT,
                   position, target_sets, target_reps_min?, target_reps_max?, rest_sec
workout            id, program_day_id? → program_day SET NULL, program_day_name? (copy),
                   program_day_label? (copy), started_at, finished_at?, note?,
                   rest_started_at?, rest_ends_at?
workout_exercise   id, workout_id → workout CASCADE, exercise_id → exercise RESTRICT,
                   position, target_sets?, target_reps_min?, target_reps_max?, rest_sec
set_entry          id, workout_exercise_id → workout_exercise CASCADE, position,
                   weight_g (0), reps?, duration_sec?, is_warmup, started_at?, completed_at?
plate              id, weight_g UNIQUE CHECK(250…50000), color_hex
```

- Indexes: all FKs, `workout(started_at)`, a partial unique index `workout WHERE finished_at IS NULL` — there is one active workout, and the database itself guarantees it.
- Deleting or changing a program does not break history: `workout` keeps a copy of the day's name and label, `workout_exercise` keeps a copy of the targets.
- Program day: `name` is required ("Chest and triceps"), `label` is an optional short label ("A"). Without a label the name is shown everywhere.
- Rest timer: `rest_started_at` and `rest_ends_at` on the active workout. ±15 s shifts the end, "Skip" clears both fields, the "of 2:00" progress is the difference of the dates.
- Timed set stopwatch: `set_entry.started_at` is written at start; on stop — `duration_sec` and `completed_at`; it survives relaunch.
- The IWF plates are inserted by migration v1 from a constant in `Domain`; "Reset to IWF standard" uses the same constant.
- Records and the "previous result" are computed by queries and in Swift, not stored separately (they can be cached if performance becomes a problem).
- There are no global settings in the DB; `UserDefaults` is only for small UI details.

## Distribution

- For now a free Apple ID (personal team): the profile lives 7 days. Reinstalling from Xcode over the current version keeps the data; deleting the app does not, which is why export matters. An option is SideStore or AltStore for automatic re-signing.
- The free account limit is about 3 apps, and a Widget Extension takes a separate slot: the app will take 2 of 3.
- **No capabilities unavailable to a free account**: iCloud/CloudKit, push notifications, App Groups (not needed for the Live Activity — `ActivityAttributes` is compiled into both targets). Local notifications and Live Activities are fine. Time Sensitive notifications — check at the timer stage.
- The paid Developer Program is still in question (payments and payouts from Belarus can be a problem).
- Language: Russian is the primary one, all strings go through the String Catalog; English — before publishing.

## Quality

- Unit tests for pure logic: 1RM, records, prefill and previous result, progression hint, heatmap levels, plate loading, JSON export and import (round-trip). Repositories — on an in-memory database.
- Accessibility: Dynamic Type, VoiceOver labels, tap targets of at least 44pt.
- Design tokens (colors, fonts, spacing) in the `DesignSystem` module, so the design system is easy to plug in.

## Stages

0. Decisions and documents.
1. Skeleton: project, targets, package, DI, token stubs, localization, three tabs.
2. DB: schema, migrations, repositories, tests.
3. Then one block at a time: equipment and exercises → programs → active workout → timer and notifications → Live Activity → plates → records and charts → progression → history and heatmap → export/import. Screens — once the design is ready.

## Out of scope

Music player and Apple Music integration, illustrations and animations of exercise technique, muscle groups, calories and nutrition, accounts, cloud and sync, social features, subscriptions, ads, AI features, Apple Watch (for now), iPad and landscape, multiple gyms, buttons in the Live Activity (for now), volume (tonnage) tracking, automatic backup (in later versions).

## Open questions (discuss along the way)

- The flow for adding an exercise and equipment — based on the design.
- App name and bundle id — at the skeleton stage.
- Machine settings (seat, back) — an idea, not in scope; their place is `equipment`.
- Counterweight machines (assisted pull-up), where a lower weight is harder — not supported for now; a separate kind in the future.
- Machines loaded on one side (T-bar) — `plate_sides` in `equipment` in the future.
- Supersets — `group_id` on `workout_exercise` in the future.
- Units: kg only or a switch to lb (weight is already stored in grams).
