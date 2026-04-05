import Foundation
import Network
import CoreTelephony

// MARK: - NetworkInfoService

/// Detects current network type, carrier, and local IP address using Network framework.
/// @unchecked Sendable is safe here because all mutable state mutations are dispatched
/// back to @MainActor before touching stored properties.
@Observable
final class NetworkInfoService: @unchecked Sendable {
    private(set) var currentType: String = "Unknown"
    private(set) var carrier: String? = nil
    private(set) var localIPAddress: String = "Unknown"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.speedtest.network-monitor")

    init() {
        startMonitoring()
        detectCarrier()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateFromPath(path)
            }
        }
        monitor.start(queue: queue)
    }

    @MainActor
    private func updateFromPath(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            currentType = "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            currentType = detectCellularGeneration()
        } else if path.usesInterfaceType(.wiredEthernet) {
            currentType = "Ethernet"
        } else {
            currentType = "Unknown"
        }
        if let ip = getLocalIPAddress() {
            localIPAddress = ip
        }
    }

    // MARK: - Cellular Detection

    private func detectCellularGeneration() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        guard let carriers = networkInfo.serviceCurrentRadioAccessTechnology,
              let radioTech = carriers.values.first else {
            return "Cellular"
        }
        switch radioTech {
        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
            return "5G"
        case CTRadioAccessTechnologyLTE:
            return "4G"
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA:
            return "3G"
        case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS:
            return "2G"
        default:
            return "Cellular"
        }
    }

    private func detectCarrier() {
        let networkInfo = CTTelephonyNetworkInfo()
        if let providers = networkInfo.serviceSubscriberCellularProviders,
           let provider = providers.values.first {
            carrier = provider.carrierName
        }
    }

    // MARK: - IP Address

    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }
            let name = String(cString: interface.ifa_name)
            guard name == "en0" || name == "pdp_ip0" else { continue }
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil, 0,
                NI_NUMERICHOST
            )
            address = String(cString: hostname)
            if name == "en0" { break }
        }
        return address
    }

    /// Snapshot of current network details for saving with a test result.
    func snapshot() -> NetworkDetails {
        NetworkDetails(
            type: currentType,
            carrier: carrier,
            ipAddress: localIPAddress
        )
    }
}
