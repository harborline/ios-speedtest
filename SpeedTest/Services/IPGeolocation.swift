import Foundation

// MARK: - IPGeolocationService

/// Fetches IP-based geolocation from FreeIPAPI (no API key required, 60 req/min).
enum IPGeolocationService {

    static func fetch() async -> IPGeolocation? {
        guard let url = URL(string: "https://freeipapi.com/api/json") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return nil }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            return IPGeolocation(
                ipAddress: json?["ipAddress"] as? String,
                city: json?["cityName"] as? String,
                region: json?["regionName"] as? String,
                country: json?["countryName"] as? String,
                countryCode: json?["countryCode"] as? String,
                latitude: json?["latitude"] as? Double,
                longitude: json?["longitude"] as? Double,
                timezone: json?["timeZone"] as? String,
                isp: json?["isp"] as? String
            )
        } catch {
            print("IP Geolocation error: \(error.localizedDescription)")
            return nil
        }
    }
}