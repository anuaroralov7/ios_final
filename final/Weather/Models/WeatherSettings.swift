import Foundation

struct WeatherSettings: Codable, Equatable, Sendable {
    var temperatureUnit: TemperatureUnit
    var windSpeedUnit: WindSpeedUnit
    var showWind: Bool
    var forecastDays: Int

    static let `default` = WeatherSettings(
        temperatureUnit: .celsius,
        windSpeedUnit: .kmh,
        showWind: true,
        forecastDays: 7
    )
}

enum TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case celsius
    case fahrenheit
}

enum WindSpeedUnit: String, Codable, CaseIterable, Sendable {
    case kmh
    case ms
    case mph
    case kn
}

