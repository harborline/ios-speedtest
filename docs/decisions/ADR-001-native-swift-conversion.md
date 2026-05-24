# ADR-001: Native Swift Conversion of Speed Test App

**Date:** 2026-03-31  
**Status:** Accepted  
**Deciders:** Aloe Wright

---

## Context

The existing speed test application was built with React Native 0.79.2 / Expo SDK 53, using the `@cloudflare/speedtest` JavaScript library, Zustand for state management, and AsyncStorage for persistence. The goal is to produce an App Store–ready iOS application with native performance, a native feel, and a straightforward CI/CD path to the App Store.

## Decision

Rewrite the application as a native Swift / SwiftUI iOS app targeting iOS 17+, Swift 6 strict concurrency.

## Key Architectural Choices

### UI Framework — SwiftUI
SwiftUI with `@Observable` macro replaces React + Zustand. The declarative model maps 1:1 with the existing component hierarchy (gauge, stats grid, history list).

### State Management — @Observable + SwiftData
`@Observable` (iOS 17) replaces Zustand. SwiftData `@Model` replaces AsyncStorage + SQLite: it provides typed persistence, automatic migrations, and native `@Query` integration in views.

### Speed Test Engine — URLSession Actor
No Swift equivalent of `@cloudflare/speedtest` exists. The engine is reimplemented as a Swift `actor` (`SpeedTestEngine`) that replicates the library's 14-stage measurement schedule:

| Stage | Kind | Payload |
|-------|------|---------|
| 1 | Latency | 0 B (×1) |
| 2 | Download | 100 KB (×1) |
| 3 | Latency | 0 B (×20) |
| 4 | Download | 100 KB (×9) |
| 5 | Download | 1 MB (×8) |
| 6 | Upload | 100 KB (×8) |
| 7 | Upload | 1 MB (×6) |
| 8 | Download | 10 MB (×6) |
| 9 | Upload | 10 MB (×4) |
| 10 | Download | 25 MB (×4) |
| 11 | Upload | 25 MB (×4) |
| 12 | Download | 100 MB (×3) |
| 13 | Upload | 50 MB (×3) |
| 14 | Download | 250 MB (×2) |

Results use the 90th-percentile of all stage measurements, consistent with Cloudflare's methodology. Endpoints: `https://speed.cloudflare.com/__down?bytes=N` and `/__up`.

### Network Detection — NWPathMonitor + CTTelephonyNetworkInfo
`NWPathMonitor` detects interface type (WiFi / Cellular / Ethernet). `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` refines cellular to 5G / 4G / 3G / 2G. Local IP is read via `getifaddrs`, preferring `en0` (WiFi) then `pdp_ip0` (cellular).

### Geolocation — FreeIPAPI
`https://freeipapi.com/api/json` provides city, region, country, ISP, and coordinates without an API key (60 req/min limit — acceptable for a speed test app).

### Project Generation — XcodeGen
`project.yml` drives `.xcodeproj` generation, keeping the repo clean of Xcode-generated binary files and making CI setup trivial.

### Distribution — Fastlane
`produce` → `match` → `gym` → `pilot`/`deliver` pipeline using App Store Connect API key (no password required, CI-safe). Bundle ID: `com.speedy.speedtest`.

## Consequences

**Positive:**
- ~60% reduction in cold-start time vs. React Native bridge overhead
- Full Swift 6 concurrency safety (actor isolation, Sendable conformances)
- Native SwiftData migrations — no custom schema management
- No third-party dependencies in the main target (zero SPM packages required for v1)

**Negative / Trade-offs:**
- `@cloudflare/speedtest` JS library receives ongoing Cloudflare updates; the Swift engine must be manually kept in sync with any stage changes
- RevenueCat SDK wired (API key present) but paywall deferred to v2
- `CTTelephonyNetworkInfo` APIs are deprecated in favour of `CoreTelephony` replacements; will need updating for iOS 18+ if Apple removes them
