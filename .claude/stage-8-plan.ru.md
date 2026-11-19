# Этап 8: блины — план

## Контекст
Этапы 0–7 и правки по ревью в `main`. Следующий блок по `docs/code-brief.md` §6 — набор блинов своего зала. Макет — `.design/system/PlatesKit` (11 «Мой зал», 13 «Блин») и `.design/screens/SettingsScreen` («Мой зал», главная настроек). Миграций нет: таблица `plate` и сид IWF есть с этапа 2, раскладка `PlateLoading` и стопка `PlateStack` — с этапа 5.

Решения обсуждения (19.11.2026, `decisions.ru.md` «Этап 8»):
- Удаление блина — только в sheet, без свайпа и без подтверждения; «Мой зал» остаётся карточками.
- Пустой набор разрешён.
- Сброс к IWF — одна транзакция, константа `StandardPlates`.
- Наблюдение за блинами читают «Мой зал», экран тренировки и координатор Live Activity.
- Вес и уникальность проверяет `SavePlateUseCase`, `UNIQUE` — страховка; ввод с разделителем локали, хранение в граммах.
- Подпись строки — название цвета палитры или «свой цвет», без «· IWF».
- Палитра: красный, синий, жёлтый, зелёный, белый, сталь (из `StandardPlates`), чёрный `#2A2A2A` (из макета) + «Свой».

## 8.1 Domain и data
**Domain (`Packages/SportplanKit/Sources/Domain/`)**
- `PlateRepository`: `observeAll() -> AsyncThrowingStream<[Plate], any Error>` (по убыванию веса), `save(_:)` (вставка или обновление), `delete(id:)`, `replaceAll(with:)`. Разовое `plates()` и `LoadPlatesUseCase` убираются — их заменяет наблюдение.
- `PlatePaletteColor` (enum, `CaseIterable`): семь цветов с `PlateColor`; `init?(color:)` — для подписи и выбора в палитре. Цвета IWF берутся из `StandardPlates`, чтобы не задваивать hex.
- `PlateDraft` (`weight: Weight`, `color: PlateColor`) с `validationIssues` (вне 0,25–50 кг — границы из `Plate.minimumWeight` / `maximumWeight`).
- `PlateError`: `invalidDraft`, `duplicateWeight`, `notFound`.
- Use cases (`UseCase/Plate/`):
  - `ObservePlatesUseCase`;
  - `LoadPlateEditorUseCase.execute(id: UUID?) -> PlateEditorSnapshot` — сам блин (для правки) и занятые веса других блинов, для подсказки под полем;
  - `SavePlateUseCase.execute(draft:existingId:) -> Plate` — проверка черновика, дубль веса среди других блинов → `duplicateWeight`;
  - `DeletePlateUseCase`;
  - `ResetPlatesToStandardUseCase` → `replaceAll(with: StandardPlates.makeIWFSet())`.
- Тесты (`DomainTests`): `PlateDraft` (границы включительно), сохранение нового и правка, дубль веса отклонён, свой же вес при правке разрешён, `notFound`, удаление, сброс к IWF, занятые веса без своего, `PlatePaletteColor(color:)`. Фейк `FakePlateRepository` на `Mutex`.

**Data (`sportplan/data/`)**
- `PlateRepositoryImpl`: `observeAll` на `ValueObservation`, как `observeActive` у оборудования; `save` — upsert; `delete`; `replaceAll` — удаление и вставка в одном `write`.
- `PlateRepositoryImplTests` на in-memory базе: порядок, наблюдение видит правку, `UNIQUE` веса, `replaceAll` даёт ровно набор IWF, удаление последнего блина — пустой список.

## 8.2 «Мой зал» и sheet блина
**«Мой зал» (`presentation/gym/`)**
- `GymViewModel` наблюдает оборудование и блины (`ObservePlatesUseCase`); `GymUiData` получает `plates: [GymPlateItem]` (id, цвет, «25 кг», подпись цвета, VoiceOver-подпись).
- `GymScreen`: вторая секция «Блины» — строки блина (кружок-блин в своём цвете с обводкой `separatorStrong`, вес `numeralS`, подпись цвета), «Добавить блин»; отдельная строка «Сбросить блины к стандарту IWF» с `confirmationDialog`. Тап по строке — sheet.
- Пустое оборудование: сейчас весь экран — `EmptyStateView`. Предлагаю пустое состояние только внутри секции оборудования (текст и «Добавить оборудование»), секция блинов — как всегда. В макете вместо неё свёрнутая строка «Блины · стандарт IWF», но непонятно, что по ней делать; полная секция проще и одинакова в обоих состояниях. **Вопрос к ревью плана.**
- Главная настроек: «6 видов оборудования · 7 блинов», как в макете — `SettingsViewModel` наблюдает и блины, новая строка каталога с plural.

**Sheet блина (`presentation/gym/plate/`: `ui/`, `viewmodel/`, `models/`, `states/`)**
- `PlateEditorTarget` (`.new` / `.existing(id:)`), `PlateEditorRoute` (NavigationStack, «Отмена» / «Готово» в toolbar снаружи `switch`), `PlateEditorScreen` с `#Preview`, `PlateEditorViewModel`, `PlateEditorUiData`, `PlateEditorUiState`.
- Превью: `PlateStack` с одним блином текущего веса и цвета на конце грифа, меняется сразу. Если вес не введён — блин по наименьшей ширине.
- Вес: `TextField` с `.decimalPad`, разбор через `WeightFormatting.parseKilograms`; подсказка под полем при дубле («Блин 20 кг уже есть») или выходе за границы; «Готово» неактивна.
- Палитра: 7 кружков + «Свой» (`ColorPicker(supportsOpacity: false)` в виде кружка). Выбранный — кольцо `ink` 2pt с зазором, `accessibilityAddTraits(.isSelected)`, подпись — название цвета. Цель тапа ≥ 44pt; при крупном тексте палитра переносится в несколько строк. Если цвет не из палитры — выбран «Свой».
- Перевод `Color` из `ColorPicker` в `PlateColor` — через `UIColor.getRed` в sRGB, с зажатием 0…1; вспомогательный файл в presentation.
- Новый блин: вес пустой, цвет — первый в палитре (красный). Существующий: «Удалить блин» внизу, без подтверждения, закрывает sheet.
- Ошибка сохранения — alert, как у оборудования.
- `AppDIContainer`: use cases и `buildPlateEditorViewModel(target:)`; `GymRoute` получает фабрику, как для оборудования.

## 8.3 Потребители набора
- `ActiveWorkoutViewModel`: `loadPlateSet()` → `observePlates()` из `.task` в `WorkoutRoute`; при изменении набора UI пересчитывается из последнего снимка store.
- `WorkoutActivityCoordinator`: блины читаются наблюдением параллельно со снимками store (`withDiscardingTaskGroup`), изменение набора переотправляет содержимое только если оно поменялось. Оговорка этапа 7 «подхватит после перезапуска» снимается в `decisions.ru.md`.
- Тесты: `WorkoutActivityCoordinatorTests` — правка блина во время тренировки обновляет стопку в содержимом; `WorkoutViewModelsTests` — удаление блина меняет раскладку в строке подхода.

## Тесты ViewModel
- `PlateEditorViewModel`: разбор «2,5»; дубль веса и выход за границы выключают «Готово» и показывают подсказку; свой вес при правке не считается дублем; выбор цвета палитры и своего цвета; сохранение и удаление.
- `GymViewModel`: подписи цвета (палитра / «свой цвет»).
- `swift test` и `xcodebuild test` — зелёные, сборка без предупреждений.

## Проверка на симуляторе
- «Мой зал»: секция блинов, добавить блин, правка веса и цвета (превью меняется сразу), дубль веса, границы 0,25 и 50, «Свой» цвет, удаление, удаление всех, сброс к IWF с подтверждением.
- Во время тренировки: правка блина — стопка в строке подхода и в Live Activity обновляется без перезапуска.
- Главная настроек: счётчик блинов.
- Тёмная тема (белый и чёрный блин видны за счёт обводки), крупный текст (палитра, строка блина), VoiceOver (палитра «выбрано», строка блина).

## Документы и коммиты
- План → `.claude/stage-8-plan.ru.md`; итоги → `decisions.ru.md` («Этап 8: итоги реализации»); `roadmap.ru.md` — этап 8 в «Готово».
- Коммиты по частям: 8.1 domain и data → 8.2 экраны → 8.3 потребители; от `Roman Gorbachev <romangorbachev2006@gmail.com>`, без упоминаний AI; сразу в `main` и push.
