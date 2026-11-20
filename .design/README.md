# .design — design canvas snapshot

A snapshot of the "Workout tracker" canvas sources as of 17.11.2026. The brief is `design-brief.md` in this same folder; the app icon has its own `icon-brief.md`.
Live version (to view and edit): https://claude.ai/artifact/HfYdf17DiKLv8MoVk1qzQJ

## What these files are

- `canvas.json` — the canvas layout: which boards exist, their sizes and order.
- `*.dc.html` — boards in the Design Component format. This is HTML with inline styles plus templates (`{{t.surf}}`, `<sc-for>`, `<sc-if>`, `<dc-import>`), so a regular browser does not render them fully. View them via the link above.
- Template values are at the end of each file, in `renderVals()`. For each theme there is a `light` / `dark` object with the colors.

## What is where

| Folder / file | Contents |
|---|---|
| `Main`, `Journal`, `Print` | Step 1: three concepts (history) |
| `Hybrid` | The chosen direction, "Plates, large" |
| `system/Color` | Color tokens for the light and dark themes, contrast, IWF plates, heatmap levels |
| `system/Type` | Type scale (Sofia Sans Condensed + Onest, Dynamic Type), 4pt spacing, corner radii, lines |
| `system/FontChoice` | Choice of the numeral font: Sofia Sans Condensed (chosen), alternatives and why not Unbounded |
| `system/Foundations` | SF Symbols, motion and Reduce Motion, haptics |
| `system/WorkoutKit` | Set row, stepper, rest timer, set stopwatch, Live Activity and Dynamic Island for the whole workout, progression hint, note |
| `system/LoadTypes` | Set row by equipment and metric |
| `system/HistoryKit` | Heatmap (5 levels by working sets), charts and records for the three exercise types, record badge, empty states |
| `system/PlatesKit` | "My gym" settings: equipment and plates |
| `screens/WorkoutScreen` | The "Workout" screen: one component, parameters `dark` and `state` (active / start / empty / ax) |
| `screens/*Light`, `*Dark` | States of the "Workout" screen, assembled from `WorkoutScreen` |
| `screens/ProgramsScreen` | The "Programs" tab: `state` list / listNoDays / menu / progDelete / empty / day / dayEmpty / dayEdit / dayDelete, `large` — large text |
| `screens/ProgramsFlow` | Program sheets: `state` create / dayNew / dayForm / goals / goalsTimed / picker, `large` |
| `screens/ExerciseFlow` | Library and adding: `state` library / libraryEmpty / libraryArchive / archive / archiveFree / type / details / detailsBody / edit |
| `screens/HistoryScreen` | The "History" tab: `state` list / empty / workout / ax |
| `screens/ExerciseCard` | Exercise card: `state` weighted / bodyweight / timed / empty / ax |
| `screens/SettingsScreen` | Settings and "My gym": `state` main / import / gym / gymEmpty / gymArchive / ax |
| `screens/LiveActivity` | Live Activity on the lock screen and Dynamic Island (compact, minimal, expanded) in three states |
| `screens/AppIcon` | Three icon variants: default, dark, tinted, small sizes |
| `screens/Prog*`, `Lib*`, `Add*`, `Archive*`, `Hist*`, `Card*`, `Set*`, `Flow*`, `Ex*` | States of these screens in the light and dark themes |

For code, what matters most is `system/Color` and `system/Type`: they hold all the tokens (names like `textPrimary`, `surfaceSunken`, `numeralL` match what should be defined in the design tokens module).
