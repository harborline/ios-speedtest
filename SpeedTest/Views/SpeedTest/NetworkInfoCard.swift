import SwiftUI

/// Displays network connection details and IP geolocation info.
struct NetworkInfoCard: View {
    let networkInfo: NetworkInfoService
    let geolocation: IPGeolocation?

    var body: some View {
        VStack(spacing: 16) {
            cardSection(title: "Network Information", icon: "wifi") {
                InfoRow(label: "Connection Type", value: networkInfo.currentType)
                if let isp = geolocation?.isp {
                    InfoRow(label: "Provider", value: isp)
                } else if let carrier = networkInfo.carrier {
                    InfoRow(label: "Carrier", value: carrier)
                }
                InfoRow(
                    label: "IP Address",
                    value: geolocation?.ipAddress ?? networkInfo.localIPAddress
                )
            }

            if let geo = geolocation {
                cardSection(title: "Server Location", icon: "globe") {
                    if let city = geo.city {
                        InfoRow(label: "City", value: city)
                    }
                    if let region = geo.region {
                        InfoRow(label: "Region", value: region)
                    }
                    if let country = geo.country {
                        let display = [country, geo.countryCode.map { "(\($0))" }]
                            .compactMap { $0 }.joined(separator: " ")
                        InfoRow(label: "Country", value: display)
                    }
                    if let lat = geo.latitude, let lon = geo.longitude {
                        InfoRow(label: "Coordinates", value: String(format: "%.4f, %.4f", lat, lon))
                    }
                    if let tz = geo.timezone {
                        InfoRow(label: "Timezone", value: tz)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cardSection<Content: View>(
        title: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundStyle(.blue)
                Text(title).fontWeight(.semibold).foregroundStyle(.white)
            }.font(.subheadline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1))
        )
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.medium).foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}