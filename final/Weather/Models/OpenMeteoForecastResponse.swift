import Foundation

struct OpenMeteoForecastResponse: Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let timezone: String

    let current: Current?
    let hourly: Hourly?
    let daily: Daily?

    struct Current: Codable, Sendable {
        let time: String
        let temperature2m: Double?
        let weatherCode: Int?
        let windSpeed10m: Double?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
        }
    }

    struct Hourly: Codable, Sendable {
        let time: [String]
        let temperature2m: [Double]?
        let weatherCode: [Int]?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Codable, Sendable {
        let time: [String]
        let temperature2mMax: [Double]?
        let temperature2mMin: [Double]?
        let weatherCode: [Int]?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weatherCode = "weather_code"
        }
    }
}
