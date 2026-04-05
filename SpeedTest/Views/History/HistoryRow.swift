import SwiftUI

struct HistoryRow: View {
    let result: SpeedTestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "wifi").font(.caption).foregroundStyle(.blue)
                    Text(result.networkType).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    if let carrier = result.carrier, carrier != "Unknown" {
                        Text("· \(carrier)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(result.timestamp.relativeDisplay).font(.caption2).foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                metricCell(icon: "arrow.down.circle.fill", color: .green, label: "Download",
                           value: String(format: "%.1f", result.downloadSpeed), unit: "Mbps")
                metricCell(icon: "arrow.up.circle.fill", color: .purple, label: "Upload",
                           value: String(format: "%.1f", result.uploadSpeed), unit: "Mbps")
                metricCell(icon: "server.rack", color: .cyan, label: "Ping",
                           value: "\(Int(result.ping))", unit: "ms")
                metricCell(icon: "waveform.path", color: .orange, label: "Jitter",
                           value: "\(Int(result.jitter))", unit: "ms")
            }
            Divider().overlay(Color.white.opacity(0.05))

            VStack(spacing: 4) {
                if let city = result.city, let region = result.region {
                    footerRow(label: "Location", value: "\(city), \(region)")
                }
                if let isp = result.ispName {
                    footerRow(label: "Provider", value: isp)
                }
                footerRow(label: "IP Address", value: result.ipAddress)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func metricCell(icon: String, color: Color, label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.callout).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.headline).fontWeight(.bold).foregroundStyle(.white).monospacedDigit()
            Text(unit).font(.caption2).foregroundStyle(.tertiary)
        }.frame(maxWidth: .infinity)
    }

    private func footerRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption2).foregroundStyle(Color(hex: "d1d5db"))
        }
    }
}