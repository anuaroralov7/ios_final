import Foundation

enum WeatherCode {
    static func iconAndText(for code: Int) -> (symbol: String, text: String) {
        switch code {
        case 0: return ("sun.max", "Clear")
        case 1, 2: return ("cloud.sun", "Mostly clear")
        case 3: return ("cloud", "Cloudy")
        case 45, 48: return ("cloud.fog", "Fog")
        case 51, 53, 55: return ("cloud.drizzle", "Drizzle")
        case 61, 63, 65: return ("cloud.rain", "Rain")
        case 71, 73, 75: return ("cloud.snow", "Snow")
        case 80, 81, 82: return ("cloud.heavyrain", "Showers")
        case 95: return ("cloud.bolt", "Thunderstorm")
        case 96, 99: return ("cloud.bolt.rain", "Thunderstorm")
        default: return ("cloud", "Weather")
        }
    }
}


