# Этап 7: Live Activity и Dynamic Island — план

## Контекст
Этап 6 (таймер отдыха) в `main`. По `docs/code-brief.md` §5 — одна Live Activity на всю тренировку: стартует с тренировкой, кончается по «Завершить» / «Отменить», показывает упражнение и подход, во время отдыха — отсчёт через `Text(timerInterval:)`, `staleDate` = конец отдыха → «Отдых окончен». Кнопок нет. Макет — `.design/screens/LiveActivity.dc.html` (экран блокировки: подход / отдых / отдых окончен; Dynamic Island: компактный, минимальный, развёрнутый со стопкой блинов). Миграций нет.

Решения обсуждения (19.11.2026):
- Таргет расширения добавляю сам правкой `project.xcproj`, проверка — `xcodebuild`; если не выйдет встраивание или подпись — пользователь создаёт таргет мастером Xcode, остальное — я.
- `WorkoutActivityAttributes` — в новой библиотеке пакета `WorkoutActivity`, её линкуют оба таргета. Соответствие `ActivityAttributes` под `#if canImport(ActivityKit)` — согласованное исключение из правила «один `#if` в `Color(light:dark:)`», иначе пакет не соберётся на macOS для `swift test`.
- Приложение отдаёт в Live Activity готовые локализованные строки и даты; у виджета свой маленький каталог только для постоянных подписей.
- Live Activity следит за `ActiveWorkoutStore`, а не вызывается из use cases; при запуске приложения состояние сверяется.
- «Завершить» и «Отменить» убирают Live Activity сразу.
- Шрифты в расширении — риск: если регистрация из пакета не работает, системный шрифт с моноширинными цифрами.

## 7.1 Таргет расширения (каркас)
- Папка `sportplanLiveActivity/` (synchronized), таргет `sportplanLiveActivity`, `product-type` app extension, bundle id `com.rgorbachev.sportplan.LiveActivity`, тот же `DEVELOPMENT_TEAM`, iOS 26.0, Swift 6, MainActor по умолчанию.
- `Info.plist` расширения с `NSExtension` → `NSExtensionPointIdentifier = com.apple.widgetkit-extension` (исключить из ресурсов, если папка его подхватит).
- Приложение: зависимость от расширения, фаза встраивания расширений, `INFOPLIST_KEY_NSSupportsLiveActivities = YES`.
- Ключи встраивания и исключений — сверить со схемой `github.com/apple/xcode-project-format`: неизвестные ключи молча игнорируются.
- `SportplanLiveActivityBundle` (`@main`, `WidgetBundle`) с пустой `ActivityConfiguration`. Готово, когда приложение собирается, `.appex` лежит в `PlugIns/` и ставится на симулятор.

## 7.2 Общие типы, Domain, связка в приложении
**Пакет `SportplanKit`** — новая библиотека `WorkoutActivity` (зависит от `DesignSystem` только если понадобится `PlateStackItem`; по умолчанию без зависимостей):
- `WorkoutActivityAttributes` — статичные поля: `workoutId: UUID`, `startedAt: Date`; вложенный `ContentState` (`Codable`, `Hashable`, `Sendable`).
- `WorkoutActivityContent` (то же, что `ContentState`): `phase: WorkoutActivityPhase` (`.set` / `.rest` / `.finishedSets`), `exerciseName`, `setText` («подход 4 · 8–12 повт.»), `loadText` («65 × 8»), `nextText` («дальше 65 × 8»), `readyText` («Пора: жим лёжа, подход 4»), `restStartedAt` / `restEndsAt: Date?`, `plates: [WorkoutActivityPlate]` (`rgb`, `kilograms`).
- Соответствие `ActivityAttributes` — отдельный файл-расширение под `#if canImport(ActivityKit)`; остальные типы собираются везде.
- `WorkoutActivityController` — протокол (`Sendable`): `func show(attributes:content:staleDate:) async`, `func end() async`.

**Domain**
- `ActiveWorkout.currentSet: WorkoutSetReference?` — во время и после отдыха: `nextPlannedSet(after: restTrigger)`; без выполненных подходов — первый невыполненный по порядку; все выполнены — nil.
- Тесты: текущий подход до первого выполнения, после выполнения, по кругу, все выполнены.

**Data** — `data/activity/WorkoutActivityControllerImpl` (`nonisolated`, ActivityKit):
- `show`: если `ActivityAuthorizationInfo().areActivitiesEnabled == false` — ничего; ищет в `Activity<WorkoutActivityAttributes>.activities` активность с тем же `workoutId` → `update(ActivityContent(state:staleDate:))`, иначе завершает чужие и делает `Activity.request(... pushType: nil)`.
- `end`: завершает все с `dismissalPolicy: .immediate`.
- Ошибки ActivityKit не пробрасываются: Live Activity — необязательное отображение.

**Presentation** — `presentation/workout/activity/`:
- `WorkoutActivityMapper` — из `ActiveWorkoutSnapshot` и блинов делает `WorkoutActivityContent` и `staleDate` (= `rest.endsAt` при отдыхе, иначе nil); текст — через `WorkoutFormatting` и String Catalog приложения, блины — `PlateLoading` как в строке подхода.
- `WorkoutActivityCoordinator` (`@MainActor`, долгоживущий, в `AppDIContainer`): читает store через `Observations { }`, грузит блины через `LoadPlatesUseCase`, не шлёт повтор одинакового содержимого; `.active` → `show`, `.noWorkout` → `end`, `.loading` / `.error` → ничего. Старт из `.task` в `RootView` рядом с `observeActiveWorkout()`.
- `AppDIContainer`: `private lazy var` контроллер и координатор, `func observeWorkoutActivity() async`.
- Строки `activity.*` — в `Localizable.xcstrings` приложения.
- Тесты (app, Swift Testing): маппер — фазы, тексты, блины, `staleDate`; координатор с фейковым контроллером — показ при активной тренировке, обновление после подхода, без дублей, конец при завершении и отмене.

## 7.3 Вид Live Activity
`sportplanLiveActivity/`, зависит от `WorkoutActivity` и `DesignSystem`; `FontRegistry.registerFonts()` в `init` бандла.
- `WorkoutLiveActivity` (`Widget`, `ActivityConfiguration(for: WorkoutActivityAttributes.self)`).
- Экран блокировки (`WorkoutLockScreenView`): верхняя строка «Тренировка · 34:12» (`Text(timerInterval:)` от `startedAt`, вперёд); подход — упражнение, `setText`, `loadText`; отдых — «Отдых», отсчёт до `restEndsAt`, «Дальше» + `nextText`; `context.isStale` при отдыхе → «Отдых окончен», `readyText`, «прошло» с отсчётом вперёд от `restEndsAt`. Фон — `activityBackgroundTint(Palette.surface)`.
- Dynamic Island (всегда тёмные варианты токенов через `.environment(\.colorScheme, .dark)`):
  - компактный: слева значок состояния, справа одно значение (`loadText` / отсчёт / «Пора»);
  - минимальный: значок или кольцо отдыха (`ProgressView(timerInterval:)`);
  - развёрнутый: как экран блокировки + `PlateStack` в фазе подхода.
- `.finishedSets` (все подходы выполнены — в макете нет): упражнение не показываем, только «Тренировка · время» и «Подходы выполнены». Отмечу как вопрос к дизайну.
- Каталог расширения `sportplanLiveActivity/Localizable.xcstrings` (ru): «Тренировка», «Отдых», «Дальше», «Отдых окончен», «прошло», «Пора», «Подходы выполнены».
- `#Preview(as: .content, using: …)` для трёх состояний и островов.
- Доступность: лейблы отсчёта, Reduce Motion — без кольца-анимации.

## Файлы
- Проект: `sportplan.xcodeproj/project.xcproj`, новая папка `sportplanLiveActivity/`.
- Пакет: `Package.swift`, `Sources/WorkoutActivity/…`, `Sources/Domain/Model/ActiveWorkout.swift`, `Tests/DomainTests/…`.
- Приложение: `data/activity/`, `presentation/workout/activity/`, `presentation/root/RootView.swift`, `di/AppDIContainer.swift`, `Localizable.xcstrings`, `sportplanTests/presentation/…`.
- Документы: `CLAUDE.md` (новый таргет и библиотека), `.claude/decisions.ru.md` («Этап 7: итоги»), `.claude/roadmap.ru.md`.

## Проверка
- `swift test` в пакете и `xcodebuild test` — зелёные, без предупреждений.
- Симулятор (iPhone 18 Pro): старт тренировки → Live Activity на экране блокировки и в Dynamic Island; подход → отдых → отсчёт; −15 / +15 / «Пропустить» обновляют; развёрнутый остров со стопкой блинов; «Завершить» и «Отменить» убирают сразу; перезапуск приложения во время тренировки не плодит вторую активность; светлая и тёмная тема.
- На устройстве (нужен пользователь): подпись расширения бесплатным аккаунтом, «Отдых окончен» по `staleDate`, когда приложение спит, шрифты в расширении.
- Коммиты: 7.1 каркас таргета → 7.2 типы, Domain, связка → 7.3 вид; от `Roman Gorbachev <romangorbachev2006@gmail.com>`, без упоминаний AI; сразу в `main` и push.
