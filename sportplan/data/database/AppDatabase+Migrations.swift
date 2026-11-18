import Domain
import Foundation
import GRDB

nonisolated extension AppDatabase {
    private static let schemaV1 = "v1"
    private static let defaultRestSeconds = 90
    private static let minimumReps = 1
    private static let minimumSets = 1
    private static let plateMinimumGrams = 250
    private static let plateMaximumGrams = 50_000

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration(schemaV1) { db in
            try createSchemaV1(db)
            try seedStandardPlates(db)
        }
        return migrator
    }

    private static func createSchemaV1(_ db: Database) throws {
        try db.execute(sql: """
            CREATE TABLE equipment (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                kind TEXT NOT NULL CHECK (kind IN ('barbell', 'dumbbell', 'plate_loaded_machine', 'selectorized_machine')),
                base_weight_g INTEGER NOT NULL DEFAULT 0 CHECK (base_weight_g >= 0),
                weight_step_g INTEGER NOT NULL CHECK (weight_step_g > 0),
                is_archived BOOLEAN NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL
            );

            CREATE TABLE exercise (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                description TEXT,
                equipment_id TEXT REFERENCES equipment(id) ON DELETE RESTRICT,
                metric TEXT NOT NULL CHECK (metric IN ('weight_reps', 'duration')),
                rest_sec INTEGER NOT NULL DEFAULT \(defaultRestSeconds) CHECK (rest_sec >= 0),
                is_archived BOOLEAN NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL
            );
            CREATE INDEX exercise_on_equipment_id ON exercise(equipment_id);

            CREATE TABLE program (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                position INTEGER NOT NULL,
                created_at DATETIME NOT NULL
            );

            CREATE TABLE program_day (
                id TEXT PRIMARY KEY NOT NULL,
                program_id TEXT NOT NULL REFERENCES program(id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                label TEXT,
                position INTEGER NOT NULL
            );
            CREATE INDEX program_day_on_program_id ON program_day(program_id);

            CREATE TABLE planned_exercise (
                id TEXT PRIMARY KEY NOT NULL,
                program_day_id TEXT NOT NULL REFERENCES program_day(id) ON DELETE CASCADE,
                exercise_id TEXT NOT NULL REFERENCES exercise(id) ON DELETE RESTRICT,
                position INTEGER NOT NULL,
                target_sets INTEGER NOT NULL CHECK (target_sets >= \(minimumSets)),
                target_reps_min INTEGER,
                target_reps_max INTEGER,
                rest_sec INTEGER NOT NULL CHECK (rest_sec >= 0),
                CHECK (\(repRangeCheck))
            );
            CREATE INDEX planned_exercise_on_program_day_id ON planned_exercise(program_day_id);
            CREATE INDEX planned_exercise_on_exercise_id ON planned_exercise(exercise_id);

            CREATE TABLE workout (
                id TEXT PRIMARY KEY NOT NULL,
                program_day_id TEXT REFERENCES program_day(id) ON DELETE SET NULL,
                program_day_name TEXT,
                program_day_label TEXT,
                started_at DATETIME NOT NULL,
                finished_at DATETIME,
                note TEXT,
                rest_started_at DATETIME,
                rest_ends_at DATETIME,
                CHECK (program_day_id IS NULL OR program_day_name IS NOT NULL),
                CHECK (program_day_label IS NULL OR program_day_name IS NOT NULL),
                CHECK ((rest_started_at IS NULL) = (rest_ends_at IS NULL))
            );
            CREATE INDEX workout_on_program_day_id ON workout(program_day_id);
            CREATE INDEX workout_on_started_at ON workout(started_at);
            CREATE UNIQUE INDEX workout_single_active ON workout((finished_at IS NULL)) WHERE finished_at IS NULL;

            CREATE TABLE workout_exercise (
                id TEXT PRIMARY KEY NOT NULL,
                workout_id TEXT NOT NULL REFERENCES workout(id) ON DELETE CASCADE,
                exercise_id TEXT NOT NULL REFERENCES exercise(id) ON DELETE RESTRICT,
                position INTEGER NOT NULL,
                target_sets INTEGER CHECK (target_sets IS NULL OR target_sets >= \(minimumSets)),
                target_reps_min INTEGER,
                target_reps_max INTEGER,
                rest_sec INTEGER NOT NULL CHECK (rest_sec >= 0),
                CHECK (\(repRangeCheck))
            );
            CREATE INDEX workout_exercise_on_workout_id ON workout_exercise(workout_id);
            CREATE INDEX workout_exercise_on_exercise_id ON workout_exercise(exercise_id);

            CREATE TABLE set_entry (
                id TEXT PRIMARY KEY NOT NULL,
                workout_exercise_id TEXT NOT NULL REFERENCES workout_exercise(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                weight_g INTEGER NOT NULL DEFAULT 0 CHECK (weight_g >= 0),
                reps INTEGER CHECK (reps IS NULL OR reps >= 0),
                duration_sec INTEGER CHECK (duration_sec IS NULL OR duration_sec >= 0),
                is_warmup BOOLEAN NOT NULL DEFAULT 0,
                started_at DATETIME,
                completed_at DATETIME
            );
            CREATE INDEX set_entry_on_workout_exercise_id ON set_entry(workout_exercise_id);

            CREATE TABLE plate (
                id TEXT PRIMARY KEY NOT NULL,
                weight_g INTEGER NOT NULL UNIQUE CHECK (weight_g BETWEEN \(plateMinimumGrams) AND \(plateMaximumGrams)),
                color_hex TEXT NOT NULL CHECK (color_hex GLOB '#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]')
            );
            """)
    }

    private static var repRangeCheck: String {
        return """
            (target_reps_min IS NULL AND target_reps_max IS NULL) \
            OR (target_reps_min IS NOT NULL AND target_reps_max IS NOT NULL \
            AND target_reps_min >= \(minimumReps) AND target_reps_min <= target_reps_max)
            """
    }

    private static func seedStandardPlates(_ db: Database) throws {
        for plate in StandardPlates.makeIWFSet() {
            try db.execute(
                sql: "INSERT INTO plate (id, weight_g, color_hex) VALUES (?, ?, ?)",
                arguments: [plate.id.uuidString.lowercased(), plate.weight.grams, plate.color.hexString]
            )
        }
    }
}
