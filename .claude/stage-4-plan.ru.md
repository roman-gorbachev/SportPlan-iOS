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

## 4.2 Экраны (после макетов, кратко)
- `programs/`: список программ с днями и числом упражнений, пустое состояние, создание программы с первым днём, меню «…» (переименовать, удалить), «+ День».
- `programs/day/`: экран дня, «Править» (перестановка, удаление), sheet целей, правка и удаление дня.
- Выбор упражнения для дня на основе справочника из 3.2: уже добавленные неактивны, «Новое упражнение» открывает 2 шага с блоком «В день A · Подходы / Повторы».
- DI-фабрики, строки, тесты ViewModel форм.
- Подробный план — после макетов.

## Не входит
- «Следующий день» и дата последней тренировки дня — этап 5.
- Порядок дней и программ.

## Проверка
- `swift test` и `xcodebuild test` зелёные.
- 4.1: экранов нет, в симуляторе проверять нечего.
- Коммиты блоками: документы → Domain → data.
