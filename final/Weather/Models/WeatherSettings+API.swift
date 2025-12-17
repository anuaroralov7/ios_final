import Foundation

extension WeatherSettings {
    var apiTemperatureUnit: String { temperatureUnit.rawValue }
    var apiWindSpeedUnit: String { windSpeedUnit.rawValue }

    var apiForecastDays: Int {
        min(max(1, forecastDays), 16)
    }
}
