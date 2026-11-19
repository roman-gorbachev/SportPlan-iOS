# Этап 10: подсказка прогрессии — план

## Контекст
Этапы 0–9 в `main`. Следующий блок по `docs/code-brief.md` §8 — подсказка прогрессии в активной тренировке. Макеты: `.design/system/WorkoutKit` (08 «Подсказка прогрессии и заметка»), `.design/screens/WorkoutScreen` (подсказка под заголовком упражнения при «0 из 3»). Миграций нет: цели прошлой тренировки уже лежат в `workout_exercise` (`target_sets`, `target_reps_min`, `target_reps_max`).

Решения обсуждения (19.11.2026, `decisions.ru.md` «Этап 10»):
- Условие — по целям прошлой тренировки с упражнением: цели были, рабочих подходов ≥ целевого числа, в каждом повторов ≥ верхней границы.
- Только оборудование + вес × повторы; вес — макс. рабочий вес прошлой тренировки + шаг оборудования.
- Видна, пока есть невыполненный рабочий подход легче предложенного веса и подсказку не скрыли.
- «Поставить» — только вес во всех невыполненных рабочих подходах, одной транзакцией; крестик — до конца тренировки, в памяти ViewModel.

## 10.1 Domain и data
**Domain (`Packages/SportplanKit/Sources/Domain/`)**
- `ActiveWorkoutExercise` получает `previousWorkoutExercise: WorkoutExercise?` (цели прошлой тренировки; параметр init со значением `nil`, чтобы не трогать места создания в тестах и use cases старта).
- `ProgressionSuggestion` (enum со `static func`), чистый расчёт:
  - `weight(for exercise: ActiveWorkoutExercise) -> Weight?` — предложенный вес, если упражнение с оборудованием и метрикой вес × повторы, у прошлой тренировки есть `targetSets` и `targetReps`, рабочих подходов прошлой тренировки ≥ `targetSets` и в каждом `reps ≥ targetReps.max`; иначе `nil`;
  - вес = максимальный `weight` рабочих подходов прошлой тренировки + `equipment.weightStep`.
- `ActiveWorkoutExercise.progressionWeight: Weight?` — предложенный вес, если среди невыполненных рабочих подходов есть подход легче него; иначе `nil` (подсказка не нужна).
- `WorkoutRepository.updateSets(_ entries: [SetEntry])` — несколько подходов одной записью.
- `ApplyProgressionUseCase.execute(workoutExerciseId:)`: берёт активную тренировку, находит упражнение (`WorkoutError` при отсутствии), пересчитывает `progressionWeight` (UI не передаёт вес) и ставит его во все невыполненные рабочие подходы через `updateSets`. Если подсказки уже нет — ничего не делает.
- Тесты (`DomainTests`):
  - условие: без целей, подходов меньше цели, одному подходу не хватило повторов до верхней границы, разминка не считается ни в числе подходов, ни в весе, лишний подход сверх цели не мешает, одиночная цель (min == max);
  - профиль: свой вес, упражнения на время и оборудование без шага — `nil`;
  - вес — максимум рабочих подходов + шаг;
  - видимость: все невыполненные уже ≥ веса — `nil`; все выполнены — `nil`;
  - `ApplyProgressionUseCase`: меняются только невыполненные рабочие подходы, повторы и выполненные подходы не трогаются, разминка не трогается. `FakeWorkoutRepository` получает `updateSets`.

**Data (`sportplan/data/`)**
- `WorkoutRepositoryImpl.fetchActive` заполняет `previousWorkoutExercise`: та же выборка «последняя завершённая тренировка с выполненными подходами упражнения», что и в `fetchPreviousSets`; общий подзапрос выносится в одну функцию, чтобы «было» и подсказка всегда смотрели на одну тренировку.
- `updateSets` — `update` записей в одном `write`.
- Тесты на in-memory базе: цели прошлой тренировки приходят в активную, прошлая тренировка без целей даёт `nil` в целях, `updateSets` обновляет все подходы одной записью.

## 10.2 Подсказка в тренировке
- `ActiveExerciseItem` получает `progression: ProgressionHintItem?` (`weightText` «67,5 кг», `accessibilityLabel`). `ActiveWorkoutUiMapper` строит его из `progressionWeight`, если упражнения нет в списке скрытых.
- `ActiveWorkoutViewModel`: `@ObservationIgnored`-набор скрытых `workoutExerciseId`; действия `applyProgression(workoutExerciseId:)` → `ApplyProgressionUseCase`, `dismissProgression(workoutExerciseId:)` → добавить в набор и пересобрать UI из последнего снимка store (как при изменении блинов).
- `ActiveWorkoutUserAction`: `.applyProgression(workoutExerciseId:)`, `.dismissProgression(workoutExerciseId:)`.
- `ProgressionHintView` (`presentation/workout/active/ui/`): по `WorkoutKit` 08 — фон `Palette.surfaceSunken`, радиус `CornerRadius.field`, текст `Typography.body`, вес полужирным; «Поставить» — `accent`, кнопка-крестик `xmark` цветом `textSecondary`; обе кнопки ≥ 44pt. При accessibility-размерах текста — текст сверху, кнопки строкой под ним. VoiceOver: текст подсказки — один элемент, кнопки «Поставить» и «Скрыть подсказку». Появление и скрытие — `.opacity` (Reduce Motion — без анимации).
- Место — в `ActiveWorkoutScreen` под `ActiveExerciseHeader`, над подходами.
- Строки каталога: «В прошлый раз всё выполнено — попробуй **%@**» (вес полужирным через markdown в значении каталога), «Поставить», «Скрыть подсказку»; если markdown в интерполяции не сработает — две `Text` подряд.
- `AppDIContainer`: `applyProgressionUseCase`, передача в `buildActiveWorkoutViewModel`.
- Превью `ActiveWorkoutScreen` с подсказкой.
- Тесты `WorkoutViewModelsTests`: подсказка есть после выполненного плана; «Поставить» меняет вес невыполненных подходов и убирает подсказку; крестик убирает подсказку только у своего упражнения.

## Тесты и сборка
- `swift test` и `xcodebuild test` — зелёные, сборка без предупреждений.

## Проверка на симуляторе
- Историю прошлой тренировки с выполненным планом вставляю в базу симулятора через `sqlite3` (в код не попадает); старт тренировки по дню.
- Подсказка видна с весом «прошлый максимум + шаг»; «Поставить» меняет вес во всех невыполненных рабочих подходах, стопка блинов пересчитывается, подсказка пропадает; крестик скрывает.
- Нет подсказки: прошлый план не выполнен (один подход ниже верхней границы), вне плана, свой вес, на время.
- Тёмная тема, крупный текст (кнопки под текстом), VoiceOver.

## Документы и коммиты
- Итоги → `decisions.ru.md` («Этап 10: итоги реализации»); `roadmap.ru.md` — этап 10 в «Готово».
- Коммиты по частям: 10.1 domain и data → 10.2 подсказка (если части не собираются по отдельности — объединить и записать в итогах); от `Roman Gorbachev <romangorbachev2006@gmail.com>`, без упоминаний AI; сразу в `main` и push.
