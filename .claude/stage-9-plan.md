# Этап 9: рекорды и графики — план

## Контекст
Этапы 0–8 в `main`. Следующий блок по `docs/code-brief.md` §7 — личные рекорды, график по упражнению и бейдж нового рекорда. Макеты: `.design/screens/ExerciseCard` (с оборудованием, свой вес, время, нет данных, крупный текст), `.design/system/HistoryKit` (06, 06a — график и рекорды, 07 — бейдж), `.design/system/WorkoutKit` (строка подхода с бейджем), `.design/system/Foundations` (анимация и haptic рекорда). Миграций нет: индексы `workout_exercise(exercise_id)` и `set_entry(workout_exercise_id)` уже есть.

Решения обсуждения (19.11.2026, `decisions.md` «Этап 9»):
- Карточка открывается из справочника (Программы → Справочник), путь из «Истории» — на этапе 11.
- Только выполненные рабочие подходы, рекорды считаются на лету.
- С оборудованием — макс. вес и 1ПМ по Эпли (до 12 повторов); свой вес — правило «никто раньше не был не хуже и по отягощению, и по повторам»; на время — макс. длительность.
- «До подхода» — по `completedAt`, включая текущую тренировку; равенство — не рекорд; без истории бейджа нет.
- График: лучшее значение тренировки, окно 8 недель до последней тренировки с упражнением, крупная цифра — последняя точка, дельта к первой точке окна.

## 9.1 Domain и data
**Domain (`Packages/SportplanKit/Sources/Domain/`)**
- `RecordProfile` (enum): `weighted` (оборудование + вес × повторы), `bodyweightReps`, `duration`; `init(loadKind:metric:)`.
- `EstimatedOneRepMax.make(weight:reps:) -> Weight?`: `w × (1 + reps / 30)`, при `reps == 1` — `w`, при `reps > 12` или `reps < 1` — `nil`. Результат в граммах (`Weight`), округление только при показе.
- `RecordBaseline` (struct): лучший вес, лучший 1ПМ, фронт подходов своего веса (пары отягощение × повторы, которые никто не превзошёл), лучшая длительность. `init(sets:profile:)`, `func isRecord(_ entry: SetEntry) -> Bool` (строго лучше хотя бы по одной метрике профиля; пустая база — `false`), `mutating func include(_ entry: SetEntry)`.
- `RecordSetDetector.recordSetIds(baseline:sets:) -> Set<UUID>`: проходит выполненные рабочие подходы по `completedAt`, отмечает рекорд и добавляет подход в базу.
- `ExerciseSession` (workoutId, `date` = `started_at` тренировки, выполненные рабочие подходы по `position`) и `ExerciseHistory` (`exercise: LibraryExercise`, `sessions`).
- `PersonalRecord` (kind, `entry: SetEntry`, `date`) и `PersonalRecordKind`: `maxWeight`, `estimatedOneRepMax`, `maxReps`, `maxWeightedReps` (наибольшее отягощение, при равенстве — больше повторов), `maxDuration`. `PersonalRecords.make(history:) -> [PersonalRecord]` в порядке карточки.
- `ProgressMetric`: `estimatedOneRepMax`, `maxWeight`, `maxReps`, `maxDuration`; `ProgressMetric.available(for: RecordProfile)`.
- `ProgressSeries.make(sessions:metric:) -> ProgressSeries`: точка на тренировку (лучшее значение; тренировка без подходящих подходов — без точки), окно 8 недель (`private static let`) до последней точки, `latest`, `delta` (nil при одной точке), отметка точек, в которых был рекорд по этой метрике.
- `ExerciseCard` (exercise, records, sessions с `recordSetIds`, `series: [ProgressMetric: ProgressSeries]`).
- `WorkoutRepository`: `observeExerciseHistory(exerciseId:) -> AsyncThrowingStream<ExerciseHistory?, any Error>` — все тренировки (и завершённые, и активная) с выполненными рабочими подходами упражнения, от новых к старым; `nil`, если упражнения нет.
- `ActiveWorkoutExercise` получает `recordBaseline: RecordBaseline` (по завершённым тренировкам) и вычисляемое `recordSetIds` через `RecordSetDetector`.
- Use case `ObserveExerciseCardUseCase.execute(exerciseId:) -> AsyncThrowingStream<ExerciseCard, any Error>`: наблюдение истории → `ExerciseCard`; `nil` → `ExerciseError.notFound` (добавить, если нет).
- Тесты (`DomainTests`):
  - 1ПМ: 1 повтор — вес, 12 — по формуле, 13 и 0 — `nil`.
  - `RecordBaseline` по трём профилям: равенство не рекорд; пустая база — не рекорд; 1ПМ бьёт рекорд при том же весе и большем числе повторов; свой вес — +5 × 10 после +15 × 6 и 14 повторов рекорд, +10 × 6 нет.
  - `RecordSetDetector`: порядок по `completedAt`, а не по `position`; второй подход первой тренировки бьёт первый; разминка не участвует.
  - `PersonalRecords`: состав по профилю, без подходов с отягощением строки нет, дата — дата тренировки рекорда.
  - `ProgressSeries`: лучшее значение тренировки, окно до последней точки, дельта, одна точка, тренировка без подходов до 12 повторов не даёт точки 1ПМ.

**Data (`sportplan/data/`)**
- `WorkoutRepositoryImpl.observeExerciseHistory` на `ValueObservation`: выполненные рабочие подходы по `exercise_id` с `JOIN workout`, группировка по тренировке в Swift; упражнение — через имеющийся `fetchLibraryExercises` (архивные тоже, для этапа 11).
- `fetchActive` заполняет `recordBaseline` для каждого упражнения: `SELECT DISTINCT weight_g, reps, duration_sec` по выполненным рабочим подходам завершённых тренировок.
- Тесты на in-memory базе: в истории только выполненные рабочие подходы, активная тренировка входит, чужие упражнения не входят, порядок, наблюдение видит новый подход; база рекордов активной тренировки не включает её саму.

## 9.2 Бейдж в тренировке
- `RecordBadge` в `DesignSystem/Components`: размер строки подхода (макет `HistoryKit` 07); заливка `Palette.record`, текст и иконка — тёмные в обеих темах (токен `onRecord`, если его нет — завести по `system/Color`). Размеры для итогов и истории — на этапе 11.
- `SetRowItem.isRecord`; `ActiveWorkoutUiMapper` берёт `recordSetIds`. Бейдж в строке выполненного подхода, как в `WorkoutKit`; VoiceOver кнопки — «Подход выполнен, новый рекорд».
- Анимация: `.transition(.scale(0.92).combined(with: .opacity))` при появлении бейджа после записи подхода, Reduce Motion — fade 150 мс.
- Haptic по `Foundations`: рекордный подход — `.success` вместо отклика записи. **Расхождение кода и макета:** сейчас запись подхода даёт `.success`, а по `Foundations` — `.impact(weight: .medium)`. Предлагаю привести к макету: обычный подход — `.impact(.medium)`, рекорд — `.success`. **Вопрос к ревью плана.**
- Live Activity без бейджа — в макете его нет.
- Тест: `WorkoutViewModelsTests` — подход сверх прошлого максимума получает `isRecord`, равный — нет.

## 9.3 Карточка упражнения (`presentation/exercisecard/`: `ui/`, `viewmodel/`, `models/`, `states/`, `navigation/`)
- `ExerciseCardDestination(exerciseId:)`, регистрируется в стеке вкладки «Программы». `LibraryScreen` получает `onOpenExercise`, строка справочника становится кнопкой (вид — по макету `ExerciseFlow`), свайп архивации остаётся.
- `ExerciseCardViewModel`: наблюдение `ObserveExerciseCardUseCase` из `.task`, `selectMetric(_:)`; `ExerciseCardUiData`:
  - шапка: название и строка «олимпийский гриф · повторы»;
  - график: подпись «Расчётный 1ПМ · 8 недель», крупное значение с единицей, дельта, точки, переключатель (только у `weighted`), фраза VoiceOver;
  - рекорды: название, значение («65 × 8», «82,3 кг», «+15 × 6», «2:10»), подпись (дата или «по Эпли»);
  - тренировки: дата («Пн 16 ноября»), подходы через «·», пометка «Рекорд».
- `ExerciseCardScreen` (`#Preview` по четырём состояниям): `ScrollView` с карточками на токенах; без данных — «—» `numeralL` и подсказка «Сделай первый подход — здесь появятся график и рекорды.».
- `ExerciseProgressChart` (Swift Charts): `LineMark` + `PointMark` цветом `accent`, без заливки; сетка `separator`, подписи осей `numeralS`; точка рекорда — `record` с обводкой; последняя точка подписана; касание — значение и дата в плашке через `chartOverlay`. Переключатель — системный сегментированный `Picker`.
- Крупный текст — по `CardAxLight`. Строки каталога — новые ключи `exerciseCard.*`, plural не нужен.
- Тесты `ExerciseCardViewModel`: состояния с данными и без, переключение метрики, подписи рекордов по трём профилям.

## Тесты и сборка
- `swift test` и `xcodebuild test` — зелёные, сборка без предупреждений.

## Проверка на симуляторе
- Историю за несколько недель для проверки вставляю в базу симулятора через `sqlite3` (в код не попадает).
- Тренировка: бейдж на рекордном подходе, нет бейджа при равенстве, бейдж пропадает после правки подхода вниз.
- Карточка из справочника: с оборудованием (переключатель, касание графика), свой вес, время, нет данных.
- Тёмная тема, крупный текст, VoiceOver (фраза графика, бейдж).

## Документы и коммиты
- Итоги → `decisions.md` («Этап 9: итоги реализации»); `roadmap.md` — этап 9 в «Готово».
- Коммиты по частям: 9.1 domain и data → 9.2 бейдж → 9.3 карточка (если части не собираются по отдельности — объединить и записать в итогах); от `Roman Gorbachev <romangorbachev2006@gmail.com>`, без упоминаний AI; сразу в `main` и push.
