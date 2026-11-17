import Observation
import SwiftUI

@Observable
final class TabRouter: Router {
    var path = NavigationPath()

    func push<Destination: Hashable>(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
