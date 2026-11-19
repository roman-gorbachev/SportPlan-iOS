import Foundation

public struct ProgressSeries: Hashable, Sendable {
    public static let windowWeeks = 8

    private static let daysPerWeek = 7
    private static let secondsPerDay: TimeInterval = 86_400

    public let metric: ProgressMetric
    public let points: [ProgressPoint]

    public init(metric: ProgressMetric, points: [ProgressPoint]) {
        self.metric = metric
        self.points = points
    }

    public init(history: ExerciseHistory, metric: ProgressMetric) {
        var allPoints: [ProgressPoint] = []
        var bestSoFar: Int?
        for session in history.chronologicalSessions {
            let values = RecordBaseline.chronological(session.sets).compactMap { entry in
                return metric.value(of: entry)
            }
            guard let best = values.max() else {
                continue
            }
            let isRecord = bestSoFar.map { previous in
                return best > previous
            } ?? false
            bestSoFar = max(bestSoFar ?? best, best)
            allPoints.append(ProgressPoint(workoutId: session.workoutId, date: session.date, value: best, isRecord: isRecord))
        }
        guard let last = allPoints.last else {
            self.init(metric: metric, points: [])
            return
        }
        let windowStart = last.date.addingTimeInterval(-Self.windowDuration)
        let points = allPoints.filter { point in
            return point.date >= windowStart
        }
        self.init(metric: metric, points: points)
    }

    public var latest: Int? {
        return points.last?.value
    }

    public var delta: Int? {
        guard points.count > 1, let first = points.first, let last = points.last else {
            return nil
        }
        return last.value - first.value
    }

    private static var windowDuration: TimeInterval {
        return TimeInterval(windowWeeks * daysPerWeek) * secondsPerDay
    }
}
