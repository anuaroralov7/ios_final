import Foundation

enum WeatherAppConfig {
    static let geocodingBaseURL = URL(string: "https://geocoding-api.open-meteo.com")!
    static let forecastBaseURL = URL(string: "https://api.open-meteo.com")!
}
