import Foundation
import SwiftData
import SwiftUI

// MARK: - SpeedTestViewModel

@Observable
@MainActor
final class SpeedTestViewModel {

    // MARK: - Test State

    var isRunning = false
    var isFinished = false
    var progress: Double = 0
    var currentPhase: String = ""

    var currentDownloadSpeed: Double = 0
    var currentUploadSpeed: Double = 0
    var currentPing: Double = 0
    var currentJitter: Double = 0

    // MARK: - Network Info

    var ipGeolocation: IPGeolocation?
    let networkInfo = NetworkInfoService()

    // MARK: - Private

    private var engine: SpeedTestEngine?
    // MARK: - Actions

    func startTest(context: ModelContext) {
        guard !isRunning else { return }
        resetState()
        isRunning = true
        isFinished = false

        Task {
            async let geoTask = IPGeolocationService.fetch()
            let testEngine = SpeedTestEngine()
            engine = testEngine

            do {
                let results = try await testEngine.run { [weak self] progress in
                    Task { @MainActor in
                        self?.handleProgress(progress)
                    }
                }
                let geo = await geoTask
                ipGeolocation = geo
                saveResult(results: results, geo: geo, context: context)
                isRunning = false
                isFinished = true
                progress = 1.0
            } catch is CancellationError {
                isRunning = false
            } catch {
                print("Speed test error: \(error.localizedDescription)")
                isRunning = false
                currentPhase = "Error"
            }
        }
    }
    func cancelTest() {
        Task { await engine?.cancel() }
        isRunning = false
    }

    func reset() {
        resetState()
        isFinished = false
        ipGeolocation = nil
    }

    // MARK: - Private Helpers

    private func resetState() {
        progress = 0
        currentPhase = ""
        currentDownloadSpeed = 0
        currentUploadSpeed = 0
        currentPing = 0
        currentJitter = 0
    }

    private func handleProgress(_ p: SpeedTestEngine.Progress) {
        progress = p.fraction
        currentPhase = p.phase.rawValue.capitalized
        currentDownloadSpeed = p.downloadSpeed
        currentUploadSpeed = p.uploadSpeed
        currentPing = p.latency
        currentJitter = p.jitter
    }
    private func saveResult(
        results: SpeedTestEngine.Results,
        geo: IPGeolocation?,
        context: ModelContext
    ) {
        let network = networkInfo.snapshot()
        let result = SpeedTestResult(
            downloadSpeed: round(results.downloadSpeed * 100) / 100,
            uploadSpeed: round(results.uploadSpeed * 100) / 100,
            ping: round(results.latency),
            jitter: round(results.jitter),
            networkType: network.type,
            carrier: network.carrier,
            ipAddress: geo?.ipAddress ?? network.ipAddress,
            city: geo?.city,
            region: geo?.region,
            country: geo?.country,
            ispName: geo?.isp,
            latitude: geo?.latitude,
            longitude: geo?.longitude
        )
        context.insert(result)
    }

    var displaySpeed: Double {
        if currentDownloadSpeed > 0 { return currentDownloadSpeed }
        return currentUploadSpeed
    }

    var displayPhaseLabel: String {
        if currentDownloadSpeed > 0 { return "Download" }
        if currentUploadSpeed > 0 { return "Upload" }
        if currentPing > 0 { return "Latency" }
        return currentPhase
    }
}