import SwiftUI
import Testing
@testable import sportplan

struct TabRouterTests {
    @Test func pushAddsDestination() {
        let router = TabRouter()
        router.push(SettingsDestination())
        #expect(router.path.count == 1)
    }

    @Test func popRemovesLastDestination() {
        let router = TabRouter()
        router.push(SettingsDestination())
        router.push(SettingsDestination())
        router.pop()
        #expect(router.path.count == 1)
    }

    @Test func popOnEmptyPathDoesNothing() {
        let router = TabRouter()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @Test func popToRootClearsPath() {
        let router = TabRouter()
        router.push(SettingsDestination())
        router.push(SettingsDestination())
        router.popToRoot()
        #expect(router.path.isEmpty)
    }
}
