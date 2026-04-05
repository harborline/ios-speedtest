import Foundation

extension Date {
    /// Human-readable relative time string matching the RN app's format.
    var relativeDisplay: String {
        let now = Date.now
        let interval = now.timeIntervalSince(self)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }

        return formatted(.dateTime.month(.abbreviated).day().year())
    }
}