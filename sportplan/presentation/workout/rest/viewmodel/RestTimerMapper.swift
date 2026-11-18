import Domain
import Foundation

enum RestTimerMapper {
    static func makeItem(workout: ActiveWorkout, rest: RestPeriod) -> RestTimerItem {
        let trigger = workout.restTrigger
        let title = trigger?.number.map { number in
            return String(localized: "rest.panel.title \(number)")
        } ?? String(localized: "rest.panel.titleGeneric")
        let total = RestFormatting.clock(seconds: Int(rest.duration.rounded()))
        let next = trigger.flatMap { trigger in
            return workout.nextPlannedSet(after: trigger)
        }
        let nextText = next.map { next in
            let summary = WorkoutFormatting.setSummary(next.entry, exercise: next.exercise.exercise)
            return String(localized: "rest.accessory.next \(summary)")
        } ?? String(localized: "rest.accessory.title")
        return RestTimerItem(
            startedAt: rest.startedAt,
            endsAt: rest.endsAt,
            title: title,
            totalText: String(localized: "rest.panel.total \(total)"),
            nextText: nextText
        )
    }
}
