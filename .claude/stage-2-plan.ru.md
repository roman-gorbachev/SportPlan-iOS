# Этап 2: база данных — план

Решения этапа — в `.claude/decisions.ru.md` (раздел «Этап 2»), схема — в `docs/code-brief.md` («Модель данных (v1)»).

## Объём
Входит: доменные модели всех таблиц, GRDB, `AppDatabase` с миграцией v1 и сидом блинов IWF, Records с `toDomainModel()`, тесты схемы и маппинга.
Не входит: репозитории, use cases, экраны — в этапах 3+ вместе с экранами.

## Структура
```
Packages/SportplanKit/Sources/Domain/
  Weight.swift (есть)
  Model/  Equipment, EquipmentKind, Exercise, ExerciseLoad, ExerciseMetric,
          Program, ProgramDay, PlannedExercise, RepRange,
          Workout, ProgramDaySnapshot, RestPeriod, WorkoutExercise, SetEntry,
          Plate, PlateColor, StandardPlates
Packages/SportplanKit/Tests/DomainTests/
  RepRangeTests, StandardPlatesTests
sportplan/data/
  database/  AppDatabase, AppDatabase+Migrations (миграция v1)
  records/   EquipmentRecord … PlateRecord, RecordMappingError
sportplanTests/data/
  MigrationTests, SchemaConstraintTests, RecordMappingTests
```

## Шаги
1. **Доменные модели** (`Domain`, `Sendable`, без GRDB):
   - `ExerciseLoad` — `.bodyweight` / `.equipment(UUID)` вместо голого `nil`;
   - `RepRange(min:max:)` — failable init: min ≥ 1, min ≤ max;
   - `ProgramDaySnapshot` — копия дня в тренировке (`programDayId?`, `name`, `label?`);
   - `RestPeriod(startedAt:endsAt:)` — таймер отдыха активной тренировки;
   - `PlateColor(rgb:)`;
   - `StandardPlates` — набор IWF (25, 20, 15, 10, 5, 2,5, 1,25 кг; цвета — светлые значения из `system/Color`).
   - Тесты: `RepRange`, в наборе IWF 7 блинов с уникальным весом в пределах 0,25–50 кг.
2. **GRDB 7** в `project.xcproj`: `{ "kind": "remote", "repository": "https://github.com/groue/GRDB.swift", "version": { "up-to-next-major-version": "7.12.0" } }`, продукт `GRDB` только в таргете `sportplan` (`dependencies` + `package-product-members`). Закоммитить `Package.resolved`. Проверить `xcodebuild`.
3. **`AppDatabase`** — `nonisolated final class`, `Sendable`, принимает `any DatabaseWriter` и прогоняет мигратор.
   - В приложении: `DatabasePool` в `Application Support/Database/sportplan.sqlite`.
   - В тестах: `DatabaseQueue()` в памяти.
   - Внешние ключи у GRDB включены по умолчанию. `eraseDatabaseOnSchemaChange` не включаем: на телефоне будут реальные данные.
4. **Миграция v1** через DSL GRDB, по схеме из code-brief:
   - CHECK:
     - `kind` / `metric` IN (…);
     - веса ≥ 0, `weight_step_g` > 0, `rest_sec` ≥ 0, `target_sets` ≥ 1;
     - `target_reps_min` ≥ 1 и ≤ `target_reps_max`, оба заданы или оба NULL;
     - `rest_started_at` / `rest_ends_at` оба заданы или оба NULL;
     - блин 250…50000 г.
   - Индексы на все FK и `workout(started_at)`.
   - Одна активная тренировка — уникальный индекс по выражению, а не по `finished_at`: в SQLite NULL в уникальном индексе не конфликтуют. Например `ON workout((finished_at IS NULL)) WHERE finished_at IS NULL`.
   - У `position` уникального ограничения нет, чтобы перестановка не требовала временных значений.
   - Сид блинов берётся из `StandardPlates`. Тест фиксирует точные веса и цвета, поэтому изменить константу без изменения теста нельзя: так миграция не меняется задним числом.
5. **Records** — `nonisolated struct XRecord: Codable, FetchableRecord, PersistableRecord`:
   - `databaseTableName`;
   - стратегии snake_case для колонок;
   - `databaseUUIDEncodingStrategy = .lowercaseString`;
   - цвет блина хранится строкой `#RRGGBB`;
   - `toDomainModel() throws` (неизвестный `kind` или `metric` → `RecordMappingError`) и `init(_ model:)`.
6. **DI**: `AppDIContainer` открывает базу при старте, чтобы миграция на устройстве проверялась сразу, а не при первом экране.
7. **Тесты** (`sportplanTests`, Swift Testing, in-memory):
   - миграция создаёт все таблицы, сид — 7 блинов;
   - `id` хранится как `text`;
   - CHECK и UNIQUE блина;
   - вторая активная тренировка отклоняется;
   - каскады `program → day → planned_exercise` и `workout → workout_exercise → set_entry`;
   - RESTRICT: нельзя удалить упражнение с историей и оборудование с упражнениями;
   - SET NULL: удаление дня оставляет копию названия и метки в тренировке;
   - туда-обратно для каждого Record ↔ модель.
8. **Проверка и документы**:
   - запуск в симуляторе, в файле базы 7 блинов (sqlite3 по контейнеру приложения);
   - CLAUDE.md: соглашения data-слоя (`nonisolated` records, UUID текстом, индекс активной тренировки);
   - коммиты блоками: доменные модели → слой БД с тестами.

## Готово, когда
Сборка проходит, `swift test` и `xcodebuild test` зелёные, приложение запускается и создаёт базу с блинами IWF, документы обновлены.

## Вопросы к ревью плана (моя позиция в скобках)
- База не открылась (диск полон, файл повреждён) — `fatalError` с описанием ошибки или экран ошибки? (`fatalError` сейчас, экран — перед App Store.)
- Идентификаторы — простой `UUID` или типизированные id? (`UUID`: проще, а путаницу закрывают именованные параметры.)
- Отдых и длительность в домене — `Int` секунд, как в БД, или `Duration`? (`Int`.)
- В `system/Color` у блинов остались светлый и тёмный варианты, а `system/PlatesKit` говорит «один цвет плюс обводка». Для сида беру светлые значения, тёмные не используются.
