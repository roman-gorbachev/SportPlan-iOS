# Этап 11. История и heatmap — план

## Контекст
Следующий этап по roadmap. Вкладка «История» сейчас заглушка (`history/ui/HistoryScreen.swift` → `StubContent`). Объём — `docs/code-brief.md` §9 и раздел «Структура UI»: heatmap в стиле GitHub, список тренировок, детали тренировки, карточка упражнения. Макеты — `.design/screens/HistoryScreen.dc.html` (состояния list / empty / workout / ax) и `.design/system/HistoryKit.dc.html`.

Решено с пользователем:
- Тап по дню: одна тренировка — сразу детали; несколько — push экрана дня со строками этих тренировок.
- Меню «…» в деталях — только «Удалить тренировку» с подтверждением. Рекорды и графики пересчитываются сами, потому что считаются из истории.
- Список под heatmap — все завершённые тренировки, сгруппированы по месяцам, без пагинации.

После одобрения план копируется в `.claude/stage-11-history-plan.md`, решения — в `decisions.md` («Этап 11: обсуждение»). Коммиты по частям в `main`, push.

## Мои решения по пробелам макета (записать в decisions)
- Скругление ячейки: `HistoryKit` даёт 5, документ Type — 6. Берём токен `CornerRadius.chip` (6), отдельный токен под 5 не заводим. Размер 18, зазор 3, свотчи легенды 14 — `private static let` в компоненте.
- Считаются только завершённые тренировки (`finished_at IS NOT NULL`). Активная тренировка в heatmap и список не попадает.
- Заметка тренировки показывается в деталях только для чтения, если она есть (отдельной карточкой после упражнений).
- Тренировка вне плана: в строке «Пн 16 · Вне плана», в деталях заголовок «Тренировка вне плана».
- Строка подхода с собственным весом — `WorkoutFormatting.setSummary` (как в карточке упражнения: «+10 × 8» / «12»).
- Кнопка «Начать тренировку» в пустом состоянии переключает на вкладку «Тренировка» (как `onCreateProgram` в `RootView`).
- Рекорды в строке и деталях: подход-рекорд — тот, что побил всё, что было до него по этому упражнению. Это то же правило, что у бейджа в тренировке (`RecordBaseline`), применённое к истории по хронологии.

## Часть 1. Domain (`Packages/SportplanKit/Sources/Domain`)
- Модели:
  - `FinishedWorkout` — `workout: Workout`, `programName: String?`, `exercises: [FinishedWorkoutExercise]`.
  - `FinishedWorkoutExercise` — `item: WorkoutExercise`, `exercise: LibraryExercise`, `sets: [SetEntry]` (только выполненные, по `position`).
- Расчёты:
  - `WorkoutRecords.make(workouts:) -> [UUID: Set<UUID>]` (id тренировки → id подходов-рекордов). По каждому упражнению идёт хронологически через `RecordBaseline` (`isRecord`, `include`, `RecordProfile` из `LibraryExercise.recordProfile`). Учитываются только рабочие подходы (`RecordBaseline.counts`).
  - `HeatmapLevel` — 5 уровней, пороги 6/12/18 как `private static let`.
  - `Heatmap`, `HeatmapWeek`, `HeatmapDay` (`date`, `workingSetCount`, `level`, `isToday`, `isFuture`, `workoutIds`).
  - `HeatmapBuilder.make(workouts:today:calendar:)` строит 15 недель с понедельника, группируя по локальному дню. Календарь копируется с `firstWeekday = 2`. Число недель и `firstWeekday` — константы.
- `HistoryOverview` — `heatmap`, `entries: [HistoryEntry]` (новые сверху), где `HistoryEntry` — `workout`, `workingSetCount`, `recordCount`.
- Репозиторий: в `WorkoutRepository` добавляются `observeFinished() -> AsyncThrowingStream<[FinishedWorkout], any Error>` и `deleteFinished(workoutId:)`.
- Use cases:
  - `ObserveHistoryUseCase(repository:now:calendar:)` возвращает поток `HistoryOverview`.
  - `ObserveFinishedWorkoutUseCase(repository:)` возвращает поток `FinishedWorkoutDetail?` (тренировка, рекорды, число рабочих подходов). Берёт тот же поток, что и история, потому что рекорды зависят от всего, что было раньше; `nil` значит, что тренировку удалили.
  - `DeleteWorkoutUseCase(repository:)`.
  - Тот же образец `now`/`calendar`, что в `LoadWorkoutPreviewUseCase`.
- Тесты (`Tests/DomainTests`):
  - `HeatmapBuilderTests`: границы уровней 0/1/6/7/12/13/18/19; разминка не считается; две тренировки в один день; сегодня и будущие дни; первая колонка начинается с понедельника; смена месяца.
  - `WorkoutRecordsTests`: первая сессия даёт рекорд при наличии истории по правилу baseline; повтор рекорда — не рекорд; разные профили.
  - Тесты use cases на `FakeWorkoutRepository` (новые методы и поток завершённых).

## Часть 2. Data (`sportplan/data/repositories/WorkoutRepositoryImpl.swift`)
- `observeFinished` через `database.stream(of:)`. Внутри:
  - `WorkoutRecord` с `finished_at IS NOT NULL`, по `started_at DESC`;
  - `workout_exercise` и выполненные `set_entry` одним запросом на всё;
  - `fetchLibraryExercises(db, ids:)` (уже есть);
  - имя программы — LEFT JOIN `program_day` → `program`, `nil` если день удалён.
- `deleteFinished` удаляет `workout` с `finished_at IS NOT NULL` (каскад уже есть).
- Тесты в `sportplanTests/data/WorkoutRepositoryImplTests.swift` через `DatabaseFixtures`: активная тренировка не попадает; невыполненные подходы не попадают; порядок; удаление не трогает активную.

## Часть 3. Presentation — список и heatmap (`sportplan/presentation/history/`)
- DesignSystem: `HeatmapGrid` (компонент из `HistoryKit`). Принимает недели уровней и подписи, обводка «сегодня» — `ink` 2pt, будущее — контур `separator`, легенда. Цвета берёт из `Palette.heatmapLevels`. Компонент только рисует и отдаёт тап по дню замыканием.
- Список:
  - `HistoryRoute` / `HistoryScreen` / `HistoryViewModel` (`historyUiState`), `HistoryUiData`.
  - Модели: `HistoryMonthSection`, `HistoryWorkoutItem` (заголовок «Пн 16 · День A · Грудь и трицепс», мета «48 мин · 17 подходов», число рекордов, VoiceOver), `HeatmapItem` (подписи месяцев, accessibility «13 ноября, 19 и больше подходов» / «, сегодня» / «, впереди»).
  - `HistoryUiMapper`; форматирование дат — по образцу `ExerciseCardFormatting`.
- Экран:
  - заголовок «История»;
  - карточка heatmap («15 недель» и «N тренировок» / «пока пусто», месяцы, Пн/Ср/Пт, легенда «0 … 19+ подходов»);
  - секции месяцев («НОЯБРЬ»), строки в карточке с точкой `record` и счётчиком, шеврон.
- Пустое состояние: heatmap со всеми ячейками на уровне 0, «Здесь будут твои тренировки», «Запиши первую — она появится в календаре и в списке.», кнопка «Начать тренировку».
- AX: размеры шрифтов растут через токены `Typography`; сетка фиксированная, как в макете.
- Навигация:
  - `HistoryWorkoutDestination(workoutId:)`, `HistoryDayDestination(date:)`.
  - Тап по дню: 0 тренировок — ничего не происходит; 1 — детали; больше — экран дня.
  - `HistoryDayRoute` / `HistoryDayScreen` показывает заголовок даты и те же строки; данные — из `ObserveHistoryUseCase`, фильтр по дню во ViewModel.
- `HistoryTabView` получает `container` (правка в `RootView`) и `onStartWorkout`. Регистрирует `HistoryWorkoutDestination`, `HistoryDayDestination` и `ExerciseCardDestination` — тот же блок `ExerciseCardRoute`, что в `ProgramsTabView` / `WorkoutTabView`.
- Заглушку `HistoryScreen` (`stub.history`) заменить; ключ удалить, если больше нигде не используется.

## Часть 4. Presentation — детали тренировки (`history/workout/`)
- `WorkoutDetailsRoute` / `WorkoutDetailsScreen` / `WorkoutDetailsViewModel`.
- Содержимое:
  - мета «Пт 13 ноября · 18:05–18:57 · День C»;
  - заголовок — имя дня или «Тренировка вне плана»;
  - три плитки «Время / Подходы / Рекорды»; плитка рекордов на `record` / `onRecord`, только когда рекорды есть, иначе обычная;
  - карточки упражнений: заголовок с целью («4 × 5», «3 × 6–8», «2 подхода»), тап открывает карточку упражнения;
  - строки подходов: номер, значение `numeralS`, чип «разминка» (`textSecondary`), `RecordBadge` для рекордов;
  - карточка заметки.
- Тулбар: `Menu` «…» → «Удалить тренировку» → `confirmationDialog` с текстом «Тренировка и её подходы будут удалены. Рекорды и графики пересчитаются.» → `DeleteWorkoutUseCase` → pop.
- Если поток вернул `nil` (тренировку удалили), Route делает pop.
- DI (`AppDIContainer`): use cases как `private lazy var`; `buildHistoryViewModel()`, `buildHistoryDayViewModel(date:)`, `buildWorkoutDetailsViewModel(workoutId:)`.
- Строки: новые ключи `history.*` в `Localizable.xcstrings` (ru). «N тренировок», «N подходов», «N рекорд(а/ов)» — плюралы one/few/many/other.

## Порядок коммитов
1. Domain и data: модели, heatmap, рекорды, use cases, репозиторий и тесты.
2. Список и heatmap: компонент, экран, пустое состояние, экран дня.
3. Детали тренировки: экран и удаление.
4. Документы: decisions «Этап 11: итоги», roadmap — этап 11 в «Сделано».

## Проверка
- `cd Packages/SportplanKit && swift test` и `xcodebuild test …` (фоном) — зелёные.
- Симулятор, на копии базы (снимок до проверки, потом восстановить):
  - heatmap: уровни, сегодня, месяцы;
  - тап по дню: одна тренировка — детали, две — экран дня;
  - список по месяцам с рекордами;
  - детали: разминка, рекорды, время, заметка, тап → карточка упражнения;
  - удаление: возврат, ячейка и список обновились;
  - пустое состояние → вкладка «Тренировка»;
  - тёмная тема, крупный текст, VoiceOver-подписи ячеек.
