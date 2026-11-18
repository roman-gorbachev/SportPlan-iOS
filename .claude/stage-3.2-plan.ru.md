# Этап 3.2: справочник упражнений — план

Решения — в `.claude/decisions.ru.md` (разделы «Этап 3» и «Этап 3.2»), макеты — `.design/screens/ExerciseFlow`, `Library*`, `LibEmpty*`, `AddType*`, `AddDetails*`, `ArchiveLight`. Паттерн и общие компоненты — из 3.1.

## Объём
Входит:
- строка «Справочник упражнений N» на вкладке «Программы»;
- экран «Упражнения»: группы, пустое состояние с чипами, swipe «Архивировать» с подтверждением;
- sheet «Новое упражнение» в 2 шага, «Новый гриф» через редактор из 3.1.

Не входит:
- правка упражнения и раздел «Архив» — ждут макетов;
- блок «В день A · Подходы» и остальное на вкладке «Программы» — этап 4;
- тап по строке справочника: пока ничего не делает, шеврона нет.

## Domain (`Packages/SportplanKit/Sources/Domain/`)
- **Модели:**
  - `ExerciseLoadKind` — выбор шага 1: `.equipment(EquipmentKind)` / `.bodyweight`. Не хранится: выводится из оборудования упражнения;
  - `ExerciseCategory` — группы справочника: `freeWeight` (гриф, гантели), `machine` (с блинами, блочный), `bodyweight`; `init(loadKind:)`;
  - `LibraryExercise` — упражнение плюс его оборудование (`Equipment?`, может быть архивным: подпись в строке всё равно нужна);
  - `ExerciseLibrary` — секции `[ExerciseCategory: [LibraryExercise]]` в порядке групп, внутри по названию (`localizedStandardCompare`), плюс `count`;
  - `QuickExercise` — 7 чипов: `benchPress`, `squat`, `deadlift`, `pullUp`, `dip`, `legPress`, `plank`, у каждого `loadKind` и `metric`. Названия — в presentation через String Catalog;
  - `ExerciseDraft` — name, loadKind, equipmentId?, metric, restSeconds, description:
    - `validationIssues`: пустое название, нет оборудования у вида с оборудованием, «Время» не у собственного веса, отдых вне 0…600 с;
    - границы и шаг отдыха (15 с) — `private static let`; отдых по умолчанию — `Exercise.defaultRestSeconds`;
    - пустое после trim описание сохраняется как `nil`;
  - `ExerciseError`: `invalidDraft`, `equipmentUnavailable` (нет, архивное или другого вида), `notFound`.
- **`Repository/ExerciseRepository`:**
  - `observeLibrary() -> AsyncThrowingStream<[LibraryExercise], any Error>` — активные упражнения с оборудованием;
  - `create(_ exercise: Exercise) async throws`;
  - `programDayCount(usingExerciseId:) async throws -> Int` — число разных дней, где есть упражнение;
  - `archive(id:) async throws` — в одной транзакции `is_archived = 1` и удаление строк `planned_exercise` этого упражнения.
- **Use cases** (`UseCase/Exercise/`), у каждого один `execute`:
  - `ObserveExerciseLibraryUseCase` → `ExerciseLibrary`;
  - `ObserveEquipmentChoicesUseCase(kind:)` → активное оборудование вида; поверх `EquipmentRepository.observeActive()`, чтобы «Новый гриф» сразу появился в списке;
  - `CreateExerciseUseCase(draft:)` → `Exercise`: валидирует; проверяет, что оборудование есть, активно и нужного вида; новый UUID и `createdAt` от часов из init;
  - `CountProgramDaysUsingExerciseUseCase(id:)`;
  - `ArchiveExerciseUseCase(id:)`.
- **Тесты** (`DomainTests`):
  - `FakeExerciseRepository` на `Mutex`, `FakeEquipmentRepository` из 3.1;
  - `ExerciseDraft`: валидация, «Время» только у собственного веса, trim названия и описания, границы отдыха;
  - `CreateExerciseUseCase`: нет оборудования, архивное, другого вида; собственный вес без оборудования;
  - `ObserveExerciseLibraryUseCase`: группы и порядок; `QuickExercise`: 7 чипов, у «Планки» время, у остальных повторы.

## Data (`sportplan/data/repositories/`)
- **`ExerciseRepositoryImpl`** (`nonisolated`, `AppDatabase`):
  - библиотека — `ValueObservation` по `exercise` с LEFT JOIN `equipment` (ассоциация `belongsTo` в `ExerciseRecord`), фильтр `is_archived = 0`, маппинг через `toDomainModel()`;
  - `programDayCount` — `COUNT(DISTINCT program_day_id)` по `planned_exercise`;
  - `archive` — одна транзакция `write`.
- **Тесты** (`sportplanTests/data/ExerciseRepositoryImplTests`):
  - наблюдение выдаёт новое упражнение и не выдаёт архивное;
  - у упражнения с архивным оборудованием оборудование всё равно приходит;
  - `programDayCount` считает разные дни, а не строки;
  - архивация удаляет `planned_exercise`, но не трогает `workout_exercise` и подходы.

## Presentation (`sportplan/presentation/`)
- **`programs/`:** `ProgramsRoute` + `ProgramsViewModel` (наблюдает `ObserveExerciseLibraryUseCase`, берёт `count`); `ProgramsScreen` — строка `NavigationRow` «Справочник упражнений» с числом, ниже прежняя заглушка. `ProgramsTabView` получает контейнер и регистрирует `LibraryDestination`.
- **`library/`:** `LibraryDestination`, `LibraryRoute`, `LibraryViewModel`, `LibraryScreen`.
  - Заголовок «Упражнения», в тулбаре «+» («Новое упражнение»).
  - Группы «Свободный вес» / «Тренажёры» / «Собственный вес», строка: название и «оборудование · метрика» («олимпийский гриф · повторы», у своего веса — «повторы» / «время»).
  - Поиск (`.searchable`, «Поиск») по названию без учёта регистра и диакритики — см. вопросы ниже.
  - Swipe «Архивировать»: ViewModel запрашивает число дней, затем `confirmationDialog`:
    - N > 0 — «Архивировать «X»?» / «Упражнение будет убрано из N дней программ. История сохранится.» (плюрал);
    - N = 0 — «Упражнение пропадёт из справочника. История сохранится.»
  - Пустое состояние: «Справочник пуст», текст из макета, 7 чипов с «+», кнопка «Своё упражнение».
- **`library/add/`:** `AddExerciseTarget` (`.blank` / `.quick(QuickExercise)`), `AddExerciseRoute`, `AddExerciseViewModel` (один на оба шага), `AddExerciseTypeScreen`, `AddExerciseDetailsScreen`.
  - Sheet с `NavigationStack(path:)`: шаг 1 — корень, шаг 2 — push. Чип открывает sheet с уже заполненным путём, «Назад» («Тип») ведёт на шаг 1.
  - Шаг 1 «Чем делаешь?», «1 из 2»: «Свободный вес» (Штанга, Гантели), «Тренажёр» (С блинами, Блочный), «Без оборудования» (Собственный вес) с подписями из макета.
  - Шаг 2: в навбаре «Тип» / вид / «Добавить» (неактивна, пока черновик невалиден):
    - «Название»;
    - «Оборудование · мой зал» — radiogroup с весами («20 · 2,5»), плюс «Новый гриф» / «Новые гантели» / «Новый тренажёр»; одно подходящее выбрано сразу, несколько — ничего;
    - «Метрика» «Повторы / Время» — только у собственного веса;
    - «Отдых» — степпер ±15 с в пределах 0:00–10:00, по умолчанию 1:30;
    - «Описание» — многострочное, необязательное.
  - «Новый …» открывает `EquipmentEditorRoute` из 3.1 вторым sheet с `.new(kind:)`; `onSaved` выбирает новое оборудование.
  - Смена вида на шаге 1 сбрасывает выбранное оборудование; метрика у видов с оборудованием становится «Повторы».
- **`common/formatting/RestFormatting`** — «1:30» и VoiceOver-значение «1 минута 30 секунд».
- **Строки**: все подписи, названия чипов, виды шага 1, плюралы «N дней программ».
- **Тесты ViewModel** (`AddExerciseViewModel`): автовыбор единственного оборудования и отсутствие выбора при нескольких; выбор нового после «Новый …»; заполнение из чипа; сброс при смене вида; границы степпера; доступность «Добавить».

## DesignSystem
- `ChipButtonStyle` — чип с «+» (поверхность `surface`, текст `accent`, высота ≥ 44 pt).
- `ValueStepper` — значение и кнопки −/+ (зоны ≥ 44 pt, `accessibilityAdjustableAction`); понадобится и в тренировке.
- Оба — в `TokenCatalogView`.

## DI
- `AppDIContainer`: `private lazy var exerciseRepository` и use cases; фабрики `buildProgramsViewModel()`, `buildLibraryViewModel()`, `buildAddExerciseViewModel(target:)`.
- `RootView` передаёт контейнер в `ProgramsTabView`.

## Проверка
- `swift test` и `xcodebuild test` зелёные.
- Симулятор:
  - «Программы» → «Справочник упражнений 0» → пустое состояние;
  - чип «Жим лёжа» без грифа в зале → «Новый гриф» → гриф выбран → «Добавить» → строка в «Свободном весе»;
  - второй гриф → новое упражнение «Штанга» → ничего не выбрано, «Добавить» неактивна до выбора;
  - «Планка» → «Собственный вес», метрика «Время»;
  - swipe → подтверждение с текстом для N = 0 → упражнение пропало, счётчик на «Программах» уменьшился;
  - вид грифа в «Моём зале» теперь заблокирован;
  - светлая и тёмная тема, крупный Dynamic Type, VoiceOver на степпере и radiogroup.
- Коммиты блоками: Domain → data → presentation.

## Вопросы к ревью плана (моя позиция в скобках)
- **Поиск.** В макете над списком есть поле «Поиск», в code-brief его нет. (Делать: это `.searchable` и фильтр в ViewModel, без новых запросов к БД. Без поиска справочник на 40+ упражнений листать неудобно.)
- **Строка справочника в макете с шевроном**, но правки ещё нет. (Без шеврона, пока нет экрана, на который ведёт тап.)
- **«Добавить» в навбаре шага 2**, а не кнопкой внизу — как в макете. (Да, как в макете.)
