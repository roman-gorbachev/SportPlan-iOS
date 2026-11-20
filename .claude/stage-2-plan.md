# Stage 2: database — plan

The stage's decisions are in `.claude/decisions.md` (the "Stage 2" section), the schema is in `docs/code-brief.md` ("Data model (v1)").

## Scope
In: domain models for all tables, GRDB, `AppDatabase` with migration v1 and the IWF plate seed, Records with `toDomainModel()`, schema and mapping tests.
Out: repositories, use cases, screens — in stages 3+ together with the screens.

## Structure
```
Packages/SportplanKit/Sources/Domain/
  Weight.swift (exists)
  Model/  Equipment, EquipmentKind, Exercise, ExerciseLoad, ExerciseMetric,
          Program, ProgramDay, PlannedExercise, RepRange,
          Workout, ProgramDaySnapshot, RestPeriod, WorkoutExercise, SetEntry,
          Plate, PlateColor, StandardPlates
Packages/SportplanKit/Tests/DomainTests/
  RepRangeTests, StandardPlatesTests
sportplan/data/
  database/  AppDatabase, AppDatabase+Migrations (migration v1)
  records/   EquipmentRecord … PlateRecord, RecordMappingError
sportplanTests/data/
  MigrationTests, SchemaConstraintTests, RecordMappingTests
```

## Steps
1. **Domain models** (`Domain`, `Sendable`, no GRDB):
   - `ExerciseLoad` — `.bodyweight` / `.equipment(UUID)` instead of a bare `nil`;
   - `RepRange(min:max:)` — a failable init: min ≥ 1, min ≤ max;
   - `ProgramDaySnapshot` — a copy of the day in the workout (`programDayId?`, `name`, `label?`);
   - `RestPeriod(startedAt:endsAt:)` — the rest timer of the active workout;
   - `PlateColor(rgb:)`;
   - `StandardPlates` — the IWF set (25, 20, 15, 10, 5, 2.5, 1.25 kg; colors are the light values from `system/Color`).
   - Tests: `RepRange`; the IWF set has 7 plates with unique weights within 0.25–50 kg.
2. **GRDB 7** in `project.xcproj`: `{ "kind": "remote", "repository": "https://github.com/groue/GRDB.swift", "version": { "up-to-next-major-version": "7.12.0" } }`, the `GRDB` product only in the `sportplan` target (`dependencies` + `package-product-members`). Commit `Package.resolved`. Check with `xcodebuild`.
3. **`AppDatabase`** — a `nonisolated final class`, `Sendable`, takes `any DatabaseWriter` and runs the migrator.
   - In the app: a `DatabasePool` at `Application Support/Database/sportplan.sqlite`.
   - In tests: an in-memory `DatabaseQueue()`.
   - GRDB enables foreign keys by default. `eraseDatabaseOnSchemaChange` stays off: the phone will have real data.
4. **Migration v1** via the GRDB DSL, following the schema in the code brief:
   - CHECK:
     - `kind` / `metric` IN (…);
     - weights ≥ 0, `weight_step_g` > 0, `rest_sec` ≥ 0, `target_sets` ≥ 1;
     - `target_reps_min` ≥ 1 and ≤ `target_reps_max`, both set or both NULL;
     - `rest_started_at` / `rest_ends_at` both set or both NULL;
     - plate 250…50000 g.
   - Indexes on all FKs and `workout(started_at)`.
   - One active workout — a unique index on an expression, not on `finished_at`: in SQLite NULLs don't conflict in a unique index. For example `ON workout((finished_at IS NULL)) WHERE finished_at IS NULL`.
   - `position` has no unique constraint, so reordering doesn't need temporary values.
   - The plate seed comes from `StandardPlates`. A test pins the exact weights and colors, so the constant can't change without changing the test: this way the migration doesn't change retroactively.
5. **Records** — `nonisolated struct XRecord: Codable, FetchableRecord, PersistableRecord`:
   - `databaseTableName`;
   - snake_case column strategies;
   - `databaseUUIDEncodingStrategy = .lowercaseString`;
   - the plate color is stored as a `#RRGGBB` string;
   - `toDomainModel() throws` (an unknown `kind` or `metric` → `RecordMappingError`) and `init(_ model:)`.
6. **DI**: `AppDIContainer` opens the database at startup so the migration is checked on the device right away, not at the first screen.
7. **Tests** (`sportplanTests`, Swift Testing, in-memory):
   - the migration creates all tables, the seed is 7 plates;
   - `id` is stored as `text`;
   - CHECK and UNIQUE on the plate;
   - a second active workout is rejected;
   - cascades `program → day → planned_exercise` and `workout → workout_exercise → set_entry`;
   - RESTRICT: an exercise with history and equipment with exercises can't be deleted;
   - SET NULL: deleting a day leaves the copy of the name and label in the workout;
   - a round trip for every Record ↔ model.
8. **Check and documents**:
   - run in the simulator, the database file has 7 plates (sqlite3 on the app container);
   - CLAUDE.md: data layer conventions (`nonisolated` records, UUIDs as text, the active workout index);
   - commits in blocks: domain models → DB layer with tests.

## Done when
The build passes, `swift test` and `xcodebuild test` are green, the app starts and creates the database with the IWF plates, the documents are updated.

## Questions for the plan review (my position in parentheses)
- The database failed to open (disk full, file corrupted) — `fatalError` with the error description or an error screen? (`fatalError` now, a screen before the App Store.)
- Identifiers — plain `UUID` or typed ids? (`UUID`: simpler, and named parameters prevent mix-ups.)
- Rest and duration in the domain — `Int` seconds, as in the DB, or `Duration`? (`Int`.)
- `system/Color` still has light and dark variants for plates, while `system/PlatesKit` says "one color plus a stroke". For the seed I take the light values; the dark ones are unused.
