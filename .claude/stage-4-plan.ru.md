# Этап 4: программы — план

Решения — в `.claude/decisions.ru.md` (раздел «Этап 4»), макеты — `.design/screens/ProgramsScreen`, `Prog*`, блок «В день A» в `ExerciseFlow`. Задачи дизайнеру — в `.design/design-brief.md` («Задачи после обсуждения этапа 4»).

Этап делится на две части:
- **4.1 — Domain и data программ.** Делается сейчас: от форм не зависит.
- **4.2 — экраны.** После макетов форм.

## 4.1 Domain и data

### Domain (`Packages/SportplanKit/Sources/Domain/`)
- **Модели (`Model/`):**
  - `ProgramSummary` — программа и её дни (`[ProgramDaySummary]`: день и число упражнений), дни по `position`; программы по `position`;
  - `ProgramDayDetail` — день, название программы, `[PlannedExerciseItem]` по `position`;
  - `PlannedExerciseItem` — `PlannedExercise` и `LibraryExercise` (упражнение с оборудованием, переиспользуем из 3.2);
  - `ProgramDraft` (name) и `ProgramDayDraft` (name, label) — trim, пустая метка сохраняется как `nil`, `validationIssues`; длина метки ≤ 3 символов (`private static let`);
  - `PlannedExerciseTargets` (sets, reps: `RepRange?`, restSeconds): `init(defaultsFor: Exercise)` — 3 × 8–12 для повторов, `reps = nil` для времени; валидация: подходы 1…10, повторы 1…100, у упражнения на время повторов нет, отдых в границах упражнения;
  - `ProgramValidationIssue`, `PlannedExerciseValidationIssue`, `ProgramError` (`invalidDraft`, `invalidTargets`, `notFound`, `exerciseAlreadyInDay`, `exerciseUnavailable`).
- Границы и шаг отдыха (0…600 с, шаг 15) сейчас `private` в `ExerciseDraft`. Переношу их в `Exercise` как `public static let` рядом с `defaultRestSeconds`, чтобы `ExerciseDraft` и `PlannedExerciseTargets` брали одни значения.
- **`Repository/ProgramRepository`:**
  - `observePrograms() -> AsyncThrowingStream<[ProgramSummary], any Error>`;
  - `observeDay(id:) -> AsyncThrowingStream<ProgramDayDetail?, any Error>`;
  - `createProgram(_ program: Program, firstDay: ProgramDay)` — одна транзакция;
  - `renameProgram(id:name:)`, `deleteProgram(id:)`;
  - `addDay(_ day: ProgramDay)`, `updateDay(id:name:label:)`, `deleteDay(id:)`;
  - `addPlannedExercise(_:)` — в транзакции проверяет дубль и бросает `exerciseAlreadyInDay`;
  - `updateTargets(id:targets:)`, `removePlannedExercise(id:)`, `reorderPlannedExercises(dayId:orderedIds:)`.
  - `position` новой записи (программы, дня, упражнения в дне) считается в репозитории внутри транзакции как max + 1; модель приходит с любым `position`, он перезаписывается. Поэтому `createProgram`, `addDay` и `addPlannedExercise` возвращают сохранённую модель.
  - `plannedExercise(id:)` — для проверки целей по метрике упражнения.
- **Use cases (`UseCase/Program/`), у каждого один `execute`:**
  - `ObserveProgramsUseCase`, `ObserveProgramDayUseCase`;
  - `CreateProgramUseCase(program: ProgramDraft, firstDay: ProgramDayDraft)` → `Program`, новые UUID, часы из init;
  - `RenameProgramUseCase`, `DeleteProgramUseCase`;
  - `AddProgramDayUseCase`, `UpdateProgramDayUseCase`, `DeleteProgramDayUseCase`;
  - `AddExerciseToDayUseCase(exerciseId:dayId:targets:)`: нет targets → значения по умолчанию из упражнения; упражнение не найдено или в архиве → `exerciseUnavailable`; для нового упражнения в контексте дня presentation вызывает `CreateExerciseUseCase`, затем этот use case с targets из блока «В день A»;
  - `UpdatePlannedExerciseTargetsUseCase` (валидирует по метрике упражнения), `RemovePlannedExerciseUseCase`, `ReorderPlannedExercisesUseCase`.
  - Упражнение для проверки берётся из `ExerciseRepository` — добавить `exercise(id:) async throws -> Exercise?`.
- **Тесты (`DomainTests`):** `FakeProgramRepository` на `Mutex`; `ProgramDraft`/`ProgramDayDraft` (trim, пустая метка, длина); `PlannedExerciseTargets` (значения по умолчанию по метрике, границы, повторы у упражнения на время отклоняются); `CreateProgramUseCase`; `AddExerciseToDayUseCase` (архивное, дубль, значения по умолчанию); `UpdatePlannedExerciseTargetsUseCase`.

### Data (`sportplan/data/repositories/ProgramRepositoryImpl.swift`)
- `nonisolated final class ProgramRepositoryImpl: ProgramRepository`, поверх `AppDatabase`, тот же паттерн наблюдения, что в `ExerciseRepositoryImpl` / `EquipmentRepositoryImpl` (`ValueObservation` → `AsyncThrowingStream`, `id.databaseText` в фильтрах).
- Список программ: программы, дни и `COUNT(*)` из `planned_exercise` по дню одним наблюдением. День: день, программа, упражнения дня с упражнением и оборудованием (как `observeLibrary`).
- Удаление полагается на CASCADE схемы v1; `workout.program_day_id` уходит в NULL, копии названия остаются (это уже проверяют `SchemaConstraintTests`).
- Новых миграций нет: запрет дубля проверяется в транзакции, не уникальным индексом.
- `ExerciseRepositoryImpl.exercise(id:)`.
- **Тесты (`sportplanTests/data/ProgramRepositoryImplTests`):** создание программы с первым днём и порядок; число упражнений в днях; наблюдение дня с упражнениями и оборудованием по порядку; дубль отклоняется; перестановка переписывает `position`; удаление программы удаляет дни и упражнения дней, тренировка остаётся с копией названия.

## Сделано в 4.1 (18.11.2026)
- Domain: модели, `ProgramRepository`, 12 use cases, тесты (62 теста пакета зелёные).
- Data: `ProgramRepositoryImpl`, `ExerciseRepositoryImpl.exercise(id:)`, 9 новых тестов (61 тест приложения зелёный).
- DI-регистрации нет: репозиторий и use cases подключаются вместе с экранами в 4.2.

## 4.2 Экраны (макеты 18.11.2026: `ProgramsScreen`, `ProgramsFlow`, блок «В день A» в `ExerciseFlow`)

### Domain (дополнение)
- `PlannedExerciseTargets` получает шаги для степперов, как у отдыха в `ExerciseDraft`: `canIncrement…` / `increment…` / `decrement…` для подходов, повторов «от» и «до» и отдыха. «от» выше «до» тянет «до» за собой, «до» ниже «от» тянет «от». Тесты на границы и подтягивание.

### Вкладка «Программы» (`programs/`)
- `ProgramsViewModel` наблюдает программы и число упражнений справочника.
- `ProgramsScreen` — `List`:
  - строка «Справочник упражнений N»;
  - секция на программу: строка заголовка (название, «3 дня» плюрал или «нет дней», `Menu` «…» с «Переименовать» и «Удалить»);
  - строки дней: квадратный бейдж метки (если есть), название, «5 упражнений» плюрал, шеврон;
  - у программы без дней — текст «Дней пока нет…»;
  - строка «+ День».
- Пустое состояние: «Программ пока нет», текст из макета, «Создать программу» (`EmptyStateView`) плюс строка справочника сверху.
- «+» в навбаре и «Создать программу» открывают лист программы; «Удалить» — алерт с текстом из брифа.
- `program/form/`: `ProgramFormRoute` / `ProgramFormViewModel` / `ProgramFormScreen`. Цель `.create` — название и первый день (метка + название, подписи из макета), «Создать». Цель `.rename(id:name:)` — только название, «Готово».
- `day/form/`: `ProgramDayFormRoute` / `ViewModel` / `Screen`. Цель `.new(programId:programName:)` — «Новый день», «Добавить». Цель `.edit(day:programName:)` — «День», «Готово», «Удалить день» с алертом из макета.

### Экран дня (`programs/day/`)
- `ProgramDayDestination(dayId:)`, `ProgramDayRoute` / `ViewModel` / `Screen`.
- Заголовок — название дня, подзаголовок `navigationSubtitle` «Сила 3× · A».
- Строки: название, «4 × 8–12» (или «3 подхода» у упражнений на время), «отдых 2:00 · олимпийский гриф» / «отдых 1:30 · свой вес» / «на время · отдых 1:00».
- Строка «+ Упражнение» открывает выбор; подсказка внизу из макета.
- «Править» / «Готово» в навбаре переключают `editMode`: сверху строка «Название и метка» (открывает лист дня), у строк системные минус и ручка (`onDelete` / `onMove`). Удаление из дня без подтверждения: это не история.
- Пустой день: «В дне пока нет упражнений», текст, «Добавить упражнение».
- Если день удалён (наблюдение вернуло `nil`), экран закрывается.
- Тап по строке открывает лист целей.

### Лист целей (`programs/day/goals/`)
- Заголовок — название упражнения, подпись «Цели в дне A · Грудь и трицепс».
- Степперы `ValueStepper`: подходы; повторы «от» и «до» (только у повторов) с подписью «Одно число…»; отдых с подписью «Шаг 15 с. У упражнения по умолчанию 1:30 — здесь только для этого дня.». Для упражнений на время — подпись о секундомере.
- «Отмена» / «Готово»; «Убрать из дня» — красная кнопка внизу, без подтверждения.

### Выбор упражнения (`programs/day/picker/`)
- Лист «В день A»: поиск, подсказка из макета, группы справочника. Строка: название и оборудование (у своего веса — метрика); уже добавленные — серые, «в дне», неактивны.
- Тап добавляет упражнение с целями по умолчанию.
- «Новое» в навбаре открывает добавление в 2 шага с контекстом дня.
- Пустой справочник — пустое состояние с «Новое».

### Добавление упражнения в контексте дня (`library/add/`)
- `AddExerciseTarget` получает контекст дня (`dayId`, подпись «В день A · Грудь и трицепс»).
- В шаге 2 появляется секция с этой подписью: степперы подходов и повторов (у упражнений на время — только подходы). В макете там строки-ссылки, но экрана, куда они ведут, нет, — беру те же степперы, что в листе целей.
- «Добавить» создаёт упражнение (`CreateExerciseUseCase`) и сразу ставит его в день (`AddExerciseToDayUseCase`) с этими целями и отдыхом упражнения.

### Общее
- Формат целей и строк дня — `common/formatting/PlannedExerciseFormatting` («4 × 8–12», «3 подхода»).
- DI: `programRepository`, use cases программ, фабрики ViewModel.
- Строки — в String Catalog, плюралы «N дней», «N упражнений», «N подходов».
- Тесты ViewModel: лист программы (создать неактивно без названия, переименование), лист дня (метка длиннее 3 недоступна), лист целей (повторы «от»/«до» тянут друг друга, у времени нет повторов, сохранение), выбор (добавленные отмечены, тап добавляет), добавление в контексте дня ставит упражнение в день.

### Проверка 4.2
- `swift test`, `xcodebuild test`.
- Симулятор: пусто → создать программу с днём → день → «+ Упражнение» → выбор (существующее, затем «Новое» с целями) → цели (4 × 8–12, отдых) → «Править»: порядок, удаление, «Название и метка», удаление дня → «…»: переименовать, удалить. Светлая и тёмная тема, крупный текст.

## Не входит
- «Следующий день» и дата последней тренировки дня — этап 5.
- Порядок дней и программ.

## Проверка
- `swift test` и `xcodebuild test` зелёные.
- 4.1: экранов нет, в симуляторе проверять нечего.
- Коммиты блоками: документы → Domain → data.
