# Stage 1 — project skeleton (plan)

## Goal
An empty but properly structured app: project settings per the decisions, a local package with `Domain` and `DesignSystem`, real tokens and fonts from the design, three tabs with their own navigation stacks, tests, installation on the iPhone. No functionality and no DB (the DB is stage 2).

## Structure after the stage
```
sportplan.xcodeproj
sportplan/                         app target (synchronized folder)
  SportplanApp.swift               replaces MyApp.swift, registers fonts
  di/AppDIContainer.swift
  presentation/
    root/RootView.swift            TabView, three tabs
    navigation/Router.swift        protocol
    navigation/TabRouter.swift     @Observable, NavigationPath
    navigation/AppTab.swift
    workout/ui/...                 tab, stub screen, gear → settings
    programs/ui/...                tab, stub screen
    history/ui/...                 tab, stub screen
    settings/ui/...                stub screen
  Localizable.xcstrings            base language ru
sportplanTests/                    Swift Testing
Packages/SportplanKit/
  Package.swift                    swift-tools 6.2, iOS 26
  Sources/Domain/Weight.swift      first domain type: grams, Comparable, arithmetic
  Sources/DesignSystem/            Palette, Typography, Spacing, CornerRadius, FontRegistry, Fonts/*.ttf
  Tests/DomainTests/, Tests/DesignSystemTests/
```

## Steps
1. **Template settings** (editing `project.xcproj`):
   - bundle id `com.rgorbachev.sportplan`;
   - Swift 6;
   - iPhone only (`TARGETED_DEVICE_FAMILY = 1`, platforms iphoneos/iphonesimulator), portrait only;
   - remove `REGISTER_APP_GROUPS`, `ENABLE_APP_SANDBOX`, `ENABLE_USER_SELECTED_FILES`;
   - `IPHONEOS_DEPLOYMENT_TARGET = 26.0`;
   - development language `ru`;
   - delete `#Playground` and `ContentView.swift`.
   Check: the project builds.
2. **The `SportplanKit` package**:
   - `Domain` without default isolation; `Weight` with tests;
   - `DesignSystem` with MainActor by default, font resources and tests;
   - no UI strings in the package.
   Check: `swift test`.
3. **Fonts and tokens**:
   - download Unbounded and Onest from Google Fonts (OFL, together with the licenses). If only variable files are there, check that iOS picks the right weights correctly; if not, make static ones;
   - `FontRegistry` registers the fonts from the package bundle;
   - move the tokens over from `.design/system`:
     - `Palette` — dynamic colors for the light and dark themes, 15 tokens + 5 heatmap levels;
     - `Typography` — numeralHero/L/M/S, largeTitle, title, headline, body, callout, footnote, caption; via `Font.custom(_:size:relativeTo:)` and `.appStyle(_:)`, tabular numerals;
     - `Spacing` — 4…56;
     - `CornerRadius` — 6/14/20/28 and a circle;
   - a token catalog for `#Preview` to compare with the canvas.
4. **Manual step in Xcode** (the new project format is undocumented, so doing it by hand is more reliable): add the local package `Packages/SportplanKit`, link `Domain` and `DesignSystem` to the app, create the test target `sportplanTests` (Swift Testing). Claude will give step-by-step instructions.
5. **App skeleton**:
   - `SportplanApp`, `AppDIContainer` (an empty composition root for now);
   - `RootView` with a `TabView`: "Workout", "Programs", "History"; each tab has its own `TabRouter` and `NavigationStack(path:)`;
   - stub screens styled with tokens. ViewModel and the `XRoute`/`XScreen` pair come with the first feature; the stubs have no data;
   - the gear on "Workout" opens the settings stub through the tab's router;
   - strings in `Localizable.xcstrings`;
   - an app test: the router (push/pop) and building the container.
6. **Documents**: in `CLAUDE.md` — build and test commands, the actual structure; in the brief — what changed along the way.
7. **Check**:
   - build and run on the iOS 27 simulator: three tabs, navigation to settings, light and dark theme, large Dynamic Type;
   - with the user's permission, download the iOS 26 runtime and run there (it's several GB);
   - green `swift test` and app tests;
   - installation on the iPhone from a free account (signing, profile).
8. **Commit** after your review, in the CLAUDE.md format.

## Open for the future (not this stage)
- ~~Plate colors in the light and dark themes~~ — resolved by the design at stage 2: one color per plate, with a `separatorStrong` stroke.
