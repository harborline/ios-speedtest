import SwiftUI

struct PrivacyPolicyView: View {
    private let cloudflareURL = URL(string: "https://speed.cloudflare.com")!
    private let geolocationURL = URL(string: "https://freeipapi.com")!
    private let supportURL = URL(string: "https://gist.github.com/aloewright/12e104c7c4060f1dea5625aa86b56c85#file-support-md")!
    private let privacyURL = URL(string: "https://gist.github.com/aloewright/12e104c7c4060f1dea5625aa86b56c85#file-privacy-md")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    policySection("Data Used", rows: [
                        "Speed-test traffic is sent to Cloudflare speed test endpoints to measure download, upload, latency, and jitter.",
                        "Your public IP address is sent to FreeIPAPI to estimate city, region, country, ISP, and approximate coordinates.",
                        "Network type, carrier name, local IP address, and test history are stored on this device using SwiftData."
                    ])

                    policySection("Data Not Used For", rows: [
                        "No account is required.",
                        "No advertising, analytics SDK, or cross-app tracking is included.",
                        "Saved history is not uploaded by the app."
                    ])

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Links")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Link("Cloudflare speed test endpoint", destination: cloudflareURL)
                        Link("FreeIPAPI geolocation service", destination: geolocationURL)
                        Link("Privacy policy", destination: privacyURL)
                        Link("Support", destination: supportURL)
                    }
                    .font(.subheadline)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "0a0e27"), Color(hex: "1a1f3a"), Color(hex: "0a0e27")],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0a0e27"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(.cyan)
    }

    private func policySection(_ title: String, rows: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(rows, id: \.self) { row in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.cyan)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(row)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
