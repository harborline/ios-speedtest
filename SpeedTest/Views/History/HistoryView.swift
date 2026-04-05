import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SpeedTestResult.timestamp, order: .reverse)
    private var results: [SpeedTestResult]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty { emptyState } else { resultsList }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "0a0e27"), Color(hex: "1a1f3a"), Color(hex: "0a0e27")],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0a0e27"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !results.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) { clearHistory() } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock").font(.system(size: 64)).foregroundStyle(Color(hex: "374151"))
            Text("No tests yet").font(.title3).foregroundStyle(.secondary)
            Text("Run a speed test to see your results here")
                .font(.subheadline).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        List {
            Section {
                Text("\(results.count) test(s) recorded")
                    .font(.caption).foregroundStyle(.secondary)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
            }
            ForEach(results) { result in
                HistoryRow(result: result)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            .onDelete(perform: deleteResults)
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
    }

    private func clearHistory() { for result in results { modelContext.delete(result) } }
    private func deleteResults(at offsets: IndexSet) { for i in offsets { modelContext.delete(results[i]) } }
}