# Roadmap (20.11.2026)

The order comes from `docs/code-brief.md` ("Stages"). The DB schema for the whole app has been ready since stage 2; after that it is mostly screens and logic.

## Done
- 0 — decisions and documents.
- 1 — skeleton: project, package, DI, tokens, localization, three tabs.
- 2 — database: schema v1, migration, Records, tests.
- 3.1 — "My gym": equipment.
- 3.2 — exercise library and adding in 2 steps.
- 4 — programs: Domain, data and screens (4.1, 4.2).
- 5 — active workout: start from a day and off-plan, planned sets, previous result, steppers, plate loading and stack, stopwatch, note, "Finish" / "Cancel", "next day".
- 6 — rest timer: panel in the exercise and the bottom accessory, ±15 s, "Skip", end-of-rest notification, "Same as last time" in the editor.
- 7 — Live Activity / Dynamic Island: extension target, data from the active workout, lock screen and island (not checked on a device).
- Review fixes: system swipes with full swipe, full-width lists on screens with swipes, deleting a day and a program by swipe with confirmation, day screen header in the content, exercise picker buttons, set row at large text sizes.
- 8 — plates: a section in "My gym", a plate sheet with a custom color, reset to IWF, observing the set during a workout and in the Live Activity.
- 9 — records and charts: record calculation in Domain, a "Record" badge in the workout, the exercise card from the library with a chart, records and history.
- 10 — progression hint: weight "previous max + step" after the plan was completed, "Apply" to all sets that are not done, a close button.
- Review 2 fixes, blocks 1–6: the set editor only saves, keyboard dismissal, starting weight and set time in the program (schema v2), countdown for a timed set with a notification and Live Activity, a custom signal and sound in headphones in the foreground, menu and swipe on the rest bar (B3), a screen before starting a day (B4). Sound, haptics and Live Activity not checked on a device.
- Review 2 fixes, block 7: creating an exercise from the picker as steps in the stack (C1), editing an exercise from the library and the card, the exercise menu in a workout, "Archive" with "Restore" (C2).
- 11 — history and heatmap: a 15-week heatmap, a list by month with records, a day screen, workout details with deletion.
- 12 — JSON export and import: "Data" in settings, export via the share sheet, import with validation and confirmation, blocked during a workout.
- App icon: the bending loaded bar from `screens/AppIcon` — default, dark and tinted; the app is renamed to Dužy.

All stages from `docs/code-brief.md` are implemented.

## Remaining
| # | Block | Scope | Status |
|---|---|---|---|
| ✓ | Rename to Dužy | Home-screen name `Dužy`, the three «Sportplan» strings in `Localizable.xcstrings`, backup file prefix `sportplan-` → `duzy-` in `ExportBackupUseCase` and `BackupUseCaseTests`, the new icon in `AppIcon`, README and docs. Bundle id, targets and the repository stay. | Done |

## Waiting for mockups
- None.

## After the app is implemented
Small fixes — once all stages are done.
- Collapsing the tab bar on scroll on the "Workout" tab during a workout, and a compact timer in the collapsed bar (decisions — in `decisions.md`).
- Fonts: in Sofia Sans Condensed "3 подхода" is drawn with Bulgarian Cyrillic forms ("3 nogxoga"); at the largest text size "Справочник упражнений" breaks mid-word; "кг" in the numeral font looks like "kг".

## To discuss
- None.

## Rejected
- B6 — remove "Empty workout": an off-plan start is in the approved scope (`docs/code-brief.md`); without it you can't train without a program.
- Time Sensitive notifications: a personal team does not sign this capability.
