import AppMetricaCore
import Foundation
import os

// MARK: - Analytics

enum AnalyticsEvent: String {
    case open
    case close
    case click
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track
    case filter
    case edit
    case delete
}

protocol AnalyticsServiceProtocol {
    func report(event: AnalyticsEvent, screen: AnalyticsScreen, item: AnalyticsItem?)
}

// MARK: - AnalyticsService

final class AnalyticsService: AnalyticsServiceProtocol {

    private static let apiKeyInfoKey = "AppMetricaAPIKey"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Tracker", category: "analytics")

    // ключ лежит в Info.plist, без ключа события только пишутся в лог
    static func activate() {
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String,
            !apiKey.isEmpty,
            let configuration = AppMetricaConfiguration(apiKey: apiKey)
        else {
            logger.warning("AppMetrica: нет API ключа, события не отправляются")
            return
        }
        AppMetrica.activate(with: configuration)
    }

    func report(event: AnalyticsEvent, screen: AnalyticsScreen, item: AnalyticsItem? = nil) {
        var parameters: [AnyHashable: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue
        ]
        if let item {
            parameters["item"] = item.rawValue
        }
        Self.logger.debug("analytics: \(parameters, privacy: .public)")
        AppMetrica.reportEvent(name: "ui_event", parameters: parameters) { error in
            Self.logger.error("analytics error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
