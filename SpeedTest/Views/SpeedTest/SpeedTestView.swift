import SwiftUI
import SwiftData
import MapKit

struct SpeedTestView: View {
    @Bindable var viewModel: SpeedTestViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    SpeedGaugeView(
                        progress: viewModel.progress,
                        speed: viewModel.isRunning ? viewModel.displaySpeed : nil,
                        phaseLabel: viewModel.isRunning ? viewModel.displayPhaseLabel : nil
                    )
                    .padding(.top, 8)

                    startButton

                    if viewModel.isRunning || viewModel.isFinished {
                        statsGrid
                    }

                    NetworkInfoCard(
                        networkInfo: viewModel.networkInfo,
                        geolocation: viewModel.ipGeolocation
                    )
                    if viewModel.isFinished,
                       let lat = viewModel.ipGeolocation?.latitude,
                       let lon = viewModel.ipGeolocation?.longitude {
                        mapSection(latitude: lat, longitude: lon)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "0a0e27"), Color(hex: "1a1f3a"), Color(hex: "0a0e27")],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("Speed Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0a0e27"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    // MARK: - Subviews

    private var startButton: some View {
        Button {
            if viewModel.isRunning {
                viewModel.cancelTest()
            } else {
                if viewModel.isFinished { viewModel.reset() }
                viewModel.startTest(context: modelContext)
            }
        } label: {
            Text(viewModel.isRunning ? "Cancel" : "Start Test")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 999)
                        .fill(
                            viewModel.isRunning
                                ? LinearGradient(colors: [.gray, Color(hex: "4b5563")], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isRunning)
    }
    private var statsGrid: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                StatCell(icon: "arrow.down.circle.fill", iconColor: .green, label: "Download",
                         value: viewModel.currentDownloadSpeed > 0 ? String(format: "%.1f", viewModel.currentDownloadSpeed) : "0.0", unit: "Mbps")
                StatCell(icon: "arrow.up.circle.fill", iconColor: .purple, label: "Upload",
                         value: viewModel.currentUploadSpeed > 0 ? String(format: "%.1f", viewModel.currentUploadSpeed) : "0.0", unit: "Mbps")
            }
            HStack(spacing: 0) {
                StatCell(icon: "server.rack", iconColor: .cyan, label: "Ping",
                         value: viewModel.currentPing > 0 ? "\(Int(viewModel.currentPing))" : "0", unit: "ms")
                StatCell(icon: "waveform.path", iconColor: .orange, label: "Jitter",
                         value: viewModel.currentJitter > 0 ? "\(Int(viewModel.currentJitter))" : "0", unit: "ms")
            }
        }
    }

    private func mapSection(latitude: Double, longitude: Double) -> some View {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        return Map(initialPosition: .region(region)) {
            Marker("Server Location", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)).tint(.blue)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeOut(duration: 0.5), value: viewModel.isFinished)
    }
}

private struct StatCell: View {
    let icon: String; let iconColor: Color; let label: String; let value: String; let unit: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title2).foregroundStyle(iconColor)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.title2).fontWeight(.bold).foregroundStyle(.white).monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.tertiary)
        }.frame(maxWidth: .infinity)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default: r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}