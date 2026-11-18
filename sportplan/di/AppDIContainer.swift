final class AppDIContainer {
    private let appDatabase: AppDatabase

    init() {
        do {
            appDatabase = try AppDatabase.makePersistent()
        } catch {
            fatalError("Unable to open the database: \(error)")
        }
    }
}
