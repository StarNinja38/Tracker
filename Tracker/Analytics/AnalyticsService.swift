import AppMetricaCore
import Foundation

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

    // ключ лежит в Info.plist, без ключа события только пишутся в лог
    static func activate() {
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String,
            !apiKey.isEmpty,
            let configuration = AppMetricaConfiguration(apiKey: apiKey)
        else {
            print("AppMetrica: нет API ключа в Info.plist, события не отправляются")
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
        print("analytics:", parameters)
        AppMetrica.reportEvent(name: "ui_event", parameters: parameters) { error in
            print("analytics error:", error.localizedDescription)
        }
    }
}
