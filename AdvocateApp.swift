import Foundation
import SwiftData

// MARK: - App Entry Point

@main
struct AdvocateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Client.self, Case.self, Event.self, Payment.self, Document.self])
    }
}
