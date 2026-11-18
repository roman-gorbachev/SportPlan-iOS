import Foundation

struct RestTimerItem: Hashable {
    let startedAt: Date
    let endsAt: Date
    let title: String
    let totalText: String
    let nextText: String
}
