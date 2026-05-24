import SwiftUI

struct ContentView: View {
    @State private var viewModel = SpeedTestViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SpeedTestView(viewModel: viewModel)
                .tabItem {
                    Label("Speed Test", systemImage: "bolt.horizontal.fill")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            PrivacyPolicyView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
                .tag(2)
        }
        .tint(.blue)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SpeedTestResult.self, inMemory: true)
}
