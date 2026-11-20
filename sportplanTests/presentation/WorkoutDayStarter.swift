import Foundation
@testable import sportplan

@MainActor
struct WorkoutDayStarter {
    let startScreen: WorkoutStartViewModel
    let makePreview: (UUID) -> WorkoutPreviewViewModel

    func start(dayId: UUID) async {
        let preview = makePreview(dayId)
        await preview.load()
        _ = await preview.start()
    }

    func startEmpty() async {
        await startScreen.startEmpty()
    }
}
