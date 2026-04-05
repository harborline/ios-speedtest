import Foundation
import SwiftData

// MARK: - SpeedTestResult

@Model
final class SpeedTestResult {
    var id: String
    var downloadSpeed: Double   // Mbps
    var uploadSpeed: Double     // Mbps
    var ping: Double            // ms (unloaded latency)
    var jitter: Double          // ms (unloaded jitter)
    var networkType: String     // WiFi, 5G, 4G, etc.
    var carrier: String?
    var ipAddress: String
    var city: String?
    var region: String?
    var country: String?
    var ispName: String?
    var latitude: Double?
    var longitude: Double?
    var timestamp: Date

    // Extended Cloudflare metrics
    var loadedLatencyDown: Double?
    var loadedLatencyUp: Double?
    var loadedJitterDown: Double?
    var loadedJitterUp: Double?
    var packetLoss: Double?
    init(
        downloadSpeed: Double,
        uploadSpeed: Double,
        ping: Double,
        jitter: Double,
        networkType: String,
        carrier: String? = nil,
        ipAddress: String,
        city: String? = nil,
        region: String? = nil,
        country: String? = nil,
        ispName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID().uuidString
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.ping = ping
        self.jitter = jitter
        self.networkType = networkType
        self.carrier = carrier
        self.ipAddress = ipAddress
        self.city = city
        self.region = region
        self.country = country
        self.ispName = ispName
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = .now
    }
}

// MARK: - Supporting Types

struct IPGeolocation: Sendable {
    var ipAddress: String?
    var city: String?
    var region: String?
    var country: String?
    var countryCode: String?
    var latitude: Double?
    var longitude: Double?
    var timezone: String?
    var isp: String?
}

struct NetworkDetails: Sendable {
    var type: String        // WiFi, 5G, 4G, Cellular, Unknown
    var carrier: String?
    var ipAddress: String
}