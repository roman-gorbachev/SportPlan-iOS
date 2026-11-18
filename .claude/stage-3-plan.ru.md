# Этап 3: оборудование и упражнения — план

## Контекст
После этапа 2 у нас есть схема, доменные модели и Records, но ещё нет ни одного репозитория, use case или ViewModel. Этап 3 — первая настоящая фича и первый проход всего паттерна Route → ViewModel → UseCase → Repository. Блок большой, поэтому делим его на два подэтапа, у каждого своё ревью и свои коммиты:
- **3.1 — «Мой зал»: оборудование.** На нём обкатываем паттерн.
- **3.2 — справочник упражнений и добавление в 2 шага.** Опирается на оборудование и его sheet.

Решения обсуждения (18.11.2026):
- Редактирование блинов, сброс к IWF и превью блина переносятся на этап «Блины». В «Моём зале» пока только оборудование.
- На главной настроек только то, что работает: «Зал → Мой зал» и «О приложении → Версия». «Данные» появятся на этапе экспорта.
- Чипы частых упражнений делаем; тап по чипу открывает шаг 2 с заполненными полями.
- Правка упражнения и раздел «Архив» с возвратом — задачи дизайнеру. В код идут, когда будут макеты.
- Вид оборудования блокируется, если оно используется хотя бы в одном упражнении.
- Репозитории отдают наблюдение как `AsyncThrowingStream<[X], any Error>`.
- Тесты: use cases в пакете с фейковыми репозиториями, репозитории на in-memory GRDB, у ViewModel — только логика формы.

## Первым делом после одобрения
- Скопировать этот план в `.claude/stage-3-plan.ru.md`.
- Записать решения в `.claude/decisions.ru.md`.
- `docs/code-brief.md`, функция 1: блокировка вида оборудования, чипы частых упражнений, «Архив» с возвратом (ждёт дизайна).
- `.design/design-brief.md`: две задачи дизайнеру — экран правки упражнения и раздел «Архив» в справочнике и в «Моём зале».

## 3.1 «Мой зал»: оборудование

### Domain (`Packages/SportplanKit/Sources/Domain/`)
- **`Repository/EquipmentRepository`**: протокол `Sendable`.
  - `observeActive() -> AsyncThrowingStream<[Equipment], any Error>`;
  - `equipment(id:) async throws -> Equipment?`;
  - `save(_:) async throws` (upsert);
  - `archive(id:) async throws`;
  - `exerciseCount(usingEquipmentId:) async throws -> Int`.
- **`Model/EquipmentDraft`**: name, kind, baseWeight, weightStep.
  - `validationIssues` пустой, когда форма валидна;
  - `EquipmentValidationIssue`: emptyName, baseWeightOutOfRange, weightStepOutOfRange;
  - границы — `private static let`: гриф или платформа 0…500 кг, шаг 0,25…50 кг (поправим, если нужно);
  - у гантелей и блочного тренажёра `baseWeight` всегда 0;
  - вспомогательное `EquipmentKind.hasBaseWeight`.
- **Use cases** (`UseCase/Equipment/`), у каждого один `execute`:
  - `ObserveGymEquipmentUseCase`;
  - `LoadEquipmentEditorUseCase` → `EquipmentEditorSnapshot` (оборудование, число упражнений, `isKindLocked`);
  - `SaveEquipmentUseCase`: валидирует черновик; бросает `EquipmentError.kindLocked`, если вид меняется у используемого оборудования; создаёт с новым UUID и `createdAt` (часы подаются через init);
  - `ArchiveEquipmentUseCase`.
- **Тесты** (`DomainTests`):
  - `FakeEquipmentRepository` на `Mutex`;
  - тесты `SaveEquipmentUseCase`: валидация, блокировка вида, обнуление веса грифа у гантелей и блочного;
  - тесты `EquipmentDraft`.

### Data (`sportplan/data/repositories/`)
- **`EquipmentRepositoryImpl`** (`nonisolated`, принимает `AppDatabase`).
  - Наблюдение: `ValueObservation.tracking { … }.values(in: reader)` превращается в `AsyncThrowingStream` и маппится через `toDomainModel()`.
  - Порядок: вид, затем название. Архивное оборудование не показывается.
  - Счётчик упражнений — `ExerciseRecord.filter(equipment_id == id).fetchCount`.
- Используем то, что уже есть: `AppDatabase` (`sportplan/data/database/AppDatabase.swift`), `EquipmentRecord`, `ExerciseRecord`.
- **Тесты** (`sportplanTests/data/EquipmentRepositoryImplTests`): наблюдение выдаёт новый список после сохранения и архивации; архивное не выдаётся; счётчик считает упражнения. Фикстуры — `DatabaseFixtures`.

### Presentation (`sportplan/presentation/`)
- **`settings/`**: `SettingsRoute`, `SettingsViewModel` (наблюдает число оборудования), `SettingsScreen` переписывается из заглушки.
  - Секция «Зал» со строкой «Мой зал» и подписью «N видов оборудования» (плюрализация в String Catalog).
  - Секция «О приложении» со строкой «Версия» из `CFBundleShortVersionString`.
- **`gym/`**:
  - `GymDestination`, `GymRoute`, `GymViewModel`, `GymScreen`.
  - В списке строка оборудования: название, вид, «20 · 2,5». Кнопка «Добавить оборудование».
  - Пустое состояние «Оборудования пока нет» с кнопкой.
- **`gym/editor/`**: `EquipmentEditorRoute`, `EquipmentEditorViewModel`, `EquipmentEditorScreen` — sheet.
  - Поля: «Название», «Вид» (Picker, неактивен при `isKindLocked`), «Вес грифа / платформы, кг» (только у грифа и тренажёра с блинами, подпись по виду), «Шаг веса, кг».
  - «Используется в N упражнениях». «Архивировать» с подтверждением из дизайна. «Отмена» / «Готово»; «Готово» неактивна, пока черновик невалиден.
  - Цель: `EquipmentEditorTarget` — `.new(kind:)` или `.existing(id:)`, плюс замыкание `onSaved(UUID)`. Это нужно для «Новый гриф» в 3.2.
- **`common/`**: `WeightFormatting` — кг с запятой, без лишних нулей; разбор ввода из десятичного поля.
- **Навигация**: `SettingsDestination` → `GymDestination` в стеке вкладки «Тренировка», редактор — `.sheet` из `GymRoute`. Контейнер передаётся `RootView` → `WorkoutTabView` → Route.
- **UI state**: `GymUiState` — `.loading` / `.success(data: GymUiData)` / `.error(error:)`; так же для настроек и редактора.
- **Строки**: в `Localizable.xcstrings` все подписи, виды оборудования, тексты пустого состояния и подтверждения, плюралы.
- **Тесты ViewModel**: только `EquipmentEditorViewModel` — доступность «Готово», скрытие веса грифа по виду, блокировка вида.

### DesignSystem (`Packages/SportplanKit/Sources/DesignSystem/`)
Только то, что нужно этим экранам, строки передаются снаружи:
- `EmptyStateView` (заголовок, текст, действие);
- `InkButtonStyle` (капсула ink);
- модификатор `appGroupedList()` (фон `background`, строки `surface`, разделители `separator`).
Новые компоненты попадают в `TokenCatalogView`.

### DI
- `AppDIContainer`: `private lazy var equipmentRepository` и use cases.
- Фабрики `buildSettingsViewModel()`, `buildGymViewModel()`, `buildEquipmentEditorViewModel(target:)` — в extension внутри `di/AppDIContainer.swift`: `private lazy var` видны только в своём файле.

## 3.2 Справочник упражнений (кратко; подробный план — `.claude/stage-3.2-plan.ru.md`)
- Domain:
  - `ExerciseRepository`;
  - use cases: `ObserveExerciseLibrary` (группы «Свободный вес» / «Тренажёры» / «Собственный вес»), `CreateExercise` (название; оборудование обязательно для всех видов, кроме собственного веса; отдых), `ArchiveExercise` (в одной транзакции удаляет `planned_exercise`), `CountProgramDaysUsingExercise`;
  - `ExerciseTemplate` — 7 чипов: название, вид, метрика.
- Presentation:
  - строка «Справочник упражнений N» на вкладке «Программы», остальное там по-прежнему заглушка до этапа 4;
  - `LibraryRoute`: группы, swipe «Архивировать» с подтверждением «будет убрано из N дней», пустое состояние с чипами и «Своё упражнение»;
  - sheet добавления: шаг 1 «Чем делаешь?», шаг 2 — название, оборудование нужного вида из зала с «Новый …» (редактор из 3.1 с `.new(kind:)`), метрика, отдых (степпер ±15 с, 0:00–10:00), описание;
  - если в зале одно оборудование нужного вида, оно выбрано сразу.
- Контекст «В день A» (подходы и повторы в sheet) — этап 4. Правка упражнения и «Архив» — после дизайна.

## Проверка
- `cd Packages/SportplanKit && swift test` и `xcodebuild test …` (команды в CLAUDE.md) зелёные.
- Симулятор:
  - шестерёнка → «Настройки» → «Мой зал»: пустое состояние → добавить гриф → строка в списке;
  - правка: вид неактивен, если оборудование уже в упражнении (вставить упражнение через тестовые данные или после 3.2);
  - архивация с подтверждением;
  - светлая и тёмная тема, крупный Dynamic Type, VoiceOver-подписи.
- Коммиты блоками: Domain → data → presentation, от `Roman Gorbachev <romangorbachev2006@gmail.com>`.
