# Этап 12. Экспорт и импорт JSON — план

## Контекст
Последний этап по roadmap. Объём — `docs/code-brief.md` §10: экспорт и импорт всех данных в JSON, в файле `schemaVersion`, импорт заменяет всё после подтверждения. Макет — `.design/screens/SettingsScreen.dc.html` (`main`, `import`, `ax`). Решения обсуждения — `decisions.md`, «Этап 12: экспорт и импорт JSON (обсуждение)».

Коммиты по частям в `main`, push.

## Часть 1. Domain (`Packages/SportplanKit/Sources/Domain`)
- Модели:
  - `BackupSummary` — `exportedAt`, `workoutCount` (завершённые), `exerciseCount` (с архивом), `programCount`.
  - `BackupCandidate` — `summary` и `contents: Data`. Файл читается один раз, а импорт получает уже прочитанные байты.
  - `BackupError` — `unreadable`, `newerVersion`, `invalidData`, `workoutInProgress`.
- Протокол `BackupRepository`:
  - `makeBackup(exportedAt: Date) async throws -> Data`;
  - `readBackup(fileURL: URL) async throws -> BackupCandidate`;
  - `replaceAll(contents: Data) async throws`.
- Use cases:
  - `ExportBackupUseCase(repository:now:)` возвращает `BackupExport` — `fileName` (`sportplan-YYYY-MM-DD.json` по локальной дате) и `contents`.
  - `ReadBackupUseCase(repository:)`.
  - `ImportBackupUseCase(backupRepository:workoutRepository:)` — при активной тренировке бросает `workoutInProgress`, даже если UI уже запретил импорт (на случай гонки).
- Тесты на fake-репозитории:
  - имя файла по локальной дате;
  - импорт при активной тренировке отклоняется и `replaceAll` не вызывается;
  - ошибки чтения пробрасываются как есть.

## Часть 2. Data (`sportplan/data/backup/`, `sportplan/data/repositories/BackupRepositoryImpl.swift`)
- Формат — свои `Codable` DTO, отдельные от `Record`: схема базы может измениться, а формат файла — нет, пока не поднят `schemaVersion`.
  - Корень: `BackupFile` — `schemaVersion`, `exportedAt`, `equipment`, `plates`, `exercises`, `programs`, `programDays`, `plannedExercises`, `workouts`, `workoutExercises`, `sets`.
  - Строки: `BackupEquipment`, `BackupPlate`, `BackupExercise`, `BackupProgram`, `BackupProgramDay`, `BackupPlannedExercise`, `BackupWorkout`, `BackupWorkoutExercise`, `BackupSet`. Поля повторяют колонки схемы v2, ключи в camelCase, веса в граммах, UUID в нижнем регистре.
  - `BackupFormat.currentVersion = 1` (версия формата, не миграций). `BackupCoding` — JSONEncoder и JSONDecoder: `prettyPrinted` + `sortedKeys`, даты в ISO 8601 UTC с миллисекундами, чтобы round-trip не терял точность базы.
- Экспорт: одна транзакция чтения всех таблиц в DTO, порядок по id (тогда файл стабилен). У активной тренировки `restStartedAt` и `restEndsAt` пустые.
- Чтение:
  - Сначала читается только `schemaVersion`: версия новее — `newerVersion`, не JSON или нет поля — `unreadable`. Только потом файл декодируется целиком; ошибка — `unreadable`.
  - Затем пробный импорт: `replace` в транзакции с откатом. Нарушения FK, CHECK и уникальности выходят как `invalidData` ещё до подтверждения.
  - Файл из `fileImporter` читается с `startAccessingSecurityScopedResource`; это вспомогательный `BackupFileReader`.
- `replaceAll`: одна write-транзакция.
  - Удаление: `workout` (каскадом `workout_exercise`, `set_entry`), `program` (каскадом дни и плановые), `exercise`, `equipment`, `plate`.
  - Вставка от родителей к детям. Любая ошибка — откат и `invalidData`.
  - `ValueObservation` срабатывает один раз после коммита.
- Тесты (`sportplanTests/data/BackupRepositoryImplTests.swift`, in-memory, `DatabaseFixtures`):
  - round-trip: export → replaceAll в чистую базу → export даёт те же байты;
  - `replaceAll` удаляет прежние данные, включая блины и архив;
  - у активной тренировки таймер отдыха в файле пустой, после импорта она снова активная;
  - `schemaVersion` 2 — `newerVersion`, мусор — `unreadable`;
  - подход со ссылкой на несуществующее упражнение — `invalidData`, данные не изменились (и при чтении, и при `replaceAll`);
  - сводка: число завершённых тренировок, упражнений с архивом, программ.

## Часть 3. Presentation (`sportplan/presentation/settings/`)
- `SettingsUiData` получает `isImportAvailable` (нет активной тренировки). `SettingsViewModel` читает `ActiveWorkoutStore` — так же, как `ExercisePickerViewModel`.
- `SettingsViewModel` получает новые use cases:
  - `export() async throws -> BackupExport` для `ShareLink`;
  - `readImport(fileURL:)` — состояние подтверждения со сводкой или ошибка;
  - `confirmImport()`, `cancelImport()`, `dismissImportResult()`.

  Подтверждение, результат и ошибка — поле `importStep` в `SettingsUiData` (`idle` / `confirming(summary)` / `importing` / `finished` / `failed(BackupError)`), а не отдельные флаги.
- Экспорт:
  - `BackupExportItem: Transferable` с `DataRepresentation(exportedContentType: .json)` и `.suggestedFileName`. Данные собираются при выборе действия в меню, временных файлов нет.
  - Ошибка экспорта — системное меню ничего не делает. Отдельного UI нет, это отмечается в итогах.
- Экран, секция «Данные» между «Зал» и «О приложении»:
  - строки «Экспортировать в JSON» (`square.and.arrow.up`) и «Импортировать из JSON» (`square.and.arrow.down`) цветом `accent`, высота строки как у `NavigationRow`;
  - подпись «Все данные хранятся только на этом iPhone. Импорт заменяет их целиком — сначала сделай экспорт.»;
  - во время тренировки импорт неактивен, подпись — «Импорт недоступен во время тренировки — заверши или отмени её.»
- Импорт:
  - `fileImporter(allowedContentTypes: [.json])`;
  - `alert` «Заменить все данные?»: «В файле от 17 ноября 2026: 38 тренировок, 24 упражнения, 2 программы. Текущие данные будут удалены, отменить это нельзя.» Кнопки «Отмена» и «Заменить» (`.destructive`);
  - после успеха — алерт «Данные заменены», по «OK» вызывается `onImported`;
  - ошибки — алерт с текстом по `BackupError`: «Не удалось прочитать файл», «Файл из более новой версии приложения — обнови Sportplan», «В файле повреждённые данные. Текущие данные не изменены.», «Заверши или отмени тренировку».
- Навигация: `SettingsRoute(onImported:)` → `WorkoutTabView(onImported:)` → `RootView` делает `programsRouter.popToRoot()` и `historyRouter.popToRoot()`.
- DI: `backupRepository`, три use case как `private lazy var`; `buildSettingsViewModel()` получает их и `activeWorkoutStore`.
- Строки: ключи `settings.data.*` в `Localizable.xcstrings` (ru), в сводке плюралы one/few/many/other. Дата — `HistoryFormatting.fullDay`-подобный формат с годом.
- Тест `SettingsViewModelTests`:
  - чтение → подтверждение → импорт → `finished`;
  - отмена оставляет данные;
  - при активной тренировке `isImportAvailable == false`.

## Порядок коммитов
1. Domain и data: формат, репозиторий, use cases, тесты.
2. Настройки: секция «Данные», экспорт, импорт с подтверждением, сброс стеков.
3. Документы: decisions «Этап 12: итоги», roadmap — этап 12 в «Готово», «Осталось» пусто.

## Проверка
- `swift test` в пакете и `xcodebuild test` — зелёные.
- Симулятор (снимок базы до проверки, потом восстановить):
  - экспорт → «Сохранить в Файлы», файл читается, имя и отступы верные;
  - импорт этого файла в базу, изменённую после экспорта, → подтверждение с верными числами → данные вернулись, «История» и «Программы» на корне;
  - импорт битого файла и файла с `schemaVersion: 2` → алерт, данные не изменились;
  - во время тренировки импорт неактивен;
  - тёмная тема, крупный текст.
