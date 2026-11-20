# Design brief: workout tracker (iOS)

## What the product is

A personal strength-training tracker for iPhone. No ads, no subscription, no calories and no social networks. The app does three jobs:

1. Stores the training program plan (program → days → exercises).
2. Records sets quickly right in the gym and shows what happened last time.
3. Shows history: a calendar, personal records, progress per exercise.

Main principle: **nothing superfluous**. Every element on screen must be justified. If you doubt whether an element is needed, it isn't.

Conditions of use: the gym, the phone in one hand, sometimes sweaty hands, bright light or dim light, 30–60 seconds of attention between sets. The screen reads at first glance, at arm's length.

---

## Step 1. Design system (done first)

Before drawing screens, we build our own design system. It must be recognizable and different from competitors (Hevy, Strong, Fitbod and the like), not look like yet another template.

### Requirement #1: don't look like AI output

The design must look as if a living designer with character and a point of view made it. Everything that immediately gives away generation or a template is banned:

- purple-blue and "sunset" gradients, gradient text;
- glassmorphism and blur on everything, glowing shadows;
- neon lime or orange on black, aggressive italic fonts (the main cliché of fitness apps);
- identical cards with the same shadow and a 16pt radius everywhere;
- emoji instead of icons, 3D blobs, abstract "AI illustrations", stock photos of athletes;
- a faceless system look with nothing but SF Pro and a blue accent;
- decorative elements that communicate nothing.

### What is needed instead

First propose **3 different concepts** for the visual direction. For each: a short idea (1–2 sentences), a palette, a font pair and one example of a key component (the set row). We pick one and develop it.

Directions to start from (you can propose your own if they are stronger):

- **Olympic plate colors.** An accent system based on the IWF standard: red 25 kg, blue 20, yellow 15, green 10, white 5. Color carries meaning, for example in heatmap levels or records. The base is neutral, color is used sparingly.
- **Training log.** The feel of a coach's paper diary: ruled lines, monospaced or tabular numerals, dense informative typography, "handwritten" marks only as a rare accent.
- **Sports print.** Swiss typography, large numerals as the main visual element, a strict grid, a bold type scale and almost no decoration.

Numbers (weight, reps, time) are the main content here. They must be large, tabular (tabular figures) and beautiful in themselves.

### Design system contents

- **Color.** Tokens for the light and dark themes: background, surfaces, text (primary/secondary/tertiary), accent, states (success, record, warm-up, destructive action). Text contrast at least WCAG AA. Color is never the only carrier of meaning.
- **Typography.** A style scale compatible with Dynamic Type. A custom font for numerals and headings is fine, but it must scale. A separate style for large numerals.
- **Spacing and grid.** A 4pt step, screen rhythm.
- **Shapes.** Its own corner radius logic (not one value for everything), strokes, dividers.
- **Icons.** SF Symbols as the base (they adapt natively to the system). Custom icons only where SF Symbols has none, in the same optical weight.
- **Motion.** Short meaningful animations: recording a set, starting the timer, a new record. Respect Reduce Motion.
- **Haptics.** Where to use haptics (recording a set, end of rest, a record).

### Base components

1. Set row: number, value, "warm-up" mark, state (planned / done). The previous result next to it. Variants by the exercise's equipment:
   - barbell and plate-loaded machine — weight × reps, with a plate stack;
   - selectorized machine — weight × reps;
   - dumbbells — weight of one dumbbell × reps;
   - bodyweight — reps and optional added weight ("+10 × 8");
   - timed — duration (the "time" metric is also possible for bodyweight, e.g. a plank).
2. Weight and reps stepper (± the equipment step, e.g. 2.5 kg; ±1 rep) and a "same as previous" button. Large tap targets, easy with the thumb.
3. **Timed set stopwatch**: a button starts counting up, the user stops it, the actual time is recorded. This is a separate component and must not be confused with the rest timer.
4. Rest timer (countdown): in the app, in the bottom accessory above the tab bar, only during rest.
5. Live Activity / Dynamic Island **for the whole workout**: the current exercise and set; during rest — a countdown; a "Rest is over" state when rest has expired and the app is in the background. No buttons.
6. "My gym" in settings:
   - equipment: bars (Olympic, EZ, Smith), dumbbells, plate-loaded and selectorized machines; each has a name, a bar or platform weight and a weight step;
   - the plate set of your gym (color and weight of each plate), editing a plate, reset to the IWF standard.
7. Heatmap cell and legend, 5 levels (0 / 1–6 / 7–12 / 13–18 / 19+ working sets per day).
8. Exercise progress chart (Swift Charts style in our system); the variant depends on the exercise type (see "App structure").
9. New record badge.
10. Progression hint ("Last time everything was done, try 62.5 kg"), unobtrusive. Only for exercises with equipment.
11. Workout note field.
12. Empty states: no placeholder illustrations, typography and one hint instead.

---

## Apple guidelines and best practices

Before starting, study the Apple Human Interface Guidelines (developer.apple.com/design/human-interface-guidelines) and the current Liquid Glass materials. The key points:

- **Liquid Glass only on the navigation layer**: tab bar, toolbars, floating buttons. There is no glass on content (set rows, cards, charts). Our uniqueness lives in the content, and the system navigation stays native.
- **The tab bar is for navigation, not for actions.** It floats above the content and can collapse on scroll.
- **The bottom accessory above the tab bar** (like the mini player in Music) suits the rest timer. It is shown only during rest.
- **In iOS 27 Liquid Glass became more contrasty**, and the user got a transparency slider. The interface must stay readable at any setting of it.
- Minimum tap target 44×44pt. Bigger is better in the gym.
- Dynamic Type, VoiceOver labels, Reduce Motion, Increase Contrast.
- Light and dark themes are both complete; the dark one is not just an inversion.
- Native patterns: sheets, context menus, swipe actions. Don't invent replacements for what the user already knows.

---

## App structure

iPhone only, portrait only. Three tabs, no more are needed. Each tab has its own navigation: an opened screen does not cover the tab bar, and the rest timer in the accessory is visible at any depth.

1. **Workout.** A "Start" button with a choice of program day, or an empty workout. Active workout: a list of exercises with sets, the previous result, steppers, timer, note, a "Finish" button.
   - When starting from a day, the set rows are already created from the plan (the "planned" state) and filled with values from the previous workout. The user adds warm-ups themselves.
   - On "Finish", rows that are not done disappear.
2. **Programs.** The list of programs, days, exercises in a day: target sets, **rep range** ("8–12", a single number is also allowed), rest time.
   - **Exercise library.** An exercise has a name, an optional description, equipment (or "bodyweight") and a metric: reps or time. On first launch the library is empty; an empty state with quick adding is needed.
   - Exercises and equipment are not deleted but **archived**. The confirmation reads: "The exercise will be removed from N program days. History will be kept."
   - **Task:** propose a flow for adding an exercise. For example: category (free weights / machine / bodyweight) → subtype → name, with parameters filled in from the subtype. Equipment is chosen from "My gym" or created right there. The flow must be short, a couple of screens at most.
3. **History.** A heatmap at the top, the workout list below. Workout details. Exercise card: chart, records, set history. Records and the chart depend on the exercise type:
   - with equipment: records — max weight and estimated 1RM; chart — 1RM or max weight with a toggle;
   - bodyweight: records — max reps and max added weight × reps; chart — max reps;
   - timed: record and chart — max duration.

In addition:
- a settings screen: "My gym" (equipment and plates), data export and import; there are no global "bar weight" and "weight step", they belong to equipment;
- Live Activity / Dynamic Island for the whole workout;
- the app icon.

---

## Order of work

1. Three concepts for the visual direction, pick one.
2. Design system: tokens and base components (see above).
3. The active workout screen. It is the most important one, the system is tested on it.
4. The other screens: Programs, History, exercise card, settings.
5. Live Activity / Dynamic Island and the icon.

For each screen: light and dark theme, empty state, state with data, large Dynamic Type size.

## Status (17.11.2026)

Canvas: https://claude.ai/artifact/HfYdf17DiKLv8MoVk1qzQJ · a snapshot of the sources in `.design/` (see `.design/README.md`).

- **Step 1 — done.** Three concepts (Plates, Journal, Print); the hybrid "Plates, large" was chosen.
- **Step 2 — done.** Design system: color (light and dark theme tokens, AA), typography (Sofia Sans Condensed for numerals and headings + Onest for text, Dynamic Type), spacing, corner radii, lines, icons, motion, haptics. Components: set row (5 states; variants by equipment and metric), stepper (equipment step), rest timer, set stopwatch, Live Activity and Dynamic Island for the whole workout, progression hint, note, heatmap (5 levels), charts and records for the three exercise types, record badge, empty states, "My gym".
- **Step 3 — draft, awaiting review.** The "Workout" screen: active workout (light, dark, AX1), day picker, empty state. Rep targets are a range, planned set rows. Settings open from a gear on this tab; the "…" menu — add exercise / cancel workout.
- **Step 4 — draft, awaiting review.** Programs (list, empty, day, AX1); exercise library (list, empty with quick adding, archiving, adding in 2 steps); History (GitHub-style heatmap over 15 weeks, list, workout details, empty, AX1); exercise card (with equipment, bodyweight, time, no data, AX1); settings (main, import confirmation, "My gym" with data and empty, AX1).
- **Step 5 — draft, awaiting review.** Live Activity on the lock screen (set, rest, rest is over; light and dark), Dynamic Island (compact, minimal, expanded with a plate stack). Icon: variant A "Small step" was shipped as a placeholder; on 20.11.2026 the app was named **Dužy** and the new icon from `icon-brief.md` is in the app.

## Decisions made (17.11.2026)

- Visual direction: the hybrid "Plates, large" — meaningful color and the plate stack from the "Plates" concept, large numerals and sets on ruled lines from "Print". An exercise is one block, not a card per set.
- Plate color is graphics only (the stack on the bar). The default is the IWF standard; the user changes plate colors and weights to match their gym. States (record, success, warm-up, destructive) are separate tokens and do not depend on plate colors.
- There is no music in the app: the system player on the lock screen covers it. The bottom accessory is used only by the rest timer.
- An exercise has two characteristics: **equipment** (free weights: barbell, dumbbells; machine: plate-loaded, selectorized; or bodyweight) and **metric** (reps or time). The five set row variants stay. The plate stack is shown only for the barbell and the plate-loaded machine; for the others only the button sits on the right of the row.
- There is no visualization of exercises (illustrations, technique animations): only a text description.
- The default exercise rest is 90 s for all kinds and is not filled in from the subtype. The subtype fills in only the equipment ("My gym" filter) and the metric. Rest can be changed in a specific program day.
- Heatmap — a GitHub-style grid over the last 15 weeks (columns are weeks, rows are days starting Monday), without day numbers. Records are marked in the workout list, not in the grid.
- The numeral and heading font is Sofia Sans Condensed (OFL, native Cyrillic): narrow numerals like the markings on plates and competition scoreboards. Unbounded was rejected — it looks like a typical "AI font". The interface text is Onest. Check tabular figures (tnum) when wiring it up.
- The app name is **Dužy** (20.11.2026): Belarusian Łacinka for «дужы», strong, read like *doozy* in English. Variant A "Small step" (the bar end with a small plate) reads as a plunger at small sizes and is replaced; the new icon — a loaded barbell bending under its weight, no letters — is briefed in `icon-brief.md`.

## Changes after the architecture discussion (17.11.2026)

**Applied to the canvas on 17.11.2026** (the snapshot in `.design/` is updated). What was fixed in the finished components and the draft:
- `system/LoadTypes`: row variants are described through equipment and metric (see above). A timed set is a stopwatch, not a countdown.
- `system/WorkoutKit`:
  - the Live Activity and Dynamic Island live for the whole workout: they show the exercise and set, and during rest — the countdown; a "Rest is over" state is needed; no buttons;
  - a set stopwatch component is needed;
  - the weight stepper steps by the equipment step.
- `system/PlatesKit`: "Bar and plates" becomes "My gym". Instead of a single bar weight — a list of equipment (name, kind, bar or platform weight, step); plates stay as they are.
- `system/HistoryKit`: the chart and records in three variants by exercise type; heatmap — 5 levels.
- The "Workout" screen: planned set rows ("planned") are created when starting from a day, rows that are not done disappear on "Finish"; rep targets are a range.

## Tasks after the stage 3 discussion (18.11.2026)

**Done on the canvas on 18.11.2026** (the "Library and adding" row, the "18.11" block, and "My gym"):
- Editing an exercise — the same sheet as step 2 of adding: name, description, equipment (only of the same kind, with a caption explaining why), metric locked with a lock icon, default rest, "Archive". Opened by tapping a library row.
- "Archive" in the library — a row at the bottom of the list with a count, a screen with a "Restore" button and a caption saying the exercise does not return to program days. "Equipment archive" — the same in "My gym". An empty archive is not shown.
- The kind Picker in the "Equipment" sheet is disabled, next to it "Used in 4 exercises — the kind can't change".
- Step 2 of adding: the barbell has no metric toggle, "Bodyweight" has one (a separate mockup). Equipment is not preselected, "Add" is disabled until a choice is made.
- The archive alert without program days: "The exercise will disappear from the library. History will be kept."

Mockups needed; this code does not start without them:
- **Editing an exercise.** Rename, change the description, rest and equipment. The exercise kind does not change. If the exercise already has sets, the metric cannot change, and the equipment can only change to equipment of the same kind. Step 2 of adding in edit mode can be used — the design decides. Where it opens from: tapping a library row.
- **The "Archive" section.** In the exercise library and in "My gym", show archived items and let the user restore them. Restoring an exercise does not return it to program days. An empty archive is not shown.

Clarifications to the finished mockups:
- The equipment kind (the Picker in the "Equipment" sheet) is disabled if the equipment is used in at least one exercise. Next to it the caption "Used in N exercises".
- Step 2 of adding an exercise: the "Reps / Time" toggle is shown only for "Bodyweight". Barbells, dumbbells and machines always have the "Reps" metric (in the mockup the toggle is also on "Barbell").
- An archive confirmation text is needed for when the exercise is in no program day. For now the code says: "The exercise will disappear from the library. History will be kept."
- If "My gym" has several items of the needed kind, nothing is preselected in step 2 (the mockup marks the first bar).

## Tasks after the stage 4 discussion (18.11.2026)

**Done on the canvas on 18.11.2026** (the "Programs" row, the "18.11" block; each mockup has light, dark and AX1, alerts have light and dark):
- Creating a program — a sheet: name + first day (label and name). "Create" in the nav bar.
- Day — a "New day" sheet (from "+ Day") and a "Day" sheet for editing with "Delete day". Editing a day opens from "Edit" mode on the day screen: the "Name and label" row. The day delete alert: "The day and its exercises will be removed from the program. Workout history will be kept." (text proposed by the design).
- The day label is shown as a square badge before the name; days without a label have no badge.
- The program "…" menu — a system context menu: "Rename", "Delete". The delete alert uses the text from the brief. Renaming — the program creation sheet with only the name field (no separate mockup was drawn).
- Exercise targets in a day — a sheet with steppers: sets, reps "from / to", rest (15 s step), "Remove from day". A variant for a timed exercise — without reps.
- Exercise picker — a sheet with search and groups; already added ones are marked "in day" and disabled; "New" in the nav bar opens adding in 2 steps.
- "Edit" mode on the day screen — a red minus on the left, a ≡ handle on the right, "Done" in the nav bar.
- Empty states: a day without exercises (an "Add exercise" button), a program without days (text in the card and "+ Day").

The "Programs" mockups have the list, the empty state, the day screen and the "In day A · Sets / Reps" block in step 2 of adding an exercise. Program screens don't go into code until the mockups below exist. Each needs a light and dark theme and large Dynamic Type.

Mockups needed:
1. **Creating a program.** Name and first day: the empty state says "Start with one day", so a program is created right away with a day. Opened by the "Create program" button and "+" in the nav bar.
2. **Adding and editing a day.** Name (required, "Chest and triceps") and label (optional, up to 3 characters, "A"). Without a label the name is shown everywhere. Adding — the "+ Day" button under the program. Where editing and deleting a day come from — the design decides, e.g. "Edit" on the day screen. Deletion — with confirmation.
3. **The program "…" menu.** Rename and delete. Delete confirmation: "The program and its days will be deleted. Workout history will be kept."
4. **Exercise targets in a day** (tap on a row on the day screen; the hint is already in the mockup). Sets, reps "from – to" (a single number is allowed, "from" = "to"), rest. Timed exercises have no reps — only sets and rest. A "Remove from day" action.
5. **Picking an exercise for a day** (the "+ Exercise" button). The library with groups and search. Exercises already added to this day are marked and disabled. At the bottom or in the nav bar — "New exercise", which opens adding in 2 steps with the "In day A" block.
6. **"Edit" mode on the day screen.** Reordering and deleting rows.
7. **Empty states.** A day without exercises; a program without days (if the last day is deleted).

Clarifications to the finished mockups:
- An exercise is added to a day only once: the previous result and set prefill are computed per exercise, and with a duplicate it's unclear whose sets they are.
- An existing exercise from the library is added to a day right away with targets 3 × 8–12 and the exercise's rest, without an intermediate screen. Targets are edited by tapping the row.
- The captions "Mon 16.11" on a day and "next — B" on a program will appear together with the active workout. Before the first workout from a day — "not yet".
- The order of days and programs doesn't change for now: days are usually added in order.

## What the app does not have (don't add)

Music player and Apple Music integration, illustrations and animations of exercise technique, muscle groups, calories and nutrition, social networks and a feed, accounts and logins, subscriptions, ads, an AI coach, gamification with achievements, multi-screen onboarding, multiple gyms, buttons in the Live Activity, volume (tonnage) tracking, automatic backup, iPad and landscape.
