import SwiftUI
import SwiftData

@main
struct SpeedTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SpeedTestResult.self])
    }
}