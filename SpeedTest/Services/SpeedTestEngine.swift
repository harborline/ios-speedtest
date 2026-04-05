import Foundation

// MARK: - SpeedTestEngine

/// Performs network speed measurements against Cloudflare's speed test endpoints.
/// Mirrors the measurement stages from the @cloudflare/speedtest JS library.
actor SpeedTestEngine {

    // MARK: - Types

    enum Phase: String, Sendable {
        case idle
        case latency
        case download
        case upload
        case finished
        case error
    }

    struct Progress: Sendable {
        var phase: Phase
        var completedSteps: Int
        var totalSteps: Int
        var currentSpeed: Double
        var downloadSpeed: Double
        var uploadSpeed: Double
        var latency: Double
        var jitter: Double

        var fraction: Double {
            guard totalSteps > 0 else { return 0 }
            return Double(completedSteps) / Double(totalSteps)
        }
    }
    struct Results: Sendable {
        var downloadSpeed: Double
        var uploadSpeed: Double
        var latency: Double
        var jitter: Double
    }

    // MARK: - Measurement Stages

    private struct MeasurementStage {
        enum Kind { case latency, download, upload }
        let kind: Kind
        let bytes: Int
        let count: Int
    }

    private static let stages: [MeasurementStage] = [
        .init(kind: .latency,  bytes: 0,           count: 1),
        .init(kind: .download, bytes: 100_000,     count: 1),
        .init(kind: .latency,  bytes: 0,           count: 20),
        .init(kind: .download, bytes: 100_000,     count: 9),
        .init(kind: .download, bytes: 1_000_000,   count: 8),
        .init(kind: .upload,   bytes: 100_000,     count: 8),
        .init(kind: .upload,   bytes: 1_000_000,   count: 6),
        .init(kind: .download, bytes: 10_000_000,  count: 6),
        .init(kind: .upload,   bytes: 10_000_000,  count: 4),
        .init(kind: .download, bytes: 25_000_000,  count: 4),
        .init(kind: .upload,   bytes: 25_000_000,  count: 4),
        .init(kind: .download, bytes: 100_000_000, count: 3),
        .init(kind: .upload,   bytes: 50_000_000,  count: 3),
        .init(kind: .download, bytes: 250_000_000, count: 2),
    ]
    // MARK: - Cloudflare Endpoints

    private static let baseURL = "https://speed.cloudflare.com"
    private static let downloadURL = "\(baseURL)/__down"
    private static let uploadURL = "\(baseURL)/__up"

    // MARK: - State

    private var isCancelled = false
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    func run(onProgress: @Sendable @escaping (Progress) -> Void) async throws -> Results {
        isCancelled = false
        let totalSteps = Self.stages.count
        var completedSteps = 0
        var allLatencies: [Double] = []
        var downloadSpeeds: [Double] = []
        var uploadSpeeds: [Double] = []
        var currentProgress = Progress(
            phase: .idle, completedSteps: 0, totalSteps: totalSteps,
            currentSpeed: 0, downloadSpeed: 0, uploadSpeed: 0, latency: 0, jitter: 0
        )

        for stage in Self.stages {
            guard !isCancelled else { throw CancellationError() }

            switch stage.kind {
            case .latency:
                currentProgress.phase = .latency
                onProgress(currentProgress)
                let latencies = try await measureLatency(count: stage.count)
                allLatencies.append(contentsOf: latencies)
                let avgLatency = allLatencies.reduce(0, +) / Double(allLatencies.count)
                currentProgress.latency = avgLatency
                currentProgress.jitter = calculateJitter(latencies: allLatencies)

            case .download:
                currentProgress.phase = .download
                onProgress(currentProgress)
                let speed = try await measureDownload(bytes: stage.bytes, count: stage.count)
                downloadSpeeds.append(speed)
                currentProgress.downloadSpeed = percentile(downloadSpeeds, p: 0.9)
                currentProgress.currentSpeed = speed

            case .upload:
                currentProgress.phase = .upload
                onProgress(currentProgress)
                let speed = try await measureUpload(bytes: stage.bytes, count: stage.count)
                uploadSpeeds.append(speed)
                currentProgress.uploadSpeed = percentile(uploadSpeeds, p: 0.9)
                currentProgress.currentSpeed = speed
            }
            completedSteps += 1
            currentProgress.completedSteps = completedSteps
            onProgress(currentProgress)
        }
        currentProgress.phase = .finished
        onProgress(currentProgress)
        return Results(
            downloadSpeed: percentile(downloadSpeeds, p: 0.9),
            uploadSpeed: percentile(uploadSpeeds, p: 0.9),
            latency: allLatencies.isEmpty ? 0 : allLatencies.reduce(0, +) / Double(allLatencies.count),
            jitter: calculateJitter(latencies: allLatencies)
        )
    }

    func cancel() {
        isCancelled = true
        session.invalidateAndCancel()
    }

    // MARK: - Measurement Implementations

    private func measureLatency(count: Int) async throws -> [Double] {
        var latencies: [Double] = []
        for _ in 0..<count {
            guard !isCancelled else { throw CancellationError() }
            guard let url = URL(string: "\(Self.downloadURL)?bytes=0") else { continue }
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let start = CFAbsoluteTimeGetCurrent()
            let (_, response) = try await session.data(for: request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { continue }
            latencies.append(elapsed)
        }
        return latencies
    }
    private func measureDownload(bytes: Int, count: Int) async throws -> Double {
        var totalBytes: Int64 = 0
        var totalTime: Double = 0
        for _ in 0..<count {
            guard !isCancelled else { throw CancellationError() }
            guard let url = URL(string: "\(Self.downloadURL)?bytes=\(bytes)") else { continue }
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let start = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await session.data(for: request)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { continue }
            totalBytes += Int64(data.count)
            totalTime += elapsed
        }
        guard totalTime > 0 else { return 0 }
        let bytesPerSecond = Double(totalBytes) / totalTime
        return (bytesPerSecond * 8) / 1_000_000
    }

    private func measureUpload(bytes: Int, count: Int) async throws -> Double {
        var totalBytes: Int64 = 0
        var totalTime: Double = 0
        let payload = Data(count: bytes)
        for _ in 0..<count {
            guard !isCancelled else { throw CancellationError() }
            guard let url = URL(string: Self.uploadURL) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let start = CFAbsoluteTimeGetCurrent()
            let (_, response) = try await session.upload(for: request, from: payload)
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { continue }
            totalBytes += Int64(bytes)
            totalTime += elapsed
        }
        guard totalTime > 0 else { return 0 }
        let bytesPerSecond = Double(totalBytes) / totalTime
        return (bytesPerSecond * 8) / 1_000_000
    }
    // MARK: - Statistics

    private func calculateJitter(latencies: [Double]) -> Double {
        guard latencies.count >= 2 else { return 0 }
        var diffs: [Double] = []
        for i in 1..<latencies.count {
            diffs.append(abs(latencies[i] - latencies[i - 1]))
        }
        return diffs.reduce(0, +) / Double(diffs.count)
    }

    private func percentile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let index = Int(Double(sorted.count - 1) * p)
        return sorted[min(index, sorted.count - 1)]
    }
}